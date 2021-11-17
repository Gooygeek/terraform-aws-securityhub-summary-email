output "sns_topic" {
  description = "The SNS topic that was created"
  value       = local.create_sns_topic ? module.sns_topic[0].sns_topic : null
}