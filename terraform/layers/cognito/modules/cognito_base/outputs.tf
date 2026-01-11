output "cognito_user_pool_id" {
  description = "Cognito User pool ID"
  value       = aws_cognito_user_pool.cognito_user_pool.id
}

output "cognito_user_pool_domain" {
  description = "Cognito User Pool Domain"
  value       = "${aws_cognito_user_pool_domain.cognito_user_pool_domain.domain}.auth.${var.region}.amazoncognito.com"
}

output "cognito_user_pool_endpoint" {
  description = "Cognito user pool endpoint"
  value       = "https://cognito-idp.${var.region}.amazonaws.com/${aws_cognito_user_pool.cognito_user_pool.id}"
}