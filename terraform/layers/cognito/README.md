# Cognito Setup 

This documentation outlines the steps to deploy and configure the AWS Cognito User Pool, Domain, and Client using Terraform, specifically for a staging environment that integrates with Google as an Identity Provider (IdP).

-----

## Prerequisites

* Terraform installed and configured.
* AWS credentials configured for the target region.
* A Google Cloud Project with OAuth 2.0 Client ID and Client Secret for use in your Terraform variables (e.g., in `staging.tfvars`).
    * **AWS Secrets Manager Secret** configured (see detail below).

### 🔑 Required AWS Secrets Manager Secret

This configuration retrieves your sensitive Google credentials securely from AWS Secrets Manager. You must create a secret with the following specifications:

| Detail | Value |
| :--- | :--- |
| **Secret Name** | `${var.environment}/docu-chat-ai/secrets` (e.g., `staging/docu-chat-ai/secrets`) |
| **Secret Type** | **Plaintext** or **Key/Value** (The content must be a valid JSON string.) |

The secret's **value** must be a **JSON string** containing the `GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET` keys, matching how they are accessed in the `locals` block:

```json
{
  "GOOGLE_CLIENT_ID": "YOUR_GOOGLE_OAUTH_CLIENT_ID",
  "GOOGLE_CLIENT_SECRET": "YOUR_GOOGLE_OAUTH_CLIENT_SECRET"
}
```
-----

## 🚀 Deployment Steps

### Step 1 - Create Cognito User Pool and Domain

This step deploys the foundational Cognito resources: the **User Pool** itself and the **Cognito Hosted UI Domain**.

Run the following command, targeting the `cognito_base` module to create these resources:

```bash
terraform apply -target="module.cognito_base" -var-file="../common/staging.tfvars"
```

* **Expected Output:** 

* This command will generate the `cognito_user_pool_id` and the base `cognito_user_pool_domain` (e.g., `staging-app-auth-domain`).

-----

### Step 2 - Configure Authorized Redirect URIs in Google Cloud

Before creating the Cognito User Pool Client, you must inform Google (the Identity Provider) about the valid URL to which Cognito will redirect users after they successfully log in.

**Action Required:**

1.  Retrieve the full Cognito User Pool Domain URL from the output of Step 1.
2.  Navigate to your Google Cloud Project's OAuth consent screen or credentials settings.
3.  Add the following URI to the list of **Authorized redirect URIs**:

<!-- end list -->

```text
https://<user_pool_domain>.auth.<region>.amazoncognito.com/oauth2/idpresponse
```

* **Example:** If your domain is `staging-docu-chat-ai-auth-domain` and your region is `eu-central-1`, the URI would be:
  `https://staging-docu-chat-ai-auth-domain.auth.eu-central-1.amazoncognito.com/oauth2/idpresponse`

-----

### Step 3 - Create User Pool Client referencing Google IdP

This final step creates the **User Pool Client** (the application interface) and configures it to use the **Google Identity Provider** for social sign-in. This module relies on the pool and domain created in Step 1.

Run the following command, targeting the `cognito_client` module:

```bash
terraform apply -target="module.cognito_clients" -var-file="../common/staging.tfvars"
```

* **Expected Output:** 

This command will generate the crucial **`cognito_user_pool_client_id`**, which you will use in your serverless application's front-end or API configuration.

-----

### Verification

After successfully completing all steps, you can check the final output values:

```bash
terraform output
```

You should see all necessary values printed:

* `cognito_user_pool_id`
* `cognito_user_pool_domain`
* `cognito_user_pool_client_id`
* `cognito_user_pool_endpoint`
