# IAM Role for Config Recorder (All Accounts)
data "aws_iam_policy_document" "config_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "config_role" {
  name               = local.config_role_name
  assume_role_policy = data.aws_iam_policy_document.config_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "config_policy_attach" {
  role       = aws_iam_role.config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRole"
}

# IAM Role for Config Aggregator (Security Account)
data "aws_iam_policy_document" "aggregator_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com", "organizations.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "aggregator_role" {
  count              = var.is_security_account ? 1 : 0
  name               = local.aggregator_role_name
  assume_role_policy = data.aws_iam_policy_document.aggregator_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy" "aggregator_policy" {
  count = var.is_security_account ? 1 : 0
  role  = aws_iam_role.aggregator_role[0].id
  name  = "${local.aggregator_role_name}-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "organizations:DescribeOrganization",
          "organizations:ListAccounts",
          "config:Describe*",
          "config:Get*",
          "config:List*"
        ]
        Resource = "*"
      }
    ]
  })
}
