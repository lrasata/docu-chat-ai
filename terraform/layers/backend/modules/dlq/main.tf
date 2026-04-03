resource "aws_sqs_queue" "dlq" {
  name                       = "${var.environment}-${var.app_id}-${var.service_name}-dlq"
  message_retention_seconds  = var.message_retention_seconds
  visibility_timeout_seconds = var.visibility_timeout_seconds
  sqs_managed_sse_enabled    = true

  tags = {
    Environment = var.environment
    App         = var.app_id
  }
}

resource "aws_cloudwatch_metric_alarm" "dlq_not_empty" {
  alarm_name          = "${var.environment}-${var.app_id}-${var.service_name}-dlq-not-empty"
  alarm_description   = "Triggers when messages land in the ${var.service_name} DLQ, indicating processing failures."
  namespace           = "AWS/SQS"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  dimensions          = { QueueName = aws_sqs_queue.dlq.name }
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]

  tags = {
    Environment = var.environment
    App         = var.app_id
  }
}