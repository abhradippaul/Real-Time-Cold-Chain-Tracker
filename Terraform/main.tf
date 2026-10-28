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

  function_name = var.lambda_function_name_processor
  source_path   = var.lambda_source_path_processor
  handler       = var.lambda_handler
  runtime       = var.lambda_runtime
  tags          = var.tags
  sqs_arn       = module.sqs_module.sqs_queue_arn
  environment_variables = {
    "QUEUE_URL" = module.sqs_module.sqs_queue_url

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

module "s3_bucket_module" {
  source = "./modules/s3_bucket"

  bucket_name         = var.bucket_name
  tags                = var.tags
  lambda_function_arn = module.lambda_module_validator.lambda_function_arn
}

