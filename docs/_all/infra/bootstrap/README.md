# AWS Bootstrap: GitHub OIDC & IAM Setup

**Purpose**: One-time AWS account setup for GitHub Actions OIDC authentication  
**Frequency**: One time per AWS account  
**Time**: 30 minutes  

---

## 📋 Overview

This folder contains infrastructure-as-code for the one-time AWS setup required before the main Rupaya infrastructure can be deployed.

### What Gets Set Up

```
AWS Account
├─ OIDC Provider (GitHub)
│  └─ Allows GitHub Actions to authenticate without long-lived keys
├─ IAM Role: GitHubActionsRoleStaging
│  └─ Assume this role from GitHub develop branch workflows
└─ IAM Role: GitHubActionsRoleProd
   └─ Assume this role from GitHub main branch workflows
```

---

## 🚀 Quick Setup

### Prerequisites

```bash
# Install AWS CLI
brew install awscli

# Install Terraform
brew install terraform

# Configure AWS credentials
aws configure
# Enter: AWS Access Key ID, Secret Access Key, Region, Output format

# Verify AWS access
aws iam get-user
```

### 1. Set Environment Variables

```bash
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_REGION="us-east-1"
export GITHUB_ORG="your-github-org"      # e.g., "mycompany"
export GITHUB_REPO="rupaya"              # e.g., "rupaya"

echo "AWS Account: $AWS_ACCOUNT_ID"
echo "GitHub: $GITHUB_ORG/$GITHUB_REPO"
```

### 2. Deploy Bootstrap Using CLI Script

**Option A**: Run setup script (simplest)

```bash
# Make script executable
chmod +x setup.sh

# Run setup
./setup.sh \
  --account-id $AWS_ACCOUNT_ID \
  --region $AWS_REGION \
  --github-org $GITHUB_ORG \
  --github-repo $GITHUB_REPO
```

**Option B**: Use Terraform

```bash
# Copy terraform.tfvars.example
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values
nano terraform.tfvars

# Deploy
terraform init
terraform plan
terraform apply
```

**Option C**: Use AWS CLI Directly

```bash
# Follow step-by-step commands in SETUP_GUIDE.md
source ./manual_setup.sh
```

### 3. Get Output Values

```bash
# If using Terraform
terraform output staging_role_arn
terraform output prod_role_arn

# If using CLI
aws iam get-role --role-name GitHubActionsRoleStaging --query 'Role.Arn'
aws iam get-role --role-name GitHubActionsRoleProd --query 'Role.Arn'
```

### 4. Add to GitHub Repository Secrets

```bash
# Using GitHub CLI
gh secret set AWS_OIDC_ROLE_STAGING --body "arn:aws:iam::$AWS_ACCOUNT_ID:role/GitHubActionsRoleStaging"
gh secret set AWS_OIDC_ROLE_PROD --body "arn:aws:iam::$AWS_ACCOUNT_ID:role/GitHubActionsRoleProd"

# Or manually via GitHub UI
# Settings → Secrets and variables → Actions → New repository secret
```

---

## 📁 Files

| File | Purpose |
|------|---------|
| `SETUP_GUIDE.md` | Detailed step-by-step setup instructions |
| `main.tf` | (For state management - already deployed) |
| `variables.tf` | Terraform input variables |
| `terraform.tfvars.example` | Example Terraform variables |
| `setup.sh` | Automated bash setup script |
| `manual_setup.sh` | Manual AWS CLI commands |
| `destroy_all.sh` | Cleanup script (if needed) |

---

## ✅ Verification

After setup, verify everything works:

```bash
# 1. Check OIDC provider exists
aws iam list-open-id-connect-providers

# 2. Check roles exist
aws iam get-role --role-name GitHubActionsRoleStaging
aws iam get-role --role-name GitHubActionsRoleProd

# 3. Check GitHub secrets
gh secret list | grep AWS_OIDC

# 4. Test by pushing to develop branch
git push origin develop
# Watch workflow execute in GitHub Actions
```

---

## 📚 Next Steps

After bootstrap setup:

1. ✅ Bootstrap OIDC setup complete (this folder)
2. ⬜ Deploy main infrastructure (`infra/aws/`)
3. ⬜ Create RDS secrets (`infra/aws/secrets.tf`)
4. ⬜ Deploy applications

---

## 🔄 Dependency Flow

```
START HERE: infra/bootstrap/ (You are here)
  ↓ One-time setup
  ↓ Creates OIDC provider & IAM roles
  ↓
  ↓ Add role ARNs to GitHub secrets
  ↓
  ⬇️ Then proceed to:
  
infra/aws/ (Main infrastructure)
  ├─ secrets.tf (RDS credentials)
  ├─ rds.tf (Database)
  ├─ ecs.tf (Containers)
  └─ etc.
```

---

## 🚨 Important Notes

### ⚠️ One-Time Only
- OIDC setup is **one-time per AWS account**
- Don't run bootstrap multiple times (it will fail if resources already exist)
- If you need to redeploy, use `destroy_all.sh` first

### ⚠️ GitHub Repository Must Exist
- Bootstrap references specific GitHub org/repo
- Make sure your GitHub repository is created first
- Update environment variables with correct org and repo names

### ⚠️ AWS Permissions Required
- Need **IAM admin** permissions to create roles and OIDC provider
- Cannot use limited IAM users without sufficient permissions

---

## 🔗 Related Documentation

- [SETUP_GUIDE.md](SETUP_GUIDE.md) - Detailed walkthrough
- [../SECRETS_MANAGER_SETUP.md](../SECRETS_MANAGER_SETUP.md) - Next: RDS credentials setup
- [../../docs/GITHUB_ENTERPRISE_CI_CD_SETUP.md](../../docs/GITHUB_ENTERPRISE_CI_CD_SETUP.md) - Complete CI/CD guide
- [GitHub OIDC Docs](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)

---

**Current Status**: ⬜ Not yet deployed  
**Time Required**: 30 minutes  
**Complexity**: Medium  
**Run Frequency**: One time only  
**Dependencies**: AWS CLI, GitHub repo created
