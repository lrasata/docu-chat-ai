locals {
  s3_static_web_files_bucket_origin = "${var.environment}-${var.app_id}-s3-static-web-files-bucket-origin"
  s3_uploads_bucket_origin          = "${var.environment}-${var.app_id}-s3-uploads-bucket-origin"
  api_gw_file_uploader_origin       = "${var.environment}-${var.app_id}-file-uploader-api-gateway-origin"
}

resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  default_root_object = "index.html"
  is_ipv6_enabled     = true

  origin {
    domain_name              = var.s3_static_web_files_bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id # ensures that CloudFront can access the S3 bucket without making it public
    origin_id                = local.s3_static_web_files_bucket_origin
  }

  origin {
    domain_name              = var.uploads_bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
    origin_id                = local.s3_uploads_bucket_origin
  }

  origin {
    domain_name = var.api_file_upload_domain_name
    origin_id   = local.api_gw_file_uploader_origin

    custom_origin_config {
      origin_protocol_policy = "https-only"
      http_port              = 80 # required by Terraform but dont get confused only https is used
      https_port             = 443
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }
  # -------------------------
  # Default behavior for frontend (S3)
  # -------------------------
  default_cache_behavior {
    target_origin_id = local.s3_static_web_files_bucket_origin
    # Ensure any HTTP request from a user is redirected to HTTPS.
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400

    compress = true
  }

  # -------------------------
  # Behavior for File-uploader API GW
  # -------------------------
  ordered_cache_behavior {
    path_pattern           = "/api/upload*"
    target_origin_id       = local.api_gw_file_uploader_origin
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = true
      headers      = ["Authorization", "Content-Type"]
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  # -------------------------
  # Behavior for File-uploader API GW (files metadata)
  # -------------------------
  ordered_cache_behavior {
    path_pattern           = "/api/files*"
    target_origin_id       = local.api_gw_file_uploader_origin
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = true
      headers      = ["Authorization", "Content-Type"]
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.cloudfront_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  aliases = [var.cloudfront_domain_name]

  depends_on = [
    aws_cloudfront_origin_access_control.oac
  ]
}

resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "${var.environment}-s3-oac"
  description                       = "OAC for private S3 access"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}