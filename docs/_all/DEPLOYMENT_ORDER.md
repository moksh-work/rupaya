# Deployment Order: Prerequisites & Dependencies

**Date**: February 5, 2026  
**Purpose**: Clear roadmap showing what must be set up first  
**Target Audience**: DevOps engineers, platform teams  

---

## 🎯 The Big Picture

Your Rupaya project has **layers of dependencies**. Each layer depends on the one below it being complete:

```
Layer 4: Applications & Workflows Run
┌──────────────────────────────────────┐
│ .github/workflows/                   │
│ ├─ 01-aws-rds-migrations.yml         │
│ ├─ 02-aws-deploy-staging.yml         │
│ └─ 03-aws-deploy-production.yml      │
└────────────┬─────────────────────────┘
             ↑ (depends on Layer 3)

Layer 3: Infrastructure Deployed
┌──────────────────────────────────────┐
│ infra/aws/                           │
│ ├─ secrets.tf (RDS credentials)      │
│ ├─ rds.tf (Database)                 │
│ ├─ ecs.tf (Containers)               │
│ └─ etc.                              │
└────────────┬─────────────────────────┘
             ↑ (depends on Layer 2)

Layer 2: GitHub Repository Secrets Configured
┌──────────────────────────────────────┐
│ GitHub Settings → Secrets & Variables│
│ ├─ AWS_OIDC_ROLE_STAGING             │
│ └─ AWS_OIDC_ROLE_PROD                │
└────────────┬─────────────────────────┘
             ↑ (depends on Layer 1)

Layer 1: AWS Bootstrap (ONE-TIME)
┌──────────────────────────────────────┐
│ infra/bootstrap/ ← START HERE         │
│ ├─ Create OIDC provider              │
│ ├─ Create IAM roles                  │
│ └─ Set up trust policies             │
└──────────────────────────────────────┘
```

---

## 📋 Step-by-Step Setup Order

### ✅ Step 1: AWS Bootstrap Setup (30 minutes)
**Location**: `infra/bootstrap/`  
**Must Do First**: YES (all other steps depend on this)  
**Frequency**: One-time per AWS account

**What It Does**:
- Creates OIDC provider (GitHub verifies tokens here)
- Creates IAM role for staging deployments
- Creates IAM role for production deployments
- Sets up trust relationships

**Commands**:
```bash
cd infra/bootstrap

# Option A: Use script
./setup.sh --account-id 123456789012 --region us-east-1 \
  --github-org myorg --github-repo rupaya

# Option B: Use Terraform
terraform init
terraform plan
terraform apply

# Get outputs
terraform output staging_role_arn
terraform output prod_role_arn
```

**Outputs You Need**:
```
AWS_OIDC_ROLE_STAGING = arn:aws:iam::123456789012:role/GitHubActionsRoleStaging
AWS_OIDC_ROLE_PROD = arn:aws:iam::123456789012:role/GitHubActionsRoleProd
```

**Verification**:
```bash
aws iam get-role --role-name GitHubActionsRoleStaging
aws iam list-open-id-connect-providers
```

---

### ✅ Step 2: Add GitHub Secrets (5 minutes)
**Location**: GitHub UI or `gh` CLI  
**Must Do First**: YES (workflows need these secrets)  
**Frequency**: Once per repository

**What It Does**:
- Stores AWS role ARNs in GitHub
- GitHub Actions workflows retrieve these at runtime
- No credentials stored (only role ARNs)

**Commands**:
```bash
# Using GitHub CLI
gh secret set AWS_OIDC_ROLE_STAGING \
  --body "arn:aws:iam::123456789012:role/GitHubActionsRoleStaging"

gh secret set AWS_OIDC_ROLE_PROD \
  --body "arn:aws:iam::123456789012:role/GitHubActionsRoleProd"

# Verify
gh secret list
```

**Or Manually**:
1. Go to GitHub → Your Repo → Settings
2. → Secrets and variables → Actions
3. → New repository secret
4. Add `AWS_OIDC_ROLE_STAGING` with value
5. Add `AWS_OIDC_ROLE_PROD` with value

**Verification**:
```bash
# List secrets
gh secret list

# Should show:
# AWS_OIDC_ROLE_PROD
# AWS_OIDC_ROLE_STAGING
```

---

### ✅ Step 3: Deploy Main Infrastructure (1-2 hours)
**Location**: `infra/aws/`  
**Must Do First**: YES (creates all AWS resources)  
**Frequency**: As needed

**What It Does**:
- Creates VPC, subnets, security groups
- Creates RDS database
- Creates ECR registries
- Creates ECS clusters
- Creates other AWS infrastructure

**Commands**:
```bash
cd infra/aws

# Initialize Terraform
terraform init \
  -backend-config="bucket=rupaya-tf-state" \
  -backend-config="key=aws/terraform.tfstate" \
  -backend-config="region=us-east-1"

# Review changes
terraform plan -out=tfplan

# Deploy
terraform apply tfplan

# Note outputs
terraform output
```

**Prerequisites**:
- ✅ Step 1: Bootstrap completed (roles created)
- ✅ Step 2: GitHub secrets added (roles accessible)

**Outputs You Need**:
```
rds_endpoint = rupaya-postgres.xxx.us-east-1.rds.amazonaws.com
ecr_registry = 123456789012.dkr.ecr.us-east-1.amazonaws.com
ecs_cluster_name = rupaya-cluster
```

---

### ✅ Step 4: Create RDS Secrets (30 minutes)
**Location**: `infra/aws/secrets.tf` (runs as part of Step 3)  
**Must Do First**: YES (workflows need database credentials)  
**Frequency**: After infrastructure deployment

**What It Does**:
- Creates AWS Secrets Manager secrets
- Stores RDS credentials (username, password, host, port, dbname)
- Sets up automatic 30-day rotation
- Grants IAM roles permission to read secrets

**Verification**:
```bash
# List secrets
aws secretsmanager list-secrets --filters Key=name,Values=rupaya/rds

# View a secret
aws secretsmanager get-secret-value \
  --secret-id rupaya/rds/staging

# Should return JSON with username, password, host, etc.
```

**Note**: Already included in `infra/aws/secrets.tf` - runs as part of Step 3

---

### ✅ Step 5: Test OIDC Authentication (15 minutes)
**Location**: GitHub Actions  
**Must Do First**: YES (before running production workflows)  
**Frequency**: First time setup only

**What It Does**:
- Tests that GitHub can authenticate to AWS
- Verifies IAM role assumptions work
- Confirms workflows can access Secrets Manager

**Commands**:
```bash
# Push test commit to develop
git checkout develop
git commit --allow-empty -m "test: OIDC authentication"
git push origin develop

# Watch workflow run
gh run list --workflow 01-aws-rds-migrations.yml

# Check logs
gh run view <run-id> --log

# Look for success indicators:
# ✅ "Assuming role arn:aws:iam::123456789012:role/GitHubActionsRoleStaging"
# ✅ "Successfully obtained temporary credentials"
```

---

### ✅ Step 6: Deploy Applications (1-2 hours)
**Location**: Application-specific configurations  
**Must Do First**: NO (can deploy after infrastructure ready)  
**Frequency**: As needed

**What It Does**:
- Deploys your application code
- Sets up ECS services
- Configures load balancers
- Sets up monitoring

**Prerequisites**:
- ✅ Steps 1-5 complete
- ✅ OIDC authentication tested successfully

---

## 📊 Dependency Matrix

| Step | Depends On | Required For | Time |
|------|-----------|-------------|------|
| 1: Bootstrap | AWS CLI access | Step 2 | 30 min |
| 2: GitHub Secrets | Step 1 | Step 3, 5 | 5 min |
| 3: Infrastructure | Step 2 | Step 4, 6 | 1-2 hrs |
| 4: RDS Secrets | Step 3 | Step 5 | 30 min |
| 5: OIDC Test | Step 2, 3, 4 | Step 6 | 15 min |
| 6: Applications | Step 5 | Users | 1-2 hrs |

---

## ⚠️ Common Mistakes (What NOT to Do)

### ❌ Mistake 1: Skip Bootstrap Setup
**Problem**: No OIDC provider → Workflows can't authenticate → Deployments fail

**Solution**: Do Step 1 first

### ❌ Mistake 2: Deploy Infrastructure Without Secrets
**Problem**: Workflows have no credentials → Database migrations fail

**Solution**: Complete Steps 1-4 before running workflows

### ❌ Mistake 3: Run Workflows Before Testing OIDC
**Problem**: Don't know if authentication works → Get confused by failures

**Solution**: Do Step 5 (OIDC test) before real deployments

### ❌ Mistake 4: Add Credentials to GitHub
**Problem**: Security risk → Compliance failures → AWS violations

**Solution**: Use OIDC roles (Step 1) instead of storing credentials

---

## 🔄 Typical Timeline

```
Day 1 - Bootstrap & Setup (2-3 hours)
  ├─ 30 min: Step 1 - Bootstrap AWS OIDC
  ├─ 5 min: Step 2 - Add GitHub secrets
  ├─ 1-2 hrs: Step 3 - Deploy infrastructure
  ├─ 30 min: Step 4 - RDS secrets (automatic)
  └─ 15 min: Step 5 - Test OIDC

Day 2+ - Development & Deployment (ongoing)
  ├─ Deploy applications (Step 6)
  ├─ Push code to develop
  ├─ Workflows run automatically
  └─ Deployments to staging/production
```

---

## 📚 Documentation for Each Step

| Step | Documentation | Time |
|------|---------------|------|
| 1 | [infra/bootstrap/SETUP_GUIDE.md](infra/bootstrap/SETUP_GUIDE.md) | 5 min read |
| 2 | [docs/GITHUB_ENTERPRISE_CI_CD_SETUP.md](docs/GITHUB_ENTERPRISE_CI_CD_SETUP.md) | 5 min read |
| 3 | [infra/aws/README.md](infra/aws/README.md) | 10 min read |
| 4 | [infra/aws/SECRETS_MANAGER_SETUP.md](infra/aws/SECRETS_MANAGER_SETUP.md) | 10 min read |
| 5 | [.github/workflows/01-aws-rds-migrations.yml](.github/workflows/01-aws-rds-migrations.yml) | 5 min read |
| 6 | Application-specific docs | Varies |

---

## ✅ Verification Checklist

Before moving to the next step, verify the current step is complete:

### After Step 1 (Bootstrap)
- [ ] OIDC provider created: `aws iam list-open-id-connect-providers`
- [ ] Staging role created: `aws iam get-role --role-name GitHubActionsRoleStaging`
- [ ] Production role created: `aws iam get-role --role-name GitHubActionsRoleProd`
- [ ] Role ARNs documented

### After Step 2 (GitHub Secrets)
- [ ] `AWS_OIDC_ROLE_STAGING` secret exists: `gh secret list`
- [ ] `AWS_OIDC_ROLE_PROD` secret exists
- [ ] Secrets contain correct role ARNs

### After Step 3 (Infrastructure)
- [ ] VPC created: `aws ec2 describe-vpcs`
- [ ] RDS instance: `aws rds describe-db-instances`
- [ ] ECR repositories: `aws ecr describe-repositories`
- [ ] Terraform state backed up

### After Step 4 (RDS Secrets)
- [ ] Staging secret created: `aws secretsmanager list-secrets --filters Key=name,Values=rupaya/rds/staging`
- [ ] Production secret created
- [ ] Secrets contain username, password, host, port, dbname

### After Step 5 (OIDC Test)
- [ ] Test commit pushed to develop
- [ ] Workflow executed successfully: `gh run list`
- [ ] No "AccessDenied" errors in logs: `gh run view <id> --log`
- [ ] OIDC role assumed successfully

---

## 🎓 Key Concepts

### Why This Order?

1. **Bootstrap first** - Creates the "trust" between GitHub and AWS
2. **GitHub secrets** - Makes role ARNs available to workflows
3. **Infrastructure** - Creates actual AWS resources (database, containers, etc.)
4. **Secrets** - Stores credentials for applications to use
5. **Test OIDC** - Ensures everything works before production
6. **Deploy apps** - Safe to deploy when infrastructure is ready

### Why Can't We Change the Order?

```
Example: What if we try Step 3 before Step 1?

Step 3 (Deploy Infrastructure) needs:
  └─ GitHub secrets (from Step 2)
      └─ Which depends on Step 1

Result: No OIDC provider to trust → GitHub can't authenticate → Workflows fail
```

---

## 📞 Getting Help

**Issue**: OIDC authentication fails  
→ See [infra/bootstrap/SETUP_GUIDE.md#troubleshooting](infra/bootstrap/SETUP_GUIDE.md#troubleshooting)

**Issue**: Database migrations don't work  
→ See [infra/aws/SECRETS_MANAGER_SETUP.md#troubleshooting](infra/aws/SECRETS_MANAGER_SETUP.md#troubleshooting)

**Issue**: Don't know what to do next  
→ Check this document to see current step and next step

**Issue**: Something failed midway  
→ Use the verification checklist to find what's missing

---

## 🎯 Summary

| # | Step | Time | Required | Status |
|---|------|------|----------|--------|
| 1 | Bootstrap AWS OIDC | 30 min | ✅ YES | ⬜ Pending |
| 2 | Add GitHub Secrets | 5 min | ✅ YES | ⬜ Pending |
| 3 | Deploy Infrastructure | 1-2 hrs | ✅ YES | ⬜ Pending |
| 4 | RDS Secrets | 30 min | ✅ YES | ⬜ Pending |
| 5 | Test OIDC | 15 min | ✅ YES | ⬜ Pending |
| 6 | Deploy Applications | 1-2 hrs | ⚠️ Optional | ⬜ Pending |

**Total Time**: 3-4 hours for complete setup  
**Next Action**: Start with Step 1 - Bootstrap!

---

**Questions?** Read the detailed setup guide for your current step above.  
**Ready?** Begin with [infra/bootstrap/SETUP_GUIDE.md](infra/bootstrap/SETUP_GUIDE.md)

---

**Last Updated**: February 5, 2026  
**Status**: Complete & Ready  
**Audience**: DevOps, Platform Engineers
