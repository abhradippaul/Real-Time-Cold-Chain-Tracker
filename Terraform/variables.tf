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

variable "lambda_function_name_validator" {
  type        = string
  description = "The name of the Lambda function."
  default     = "real-time-cold-chain-tracker_validator"
}

variable "lambda_source_path_validator" {
  type        = string
  description = "The path to the Lambda function code."
  default     = "../lambda/Validator"
}

variable "lambda_function_name_processor" {
  type        = string
  description = "The name of the Lambda function."
  default     = "real-time-cold-chain-tracker_processor"
}

variable "lambda_source_path_processor" {
  type        = string
  description = "The path to the Lambda function code."
  default     = "../lambda/Processor"
}

variable "lambda_handler" {
  type        = string
  description = "The handler of the Lambda function."
  default     = "main.handler"
}

variable "lambda_runtime" {
  type        = string
  description = "The runtime of the Lambda function."
  default     = "python3.13"
}

variable "sqs_name" {
  type        = string
  description = "The name of the SQS queue."
  default     = "real-time-cold-chain-tracker-sqs"
}

variable "sqs_queue_delay_seconds" {
  type        = number
  description = "The delay of the SQS queue."
  default     = 0
}

variable "sqs_queue_max_message_size" {
  type        = number
  description = "The maximum message size of the SQS queue."
  default     = 262144
}

variable "sqs_queue_message_retention_seconds" {
  type        = number
  description = "The message retention period of the SQS queue."
  default     = 345600
}

variable "sqs_queue_receive_wait_time_seconds" {
  type        = number
  description = "The receive wait time of the SQS queue."
  default     = 0
}

variable "sqs_queue_visibility_timeout_seconds" {
  type        = number
  description = "The visibility timeout of the SQS queue."
  default     = 30
}
