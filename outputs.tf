output "config_role_arn" {
  value = aws_iam_role.config_role.arn
}

output "aggregator_role_arn" {
  value = var.is_security_account ? aws_iam_role.aggregator_role[0].arn : null
}

output "central_bucket_name_out" {
  value = var.is_logging_account ? var.aws_config_central_bucket_name : null
}

output "config_sns_topic_arn" {
  description = "ARN of the SNS topic used for Config notifications"
  value       = var.sns_topic_arn != null ? var.sns_topic_arn : (var.create_sns_topic ? aws_sns_topic.config_notifications[0].arn : null)
}
