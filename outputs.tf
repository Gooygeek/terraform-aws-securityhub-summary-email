output "sns_topic_arn" {
  description = "The SNS topic that was created"
  value       = var.sns_topic_arn != null ? var.sns_topic_arn : aws_sns_topic.this[0].arn
}
