# Testing Guide: Bedrock Chat Integration

## Branch Information

**Branch Name:** `feature/bedrock-chat-integration`

**Pull Request:** [Create PR on GitHub](https://github.com/lrasata/serverless-docu-chat-ai/pull/new/feature/bedrock-chat-integration)

## What's in This Branch

All the changes needed to complete your document chat AI with AWS Bedrock:

### Backend Changes:
- ✅ New Lambda function: `query_document` (Bedrock chat handler)
- ✅ API Gateway endpoint: `POST /chat`
- ✅ IAM permissions for Bedrock access
- ✅ OpenSearch data access policy
- ✅ Terraform configuration updates

### Frontend Changes:
- ✅ Chat API client (`chatApi.ts`)
- ✅ Real API integration in ChatPage
- ✅ Source citations display
- ✅ Loading states and error handling

### Documentation:
- ✅ DEPLOYMENT.md (complete deployment guide)
- ✅ IMPLEMENTATION_SUMMARY.md (what was built)
- ✅ Updated README.md
- ✅ Configuration examples (.tfvars)

## Prerequisites for Testing

### 1. AWS Account Setup

**Enable Bedrock Model Access:**
```bash
# Go to AWS Console → Bedrock → Model access
# Request access to:
# - Amazon Titan Embeddings G1 - Text
# - Anthropic Claude 3 Sonnet
```

This usually takes 5-10 minutes to be approved.

**Verify Access:**
```bash
aws bedrock list-foundation-models --region us-east-1 \
  --query 'modelSummaries[?modelId==`amazon.titan-embed-text-v1` || modelId==`anthropic.claude-3-sonnet-20240229-v1:0`]'
```

### 2. AWS Credentials

Ensure your AWS CLI is configured:
```bash
aws sts get-caller-identity
```

### 3. Domain and SSL Certificate

You'll need:
- A Route53 hosted zone
- An ACM certificate in `us-east-1` (for CloudFront)

## Testing Steps

### Option A: Deploy to Staging (Recommended)

**Step 1: Configure Variables**
```bash
cd terraform/environments
cp staging.tfvars.example staging.tfvars
```

Edit `staging.tfvars` with your values:
```hcl
environment = "staging"
region      = "us-east-1"
app_id      = "docu-chat-ai"

# Your domain configuration
api_file_upload_domain_name = "api-staging.your-domain.com"
alt_cloudfront_domain_name  = "staging.your-domain.com"
route53_zone_name          = "your-domain.com"

# Your ACM certificate ARN
backend_certificate_arn = "arn:aws:acm:us-east-1:YOUR_ACCOUNT:certificate/YOUR_CERT_ID"

# Your email
notification_email = "your-email@your-domain.com"

# Bedrock configuration
bedrock_model_id = "anthropic.claude-3-sonnet-20240229-v1:0"
max_search_results = 5
```

**Step 2: Deploy Backend Infrastructure**
```bash
# Deploy in order:
cd terraform/layers/secrets
terraform init
terraform apply -var-file="../../environments/staging.tfvars"

cd ../cognito
terraform init
terraform apply -var-file="../../environments/staging.tfvars"

cd ../backend
terraform init
terraform apply -var-file="../../environments/staging.tfvars"
```

**Step 3: Get API Gateway URL**
```bash
cd terraform/layers/backend
terraform output api_gateway_url
# Copy this URL for frontend configuration
```

**Step 4: Configure Frontend**
```bash
cd frontend/docu-chat-ai
cp .env.example .env
```

Edit `.env`:
```bash
VITE_API_BASE_URL=https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/staging
VITE_COGNITO_USER_POOL_ID=us-east-1_XXXXXXXXX
VITE_COGNITO_CLIENT_ID=xxxxxxxxxxxxxxxxxxxxxxxxxx
VITE_COGNITO_DOMAIN=your-domain.auth.us-east-1.amazoncognito.com
```

Get Cognito values:
```bash
cd terraform/layers/cognito
terraform output
```

**Step 5: Test Locally First**
```bash
cd frontend/docu-chat-ai
npm install
npm run dev
```

Open [http://localhost:5173](http://localhost:5173) and test:
1. Sign in with Google
2. Upload a test PDF
3. Go to Chat page
4. Ask a question about the document

**Step 6: Check Lambda Logs**
```bash
# Watch the ingestion Lambda (after uploading)
aws logs tail /aws/lambda/staging-docu-chat-ai-s3-ingestion --follow

# Watch the query Lambda (after asking a question)
aws logs tail /aws/lambda/staging-docu-chat-ai-query-document --follow
```

### Option B: Local Testing (Lambda Only)

You can test the Lambda function locally before deploying:

**Test Query Lambda:**
```bash
cd terraform/layers/backend/src/lambda_functions/query_document
pip install -r requirements.txt

# Set environment variables
export AWS_REGION=us-east-1
export OPENSEARCH_ENDPOINT=your-opensearch-endpoint.us-east-1.aoss.amazonaws.com
export OPENSEARCH_INDEX=staging-docu-chat-ai-index
export DOCUMENTS_TABLE=staging-docu-chat-ai-documents
export BEDROCK_MODEL_ID=anthropic.claude-3-sonnet-20240229-v1:0

# Test the function
python3 -c "
from query_document import handler
event = {
    'body': '{\"question\": \"What is this document about?\"}',
    'requestContext': {
        'authorizer': {
            'jwt': {
                'claims': {
                    'sub': 'test-user-id'
                }
            }
        }
    }
}
result = handler(event, None)
print(result)
"
```

## Verification Checklist

After deployment, verify each component:

### 1. Document Ingestion Pipeline
- [ ] Upload a PDF via the frontend
- [ ] Check S3 bucket has the file: `aws s3 ls s3://your-uploads-bucket/`
- [ ] Check S3 ingestion Lambda logs for successful processing
- [ ] Verify OpenSearch index has documents:
```bash
aws opensearchserverless list-collections
```

### 2. Chat Functionality
- [ ] Ask a question in the chat interface
- [ ] Verify query Lambda is invoked (check CloudWatch logs)
- [ ] Check for Bedrock API calls in logs
- [ ] Verify answer is relevant to document content
- [ ] Check that sources are displayed with relevance scores

### 3. Error Handling
- [ ] Ask a question before uploading any documents (should get "no relevant information" message)
- [ ] Try uploading an invalid file type (should fail gracefully)
- [ ] Test with network disconnected (should show error message)

## Common Issues and Solutions

### Issue: Lambda Timeout
**Symptom:** Query takes longer than 30 seconds
**Solution:**
```hcl
# In terraform/layers/backend/modules/lambda_function/main.tf
timeout     = 120
memory_size = 1024
```

### Issue: Bedrock AccessDeniedException
**Symptom:** `AccessDeniedException: Could not access model`
**Solution:**
1. Verify model access in Bedrock console
2. Check IAM role has `bedrock:InvokeModel` permission
3. Ensure correct model ID format

### Issue: OpenSearch 403 Forbidden
**Symptom:** `AccessDenied: User is not authorized`
**Solution:**
Check data access policy in `terraform/layers/backend/modules/opensearch/main.tf`

### Issue: Frontend CORS Error
**Symptom:** `CORS policy: No 'Access-Control-Allow-Origin'`
**Solution:**
Verify API Gateway CORS configuration includes your CloudFront domain

## Performance Testing

### Test Query Latency
```bash
# Time a chat request
time curl -X POST https://your-api-gateway-url/chat \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"question": "What is this document about?"}'
```

Expected latency:
- Embedding creation: ~200ms
- OpenSearch search: ~100-300ms
- Bedrock inference: ~2-5 seconds
- **Total: ~3-6 seconds**

### Load Testing (Optional)
```bash
# Install Apache Bench
sudo apt-get install apache2-utils

# Test 100 requests with 10 concurrent
ab -n 100 -c 10 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -p question.json \
  https://your-api-gateway-url/chat
```

## Monitoring During Testing

### CloudWatch Logs
```bash
# Query Lambda logs
aws logs tail /aws/lambda/staging-docu-chat-ai-query-document --follow

# S3 Ingestion Lambda logs
aws logs tail /aws/lambda/staging-docu-chat-ai-s3-ingestion --follow

# API Gateway logs
aws logs tail /aws/apigateway/staging-docu-chat-ai-api-gateway --follow
```

### CloudWatch Metrics
Key metrics to watch:
- Lambda Duration
- Lambda Errors
- API Gateway 4xx/5xx errors
- Bedrock InvokedModels

### Cost Monitoring
```bash
# Check current month costs
aws ce get-cost-and-usage \
  --time-period Start=$(date +%Y-%m-01),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=SERVICE
```

## Success Criteria

Your implementation is successful if:

1. ✅ Document uploads and appears in S3
2. ✅ S3 ingestion Lambda processes without errors
3. ✅ OpenSearch index contains document chunks
4. ✅ Chat endpoint responds in < 10 seconds
5. ✅ Answers are contextually relevant
6. ✅ Sources are displayed with correct document IDs
7. ✅ No errors in CloudWatch logs
8. ✅ Costs align with estimates (~$1-2 for testing)

## Next Steps After Testing

### 1. Create Pull Request
Once testing is successful:
- Go to: [Create PR](https://github.com/lrasata/serverless-docu-chat-ai/pull/new/feature/bedrock-chat-integration)
- Add description of changes
- Request review
- Merge to main

### 2. Deploy to Production
```bash
# Use prod.tfvars
cd terraform/environments
cp prod.tfvars.example prod.tfvars
# Edit with production settings

# Deploy to prod
terraform apply -var-file="../../environments/prod.tfvars"
```

### 3. Set Up Monitoring
- CloudWatch alarms for Lambda errors
- Cost alerts in AWS Budgets
- API Gateway throttling alerts

### 4. Enable Enhancements
Consider implementing:
- Conversation history
- Multi-document chat
- Streaming responses
- Advanced analytics

## Getting Help

If you encounter issues:

1. **Check Logs First:**
```bash
aws logs tail /aws/lambda/staging-docu-chat-ai-query-document --follow
```

2. **Validate Terraform:**
```bash
cd terraform/layers/backend
terraform validate
terraform plan
```

3. **Test Lambda Directly:**
```bash
aws lambda invoke \
  --function-name staging-docu-chat-ai-query-document \
  --payload '{"body": "{\"question\": \"test\"}"}' \
  response.json
cat response.json
```

4. **Review Documentation:**
- [DEPLOYMENT.md](./DEPLOYMENT.md) - Detailed deployment steps
- [IMPLEMENTATION_SUMMARY.md](./IMPLEMENTATION_SUMMARY.md) - What was built
- [AWS Bedrock Docs](https://docs.aws.amazon.com/bedrock/)

## Feedback

After testing, please note:
- What worked well?
- What needs improvement?
- Any performance issues?
- Documentation gaps?

This will help refine the implementation before merging to main.

---

**Branch:** `feature/bedrock-chat-integration`
**Status:** Ready for Testing
**Estimated Test Time:** 2-3 hours (including deployment)
