module "s3_static_web_files_bucket" {
  source      = "./modules/s3"
  environment = var.environment
  app_id      = var.app_id
}

module "cloudfront" {
  source = "./modules/cloudfront"

  environment                                     = var.environment
  app_id                                          = var.app_id
  s3_static_web_files_bucket_regional_domain_name = module.s3_static_web_files_bucket.s3_static_web_files_bucket_regional_domain_name
  uploads_bucket_regional_domain_name             = data.terraform_remote_state.backend.outputs.uploads_bucket_regional_domain_name
  file_upload_auth_secret                         = data.terraform_remote_state.security.outputs.file_upload_auth_secret
  cloudfront_certificate_arn                      = var.cloudfront_certificate_arn
  cloudfront_domain_name                          = var.cloudfront_domain_name
}

module "route53" {
  source = "./modules/route53"

  cdn_hosted_zone_id = module.cloudfront.cloudfront_hosted_zone_id
  cdn_domain_name    = module.cloudfront.cloudfront_domain_name
}