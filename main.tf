
#    _____ _   _  _____
#   / ____| \ | |/ ____|
#  | (___ |  \| | (___
#   \___ \| . ` |\___ \
#   ____) | |\  |____) |
#  |_____/|_| \_|_____/

resource "aws_sns_topic" "this" {
  count = sns_topic_arn != null ? 1 : 0

  name         = var.name
  display_name = replace(name, ".", "-") # dots are illegal in display names and for .fifo topics required as part of the name (AWS SNS by design)
  # kms_master_key_id           = var.kms_key_id
  # delivery_policy             = var.delivery_policy
  # fifo_topic                  = var.fifo_topic
  # content_based_deduplication = var.content_based_deduplication

  tags = var.tags
}

resource "aws_sns_topic_subscription" "this" {
  count = (sns_topic_arn != null) && (var.email != null) ? 1 : 0

  topic_arn = aws_sns_topic.arn
  protocol  = "email"
  endpoint  = var.email
}

#   _____           _       _     _
#  |_   _|         (_)     | |   | |
#    | |  _ __  ___ _  __ _| |__ | |_ ___
#    | | | '_ \/ __| |/ _` | '_ \| __/ __|
#   _| |_| | | \__ \ | (_| | | | | |_\__ \
#  |_____|_| |_|___/_|\__, |_| |_|\__|___/
#                      __/ |
#                     |___/

resource "aws_securityhub_insight" "aws_best_prac_by_status" {
  name = "Summary Email - 01 - AWS Foundational Security Best practices findings by compliance status"

  group_by_attribute = "ComplianceStatus"

  filters {
    type {
      comparison = "EQUALS"
      value      = "Software and Configuration Checks/Industry and Regulatory Standards/ AWS - Foundational - Security - Best - Practices"
    }
    workflow_status {
      comparison = "NOT_EQUALS"
      value      = "SUPPRESSED"
    }
    record_state {
      comparison = "EQUALS"
      value      = "ACTIVE"
    }
  }
}

resource "aws_securityhub_insight" "aws_best_prac_by_severity" {
  name = "Summary Email - 02 - Failed AWS Foundational Security Best practices findings by severity"

  group_by_attribute = "SeverityLabel"

  filters {
    type {
      comparison = "EQUALS"
      value      = "Software and Configuration Checks/Industry and Regulatory Standards/ AWS - Foundational - Security - Best - Practices"
    }
    workflow_status {
      comparison = "NOT_EQUALS"
      value      = "SUPPRESSED"
    }
    compliance_status {
      comparison = "EQUALS"
      value      = "FAILED"
    }
    record_state {
      comparison = "EQUALS"
      value      = "ACTIVE"
    }
  }
}

resource "aws_securityhub_insight" "guardduty_by_severity" {
  name = "Summary Email - 03 - Count of Amazon GuardDuty findings by severity"

  group_by_attribute = "SeverityLabel"

  filters {
    product_name {
      comparison = "EQUALS"
      value      = "GuardDuty"
    }
    workflow_status {
      comparison = "NOT_EQUALS"
      value      = "SUPPRESSED"
    }
    record_state {
      comparison = "EQUALS"
      value      = "ACTIVE"
    }
  }
}

resource "aws_securityhub_insight" "iam_by_severity" {
  name = "Summary Email - 04 - Count of IAM Access Analyzer findings by severity"

  group_by_attribute = "SeverityLabel"

  filters {
    product_name {
      comparison = "EQUALS"
      value      = "IAM Access Analyzer"
    }
    workflow_status {
      comparison = "NOT_EQUALS"
      value      = "SUPPRESSED"
    }
    record_state {
      comparison = "EQUALS"
      value      = "ACTIVE"
    }
  }
}

resource "aws_securityhub_insight" "all_by_severity" {
  name = "Summary Email - 05 - Count of all unresolved findings by severity"

  group_by_attribute = "SeverityLabel"

  filters {
    workflow_status {
      comparison = "NOT_EQUALS"
      value      = "RESOLVED"
    }
    workflow_status {
      comparison = "NOT_EQUALS"
      value      = "SUPPRESSED"
    }
    record_state {
      comparison = "EQUALS"
      value      = "ACTIVE"
    }
  }
}

resource "aws_securityhub_insight" "new_findings" {
  name = "Summary Email - 06 - new findings in the last 7 days"

  group_by_attribute = "ProductName"

  filters {
    workflow_status {
      comparison = "NOT_EQUALS"
      value      = "RESOLVED"
    }
    workflow_status {
      comparison = "NOT_EQUALS"
      value      = "SUPPRESSED"
    }
    created_at {
      date_rage {
        unit  = "DAYS"
        value = "7"
      }
    }
    record_state {
      comparison = "EQUALS"
      value      = "ACTIVE"
    }
  }
}

resource "aws_securityhub_insight" "top_resource_types" {
  name = "Summary Email - 07 - Top Resource Types with findings by count"

  group_by_attribute = "ResourceType"

  filters {
    workflow_status {
      comparison = "NOT_EQUALS"
      value      = "SUPPRESSED"
    }
    record_state {
      comparison = "EQUALS"
      value      = "ACTIVE"
    }
  }
}

#   _                     _         _
#  | |                   | |       | |
#  | |     __ _ _ __ ___ | |__   __| | __ _
#  | |    / _` | '_ ` _ \| '_ \ / _` |/ _` |
#  | |___| (_| | | | | | | |_) | (_| | (_| |
#  |______\__,_|_| |_| |_|_.__/ \__,_|\__,_|

resource "aws_iam_role" "iam_for_lambda" {
  name = var.name

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  inline_policy {
    name = "SecurityHubSendEmailToSNS"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = ["sns:Publish"]
          Effect   = "Allow"
          Resource = var.sns_topic_arn != null ? var.sns_topic_arn : var.sns_aws_sns_topic.this[0].arn
        },
      ]
    })
  }

  managed_policy_arns = ["arn:${data.aws_partition.this.partition}:iam::aws:policy/AWSSecurityHubReadOnlyAccess"]
}

resource "aws_lambda_function" "sechub_summariser" {
  filename      = "lambda_function_payload.zip"
  function_name = var.name
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "index.lambda_handler"

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  source_code_hash = filebase64sha256("lambda_function_payload.zip")

  runtime = "python3.7"
  timeout = 30

  environment {
    variables = {
      ARNInsight01              = aws_securityhub_insight.aws_best_prac_by_status.arn
      ARNInsight02              = aws_securityhub_insight.aws_best_prac_by_severity.arn
      ARNInsight03              = aws_securityhub_insight.guardduty_by_severity.arn
      ARNInsight04              = aws_securityhub_insight.iam_by_severity.arn
      ARNInsight05              = aws_securityhub_insight.all_by_severity.arn
      ARNInsight06              = aws_securityhub_insight.new_findings.arn
      ARNInsight07              = aws_securityhub_insight.top_resource_types.arn
      SNSTopic                  = var.sns_topic_arn != null ? var.sns_topic_arn : var.sns_aws_sns_topic.this[0].arn
      AdditionalEmailFooterText = var.additional_email_footer_text
    }
  }
}

resource "aws_lambda_permission" "trigger" {
  statement_id  = "AllowExecutionFromEvents"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sechub_summariser.name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.trigger.arn
}

#   _______   _                         ______               _
#  |__   __| (_)                       |  ____|             | |
#     | |_ __ _  __ _  __ _  ___ _ __  | |____   _____ _ __ | |_
#     | | '__| |/ _` |/ _` |/ _ \ '__| |  __\ \ / / _ \ '_ \| __|
#     | | |  | | (_| | (_| |  __/ |    | |___\ V /  __/ | | | |_
#     |_|_|  |_|\__, |\__, |\___|_|    |______\_/ \___|_| |_|\__|
#                __/ | __/ |
#               |___/ |___/

resource "aws_cloudwatch_event_rule" "trigger" {
  name        = "security_hub_summary_email_schedule"
  description = "Triggers the Recurring Security Hub summary email"

  schedule_expression = var.schedule
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.trigger.name
  target_id = "TriggerLambda"
  arn       = aws_lambda_function.sechub_summariser.arn
}
