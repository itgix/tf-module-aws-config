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

variable "aws_config_notifications_email" {
  description = "Email address to subscribe to the SNS topic for Config notifications"
  type        = string
  default     = null
}

# S3
variable "aws_config_central_bucket_name" {
  description = "Name of the S3 bucket that will store AWS Config aggregation history files (has to be a unique name globally in AWS)"
  type        = string
  default     = "itgix-landing-zone-aws-config-history"
}

# Conformance Pack
variable "create_conformance_pack" {
  description = "Whether to create an AWS Config organization conformance pack in the security account"
  type        = bool
  default     = false
}

variable "conformance_pack_name" {
  description = "Name of the AWS Config organization conformance pack"
  type        = string
  default     = "itgix-landing-zone-opinionated-managed-rules"
}

variable "use_default_conformance_pack_managed_rules" {
  description = "Whether to include the module's built-in default managed rules in the conformance pack"
  type        = bool
  default     = true
}

variable "conformance_pack_managed_rule_identifiers" {
  description = "Additional AWS Config managed rule identifiers to include in the conformance pack"
  type        = list(string)
  default     = []
}

variable "conformance_pack_rule_input_parameters" {
  description = "Input parameters for managed rules keyed by AWS Config managed rule identifier"
  type        = map(map(string))
  default     = {}
}

variable "conformance_pack_rule_maximum_execution_frequency" {
  description = "Maximum execution frequency keyed by AWS Config managed rule identifier"
  type        = map(string)
  default     = {}
}

variable "conformance_pack_excluded_accounts" {
  description = "List of AWS account IDs to exclude from the organization conformance pack"
  type        = list(string)
  default     = []
}
