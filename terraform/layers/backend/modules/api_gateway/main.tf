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


# ===== API Gateway Routes =====

# POST /chat - Query documents with AI
resource "aws_apigatewayv2_integration" "query_document" {
  api_id             = aws_apigatewayv2_api.api.id
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  integration_uri    = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${var.lambda_query_document_arn}/invocations"

}

resource "aws_apigatewayv2_route" "query_document" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "POST /api/chat"
  target             = "integrations/${aws_apigatewayv2_integration.query_document.id}"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
  authorization_type = "JWT"
}

resource "aws_lambda_permission" "query_document" {
  statement_id  = "AllowAPIGatewayQueryDocument"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_query_document_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}
