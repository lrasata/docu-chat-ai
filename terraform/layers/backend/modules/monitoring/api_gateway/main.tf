#############################################
# CLOUDWATCH DASHBOARD
#############################################
resource "aws_cloudwatch_dashboard" "api_gateway_dashboard" {
  dashboard_name = "${var.api_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      # -------------------------
      # Latency
      # -------------------------
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApiGateway", "Latency", "ApiName", var.api_name]
          ]
          period      = 60
          stat        = "Average"
          title       = "API Gateway Latency (ms)"
          region      = var.region
          view        = "timeSeries"
          annotations = {}
        }
      },

      # -------------------------
      # 4XX & 5XX Errors
      # -------------------------
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApiGateway", "4XXError", "ApiName", var.api_name, { stat : "Sum" }],
            ["AWS/ApiGateway", "5XXError", "ApiName", var.api_name, { stat : "Sum" }]
          ]
          period      = 60
          stat        = "Sum"
          title       = "API Gateway Errors"
          region      = var.region
          view        = "timeSeries"
          annotations = {}
        }
      }
    ]
  })
}

#############################################
# ALARMS: 4XX & 5XX Errors
#############################################
resource "aws_cloudwatch_metric_alarm" "api_4xx_alarm" {
  alarm_name          = "${var.api_name}-4xx-errors"
  alarm_description   = "Triggers if API Gateway 4XX errors exceed threshold"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  period              = 60
  metric_name         = "4XXError"
  namespace           = "AWS/ApiGateway"
  statistic           = "Sum"
  threshold           = 5

  dimensions = {
    ApiName = var.api_name
  }

  alarm_actions = [var.sns_topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "api_5xx_alarm" {
  alarm_name          = "${var.api_name}-5xx-errors"
  alarm_description   = "Triggers if API Gateway 5XX errors exceed threshold"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  period              = 60
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGateway"
  statistic           = "Sum"
  threshold           = 5

  dimensions = {
    ApiName = var.api_name
  }

  alarm_actions = [var.sns_topic_arn]
}