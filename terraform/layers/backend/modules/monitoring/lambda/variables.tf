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

variable "bedrock_embedding_latency_threshold_ms" {
  type        = number
  description = "Bedrock embedding latency in ms above which the alarm triggers. Set to null to disable."
  default     = null
}

variable "bedrock_llm_latency_threshold_ms" {
  type        = number
  description = "Bedrock LLM (converse) latency in ms above which the alarm triggers. Set to null to disable."
  default     = null
}
