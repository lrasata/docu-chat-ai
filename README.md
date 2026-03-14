# AI Powered Document Chat App

![Staging Backend - Deployment pipeline](https://github.com/lrasata/serverless-docu-chat-ai/actions/workflows/deploy-backend-to-staging.yml/badge.svg)
![Staging Frontend - Deployment pipeline](https://github.com/lrasata/serverless-docu-chat-ai/actions/workflows/deploy-frontend-to-staging.yml/badge.svg)

A serverless, cloud-native application that allows users to chat with their PDF documents using AI. Built with AWS Bedrock, OpenSearch, and React.

## Features

- **Document Upload**: Upload PDF, DOCX, or TXT files
- **AI-Powered Chat**: Ask questions about your documents using natural language
- **Semantic Search**: Vector search with Amazon Titan embeddings
- **LLM Integration**: Powered by Anthropic Claude 4 on AWS Bedrock
- **Secure Authentication**: AWS Cognito with Google OAuth
- **Real-time Interface**: Modern React UI with Material-UI
- **Serverless Architecture**: Auto-scaling, pay-per-use infrastructure
- **Infrastructure as Code**: Complete Terraform deployment

## Architecture

```file
.infracodebase/architecture.json
```

**Frontend:**
- React (Vite) app with TypeScript
- Material-UI components
- Hosted on S3 + CloudFront

**Backend:**
- **API Gateway**: RESTful endpoints with JWT authentication
- **Lambda Functions**:
  - `upload` - Generate presigned S3 URLs
  - `list-files` - Query DynamoDB for user documents
  - `query-document` - Chat handler with Bedrock integration
  - `s3-ingestion` - Extract text, create embeddings, index to OpenSearch
- **Storage**:
  - S3 for document storage
  - DynamoDB for metadata
  - OpenSearch Serverless for vector search
- **AI/ML**:
  - Amazon Titan for embeddings
  - Anthropic Claude 4 for chat responses

**Authentication:**
- AWS Cognito User Pool with Google IdP

## How It Works

1. **User uploads a document** → Stored in S3
2. **S3 event triggers ingestion Lambda** → Extracts text, chunks it
3. **Text chunks embedded** → Using Amazon Titan Embeddings
4. **Chunks indexed** → Stored in OpenSearch Serverless with vectors
5. **User asks a question** → Question embedded with Titan
6. **Vector search** → OpenSearch finds relevant chunks
7. **LLM generates answer** → Claude 4 uses context to respond
8. **User receives answer** → With source citations

## Quickstart

### Prerequisites

- **AWS Account** with Bedrock access enabled
- **AWS CLI** configured
- **Terraform** >= 1.0
- **Node.js** >= 18.x
- **Domain name** (optional for custom domains)

### Enable Bedrock Models

Before deploying, enable model access in AWS Bedrock console:
1. Go to AWS Bedrock → Model access
2. Request access to:
   - Amazon Titan Embeddings G1 - Text
   - Anthropic Claude 4 Sonnet (or Haiku/Opus)

### 1. Configure Deployment

```bash
cd terraform/environments
cp staging.tfvars.example staging.tfvars
```

Edit `staging.tfvars` with your AWS account details.

### 2. Deploy Infrastructure

```bash
# Deploy in order:
cd terraform/layers/secrets
terraform init && terraform apply -var-file="../../environments/staging.tfvars"

cd ../cognito
terraform init && terraform apply -var-file="../../environments/staging.tfvars"

cd ../backend
terraform init && terraform apply -var-file="../../environments/staging.tfvars"

cd ../frontend
terraform init && terraform apply -var-file="../../environments/staging.tfvars"
```

See [DEPLOYMENT.md](./DEPLOYMENT.md) for detailed instructions.

### 3. Configure Frontend

```bash
cd frontend/docu-chat-ai
cp .env.example .env
# Edit .env with API Gateway URL and Cognito details from Terraform outputs
npm install
npm run build
```

### 4. Deploy Frontend

```bash
aws s3 sync dist/ s3://your-frontend-bucket/ --delete
```

### 5. Test

Navigate to your CloudFront URL, sign in, upload a document, and start chatting!

## Repository Structure

```
.
├── frontend/
│   └── docu-chat-ai/          # React TypeScript app
│       ├── src/
│       │   ├── app/
│       │   │   ├── features/
│       │   │   │   ├── chat/  # Chat UI components
│       │   │   │   └── files/ # File upload
│       │   │   └── shared/
│       │   │       └── api/   # API client (chatApi.ts)
│       │   └── main.tsx
│       └── package.json
├── terraform/
│   ├── environments/          # Variable files
│   │   ├── staging.tfvars.example
│   │   └── prod.tfvars.example
│   └── layers/
│       ├── backend/           # Lambda, API Gateway, OpenSearch
│       │   ├── main.tf
│       │   ├── locals.tf      # Lambda configurations
│       │   └── src/
│       │       └── lambda_functions/
│       │           ├── query_document/     # Chat handler (NEW)
│       │           ├── s3_ingestion/       # Document processing
│       │           ├── list_files/
│       │           └── get_file/
│       ├── cognito/           # Authentication
│       ├── secrets/           # Secrets Manager
│       └── frontend/          # S3 + CloudFront
└── DEPLOYMENT.md              # Detailed deployment guide
```

## API Endpoints

- `POST /chat` - Send a question, get AI-generated answer
- `GET /files` - List user's uploaded documents
- `GET /files/{id}` - Get specific document
- `GET /documents/{id}` - Get document metadata

All endpoints require JWT authentication via Cognito.

## Configuration

### Bedrock Models

Available models (configure in `bedrock_model_inference_profile_arn` variable):
- `anthropic.claude-sonnet-4-20250514-v1:0` (Recommended - balanced)
- `meta.llama3-70b-instruct-v1:0` (Open source)

### Vector Search

Adjust chunk size and search results:
```hcl
max_search_results = 5  # Number of chunks to retrieve
```

## Development

### Run Frontend Locally

```bash
cd frontend/docu-chat-ai
npm install
npm run dev
```

### Test Lambda Functions

```bash
cd terraform/layers/backend/src/lambda_functions/query_document
pip install -r requirements.txt
python -c "from query_document import handler; print(handler({'body': '{\"question\": \"test\"}'}, None))"
```

### View Logs

```bash
aws logs tail /aws/lambda/staging-docu-chat-ai-query-document --follow
```

## Costs

Estimated monthly costs (low usage):
- **OpenSearch Serverless**: ~$700/month (always-on)
- **Lambda**: ~$5-10 (1M requests free tier)
- **Bedrock**: Pay-per-token
  - Titan Embeddings: $0.0001/1K tokens
  - Claude 4 Sonnet: $0.003/1K input tokens
- **S3 + CloudFront**: ~$1-5
- **DynamoDB**: ~$1-2 (on-demand)

**Total: ~$720-750/month** for staging environment 
> Note: This is quite expensive for a low-usage application. Looking into alternatives.

See [DEPLOYMENT.md](./DEPLOYMENT.md) for cost optimization strategies.

## Troubleshooting

Common issues and solutions:

**Lambda timeout**: Increase timeout to 120s and memory to 1024MB

**OpenSearch 403**: Check data access policy includes Lambda role

**Bedrock throttling**: Request quota increase or add retry logic

**CORS errors**: Verify API Gateway CORS includes CloudFront domain

See [DEPLOYMENT.md](./DEPLOYMENT.md) for detailed troubleshooting.

## Security

- JWT authentication via Cognito
- Encrypted at rest (S3, DynamoDB, OpenSearch)
- IAM least privilege for Lambda roles
- Private OpenSearch endpoints
- Presigned URLs with expiration
- No hardcoded credentials

## Roadmap

- [ ] Streaming chat responses with WebSockets
- [ ] Conversation history persistence
- [ ] Multi-document chat (query across all docs)
- [ ] Document versioning
- [ ] Export chat conversations
- [ ] Advanced citation tracking
- [ ] Admin dashboard for analytics

## Contributing

Contributions welcome! Please open an issue or PR.

## License

MIT License - see LICENSE file for details

## Acknowledgments

Built with:
- [AWS Bedrock](https://aws.amazon.com/bedrock/)
- [OpenSearch Serverless](https://aws.amazon.com/opensearch-service/features/serverless/)
- [React](https://react.dev/)
- [Terraform](https://www.terraform.io/)
- [Material-UI](https://mui.com/)
