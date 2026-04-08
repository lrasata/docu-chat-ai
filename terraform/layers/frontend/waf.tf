resource "aws_wafv2_web_acl" "cloudfront_waf" {
  provider    = aws.us_east_1
  name        = "${var.environment}-${var.app_id}-cloudfront-waf"
  description = "WAF for CloudFront distribution"
  scope       = "CLOUDFRONT"

  tags = {
    Environment = var.environment
    App         = var.app_id
  }

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.environment}-${var.app_id}-CloudfrontWAF"
    sampled_requests_enabled   = true
  }

  # Managed rule group: common protections
  # covers SQL injection, XSS, and other common attacks.
  rule {
    name     = "${var.environment}-${var.app_id}-AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "managedRules"
      sampled_requests_enabled   = true
    }
  }

  # Rate-based rule to limit requests per IP
  rule {
    name     = "${var.environment}-${var.app_id}-RateLimitPerIP"
    priority = 2

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 1000 # requests per 5 minutes
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.environment}-${var.app_id}-rateLimit"
      sampled_requests_enabled   = true
    }
  }
}
