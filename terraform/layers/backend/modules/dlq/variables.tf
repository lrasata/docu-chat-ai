variable "environment" {
  description = "The deployment environment (e.g., 'dev', 'prod'). Used for resource naming prefixes."
  type        = string
}

variable "app_id" {
  description = "A unique identifier or name for the application. Used in resource tags."
  type        = string
}

variable "service_name" {
  description = "The service name"
  type        = string
}

variable "message_retention_seconds" {
  type    = number
  default = 1209600 # 14 days
}

variable "visibility_timeout_seconds" {
  type    = number
  default = 900 # Lambda max timeout — safe upper bound for any consumer
}

variable "sns_topic_arn" {
  type = string
}