
### Step 1 - Create Cognito user pool and domain
````bash
terraform apply -target="module.cognito_base" -var-file="../common/staging.tfvars"
````

### Step 2 - Configure Authorized redirect UIRs in Google Cloud
````text
https://<user_pool_domain>.auth.<region>.amazoncognito.com/oauth2/idpresponse
````

### Step 3 - Create User Pool Client referencing Google Idp
````bash
terraform apply -target="module.cognito_client" -var-file="../common/staging.tfvars"
````