# SSL/TLS Certificate Infrastructure - Summary

**Status**: ✅ Production Ready  
**Date**: 2024  
**Implementation**: AWS Certificate Manager + ALB + Route53

---

## 🎉 What Has Been Completed

### ✅ Terraform Code Generated

**New File: `infra/aws/acm.tf`**
- Production SSL certificate (api.domain.com + wildcard)
- Staging SSL certificate (staging-api.domain.com)
- Automatic DNS validation using Route53
- Auto-renewal configuration (30 days before expiry)
- SNS alerts for certificate expiration
- CloudWatch monitoring

**Updated File: `infra/aws/alb.tf`**
- HTTP listener → HTTPS redirect (port 80 → 443)
- HTTPS listener with production certificate (port 443)
- Optional staging listener on port 8443
- TLS 1.2+ enforcement

**Updated File: `infra/aws/route53.tf`**
- Production API record: api.domain.com → ALB
- Staging API record: staging-api.domain.com → ALB
- Optional root domain record: domain.com → ALB
- Optional www record: www.domain.com → ALB
- DNS validation records (automatic)

**Updated Files**
- `variables.tf` - New certificate variables
- `outputs.tf` - Certificate and endpoint outputs
- `terraform.tfvars.example` - Configuration example

### ✅ Helper Script

**`deploy-certificates.sh`**
- Automated deployment script
- Pre-deployment validation
- Interactive confirmation
- Shows next steps
- Error handling

### ✅ Documentation

**`SSL_CERTIFICATE_GUIDE.md`**
- Complete setup guide
- Step-by-step deployment
- Verification procedures
- Troubleshooting guide
- Security best practices
- Monitoring instructions

---

## 📊 Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│ Users / API Clients                                     │
└────────────────────┬────────────────────────────────────┘
                     │ HTTPS (Port 443)
                     │ TLS 1.2+
                     ↓
┌─────────────────────────────────────────────────────────┐
│ Application Load Balancer (ALB)                         │
├─────────────────────────────────────────────────────────┤
│ • Port 80 (HTTP) → Redirect to 443                      │
│ • Port 443 (HTTPS)                                      │
│   ├─ api.domain.com → Production certificate           │
│   └─ staging-api.domain.com → Staging certificate      │
└────────────────────┬────────────────────────────────────┘
                     │
                     ↓
┌─────────────────────────────────────────────────────────┐
│ ECS Fargate (Backend Services)                          │
├─────────────────────────────────────────────────────────┤
│ • Port 3000 (HTTP internal)                             │
│ • Health checks enabled                                 │
└─────────────────────────────────────────────────────────┘

Certificates:
├─ ACM Production: *.domain.com (auto-renewed)
├─ ACM Staging: staging-api.domain.com (auto-renewed)
└─ Both validated via Route53 DNS

Monitoring:
├─ CloudWatch alerts (30 days before expiry)
├─ SNS notifications (to ops email)
└─ No manual renewal needed
```

---

## 🚀 Quick Start

### 1. Prerequisites

```bash
# Ensure you have:
✅ AWS credentials configured
✅ Terraform installed (v1.x+)
✅ Domain registered (e.g., example.com)
✅ jq installed (for script output parsing)
```

### 2. Deploy Certificates

**Option A: Using Script (Recommended)**

```bash
cd infra/aws

# Run deployment script
bash deploy-certificates.sh yourdomain.com ops@yourdomain.com

# Script will:
# - Validate configuration
# - Create ACM certificates
# - Setup Route53 records
# - Configure ALB listeners
# - Display outputs
```

**Option B: Manual Terraform**

```bash
cd infra/aws

# Update configuration
cat > terraform.tfvars << EOF
route53_domain     = "yourdomain.com"
certificate_alert_email = "ops@yourdomain.com"
EOF

# Deploy
terraform init
terraform plan
terraform apply
```

### 3. Update Domain Registrar

```bash
# Get nameservers from deployment output
terraform output route53_zone_nameservers

# Output example:
# ["ns-123.awsdns-45.com", "ns-456.awsdns-78.com", ...]

# In domain registrar:
# 1. Go to domain settings
# 2. Update nameservers to the above values
# 3. Wait 24-48 hours for propagation
```

### 4. Confirm SNS Subscription

```bash
# Check email for SNS confirmation
# From: AWS Notifications
# Link: Click "Confirm subscription"

# After confirmation:
# - Alerts enabled for certificate expiration
# - Notifications sent 30 days before expiry
```

### 5. Verify HTTPS

```bash
# Test production endpoint (after DNS propagates)
curl -v https://api.yourdomain.com

# Should show:
# - SSL certificate valid
# - Subject: *.yourdomain.com
# - Issuer: Amazon

# Test HTTP redirect
curl -I http://api.yourdomain.com
# Should show: HTTP/1.1 301 Moved Permanently
```

---

## 📋 Configuration Reference

### terraform.tfvars Settings

```hcl
# Required
route53_domain     = "yourdomain.com"
certificate_alert_email = "ops@yourdomain.com"

# Optional
enable_staging_listener = false      # Separate HTTPS port for staging
create_root_domain_record = false    # Root domain (yourdomain.com)
create_www_record = false           # WWW subdomain (www.yourdomain.com)
ssl_policy = "ELBSecurityPolicy-TLS-1-2-2017-01"  # TLS version/ciphers
```

### Certificates Covered

**Production Certificate**
- api.yourdomain.com (primary)
- yourdomain.com (root)
- www.yourdomain.com
- *.yourdomain.com (all subdomains)

**Staging Certificate**
- staging-api.yourdomain.com (primary)
- staging.yourdomain.com

---

## ✅ What Gets Deployed

### AWS Resources Created

```
✅ ACM Certificate - Production
   • Domain: *.yourdomain.com
   • Status: ISSUED
   • Auto-renewal: Enabled

✅ ACM Certificate - Staging
   • Domain: staging-api.yourdomain.com
   • Status: ISSUED
   • Auto-renewal: Enabled

✅ Route53 Hosted Zone
   • Zone: yourdomain.com
   • Nameservers: 4 AWS nameservers

✅ Route53 DNS Records
   • api.yourdomain.com → ALB
   • staging-api.yourdomain.com → ALB
   • ACM validation records (temporary)

✅ ALB Listeners
   • Port 80 (HTTP) → Redirect to 443
   • Port 443 (HTTPS) → Production certificate

✅ SNS Topic
   • Topic: rupaya-cert-expiration-alerts
   • Subscription: Your email
   • Trigger: 30 days before expiry

✅ CloudWatch Event Rule
   • Rule: Monitor certificate expiration
   • Action: Send SNS notification
```

---

## 🔒 Security Features

### HTTPS Enforcement
- ✅ HTTP (80) redirects to HTTPS (443)
- ✅ 301 permanent redirect (cacheable)
- ✅ Forces encrypted communication

### TLS Configuration
- ✅ TLS 1.2+ minimum (configurable)
- ✅ Strong cipher suites
- ✅ Forward secrecy support

### Certificate Validation
- ✅ DNS validation via Route53
- ✅ Automatic ownership verification
- ✅ No email required

### Auto-Renewal
- ✅ Renewed 30 days before expiry
- ✅ Zero-downtime renewal
- ✅ No manual intervention needed

### Monitoring
- ✅ Email alerts (30 days before expiry)
- ✅ CloudWatch events
- ✅ SNS notifications

---

## 📊 Files Created/Updated

```
infra/aws/
├── acm.tf (NEW)                          ← Certificates
├── alb.tf (UPDATED)                      ← HTTPS listeners
├── route53.tf (UPDATED)                  ← DNS records
├── variables.tf (UPDATED)                ← New variables
├── outputs.tf (UPDATED)                  ← Certificate outputs
├── terraform.tfvars.example (UPDATED)    ← Example config
├── deploy-certificates.sh (NEW)          ← Deployment script
└── SSL_CERTIFICATE_GUIDE.md (NEW)       ← Documentation
```

---

## 🔍 Verification Checklist

After deployment:

- [ ] Terraform apply completed successfully
- [ ] SNS confirmation email received
- [ ] SNS subscription confirmed
- [ ] Domain nameservers updated
- [ ] DNS propagated (check: nslookup api.domain.com)
- [ ] HTTPS works: curl -v https://api.domain.com
- [ ] HTTP redirects: curl -I http://api.domain.com
- [ ] Certificate valid: openssl s_client -connect api.domain.com:443
- [ ] No browser warnings
- [ ] Health checks passing in ALB

---

## 🛠️ Common Commands

### Check Certificate Status
```bash
aws acm list-certificates --region us-east-1

aws acm describe-certificate \
  --certificate-arn <cert-arn> \
  --region us-east-1
```

### View Route53 Records
```bash
ZONE_ID=$(terraform output -raw route53_zone_id)

aws route53 list-resource-record-sets \
  --hosted-zone-id $ZONE_ID
```

### Test HTTPS
```bash
# Show certificate details
openssl s_client -connect api.yourdomain.com:443

# Check expiration date
echo | openssl s_client -servername api.yourdomain.com \
  -connect api.yourdomain.com:443 2>/dev/null | \
  openssl x509 -noout -dates

# Verify redirect
curl -i http://api.yourdomain.com
```

### Update Certificate
```bash
# Add new domain to certificate
# Edit acm.tf → add to subject_alternative_names
# Re-run terraform

cd infra/aws
terraform apply
```

### Monitor Alerts
```bash
# List SNS subscriptions
aws sns list-subscriptions-by-topic \
  --topic-arn <topic-arn>

# Monitor certificate expiration
aws events list-rules --name-prefix rupaya-cert
```

---

## 💡 Pro Tips

### 1. Wildcard Certificates
✅ Covers all subdomains automatically
✅ Only need one certificate

### 2. DNS-Based Validation
✅ No email required
✅ Automatic in Route53
✅ Works within AWS ecosystem

### 3. Auto-Renewal
✅ AWS renews automatically
✅ No downtime
✅ 30-day alert window

### 4. Separate Staging
```hcl
# Option 1: Same ALB, host-based routing (default)
enable_staging_listener = false
# Both prod and staging on port 443
# Use different hostnames: api.* vs staging-api.*

# Option 2: Separate HTTPS port for staging
enable_staging_listener = true
# Staging on port 8443
# Endpoint: https://staging-api.domain.com:8443
```

---

## ❓ FAQ

**Q: Do I need to renew the certificate?**
A: No, AWS renews automatically 30 days before expiry.

**Q: Will there be downtime during renewal?**
A: No, renewal happens transparently with zero downtime.

**Q: Can I add more subdomains later?**
A: Yes, edit `acm.tf` and re-apply (renewal certificates created).

**Q: What if DNS validation fails?**
A: Check that Route53 records were created. Terraform shows in output.

**Q: Can I use different certificate for staging?**
A: Yes, already configured! Separate certificate: staging-api.domain.com

**Q: What's the cost?**
A: Free! AWS Certificate Manager certificates are always free.

---

## 📞 Support

### Troubleshooting
- See: `SSL_CERTIFICATE_GUIDE.md` → Troubleshooting section
- Common issues with solutions included

### Configuration Help
- See: `SSL_CERTIFICATE_GUIDE.md` → Common Configurations section
- Production-only, staging, additional subdomains

### AWS Documentation
- [ACM User Guide](https://docs.aws.amazon.com/acm/)
- [ALB HTTPS Listener](https://docs.aws.amazon.com/elasticloadbalancing/)
- [Route53 Documentation](https://docs.aws.amazon.com/route53/)

---

## ✨ Summary

This Terraform implementation provides:

✅ **Enterprise-Grade HTTPS**
- Auto-renewed certificates
- TLS 1.2+ enforcement
- Zero-downtime deployment

✅ **Production Ready**
- Separate certs for prod/staging
- Wildcard domain support
- Health checks enabled

✅ **Monitoring & Alerts**
- Email notifications
- 30-day expiration alerts
- CloudWatch integration

✅ **Low Maintenance**
- Automatic renewal
- No manual intervention
- Self-healing

**Status**: ✅ Ready to Deploy  
**Next Step**: Run `bash deploy-certificates.sh yourdomain.com ops@yourdomain.com`

