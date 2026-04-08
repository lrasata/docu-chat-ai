# The base API Gateway ID
output "api_id" {
  value       = aws_apigatewayv2_api.api.id
  description = "The ID of the Query document API Gateway"
}

output "api_name" {
  value = aws_apigatewayv2_api.api.name
}

# The default execution URL (base URL) of the API
output "api_endpoint" {
  value       = aws_apigatewayv2_api.api.api_endpoint
  description = "The base endpoint URL for the Query document API Gateway"
}

# domain name
output "api_gateway_domain_name" {
  value = aws_apigatewayv2_domain_name.api.domain_name_configuration[0].target_domain_name
}

# hosted zone id
output "api_gateway_hosted_zone_id" {
  value = aws_apigatewayv2_domain_name.api.domain_name_configuration[0].hosted_zone_id
}

# The stage for the environment
output "stage_name" {
  value       = aws_apigatewayv2_stage.api.name
  description = "The stage name for this API Gateway"
}

# Cognito authorizer ID
output "authorizer_id" {
  value       = aws_apigatewayv2_authorizer.cognito.id
  description = "The ID of the Cognito JWT authorizer"
}