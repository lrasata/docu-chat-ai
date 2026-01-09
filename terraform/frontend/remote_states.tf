data "terraform_remote_state" "security" {
  backend = "s3"
  config = {
    bucket = "docu-chat-ai-app-states"
    key    = "security/terraform.tfstate"
    region = "eu-central-1"
  }
}

data "terraform_remote_state" "backend" {
  backend = "s3"
  config = {
    bucket = "docu-chat-ai-app-states"
    key    = "backend/terraform.tfstate"
    region = "eu-central-1"
  }
}