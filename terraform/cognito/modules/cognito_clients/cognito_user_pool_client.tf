resource "aws_cognito_user_pool_client" "cognito_user_pool_client" {
  name         = "${var.environment}-docu-chat-ai-cognito-user-pool-client"
  user_pool_id = var.cognito_user_pool_id

  generate_secret                      = false # application which runs in the browser (React), you must NOT use a client secret — because it cannot be securely stored
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["openid", "email", "profile"]
  allowed_oauth_flows_user_pool_client = true

  callback_urls = var.callback_urls
  logout_urls   = var.logout_urls

  supported_identity_providers = ["COGNITO", "Google"]


  explicit_auth_flows = [
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]
}

