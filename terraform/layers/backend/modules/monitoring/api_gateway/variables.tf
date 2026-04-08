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

variable "latency_p99_threshold_ms" {
  type        = number
  description = "p99 latency in milliseconds above which the alarm triggers. RAG queries can be slow; default is 10s."
  default     = 10000
}