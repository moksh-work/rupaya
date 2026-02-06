# AWS SSL/TLS Certificate Setup - Complete Guide

**Status**: Production Ready  
**Updated**: 2024  
**Certificates**: Production + Staging with Auto-Renewal

---

## 📋 Overview

This Terraform configuration sets up AWS Certificate Manager (ACM) SSL/TLS certificates for:
- **Production**: api.example.com (main certificate)
- **Staging**: staging-api.example.com (separate certificate)
- **Auto-renewal**: Automatic certificate renewal 30 days before expiration
- **Monitoring**: SNS alerts for certificate expiration

---

## 🔑 Key Components

### 1. ACM Certificates (`acm.tf`)

**Production Certificate**
```hcl
# Covers:
- api.example.com (primary domain)
- example.com (root domain)
- www.example.com (www subdomain)
- *.example.com (wildcard for all subdomains)
```

**Staging Certificate**
```hcl
# Covers:
- staging-api.example.com (staging API)
- staging.example.com (staging root)
```

Both certificates:
- ✅ Auto-validated using Route53 DNS
- ✅ Auto-renewed by AWS 30 days before expiry
- ✅ No manual renewal needed
- ✅ Valid for 1 year (auto-renewed)

### 2. ALB HTTPS Listeners (`alb.tf`)

**HTTP (Port 80)**
- Redirects all traffic to HTTPS (301 permanent redirect)
- Enforces HTTPS-only access

**HTTPS (Port 443)**
- Production certificate for api.domain.com
- TLS 1.2+ enforced
- Health checks enabled

### 3. Route53 Records (`route53.tf`)

**Production**
- api.example.com → ALB (via alias record)
- DNS validation records for certificate

**Staging**
- staging-api.example.com → ALB (via alias record)
- DNS validation records for certificate

---

## 🚀 Deployment Steps

### Step 1: Update Configuration

Edit `terraform.tfvars`:

```hcl
# Update your domain
route53_domain     = "yourdomain.com"      # e.g., rupaya.com
route53_subdomain  = "api"

# Update alert email
certificate_alert_email = "ops@yourdomain.com"

# Optional: Enable other records
create_root_domain_record = true  # yourdomain.com → ALB
create_www_record        = true  # www.yourdomain.com → ALB
enable_staging_listener  = false # Use same ALB port 443
```

### Step 2: Initialize Terraform

```bash
cd infra/aws

# Initialize Terraform
terraform init

# Validate syntax
terraform validate
```

### Step 3: Plan Deployment

```bash
# Review changes
terraform plan -out=tfplan

# Shows:
# - ACM certificate creation
# - Route53 validation records
# - ALB listener updates
# - SNS topic creation
```

### Step 4: Apply Configuration

```bash
# Deploy infrastructure
terraform apply tfplan

# Output will show:
# - Production API endpoint
# - Staging API endpoint
# - Route53 nameservers
# - Certificate ARNs
```

### Step 5: Domain Setup (First Time Only)

If this is a new domain:

```bash
# Get nameservers from Terraform output
terraform output route53_zone_nameservers

# Output: ["ns-XXX.awsdns-XX.com", "ns-XXX.awsdns-XX.com", ...]
```

**In your domain registrar:**
1. Go to domain settings
2. Update nameservers to the ones from Terraform output
3. Wait 24-48 hours for DNS propagation

### Step 6: Confirm SNS Subscription

After deployment, check your email:
1. You'll receive an email from AWS SNS
2. Click the confirmation link
3. Certificate expiration alerts will now be sent to your email

---

## ✅ Verification

### Verify Certificate Creation

```bash
# Check production certificate status
terraform output certificate_production_arn

# Check staging certificate status
terraform output certificate_staging_arn

# Should show: arn:aws:acm:region:account:certificate/uuid
```

### Verify HTTPS Access

```bash
# Test production endpoint
curl -v https://api.yourdomain.com

# Should show:
# - SSL certificate valid
# - Subject: *.yourdomain.com
# - Issuer: Amazon (via AWS Certificate Manager)

# Test staging endpoint
curl -v https://staging-api.yourdomain.com

# Should also show valid certificate
```

### Verify HTTP Redirect

```bash
# Test HTTP redirect to HTTPS
curl -I http://api.yourdomain.com

# Should show:
# HTTP/1.1 301 Moved Permanently
# Location: https://api.yourdomain.com
```

### Check Certificate in AWS Console

1. Go to AWS Certificate Manager
2. Select region (us-east-1 for ALB)
3. Should see:
   - Production certificate: "ISSUED" status
   - Staging certificate: "ISSUED" status
4. Both should show domains and validation status

---

## 🔄 Certificate Auto-Renewal

AWS automatically renews certificates 30 days before expiration:

✅ **No action needed** - automatic process
✅ **No downtime** - renewed in-place
✅ **Monitoring enabled** - alerts 30 days before expiry
✅ **No cost** - ACM is free

**Monitoring**
- CloudWatch event rule triggers 30 days before expiry
- SNS notification sent to your email
- No action required (just informational)

---

## 📊 File Structure

### Files Modified

```
infra/aws/
├── acm.tf (NEW)                    ← Certificate configuration
├── alb.tf (UPDATED)                ← HTTPS listeners
├── route53.tf (UPDATED)            ← DNS records
├── variables.tf (UPDATED)          ← New variables
├── outputs.tf (UPDATED)            ← Certificate outputs
└── terraform.tfvars.example (UPDATED)  ← Example config
```

### Variables Added

```hcl
certificate_alert_email      # Email for alerts
enable_staging_listener      # Separate staging port (optional)
create_root_domain_record    # Root domain record (optional)
create_www_record           # www subdomain record (optional)
ssl_policy                  # TLS security policy
```

### Outputs Added

```
certificate_production_arn         # Production cert ARN
certificate_staging_arn            # Staging cert ARN
api_production_endpoint            # https://api.domain.com
api_staging_endpoint              # https://staging-api.domain.com
route53_zone_nameservers          # DNS nameservers
certificate_alert_topic_arn       # SNS topic for alerts
```

---

## 🔐 Security Features

### TLS 1.2+ Enforcement

```hcl
ssl_policy = "ELBSecurityPolicy-TLS-1-2-2017-01"

# Available policies:
# - ELBSecurityPolicy-TLS-1-2-2017-01 (default, recommended)
# - ELBSecurityPolicy-TLS-1-2-Ext-2018-06 (more ciphers)
# - ELBSecurityPolicy-FS-1-2-Res-2019-08 (most secure)
```

### Automatic Redirect

- All HTTP traffic (port 80) redirects to HTTPS
- 301 permanent redirect (cacheable)
- Enforces encrypted communication

### DNS Validation

- Certificates validated using Route53
- No email validation required
- Automatic renewal within AWS ecosystem

---

## 🛠️ Troubleshooting

### Certificate Validation Failed

**Symptom**: Certificate stuck in "Pending validation" state

**Solution**:
```bash
# Check validation records were created
terraform output certificate_production_domain_validation_options

# Verify Route53 records exist
aws route53 list-resource-record-sets --hosted-zone-id <zone-id>

# If records missing, re-apply:
terraform apply
```

### HTTP Not Redirecting to HTTPS

**Symptom**: curl http://api.domain.com shows 200 instead of 301

**Solution**:
```bash
# Check ALB listener configuration
terraform output alb_dns_name

# Verify listener on port 80 exists:
aws elbv2 describe-listeners --load-balancer-arn <alb-arn>

# Should show: Port 80 with redirect to 443
```

### Certificate Not Valid for Domain

**Symptom**: Browser shows certificate not valid for domain

**Solution**:
```bash
# Check certificate covers domain
terraform output certificate_production_domain_validation_options

# If domain not covered:
# 1. Add to subject_alternative_names in acm.tf
# 2. Re-apply terraform
# 3. Validate new domains in Route53
```

### SNS Alerts Not Received

**Symptom**: No email received for certificate expiration

**Solution**:
1. Check email for SNS confirmation link
2. Click confirmation link (if pending)
3. Verify email address in terraform.tfvars
4. Check spam/junk folder
5. Re-run terraform apply to resend subscription email

---

## 📝 Common Configurations

### Production Only (No Staging)

```hcl
enable_staging_listener = false
# Only production certificate used
# Both domains on port 443 (host-based routing)
```

### Separate Staging Environment

```hcl
enable_staging_listener = true
# Staging certificate on port 8443
# Separate endpoint: https://staging-api.domain.com:8443
```

### Additional Subdomains

Edit `acm.tf` to add to `subject_alternative_names`:

```hcl
resource "aws_acm_certificate" "production" {
  # ...
  subject_alternative_names = [
    "api.${var.route53_domain}",
    "admin.${var.route53_domain}",    # Add new
    "docs.${var.route53_domain}",     # Add new
    "*.${var.route53_domain}",
  ]
  # ...
}
```

---

## 📞 Monitoring & Maintenance

### Daily

- ✅ ALB responds on HTTPS
- ✅ Certificate valid (no warnings)
- ✅ HTTP redirects to HTTPS

### Weekly

- Check CloudWatch logs for SSL errors
- Verify health checks passing

### Monthly

- Review SNS alerts (if any)
- Verify certificate status in ACM console
- Check expiration date (should be 11+ months away)

### Quarterly

- Review SSL policy version
- Consider upgrading TLS policy if available
- Update documentation

---

## 💡 Best Practices

### 1. Use Wildcard Certificate

✅ Covers all subdomains automatically
✅ Single certificate for multiple endpoints
✅ Easier to add new subdomains

```hcl
subject_alternative_names = [
  "*.${var.route53_domain}",  # Covers api.*, admin.*, etc.
]
```

### 2. Enable HTTP Redirect

✅ Forces HTTPS for security
✅ 301 redirect is permanent and cacheable
✅ Improves SEO (HTTPS preferred)

```hcl
# Already configured in alb.tf
# HTTP port 80 → HTTPS port 443
```

### 3. Monitor Certificate Expiration

✅ SNS alerts 30 days before expiry
✅ Automatic renewal (no action needed)
✅ Email confirmation required once

### 4. Use Strong TLS Policy

✅ Enforce TLS 1.2+ minimum
✅ Disable weak ciphers
✅ Use forward secrecy if possible

```hcl
ssl_policy = "ELBSecurityPolicy-FS-1-2-Res-2019-08"
```

---

## 🔗 Useful Links

- [AWS Certificate Manager](https://docs.aws.amazon.com/acm/)
- [ALB HTTPS Listener](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html)
- [Route53 DNS Validation](https://docs.aws.amazon.com/acm/latest/userguide/dns-validation.html)
- [SSL/TLS Best Practices](https://docs.aws.amazon.com/security/)

---

## ✅ Checklist

Before deploying to production:

- [ ] Domain registered and accessible
- [ ] Nameservers ready to update
- [ ] Email configured for alert notifications
- [ ] terraform.tfvars updated with correct domain
- [ ] ALB security group allows port 443
- [ ] ECS tasks healthy (listening on port 3000)
- [ ] Terraform plan reviewed
- [ ] Infrastructure deployed
- [ ] SNS subscription confirmed
- [ ] HTTPS access verified
- [ ] Certificate validity confirmed
- [ ] HTTP redirect verified

---

## 📊 Summary

This Terraform configuration provides:

✅ **Automated Certificate Management**
- ACM certificates for prod + staging
- Auto-renewal 30 days before expiry
- No manual renewal needed

✅ **HTTPS Enforcement**
- Port 443 HTTPS listener
- TLS 1.2+ minimum
- HTTP redirects to HTTPS

✅ **DNS Integration**
- Route53 hosted zone
- Automatic DNS validation
- Multiple domain support

✅ **Monitoring & Alerts**
- SNS notifications for expiration
- CloudWatch event rules
- Email confirmations

✅ **Production Ready**
- High availability configuration
- Health checks enabled
- Auto-renewal configured

---

**Status**: ✅ Ready to Deploy  
**Maintenance**: Minimal (auto-renewal handled by AWS)  
**Cost**: Free (ACM certificates are free)

