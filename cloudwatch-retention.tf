# IAM role to be assumed by the Lambda function for the purposes of checking cloudwatch log group retention
resource "aws_iam_role" "config_cw_retention_lambda" {
  count = var.is_security_account && var.cloudwatch_log_retention_remediation ? 1 : 0
  name  = "Config-CW-Log-Retention-Lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "config_cw_retention_lambda_policy" {
  count = var.is_security_account && var.cloudwatch_log_retention_remediation ? 1 : 0
  role  = aws_iam_role.config_cw_retention_lambda[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["logs:DescribeLogGroups", "logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["config:PutEvaluations"]
        Resource = "*"
      }
    ]
  })
}

// Lambda function to evaluate CloudWatch Log Group retention
resource "aws_lambda_function" "cw_log_retention" {
  count         = var.is_security_account && var.cloudwatch_log_retention_remediation ? 1 : 0
  filename      = "${path.module}/lambda/cw_log_retention.zip" # zip must contain cw_log_retention.py
  function_name = "config-cw-log-retention-check"
  role          = aws_iam_role.config_cw_retention_lambda[0].arn
  handler       = "cw_log_retention.lambda_handler"
  runtime       = "python3.11"
  timeout       = 300

  source_code_hash = filebase64sha256("${path.module}/lambda/cw_log_retention.zip")
}

resource "aws_lambda_permission" "allow_config_org_invoke" {
  count = var.is_security_account && var.cloudwatch_log_retention_remediation ? 1 : 0

  statement_id  = "AllowExecutionFromAWSConfigOrg"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cw_log_retention[0].function_name
  principal     = "config.amazonaws.com"
}

// Organization Custom Config Rule (AWS doesn't have a managed rule that is supported organization wide that stupports this check so we make a custom rule)
resource "aws_config_organization_custom_rule" "cw_log_retention_check" {
  count = var.is_security_account && var.cloudwatch_log_retention_remediation ? 1 : 0
  name  = "cloudwatch-log-group-retention-check"

  lambda_function_arn = aws_lambda_function.cw_log_retention[0].arn

  trigger_types = ["ConfigurationItemChangeNotification"]

  resource_types_scope = ["AWS::Logs::LogGroup"]

  input_parameters = jsonencode({
    RetentionInDays = 365
  })

  description = "Ensure CloudWatch Log Groups do not use Never Expire retention"
}

# Role used for auto-remediation to update log groups
resource "aws_iam_role" "config_remediation_role" {
  count = var.cloudwatch_log_retention_remediation ? 1 : 0
  name  = "AWSConfigRemediation-CloudWatchLogRetention"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ssm.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

# Role for Config to access logs in member accounts
resource "aws_iam_role" "config_cross_account_logs_access" {
  count = !var.is_security_account && var.cloudwatch_log_retention_remediation ? 1 : 0
  name  = "Config-CrossAccount-LogsAccess"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${var.security_account_id}:root" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "config_cross_account_logs_policy" {
  count = !var.is_security_account && var.cloudwatch_log_retention_remediation ? 1 : 0
  role  = aws_iam_role.config_cross_account_logs_access[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["logs:DescribeLogGroups"]
        Resource = "*"
      }
    ]
  })
}

# EventBridge rule to trigger remediation on NON_COMPLIANT evaluations
resource "aws_cloudwatch_event_rule" "config_cw_remediation" {
  count = !var.is_security_account && var.cloudwatch_log_retention_remediation ? 1 : 0
  name  = "config-cw-log-retention-remediation"

  event_pattern = jsonencode({
    source      = ["aws.config"]
    detail-type = ["Config Rules Compliance Change"]
    detail = {
      configRuleName = ["cloudwatch-log-group-retention-check"]
      newEvaluationResult = {
        complianceType = ["NON_COMPLIANT"]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "config_cw_remediation_target" {
  count     = !var.is_security_account && var.cloudwatch_log_retention_remediation ? 1 : 0
  rule      = aws_cloudwatch_event_rule.config_cw_remediation[0].name
  target_id = "SSMRemediation"

  arn = "arn:aws:ssm:${var.region}:${var.current_account_id}:automation-definition/${aws_ssm_document.set_cloudwatch_log_retention[0].name}:$DEFAULT"

  role_arn = aws_iam_role.eventbridge_invoke_ssm[0].arn

  input_transformer {
    input_paths = {
      resourceId = "$.detail.resourceId"
    }
    input_template = jsonencode({
      DocumentName = aws_ssm_document.set_cloudwatch_log_retention[0].name
      Parameters = {
        LogGroupName         = ["<resourceId>"]
        RetentionInDays      = [tostring(var.cloudwatch_logs_default_retention)]
        AutomationAssumeRole = ["arn:aws:iam::${var.current_account_id}:role/AWSConfigRemediation-CloudWatchLogRetention"]
      }
    })
  }
}

# IAM role for EventBridge to invoke SSM
resource "aws_iam_role" "eventbridge_invoke_ssm" {
  count = !var.is_security_account && var.cloudwatch_log_retention_remediation ? 1 : 0
  name  = "EventBridge-Invoke-SSM-Remediation"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "events.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "eventbridge_invoke_ssm_policy" {
  count = !var.is_security_account && var.cloudwatch_log_retention_remediation ? 1 : 0
  role  = aws_iam_role.eventbridge_invoke_ssm[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ssm:StartAutomationExecution"]
        Resource = "*"
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

# Custom SSM Automation Document for setting CloudWatch Log Group retention
resource "aws_ssm_document" "set_cloudwatch_log_retention" {
  count = var.cloudwatch_log_retention_remediation ? 1 : 0
  name  = "itgix-landing-zone-aws-config-cloudwatch-logs-remediation"

  document_type = "Automation"

  content = jsonencode({
    schemaVersion = "0.3"
    assumeRole    = "{{ AutomationAssumeRole }}"
    parameters = {
      LogGroupName = {
        type = "String"
      }
      RetentionInDays = {
        type = "String"
      }
      AutomationAssumeRole = {
        type = "String"
      }
    }
    mainSteps = [
      {
        name   = "SetRetentionPolicy"
        action = "aws:executeAwsApi"
        inputs = {
          Service         = "logs"
          Api             = "PutRetentionPolicy"
          LogGroupName    = "{{ LogGroupName }}"
          RetentionInDays = "{{ RetentionInDays }}"
        }
      }
    ]
  })
}


