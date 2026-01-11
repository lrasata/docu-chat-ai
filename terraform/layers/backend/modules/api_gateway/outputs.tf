# The base API Gateway ID
output "api_id" {
  value       = aws_apigatewayv2_api.api.id
  description = "The ID of the API Gateway"
}

# The default execution URL (base URL) of the API
output "api_endpoint" {
  value       = aws_apigatewayv2_api.api.api_endpoint
  description = "The base endpoint URL for the API Gateway"
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

# Lambda integration ARNs (already passed from lambda module)
output "lambda_list_files_arn" {
  value       = var.lambda_list_files_arn
  description = "ARN of the Lambda function for listing files"
}

output "lambda_get_file_arn" {
  value       = var.lambda_get_file_arn
  description = "ARN of the Lambda function for getting a single file"
}

output "lambda_get_document_data_arn" {
  value       = var.lambda_get_document_data_arn
  description = "ARN of the Lambda function for getting document metadata"
}

# Full routes URLs using the stage name
output "list_files_route" {
  value       = "${aws_apigatewayv2_api.api.api_endpoint}/${aws_apigatewayv2_stage.api.name}/files"
  description = "Full URL for GET /files route"
}

output "get_file_route" {
  value       = "${aws_apigatewayv2_api.api.api_endpoint}/${aws_apigatewayv2_stage.api.name}/files/{id}"
  description = "Full URL for GET /files/{id} route"
}

output "get_document_data_route" {
  value       = "${aws_apigatewayv2_api.api.api_endpoint}/${aws_apigatewayv2_stage.api.name}/documents/{id}"
  description = "Full URL for GET /documents/{id} route"
}
