locals {

  # Central configuration map for all Lambdas
  lambda_configs = {
    # Configuration for LIST_FILES
    list_files = {
      base_name    = "${var.environment}-${var.app_id}-list-files"
      source_dir   = "${path.module}/src/lambdas_functions/list_files"
      handler_file = "index.handler"
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
      base_name    = "${var.environment}-${var.app_id}-get-file"
      source_dir   = "${path.module}/src/lambda_functions/get_file"
      handler_file = "index.handler"
      excludes     = []
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
            "s3:GetObjectTagging"
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
      base_name    = "${var.environment}-${var.app_id}-get-document-data"
      source_dir   = "${path.module}/src/lambda_functions/get_document_data"
      handler_file = "index.handler"
      excludes     = []
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
  }

}