data "terraform_remote_state" "cognito" {
  backend = "s3"

  config = {
    bucket = "docu-chat-ai-app-states"
    key    = "cognito/terraform.tfstate"
    region = var.region
  }
}


data "terraform_remote_state" "security" {
  backend = "s3"

  config = {
    bucket = "docu-chat-ai-app-states"
    key    = "security/terraform.tfstate"
    region = var.region
  }
}
