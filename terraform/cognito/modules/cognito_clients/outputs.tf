output "cognito_user_pool_client_id" {
  description = "Cognito User pool Client ID"
  value       = aws_cognito_user_pool_client.cognito_user_pool_client.id
}