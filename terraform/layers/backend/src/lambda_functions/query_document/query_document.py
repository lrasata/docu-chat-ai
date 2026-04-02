import json
import os
import boto3
import psycopg2
from pgvector.psycopg2 import register_vector

# ---------- Environment variables ----------
REGION = os.environ["REGION"]
RDS_SECRET_ARN = os.environ["RDS_SECRET_ARN"]
DOCUMENTS_TABLE = os.environ["DOCUMENTS_TABLE"]
BEDROCK_MODEL_INFERENCE_PROFILE_ARN = os.environ.get(
    "BEDROCK_MODEL_INFERENCE_PROFILE_ARN", "anthropic.claude-sonnet-4-20250514-v1:0"
)
MAX_RESULTS = int(os.environ.get("MAX_SEARCH_RESULTS", "5"))
BEDROCK_GUARDRAIL_ID = os.environ.get("BEDROCK_GUARDRAIL_ID")
BEDROCK_GUARDRAIL_VERSION = os.environ.get("BEDROCK_GUARDRAIL_VERSION", "1")

# ---------- AWS clients ----------
bedrock_runtime = boto3.client("bedrock-runtime", region_name=REGION)
dynamodb = boto3.client("dynamodb", region_name=REGION)
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

# ---------- Helper functions ----------
def create_embedding(text):
    try:
        response = bedrock_runtime.invoke_model(
            modelId="amazon.titan-embed-text-v1",
            contentType="application/json",
            accept="application/json",
            body=json.dumps({"inputText": text})
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
                    (question_embedding, document_id, question_embedding, max_results)
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
                    (question_embedding, f"uploads/users/{user_id}/%", question_embedding, max_results)
                )
            rows = cur.fetchall()

        return [
            {"document_id": r[0], "chunk_id": r[1], "text": r[2], "score": float(r[3])}
            for r in rows
        ]
    except Exception as e:
        print(f"Error searching pgvector: {str(e)}")
        raise

def generate_answer_with_bedrock(question, context_chunks, model_id=BEDROCK_MODEL_INFERENCE_PROFILE_ARN):
    try:
        context = "\n\n".join([f"[Chunk {i+1}]\n{chunk['text']}" for i, chunk in enumerate(context_chunks)])
        prompt = f"""You are a helpful AI assistant that answers questions based on the provided document context.
Only use information from the context below to answer the question. If the answer cannot be found in the context, say so.

Context:
{context}

Question: {question}

Answer:"""
        request_body = {
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": 2000,
            "temperature": 0.7,
            "messages": [{"role": "user", "content": prompt}]
        }
        invoke_kwargs = {
            "modelId": model_id,
            "contentType": "application/json",
            "accept": "application/json",
            "body": json.dumps(request_body),
        }
        if BEDROCK_GUARDRAIL_ID:
            invoke_kwargs["guardrailIdentifier"] = BEDROCK_GUARDRAIL_ID
            invoke_kwargs["guardrailVersion"] = BEDROCK_GUARDRAIL_VERSION

        response = bedrock_runtime.invoke_model(**invoke_kwargs)
        response_body = json.loads(response["body"].read())
        return response_body["content"][0]["text"]
    except Exception as e:
        print(f"Error calling Bedrock: {str(e)}")
        raise

# ---------- Lambda handler ----------
def handler(event, context):
    try:
        if "body" in event:
            body = json.loads(event["body"]) if isinstance(event["body"], str) else event["body"]
        else:
            body = event

        question = body.get("question", "").strip()
        document_id = body.get("documentId")

        if not question:
            return {
                "statusCode": 400,
                "headers": {"Content-Type": "application/json"},
                "body": json.dumps({"error": "Question is required"})
            }

        user_id = None
        if "requestContext" in event and "authorizer" in event["requestContext"]:
            authorizer = event["requestContext"]["authorizer"]
            claims = authorizer.get("jwt", {}).get("claims") or authorizer.get("claims", {})
            user_id = claims.get("sub")

        print(f"Processing question: {question}, document_id: {document_id}, user_id: {user_id}")

        question_embedding = create_embedding(question)
        relevant_chunks = search_similar_chunks(question_embedding, user_id, document_id)

        if not relevant_chunks:
            return {
                "statusCode": 200,
                "headers": {"Content-Type": "application/json"},
                "body": json.dumps({
                    "answer": "I couldn't find any relevant information in the uploaded documents to answer your question.",
                    "sources": []
                })
            }

        print(f"Found {len(relevant_chunks)} relevant chunks")
        answer = generate_answer_with_bedrock(question, relevant_chunks)

        sources = []
        for chunk in relevant_chunks[:3]:
            sources.append({
                "documentId": chunk["document_id"],
                "chunkId": chunk["chunk_id"],
                "relevanceScore": round(chunk["score"], 3),
                "preview": chunk["text"][:200] + "..." if len(chunk["text"]) > 200 else chunk["text"]
            })

        return {
            "statusCode": 200,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"answer": answer, "sources": sources, "question": question})
        }

    except Exception as e:
        print(f"Error in handler: {str(e)}")
        import traceback
        traceback.print_exc()
        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"error": "Internal server error", "message": str(e)})
        }