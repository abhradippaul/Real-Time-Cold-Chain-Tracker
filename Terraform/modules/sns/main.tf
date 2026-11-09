resource "aws_sns_topic" "this" {
  name = var.sns_name

  tags = var.tags
}

resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.this.arn
  protocol  = "email"
  endpoint  = "abhradipserampore@gmail.com"
}
