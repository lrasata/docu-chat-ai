# Create API Gateway
resource "aws_apigatewayv2_api" "api" {
  name          = "${var.environment}-${var.app_id}-query-document-apigw"
  protocol_type = "HTTP"
  cors_configuration {
    allow_origins  = ["https://${var.cloudfront_domain_name}"]
    allow_methods  = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers  = ["*"]
    expose_headers = ["*"]
  }
}

# API Gateway Stage
resource "aws_apigatewayv2_stage" "api" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = var.environment
  auto_deploy = true
}

# Custom domain name resource
resource "aws_apigatewayv2_domain_name" "api" {
  domain_name = var.custom_domain_name

  domain_name_configuration {
    certificate_arn = var.backend_certificate_arn # must be in same region (eu-central-1)
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

# API mapping - connects the custom domain to your API + stage
resource "aws_apigatewayv2_api_mapping" "api" {
  api_id      = aws_apigatewayv2_api.api.id
  domain_name = aws_apigatewayv2_domain_name.api.id
  stage       = aws_apigatewayv2_stage.api.id
}

# Cognito Authorizer for API Gateway
resource "aws_apigatewayv2_authorizer" "cognito" {
  api_id           = aws_apigatewayv2_api.api.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "${var.environment}-cognito-authorizer"

  jwt_configuration {
    audience = [var.cognito_user_pool_client_id]
    issuer   = "https://cognito-idp.${var.region}.amazonaws.com/${var.cognito_user_pool_id}"
  }
}

