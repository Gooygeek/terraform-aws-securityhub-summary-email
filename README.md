# terraform-aws-securityhub-summary-email

Generates and sends a periodic email summarising of Security Hub. Based on https://github.com/aws-samples/aws-security-hub-summary-email

This solution uses Security Hub custom insights, AWS Lambda, and the Security Hub API. A custom insight is a collection of findings that are aggregated by a grouping attribute, such as severity or status. Insights help you identify common security issues that may require remediation action. Security Hub includes several managed insights, or you can create your own custom insights.

## Overview

A recurring Security Hub Summary email will provide recipients with a proactive communication summarizing the security posture and improvement within their AWS Accounts. The email message contains the following sections:

- AWS Foundational Security Best Practices findings by status
- AWS Foundational Security Best Practices findings by severity
- Amazon GuardDuty findings by severity
- AWS IAM Access Analyzer findings by severity
- Unresolved findings by severity
- New findings in the last 7 days by security product
- Top 10 resource types with the most findings

## Here’s how the solution works

1. Seven Security Hub custom insights are created when the solution is first deployed.
2. A CloudWatch time-based event invokes a Lambda function for processing.
3. The Lambda function gets results of the custom insights from Security Hub, formats the results for email and sends a message to SNS.
4. SNS sends the email notification to the address provided during deployment.
5. The email includes the summary and links to the Security Hub UI to follow the remediation workflow.

![diagram](docs/diagram.png)

## Usage

For a complete example, see [examples/managed_sns](examples/managed_sns).

For automated tests of the complete example using [bats](https://github.com/bats-core/bats-core) and [Terratest](https://github.com/gruntwork-io/terratest) (which tests and deploys the example on AWS), see [test](test).

Here's how to invoke this module in your projects:

```hcl
module "securityhub-email" {
  source  = "gooygeek/security-hub-summary-email/aws"
  version = "x.x.x"
}
```

## Examples

Here is an example of using this module: [`examples/managed_sns`](https://github.com/gooygeek/terraform-aws-securityhub-summary-email/tree/master/examples/managed_sns/)

## Requirements

| Name                                                                     | Version   |
| ------------------------------------------------------------------------ | --------- |
| <a name="requirement_terraform"></a> [terraform](#requirement_terraform) | >= 0.13.0 |
| <a name="requirement_aws"></a> [aws](#requirement_aws)                   | >= 2      |

## Providers

| Name                                             | Version |
| ------------------------------------------------ | ------- |
| <a name="provider_aws"></a> [aws](#provider_aws) | >= 2    |

## Resources

| Name                                                                                                                                                     | Type        |
| -------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| [aws_cloudwatch_event_rule.trigger](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule)                   | resource    |
| [aws_cloudwatch_event_target.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target)                | resource    |
| [aws_iam_role.iam_for_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target)                       | resource    |
| [aws_lambda_permission.trigger](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target)                     | resource    |
| [aws_lambda_function.sechub_summariser](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target)             | resource    |
| [aws_securityhub_insight.all_by_severity](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target)           | resource    |
| [aws_securityhub_insight.aws_best_prac_by_severity](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource    |
| [aws_securityhub_insight.aws_best_prac_by_status](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target)   | resource    |
| [aws_securityhub_insight.guardduty_by_severity](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target)     | resource    |
| [aws_securityhub_insight.iam_by_severity](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target)           | resource    |
| [aws_securityhub_insight.new_findings](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target)              | resource    |
| [aws_securityhub_insight.top_resource_types](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target)        | resource    |
| [aws_sns_topic.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target)                                | resource    |
| [aws_sns_topic_subscription.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target)                   | resource    |
| [aws_partition.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition)                                           | data source |

## Inputs

| Name                                                                                                                  | Description                                                                                                                                        | Type          | Default             | Required |
| --------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- | ------------- | ------------------- | :------: |
| <a name="input_additional_email_footer_text"></a> [additional_email_footer_text](#input_additional_email_footer_text) | Additional text to append at the end of email message.                                                                                             | `string`      | `""`                |    no    |
| <a name="input_email"></a> [email](#input_email)                                                                      | Email Address for Subscriber to Security Hub summary. Only used if SNS arn is not specified.                                                       | `string`      | `null`              |    no    |
| <a name="input_name"></a> [name](#input_name)                                                                         | ID element. Usually the component or solution name, e.g. 'app' or 'jenkins'.                                                                       | `string`      | `sechub-aummariser` |    no    |
| <a name="input_schedule"></a> [schedule](#input_schedule)                                                             | Expression for scheduling the Security Hub summary email. Default: Every Monday 8:00 AM UTC. Example: Every Friday 9:00 AM UTC: cron(0 9 ? _ 6 _). | `string`      | `cron(0 8 ? * 2 *)` |    no    |
| <a name="input_sns_topic_arn"></a> [sns_topic_arn](#input_sns_topic_arn)                                              | ARN of the SNS Topic to send summaries to. If empty, a topic is created for you.                                                                   | `string`      | `null`              |    no    |
| <a name="input_tags"></a> [tags](#input_tags)                                                                         | Additional tags (e.g. `{'BusinessUnit': 'XYZ'}`).                                                                                                  | `map(string)` | `{}`                |    no    |

## Outputs

| Name                                                           | Description                    |
| -------------------------------------------------------------- | ------------------------------ |
| <a name="output_sns_topic"></a> [sns_topic](#output_sns_topic) | The SNS topic that was created |

## Test Solution

You can send a test email once the deployment is complete and you have confirmed the SNS subscription email. Navigate to the Lambda console and locate the function Lambda function named SendSecurityHubSummaryEmail. Perform a [manual invocation](https://docs.aws.amazon.com/lambda/latest/dg/getting-started-create-function.html#get-started-invoke-manually) with any event payload to receive an email shortly.

## License

This library is licensed under the MIT License. See the LICENSE file.