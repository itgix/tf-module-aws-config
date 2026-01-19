variable "is_security_account" {
  description = "Set to true when running in the Security/Delegated Admin Account"
  type        = bool
  default     = false
}

variable "is_logging_account" {
  description = "Set to true in central logging account (creates S3 buckets)"
  type        = bool
  default     = false
}

variable "tags" {
  type = map(string)
  default = {
    Name = "itgix-landing-zone"
  }
}

# SNS
variable "sns_topic_arn" {
  description = "Existing SNS topic ARN for Config delivery notifications. If not provided, a new SNS topic will be created."
  type        = string
  default     = null
}

variable "create_sns_topic" {
  description = "Whether to create a new SNS topic for Config notifications"
  type        = bool
  default     = true
}

# S3
variable "aws_config_central_bucket_name" {
  description = "Name of the S3 bucket that will store AWS Config aggregation history files (has to be a unique name globally in AWS)"
  type        = string
  default     = "itgix-landing-zone-aws-config-history"
}

# Cloudwatch log group retention and remediation
variable "cloudwatch_log_retention_remediation" {
  description = "Enable org-wide CloudWatch Log Group retention enforcement and remediation"
  type        = bool
  default     = true
}

variable "current_account_id" {
  type        = string
  description = "Account ID of the current account where the module is called from, used to configure auto-remediation of log groups in each account"
}

variable "security_account_id" {
  type        = string
  description = "ID of the Organization management account, required for organization wide AWS config rules "
}

variable "region" {
  type        = string
  description = "AWS Region to be added to the Lambda permissions for the purposes of allowing AWS Config from the management account to trigger the Lambda"
}
