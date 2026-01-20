The Terraform module is used by the ITGix AWS Landing Zone - https://itgix.com/itgix-landing-zone/

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.4 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_config_configuration_aggregator.org](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_configuration_aggregator) | resource |
| [aws_config_configuration_recorder.member](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_configuration_recorder) | resource |
| [aws_config_configuration_recorder_status.member](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_configuration_recorder_status) | resource |
| [aws_config_delivery_channel.member_acc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_delivery_channel) | resource |
| [aws_config_delivery_channel.security_acc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_delivery_channel) | resource |
| [aws_iam_role.aggregator_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.config_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.aggregator_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.config_policy_attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_s3_bucket.aws_config_aggregation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.aws_config_aggregation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_policy.aws_config_aggregation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_sns_topic.config_notifications](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_subscription.email](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [aws_iam_policy_document.aggregator_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.config_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_config_central_bucket_name"></a> [aws\_config\_central\_bucket\_name](#input\_aws\_config\_central\_bucket\_name) | Name of the S3 bucket that will store AWS Config aggregation history files (has to be a unique name globally in AWS) | `string` | `"itgix-landing-zone-aws-config-history"` | no |
| <a name="input_aws_config_notifications_email"></a> [aws\_config\_notifications\_email](#input\_aws\_config\_notifications\_email) | Email address to subscribe to the SNS topic for Config notifications | `string` | `null` | no |
| <a name="input_create_sns_topic"></a> [create\_sns\_topic](#input\_create\_sns\_topic) | Whether to create a new SNS topic for Config notifications | `bool` | `true` | no |
| <a name="input_is_logging_account"></a> [is\_logging\_account](#input\_is\_logging\_account) | Set to true in central logging account (creates S3 buckets) | `bool` | `false` | no |
| <a name="input_is_security_account"></a> [is\_security\_account](#input\_is\_security\_account) | Set to true when running in the Security/Delegated Admin Account | `bool` | `false` | no |
| <a name="input_sns_topic_arn"></a> [sns\_topic\_arn](#input\_sns\_topic\_arn) | Existing SNS topic ARN for Config delivery notifications. If not provided, a new SNS topic will be created. | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(string)` | <pre>{<br/>  "Name": "itgix-landing-zone"<br/>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aggregator_role_arn"></a> [aggregator\_role\_arn](#output\_aggregator\_role\_arn) | n/a |
| <a name="output_central_bucket_name_out"></a> [central\_bucket\_name\_out](#output\_central\_bucket\_name\_out) | n/a |
| <a name="output_config_role_arn"></a> [config\_role\_arn](#output\_config\_role\_arn) | n/a |
| <a name="output_config_sns_topic_arn"></a> [config\_sns\_topic\_arn](#output\_config\_sns\_topic\_arn) | ARN of the SNS topic used for Config notifications |
<!-- END_TF_DOCS -->
