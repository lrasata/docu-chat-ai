output "cognito_user_pool_client_id" {
  description = "Cognito User pool Client ID"
  value       = module.cognito_clients.cognito_user_pool_client_id
}

output "cognito_user_pool_id" {
  description = "Cognito User pool ID"
  value       = module.cognito_base.cognito_user_pool_id
}

output "cognito_user_pool_domain" {
  description = "Cognito User Pool Domain"
  value       = module.cognito_base.cognito_user_pool_domain
}

output "cognito_user_pool_endpoint" {
  description = "Cognito user pool endpoint"
  value       = "https://cognito-idp.${var.region}.amazonaws.com/${module.cognito_base.cognito_user_pool_id}"
}

