import json
import boto3
import datetime

sts = boto3.client("sts")
config = boto3.client("config")


def evaluate_log_group(log_group_name, min_retention, account_id):
    # Assume role in member account for cross-account access
    role_arn = f"arn:aws:iam::{account_id}:role/Config-CrossAccount-LogsAccess"
    assumed_role = sts.assume_role(
        RoleArn=role_arn,
        RoleSessionName="ConfigEvaluation"
    )
    credentials = assumed_role['Credentials']
    
    logs = boto3.client(
        "logs",
        aws_access_key_id=credentials['AccessKeyId'],
        aws_secret_access_key=credentials['SecretAccessKey'],
        aws_session_token=credentials['SessionToken']
    )
    
    response = logs.describe_log_groups(logGroupNamePrefix=log_group_name)
    for lg in response.get("logGroups", []):
        if lg["logGroupName"] == log_group_name:
            retention = lg.get("retentionInDays")
            if retention is None or retention < min_retention:
                return "NON_COMPLIANT"
            return "COMPLIANT"
    return "NON_COMPLIANT"


def lambda_handler(event, context):
    invoking_event = json.loads(event["invokingEvent"])
    rule_params = json.loads(event.get("ruleParameters", "{}"))

    min_retention = int(rule_params.get("RetentionInDays", 365))

    configuration_item = invoking_event.get("configurationItem")
    log_group_name = configuration_item["resourceName"]
    account_id = configuration_item["awsAccountId"]

    compliance = evaluate_log_group(log_group_name, min_retention, account_id)

    result = {
        "ComplianceResourceType": "AWS::Logs::LogGroup",
        "ComplianceResourceId": configuration_item["resourceId"],
        "ComplianceType": compliance,
        "OrderingTimestamp": configuration_item["configurationItemCaptureTime"],
    }

    config.put_evaluations(Evaluations=[result], ResultToken=event["resultToken"])
