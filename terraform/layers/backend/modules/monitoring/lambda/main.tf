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

#############################################
# ALARMS: Bedrock Embedding Latency (custom metric)
#############################################
resource "aws_cloudwatch_metric_alarm" "bedrock_embedding_latency" {
  count = var.bedrock_embedding_latency_threshold_ms != null ? 1 : 0

  alarm_name          = "${var.function_name}-bedrock-embedding-latency"
  alarm_description   = "Triggers if Bedrock embedding latency exceeds threshold"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  period              = 60
  metric_name         = "EmbeddingLatency"
  namespace           = "DocuChatAI/Bedrock"
  statistic           = "p99"
  threshold           = var.bedrock_embedding_latency_threshold_ms

  dimensions = {
    FunctionName = var.function_name
  }

  treat_missing_data = "notBreaching"
  alarm_actions      = [var.sns_topic_arn]
}

#############################################
# ALARMS: Bedrock LLM Latency (custom metric)
#############################################
resource "aws_cloudwatch_metric_alarm" "bedrock_llm_latency" {
  count = var.bedrock_llm_latency_threshold_ms != null ? 1 : 0

  alarm_name          = "${var.function_name}-bedrock-llm-latency"
  alarm_description   = "Triggers if Bedrock LLM latency exceeds threshold"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  period              = 60
  metric_name         = "LLMLatency"
  namespace           = "DocuChatAI/Bedrock"
  statistic           = "p99"
  threshold           = var.bedrock_llm_latency_threshold_ms

  dimensions = {
    FunctionName = var.function_name
  }

  treat_missing_data = "notBreaching"
  alarm_actions      = [var.sns_topic_arn]
}
