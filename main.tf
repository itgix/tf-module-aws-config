locals {
  recorder_name = "itgix-landing-zone-config-recorder"
  delivery_name = "itgix-landing-zone-delivery-name"
}


// Aggregator
resource "aws_config_configuration_aggregator" "org" {
  // TODO: count in security account
  name = "org-aggregator"

  organization_aggregation_source {
    all_regions = true
    role_arn    = aws_iam_role.config_aggregator_role.arn
  }
}

// TODO: conformance packs
# Operational-Best-Practices-for-PCI-DSS
# Security-Best-Practices
resource "aws_config_organization_conformance_pack" "pci_dss" {
  // TODO: count in security account
  name            = "Operational-Best-Practices-for-PCI-DSS"
  template_s3_uri = "s3://aws-config-conformance-packs-us-east-1/Operational-Best-Practices-for-PCI-DSS.yaml"

  depends_on = [aws_config_configuration_aggregator.org]
}



// Recorder -
resource "aws_config_configuration_recorder" "default" {
  //TODO: in member accounts with a for_each loop
  name     = local.recorder_name
  role_arn = aws_iam_role.config_role.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }

  depends_on = [aws_iam_role_policy_attachment.config_managed_policy]
}

resource "aws_config_delivery_channel" "default" {
  //TODO: in member accounts with a for_each loop
  name           = local.delivery_name
  s3_bucket_name = var.central_bucket_name
  sns_topic_arn  = var.sns_topic_arn

  depends_on = [aws_config_configuration_recorder.this]
}

resource "aws_config_configuration_recorder_status" "this" {
  //TODO: in member accounts with a for_each loop
  name       = local.recorder_name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.this]
}

// TODO: aws_iam_role
// # common IAM Role for AWS config
resource "aws_iam_role" "config_role" {
  name               = "aws-config-role"
  assume_role_policy = data.aws_iam_policy_document.config_assume.json

  tags = var.tags
}

data "aws_iam_policy_document" "config_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "config_managed_policy" {
  role       = aws_iam_role.config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRole"
}


// TODO: aws_sns_topic for security notifications
// TODO: S3 bucket and with a bucket policy granting access to all org accounts and the AWS Config service (similar to what we do in Cloudtrail)

// TODO: 
// aws_config_delivery_channel

// TODO: other custom config rules not covered by conformance packs
# aws_config_config_rule

// TODO:
// aws_config_remediation_configuration
// TODO: remediation for cloudwatch logs to not have never expire 
