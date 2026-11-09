output "sns_arn" {
  value = aws_sns_topic.this.arn
}

output "sns_name" {
  value = aws_sns_topic.this.name
}
