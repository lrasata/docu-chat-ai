variable "route53_zone_name" {
  description = "Route 53 zone name (e.g., epic-trip-planner.com)"
  type        = string
}

variable "api_file_upload_domain_name" {
  description = "The domain name for the API Gateway"
  type        = string
}

variable "api_gateway_regional_domain_name" {
  description = "Regional domain name of the API Gateway custom domain"
  type        = string
}

variable "api_gateway_regional_zone_id" {
  description = "Regional zone ID of the API Gateway custom domain"
  type        = string
}