output "sqs_queue_url" {
  value       = aws_sqs_queue.this.id
  description = "The URL of the SQS queue"
}

output "sqs_queue_arn" {
  value       = aws_sqs_queue.this.arn
  description = "The ARN of the SQS queue"
}
