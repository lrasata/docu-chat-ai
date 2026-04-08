variable "function_name" {
  type        = string
  description = "Name of the Lambda function to monitor"
}

variable "sns_topic_arn" {
  type        = string
  description = "SNS topic ARN to notify on alarms"
}

variable "error_rate_threshold" {
  type        = number
  description = "Number of errors per evaluation period that triggers the alarm"
  default     = 5
}
