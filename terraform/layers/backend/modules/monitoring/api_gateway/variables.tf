variable "api_name" {
  type        = string
  description = "Name of the API Gateway to monitor"
}

variable "region" {
  type        = string
  description = "AWS region"
}

variable "sns_topic_arn" {
  type        = string
  description = "SNS topic ARN to notify on alarms"
}