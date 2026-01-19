# CloudWatch Log Group Retention Auto-Remediation

## Overview

This module includes automatic remediation for CloudWatch log groups that have "Never Expire" retention. When enabled, AWS Config will automatically set retention to a specified number of days (default: 365).

## How It Works

1. **AWS Config Rule** monitors all CloudWatch log groups across your organization
2. **Detects** log groups without retention policies (Never Expire)
3. **Automatically remediates** by setting retention to the configured value
4. **Works cross-account** using IAM role assumption

## Configuration

### Enable in Security Account

In `landing-zone-deployment/security/aws-config.tf`:

```hcl
module "aws_config_sec_account" {
  source = "git::https://github.com/itgix/tf-module-aws-config.git?ref=v1.1.0"
  count  = var.enable_aws_config_service ? 1 : 0

  is_security_account = true
  is_logging_account  = false

  # Enable CloudWatch retention remediation
  enable_cloudwatch_retention_remediation = true
  cloudwatch_retention_days               = 365
  security_account_id                     = var.security_account_id
}
```

### Enable in Member Accounts

In `landing-zone-deployment/logging-and-audit/aws-config.tf` and other member accounts:

```hcl
module "aws_config_member_account" {
  source = "git::https://github.com/itgix/tf-module-aws-config.git?ref=v1.1.0"
  count  = var.enable_aws_config_service ? 1 : 0

  is_security_account = false
  is_logging_account  = true  # or false for other accounts

  # Enable CloudWatch retention remediation
  enable_cloudwatch_retention_remediation = true
  cloudwatch_retention_days               = 365
  security_account_id                     = var.security_account_id
}
```

## Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `enable_cloudwatch_retention_remediation` | bool | false | Enable/disable the remediation feature |
| `cloudwatch_retention_days` | number | 365 | Retention period in days (must be valid CloudWatch value) |
| `security_account_id` | string | "" | Account ID of the security account |

### Valid Retention Values

1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653

## Resources Created

### Security Account
- `aws_config_organization_managed_rule.cloudwatch_log_retention` - Organization-wide Config rule
- `aws_ssm_document.cloudwatch_retention_remediation` - SSM Automation document
- `aws_iam_role.config_remediation` - IAM role for remediation
- `aws_iam_role_policy.config_remediation` - IAM policy
- `aws_config_remediation_configuration.cloudwatch_retention` - Remediation configuration

### Member Accounts
- `aws_iam_role.config_remediation_member` - Cross-account IAM role
- `aws_iam_role_policy.config_remediation_member` - IAM policy

## Testing

Create a test log group without retention:

```bash
aws logs create-log-group --log-group-name /test/auto-remediation
```

Wait 5-10 minutes, then verify retention was set:

```bash
aws logs describe-log-groups --log-group-name-prefix /test/auto-remediation
# Should show: retentionInDays: 365
```

Clean up:

```bash
aws logs delete-log-group --log-group-name /test/auto-remediation
```

## Monitoring

### View Compliance Status

AWS Console → Security Account → AWS Config → Rules → `cloudwatch-log-group-retention-check`

### CLI Commands

```bash
# Check rule status
aws configservice describe-organization-config-rules \
  --organization-config-rule-names cloudwatch-log-group-retention-check

# View remediation configuration
aws configservice describe-remediation-configurations \
  --config-rule-names cloudwatch-log-group-retention-check

# Check compliance status
aws configservice get-organization-config-rule-detailed-status \
  --organization-config-rule-name cloudwatch-log-group-retention-check
```

## Troubleshooting

### Access Denied Errors

Verify the member role exists:

```bash
aws iam get-role --role-name ConfigRemediation-CloudWatchLogRetention-Member
```

### Remediation Not Triggering

Check if automatic remediation is enabled:

```bash
aws configservice describe-remediation-configurations \
  --config-rule-names cloudwatch-log-group-retention-check \
  --query 'RemediationConfigurations[0].Automatic'
```

## Cost

Estimated monthly cost for 10 accounts with ~100 log groups:
- AWS Config Rules: ~$2
- Config Evaluations: ~$3
- SSM Automation: Free
- **Total: ~$5/month**

## Security

- **Least Privilege**: Roles only have permissions for log retention
- **Cross-Account Trust**: Explicit trust with external ID
- **Audit Trail**: All actions logged in CloudTrail
- **Organization-Wide**: Consistent policy enforcement
