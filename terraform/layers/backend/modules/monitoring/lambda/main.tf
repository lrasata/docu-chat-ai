#############################################
# ALARMS: Lambda Error Rate
#############################################
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.function_name}-errors"
  alarm_description   = "Triggers if Lambda error count exceeds threshold"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  period              = 60
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  statistic           = "Sum"
  threshold           = var.error_rate_threshold

  dimensions = {
    FunctionName = var.function_name
  }

  alarm_actions = [var.sns_topic_arn]
}
