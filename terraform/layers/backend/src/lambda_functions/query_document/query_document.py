import json
import os
import boto3
from opensearchpy import OpenSearch, RequestsHttpConnection
from requests_aws4auth import AWS4Auth

# ---------- Environment variables ----------
REGION = os.environ.get("REGION", os.environ.get("AWS_REGION", "eu-central-1"))
OPENSEARCH_HOST = os.environ["OPENSEARCH_ENDPOINT"].replace("https://", "").replace("http://", "")
OPENSEARCH_INDEX = os.environ["OPENSEARCH_INDEX"]
DOCUMENTS_TABLE = os.environ["DOCUMENTS_TABLE"]
BEDROCK_MODEL_INFERENCE_PROFILE_ARN = os.environ.get("BEDROCK_MODEL_INFERENCE_PROFILE_ARN", "anthropic.claude-sonnet-4-20250514-v1:0")
MAX_RESULTS = int(os.environ.get("MAX_SEARCH_RESULTS", "5"))

# ---------- AWS clients ----------
bedrock_runtime = boto3.client("bedrock-runtime", region_name=REGION)
dynamodb = boto3.client("dynamodb", region_name=REGION)

# ---------- OpenSearch client ----------
credentials = boto3.Session().get_credentials()

auth = AWS4Auth(
    credentials.access_key,
    credentials.secret_key,
    REGION,
    "aoss",
    session_token=credentials.token
)

os_client = OpenSearch(
    hosts=[{"host": OPENSEARCH_HOST, "port": 443}],
    http_auth=auth,
    use_ssl=True,
    verify_certs=True,
    connection_class=RequestsHttpConnection
)

# ---------- Helper functions ----------

def create_embedding(text):
    """Create embedding using Amazon Titan Embeddings model"""
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


def search_similar_chunks(question_embedding, document_id=None, max_results=MAX_RESULTS):
    """Search for similar document chunks using KNN vector search"""
    try:
        query_body = {
            "size": max_results,
            "query": {
                "bool": {
                    "must": [
                        {
                            "knn": {
                                "embedding": {
                                    "vector": question_embedding,
                                    "k": max_results
                                }
                            }
                        }
                    ]
                }
            },
            "_source": ["text", "document_id", "chunk_id"]
        }

        # Filter by document_id if provided
        if document_id:
            query_body["query"]["bool"]["filter"] = [
                {"term": {"document_id": document_id}}
            ]

        response = os_client.search(
            index=OPENSEARCH_INDEX,
            body=query_body
        )

        chunks = []
        for hit in response["hits"]["hits"]:
            chunks.append({
                "text": hit["_source"]["text"],
                "document_id": hit["_source"]["document_id"],
                "chunk_id": hit["_source"]["chunk_id"],
                "score": hit["_score"]
            })

        return chunks
    except Exception as e:
        print(f"Error searching OpenSearch: {str(e)}")
        raise


def get_document_metadata(document_id, user_id):
    """Get document metadata from DynamoDB"""
    try:
        response = dynamodb.get_item(
            TableName=DOCUMENTS_TABLE,
            Key={
                "userId": {"S": user_id},
                "documentId": {"S": document_id}
            }
        )

        if "Item" in response:
            return {
                "fileName": response["Item"].get("fileName", {}).get("S", "Unknown"),
                "uploadedAt": response["Item"].get("uploadedAt", {}).get("S", "")
            }
        return None
    except Exception as e:
        print(f"Error fetching document metadata: {str(e)}")
        return None


def generate_answer_with_bedrock(question, context_chunks, model_id=BEDROCK_MODEL_INFERENCE_PROFILE_ARN):
    """Generate answer using Bedrock LLM (Claude)"""
    try:
        # Build context from retrieved chunks
        context = "\n\n".join([f"[Chunk {i+1}]\n{chunk['text']}" for i, chunk in enumerate(context_chunks)])

        # Construct prompt
        prompt = f"""You are a helpful AI assistant that answers questions based on the provided document context.
Only use information from the context below to answer the question. If the answer cannot be found in the context, say so.

Context:
{context}

Question: {question}

Answer:"""

        # Call Bedrock - Claude 4 format
        request_body = {
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": 2000,
            "temperature": 0.7,
            "messages": [
                {
                    "role": "user",
                    "content": prompt
                }
            ]
        }

        response = bedrock_runtime.invoke_model(
            modelId=model_id,
            contentType="application/json",
            accept="application/json",
            body=json.dumps(request_body)
        )

        response_body = json.loads(response["body"].read())

        # Extract answer from Claude response
        answer = response_body["content"][0]["text"]

        return answer
    except Exception as e:
        print(f"Error calling Bedrock: {str(e)}")
        raise


# ---------- Lambda handler ----------

def handler(event, context):
    """
    Main Lambda handler for document Q&A

    Expected input:
    {
        "question": "What is this document about?",
        "documentId": "optional-document-id" (if omitted, searches all documents)
    }
    """
    try:
        # Parse request
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

        # Get user ID from authorizer (if available)
        user_id = None
        if "requestContext" in event and "authorizer" in event["requestContext"]:
            user_id = event["requestContext"]["authorizer"].get("jwt", {}).get("claims", {}).get("sub")

        print(f"Processing question: {question}")
        print(f"Document ID: {document_id}")
        print(f"User ID: {user_id}")

        # Step 1: Create embedding for the question
        question_embedding = create_embedding(question)

        # Step 2: Search for relevant document chunks
        relevant_chunks = search_similar_chunks(question_embedding, document_id)

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

        # Step 3: Generate answer using Bedrock
        answer = generate_answer_with_bedrock(question, relevant_chunks)

        # Step 4: Prepare sources information
        sources = []
        for chunk in relevant_chunks[:3]:  # Return top 3 sources
            sources.append({
                "documentId": chunk["document_id"],
                "chunkId": chunk["chunk_id"],
                "relevanceScore": round(chunk["score"], 3),
                "preview": chunk["text"][:200] + "..." if len(chunk["text"]) > 200 else chunk["text"]
            })

        # Return response
        return {
            "statusCode": 200,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({
                "answer": answer,
                "sources": sources,
                "question": question
            })
        }

    except Exception as e:
        print(f"Error in handler: {str(e)}")
        import traceback
        traceback.print_exc()

        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({
                "error": "Internal server error",
                "message": str(e)
            })
        }
