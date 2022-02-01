variable "additional_email_header_text" {
  description = "Additional text to prepend at the start of email message"
  type        = string
  default     = ""
}

variable "additional_email_footer_text" {
  description = "Additional text to append at the end of email message"
  type        = string
  default     = ""
}

variable "email" {
  description = "Email Address for Subscriber to Security Hub summary. Only used if SNS arn is not specified"
  type        = string
  default     = null
}

variable "insights" {
  description = "list of insights and in what order to include in the summary."
  type        = list(any)
  default     = []
}

variable "name" {
  description = "ID element"
  type        = string
  default     = "sechub-summariser"
}

variable "schedule" {
  description = "Expression for scheduling the Security Hub summary email. Default: Every Monday 8:00 AM UTC. Example: Every Friday 9:00 AM UTC: cron(0 9 ? * 6 *)"
  type        = string
  default     = "cron(0 8 ? * 2 *)"
}

variable "sns_topic_arn" {
  description = "ARN of the SNS Topic to send summaries to. If empty, a topic is created for you."
  type        = string
  default     = null
}

variable "kms_key_id" {
  description = "KMS Key ID to use for encrypting the topic"
  type        = string
  default     = "alias/aws/sns"
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}

data "aws_partition" "this" {}
