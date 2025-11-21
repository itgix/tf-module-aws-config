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

resource "aws_config_delivery_channel" "member" {
  count          = var.is_security_account ? 0 : 1
  name           = local.delivery_name
  s3_bucket_name = local.central_bucket_name
  // TODO: create one in the module and provide option to just paass an existing one's ARN
  sns_topic_arn = var.sns_topic_arn == "" ? null : var.sns_topic_arn

  depends_on = [aws_config_configuration_recorder.member]
}

