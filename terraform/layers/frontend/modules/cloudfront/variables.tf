variable "environment" {
  description = "The environment for the deployment (e.g., dev, staging, prod)"
  type        = string
}

variable "app_id" {
  description = "Name which identifies the deployed app"
  type        = string
}

variable "s3_static_web_files_bucket_regional_domain_name" {
  type = string
}

variable "uploads_bucket_regional_domain_name" {
  type = string
}

variable "cloudfront_certificate_arn" {
  type = string
}

variable "cloudfront_domain_name" {
  type = string
}

variable "api_file_upload_domain_name" {
  type = string
}