# S3 bucket to store Conformance pack yaml files
resource "aws_s3_bucket" "aws_config_conformance_packs" {
  count  = var.is_security_account ? 1 : 0
  bucket = local.conformance_packs_bucket_name

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
