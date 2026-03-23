variable "route53_zone_name" {
  description = "Route 53 zone name (e.g., epic-trip-planner.com)"
  type        = string
}

variable "api_custom_domain_name" {
  description = "The custom domain name for the API Gateway"
  type        = string
}

variable "api_gateway_domain_name" {
  description = "domain name of the API Gateway custom domain"
  type        = string
}

variable "api_gateway_hosted_zone_id" {
  description = "Hosted zone ID of the API Gateway custom domain"
  type        = string
}

