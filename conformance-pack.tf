# Config Organization Conformance Pack (Security account)
resource "aws_config_organization_conformance_pack" "this" {
  count = var.is_security_account && var.create_conformance_pack && length(local.conformance_pack_managed_rules) > 0 ? 1 : 0

  name              = var.conformance_pack_name
  template_body     = local.conformance_pack_template_body
  excluded_accounts = var.conformance_pack_excluded_accounts
}
