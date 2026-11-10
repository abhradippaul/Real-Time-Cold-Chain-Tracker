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
  name               = "lambda_execution_role_processor"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_sqs_execution" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
}

data "aws_iam_policy_document" "lambda_dynamodb_put_policy" {
  statement {
    effect = "Allow"

    # principals {
    #   type        = "Service"
    #   identifiers = ["dynamodb.amazonaws.com"]
    # }

    actions   = ["dynamodb:PutItem"]
    resources = [var.dynamodb_arn]
  }
}

resource "aws_iam_policy" "lambda_dynamodb_put_policy" {
  name   = "lambda_dynamodb_put_policy"
  policy = data.aws_iam_policy_document.lambda_dynamodb_put_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.lambda_dynamodb_put_policy.arn
}

data "aws_iam_policy_document" "lambda_sns_policy" {
  statement {
    effect = "Allow"

    actions   = ["sns:Publish"]
    resources = [var.sns_arn]
  }
}

resource "aws_iam_policy" "lambda_sns_policy" {
  name   = "lambda_sns_policy"
  policy = data.aws_iam_policy_document.lambda_sns_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_sns" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.lambda_sns_policy.arn
}

data "aws_iam_policy_document" "lambda_secrets_policy" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = var.database_secret_arn != "" ? [var.database_secret_arn] : ["*"]
  }
}

resource "aws_iam_policy" "lambda_secrets_policy" {
  name   = "${var.function_name}_secrets_policy"
  policy = data.aws_iam_policy_document.lambda_secrets_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_secrets" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.lambda_secrets_policy.arn
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# Build package with dependencies using local-exec
resource "terraform_data" "lambda_package" {
  triggers_replace = [
    filesha256("${var.source_path}/requirements.txt"),
    filesha256("${var.source_path}/main.py")
  ]

  provisioner "local-exec" {
    command = <<EOT
      mkdir -p ${var.source_path}/package
      pip install \
        --platform manylinux2014_x86_64 \
        --target ${var.source_path}/package \
        --implementation cp \
        --python-version ${replace(var.runtime, "python", "")} \
        --only-binary=:all: \
        --upgrade \
        -r ${var.source_path}/requirements.txt
      cp ${var.source_path}/main.py ${var.source_path}/package/main.py
    EOT
  }
}

# Package the Lambda function code
data "archive_file" "this" {
  type        = "zip"
  source_dir  = "${var.source_path}/package"
  output_path = "${var.source_path}/function.zip"
  depends_on  = [terraform_data.lambda_package]
}

# Lambda function
resource "aws_lambda_function" "this" {
  filename      = data.archive_file.this.output_path
  function_name = var.function_name
  role          = aws_iam_role.this.arn
  handler       = var.handler
  code_sha256   = data.archive_file.this.output_base64sha256

  runtime = var.runtime

  # Advanced logging configuration
  logging_config {
    log_format            = "JSON"
    application_log_level = "INFO"
    system_log_level      = "INFO"
  }

  # Ensure log group and IAM policies exist before function
  depends_on = [
    aws_cloudwatch_log_group.this,
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_iam_role_policy_attachment.lambda_sqs_execution,
    aws_iam_role_policy_attachment.lambda_dynamodb,
    aws_iam_role_policy_attachment.lambda_sns,
    aws_iam_role_policy_attachment.lambda_secrets
  ]

  environment {
    variables = var.environment_variables
  }

  tags = var.tags
}

resource "aws_lambda_event_source_mapping" "this" {
  event_source_arn = var.sqs_arn
  function_name    = aws_lambda_function.this.arn
  batch_size       = 10

  scaling_config {
    maximum_concurrency = 100
  }
}
