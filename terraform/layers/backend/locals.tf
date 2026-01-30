locals {

  # Central configuration map for all Lambdas
  lambda_configs = {
    # Configuration for LIST_FILES
    list_files = {
      base_name    = "list-files"
      source_dir   = "${path.module}/src/lambda_functions/list_files"
      handler_file = "index.handler"
      runtime      = "nodejs22.x"
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
          Resource = module.file_uploader.dynamo_db_table_arn
        }
      ]
    }
    # Configuration for GET_FILE
    get_file = {
      base_name    = "get-file"
      source_dir   = "${path.module}/src/lambda_functions/get_file"
      handler_file = "index.handler"
      runtime      = "nodejs22.x"
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
          Resource = module.file_uploader.dynamo_db_table_arn
        },

      ]
    }

    # s3 document ingestion lambda
    s3_ingestion = {
      base_name    = "s3-ingestion"
      source_dir   = "${path.module}/src/lambda_functions/s3_ingestion"
      handler_file = "s3_ingestion.handler"
      runtime      = "python3.11"
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
          Resource = module.opensearchserverless.opensearch_collection_arn
        }
      ]
    }
  }

}