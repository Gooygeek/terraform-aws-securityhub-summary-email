module "securityhub-email" {
  source  = "gooygeek/security-hub-summary-email/aws"
  version = "1.0.0"

  name = "securityhub-summariser"

  additional_email_footer_text = ""
  email                        = "my.email@example.com"
  schedule                     = "cron(0 8 ? * 2 *)"
  tags = {
    Environment = "Production"
  }
}
