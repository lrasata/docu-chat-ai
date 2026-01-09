variable "environment" {
  description = "The environment for the deployment (e.g., dev, staging, prod)"
  type        = string
  default     = "staging"
}

variable "region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "eu-central-1"
}

variable "app_name" {
  type    = string
  default = "docu-chat-ai"
}

variable "static_web_app_bucket_name" {
  description = "The name of the S3 bucket containing the build of the SPA"
  type        = string
  default     = "frontend-spa-bucket"
}

variable "cloudfront_certificate_arn" {
  description = "The ARN of the ACM certificate for CloudFront"
  type        = string
}

variable "cloudfront_domain_name" {
  description = "The domain name for CloudFront distribution"
  type        = string
}