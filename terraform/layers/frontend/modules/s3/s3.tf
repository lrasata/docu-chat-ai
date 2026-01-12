resource "aws_s3_bucket" "static_web_app_bucket" {
  bucket = "${var.environment}-${var.app_id}-static-web-app-bucket"
}

#  Block public access to the S3 bucket
resource "aws_s3_bucket_public_access_block" "s3-bucket" {
  bucket                  = aws_s3_bucket.static_web_app_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}