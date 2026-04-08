#############################################
# ALARMS: RDS Connection Count
#############################################
resource "aws_cloudwatch_metric_alarm" "rds_connection_count" {
  alarm_name          = "${var.db_instance_identifier}-connection-count"
  alarm_description   = "Triggers if RDS connection count exceeds threshold"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  period              = 60
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  statistic           = "Average"
  threshold           = var.connection_count_threshold

  dimensions = {
    DBInstanceIdentifier = var.db_instance_identifier
  }

  alarm_actions = [var.sns_topic_arn]
}

#############################################
# ALARMS: RDS Free Storage Space
#############################################
resource "aws_cloudwatch_metric_alarm" "rds_free_storage" {
  alarm_name          = "${var.db_instance_identifier}-free-storage"
  alarm_description   = "Triggers if RDS free storage drops below threshold (default 2 GB)"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  period              = 300
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  statistic           = "Average"
  threshold           = var.free_storage_threshold_bytes

  dimensions = {
    DBInstanceIdentifier = var.db_instance_identifier
  }

  alarm_actions = [var.sns_topic_arn]
}

#############################################
# ALARMS: RDS CPU Utilization
#############################################
resource "aws_cloudwatch_metric_alarm" "rds_cpu_utilization" {
  alarm_name          = "${var.db_instance_identifier}-cpu-utilization"
  alarm_description   = "Triggers if RDS CPU utilization exceeds threshold"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  period              = 300
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  statistic           = "Average"
  threshold           = var.cpu_utilization_threshold

  dimensions = {
    DBInstanceIdentifier = var.db_instance_identifier
  }

  alarm_actions = [var.sns_topic_arn]
}