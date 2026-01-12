
# AI Powered PDF Document Chat App 🚧

>
> 🚧 In construction
>

![Staging - Deployment pipeline](https://github.com/lrasata/serverless-docu-chat-ai/actions/workflows/deploy-to-staging.yml/badge.svg)

## Overview

This project is a serverless, cloud-native application that allows users to chat with their own PDF documents using AI. It leverages AWS services, React frontend, and modern infrastructure-as-code for scalable, secure deployments.

## Features

- Upload PDF files and interact with them using natural language
- Secure authentication with AWS Cognito (Google sign-in supported)
- Real-time chat interface powered by React
- Serverless backend using AWS Lambda, API Gateway, and DynamoDB
- Infrastructure managed with Terraform

## Architecture

**Frontend:**
- React (Vite) app in `frontend/docu-chat-ai-frontend/`

**Backend:**
- AWS Lambda functions for file handling and document Q&A
- API Gateway for RESTful endpoints
- DynamoDB for metadata storage
- S3 for file storage

**Authentication:**
- AWS Cognito User Pool with Google as an Identity Provider

**Infrastructure:**
- Terraform modules in `terraform/` for backend, Cognito, secrets, and frontend hosting

## Quickstart

### Prerequisites
- Node.js (for frontend)
- Terraform >= 1.0
- AWS CLI configured with appropriate credentials

### 1. Deploy Infrastructure

```sh
cd terraform/layers/backend
terraform init
terraform apply -var-file="../../common/staging.tfvars"
```
Repeat for `cognito`, `secrets`, and `frontend` layers as needed.

### 2. Run Frontend Locally

```sh
cd frontend/docu-chat-ai-frontend
npm install
npm run dev
```

### 3. Usage
- Sign in with Google
- Upload a PDF
- Start chatting with your document!

## Repository Structure

- `frontend/` - React app source code
- `terraform/` - Infrastructure as code (modularized by layer)
- `docs/` - Additional documentation