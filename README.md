# AI Powered Document Chat App [In construction 🚧]

![Staging Backend - Deployment pipeline](https://github.com/lrasata/serverless-docu-chat-ai/actions/workflows/deploy-backend-to-staging.yml/badge.svg)
![Staging Frontend - Deployment pipeline](https://github.com/lrasata/serverless-docu-chat-ai/actions/workflows/deploy-frontend-to-staging.yml/badge.svg)

A serverless, cloud-native application that allows users to chat with their PDF documents using AI. Built with AWS Bedrock, RDS PostgreSQL + pgvector, and React. Uses **Retrieval-Augmented Generation (RAG)** to answer questions grounded in the user's own documents.

## Features

- **Document Upload**: Upload PDF, DOCX, or TXT files
- **AI-Powered Chat**: Ask questions about your documents using natural language
- **Semantic Search**: Vector similarity search with Amazon Titan embeddings and pgvector
- **LLM Integration**: Powered by Anthropic Claude 4 on AWS Bedrock
- **Secure Authentication**: AWS Cognito with Google OAuth
- **Real-time Interface**: Modern React UI with Material-UI
- **Serverless Architecture**: Auto-scaling, pay-per-use infrastructure
- **Infrastructure as Code**: Complete Terraform deployment

## What is RAG?

**Retrieval-Augmented Generation (RAG)** is a technique that combines a vector search engine with a large language model (LLM). Instead of relying solely on the LLM's pre-trained knowledge, RAG first retrieves relevant passages from a document store and feeds them as context to the LLM before generating an answer.

**Pros:**
- Answers are grounded in your actual documents — less hallucination
- Works with private or domain-specific content the LLM was never trained on
- Easy to update the knowledge base without retraining the model
- Source citations are traceable

**Cons:**
- Answer quality depends heavily on chunking and retrieval quality
- Adds latency (embedding + vector search before LLM call)
- Irrelevant chunks can mislead the LLM if retrieval is poor
- Requires maintaining a vector database alongside the document store

### How RAG works in this project

1. **Ingestion** — When a document is uploaded to S3, the `s3-ingestion` Lambda extracts the text, splits it into overlapping chunks (~500 words), and calls Amazon Titan Embeddings to convert each chunk into a 1536-dimensional vector. The vectors are stored alongside the text in RDS PostgreSQL using the `pgvector` extension.

2. **Query** — When a user asks a question, the `query-document` Lambda embeds the question with the same Titan model, then runs a cosine similarity search (`<=>` operator) against the `document_chunks` table in PostgreSQL to find the most relevant chunks. Results can be scoped to a specific document or to all documents belonging to the user.

3. **Generation** — The top matching chunks are assembled into a context prompt and sent to Anthropic Claude 4 on AWS Bedrock. Claude answers the question using only the retrieved context, then the response is returned to the frontend with source citations.

## Architecture

**Frontend:**
- React (Vite) app with TypeScript
- Material-UI components
- Hosted on S3 + CloudFront

**Backend:**
- **API Gateway**: RESTful endpoints with JWT authentication
- **Lambda Functions**:
  - `upload` - Generate presigned S3 URLs
  - `get-files` - Query DynamoDB for user documents
  - `query-document` - RAG chat handler with Bedrock integration
  - `s3-ingestion` - Extract text, create embeddings, index to pgvector
- **Storage**:
  - S3 for document storage
  - DynamoDB for file metadata
  - RDS PostgreSQL + pgvector for vector search
- **Networking**:
  - Lambda and RDS run inside a private VPC
  - VPC Interface Endpoints for Bedrock, Secrets Manager, SNS (no NAT Gateway)
  - VPC Gateway Endpoints for S3 and DynamoDB (free)
- **AI/ML**:
  - Amazon Titan Embeddings for vectorisation
  - Anthropic Claude 4 for chat responses

**Authentication:**
- AWS Cognito User Pool with Google IdP

## How It Works

1. **User uploads a document** → Stored in S3
2. **S3 event triggers ingestion Lambda** → Extracts text, chunks it
3. **Text chunks embedded** → Using Amazon Titan Embeddings (1536 dimensions)
4. **Chunks indexed** → Stored in RDS PostgreSQL (`document_chunks` table) with pgvector
5. **User asks a question** → Question embedded with Titan
6. **Vector search** → pgvector cosine similarity finds the most relevant chunks
7. **LLM generates answer** → Claude 4 uses retrieved context to respond
8. **User receives answer** → With source citations and relevance scores

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
│       ├── backend/           # Lambda, API Gateway, RDS pgvector
│       │   ├── main.tf
│       │   ├── locals.tf      # Lambda configurations
│       │   ├── modules/
│       │   │   └── rds/       # VPC, RDS PostgreSQL, VPC endpoints
│       │   └── src/
│       │       └── lambda_functions/
│       │           ├── query_document/  # RAG chat handler
│       │           └── s3_ingestion/    # Document processing + embedding
│       ├── cognito/           # Authentication
│       ├── secrets/           # Secrets Manager
│       └── frontend/          # S3 + CloudFront
└── DEPLOYMENT.md              # Detailed deployment guide
```

## API Endpoints

- `POST /api/chat` - Send a question, get AI-generated answer (optionally scoped to a document)
- `GET /api/files` - List user's uploaded documents
- `GET /api/upload` - Get a presigned S3 URL for uploading

All endpoints require JWT authentication via Cognito.

## Configuration

### Bedrock Models

Available models (configure in `bedrock_model_inference_profile_arn` variable):
- `anthropic.claude-sonnet-4-20250514-v1:0` (Recommended - balanced)

### Vector Search

Adjust the number of chunks retrieved per query:
```hcl
max_search_results = 5  # Number of chunks to retrieve per query
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
aws logs tail /aws/lambda/staging-docu-chat-ai-s3-ingestion --follow
```

## Costs

Estimated monthly costs (low usage):
- **RDS PostgreSQL** (db.t4g.micro): ~$13/month
- **VPC Interface Endpoints** (Bedrock, Secrets Manager, SNS): ~$30-45/month
- **Lambda**: ~$5-10 (1M requests free tier)
- **Bedrock**: Pay-per-token
  - Titan Embeddings: $0.0001/1K tokens
  - Claude 4 Sonnet: $0.003/1K input tokens
- **S3 + CloudFront**: ~$1-5
- **DynamoDB**: ~$1-2 (on-demand)

**Total: ~$55-80/month** for staging environment

## Troubleshooting

**Lambda timeout**: Increase timeout to 120s and memory to 512MB

**pgvector type not found**: The `vector` extension is created automatically on first Lambda cold start. If it fails, check that the Lambda security group can reach the RDS security group on port 5432.

**Bedrock throttling**: Request quota increase or add retry logic

**CORS errors**: Verify API Gateway CORS includes CloudFront domain

See [DEPLOYMENT.md](./DEPLOYMENT.md) for detailed troubleshooting.

## Security

- JWT authentication via Cognito
- Encrypted at rest (S3, DynamoDB, RDS storage encryption)
- IAM least privilege for Lambda roles
- RDS in private VPC subnets — not publicly accessible
- RDS credentials stored in Secrets Manager, fetched at runtime
- Presigned URLs with expiration
- No hardcoded credentials

## Roadmap

- [ ] Streaming chat responses with WebSockets
- [ ] Conversation history persistence
- [ ] Document versioning
- [ ] Export chat conversations
- [ ] Advanced citation tracking
- [ ] Admin dashboard for analytics

## License

MIT License - see LICENSE file for details

## Acknowledgments

Built with:
- [AWS Bedrock](https://aws.amazon.com/bedrock/)
- [RDS PostgreSQL + pgvector](https://github.com/pgvector/pgvector)
- [React](https://react.dev/)
- [Terraform](https://www.terraform.io/)
- [Material-UI](https://mui.com/)