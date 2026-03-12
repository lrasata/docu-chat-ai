data "aws_caller_identity" "current" {}

locals {

  # Central configuration map for all Lambdas
  lambda_configs = {
    # Configuration for LIST_FILES
    list_files = {
      base_name    = "list-files"
      source_dir   = "${path.module}/src/lambda_functions/list_files"
      handler_file = "index.handler"
      runtime      = "nodejs22.x"
      timeout      = 5
      memory_size  = 128
      s3_bucket    = null
      s3_key       = null
      # Variables unique to this Lambda
      environment_vars = {
        UPLOADS_BUCKET  = module.file_uploader.uploads_bucket_id
        DOCUMENTS_TABLE = module.file_uploader.dynamo_db_table_name
      }
      # Policy unique to this Lambda
      iam_policy_statements = [
        {
          Effect = "Allow"
          Action = [
            "dynamodb:Query",
            "dynamodb:Scan"
          ]
          Resource = [module.file_uploader.dynamo_db_table_arn]
        }
      ]
    }
    # Configuration for GET_FILE
    get_file = {
      base_name    = "get-file"
      source_dir   = "${path.module}/src/lambda_functions/get_file"
      handler_file = "index.handler"
      runtime      = "nodejs22.x"
      timeout      = 5
      memory_size  = 128
      s3_bucket    = null
      s3_key       = null
      # Variables unique to this Lambda
      environment_vars = {
        UPLOADS_BUCKET = module.file_uploader.uploads_bucket_id
      }
      # Policy unique to this Lambda
      iam_policy_statements = [
        {
          Effect = "Allow"
          Action = [
            "s3:GetObject",
            "s3:GetObjectTagging",
            "s3:ListBucket"
          ]
          Resource = [
            "arn:aws:s3:::${module.file_uploader.uploads_bucket_id}",
            "arn:aws:s3:::${module.file_uploader.uploads_bucket_id}/*"
          ]
        },

      ]
    }

    # Configuration for GET_DOCUMENT_DATA
    get_document_data = {
      base_name    = "get-document-data"
      source_dir   = "${path.module}/src/lambda_functions/get_document_data"
      handler_file = "index.handler"
      runtime      = "nodejs22.x"
      timeout      = 5
      memory_size  = 128
      s3_bucket    = null
      s3_key       = null
      # Variables unique to this Lambda
      environment_vars = {
        DOCUMENTS_TABLE = module.file_uploader.dynamo_db_table_name
      }
      # Policy unique to this Lambda
      iam_policy_statements = [
        {
          Effect = "Allow"
          Action = [
            "dynamodb:GetItem"
          ]
          Resource = [module.file_uploader.dynamo_db_table_arn]
        },

      ]
    }

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
        OPENSEARCH_ENDPOINT = module.opensearchserverless.opensearch_collection_endpoint
        OPENSEARCH_INDEX    = "${var.environment}-${var.app_id}-index"
        REGION              = var.region
      }
      # Policy unique to this Lambda
      iam_policy_statements = [
        {
          Effect = "Allow"
          Action = [
            "aoss:APIAccessAll"
          ]
          Resource = [module.opensearchserverless.opensearch_collection_arn]
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
        }
      ]
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
        OPENSEARCH_ENDPOINT = module.opensearchserverless.opensearch_collection_endpoint
        OPENSEARCH_INDEX    = "${var.environment}-${var.app_id}-index"
        REGION              = var.region
        DOCUMENTS_TABLE     = module.file_uploader.dynamo_db_table_name
        BEDROCK_MODEL_INFERENCE_PROFILE_ARN    = var.bedrock_model_inference_profile_arn
        MAX_SEARCH_RESULTS  = var.max_search_results
      }
      # Policy unique to this Lambda
      iam_policy_statements = [
        {
          Effect = "Allow"
          Action = [
            "aoss:APIAccessAll"
          ]
          Resource = [module.opensearchserverless.opensearch_collection_arn]
        },
        {
          Effect = "Allow"
          Action = [
            "bedrock:InvokeModel"
          ]
          Resource = [
            "arn:aws:bedrock:${var.region}::foundation-model/amazon.titan-embed-text-v1",
            "arn:aws:bedrock:${var.region}::foundation-model/eu.anthropic.claude-sonnet-4-20250514-v1:0",
            "arn:aws:bedrock:${var.region}:${data.aws_caller_identity.current.account_id}:inference-profile/eu.anthropic.claude-sonnet-4-20250514-v1:0",
          ]
        },
        {
          Effect = "Allow"
          Action = [
            "dynamodb:GetItem"
          ]
          Resource = [module.file_uploader.dynamo_db_table_arn]
        }
      ]
    }
  }

}