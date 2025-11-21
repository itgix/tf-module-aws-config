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

resource "aws_config_organization_conformance_pack" "org_packs" {
  for_each = var.is_security_account ? var.conformance_packs : {}

  name            = each.key
  template_s3_uri = each.value.template_s3_uri

  depends_on = [
    aws_config_configuration_aggregator.org,
    aws_s3_bucket.aws_config_conformance_packs
  ]
}
