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