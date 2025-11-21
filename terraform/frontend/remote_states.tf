data "terraform_remote_state" "security" {
  backend = "s3"
  config = {
    bucket = "docu-chat-ai-app-states"
    key    = "security/terraform.tfstate"
    region = "eu-central-1"
  }
}