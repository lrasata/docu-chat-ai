# Deployment Guide

This guide walks you through deploying the Serverless Document Chat AI application to AWS.

## Prerequisites

Before you begin, ensure you have:

1. **AWS Account** with administrator access
2. **AWS CLI** configured with credentials
3. **Terraform** >= 1.0 installed
4. **Node.js** >= 18.x for frontend development
5. **Domain name** (optional, but recommended for production)
6. **Bedrock Model Access** enabled in your AWS account

### Enable Bedrock Model Access

1. Navigate to AWS Bedrock console
2. Go to "Model access" in the left sidebar
3. Request access to:
   - **Amazon Titan Embeddings G1 - Text** (required for embeddings)
   - **Anthropic Claude 3 Sonnet** (recommended for chat)
   - Or other LLM models like Claude 3 Haiku or Llama 3

Access is usually granted within minutes.

## Architecture Overview

The application consists of several AWS services:

- **Frontend**: React app hosted on S3 + CloudFront
- **Authentication**: Cognito User Pool with Google OAuth
- **API**: API Gateway + Lambda functions
- **Storage**: S3 for documents, DynamoDB for metadata
- **Vector Search**: OpenSearch Serverless with embeddings
- **AI**: Amazon Bedrock (Titan for embeddings, Claude for chat)

## Deployment Steps

### 1. Clone and Configure

```bash
git clone <your-repo-url>
cd serverless-docu-chat-ai
```

### 2. Configure Variables

Copy the example tfvars file and customize it:

```bash
cd terraform/environments
cp staging.tfvars.example staging.tfvars
```

Edit `staging.tfvars` with your values:

```hcl
# Required changes:
environment = "staging"
region      = "us-east-1"  # Choose your region

# Domain configuration (use your own domain)
api_file_upload_domain_name = "api-staging.your-domain.com"
alt_cloudfront_domain_name  = "staging.your-domain.com"
route53_zone_name          = "your-domain.com"

# SSL Certificate ARN (must be in us-east-1 for CloudFront)
backend_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/your-cert-id"

# Notification email
notification_email = "your-email@your-domain.com"

# Bedrock model (default is Claude 3 Sonnet)
bedrock_model_id = "anthropic.claude-3-sonnet-20240229-v1:0"
```

### 3. Deploy Backend Infrastructure

Deploy in this order:

#### Step 3.1: Deploy Secrets Layer

```bash
cd terraform/layers/secrets
terraform init
terraform apply -var-file="../../environments/staging.tfvars"
```

#### Step 3.2: Deploy Cognito Layer

```bash
cd ../cognito
terraform init
terraform apply -var-file="../../environments/staging.tfvars"
```

**Note:** After Cognito deployment, configure Google OAuth:
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create OAuth 2.0 credentials
3. Add the Cognito callback URL from the Terraform output
4. Update Cognito with Google Client ID and Secret

#### Step 3.3: Deploy Backend Layer

```bash
cd ../backend
terraform init
terraform apply -var-file="../../environments/staging.tfvars"
```

This will create:
- Lambda functions (upload, list, query, s3_ingestion)
- API Gateway with endpoints
- OpenSearch Serverless collection
- S3 bucket for uploads
- DynamoDB table for metadata

**Important:** The first apply might take 10-15 minutes as OpenSearch Serverless provisions.

#### Step 3.4: Deploy Frontend Layer

```bash
cd ../frontend
terraform init
terraform apply -var-file="../../environments/staging.tfvars"
```

This creates:
- S3 bucket for static hosting
- CloudFront distribution
- Route53 DNS records

### 4. Configure Frontend Environment

After backend deployment, get the API Gateway URL:

```bash
cd terraform/layers/backend
terraform output api_gateway_url
```

Create frontend environment file:

```bash
cd frontend/docu-chat-ai
cp .env.example .env
```

Edit `.env`:

```bash
VITE_API_BASE_URL=https://your-api-id.execute-api.us-east-1.amazonaws.com/staging
VITE_COGNITO_USER_POOL_ID=us-east-1_XXXXXXXXX
VITE_COGNITO_CLIENT_ID=xxxxxxxxxxxxxxxxxxxxxxxxxx
VITE_COGNITO_DOMAIN=your-domain.auth.us-east-1.amazoncognito.com
VITE_FILE_UPLOAD_API_URL=https://api-staging.your-domain.com
```

Get these values from Terraform outputs:

```bash
cd terraform/layers/cognito
terraform output
```

### 5. Build and Deploy Frontend

```bash
cd frontend/docu-chat-ai
npm install
npm run build
```

Upload to S3:

```bash
aws s3 sync dist/ s3://your-frontend-bucket/ --delete
```

Invalidate CloudFront cache:

```bash
aws cloudfront create-invalidation \
  --distribution-id YOUR_DISTRIBUTION_ID \
  --paths "/*"
```

### 6. Test the Application

1. Navigate to your CloudFront domain: `https://staging.your-domain.com`
2. Sign in with Google
3. Upload a PDF document
4. Wait for processing (check CloudWatch logs for s3_ingestion Lambda)
5. Go to Chat page and ask questions about your document

## Verification Checklist

After deployment, verify:

- [ ] Frontend loads at CloudFront URL
- [ ] Google sign-in works
- [ ] File upload returns presigned URL
- [ ] S3 ingestion Lambda processes uploaded files
- [ ] OpenSearch index contains document chunks
- [ ] Chat endpoint responds to questions
- [ ] Bedrock API calls succeed (check Lambda logs)

## Troubleshooting

### Lambda Functions Timing Out

**Symptom:** Query Lambda times out after 30 seconds

**Solution:** Increase Lambda timeout and memory:

```hcl
# In terraform/layers/backend/modules/lambda_function/main.tf
timeout     = 120  # seconds
memory_size = 1024 # MB
```

### OpenSearch Access Denied

**Symptom:** Lambda gets 403 errors from OpenSearch

**Solution:** Check data access policy includes Lambda execution role:

```bash
cd terraform/layers/backend/modules/opensearch
# Review main.tf data access policy
```

### Bedrock Throttling

**Symptom:** "ThrottlingException" in Lambda logs

**Solution:**
1. Request service quota increase in AWS Service Quotas
2. Add exponential backoff retry logic to Lambda
3. Consider using reserved capacity for production

### S3 Ingestion Not Triggering

**Symptom:** Files upload but never get indexed

**Solution:**
1. Check S3 bucket notification configuration
2. Verify Lambda has permission to be invoked by S3
3. Check CloudWatch logs for the s3_ingestion Lambda

### CORS Errors

**Symptom:** Frontend can't call API Gateway

**Solution:**
1. Verify API Gateway CORS configuration includes your CloudFront domain
2. Check that Authorization header is allowed
3. Ensure frontend sends correct Origin header

## Monitoring

Key metrics to monitor:

1. **Lambda Invocations**: CloudWatch Metrics for each Lambda
2. **API Gateway 4xx/5xx**: Check for authentication or server errors
3. **OpenSearch Indexing Rate**: Monitor chunk ingestion
4. **Bedrock API Calls**: Track usage and costs
5. **S3 Upload Success Rate**: Monitor presigned URL usage

Set up CloudWatch Alarms for:
- Lambda errors > threshold
- API Gateway 5xx errors
- OpenSearch indexing failures

## Cost Optimization

Expected monthly costs (staging/low usage):

- **Lambda**: ~$5-10 (first 1M requests free)
- **API Gateway**: ~$3.50 per million requests
- **OpenSearch Serverless**: ~$700/month (always-on)
- **Bedrock**: Pay per use
  - Titan Embeddings: $0.0001 per 1K tokens
  - Claude 3 Sonnet: $0.003 per 1K input tokens
- **S3 + CloudFront**: ~$1-5 for low traffic
- **DynamoDB**: ~$1-2 (on-demand)

**Total:** ~$720-750/month for staging

**Production cost optimization:**
- Use Reserved Capacity for OpenSearch
- Enable CloudFront caching
- Implement request caching in Lambda
- Use Bedrock Haiku for cost-sensitive use cases

## Security Best Practices

1. **Enable WAF** on CloudFront and API Gateway
2. **Encrypt at rest**: Enable for S3, DynamoDB, and OpenSearch
3. **Rotate secrets**: Use AWS Secrets Manager for API keys
4. **Least privilege IAM**: Review Lambda execution roles
5. **Enable CloudTrail**: Monitor all API calls
6. **VPC Endpoints**: Use for Bedrock API calls (optional)
7. **MFA**: Enforce for Cognito users in production

## Cleanup

To destroy all resources:

```bash
# Destroy in reverse order
cd terraform/layers/frontend
terraform destroy -var-file="../../environments/staging.tfvars"

cd ../backend
terraform destroy -var-file="../../environments/staging.tfvars"

cd ../cognito
terraform destroy -var-file="../../environments/staging.tfvars"

cd ../secrets
terraform destroy -var-file="../../environments/staging.tfvars"
```

**Warning:** This will delete all data including uploaded documents and indexed content.

## Next Steps

- Set up CI/CD with GitHub Actions (see `.github/workflows/`)
- Configure custom domain with Route53
- Add conversation history to DynamoDB
- Implement streaming responses with WebSockets
- Add multi-document chat support
- Implement citation tracking for answers

## Support

For issues or questions:
1. Check CloudWatch Logs for Lambda functions
2. Review Terraform outputs for endpoint URLs
3. Verify Bedrock model access in AWS Console
4. Check GitHub Issues for known problems
