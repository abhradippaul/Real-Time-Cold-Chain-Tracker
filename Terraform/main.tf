# module "s3_bucket_module" {
#   source = "./modules/s3_bucket"

#   bucket_name = var.bucket_name
#   tags        = var.tags
# }

module "lambda_module" {
  source = "./modules/lambda"

  function_name         = var.lambda_function_name
  source_path           = var.lambda_source_path
  handler               = var.lambda_handler
  runtime               = var.lambda_runtime
  tags                  = var.tags
  environment_variables = {}

}
