locals {
  module_prefix        = "itgix-landing-zone"
  recorder_name        = "${local.module_prefix}-recorder"
  delivery_name        = "${local.module_prefix}-delivery"
  aggregator_name      = "${local.module_prefix}-aggregator"
  config_role_name     = "${local.module_prefix}-config-role"
  aggregator_role_name = "${local.module_prefix}-aggregator-role"
  sns_topic_name       = "${local.module_prefix}-config-notifications"

  # Keep stable internal rule identifiers so filtering, overrides, and per-rule settings use one consistent key before AWS-specific rendering.
  #https://docs.aws.amazon.com/config/latest/developerguide/aws-config-managed-rules-cloudformation-templates.html
  default_conformance_pack_managed_rules = [
    # ECR
    "ECR_PRIVATE_LIFECYCLE_POLICY_CONFIGURED",
    "ECR_PRIVATE_IMAGE_SCANNING_ENABLED",

    # EC2 
    "EC2_LAUNCH_TEMPLATE_IMDSV2_CHECK",
    "EC2_TOKEN_HOP_LIMIT_CHECK",
    "NACL_NO_UNRESTRICTED_SSH_RDP",
    "EC2_INSTANCE_DETAILED_MONITORING_ENABLED",

    # S3
    "S3_LIFECYCLE_POLICY_CHECK",
    "S3_BUCKET_SSL_REQUESTS_ONLY",
    "S3_BUCKET_PUBLIC_READ_PROHIBITED",
    "S3_BUCKET_PUBLIC_WRITE_PROHIBITED",
    "S3_ACCOUNT_LEVEL_PUBLIC_ACCESS_BLOCKS",

    # IAM
    "IAM_POLICY_NO_STATEMENTS_WITH_ADMIN_ACCESS",
    "IAM_PASSWORD_POLICY",
    "ROOT_ACCOUNT_MFA_ENABLED",
    "ACCESS_KEYS_ROTATED",
    "IAM_USER_UNUSED_CREDENTIALS_CHECK",
    "IAM_USER_MFA_ENABLED",
    "IAM_ROOT_ACCESS_KEY_CHECK",
    "IAM_POLICY_NO_STATEMENTS_WITH_FULL_ACCESS",
    "MFA_ENABLED_FOR_IAM_CONSOLE_ACCESS",
    "IAM_NO_INLINE_POLICY_CHECK",
    "IAM_USER_GROUP_MEMBERSHIP_CHECK",

    # KMS
    "CMK_BACKING_KEY_ROTATION_ENABLED",
    "KMS_CMK_NOT_SCHEDULED_FOR_DELETION",
    "KMS_KEY_POLICY_NO_PUBLIC_ACCESS",

    # RDS
    "RDS_MULTI_AZ_SUPPORT",
    "RDS_AUTOMATIC_MINOR_VERSION_UPGRADE_ENABLED",
    "DB_INSTANCE_BACKUP_ENABLED",
    "RDS_INSTANCE_DELETION_PROTECTION_ENABLED",
    "RDS_LOGGING_ENABLED",
    "RDS_CLUSTER_ENCRYPTED_AT_REST",
    "RDS_SNAPSHOTS_PUBLIC_PROHIBITED",
    "RDS_INSTANCE_PUBLIC_ACCESS_CHECK",
    "RDS_STORAGE_ENCRYPTED",
    "RDS_CLUSTER_BACKUP_RETENTION_CHECK",
    "RDS_MARIADB_INSTANCE_ENCRYPTED_IN_TRANSIT",
    "RDS_MYSQL_INSTANCE_ENCRYPTED_IN_TRANSIT",
    "RDS_POSTGRES_INSTANCE_ENCRYPTED_IN_TRANSIT",

    # SQS 
    "SQS_QUEUE_DLQ_CHECK",

    # CloudTrail
    "CLOUD_TRAIL_ENABLED",
    "CLOUD_TRAIL_LOG_FILE_VALIDATION_ENABLED",
    "CLOUD_TRAIL_CLOUD_WATCH_LOGS_ENABLED",
    "CLOUD_TRAIL_ENCRYPTION_ENABLED",
    "CLOUDTRAIL_S3_BUCKET_PUBLIC_ACCESS_PROHIBITED",

    # EC2 and VPC
    "VPC_FLOW_LOGS_ENABLED",
    "VPC_DEFAULT_SECURITY_GROUP_CLOSED",
    "EC2_INSTANCE_NO_PUBLIC_IP",
    "RESTRICTED_COMMON_PORTS",
    "RESTRICTED_SSH",
    "VPC_SG_OPEN_ONLY_TO_AUTHORIZED_PORTS",
    "INTERNET_GATEWAY_AUTHORIZED_VPC_ONLY",
    "NO_UNRESTRICTED_ROUTE_TO_IGW",
    "EIP_ATTACHED",
    "EC2_EBS_ENCRYPTION_BY_DEFAULT",
    "ENCRYPTED_VOLUMES",

    # Lambda
    "LAMBDA_FUNCTION_PUBLIC_ACCESS_PROHIBITED",
    "LAMBDA_DLQ_CHECK",
    "LAMBDA_INSIDE_VPC",

    # Transit Gateway
    "EC2_TRANSIT_GATEWAY_AUTO_VPC_ATTACH_DISABLED",

    # VPC Endpoints
    "VPC_ENDPOINT_ENABLED",
    "SERVICE_VPC_ENDPOINT_ENABLED",

    # VPC Peering
    "VPC_PEERING_DNS_RESOLUTION_CHECK",

    # Network Firewall
    "NETFW_LOGGING_ENABLED",
    "NETFW_MULTI_AZ_ENABLED",
    "NETFW_POLICY_RULE_GROUP_ASSOCIATED",
    "NETFW_POLICY_DEFAULT_ACTION_FULL_PACKETS",
    "NETFW_POLICY_DEFAULT_ACTION_FRAGMENT_PACKETS",

    # Client VPN
    "EC2_CLIENT_VPN_CONNECTION_LOG_ENABLED",
    "EC2_CLIENT_VPN_NOT_AUTHORIZE_ALL",

    # Site-to-Site VPN
    "VPC_VPN_2_TUNNELS_UP",
    "EC2_VPN_CONNECTION_LOGGING_ENABLED",
    "EC2_VPN_CONNECTION_IKE_VERSION_CHECK",

    # ACM
    "ACM_CERTIFICATE_EXPIRATION_CHECK",
    "ACM_CERTIFICATE_RSA_CHECK",
    "ACM_CERTIFICATE_TRANSPARENT_LOGGING_ENABLED",

    # Transfer Family
    "TRANSFER_FAMILY_SERVER_NO_FTP",
    "TRANSFER_CONNECTOR_LOGGING_ENABLED",

    # SNS
    "SNS_ENCRYPTED_KMS",
    "SNS_TOPIC_NO_PUBLIC_ACCESS",
    "SNS_TOPIC_MESSAGE_DELIVERY_NOTIFICATION_ENABLED",

    # ECS
    "ECS_CONTAINER_INSIGHTS_ENABLED",
    "ECS_CONTAINERS_NONPRIVILEGED",
    "ECS_CONTAINERS_READONLY_ACCESS",
    "ECS_TASK_DEFINITION_NONROOT_USER",
    "ECS_TASK_DEFINITION_LOG_CONFIGURATION",

    # EKS
    "EKS_ENDPOINT_NO_PUBLIC_ACCESS",
    "EKS_CLUSTER_LOGGING_ENABLED",
    "EKS_SECRETS_ENCRYPTED",
    "EKS_CLUSTER_SUPPORTED_VERSION",
    "EKS_NODEGROUP_SUPPORTED_VERSION_CHECK",

    # API Gateway
    "API_GW_EXECUTION_LOGGING_ENABLED",
    "API_GW_XRAY_ENABLED",
    "API_GW_ENDPOINT_TYPE_CHECK",
    "API_GW_SSL_ENABLED",
    "API_GW_CACHE_ENABLED_AND_ENCRYPTED",
    "APIGATEWAY_STAGE_ACCESS_LOGS_ENABLED",

    # CloudFront
    "CLOUDFRONT_ACCESSLOGS_ENABLED",
    "CLOUDFRONT_VIEWER_POLICY_HTTPS",
    "CLOUDFRONT_ASSOCIATED_WITH_WAF",
    "CLOUDFRONT_NO_DEPRECATED_SSL_PROTOCOLS",

    # WAF
    "WAFV2_LOGGING_ENABLED",
    "WAFV2_WEBACL_NOT_EMPTY",
    "WAFV2_RULEGROUP_NOT_EMPTY",

    # SSM
    "SSM_DOCUMENT_NOT_PUBLIC",
    "SSM_AUTOMATION_BLOCK_PUBLIC_SHARING",
    "SSM_AUTOMATION_LOGGING_ENABLED",

    # Logging and detection
    "CW_LOGGROUP_RETENTION_PERIOD_CHECK",
    "SECRETSMANAGER_ROTATION_ENABLED_CHECK",

    # Load balancer encryption and resilience
    "ELBV2_LISTENER_ENCRYPTION_IN_TRANSIT",
    "ELB_ACM_CERTIFICATE_REQUIRED",
    "ELB_DELETION_PROTECTION_ENABLED"
  ]

  # CloudFront AWS Config managed rules are available only in us-east-1.
  us_east_1_only_conformance_pack_managed_rules = [
    "CLOUDFRONT_ACCESSLOGS_ENABLED",
    "CLOUDFRONT_VIEWER_POLICY_HTTPS",
    "CLOUDFRONT_ASSOCIATED_WITH_WAF",
    "CLOUDFRONT_NO_DEPRECATED_SSL_PROTOCOLS"
  ]

  # Some AWS managed rules require input parameters; provide safe defaults.
  default_conformance_pack_rule_input_parameters = {
    #https://docs.aws.amazon.com/config/latest/developerguide/access-keys-rotated.html
    ACCESS_KEYS_ROTATED = {
      maxAccessKeyAge = "90"
    }
    #https://docs.aws.amazon.com/config/latest/developerguide/iam-password-policy.html
    IAM_USER_UNUSED_CREDENTIALS_CHECK = {
      maxCredentialUsageAge = "90"
    }
    #https://docs.aws.amazon.com/config/latest/developerguide/service-vpc-endpoint-enabled.html
    SERVICE_VPC_ENDPOINT_ENABLED = {
      serviceName = "ssm"
    }
    #https://docs.aws.amazon.com/config/latest/developerguide/vpc-endpoint-enabled.html
    VPC_ENDPOINT_ENABLED = {
      serviceNames = "ssm"
    }
    #https://docs.aws.amazon.com/config/latest/developerguide/eks-cluster-supported-version-check.html
    EKS_CLUSTER_SUPPORTED_VERSION = {
      oldestVersionSupported = "1.31"
    }
    #https://docs.aws.amazon.com/config/latest/developerguide/eks-nodegroup-supported-version-check.html
    EKS_NODEGROUP_SUPPORTED_VERSION_CHECK = {
      oldestVersionSupported = "1.31"
    }
    #https://docs.aws.amazon.com/config/latest/developerguide/api-gw-endpoint-type-check.html
    API_GW_ENDPOINT_TYPE_CHECK = {
      endpointConfigurationTypes = "REGIONAL,PRIVATE"
    }
    #https://docs.aws.amazon.com/config/latest/developerguide/netfw-policy-default-action-full-packets.html
    NETFW_POLICY_DEFAULT_ACTION_FULL_PACKETS = {
      statelessDefaultActions = "aws:forward_to_sfe"
    }
    #https://docs.aws.amazon.com/config/latest/developerguide/netfw-policy-default-action-fragment-packets.html
    NETFW_POLICY_DEFAULT_ACTION_FRAGMENT_PACKETS = {
      statelessFragmentDefaultActions = "aws:forward_to_sfe"
    }
  }

  conformance_pack_rule_source_identifiers = {
    #https://docs.aws.amazon.com/config/latest/developerguide/restricted-common-ports.html
    RESTRICTED_COMMON_PORTS = "RESTRICTED_INCOMING_TRAFFIC"
    #https://docs.aws.amazon.com/config/latest/developerguide/restricted-ssh.html
    RESTRICTED_SSH = "INCOMING_SSH_DISABLED"
  }

  # Final per-rule input parameters used in the conformance pack template.
  # Step 1: start from module defaults for rules that need required parameters.
  # Step 2: for each user-provided rule override, merge default + custom values.
  # Result: custom values win for matching keys, while missing keys keep defaults.
  conformance_pack_rule_input_parameters = merge(
    local.default_conformance_pack_rule_input_parameters,
    {
      for rule_identifier, rule_input_parameters in var.conformance_pack_rule_input_parameters :
      # If a rule has no defaults, start from an empty map and apply user values only.
      rule_identifier => merge(
        lookup(local.default_conformance_pack_rule_input_parameters, rule_identifier, {}),
        rule_input_parameters
      )
    }
  )

  # Final candidate rule list before region filtering.
  # Step 1: include module defaults only when the toggle is enabled.
  # Step 2: append any caller-provided managed rule identifiers.
  # Step 3: remove duplicates so each rule appears only once.
  conformance_pack_managed_rules_unfiltered = distinct(concat(
    var.use_default_conformance_pack_managed_rules ? local.default_conformance_pack_managed_rules : [],
    var.conformance_pack_managed_rule_identifiers
  ))

  # Keep all rules in us-east-1; in other regions skip us-east-1-only rules.
  conformance_pack_managed_rules = data.aws_region.current.region == "us-east-1" ? local.conformance_pack_managed_rules_unfiltered : [
    for rule_identifier in local.conformance_pack_managed_rules_unfiltered :
    rule_identifier if !contains(local.us_east_1_only_conformance_pack_managed_rules, rule_identifier)
  ]

  # Create one Config rule resource per selected identifier, with optional params/frequency.
  conformance_pack_template_resources = {
    # Loop through the final rule list and turn each identifier into one template resource.
    for rule_identifier in local.conformance_pack_managed_rules :
    # Logical resource key in the generated template (letters/numbers only).
    "Rule${join("", regexall("[A-Za-z0-9]", rule_identifier))}" => {
      Type = "AWS::Config::ConfigRule"
      Properties = merge(
        {
          # Render AWS-specific fields here so the module can keep stable internal keys even when AWS rule names/source identifiers differ.
          # AWS Config rule name uses lowercase kebab-case.
          ConfigRuleName = lower(replace(rule_identifier, "_", "-"))
          Source = {
            Owner = "AWS"
            # Use mapped AWS source identifiers when names differ, else use the rule identifier.
            SourceIdentifier = lookup(local.conformance_pack_rule_source_identifiers, rule_identifier, rule_identifier)
          }
        },
        # Add InputParameters only for rules that define them.
        length(lookup(local.conformance_pack_rule_input_parameters, rule_identifier, {})) > 0 ? {
          InputParameters = lookup(local.conformance_pack_rule_input_parameters, rule_identifier, {})
        } : {},
        # Add execution frequency only when explicitly configured.
        lookup(var.conformance_pack_rule_maximum_execution_frequency, rule_identifier, null) != null ? {
          MaximumExecutionFrequency = lookup(var.conformance_pack_rule_maximum_execution_frequency, rule_identifier, null)
        } : {}
      )
    }
  }
  conformance_pack_template_body = yamlencode({
    AWSTemplateFormatVersion = "2010-09-09"
    Description              = "ITGix opinionated AWS Config managed rules conformance pack"
    Resources                = local.conformance_pack_template_resources
  })
}
