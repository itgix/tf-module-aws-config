// Used to handle automatic remediation of log groups that do not have a retention set
resource "aws_iam_role" "config_remediation_role" {
  count = var.is_security_account && var.cloudwatch_log_retention_remediation ? 1 : 0
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
  count = var.is_security_account && var.cloudwatch_log_retention_remediation ? 1 : 0
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

// Check if there are log groups that have never expire
resource "aws_config_organization_managed_rule" "cw_log_retention_check" {
  count = var.is_security_account && var.cloudwatch_log_retention_remediation ? 1 : 0

  name            = "cloudwatch-log-group-retention-check"
  rule_identifier = "CLOUDWATCH_LOG_GROUP_RETENTION_PERIOD_CHECK"

  input_parameters = jsonencode({
    MinRetentionTime = 1
  })
}

// Automatically set expiration on any log group that is set to never expire
resource "aws_config_organization_remediation_configuration" "cw_log_retention_remediation" {
  count     = var.is_security_account && var.cloudwatch_log_retention_remediation ? 1 : 0
  rule_name = aws_config_organization_managed_rule.cw_log_retention_check[0].name

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
    name         = "AutomationAssumeRole"
    static_value = aws_iam_role.config_remediation_role[0].arn
  }

  resource_type = "AWS::Logs::LogGroup"
}
