data "aws_caller_identity" "current" {}

locals {

  # Central configuration map for all Lambdas
  lambda_configs = {
    # s3 document ingestion lambda
    s3_ingestion = {
      base_name    = "s3-ingestion"
      source_dir   = "${path.module}/src/lambda_functions/s3_ingestion"
      handler_file = "s3_ingestion.handler"
      runtime      = "python3.11"
      timeout      = 120
      memory_size  = 512
      s3_bucket    = var.s3_ingestion_lambda_code_bucket
      s3_key       = var.s3_ingestion_lambda_code_key
      # Variables unique to this Lambda
      environment_vars = {
        RDS_SECRET_ARN  = module.rds.rds_secret_arn
        DOCUMENTS_TABLE = module.file_uploader.dynamo_db_table_name
        REGION          = var.region
      }
      # Policy unique to this Lambda
      iam_policy_statements = [
        {
          Effect   = "Allow"
          Action   = ["secretsmanager:GetSecretValue"]
          Resource = [module.rds.rds_secret_arn]
        },
        {
          Effect = "Allow"
          Action = [
            "s3:GetObject",
            "s3:ListBucket"
          ]
          Resource = [
            "arn:aws:s3:::${module.file_uploader.uploads_bucket_id}",
            "arn:aws:s3:::${module.file_uploader.uploads_bucket_id}/*"
          ]
        },
        {
          Effect   = "Allow"
          Action   = ["bedrock:InvokeModel"]
          Resource = ["arn:aws:bedrock:${var.region}::foundation-model/amazon.titan-embed-text-v1"]
        },
        {
          Effect   = "Allow",
          Action   = ["dynamodb:UpdateItem"],
          Resource = [module.file_uploader.dynamo_db_table_arn]
        },
        {
          Effect   = "Allow"
          Action   = ["sqs:SendMessage"]
          Resource = [module.s3_ingestion_dlq.dlq_arn]
        }
      ]
      # Wiring: SNS trigger + DLQ on failure
      function_url          = null
      enable_sns_trigger    = true
      sns_trigger_arn       = module.file_uploader.sns_topic_arn_processed_file_event
      sns_redrive_dlq_arn   = module.s3_ingestion_dlq.dlq_arn
      enable_dlq_on_failure = true
      dlq_on_failure_arn    = module.s3_ingestion_dlq.dlq_arn
    }

    # RAG evaluation lambda — runs the golden-dataset evaluation pipeline
    rag_evaluation = {
      base_name    = "rag-evaluation"
      source_dir   = "${path.module}/src/lambda_functions/rag_evaluation"
      handler_file = "rag_evaluation.handler"
      runtime      = "python3.11"
      timeout      = 900 # 15 min: ingestion poll (up to 10 min) + evaluation loop
      memory_size  = 256
      s3_bucket    = null
      s3_key       = null
      environment_vars = {
        REGION          = var.region
        UPLOADS_BUCKET  = module.file_uploader.uploads_bucket_id
        DOCUMENTS_TABLE = module.file_uploader.dynamo_db_table_name
        # Constructed inline to avoid circular dependency with the lambda_functions for_each
        QUERY_DOCUMENT_LAMBDA_NAME          = "${var.environment}-${var.app_id}-query-document-lambda"
        BEDROCK_MODEL_INFERENCE_PROFILE_ARN = var.bedrock_model_inference_profile_arn
        RESULTS_BUCKET                      = module.file_uploader.uploads_bucket_id
      }
      iam_policy_statements = [
        {
          Effect = "Allow"
          Action = [
            "s3:HeadObject",
            "s3:GetObject",
            "s3:PutObject",
            "s3:ListBucket"
          ]
          Resource = [
            "arn:aws:s3:::${module.file_uploader.uploads_bucket_id}",
            "arn:aws:s3:::${module.file_uploader.uploads_bucket_id}/*"
          ]
        },
        {
          Effect   = "Allow"
          Action   = ["dynamodb:Scan"]
          Resource = [module.file_uploader.dynamo_db_table_arn]
        },
        {
          Effect   = "Allow"
          Action   = ["lambda:InvokeFunction"]
          Resource = ["arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:${var.environment}-${var.app_id}-query-document-lambda"]
        },
        {
          Effect   = "Allow"
          Action   = ["bedrock:InvokeModel"]
          Resource = concat([var.bedrock_model_inference_profile_arn], var.bedrock_foundation_model_arns)
        }
      ]
      # Wiring: no trigger, no DLQ, no function URL
      function_url          = null
      enable_sns_trigger    = false
      sns_trigger_arn       = null
      sns_redrive_dlq_arn   = null
      enable_dlq_on_failure = false
      dlq_on_failure_arn    = null
    }

    # Query document lambda for chat functionality
    query_document = {
      base_name    = "query-document"
      source_dir   = "${path.module}/src/lambda_functions/query_document"
      handler_file = "query_document.handler"
      runtime      = "python3.11"
      timeout      = 120
      memory_size  = 512
      s3_bucket    = var.s3_query_document_lambda_code_bucket
      s3_key       = var.s3_query_document_lambda_code_key
      # Variables unique to this Lambda
      environment_vars = {
        RDS_SECRET_ARN                      = module.rds.rds_secret_arn
        REGION                              = var.region
        DOCUMENTS_TABLE                     = module.file_uploader.dynamo_db_table_name
        BEDROCK_MODEL_INFERENCE_PROFILE_ARN = var.bedrock_model_inference_profile_arn
        TEMPERATURE                         = var.llm_temperature
        LLM_MAX_TOKENS                      = var.llm_max_tokens
        MAX_SEARCH_RESULTS                  = var.max_search_results
        BEDROCK_GUARDRAIL_ID                = module.bedrock_guardrails.guardrail_id
        BEDROCK_GUARDRAIL_VERSION           = module.bedrock_guardrails.guardrail_version
        COGNITO_USER_POOL_ID                = data.terraform_remote_state.cognito.outputs.cognito_user_pool_id
        COGNITO_CLIENT_ID                   = data.terraform_remote_state.cognito.outputs.cognito_user_pool_client_id
      }
      # Policy unique to this Lambda
      iam_policy_statements = [
        {
          Effect   = "Allow"
          Action   = ["secretsmanager:GetSecretValue"]
          Resource = [module.rds.rds_secret_arn]
        },
        {
          Effect = "Allow"
          Action = [
            "bedrock:InvokeModel",
            "bedrock:InvokeModelWithResponseStream" # required for converse_stream()
          ]
          Resource = concat(
            # Titan Embeddings is kept explicit — it serves a different role (embeddings, not LLM)
            ["arn:aws:bedrock:${var.region}::foundation-model/amazon.titan-embed-text-v1", var.bedrock_model_inference_profile_arn],
            var.bedrock_foundation_model_arns
          )
        },
        {
          Effect   = "Allow"
          Action   = ["bedrock:ApplyGuardrail"]
          Resource = [module.bedrock_guardrails.guardrail_arn]
        },
        {
          Effect = "Allow"
          Action = [
            "aws-marketplace:ViewSubscriptions",
            "aws-marketplace:Subscribe",
            "aws-marketplace:Unsubscribe"
          ]
          Resource = ["*"]
        },
        {
          Effect = "Allow"
          Action = [
            "dynamodb:GetItem"
          ]
          Resource = [module.file_uploader.dynamo_db_table_arn, module.bedrock_guardrails.guardrail_arn]
        }
      ]
      # Wiring: streaming function URL, no SNS trigger, no DLQ
      enable_sns_trigger    = false
      sns_trigger_arn       = null
      sns_redrive_dlq_arn   = null
      enable_dlq_on_failure = false
      dlq_on_failure_arn    = null
      function_url = {
        auth_type         = "NONE"
        invoke_mode       = "RESPONSE_STREAM"
        allow_credentials = true
        cors_origins      = ["https://${var.cloudfront_domain_name}"]
        cors_methods      = ["POST", "OPTIONS"]
        cors_headers      = ["authorization", "content-type"]
        expose_headers    = ["content-type"]
        max_age           = 86400
      }
    }
  }

}