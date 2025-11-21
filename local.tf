locals {
  module_prefix                 = "itgix-landing-zone"
  recorder_name                 = "${local.module_prefix}-recorder"
  delivery_name                 = "${local.module_prefix}-delivery"
  aggregator_name               = "${local.module_prefix}-aggregator"
  config_role_name              = "${local.module_prefix}-config-role"
  aggregator_role_name          = "${local.module_prefix}-aggregator-role"
  central_bucket_name           = "${local.module_prefix}-aws-config-history"
  conformance_packs_bucket_name = "${local.module_prefix}-aws-config-conformance-packs"
}
