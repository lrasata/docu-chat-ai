output "cloudfront_domain" {
  value = module.cloudfront.cloudfront_domain_name
}

output "cloudfront_distribution_id" {
  value = module.cloudfront.cloudfront_distribution_id
}

output "lambda_stream_url" {
  value       = data.terraform_remote_state.backend.outputs.query_document_stream_url
  description = "Lambda Function URL for streaming chat — used as VITE_LAMBDA_STREAM_URL in the frontend build"
}