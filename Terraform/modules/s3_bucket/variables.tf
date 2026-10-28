variable "bucket_name" {
  type        = string
  description = "The name of the S3 bucket."
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the S3 bucket."
  default     = {}
}

variable "lambda_function_arn" {
  type        = string
  description = "The ARN of the Lambda function."
}

