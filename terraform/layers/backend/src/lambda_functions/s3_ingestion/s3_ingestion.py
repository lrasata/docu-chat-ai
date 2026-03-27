import json
import os
import io
import boto3
import psycopg2
import pdfplumber
from docx import Document
from pgvector.psycopg2 import register_vector

# ---------- AWS clients ----------
s3 = boto3.client("s3")
bedrock = boto3.client("bedrock-runtime")
secretsmanager = boto3.client("secretsmanager")
dynamodb = boto3.client("dynamodb", region_name=os.environ["REGION"])

REGION = os.environ["REGION"]
RDS_SECRET_ARN = os.environ["RDS_SECRET_ARN"]
DOCUMENTS_TABLE = os.environ["DOCUMENTS_TABLE"]

# ---------- Connection cache (survives warm invocations) ----------
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
    _db_conn.autocommit = False
    register_vector(_db_conn)
    return _db_conn

def ensure_table():
    conn = get_db_connection()
    with conn.cursor() as cur:
        cur.execute("CREATE EXTENSION IF NOT EXISTS vector;")
        cur.execute("""
            CREATE TABLE IF NOT EXISTS document_chunks (
                id          BIGSERIAL PRIMARY KEY,
                document_id TEXT         NOT NULL,
                chunk_id    TEXT         NOT NULL UNIQUE,
                content     TEXT         NOT NULL,
                embedding   vector(1536) NOT NULL
            );
        """)
        cur.execute("""
            CREATE INDEX IF NOT EXISTS document_chunks_embedding_idx
            ON document_chunks
            USING ivfflat (embedding vector_cosine_ops)
            WITH (lists = 100);
        """)
        cur.execute("""
            CREATE INDEX IF NOT EXISTS document_chunks_document_id_idx
            ON document_chunks (document_id);
        """)
    conn.commit()
    print("Table and indexes ensured")

# ---------- Text extraction helpers ----------
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

def index_chunk(conn, document_id, chunk_id, chunk_text_content, embedding):
    with conn.cursor() as cur:
        cur.execute(
            """
            INSERT INTO document_chunks (document_id, chunk_id, content, embedding)
            VALUES (%s, %s, %s, %s)
            ON CONFLICT (chunk_id) DO UPDATE
              SET content = EXCLUDED.content,
                  embedding = EXCLUDED.embedding;
            """,
            (document_id, chunk_id, chunk_text_content, embedding)
        )

# ---------- Cold-start initialization ----------
ensure_table()

# ---------- Lambda handler ----------
def handler(event, context):
    sns_record = event["Records"][0]["Sns"]
    message = json.loads(sns_record["Message"])
    print(f"Received SNS message: {json.dumps(message)}")

    bucket = message["bucket"]
    key = message["fileKey"]
    print(f"Processing file: s3://{bucket}/{key}")

    response = s3.get_object(Bucket=bucket, Key=key)
    file_bytes = response["Body"].read()

    text = extract_text(file_bytes, key)
    if not text or len(text.strip()) < 100:
        raise Exception("Extracted text is empty or too short")

    chunks = chunk_text(text)
    print(f"Created {len(chunks)} chunks")

    document_id = key
    conn = get_db_connection()

    for idx, chunk in enumerate(chunks):
        embedding = create_embedding(chunk)
        chunk_id = f"{document_id}-{idx}"
        index_chunk(conn, document_id, chunk_id, chunk, embedding)

    conn.commit()
    print("Document ingestion completed successfully")

    dynamodb.update_item(
        TableName=DOCUMENTS_TABLE,
        Key={
            "id": {"S": message["partitionKey"]},
            "file_key": {"S": key}
        },
        UpdateExpression="SET document_id = :doc_id",
        ExpressionAttributeValues={":doc_id": {"S": document_id}}
    )

    return {
        "statusCode": 200,
        "body": json.dumps({"document_id": document_id, "chunks_indexed": len(chunks)})
    }