output "google_client_id" {
  value     = local.google_client_id
  sensitive = true
}

output "google_client_secret" {
  value     = local.google_client_secret
  sensitive = true
}

output "file_upload_auth_secret" {
  value     = local.file_upload_auth_secret
  sensitive = true
}

output "secret_store_name" {
  value = data.aws_secretsmanager_secret.docu_chat_ai_secrets.name
}