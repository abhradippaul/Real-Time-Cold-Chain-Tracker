variable "bucket_name" {
  type        = string
  description = "The name of the S3 bucket."
  default     = "real-time-cold-chain-tracker"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the S3 bucket."
  default = {
    Name        = "real-time-cold-chain-tracker"
    Environment = "Dev"
    Project     = "Real-Time Cold Chain Tracker"
  }
}

variable "lambda_function_name" {
  type        = string
  description = "The name of the Lambda function."
  default     = "real-time-cold-chain-tracker_validator"
}

variable "lambda_source_path" {
  type        = string
  description = "The path to the Lambda function code."
  default     = "../lambda/Validator"
}

variable "lambda_handler" {
  type        = string
  description = "The handler of the Lambda function."
  default     = "main.handler"
}

variable "lambda_runtime" {
  type        = string
  description = "The runtime of the Lambda function."
  default     = "python3.12"
}
