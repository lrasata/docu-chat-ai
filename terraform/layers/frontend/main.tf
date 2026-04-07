module "s3_static_web_files_bucket" {
  source      = "./modules/s3"
  environment = var.environment
  app_id      = var.app_id
}

module "cloudfront" {
  source = "./modules/cloudfront"

  environment                                     = var.environment
  app_id                                          = var.app_id
  s3_static_web_files_bucket_regional_domain_name = module.s3_static_web_files_bucket.s3_bucket_regional_domain_name
  uploads_bucket_regional_domain_name             = data.terraform_remote_state.backend.outputs.uploads_bucket_regional_domain_name
  cloudfront_certificate_arn                      = var.cloudfront_certificate_arn
  cloudfront_domain_name                          = var.cloudfront_domain_name
  api_file_upload_domain_name                     = data.terraform_remote_state.backend.outputs.api_file_upload_domain_name
}

# For the static web app bucket
module "static_web_app_policy" {
  source = "./modules/cloudfront_s3_bucket_policy"

  bucket_id      = module.s3_static_web_files_bucket.s3_bucket_name
  bucket_arn     = module.s3_static_web_files_bucket.s3_bucket_arn
  cloudfront_arn = module.cloudfront.cloudfront_arn
  paths          = ["*"]
}

# For the uploads bucket
module "uploads_bucket_policy" {
  source = "./modules/cloudfront_s3_bucket_policy"

  bucket_id      = try(data.terraform_remote_state.backend.outputs.uploads_bucket_id, "uploads-bucket-id-placeholder")
  bucket_arn     = try(data.terraform_remote_state.backend.outputs.uploads_bucket_arn, "uploads-bucket-arn-placeholder")
  cloudfront_arn = module.cloudfront.cloudfront_arn
  paths          = ["uploads/*", "thumbnails/*"]
}

module "route53" {
  source = "./modules/route53"

  cdn_hosted_zone_id = module.cloudfront.cloudfront_hosted_zone_id
  cdn_domain_name    = module.cloudfront.cloudfront_domain_name
  alt_domain_name    = var.cloudfront_domain_name
}