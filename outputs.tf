output "sns_topic_arn" {
  description = "The SNS topic that was created"
  value       = sns_topic_arn != null ? aws_sns_topic.this[0].arn : var.sns_topic_arn
}
