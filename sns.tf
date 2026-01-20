resource "aws_sns_topic" "config_notifications" {
  count = var.is_security_account && var.create_sns_topic && var.sns_topic_arn == null ? 1 : 0
  name  = local.sns_topic_name

  tags = var.tags
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.is_security_account && var.create_sns_topic && var.sns_topic_arn == null && var.aws_config_notifications_email != null ? 1 : 0
  topic_arn = aws_sns_topic.config_notifications[0].arn
  protocol  = "email"
  endpoint  = var.aws_config_notifications_email
}

