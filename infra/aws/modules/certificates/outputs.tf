output "certificate_production_arn" {
  description = "ARN of production certificate"
  value       = aws_acm_certificate_validation.production.certificate_arn
}

output "certificate_staging_arn" {
  description = "ARN of staging certificate"
  value       = aws_acm_certificate_validation.staging.certificate_arn
}

output "certificate_production_status" {
  description = "Status of production certificate"
  value       = aws_acm_certificate.production.status
}

output "certificate_staging_status" {
  description = "Status of staging certificate"
  value       = aws_acm_certificate.staging.status
}

output "certificate_production_domains" {
  description = "Domains covered by production certificate"
  value = distinct(
    concat(
      [aws_acm_certificate.production.domain_name],
      tolist(aws_acm_certificate.production.subject_alternative_names)
    )
  )
}

output "certificate_staging_domains" {
  description = "Domains covered by staging certificate"
  value = distinct(
    concat(
      [aws_acm_certificate.staging.domain_name],
      tolist(aws_acm_certificate.staging.subject_alternative_names)
    )
  )
}

output "certificate_alert_topic_arn" {
  description = "SNS topic for certificate expiration alerts"
  value       = aws_sns_topic.certificate_expiration.arn
}

output "certificate_alert_email" {
  description = "Email receiving certificate expiration alerts"
  value       = var.certificate_alert_email
}

output "certificate_alert_note" {
  description = "Note about SNS subscription confirmation"
  value       = "A confirmation email has been sent to ${var.certificate_alert_email}. Click the link in the email to enable certificate expiration alerts."
}
