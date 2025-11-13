// TODO: outline to be refactored as we start implementation

variable "admin" {
  description = "Set to true for delegated admin account (Security account)"
  type        = bool
  default     = false
}

variable "organization_id" {
  description = "AWS Organization ID (e.g., o-xxxxxx)"
  type        = string
}

variable "security_account_id" {
  description = "Account ID of the delegated admin (Security account)"
  type        = string
}

variable "central_bucket_name" {
  description = "S3 bucket name for centralized Config data (in Logging/Audit account)"
  type        = string
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for Config notifications (optional)"
  type        = string
  default     = null
}

variable "region" {
  description = "AWS region to deploy Config in"
  type        = string
  default     = "us-east-1"
}

variable "tags" {
  description = "Common tags to apply"
  type        = map(string)
  default     = {}
}
