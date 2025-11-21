module "cognito_base" {
  source               = "./modules/cognito_base"
  google_client_id     = data.terraform_remote_state.security.outputs.google_client_id
  google_client_secret = data.terraform_remote_state.security.outputs.google_client_secret
  region               = var.region
}

# Apply after applying cognito_base and configuring Google redirect URI in Google Cloud:
module "cognito_clients" {
  source = "./modules/cognito_clients"

  cognito_user_pool_id = module.cognito_base.cognito_user_pool_id
  callback_urls        = var.callback_urls
  logout_urls          = var.logout_urls
}
