# ============================================================================
# CloudWatch Log Group Retention Auto-Remediation
# ============================================================================
# This file contains all resources needed for organization-wide CloudWatch
# log group retention enforcement with automatic remediation.
#
# Resources created in Security Account (is_security_account = true):
#   - AWS Config Organization Rule
#   - SSM Automation Document
#   - IAM Role for remediation
#   - Config Remediation Configuration
#
# Resources created in Member Accounts (is_security_account = false):
#   - IAM Role for cross-account remediation
# ============================================================================

# ----------------------------------------------------------------------------
# Variables
# ----------------------------------------------------------------------------

variable "enable_cloudwatch_retention_remediation" {
  description = "Enable CloudWatch log group retention auto-remediation"
  type        = bool
  default     = false
}

variable "cloudwatch_retention_days" {
  description = "Default retention period in days for CloudWatch log groups"
  type        = number
  default     = 365
  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180,
      365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653
    ], var.cloudwatch_retention_days)
    error_message = "Retention days must be a valid CloudWatch Logs retention period."
  }
}

variable "security_account_id" {
  description = "AWS Account ID of the security account (delegated admin for Config)"
  type        = string
  default     = ""
}

# ----------------------------------------------------------------------------
# SECURITY ACCOUNT RESOURCES
# ----------------------------------------------------------------------------

# AWS Config Organization Rule
resource "aws_config_organization_managed_rule" "cloudwatch_log_retention" {
  count = var.is_security_account && var.enable_cloudwatch_retention_remediation ? 1 : 0

  name        = "cloudwatch-log-group-retention-check"
  description = "Checks that CloudWatch log groups have retention period set (not Never Expire)"

  rule_identifier = "CW_LOGGROUP_RETENTION_PERIOD_CHECK"

  # Apply to all accounts in the organization
  excluded_accounts = []

  depends_on = [aws_config_configuration_aggregator.org]
}

# SSM Automation Document for Remediation
resource "aws_ssm_document" "cloudwatch_retention_remediation" {
  count = var.is_security_account && var.enable_cloudwatch_retention_remediation ? 1 : 0

  name            = "ConfigRemediation-SetCloudWatchLogGroupRetention"
  document_type   = "Automation"
  document_format = "YAML"

  content = <<DOC
schemaVersion: '0.3'
description: |
  ### Document Name - ConfigRemediation-SetCloudWatchLogGroupRetention
  
  ## What does this document do?
  Sets the retention period for a CloudWatch Log Group to a specified number of days.
  
  ## Input Parameters
  * AutomationAssumeRole: (Required) The ARN of the role that allows Automation to perform actions.
  * LogGroupName: (Required) The name of the CloudWatch Log Group.
  * RetentionInDays: (Required) The number of days to retain log events.
  
  ## Output Parameters
  * SetLogGroupRetention.Output - Success message or failure exception.

assumeRole: '{{ AutomationAssumeRole }}'
parameters:
  AutomationAssumeRole:
    type: String
    description: (Required) The ARN of the role that allows Automation to perform actions.
    allowedPattern: '^arn:aws[a-z0-9-]*:iam::\d{12}:role\/[\w-\/.@+=,]{1,1017}$$'
  LogGroupName:
    type: String
    description: (Required) The name of the CloudWatch Log Group.
    allowedPattern: '[\.\-_/#A-Za-z0-9]+'
  RetentionInDays:
    type: Integer
    description: (Required) The number of days to retain log events.
    default: ${var.cloudwatch_retention_days}
    allowedValues:
      - 1
      - 3
      - 5
      - 7
      - 14
      - 30
      - 60
      - 90
      - 120
      - 150
      - 180
      - 365
      - 400
      - 545
      - 731
      - 1096
      - 1827
      - 2192
      - 2557
      - 2922
      - 3288
      - 3653

mainSteps:
  - name: SetLogGroupRetention
    action: 'aws:executeAwsApi'
    description: |
      ## SetLogGroupRetention
      Sets the retention period for the specified CloudWatch Log Group.
      ## Outputs
      * Output: Success message or failure exception.
    timeoutSeconds: 600
    isEnd: true
    inputs:
      Service: logs
      Api: PutRetentionPolicy
      logGroupName: '{{ LogGroupName }}'
      retentionInDays: '{{ RetentionInDays }}'
    outputs:
      - Name: Output
        Selector: $$.ResponseMetadata
        Type: StringMap
DOC

  tags = var.tags
}

# IAM Role for Config Remediation (Security Account)
resource "aws_iam_role" "config_remediation" {
  count = var.is_security_account && var.enable_cloudwatch_retention_remediation ? 1 : 0

  name        = "ConfigRemediation-CloudWatchLogRetention"
  description = "Role for AWS Config to remediate CloudWatch log group retention"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = [
            "ssm.amazonaws.com",
            "config.amazonaws.com"
          ]
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

# IAM Policy for Config Remediation Role (Security Account)
resource "aws_iam_role_policy" "config_remediation" {
  count = var.is_security_account && var.enable_cloudwatch_retention_remediation ? 1 : 0

  name = "ConfigRemediationPolicy"
  role = aws_iam_role.config_remediation[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchLogsPermissions"
        Effect = "Allow"
        Action = [
          "logs:PutRetentionPolicy",
          "logs:DescribeLogGroups"
        ]
        Resource = "*"
      },
      {
        Sid    = "AssumeRoleToMemberAccounts"
        Effect = "Allow"
        Action = [
          "sts:AssumeRole"
        ]
        Resource = "arn:aws:iam::*:role/ConfigRemediation-CloudWatchLogRetention-Member"
      },
      {
        Sid    = "SSMDocumentPermissions"
        Effect = "Allow"
        Action = [
          "ssm:GetDocument",
          "ssm:DescribeDocument"
        ]
        Resource = "*"
      }
    ]
  })
}

# Config Remediation Configuration
resource "aws_config_remediation_configuration" "cloudwatch_retention" {
  count = var.is_security_account && var.enable_cloudwatch_retention_remediation ? 1 : 0

  config_rule_name = aws_config_organization_managed_rule.cloudwatch_log_retention[0].name

  target_type    = "SSM_DOCUMENT"
  target_id      = aws_ssm_document.cloudwatch_retention_remediation[0].name
  target_version = "$LATEST"

  automatic                  = true
  maximum_automatic_attempts = 5
  retry_attempt_seconds      = 60

  parameter {
    name         = "AutomationAssumeRole"
    static_value = aws_iam_role.config_remediation[0].arn
  }

  parameter {
    name           = "LogGroupName"
    resource_value = "RESOURCE_ID"
  }

  parameter {
    name         = "RetentionInDays"
    static_value = tostring(var.cloudwatch_retention_days)
  }

  depends_on = [
    aws_config_organization_managed_rule.cloudwatch_log_retention,
    aws_ssm_document.cloudwatch_retention_remediation,
    aws_iam_role_policy.config_remediation
  ]
}

# ----------------------------------------------------------------------------
# MEMBER ACCOUNT RESOURCES
# ----------------------------------------------------------------------------

# IAM Role for Cross-Account Remediation (Member Accounts)
resource "aws_iam_role" "config_remediation_member" {
  count = !var.is_security_account && var.enable_cloudwatch_retention_remediation ? 1 : 0

  name        = "ConfigRemediation-CloudWatchLogRetention-Member"
  description = "Allows security account to remediate CloudWatch log groups"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.security_account_id}:role/ConfigRemediation-CloudWatchLogRetention"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = "config-remediation"
          }
        }
      }
    ]
  })

  tags = var.tags
}

# IAM Policy for Member Account Role
resource "aws_iam_role_policy" "config_remediation_member" {
  count = !var.is_security_account && var.enable_cloudwatch_retention_remediation ? 1 : 0

  name = "ConfigRemediationMemberPolicy"
  role = aws_iam_role.config_remediation_member[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchLogsPermissions"
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

# ----------------------------------------------------------------------------
# Outputs
# ----------------------------------------------------------------------------

output "config_rule_name" {
  description = "Name of the Config rule for CloudWatch log retention"
  value       = var.is_security_account && var.enable_cloudwatch_retention_remediation ? aws_config_organization_managed_rule.cloudwatch_log_retention[0].name : null
}

output "remediation_role_arn" {
  description = "ARN of the remediation role"
  value = var.is_security_account && var.enable_cloudwatch_retention_remediation ? aws_iam_role.config_remediation[0].arn : (
    !var.is_security_account && var.enable_cloudwatch_retention_remediation ? aws_iam_role.config_remediation_member[0].arn : null
  )
}
