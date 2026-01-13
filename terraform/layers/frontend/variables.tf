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

variable "app_id" {
  type    = string
  default = "docu-chat-ai"
}

variable "cloudfront_certificate_arn" {
  description = "The ARN of the ACM certificate for CloudFront"
  type        = string
}

variable "alt_cloudfront_domain_name" {
  description = "The Alternative domain name for CloudFront distribution"
  type        = string
}