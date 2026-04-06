module "rds" {
  source = "./modules/rds"

  environment        = var.environment
  app_id             = var.app_id
  region             = var.region
  availability_zones = var.availability_zones
  db_instance_class  = var.db_instance_class
}

module "bedrock_guardrails" {
  source = "./modules/bedrock-guardrails"

  environment = var.environment
  app_id      = var.app_id
}

module "dlq_is_not_empty_sns" {
  source = "./modules/sns"

  app_id       = var.app_id
  environment  = var.environment
  service_name = "s3-ingestion"
}

module "s3_ingestion_dlq" {
  source = "./modules/dlq"

  app_id        = var.app_id
  environment   = var.environment
  service_name  = "s3-ingestion"
  sns_topic_arn = module.dlq_is_not_empty_sns.sns_topic_arn

  depends_on = [module.dlq_is_not_empty_sns]
}

module "lambda_functions" {
  source = "./modules/lambda_function"

  # for_each to loop over lambda_configs to set up s3_ingestion and query_document lambdas
  for_each = local.lambda_configs

  # Pass common variables
  environment = var.environment
  app_id      = var.app_id

  # Pass variables specific to the current iteration (key is the map key, value is the map content)
  lambda_name           = each.value.base_name
  source_dir            = each.value.source_dir
  handler_file          = each.value.handler_file
  runtime               = each.value.runtime
  timeout               = each.value.timeout
  memory_size           = each.value.memory_size
  environment_vars      = each.value.environment_vars
  s3_bucket             = each.value.s3_bucket != null ? each.value.s3_bucket : ""
  s3_key                = each.value.s3_key != null ? each.value.s3_key : ""
  iam_policy_statements = each.value.iam_policy_statements
  function_url          = each.value.function_url
  sns_trigger_arn       = each.value.sns_trigger_arn
  sns_redrive_dlq_arn   = each.value.sns_redrive_dlq_arn
  dlq_on_failure_arn    = each.value.dlq_on_failure_arn

  vpc_subnet_ids         = module.rds.private_subnet_ids
  vpc_security_group_ids = [module.rds.lambda_security_group_id]

  depends_on = [module.rds, module.s3_ingestion_dlq]
}

module "file_uploader" {
  source = "git::https://github.com/lrasata/infra-file-uploader//terraform/modules/file_uploader?ref=v1.8.0"

  region                                        = var.region
  app_id                                        = var.app_id
  environment                                   = var.environment
  api_file_upload_domain_name                   = var.api_file_upload_domain_name
  backend_certificate_arn                       = var.backend_certificate_arn
  uploads_bucket_name                           = var.uploads_bucket_name
  enable_transfer_acceleration                  = var.enable_transfer_acceleration
  lambda_upload_presigned_url_expiration_time_s = var.lambda_upload_presigned_url_expiration_time_s
  bucket_av_sns_findings_topic_name             = var.bucket_av_sns_findings_topic_name
  lambda_memory_size_mb                         = var.lambda_memory_size_mb
  notification_email                            = var.notification_email
  route53_zone_name                             = var.route53_zone_name
  cloudfront_domain_name                        = var.cloudfront_domain_name
  cognito_user_pool_client_id                   = data.terraform_remote_state.cognito.outputs.cognito_user_pool_client_id
  cognito_user_pool_id                          = data.terraform_remote_state.cognito.outputs.cognito_user_pool_id
}
