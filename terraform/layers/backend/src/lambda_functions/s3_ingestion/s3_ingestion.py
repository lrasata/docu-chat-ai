import json
import os
import uuid
import io
import boto3
import pdfplumber
from docx import Document
from opensearchpy import OpenSearch, RequestsHttpConnection
from requests_aws4auth import AWS4Auth

# ---------- AWS clients ----------
s3 = boto3.client("s3")
bedrock = boto3.client("bedrock-runtime")

# ---------- OpenSearch ----------
REGION = os.environ["AWS_REGION"]
OPENSEARCH_HOST = os.environ["OPENSEARCH_ENDPOINT"]
OPENSEARCH_INDEX = os.environ["OPENSEARCH_INDEX"]

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

# ---------- Helpers ----------

def extract_pdf(file_bytes):
    text = ""
    with pdfplumber.open(io.BytesIO(file_bytes)) as pdf:
        for page in pdf.pages:
            page_text = page.extract_text()
            if page_text:
                text += page_text + "\n"
    return text

def extract_docx(file_bytes):
    doc = Document(io.BytesIO(file_bytes))
    return "\n".join(p.text for p in doc.paragraphs)

def extract_text(file_bytes, file_key):
    if file_key.endswith(".pdf"):
        return extract_pdf(file_bytes)
    elif file_key.endswith(".txt"):
        return file_bytes.decode("utf-8")
    elif file_key.endswith(".docx"):
        return extract_docx(file_bytes)
    else:
        raise ValueError("Unsupported file type")

def chunk_text(text, chunk_size=500, overlap=50):
    words = text.split()
    chunks = []
    start = 0

    while start < len(words):
        end = start + chunk_size
        chunk = " ".join(words[start:end])
        if len(chunk.strip()) > 200:
            chunks.append(chunk)
        start = end - overlap

    return chunks

def create_embedding(text):
    response = bedrock.invoke_model(
        modelId="amazon.titan-embed-text-v1",
        contentType="application/json",
        accept="application/json",
        body=json.dumps({"inputText": text})
    )
    body = json.loads(response["body"].read())
    return body["embedding"]

def index_chunk(document_id, chunk_id, chunk_text, embedding):
    doc = {
        "document_id": document_id,
        "chunk_id": chunk_id,
        "text": chunk_text,
        "embedding": embedding
    }

    os_client.index(
        index=OPENSEARCH_INDEX,
        body=doc
    )

# ---------- Ensure OpenSearch index exists ----------

def ensure_index():
    if not os_client.indices.exists(index=OPENSEARCH_INDEX):
        os_client.indices.create(
            index=OPENSEARCH_INDEX,
            body={
                "settings": {"index.knn": True},
                "mappings": {
                    "properties": {
                        "embedding": {
                            "type": "knn_vector",
                            "dimension": 1536
                        },
                        "text": {"type": "text"},
                        "document_id": {"type": "keyword"},
                        "chunk_id": {"type": "keyword"}
                    }
                }
            }
        )
        print(f"Created OpenSearch index: {OPENSEARCH_INDEX}")
    else:
        print(f"OpenSearch index already exists: {OPENSEARCH_INDEX}")

# ---------- Lambda handler ----------

# Ensure index exists on cold start
ensure_index()

def handler(event, context):
    record = event["Records"][0]
    bucket = record["s3"]["bucket"]["name"]
    key = record["s3"]["object"]["key"]

    print(f"Processing file: s3://{bucket}/{key}")

    # 1️⃣ Read file
    response = s3.get_object(Bucket=bucket, Key=key)
    file_bytes = response["Body"].read()

    # 2️⃣ Extract text
    text = extract_text(file_bytes, key)
    if not text or len(text.strip()) < 100:
        raise Exception("Extracted text is empty or too short")

    # 3️⃣ Chunk text
    chunks = chunk_text(text)
    print(f"Created {len(chunks)} chunks")

    document_id = str(uuid.uuid4())

    # 4️⃣ Embed & index
    for idx, chunk in enumerate(chunks):
        embedding = create_embedding(chunk)
        chunk_id = f"{document_id}-{idx}"
        index_chunk(document_id, chunk_id, chunk, embedding)

    print("Document ingestion completed successfully")

    return {
        "statusCode": 200,
        "body": json.dumps({
            "document_id": document_id,
            "chunks_indexed": len(chunks)
        })
    }
