# Refactored Terraform Architecture - Modular Certificates

## What Changed

### Before (Non-Modular)
```
infra/aws/
├── acm.tf                          ← Certificates defined here
├── alb.tf                          ← ALB references acm.tf
├── route53.tf                      ← References acm.tf
└── terraform.tfvars                ← Single state file
```

**Problem:** All resources in single apply, certificate validation delays block ALB creation.

### After (Modular - Enterprise Pattern)
```
infra/aws/
├── modules/certificates/           ← NEW: Separate module
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── certificates-module.tf          ← NEW: Module invocation
├── alb.tf                          ← Updated: references module outputs
├── route53.tf                      ← Updated: depends_on module
├── variables.tf                    ← Updated: new cert variables
├── outputs.tf                      ← Updated: module outputs
└── terraform.tfvars                ← Single tfvars (but modular deployment)
```

**Solution:** Deploy certificates first, then ALB independently.

---

## Deployment Strategy

### Option A: Two-Step Deployment (RECOMMENDED)

```bash
# Step 1: Deploy ONLY certificates (wait for validation)
cd infra/aws
terraform apply -target=module.certificates

# Output will show:
# ✅ Route53 zone created
# ✅ ACM certificates created (PENDING_VALIDATION)
# ✅ Validation records created
# ⏳ Waiting for Route53 to propagate... (5-30 minutes)

# Step 2: Deploy everything else (when certs are ISSUED)
terraform apply

# Outputs:
# ✅ ALB with HTTPS listener
# ✅ ECS services
# ✅ RDS database
# ✅ Redis cache
# ✅ Health checks passing
```

**Timeline:**
- 5-10 min: Certificates created
- 5-30 min: DNS propagation
- 10-15 min: Infrastructure deployed
- **Total: 20-55 minutes**

### Option B: Automated Staged Deployment

Create `deploy.sh`:
```bash
#!/bin/bash
set -e

echo "🔐 Step 1: Deploy Certificates..."
terraform apply -target=module.certificates -auto-approve

echo "⏳ Waiting for DNS propagation (5 minutes)..."
sleep 300

echo "🔍 Checking certificate status..."
aws acm describe-certificate \
  --certificate-arn $(terraform output -raw certificate_production_arn) \
  --region us-east-1 \
  --query 'Certificate.Status'

echo "🏗️ Step 2: Deploy Infrastructure..."
terraform apply -auto-approve

echo "✅ Deployment complete!"
terraform output -json | jq '{
  api_prod: .api_production_endpoint.value,
  api_staging: .api_staging_endpoint.value,
  alb: .alb_dns_name.value,
  cert_status: .certificate_production_domain_validation_options.value.status
}'
```

Run:
```bash
chmod +x deploy.sh
./deploy.sh
```

### Option C: GitHub Actions (CI/CD)

See `.github/workflows/deploy-infrastructure.yml` (create separately).

---

## Key Changes

### 1. Certificate Module Created
**File:** `infra/aws/modules/certificates/main.tf`

- Centralized certificate management
- Reusable across projects
- Configurable validation timeout
- Monitoring with CloudWatch + SNS

### 2. ALB Updated
**File:** `infra/aws/alb.tf`

**Before:**
```hcl
certificate_arn = aws_acm_certificate.production.arn
depends_on = [aws_acm_certificate_validation.production]
```

**After:**
```hcl
certificate_arn = module.certificates.certificate_production_arn
depends_on = [module.certificates]
```

### 3. Route53 Updated
**File:** `infra/aws/route53.tf`

**Before:**
```hcl
depends_on = [aws_acm_certificate_validation.production]
```

**After:**
```hcl
depends_on = [module.certificates]
```

### 4. Variables Added
**File:** `infra/aws/variables.tf`

New variables:
- `certificate_validation_timeout` - Allow longer DNS propagation (default: 15m)
- `enable_staging_certificate` - Create staging cert or not

### 5. Outputs Updated
**File:** `infra/aws/outputs.tf`

Now reference module outputs:
```hcl
output "certificate_production_arn" {
  value = module.certificates.certificate_production_arn
}
```

---

## Testing the Refactor

### Test 1: Plan Only (No Apply)
```bash
cd infra/aws
terraform plan
```

Should show:
- module.certificates resources
- ALB, ECS, RDS, etc. resources
- No errors about resource references

### Test 2: Deploy Certificates
```bash
terraform apply -target=module.certificates
```

Monitor in AWS Console:
1. Certificate Manager → Check status (should be PENDING_VALIDATION)
2. Route53 → Verify CNAME records created
3. Wait 5-30 minutes for validation

### Test 3: Deploy Everything
```bash
terraform apply
```

Should complete successfully without timeouts.

### Test 4: Verify HTTPS
```bash
curl -v https://api.cloudycs.com/health
```

Should show:
- SSL certificate valid
- 200 OK response

---

## Migration from Old Setup

If you have existing infrastructure:

```bash
# 1. Backup current state
cp terraform.tfstate terraform.tfstate.backup

# 2. Remove old ACM resources from state
terraform state rm aws_acm_certificate.production
terraform state rm aws_acm_certificate.staging
terraform state rm aws_route53_record.acm_validation_production
terraform state rm aws_route53_record.acm_validation_staging
terraform state rm aws_acm_certificate_validation.production
terraform state rm aws_acm_certificate_validation.staging

# 3. Import into module
terraform import module.certificates.aws_acm_certificate.production \
  arn:aws:acm:us-east-1:xxx:certificate/yyy

terraform import module.certificates.aws_acm_certificate.staging \
  arn:aws:acm:us-east-1:xxx:certificate/yyy

# 4. Plan to verify no changes
terraform plan

# 5. If plan is clean, apply
terraform apply
```

---

## Benefits of Modular Approach

✅ **Separation of Concerns**
- Certificates managed independently
- Easy to understand ownership
- Reusable across multiple projects

✅ **Scaling**
- Add more environments (dev, staging, prod)
- Deploy in parallel
- Minimal blast radius

✅ **Maintenance**
- Certificate renewal independent from infra
- Team collaboration easier
- Rollback simplified

✅ **Enterprise Ready**
- Matches industry patterns
- Easier for new team members
- Compliance-friendly

✅ **Automation**
- Consistent deployments
- CI/CD integration ready
- Manual error reduction

---

## Troubleshooting

### Certificate Still Pending After 30 minutes
```bash
# Check validation status
aws acm describe-certificate \
  --certificate-arn arn:aws:acm:us-east-1:xxx:certificate/yyy \
  --region us-east-1 \
  --query 'Certificate.{Status:Status, ValidationOptions:DomainValidationOptions}'

# Check Route53 records
aws route53 list-resource-record-sets \
  --hosted-zone-id Z04635962BFA7VSD4OQ6H \
  --query 'ResourceRecordSets[?Type==`CNAME`]'

# Verify DNS propagation
nslookup _xxxxx.cloudycs.com
```

### ALB Deploy Fails
```bash
# Ensure certificate is ISSUED
aws acm describe-certificate \
  --certificate-arn $(terraform output -raw certificate_production_arn) \
  --region us-east-1 \
  --query 'Certificate.Status'

# If PENDING, wait longer and try again
# If FAILED, check validation records in Route53
```

---

## Next Steps

1. ✅ Test the refactored code
2. ✅ Document team runbooks
3. ✅ Add GitHub Actions workflow (optional)
4. ✅ Train team on modular deployment
5. ✅ Monitor certificate renewals

