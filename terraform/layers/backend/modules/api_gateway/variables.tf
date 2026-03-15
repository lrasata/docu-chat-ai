variable "environment" {
  description = "The environment for the deployment (e.g., dev, staging, prod)"
  type        = string
}

variable "app_id" {
  description = "Name which identifies the deployed app"
  type        = string
}

variable "region" {
  description = "The AWS region to deploy resources"
  type        = string
}

variable "cloudfront_domain_name" {
  description = "The  domain name for CloudFront distribution for CORS settings"
  type        = string
}

variable "custom_domain_name" {
  description = "The custom domain name"
  type        = string
}

variable "backend_certificate_arn" {
  description = "The ARN of the ACM certificate"
  type        = string
}


variable "cognito_user_pool_client_id" {
  type = string
}

variable "cognito_user_pool_id" {
  type = string
}

variable "lambda_list_files_arn" {
  type = string
}

variable "lambda_list_files_function_name" {
  type = string
}

variable "lambda_get_file_arn" {
  type = string
}

variable "lambda_get_file_function_name" {
  type = string
}

variable "lambda_get_document_data_arn" {
  type = string
}

variable "lambda_get_document_data_function_name" {
  type = string
}

variable "lambda_query_document_arn" {
  type = string
}

variable "lambda_query_document_function_name" {
  type = string
}
