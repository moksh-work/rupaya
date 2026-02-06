# GitHub Branch Protection & Workflows Setup Guide

**Environment**: GitHub Enterprise / GitHub.com  
**Repository**: rupaya  
**Strategy**: Git Flow + Trunk-Based Development

---

## 📋 Quick Setup Checklist

- [ ] Create main and develop branches
- [ ] Enable branch protection on main
- [ ] Enable branch protection on develop
- [ ] Add GitHub Actions secrets
- [ ] Configure environments (production, staging)
- [ ] Enable required workflow status checks
- [ ] Add CODEOWNERS file
- [ ] Enable auto-merge for QA workflows
- [ ] Setup Slack notifications

---

## 🌳 Branch Setup

### Step 1: Create Main Branches

```bash
# Initialize git if not done
git init

# Create and push develop branch
git checkout -b develop
git push -u origin develop

# Main branch should exist by default
git checkout main
git push origin main
```

### Step 2: Branch Protection Rules

#### **MAIN BRANCH** (Production)

Navigate to: **Settings → Branches → Branch protection rules → Add rule**

**Pattern**: `main`

```yaml
Configuration:
  1. Require a pull request before merging
     ✅ Require approvals: 2
     ✅ Dismiss stale pull request approvals when new commits are pushed
     ✅ Require review from Code Owners
     ✅ Require approval of the most recent reviewable push
  
  2. Require status checks to pass before merging
     ✅ Require branches to be up to date before merging
     Required status checks:
     ├─ lint-and-quality
     ├─ backend-tests
     ├─ security-scan
     ├─ build-check
     └─ branch-validation
  
  3. Require conversation resolution before merging
     ✅ Enabled
  
  4. Require signed commits
     ✅ Enabled (recommended)
  
  5. Restrict who can push to matching branches
     ✅ Restrict pushes that create matching branches
        → Allow only following users/teams: (ops-team)
```

#### **DEVELOP BRANCH** (Staging)

Navigate to: **Settings → Branches → Branch protection rules → Add rule**

**Pattern**: `develop`

```yaml
Configuration:
  1. Require a pull request before merging
     ✅ Require approvals: 1
     ✅ Dismiss stale pull request approvals when new commits are pushed
     ✅ Require review from Code Owners
  
  2. Require status checks to pass before merging
     ✅ Require branches to be up to date before merging
     Required status checks:
     ├─ lint-and-quality
     ├─ backend-tests
     ├─ security-scan
     ├─ build-check
     └─ branch-validation
  
  3. Require conversation resolution before merging
     ✅ Enabled
  
  4. Allow auto-merge for hotfix branches
     ✅ Auto-merge enabled (Squash and merge)
```

#### **RELEASE BRANCHES** (Release preparation)

Navigate to: **Settings → Branches → Branch protection rules → Add rule**

**Pattern**: `release/*`

```yaml
Configuration:
  1. Require a pull request before merging
     ✅ Require approvals: 1
  
  2. Require status checks to pass before merging
     ✅ All checks same as develop
  
  3. Allow auto-merge
     ✅ Enabled (Squash and merge)
```

---

## 🔐 GitHub Actions Secrets Setup

### Step 1: Add Repository Secrets

Navigate to: **Settings → Secrets and variables → Actions → Repository secrets**

#### **AWS Credentials**

```
AWS_ACCESS_KEY_ID
Value: <AWS Access Key>

AWS_SECRET_ACCESS_KEY
Value: <AWS Secret Access Key>

ECR_REGISTRY
Value: <Account ID>.dkr.ecr.us-east-1.amazonaws.com

AWS_ROLE_TO_ASSUME (for OIDC)
Value: arn:aws:iam::<Account ID>:role/GitHubActionsRole
```

#### **Database Credentials**

```
PROD_DATABASE_URL
Value: postgresql://user:password@rupaya-prod.xxx.us-east-1.rds.amazonaws.com:5432/rupaya

STAGING_DATABASE_URL
Value: postgresql://user:password@rupaya-staging.xxx.us-east-1.rds.amazonaws.com:5432/rupaya

RDS_PROXY_ENDPOINT
Value: rupaya-prod-proxy.proxy-xxx.us-east-1.rds.amazonaws.com
```

#### **Application Secrets**

```
JWT_SECRET
Value: <32+ character random string>

JWT_REFRESH_SECRET
Value: <32+ character random string>

ENCRYPTION_KEY
Value: <32 byte encryption key>

API_SECRET
Value: <Random secret key>
```

#### **Testing Credentials**

```
SMOKE_TEST_EMAIL
Value: test@example.com

SMOKE_TEST_PASSWORD
Value: TestPassword123!
```

#### **Notifications**

```
SLACK_WEBHOOK
Value: https://hooks.slack.com/services/TXXXXX/BXXXXX/XXXXXXX

SLACK_WEBHOOK_PROD
Value: https://hooks.slack.com/services/TXXXXX/BXXXXX/XXXXXXY
```

### Step 2: Add Environment-Specific Secrets

Navigate to: **Settings → Environments → [Environment Name] → Environment secrets**

#### **Production Environment**

```
Environment Name: production
Protected branch: main
```

Secrets:
```
PROD_DATABASE_URL
PROD_REDIS_URL
PROD_API_KEY
```

#### **Staging Environment**

```
Environment Name: staging
Protected branch: develop
```

Secrets:
```
STAGING_DATABASE_URL
STAGING_REDIS_URL
STAGING_API_KEY
```

---

## 👥 CODEOWNERS Setup

Create `.github/CODEOWNERS` file:

```
# Global owners
* @backend-team @platform-team

# Backend
/backend/ @backend-team
/backend/src/services/ @backend-team @security-team

# Infrastructure
/infra/ @platform-team @devops-team
/terraform/ @platform-team

# Mobile
/ios/ @ios-team
/android/ @android-team

# Documentation
/docs/ @documentation-team
*.md @documentation-team

# GitHub Actions
.github/workflows/ @platform-team @devops-team

# CI/CD
.github/scripts/ @platform-team
```

---

## 🔄 Workflow Status Checks

Navigate to: **Settings → Branches → main → Require status checks**

Required checks for **main branch**:

```yaml
✅ lint-and-quality
✅ backend-tests
✅ security-scan
✅ build-check
✅ branch-validation
✅ validate
```

---

## 🌐 Environments Configuration

Navigate to: **Settings → Environments**

### Production Environment

```
Name: production
Protected branches: main
Reviewers: @ops-team, @tech-lead

Environment secrets:
├─ PROD_DATABASE_URL
├─ PROD_REDIS_URL
├─ PROD_API_KEYS
└─ MONITORING_WEBHOOKS
```

### Staging Environment

```
Name: staging
Protected branches: develop
Reviewers: @qa-team, @tech-lead

Environment secrets:
├─ STAGING_DATABASE_URL
├─ STAGING_REDIS_URL
└─ STAGING_API_KEYS
```

---

## 📝 Workflow Files to Add

The following workflows should already exist in `.github/workflows/`:

```
.github/workflows/
├── validate.yml                    # Linting, testing, security
├── deploy-staging.yml              # Deploy to staging (develop)
├── deploy-production.yml           # Deploy to production (main)
├── branch-validation.yml           # Branch naming enforcement
├── backend-tests.yml               # Backend test suite
├── tests.yml                       # Multi-platform testing
├── 11-common-mobile-build.yml      # iOS/Android builds
├── 06-aws-ecr-backend.yml          # ECR push
├── 01-aws-rds-migrations.yml       # Database migrations
├── aws-lambda-deployment.yml       # Lambda deployments
├── 10-common-ios.yml               # iOS builds
├── 09-common-android.yml           # Android builds
└── security-scan.yml               # Security scanning (Trivy, npm audit)
```

---

## ✅ Verification Steps

### 1. Verify Branch Protection

```bash
# List branch protection rules
gh api repos/{owner}/{repo}/branches --jq '.[] | {name: .name, protected: .protected}'

# Verify main branch protection
gh api repos/{owner}/{repo}/branches/main --jq '.protection'

# Verify develop branch protection
gh api repos/{owner}/{repo}/branches/develop --jq '.protection'
```

### 2. Verify Workflow Permissions

```bash
# Check workflow permissions
gh api repos/{owner}/{repo}/actions/permissions
```

### 3. Test a Feature Branch

```bash
# Create and push a feature branch
git checkout -b feature/test-workflow
echo "# Test" >> README.md
git add .
git commit -m "Test: verify workflows"
git push -u origin feature/test-workflow

# Create PR and verify:
# ✅ Workflows run automatically
# ✅ Status checks appear
# ✅ Cannot merge without approvals
# ✅ Cannot merge with failing checks
```

### 4. Verify Slack Notifications

1. Push to develop branch
2. Check Slack for deployment notification
3. Verify message includes commit, author, environment

---

## 🚀 First Deployment

### Step 1: Initial Setup Validation

```bash
# Verify main branch exists and is protected
git branch -a

# Verify workflows are in place
ls -la .github/workflows/

# Verify secrets are configured
gh secret list
```

### Step 2: Deploy to Staging

```bash
# Create a release branch
git checkout develop
git pull origin develop
git checkout -b release/1.0.0

# Update version
# ... make version changes ...

git add .
git commit -m "Release: version 1.0.0"
git push -u origin release/1.0.0

# Create PR to main via GitHub UI
# → Wait for workflows to pass
# → Get 2 approvals
# → Merge to main
```

### Step 3: Monitor Production Deployment

```bash
# View workflow runs
gh run list --workflow deploy-production.yml

# View logs for latest run
gh run view <run-id> --log
```

---

## 🔍 Troubleshooting

### Workflows Not Running

```bash
# Check if workflows are enabled
gh api repos/{owner}/{repo}/actions/permissions

# Check for syntax errors
gh workflow view validate.yml

# Re-run a failed workflow
gh run rerun <run-id>
```

### Status Checks Not Required

1. Go to **Settings → Branches → main**
2. Scroll to "Require status checks to pass before merging"
3. Add missing checks:
   - lint-and-quality
   - backend-tests
   - security-scan
   - build-check

### Secrets Not Available in Workflow

```bash
# List all secrets
gh secret list

# Verify secret was added correctly
gh secret view AWS_ACCESS_KEY_ID

# Re-add secret if needed
gh secret set AWS_ACCESS_KEY_ID < aws-key.txt
```

---

## 📚 Additional Resources

- [GitHub Branch Protection Docs](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)
- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Git Flow Workflow](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow)
- [GitHub CLI Documentation](https://cli.github.com/manual/)

---

## ✨ Summary

Once setup is complete:

1. ✅ All pushes to main/develop trigger validation
2. ✅ PRs require approvals before merging
3. ✅ Failed tests block merges
4. ✅ Staging deploys automatically on develop push
5. ✅ Production deploys automatically on main push
6. ✅ Team receives notifications on Slack
7. ✅ Hotfixes can be deployed within 2 minutes

**Status**: Ready for team collaboration and continuous deployment

