variable "db_instance_identifier" {
  type        = string
  description = "Identifier of the RDS instance to monitor"
}

variable "sns_topic_arn" {
  type        = string
  description = "SNS topic ARN to notify on alarms"
}

variable "connection_count_threshold" {
  type        = number
  description = "Number of connections that triggers the alarm. Default is ~80% of max_connections for db.t4g.micro (max ~112)."
  default     = 90
}

variable "free_storage_threshold_bytes" {
  type        = number
  description = "Free storage in bytes below which the alarm triggers. Default is 2 GB."
  default     = 2000000000
}

variable "cpu_utilization_threshold" {
  type        = number
  description = "CPU utilization percentage above which the alarm triggers."
  default     = 80
}