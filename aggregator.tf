# Config Aggregator (Security account)
resource "aws_config_configuration_aggregator" "org" {
  count = var.is_security_account ? 1 : 0
  name  = local.aggregator_name

  organization_aggregation_source {
    all_regions = true
    role_arn    = aws_iam_role.aggregator_role[0].arn
  }

  tags = var.tags
}
