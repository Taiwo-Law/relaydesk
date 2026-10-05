# Security exception: SNS encryption for CloudWatch alarm publishing would
# require a customer-managed KMS key. Accepted for this low-cost portfolio environment.
#trivy:ignore:AWS-0095
resource "aws_sns_topic" "alerts" {
  name = "${lower(var.project_name)}-alerts"

  tags = {
    Name = "${var.project_name}-alerts"
  }
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}