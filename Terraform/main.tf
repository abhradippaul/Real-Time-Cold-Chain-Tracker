module "lambda_module_validator" {
  source = "./modules/lambda-validator"

  function_name = var.lambda_function_name_validator
  source_path   = var.lambda_source_path_validator
  handler       = var.lambda_handler
  runtime       = var.lambda_runtime
  tags          = var.tags
  s3_bucket_arn = module.s3_bucket_module.s3_bucket_arn
  sqs_arn       = module.sqs_module.sqs_queue_arn
  environment_variables = {
    "QUEUE_URL" = module.sqs_module.sqs_queue_url

  }
}

module "lambda_module_processor" {
  source = "./modules/lambda-processor"

  function_name       = var.lambda_function_name_processor
  source_path         = var.lambda_source_path_processor
  handler             = var.lambda_handler
  runtime             = var.lambda_runtime
  tags                = var.tags
  sqs_arn             = module.sqs_module.sqs_queue_arn
  dynamodb_arn        = module.dynamodb_table_module.arn
  sns_arn             = module.sns_module.sns_arn
  database_secret_arn = module.database_module.database_secret_arn
  database_name       = var.database_name
  environment_variables = {
    "QUEUE_URL"           = module.sqs_module.sqs_queue_url
    "DYNAMODB_TABLE_NAME" = module.dynamodb_table_module.name
    "TOPIC_ARN"           = module.sns_module.sns_arn
    "SECRET_ID"           = module.database_module.database_secret_arn
    "DB_HOST"             = module.database_module.database_address
    "DB_PORT"             = tostring(module.database_module.database_port)
    "DB_NAME"             = var.database_name
  }
}

module "sqs_module" {
  source = "./modules/sqs"

  name                       = var.sqs_name
  delay_seconds              = var.sqs_queue_delay_seconds
  max_message_size           = var.sqs_queue_max_message_size
  message_retention_seconds  = var.sqs_queue_message_retention_seconds
  receive_wait_time_seconds  = var.sqs_queue_receive_wait_time_seconds
  visibility_timeout_seconds = var.sqs_queue_visibility_timeout_seconds
  tags                       = var.tags
  source_arn                 = module.lambda_module_validator.lambda_function_arn
}

module "dynamodb_table_module" {
  source = "./modules/dynamodb"

  hash_key  = var.dynamodb_hash_key
  range_key = var.dynamodb_range_key
  tags      = var.tags
  name      = var.dynamodb_table_name
}

module "sns_module" {
  source   = "./modules/sns"
  sns_name = var.sns_name
  tags     = var.tags
}

module "database_module" {
  source              = "./modules/database"
  db_name             = var.database_name
  db_username         = var.database_username
  engine              = var.database_engine
  engine_version      = var.database_engine_version
  instance_class      = var.database_instance_class
  allocated_storage   = var.database_allocated_storage
  allowed_cidr_blocks = var.database_allowed_cidr_blocks
  database_identifier = var.database_identifier
  tags                = var.tags
}

module "s3_bucket_module" {
  source = "./modules/s3_bucket"

  bucket_name         = var.bucket_name
  tags                = var.tags
  lambda_function_arn = module.lambda_module_validator.lambda_function_arn
}

