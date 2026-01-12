data "terraform_remote_state" "secrets" {
  backend = "s3"
  config = {
    bucket = "docu-chat-ai-app-states"
    key    = "secrets/${var.environment}/terraform.tfstate"
    region = var.region
  }
}

data "terraform_remote_state" "backend" {
  backend = "s3"
  config = {
    bucket = "docu-chat-ai-app-states"
    key    = "backend/${var.environment}/terraform.tfstate"
    region = var.region
  }
}