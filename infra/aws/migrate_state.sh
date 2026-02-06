#!/bin/bash
set -e

echo "🔄 Migrating certificate resources to module..."

# Backup state
cp terraform.tfstate terraform.tfstate.backup.$(date +%s)

echo "📦 Moving resources to module..."

# Move ACM certificates
terraform state mv aws_acm_certificate.production module.certificates.aws_acm_certificate.production || true
terraform state mv aws_acm_certificate.staging module.certificates.aws_acm_certificate.staging || true

# Move certificate validations
terraform state mv aws_acm_certificate_validation.production module.certificates.aws_acm_certificate_validation.production || true
terraform state mv aws_acm_certificate_validation.staging module.certificates.aws_acm_certificate_validation.staging || true

# Move Route53 validation records (production)
terraform state mv 'aws_route53_record.acm_validation_production["cloudycs.com"]' 'module.certificates.aws_route53_record.acm_validation_production["cloudycs.com"]' || true
terraform state mv 'aws_route53_record.acm_validation_production["*.cloudycs.com"]' 'module.certificates.aws_route53_record.acm_validation_production["*.cloudycs.com"]' || true
terraform state mv 'aws_route53_record.acm_validation_production["www.cloudycs.com"]' 'module.certificates.aws_route53_record.acm_validation_production["www.cloudycs.com"]' || true
terraform state mv 'aws_route53_record.acm_validation_production["api.cloudycs.com"]' 'module.certificates.aws_route53_record.acm_validation_production["api.cloudycs.com"]' || true

# Move Route53 validation records (staging)
terraform state mv 'aws_route53_record.acm_validation_staging["staging-api.cloudycs.com"]' 'module.certificates.aws_route53_record.acm_validation_staging["staging-api.cloudycs.com"]' || true
terraform state mv 'aws_route53_record.acm_validation_staging["staging.cloudycs.com"]' 'module.certificates.aws_route53_record.acm_validation_staging["staging.cloudycs.com"]' || true

# Move SNS resources
terraform state mv aws_sns_topic.certificate_expiration module.certificates.aws_sns_topic.certificate_expiration || true
terraform state mv aws_sns_topic_subscription.certificate_expiration_email module.certificates.aws_sns_topic_subscription.certificate_expiration_email || true
terraform state mv aws_sns_topic_policy.certificate_expiration module.certificates.aws_sns_topic_policy.certificate_expiration || true

# Move CloudWatch resources
terraform state mv aws_cloudwatch_event_rule.acm_expiration module.certificates.aws_cloudwatch_event_rule.acm_expiration || true
terraform state mv aws_cloudwatch_event_target.acm_expiration_sns module.certificates.aws_cloudwatch_event_target.acm_expiration_sns || true

# Move IAM resources
terraform state mv aws_iam_role.certificate_expiration_role module.certificates.aws_iam_role.certificate_expiration_role || true
terraform state mv aws_iam_role_policy.certificate_expiration_policy module.certificates.aws_iam_role_policy.certificate_expiration_policy || true

echo "✅ State migration complete!"
echo "📋 Verifying module resources in state..."
terraform state list | grep "module.certificates" | head -20

echo ""
echo "✅ Migration successful! Certificate resources now managed by module."
