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