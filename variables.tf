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

variable "sns_topic_arn" {
  description = "SNS topic ARN for Config delivery notifications"
  type        = string
  default     = ""
}

variable "conformance_packs" {
  type    = map(object({ template_s3_uri = string }))
  default = {}
}

variable "tags" {
  type = map(string)
  default = {
    Name = "itgix-landing-zone"
  }
}
