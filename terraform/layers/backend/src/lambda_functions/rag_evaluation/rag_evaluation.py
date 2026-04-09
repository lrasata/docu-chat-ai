import json
import os
import time
import boto3
from botocore.exceptions import ClientError

# ---------- AWS clients (module-level for connection reuse) ----------
s3 = boto3.client("s3")
dynamodb = boto3.client("dynamodb")
lambda_client = boto3.client("lambda")

# ---------- Environment variables ----------
REGION = os.environ["REGION"]
UPLOADS_BUCKET = os.environ["UPLOADS_BUCKET"]
DOCUMENTS_TABLE = os.environ["DOCUMENTS_TABLE"]
QUERY_DOCUMENT_LAMBDA_NAME = os.environ["QUERY_DOCUMENT_LAMBDA_NAME"]
EVAL_MODEL_ARN = os.environ.get("EVAL_MODEL_ARN", "anthropic.claude-opus-4-5")
RESULTS_BUCKET = os.environ.get("RESULTS_BUCKET", UPLOADS_BUCKET)

# ---------- Constants ----------
FILE_NAME = "rfc7519.pdf"
EVAL_DOC_S3_KEY = f"uploads/resources/rag_eval/{FILE_NAME}"
LOCAL_PDF_PATH = os.path.join(os.path.dirname(__file__), "docs", FILE_NAME)

GOLDEN_DATASET_FILE = "rfc7519_golden_dataset.json"
LOCAL_DATASET_PATH = os.path.join(os.path.dirname(__file__), "datasets", GOLDEN_DATASET_FILE)
RESULTS_S3_KEY = f"evals/{os.path.splitext(FILE_NAME)[0]}_eval_results.json"

MAX_WAIT_SECONDS = 600  # 10 minutes for ingestion
POLL_INTERVAL_SECONDS = 15


# ---------- Step 1 helpers: ensure document is uploaded and indexed ----------

def is_document_indexed():
    """
    Scan DynamoDB for the eval document with status=indexed.
    Uses a scan because we only know file_key (sort key), not id (partition key).
    """
    response = dynamodb.scan(
        TableName=DOCUMENTS_TABLE,
        FilterExpression="file_key = :fk AND #s = :status",
        ExpressionAttributeNames={"#s": "status"},
        ExpressionAttributeValues={
            ":fk": {"S": EVAL_DOC_S3_KEY},
            ":status": {"S": "indexed"},
        },
        Limit=1,
    )
    return len(response.get("Items", [])) > 0


def file_exists_in_s3():
    try:
        s3.head_object(Bucket=UPLOADS_BUCKET, Key=EVAL_DOC_S3_KEY)
        return True
    except ClientError as e:
        code = e.response["Error"]["Code"]
        # S3 returns 403 instead of 404 when the object is missing and the caller
        # lacks s3:ListBucket. Treat it as "not found" — if there is a genuine
        # permission problem the subsequent put_object will fail with a clear error.
        if code in ("404", "403", "NoSuchKey"):
            return False
        raise


def upload_eval_document():
    print(f"Uploading {FILE_NAME} to s3://{UPLOADS_BUCKET}/{EVAL_DOC_S3_KEY}")
    with open(LOCAL_PDF_PATH, "rb") as f:
        s3.put_object(
            Bucket=UPLOADS_BUCKET,
            Key=EVAL_DOC_S3_KEY,
            Body=f,
            ContentType="application/pdf",
        )
    print("Upload complete — waiting for S3 event to trigger ingestion pipeline.")


def wait_for_indexing():
    """
    Poll DynamoDB until the document status is 'indexed' or the timeout is reached.
    The upload triggers process_uploaded_file (S3 event) → SNS → s3_ingestion Lambda,
    which sets status='indexed' in DynamoDB when all chunks are committed.
    """
    print(f"Polling for indexing completion (timeout: {MAX_WAIT_SECONDS}s, interval: {POLL_INTERVAL_SECONDS}s)...")
    elapsed = 0
    while elapsed < MAX_WAIT_SECONDS:
        if is_document_indexed():
            print(f"Document indexed after ~{elapsed}s.")
            return
        time.sleep(POLL_INTERVAL_SECONDS)
        elapsed += POLL_INTERVAL_SECONDS
        print(f"  Still ingesting... ({elapsed}s elapsed)")

    raise TimeoutError(
        f"Document '{EVAL_DOC_S3_KEY}' was not indexed within {MAX_WAIT_SECONDS}s. "
        "Check that the S3 bucket notification is configured for the 'resources/' prefix "
        "and that the s3_ingestion Lambda completed without errors."
    )


def ensure_document_ready():
    """
    Idempotent: skip upload and wait if the document is already indexed.
    Otherwise upload (if needed) and wait for indexing to complete.
    """
    if is_document_indexed():
        print(f"Document already indexed at '{EVAL_DOC_S3_KEY}'. Skipping upload.")
        return

    if not file_exists_in_s3():
        upload_eval_document()
    else:
        print(f"File already in S3 at '{EVAL_DOC_S3_KEY}' but not yet indexed. Waiting...")

    wait_for_indexing()


# ---------- Step 2 helper: call query_document Lambda ----------

def call_query_endpoint(question, document_id):
    """
    Invoke the query_document Lambda directly (bypasses API Gateway JWT auth).
    The Lambda accepts both API Gateway proxy events and plain dicts, so we wrap
    the payload in 'body' to match the API Gateway proxy integration format.
    """
    payload = {
        "body": json.dumps({"question": question, "documentId": document_id})
    }
    response = lambda_client.invoke(
        FunctionName=QUERY_DOCUMENT_LAMBDA_NAME,
        InvocationType="RequestResponse",
        Payload=json.dumps(payload).encode(),
    )
    result = json.loads(response["Payload"].read())
    if result.get("statusCode") != 200:
        print(f"  Warning: query Lambda returned statusCode={result.get('statusCode')}")
    body = json.loads(result.get("body", "{}"))
    return body.get("answer", "No answer returned")


# ---------- Step 3 helper: LLM-as-judge via Bedrock ----------

def judge_answer(question, expected_answer, generated_answer, bedrock_client):
    prompt = f"""You are evaluating a RAG system. Score the generated answer on these dimensions.

Question: {question}
Expected answer: {expected_answer if expected_answer else "No answer exists in the documents"}
Generated answer: {generated_answer}

Score each dimension 1-5 and respond ONLY in valid JSON, no extra text:
{{
  "faithfulness": <1-5, is the answer grounded or hallucinated>,
  "correctness": <1-5, does it match the expected answer>,
  "handles_unknown": <1-5, if expected is null did it correctly say it doesn't know - otherwise set 5>,
  "reasoning": "<one sentence explanation>"
}}"""

    response = bedrock_client.invoke_model(
        modelId=EVAL_MODEL_ARN,
        contentType="application/json",
        accept="application/json",
        body=json.dumps({
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": 300,
            "temperature": 0,
            "messages": [{"role": "user", "content": prompt}],
        }),
    )
    result = json.loads(response["body"].read())
    return json.loads(result["content"][0]["text"])


# ---------- Lambda handler ----------

def handler(event, context):
    bedrock_client = boto3.client("bedrock-runtime", region_name=REGION)

    # --- Step 1: Upload file if not already indexed ---
    ensure_document_ready()

    # --- Step 2: Load golden dataset (bundled in Lambda package) ---
    with open(LOCAL_DATASET_PATH, "r") as f:
        golden = json.load(f)

    print(f"Loaded {len(golden)} questions from golden dataset.")

    results = []

    # --- Step 3: Query and judge each question ---
    for i, item in enumerate(golden):
        question = item["question"]
        expected = item.get("expected_answer")
        print(f"[{i + 1}/{len(golden)}] {question}")

        generated = call_query_endpoint(question, EVAL_DOC_S3_KEY)
        scores = judge_answer(question, expected, generated, bedrock_client)

        results.append({
            "question": question,
            "type": item.get("type"),
            "source_hint": item.get("source_hint"),
            "expected": expected,
            "generated": generated,
            "scores": scores,
        })

    # --- Step 4: Compute summary ---
    avg_faithfulness = sum(r["scores"]["faithfulness"] for r in results) / len(results)
    avg_correctness = sum(r["scores"]["correctness"] for r in results) / len(results)
    avg_handles_unknown = sum(r["scores"]["handles_unknown"] for r in results) / len(results)

    summary = {
        "avg_faithfulness": round(avg_faithfulness, 2),
        "avg_correctness": round(avg_correctness, 2),
        "avg_handles_unknown": round(avg_handles_unknown, 2),
        "total_questions": len(results),
        "detail": results,
    }

    # --- Step 5: Persist results to S3 ---
    s3.put_object(
        Bucket=RESULTS_BUCKET,
        Key=RESULTS_S3_KEY,
        Body=json.dumps(summary, indent=2),
        ContentType="application/json",
    )
    print(f"Results saved to s3://{RESULTS_BUCKET}/{RESULTS_S3_KEY}")

    return {
        "statusCode": 200,
        "body": json.dumps(summary),
    }
