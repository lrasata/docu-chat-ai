resource "aws_cognito_user_pool" "cognito_user_pool" {
  name = "${var.environment}-${var.app_id}-cognito-user-pool"

  alias_attributes         = ["email"]
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length    = 16
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  mfa_configuration = "OFF"

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }
}

resource "aws_cognito_user_pool_domain" "cognito_user_pool_domain" {
  domain       = "${var.environment}-${var.app_id}-auth-domain"
  user_pool_id = aws_cognito_user_pool.cognito_user_pool.id
}