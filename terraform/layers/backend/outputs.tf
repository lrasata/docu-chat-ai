output "uploads_bucket_regional_domain_name" {
  value = module.file_uploader.uploads_bucket_regional_domain_name
}

output "documents_table_name" {
  value = module.file_uploader.dynamo_db_table_name
}

output "api_file_upload_domain_name" {
  value = var.api_file_upload_domain_name
}

output "uploads_bucket_id" {
  value = module.file_uploader.uploads_bucket_id
}

output "uploads_bucket_arn" {
  value = module.file_uploader.uploads_bucket_arn
}
