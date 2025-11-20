output "config_role_arn" {
  value = aws_iam_role.config_role.arn
}

output "aggregator_role_arn" {
  value = var.is_security_account ? aws_iam_role.aggregator_role[0].arn : null
}

output "central_bucket_name_out" {
  value = var.is_logging_account ? local.central_bucket_name : null
}
