data "aws_secretsmanager_secret" "docu_chat_ai_secrets" {
  name = "${var.environment}/${var.app_id}/secrets"
}

data "aws_secretsmanager_secret_version" "docu_chat_ai_secret_values" {
  secret_id = data.aws_secretsmanager_secret.docu_chat_ai_secrets.id
}

locals {
  google_client_id        = jsondecode(data.aws_secretsmanager_secret_version.docu_chat_ai_secret_values.secret_string)["GOOGLE_CLIENT_ID"]
  google_client_secret    = jsondecode(data.aws_secretsmanager_secret_version.docu_chat_ai_secret_values.secret_string)["GOOGLE_CLIENT_SECRET"]
  file_upload_auth_secret = jsondecode(data.aws_secretsmanager_secret_version.docu_chat_ai_secret_values.secret_string)["API_GW_FILE_UPLOAD_AUTH_SECRET"]
}