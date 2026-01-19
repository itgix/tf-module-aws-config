// Check if there are log groups that have never expire
resource "aws_config_organization_managed_rule" "cw_log_retention_check" {
  count           = var.is_security_account && var.cloudwatch_log_retention_remediation ? 1 : 0
  name            = "cloudwatch-log-group-retention-check"
  rule_identifier = "CLOUDWATCH_LOG_GROUP_RETENTION_PERIOD_CHECK"

  description = "Ensure CloudWatch Log Groups do not use Never Expire retention"

  input_parameters = jsonencode({
    MinRetentionTime = 1
  })
}

# Role used for auto-remediation to update log groups 
resource "aws_iam_role" "config_remediation_role" {
  count = var.cloudwatch_log_retention_remediation ? 1 : 0
  name  = "AWSConfigRemediation-CloudWatchLogRetention"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ssm.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "config_remediation_policy" {
  count = var.cloudwatch_log_retention_remediation ? 1 : 0
  role  = aws_iam_role.config_remediation_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:PutRetentionPolicy",
          "logs:DescribeLogGroups"
        ]
        Resource = "*"
      }
    ]
  })
}

// Used to handle automatic remediation of log groups that do not have a retention set
resource "aws_config_remediation_configuration" "cw_log_retention" {
  count            = var.cloudwatch_log_retention_remediation ? 1 : 0
  config_rule_name = "cloudwatch-log-group-retention-check"

  target_type = "SSM_DOCUMENT"
  target_id   = "AWSConfigRemediation-SetCloudWatchLogGroupRetention"

  automatic                  = true
  maximum_automatic_attempts = 3
  retry_attempt_seconds      = 60

  parameter {
    name         = "RetentionInDays"
    static_value = "365"
  }

  parameter {
    name = "AutomationAssumeRole"
    # static_value = "arn:aws:iam::${var.current_account_id}:role/AWSConfigRemediation-CloudWatchLogRetention"
    static_value = aws_iam_role.config_role[0].arn
  }

  resource_type = "AWS::Logs::LogGroup"
}
