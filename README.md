The Terraform module is used by the ITGix AWS Landing Zone - https://itgix.com/itgix-landing-zone/

# AWS Config Terraform Module

This module deploys AWS Config with recorders, S3 delivery channel, IAM roles, SNS notifications, and optional Config aggregator for multi-account setups.

Part of the [ITGix AWS Landing Zone](https://itgix.com/itgix-landing-zone/).

## Resources Created

- AWS Config recorder and delivery channel
- S3 bucket for Config history (in logging account)
- IAM roles for Config and aggregator
- SNS topic for Config notifications
- *(Optional)* Config aggregator (in security/delegated admin account)

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `is_security_account` | Set to true when running in the Security/Delegated Admin Account | `bool` | `false` | no |
| `is_logging_account` | Set to true in central logging account (creates S3 buckets) | `bool` | `false` | no |
| `tags` | Tags to apply to resources | `map(string)` | `{Name="itgix-landing-zone"}` | no |
| `sns_topic_arn` | Existing SNS topic ARN for Config delivery notifications | `string` | `null` | no |
| `create_sns_topic` | Whether to create a new SNS topic for Config notifications | `bool` | `true` | no |
| `aws_config_notifications_email` | Email address to subscribe to the SNS topic | `string` | `null` | no |
| `aws_config_central_bucket_name` | Name of the S3 bucket for AWS Config aggregation history | `string` | `"itgix-landing-zone-aws-config-history"` | no |

## Outputs

| Name | Description |
|------|-------------|
| `config_role_arn` | Config IAM role ARN |
| `aggregator_role_arn` | Aggregator IAM role ARN (null if not security account) |
| `central_bucket_name_out` | Central S3 bucket name (null if not logging account) |
| `config_sns_topic_arn` | ARN of the SNS topic used for Config notifications |

## Usage Example

```hcl
module "config" {
  source = "path/to/tf-module-aws-config"

  is_security_account = true
  create_sns_topic    = true

  aws_config_notifications_email = "alerts@example.com"
  aws_config_central_bucket_name = "my-org-config-history"

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```
