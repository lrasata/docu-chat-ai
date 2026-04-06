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

output "query_document_stream_url" {
  value       = module.lambda_functions["query_document"].function_url
  description = "Lambda Function URL for streaming SSE chat responses"
}

output "api_backend_domain_name" {
  value       = trimsuffix(replace(module.lambda_functions["query_document"].function_url, "https://", ""), "/")
  description = "Lambda Function URL domain — used by the frontend CloudFront as the backend origin"
}
