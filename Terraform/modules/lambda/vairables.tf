variable "function_name" {
  type        = string
  description = "The name of the Lambda function."
}

variable "source_path" {
  type        = string
  description = "The path to the Lambda function code."
}

variable "handler" {
  type        = string
  description = "The handler of the Lambda function."
}

variable "runtime" {
  type        = string
  description = "The runtime of the Lambda function."
}

variable "environment_variables" {
  type        = map(string)
  description = "The environment variables of the Lambda function."
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the Lambda function."
  default     = {}
}
