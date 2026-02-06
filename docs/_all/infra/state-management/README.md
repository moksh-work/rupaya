# Enterprise Terraform State Management Setup

## Overview

This directory contains the infrastructure for managing Terraform state at enterprise scale.

**Pattern:** Separate AWS account or root account hosts centralized state management for all environments.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│           State Management Account (Shared)                  │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  S3 Bucket: rupaya-terraform-state-767397779454             │
│  ├── Versioning enabled (disaster recovery)                 │
│  ├── KMS encryption (at-rest & in-transit)                  │
│  ├── Access logging to separate bucket                      │
│  ├── CloudTrail monitoring (who accessed what)              │
│  └── Structure:                                             │
│      ├── prod/                                              │
│      │   └── terraform.tfstate                              │
│      ├── staging/                                           │
│      │   └── terraform.tfstate                              │
│      └── dev/                                               │
│          └── terraform.tfstate                              │
│                                                              │
│  DynamoDB: rupaya-terraform-state-lock                      │
│  ├── State locking (prevents concurrent applies)            │
│  ├── Point-in-time recovery enabled                         │
│  └── Partition key: LockID                                  │
│                                                              │
│  KMS Key: alias/rupaya-terraform-state                      │
│  ├── Key rotation enabled                                   │
│  └── Used for S3 encryption                                 │
│                                                              │
│  IAM Roles:                                                 │
│  ├── rupaya-terraform-cicd (GitHub Actions, etc.)          │
│  └── Can assume only with valid external ID                │
│                                                              │
│  CloudTrail Monitoring                                      │
│  └── Audit all state file access                           │
└─────────────────────────────────────────────────────────────┘
```

## Setup Instructions

### 1. Deploy State Management Infrastructure

```bash
cd /Users/rsingh/Documents/Projects/rupaya/infra/state-management

terraform init
terraform plan
terraform apply
```

### 2. Capture Outputs

```bash
terraform output -json > backend-config.json
```

This generates:
```json
{
  "terraform_state_bucket": "rupaya-terraform-state-767397779454",
  "terraform_state_lock_table": "rupaya-terraform-state-lock",
  "terraform_kms_key_id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "cicd_role_arn": "arn:aws:iam::767397779454:role/rupaya-terraform-cicd",
  "backend_config": {
    "bucket": "rupaya-terraform-state-767397779454",
    "region": "us-east-1",
    "dynamodb_table": "rupaya-terraform-state-lock",
    "encrypt": true,
    "key": "prod/infrastructure/terraform.tfstate",
    "kms_key_id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  }
}
```

### 3. Configure Backend for Main Infrastructure

Update `/Users/rsingh/Documents/Projects/rupaya/infra/aws/backend.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "rupaya-terraform-state-767397779454"
    key            = "prod/infrastructure/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "rupaya-terraform-state-lock"
    encrypt        = true
    kms_key_id     = "arn:aws:kms:us-east-1:767397779454:key/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  }
}
```

### 4. Migrate Local State to S3

```bash
cd /Users/rsingh/Documents/Projects/rupaya/infra/aws

# Create backend.tf with config above
cat > backend.tf << EOF
terraform {
  backend "s3" {
    bucket         = "rupaya-terraform-state-767397779454"
    key            = "prod/infrastructure/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "rupaya-terraform-state-lock"
    encrypt        = true
  }
}
EOF

# Re-initialize Terraform
terraform init

# When prompted: "Do you want to copy existing state to the new backend?"
# Answer: yes
```

### 5. Verify State is Remote

```bash
# Should show empty local state
ls -la terraform.tfstate
# It will be gone or minimal

# Remote state now at:
aws s3 ls s3://rupaya-terraform-state-767397779454/prod/
# Should show: terraform.tfstate

# Verify locking works
terraform plan  # Should acquire lock in DynamoDB
```

## Environment Separation

Use workspaces for different environments:

```bash
# Create dev environment
terraform workspace new dev
terraform workspace select dev

# Configure with dev state key
# (Update backend.tf key to: dev/infrastructure/terraform.tfstate)

# Create staging environment
terraform workspace new staging
terraform workspace select staging

# Create production environment (default)
terraform workspace select default
```

Or use separate state files:

```
terraform {
  backend "s3" {
    key = "prod/infrastructure/terraform.tfstate"    # Production
    key = "staging/infrastructure/terraform.tfstate" # Staging  
    key = "dev/infrastructure/terraform.tfstate"     # Development
  }
}
```

## Security Features

✅ **Encryption at Rest**
- S3: KMS encryption with key rotation
- DynamoDB: Encrypted by default

✅ **Encryption in Transit**
- TLS 1.2+ for all S3/DynamoDB connections
- KMS key used for all state operations

✅ **Access Control**
- S3 bucket: Block all public access
- IAM policy: Least privilege (only needed permissions)
- CI/CD role: External ID required for assumption

✅ **Audit & Compliance**
- CloudTrail: All state access logged
- S3 access logs: Detailed request history
- Versioning: Full history of state changes

✅ **Disaster Recovery**
- Versioning enabled: Restore old state files
- Point-in-time recovery: DynamoDB PITR
- Lifecycle rules: Archive old versions to Glacier

## CI/CD Integration (GitHub Actions)

### 1. Get CI/CD Role ARN

```bash
terraform output cicd_role_arn
# Output: arn:aws:iam::767397779454:role/rupaya-terraform-cicd
```

### 2. Create GitHub OIDC Provider

```bash
# This allows GitHub Actions to assume the role without secrets
# (See: https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
```

### 3. Add GitHub Secrets

```
AWS_ROLE_TO_ASSUME: arn:aws:iam::767397779454:role/rupaya-terraform-cicd
AWS_ACCOUNT_ID: 767397779454
```

### 4. GitHub Actions Workflow

```yaml
name: Terraform Deploy

on:
  push:
    branches: [main]
    paths: [infra/aws/**]
  pull_request:
    branches: [main]
    paths: [infra/aws/**]

permissions:
  id-token: write
  contents: read

jobs:
  terraform:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_TO_ASSUME }}
          aws-region: us-east-1
      
      - uses: hashicorp/setup-terraform@v3
      
      - run: terraform -chdir=infra/aws init
      - run: terraform -chdir=infra/aws plan
      
      - if: github.event_name == 'push' && github.ref == 'refs/heads/main'
        run: terraform -chdir=infra/aws apply -auto-approve
```

## Monitoring & Alerts

### Check CloudTrail for Access

```bash
# List all state file access
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=ResourceName,AttributeValue=terraform.tfstate \
  --region us-east-1
```

### Monitor S3 for Unauthorized Access

```bash
# Enable S3 Object Lambda to audit/block access patterns
# Or use CloudWatch metrics on S3 requests
```

### DynamoDB Monitoring

```bash
# Check lock table for stuck locks
aws dynamodb scan \
  --table-name rupaya-terraform-state-lock \
  --region us-east-1
```

## Troubleshooting

### State Lock Stuck

```bash
# Find and delete stuck lock (use with caution!)
aws dynamodb scan \
  --table-name rupaya-terraform-state-lock \
  --region us-east-1

aws dynamodb delete-item \
  --table-name rupaya-terraform-state-lock \
  --key '{"LockID":{"S":"prod/infrastructure/terraform.tfstate"}}'
```

### State Corruption

```bash
# Restore from S3 version history
aws s3api list-object-versions \
  --bucket rupaya-terraform-state-767397779454 \
  --prefix prod/infrastructure/

# Restore specific version
aws s3 cp \
  s3://rupaya-terraform-state-767397779454/prod/infrastructure/terraform.tfstate?versionId=xyz \
  terraform.tfstate
```

### Encryption Errors

```bash
# Verify KMS key permissions
aws kms describe-key --key-id alias/rupaya-terraform-state

# Grant permissions if needed
aws kms grant-token --key-id ...
```

## Best Practices

1. **Separate AWS Accounts** (for prod vs staging)
2. **Different KMS Keys** per environment
3. **MFA Delete** enabled on prod state bucket
4. **Approval Gates** in CI/CD before apply
5. **Team Members** have read-only access to state
6. **Only CI/CD** has write access
7. **Regular Backups** tested for restore
8. **Encryption Keys** rotated annually
9. **CloudTrail Logs** exported to separate bucket for compliance
10. **Drift Detection** automated monthly

## References

- [Terraform Backend S3](https://www.terraform.io/language/settings/backends/s3)
- [AWS S3 Bucket Policies](https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-control-overview.html)
- [DynamoDB State Locking](https://www.terraform.io/language/settings/backends/s3#dynamodb-state-locking)
- [Terraform Cloud](https://app.terraform.io) - Enterprise SaaS alternative
