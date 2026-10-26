# IAM role for Lambda execution
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "this" {
  name               = "lambda_execution_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# Package the Lambda function code
data "archive_file" "this" {
  type        = "zip"
  source_file = "${var.source_path}/main.py"
  output_path = "${var.source_path}/function.zip"
}

# Lambda function
resource "aws_lambda_function" "this" {
  filename      = data.archive_file.this.output_path
  function_name = var.function_name
  role          = aws_iam_role.this.arn
  handler       = var.handler
  code_sha256   = data.archive_file.this.output_base64sha256

  runtime = var.runtime

  environment {
    variables = var.environment_variables
  }

  tags = var.tags
}

