output "s3_bucket_name" {
  value = aws_s3_bucket.static_web_app_bucket.bucket
}

output "s3_bucket_arn" {
  value = aws_s3_bucket.static_web_app_bucket.arn
}

output "s3_bucket_regional_domain_name" {
  value = aws_s3_bucket.static_web_app_bucket.bucket_regional_domain_name
}