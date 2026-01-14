resource "aws_sns_topic" "config_notifications" {
  count = var.is_security_account && var.create_sns_topic && var.sns_topic_arn == null ? 1 : 0
  name  = local.sns_topic_name

  tags = var.tags
}
