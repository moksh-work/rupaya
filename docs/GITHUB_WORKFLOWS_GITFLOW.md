# GitHub Actions Workflows - Git Flow Implementation

This document describes all GitHub Actions workflows aligned with the Git Flow branching strategy used by Rupaya.

## Overview

The Rupaya CI/CD pipeline follows **Git Flow** branching model with automated deployments:

```
develop (Staging)
  ↑
  ├── feature/* → PR to develop → Tests & Review
  ├── bugfix/* → PR to develop → Tests & Review
  ├── chore/* → PR to develop → Tests & Review
  │
  └─→ Auto-merge → Deploy to staging
      
main (Production)
  ↑
  ├── release/* → PR to main → Tests & 2 Approvals
  ├── hotfix/* → PR to main → Tests & Urgent Deploy
  └─→ Tag & Deploy to production
```

## Workflow Architecture

### 1. **Git Flow - Feature Validation** (`.github/workflows/git-flow-feature.yml`)

**Trigger:** Pull Request to `develop` from `feature/*`, `bugfix/*`, `chore/*`

**Purpose:** Validate feature branches before merging to staging

**Steps:**
- ✓ Validate branch naming (feature/JIRA-123-description)
- ✓ Run linter and code quality checks
- ✓ Run full test suite (unit tests, integration tests)
- ✓ Run security scans (npm audit, secret scanning)
- ✓ Upload coverage reports

**Approval Requirements:**
- 1 code review approval minimum
- All tests must pass
- No security vulnerabilities

**Auto-Merge:** No (requires manual merge)

### 2. **Backend CI/CD Pipeline** (`.github/workflows/backend.yml`)

**Trigger:** 
- Push to: `develop`, `main`, `release/*`, `hotfix/*`
- PR to: `develop`, `main`

**Purpose:** Test and build backend Docker image for ECR

**Steps:**
- ✓ Run linter (ESLint, Prettier)
- ✓ Run unit tests with coverage
- ✓ Build Docker image (multi-arch)
- ✓ Push to Amazon ECR

**Build Conditions:**
- **develop** → `staging-COMMIT_SHA` tag
- **main** → `prod-COMMIT_SHA` tag
- **release/** → `release-COMMIT_SHA` tag
- **hotfix/** → `hotfix-COMMIT_SHA` tag

**PR Mode:** Tests only, no image build

### 3. **Deploy to Staging** (`.github/workflows/deploy-staging.yml`)

**Trigger:**
- Push to: `develop`, `release/*`
- Manual: `workflow_dispatch`

**Purpose:** Deploy backend to staging ECS cluster

**Environment:** AWS Staging (us-east-1)

**Cluster:** `rupaya-staging`

**Auto-Deploy:**
- ✓ `develop` → Auto-deploy to staging
- ⚠ `release/*` → Requires manual approval

**Steps:**
- ✓ Validate and test code
- ✓ Build Docker image
- ✓ Push to ECR
- ✓ Update ECS service with new image
- ✓ Monitor deployment (30-minute timeout)

### 4. **Deploy to Production** (`.github/workflows/deploy-production.yml`)

**Trigger:**
- Push to: `main`, `hotfix/*`
- Tags: `v*.*.*`
- Manual: `workflow_dispatch`

**Purpose:** Deploy backend to production ECS cluster

**Environment:** AWS Production (us-east-1)

**Cluster:** `rupaya-production`

**Auto-Deploy:**
- ✓ `main` → Auto-deploy (after release merge)
- ✓ `hotfix/*` → Urgent deploy (high priority)

**Steps:**
- ✓ Validate code and tests
- ✓ Build Docker image
- ✓ Push to ECR
- ✓ Blue/green deployment
- ✓ Health checks
- ✓ Rollback on failure

### 5. **Terraform Infrastructure Deploy** (`.github/workflows/terraform-staged-deploy.yml`)

**Trigger:**
- Push to: `develop`, `main`, `hotfix/*`, `release/*`
- PR to: `develop`, `main`
- Manual: `workflow_dispatch`

**Purpose:** Deploy AWS infrastructure with Terraform

**Infrastructure Stages:**
1. **Stage 1 - ACM Certificates** (must pass first)
   - Deploy/update SSL certificates
   - Wait for certificate issuance
2. **Stage 2 - Infrastructure** (depends on Stage 1)
   - Deploy VPC, subnets, security groups
   - Deploy ALB with listeners
   - Deploy ECS cluster and services
   - Deploy RDS and Redis
   - Deploy Route53 records

**Branch Behavior:**
- **develop** → Terraform applies to staging state
- **main** → Terraform applies to production state
- **release/*** → Plan only (manual approval)
- **hotfix/*** → Urgent apply to production

**State Management:**
- Each environment uses separate Terraform state:
  - `staging/infrastructure/terraform.tfstate`
  - `production/infrastructure/terraform.tfstate`
- Centralized S3 backend with DynamoDB locking
- KMS encryption for state data

### 6. **Git Flow - Release Management** (`.github/workflows/git-flow-release.yml`)

**Trigger:** Pull Request to `main` from `release/*`

**Purpose:** Manage production release process

**Steps:**
- ✓ Validate release branch naming (`release/X.Y.Z`)
- ✓ Verify version file updated
- ✓ Verify CHANGELOG.md updated
- ✓ Run full test suite
- ✓ Require 2 approvals (at least 1 from release manager)
- ✓ On merge: Create production tag (`vX.Y.Z`)
- ✓ On merge: Merge back to develop

**Approval Requirements:**
- 2 code review approvals minimum (one from release manager)
- All tests must pass
- Version and changelog must be updated

**Post-Merge Actions:**
- Create Git tag: `vX.Y.Z`
- Auto-deploy to production
- Merge release branch back to develop

### 7. **Git Flow - Hotfix Management** (`.github/workflows/git-flow-hotfix.yml`)

**Trigger:** Pull Request to `main` from `hotfix/*`

**Purpose:** Manage emergency production hotfixes

**Steps:**
- ✓ Validate hotfix branch naming (`hotfix/DESCRIPTION`)
- ✓ Run full test suite
- ✓ Security scan
- ✓ Require 1 approval (expedited review)
- ✓ On merge: Create production tag (auto-increment patch)
- ✓ On merge: Auto-deploy to production
- ✓ On merge: Merge back to develop

**Approval Requirements:**
- 1 code review approval (expedited)
- All tests must pass
- Security scan must pass

**Priority:** URGENT - High priority queue in deployment system

**Post-Merge Actions:**
- Create Git tag: `vX.Y.Z+hotfix.N`
- Auto-deploy to production
- Merge back to develop
- Alert team about hotfix deployment

### 8. **AWS RDS Migrations** (`.github/workflows/01-aws-rds-migrations.yml`)

**Trigger:**
- Push to `develop` or `main`
- Manual trigger with environment selection

**Purpose:** Run database migrations

**Environments:**
- `develop` → Staging database
- `main` → Production database

**Steps:**
- ✓ Connect to RDS database
- ✓ Run pending migrations
- ✓ Verify schema integrity
- ✓ Rollback on failure

## Branch Protection Rules

### `develop` Branch
```
✓ Require pull request before merging (1 approver)
✓ Require status checks to pass:
  - git-flow-feature (validation)
  - 02-common-backend.yml (tests)
  - Codecov (coverage)
✓ Require branches to be up to date
✓ Require code reviews from CODEOWNERS
✓ Dismiss stale reviews on new commits
```

### `main` Branch
```
✓ Require pull request before merging (2 approvers)
✓ Require status checks to pass:
  - All backend tests
  - All security scans
  - Terraform plan validation
  - Deployment preview
✓ Require branches to be up to date
✓ Require code reviews from CODEOWNERS
✓ Require approval from release manager (1 of 2)
✓ Dismiss stale reviews on new commits
✓ Enforce linear history (no merge commits)
```

### `release/*` Branches
```
✓ Require pull request before merging to main (2 approvers)
✓ Allow direct commits for version/changelog updates
✓ Require status checks to pass
✓ Auto-delete after merge
```

### `hotfix/*` Branches
```
✓ Require pull request before merging to main (1 approver - expedited)
✓ High priority queue for deployment
✓ Require status checks to pass
✓ Auto-delete after merge
```

## Environment Configuration

### GitHub Environments

Three GitHub environments are configured:

#### `staging` Environment
- Auto-deploy on: `develop` push
- Manual approval: Not required
- AWS Account: `102503111808`
- AWS Region: `us-east-1`
- ECS Cluster: `rupaya-staging`

#### `production` Environment
- Auto-deploy on: `main` push, `hotfix/*` push, `hotfix/*` merge
- Manual approval: Required for `release/*` branch
- AWS Account: `102503111808`
- AWS Region: `us-east-1`
- ECS Cluster: `rupaya-production`
- Variables:
  - `DEPLOYMENT_TIMEOUT: 900` (seconds)
  - `ENABLE_CANARY_DEPLOY: true`

#### `certificates` Environment (Optional)
- For ACM certificate management
- High security approvals

### AWS Configuration

**OIDC Authentication:**
```
Provider: arn:aws:iam::102503111808:oidc-provider/token.actions.githubusercontent.com
Trusted Entity: GitHub Actions
Role: rupaya-terraform-cicd
Permissions: Terraform, ECS, ECR, RDS, Route53, ACM, KMS, S3
```

## Workflow Decision Tree

```
Feature Development:
1. Create branch: feature/JIRA-123-description
2. Open PR to develop
3. Run: git-flow-feature workflow
4. Get 1 approval
5. Merge to develop
6. Triggers: backend.yml + deploy-staging.yml
7. Auto-deploy to staging

Release Process:
1. Create branch: release/X.Y.Z from develop
2. Update VERSION and CHANGELOG.md
3. Open PR to main
4. Run: git-flow-release workflow
5. Get 2 approvals (1 from release manager)
6. Merge to main
7. Triggers: terraform-staged-deploy + deploy-production
8. Auto-deploy to production
9. Auto-merge back to develop

Production Hotfix:
1. Create branch: hotfix/CRITICAL-ISSUE-DESCRIPTION from main
2. Fix issue with tests
3. Open PR to main
4. Run: git-flow-hotfix workflow
5. Get 1 approval (expedited)
6. Merge to main
7. Triggers: deploy-production
8. Auto-deploy to production (urgent priority)
9. Auto-merge back to develop
```

## Troubleshooting

### Workflow Not Triggering

**Check:**
1. Branch protection rules - PR might be blocked
2. Path filters - Changes don't match path patterns
3. Event type - Using correct trigger event

### Deployment Timeout

**Solutions:**
1. Check AWS CloudFormation/Terraform logs
2. Verify RDS/EC2 instance health
3. Check ECR image availability

### Certificate Not Issued

**Solutions:**
1. Verify domain ownership in ACM console
2. Check Route53 DNS records
3. Look for validation email in inbox

## Security Best Practices

- ✓ All deployments use OIDC (no long-lived credentials)
- ✓ Secrets stored in GitHub Secrets (not in code)
- ✓ All workflows have branch protection
- ✓ Deployment approval gates on main/production
- ✓ Audit logging in CloudTrail
- ✓ Docker images signed before push
- ✓ Terraform state encrypted with KMS

## Related Documentation

- [Git Branching Strategy](./GIT_BRANCHING_STRATEGY.md)
- [GitHub CICD Setup](./GITHUB_CICD_SETUP.md)
- [AWS Deployment Guide](./AWS_DEPLOYMENT_GUIDE.md)
- [Terraform Documentation](../infra/aws/README.md)
