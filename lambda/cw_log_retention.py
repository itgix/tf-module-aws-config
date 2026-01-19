import json
import boto3
import datetime

logs = boto3.client("logs")
config = boto3.client("config")


def evaluate_log_group(log_group_name, min_retention):
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

    compliance = evaluate_log_group(log_group_name, min_retention)

    result = {
        "ComplianceResourceType": "AWS::Logs::LogGroup",
        "ComplianceResourceId": configuration_item["resourceId"],
        "ComplianceType": compliance,
        "OrderingTimestamp": configuration_item["configurationItemCaptureTime"],
    }

    config.put_evaluations(Evaluations=[result], ResultToken=event["resultToken"])
