## AWS Cognito Terraform Layer

This directory contains Terraform code for provisioning AWS Cognito resources for the serverless-docu-chat-ai project. It supports secure authentication and social sign-in (Google) for your application.

---

### 📄 Overview

This guide walks you through deploying and configuring the AWS Cognito User Pool, Domain, and Client using Terraform. It is tailored for a staging environment and includes Google as an Identity Provider (IdP).

---

> **Note:**
> When running the GitHub pipeline, most requirements are handled automatically, but the Google Cloud setup (OAuth consent/redirect URI) must be done manually.

---

## Prerequisites

- Terraform >= 1.0 installed and configured
- AWS credentials for the target region
- A Google Cloud Project with OAuth 2.0 Client ID and Secret (for use in your Terraform variables, e.g., in `staging.tfvars`)
- **AWS Secrets Manager Secret** configured (see below)

### 🔑 Required AWS Secrets Manager Secret

Create a secret in AWS Secrets Manager with the following:

| Detail | Value |
| :--- | :--- |
| **Secret Name** | `${var.environment}/${var.app_id}/secrets` (e.g., `staging/docu-chat-ai/secrets`) |
| **Secret Type** | Plaintext or Key/Value (must be a valid JSON string) |

**Secret value example:**

```json
{
  "GOOGLE_CLIENT_ID": "YOUR_GOOGLE_OAUTH_CLIENT_ID",
  "GOOGLE_CLIENT_SECRET": "YOUR_GOOGLE_OAUTH_CLIENT_SECRET"
}
```

---

## 🚀 Deployment Steps details

### 1. Create Cognito User Pool and Domain


This step deploys the foundational Cognito resources: the **User Pool** and the **Cognito Hosted UI Domain**.

```sh
terraform apply -target="module.cognito_base" -var-file="../common/staging.tfvars"
```

**Expected Output:**
- `cognito_user_pool_id`
- `cognito_user_pool_domain` (e.g., `staging-app-auth-domain`)

---

### 2. Configure Authorized Redirect URIs in Google Cloud (Manual, one-time)

Before creating the Cognito User Pool Client, you must inform Google (the IdP) about the valid redirect URI.

**Action Required:**
1. Retrieve the full Cognito User Pool Domain URL from Step 1 output.
2. In your Google Cloud Project, go to OAuth consent screen or credentials settings.
3. Add this URI to **Authorized redirect URIs**:

```
https://<user_pool_domain>.auth.<region>.amazoncognito.com/oauth2/idpresponse
```

**Examples:**
- `https://staging-docu-chat-ai-auth-domain.auth.eu-central-1.amazoncognito.com/oauth2/idpresponse`
- `https://dev-docu-chat-ai-auth-domain.auth.eu-central-1.amazoncognito.com/oauth2/idpresponse`

The domain format: `${var.environment}-${var.app_id}-auth-domain`

---

### 3. Create User Pool Client referencing Google IdP

This step creates the **User Pool Client** and configures it to use Google as an Identity Provider.

```sh
terraform apply -target="module.cognito_clients" -var-file="../common/staging.tfvars"
```

**Expected Output:**
- `cognito_user_pool_client_id` (used in your application's frontend or API config)

---

### 4. Verification

After all steps, check the outputs:

```sh
terraform output
```

You should see:
- `cognito_user_pool_id`
- `cognito_user_pool_domain`
- `cognito_user_pool_client_id`
- `cognito_user_pool_endpoint`

---

## 📁 Module Structure

- **main.tf**: Entry point for Cognito resources
- **variables.tf**: Input variables
- **outputs.tf**: Outputs from the Cognito layer
- **provider.tf**: AWS provider config
- **remote_states.tf**: Remote state data sources
- **modules/**: Reusable submodules:
  - `cognito_base/`: User pool and IdP setup
  - `cognito_clients/`: User pool client config

---

## ℹ️ Additional Information

Refer to the module files for advanced configuration. For questions or issues, open an issue in the main repository or contact the maintainers.
