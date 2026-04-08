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