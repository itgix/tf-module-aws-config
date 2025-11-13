// TODO: outline; to be refactored as we implement the module
output "config_role_arn" {
  value       = aws_iam_role.config_role.arn
  description = "IAM role used by AWS Config"
}

output "aggregator_name" {
  value       = try(aws_config_configuration_aggregator.org[0].name, null)
  description = "Name of the AWS Config organization aggregator"
}
