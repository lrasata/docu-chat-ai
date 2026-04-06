import base64
import json
import os
import time
import boto3
import psycopg2
from pgvector.psycopg2 import register_vector

# ---------- Environment variables ----------
REGION = os.environ["REGION"]
RDS_SECRET_ARN = os.environ["RDS_SECRET_ARN"]
DOCUMENTS_TABLE = os.environ["DOCUMENTS_TABLE"]
BEDROCK_MODEL_INFERENCE_PROFILE_ARN = os.environ["BEDROCK_MODEL_INFERENCE_PROFILE_ARN"]
MAX_RESULTS = int(os.environ.get("MAX_SEARCH_RESULTS", "5"))
BEDROCK_GUARDRAIL_ID = os.environ["BEDROCK_GUARDRAIL_ID"]
BEDROCK_GUARDRAIL_VERSION = os.environ.get("BEDROCK_GUARDRAIL_VERSION", "1")
TEMPERATURE = float(os.environ.get("TEMPERATURE", "0.7"))
MAX_TOKENS = int(os.environ.get("LLM_MAX_TOKENS", "2000"))
COGNITO_USER_POOL_ID = os.environ.get("COGNITO_USER_POOL_ID", "")
COGNITO_CLIENT_ID = os.environ.get("COGNITO_CLIENT_ID", "")

# ----------- CONSTANTS -----------------
QUESTION_MODEL_EMBEDDING = "amazon.titan-embed-text-v1"
SYSTEM_PROMPT = (
    "You are a helpful AI assistant that answers questions based on the provided document context. "
    "Only use information from the context below to answer the question. "
    "If the answer cannot be found in the context, say so."
)

# ---------- AWS clients ----------
bedrock_runtime = boto3.client("bedrock-runtime", region_name=REGION)
secretsmanager = boto3.client("secretsmanager")

# ---------- Connection cache ----------
_db_conn = None


def get_db_credentials():
    response = secretsmanager.get_secret_value(SecretId=RDS_SECRET_ARN)
    return json.loads(response["SecretString"])


def get_db_connection():
    global _db_conn
    try:
        if _db_conn is not None:
            _db_conn.cursor().execute("SELECT 1")
            return _db_conn
    except Exception:
        _db_conn = None

    creds = get_db_credentials()
    _db_conn = psycopg2.connect(
        host=creds["host"],
        port=creds["port"],
        dbname=creds["dbname"],
        user=creds["username"],
        password=creds["password"],
        connect_timeout=5,
        sslmode="require",
    )
    _db_conn.autocommit = True
    register_vector(_db_conn)
    return _db_conn


# ---------- JWT helpers ----------
def _decode_jwt_payload(token):
    """Decode JWT payload without signature verification (stdlib only)."""
    try:
        parts = token.split(".")
        if len(parts) != 3:
            return None
        # Fix base64 padding
        payload_b64 = parts[1]
        padding = 4 - len(payload_b64) % 4
        if padding != 4:
            payload_b64 += "=" * padding
        return json.loads(base64.urlsafe_b64decode(payload_b64))
    except Exception:
        return None


def extract_user_id_from_bearer_token(authorization_header):
    """
    Extract the Cognito user_id (sub) from the Bearer token.

    Performs basic claim validation (expiry, issuer, client_id) without
    verifying the RSA signature. For full signature verification, bundle
    python-jose[cryptography] and validate against Cognito's JWKS endpoint:
      https://cognito-idp.{region}.amazonaws.com/{user_pool_id}/.well-known/jwks.json
    """
    if not authorization_header or not authorization_header.startswith("Bearer "):
        return None

    token = authorization_header[7:]
    payload = _decode_jwt_payload(token)
    if not payload:
        return None

    if payload.get("exp", 0) < time.time():
        print("Token expired")
        return None

    if COGNITO_USER_POOL_ID:
        expected_iss = f"https://cognito-idp.{REGION}.amazonaws.com/{COGNITO_USER_POOL_ID}"
        if payload.get("iss") != expected_iss:
            print(f"Invalid issuer: {payload.get('iss')}")
            return None

    if COGNITO_CLIENT_ID:
        token_client = payload.get("client_id") or payload.get("aud")
        if token_client != COGNITO_CLIENT_ID:
            print(f"Invalid client_id/aud: {token_client}")
            return None

    return payload.get("sub")


# ---------- Embedding + vector search ----------
def create_embedding(text):
    try:
        response = bedrock_runtime.invoke_model(
            modelId=QUESTION_MODEL_EMBEDDING,
            contentType="application/json",
            accept="application/json",
            body=json.dumps({"inputText": text}),
        )
        body = json.loads(response["body"].read())
        return body["embedding"]
    except Exception as e:
        print(f"Error creating embedding: {str(e)}")
        raise


def search_similar_chunks(question_embedding, user_id, document_id=None, max_results=MAX_RESULTS):
    try:
        conn = get_db_connection()
        with conn.cursor() as cur:
            if document_id:
                cur.execute(
                    """
                    SELECT document_id, chunk_id, content,
                           1 - (embedding <=> %s::vector) AS score
                    FROM document_chunks
                    WHERE document_id = %s
                    ORDER BY embedding <=> %s::vector
                    LIMIT %s;
                    """,
                    (question_embedding, document_id, question_embedding, max_results),
                )
            else:
                cur.execute(
                    """
                    SELECT document_id, chunk_id, content,
                           1 - (embedding <=> %s::vector) AS score
                    FROM document_chunks
                    WHERE document_id LIKE %s
                    ORDER BY embedding <=> %s::vector
                    LIMIT %s;
                    """,
                    (question_embedding, f"uploads/users/{user_id}/%", question_embedding, max_results),
                )
            rows = cur.fetchall()

        return [
            {"document_id": r[0], "chunk_id": r[1], "text": r[2], "score": float(r[3])}
            for r in rows
        ]
    except Exception as e:
        print(f"Error searching pgvector: {str(e)}")
        raise


# ---------- Bedrock helpers ----------
def _build_converse_kwargs(question, context_chunks):
    context = "\n\n".join(
        [f"[Chunk {i+1}]\n{chunk['text']}" for i, chunk in enumerate(context_chunks)]
    )
    kwargs = {
        "modelId": BEDROCK_MODEL_INFERENCE_PROFILE_ARN,
        "system": [{"text": SYSTEM_PROMPT}],
        "messages": [
            {
                "role": "user",
                "content": [{"text": f"Context:\n{context}\n\nQuestion: {question}"}],
            }
        ],
        "inferenceConfig": {
            "maxTokens": MAX_TOKENS,
            "temperature": TEMPERATURE,
        },
    }
    if BEDROCK_GUARDRAIL_ID:
        kwargs["guardrailConfig"] = {
            "guardrailIdentifier": BEDROCK_GUARDRAIL_ID,
            "guardrailVersion": BEDROCK_GUARDRAIL_VERSION,
        }
    return kwargs


def generate_answer_with_bedrock(question, context_chunks):
    """Non-streaming Bedrock call. Used for sync (API Gateway / direct invoke) path."""
    try:
        response = bedrock_runtime.converse(**_build_converse_kwargs(question, context_chunks))
        return response["output"]["message"]["content"][0]["text"]
    except Exception as e:
        print(f"Error calling Bedrock: {str(e)}")
        raise


def stream_answer_with_bedrock(question, context_chunks, response_stream):
    """
    Streaming Bedrock call via converse_stream().
    Writes SSE text-delta events to response_stream as tokens arrive.

    SSE event format:
      data: {"type": "text_delta", "text": "..."}\n\n
    """
    try:
        result = bedrock_runtime.converse_stream(**_build_converse_kwargs(question, context_chunks))
        for event in result["stream"]:
            if "contentBlockDelta" in event:
                delta = event["contentBlockDelta"].get("delta", {})
                if "text" in delta:
                    sse = json.dumps({"type": "text_delta", "text": delta["text"]})
                    response_stream.write(f"data: {sse}\n\n".encode("utf-8"))
    except Exception as e:
        print(f"Error streaming from Bedrock: {str(e)}")
        error_sse = json.dumps({"type": "error", "message": str(e)})
        response_stream.write(f"data: {error_sse}\n\n".encode("utf-8"))
        raise


def _build_sources(relevant_chunks):
    return [
        {
            "documentId": chunk["document_id"],
            "chunkId": chunk["chunk_id"],
            "relevanceScore": round(chunk["score"], 3),
            "preview": chunk["text"][:200] + "..." if len(chunk["text"]) > 200 else chunk["text"],
        }
        for chunk in relevant_chunks[:3]
    ]


def _sse_error(response_stream, message):
    error_sse = json.dumps({"type": "error", "message": message})
    response_stream.write(f"data: {error_sse}\n\n".encode("utf-8"))
    response_stream.write(b"data: [DONE]\n\n")


# ---------- Lambda handler ----------
def handler(event, context, response_stream=None):
    """
    Unified handler supporting both invocation modes:

    Streaming  — Lambda Function URL (invoke_mode=RESPONSE_STREAM):
      The awslambdaric runtime (>= 1.2.0) detects the 3-parameter signature
      and passes a ResponseStream object. Text is pushed to the client token
      by token using SSE format; sources follow after the full answer.

    Sync       — API Gateway proxy / direct lambda.invoke():
      response_stream is None; returns a standard JSON response object.
    """
    is_streaming = response_stream is not None

    # --- Parse body ---
    try:
        if "body" in event:
            body = json.loads(event["body"]) if isinstance(event["body"], str) else event["body"]
        else:
            body = event

        question = body.get("question", "").strip()
        document_id = body.get("documentId")
    except Exception:
        if is_streaming:
            _sse_error(response_stream, "Invalid request body")
            return
        return {
            "statusCode": 400,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"error": "Invalid request body"}),
        }

    if not question:
        if is_streaming:
            _sse_error(response_stream, "Question is required")
            return
        return {
            "statusCode": 400,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"error": "Question is required"}),
        }

    # --- Extract user_id ---
    user_id = None
    if is_streaming:
        # Function URL bypasses API Gateway auth — validate JWT ourselves
        headers = event.get("headers", {})
        auth_header = headers.get("authorization") or headers.get("Authorization", "")
        user_id = extract_user_id_from_bearer_token(auth_header)
        if not user_id:
            _sse_error(response_stream, "Unauthorized")
            return
    else:
        # JWT already validated by API Gateway Cognito authorizer
        if "requestContext" in event and "authorizer" in event["requestContext"]:
            authorizer = event["requestContext"]["authorizer"]
            claims = authorizer.get("jwt", {}).get("claims") or authorizer.get("claims", {})
            user_id = claims.get("sub")

    print(
        f"question={question[:60]!r} document_id={document_id} "
        f"user_id={user_id} streaming={is_streaming}"
    )

    try:
        question_embedding = create_embedding(question)
        relevant_chunks = search_similar_chunks(question_embedding, user_id, document_id)

        if not relevant_chunks:
            no_context = "I couldn't find any relevant information in the uploaded documents to answer your question."
            if is_streaming:
                sse = json.dumps({"type": "text_delta", "text": no_context})
                response_stream.write(f"data: {sse}\n\n".encode("utf-8"))
                response_stream.write(b"data: [DONE]\n\n")
                return
            return {
                "statusCode": 200,
                "headers": {"Content-Type": "application/json"},
                "body": json.dumps({"answer": no_context, "sources": []}),
            }

        print(f"Found {len(relevant_chunks)} relevant chunks")
        sources = _build_sources(relevant_chunks)

        if is_streaming:
            stream_answer_with_bedrock(question, relevant_chunks, response_stream)
            sources_sse = json.dumps({"type": "sources", "sources": sources})
            response_stream.write(f"data: {sources_sse}\n\n".encode("utf-8"))
            response_stream.write(b"data: [DONE]\n\n")
        else:
            answer = generate_answer_with_bedrock(question, relevant_chunks)
            return {
                "statusCode": 200,
                "headers": {"Content-Type": "application/json"},
                "body": json.dumps({"answer": answer, "sources": sources, "question": question}),
            }

    except Exception as e:
        print(f"Error in handler: {str(e)}")
        import traceback
        traceback.print_exc()
        if is_streaming:
            try:
                _sse_error(response_stream, "Internal server error")
            except Exception:
                pass
            return
        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"error": "Internal server error", "message": str(e)}),
        }
