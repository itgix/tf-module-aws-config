# Config Recorder (Member Accounts Only)
resource "aws_config_configuration_recorder" "member" {
  count    = var.is_security_account ? 0 : 1
  name     = local.recorder_name
  role_arn = aws_iam_role.config_role.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }

  depends_on = [aws_iam_role_policy_attachment.config_policy_attach]
}

resource "aws_config_configuration_recorder_status" "member" {
  count      = var.is_security_account ? 0 : 1
  name       = local.recorder_name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.member]
}

resource "aws_config_delivery_channel" "member_acc" {
  count          = var.is_security_account ? 0 : 1
  name           = local.delivery_name
  s3_bucket_name = var.aws_config_central_bucket_name
  // if no SNS topic ARN is passed, the module will create one and use it
  sns_topic_arn = var.sns_topic_arn != null ? var.sns_topic_arn : (var.is_security_account && var.create_sns_topic ? aws_sns_topic.config_notifications[0].arn : null)

  depends_on = [aws_config_configuration_recorder.member]
}

resource "aws_config_delivery_channel" "security_acc" {
  count          = var.is_security_account ? 1 : 0
  name           = local.delivery_name
  s3_bucket_name = var.aws_config_central_bucket_name
  sns_topic_arn  = var.sns_topic_arn != null ? var.sns_topic_arn : (var.create_sns_topic ? aws_sns_topic.config_notifications[0].arn : null)
}
