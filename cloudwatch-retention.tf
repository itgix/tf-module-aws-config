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
        Action   = ["logs:DescribeLogGroups"]
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

// Automatic remediation of log groups that do not have a retention set
resource "aws_config_remediation_configuration" "cw_log_retention" {
  count            = var.cloudwatch_log_retention_remediation ? 1 : 0
  config_rule_name = aws_config_organization_custom_rule.cw_log_retention_check[0].name

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
    static_value = "arn:aws:iam::${var.current_account_id}:role/AWSConfigRemediation-CloudWatchLogRetention"
  }

  resource_type = "AWS::Logs::LogGroup"
}
