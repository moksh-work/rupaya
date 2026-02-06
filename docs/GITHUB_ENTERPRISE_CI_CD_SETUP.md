# GitHub Enterprise CI/CD Configuration Guide

**Objective**: Zero-touch CI/CD automation with minimal manual interventions  
**Repository**: Rupaya  
**Strategy**: Git Flow + GitHub Actions + Enterprise Security  
**Last Updated**: February 5, 2026

---

## � Important Security Principle: Secrets Storage Architecture

### The Problem with Storing Credentials in GitHub Secrets

❌ **Anti-Pattern**: Storing RDS credentials directly in GitHub
```
GitHub Secrets:
  - RDS_STAGING_USER
  - RDS_STAGING_PASSWORD
  - RDS_PROD_USER
  - RDS_PROD_PASSWORD
```

**Why This is Bad**:
- ❌ Credentials visible in GitHub (if accidentally leaked)
- ❌ Manual rotation required (change password → update GitHub)
- ❌ No audit logging of credential usage
- ❌ No encryption control
- ❌ Violates principle of least privilege
- ❌ Fails SOC2/PCI-DSS compliance audits

### The Correct Pattern: AWS Secrets Manager + OIDC

✅ **Enterprise-Grade Pattern**: GitHub stores only OIDC role, retrieves credentials at runtime
```
GitHub Secrets:
  - AWS_OIDC_ROLE_STAGING (only this!)
  - AWS_OIDC_ROLE_PROD (only this!)

AWS Secrets Manager:
  - rupaya/rds/staging (encrypted, audited, rotatable)
  - rupaya/rds/production (encrypted, audited, rotatable)

Workflow Flow:
  1. GitHub Actions assumes OIDC role
  2. OIDC role has permission to read Secrets Manager
  3. At runtime, workflow retrieves credentials from Secrets Manager
  4. Use credentials for database operations
  5. CloudTrail logs all access attempts
```

**Why This is Enterprise-Grade**:
- ✅ No actual credentials in GitHub
- ✅ Automatic credential rotation in Secrets Manager
- ✅ Full audit logging via CloudTrail
- ✅ AWS KMS encryption at rest
- ✅ Fine-grained IAM policies
- ✅ Passes SOC2/PCI-DSS compliance
- ✅ Follows AWS best practices
- ✅ Secrets Manager handles encryption keys

### Quick Comparison Table

| Aspect | GitHub Secrets | AWS Secrets Manager |
|--------|-----------------|-------------------|
| Credentials Visible in GitHub | ❌ Yes (risk) | ✅ No |
| Automatic Rotation | ❌ Manual | ✅ Automatic |
| Audit Logging | ⚠️ Limited | ✅ Full CloudTrail |
| Encryption | ⚠️ GitHub managed | ✅ AWS KMS |
| Compliance Ready | ❌ No | ✅ SOC2/PCI-DSS |
| Access Control | ⚠️ All-or-nothing | ✅ Fine-grained IAM |
| Cost | Free | $0.40/secret/month |

---

## �📋 Executive Summary

This guide provides complete setup instructions for enterprise-level CI/CD automation. Once configured, all 24 workflows will execute automatically based on branch patterns and file changes, requiring minimal manual intervention.

**Key Features**:
- ✅ Automatic validation on all branches
- ✅ Automatic deployment to staging/production
- ✅ Enforced code reviews and approvals
- ✅ Secure credential management with OIDC
- ✅ Real-time Slack notifications
- ✅ Protection against unauthorized deployments

---

## 🔐 Part 1: Repository Secrets Configuration

Navigate to: **Settings → Secrets and variables → Actions → Repository secrets**

### AWS Secrets (for AWS deployments)

These secrets enable secure authentication to AWS services without storing long-lived access keys or database credentials.

```
AWS_OIDC_ROLE_ARN
Description: ARN of the GitHub Actions IAM role in AWS (OIDC authentication)
Format: arn:aws:iam::<ACCOUNT_ID>:role/GitHubActionsRole
Used by: 06-aws-ecr-backend.yml, 07-aws-ec2-deploy.yml, 08-aws-eks-deploy.yml, 09-aws-lambda-deploy.yml

AWS_OIDC_ROLE_STAGING
Description: OIDC role for staging deployments (has permissions to read Secrets Manager)
Format: arn:aws:iam::<ACCOUNT_ID>:role/GitHubActionsRoleStaging
Used by: 01-aws-rds-migrations.yml (staging job)

AWS_OIDC_ROLE_PROD
Description: OIDC role for production deployments (has permissions to read Secrets Manager)
Format: arn:aws:iam::<ACCOUNT_ID>:role/GitHubActionsRoleProd
Used by: 01-aws-rds-migrations.yml (production job)

EC2_INSTANCE_ID
Description: AWS EC2 instance ID for direct deployment
Format: i-0123456789abcdef0
Used by: 07-aws-ec2-deploy.yml

KUBE_CONFIG_DATA
Description: Base64-encoded kubeconfig for EKS cluster access
Format: base64 encoded kubeconfig file
Used by: 08-aws-eks-deploy.yml

⚠️ RDS CREDENTIALS: DO NOT STORE IN GITHUB SECRETS
   Instead, store in AWS Secrets Manager (see Part 12 below)
   Workflows retrieve credentials at runtime using OIDC role
```

### GCP Secrets (for GCP deployments)

```
GCP_PROJECT_ID
Description: GCP project ID
Format: rupaya-project-id
Used by: 01-gcp-cloudrun-backend.yml, 02-gcp-compute-backend.yml, 03-gcp-gke-backend.yml, 04-gcp-functions-backend.yml

GCP_WORKLOAD_IDENTITY_PROVIDER
Description: Workload Identity Provider resource name
Format: projects/<PROJECT_NUMBER>/locations/global/workloadIdentityPools/<POOL_NAME>/providers/<PROVIDER_NAME>
Used by: All GCP workflows

GCP_SERVICE_ACCOUNT_EMAIL
Description: Service account email for GCP authentication
Format: github-actions@<PROJECT_ID>.iam.gserviceaccount.com
Used by: All GCP workflows
```

### Mobile Build Secrets

```
IOS_BUILD_CERTIFICATE_BASE64
Description: iOS distribution certificate in base64 format
Format: base64 encoded .p12 certificate
Used by: 10-common-ios.yml

IOS_P12_PASSWORD
Description: Password for iOS P12 certificate
Format: <certificate password>
Used by: 10-common-ios.yml

IOS_KEYCHAIN_PASSWORD
Description: Keychain password for macOS build environment
Format: <keychain password>
Used by: 10-common-ios.yml

APP_STORE_CONNECT_API_KEY
Description: App Store Connect API key for iOS publishing
Format: base64 encoded API key JSON
Used by: 10-common-ios.yml

ANDROID_KEYSTORE_BASE64
Description: Android keystore in base64 format
Format: base64 encoded .jks keystore
Used by: 09-common-android.yml

ANDROID_KEYSTORE_PASSWORD
Description: Password for Android keystore
Format: <keystore password>
Used by: 09-common-android.yml

ANDROID_KEY_ALIAS
Description: Key alias in Android keystore
Format: release
Used by: 09-common-android.yml

ANDROID_KEY_PASSWORD
Description: Password for Android key
Format: <key password>
Used by: 09-common-android.yml

GOOGLE_PLAY_SERVICE_ACCOUNT
Description: Google Play Console service account JSON (base64)
Format: base64 encoded service account JSON
Used by: 09-common-android.yml
```

### Testing & Notifications

```
SMOKE_TEST_EMAIL
Description: Test user email for smoke testing
Format: test@example.com
Used by: 02-aws-deploy-staging.yml

SMOKE_TEST_PASSWORD
Description: Test user password for smoke testing
Format: <test password>
Used by: 02-aws-deploy-staging.yml

SLACK_WEBHOOK
Description: Slack webhook for staging/general deployments
Format: https://hooks.slack.com/services/TXXXXX/BXXXXX/XXXXXXX
Used by: 02-aws-deploy-staging.yml, 05-aws-ecs-deploy.yml, 01-aws-rds-migrations.yml

SLACK_WEBHOOK_PROD
Description: Slack webhook for production deployments (separate channel)
Format: https://hooks.slack.com/services/TXXXXX/BXXXXX/XXXXXXY
Used by: 03-aws-deploy-production.yml
```

---

## 🛡️ Part 2: Branch Protection Rules

Navigate to: **Settings → Branches → Branch protection rules**

### Rule 1: Main Branch (Production)

**Pattern**: `main`

**Configuration**:

```yaml
# 1. Pull Request Requirements
Require a pull request before merging:
  ✅ Enabled
  
Require approvals:
  ✅ Number of approvals required: 2
  ✅ Dismiss stale pull request approvals when new commits are pushed: YES
  ✅ Require review from Code Owners: YES
  ✅ Require approval of the most recent reviewable push: YES

# 2. Status Checks
Require status checks to pass before merging:
  ✅ Enabled
  ✅ Require branches to be up to date before merging: YES
  
Required status checks:
  • lint-and-quality
  • backend-tests
  • security-scan
  • build-check
  • branch-validation

# 3. Code Review Requirements
Require conversation resolution before merging:
  ✅ Enabled

# 4. Security
Require signed commits:
  ✅ Enabled (Recommended)

# 5. Push Restrictions
Restrict who can push to matching branches:
  ✅ Restrict pushes that create matching branches
  ✅ Allow only the following users/teams to push: ops-team, devops-team

# 6. Bypass Rules
Do not allow bypassing the above settings:
  ✅ Enabled

# 7. Admin Bypass
Include administrators:
  ⚠️ Uncheck to prevent admins from bypassing (Recommended for compliance)
```

### Rule 2: Develop Branch (Staging)

**Pattern**: `develop`

**Configuration**:

```yaml
# 1. Pull Request Requirements
Require a pull request before merging:
  ✅ Enabled
  
Require approvals:
  ✅ Number of approvals required: 1
  ✅ Dismiss stale pull request approvals when new commits are pushed: YES
  ✅ Require review from Code Owners: YES

# 2. Status Checks
Require status checks to pass before merging:
  ✅ Enabled
  ✅ Require branches to be up to date before merging: YES
  
Required status checks:
  • lint-and-quality
  • backend-tests
  • security-scan
  • build-check
  • branch-validation

# 3. Code Review Requirements
Require conversation resolution before merging:
  ✅ Enabled

# 4. Automatic Merge
Allow auto-merge:
  ✅ Enabled (Allow squash merging for clean history)

# 5. Bypass Rules
Do not allow bypassing the above settings:
  ✅ Enabled
```

### Rule 3: Release Branches

**Pattern**: `release/*`

**Configuration**:

```yaml
# 1. Pull Request Requirements
Require a pull request before merging:
  ✅ Enabled
  
Require approvals:
  ✅ Number of approvals required: 1

# 2. Status Checks
Require status checks to pass before merging:
  ✅ Enabled
  
Required status checks:
  • lint-and-quality
  • backend-tests
  • security-scan
  • build-check

# 3. Automatic Merge
Allow auto-merge:
  ✅ Enabled (Allow squash merging)

# 4. Dismiss approvals
Dismiss stale pull request approvals:
  ✅ Enabled
```

### Rule 4: Feature Branches

**Pattern**: `feature/*`

**Configuration**:

```yaml
# Minimal restrictions - allow faster development iteration
# Status checks still required but no approval requirement

Require status checks to pass before merging:
  ✅ Enabled
  
Required status checks:
  • lint-and-quality
  • backend-tests
```

### Rule 5: Hotfix Branches

**Pattern**: `hotfix/*`

**Configuration**:

```yaml
# Quick deployment for critical fixes

Require a pull request before merging:
  ✅ Enabled
  
Require approvals:
  ✅ Number of approvals required: 1

Require status checks to pass before merging:
  ✅ Enabled
  
Required status checks:
  • lint-and-quality
  • backend-tests
  • security-scan

Allow auto-merge:
  ✅ Enabled (Squash merging)
```

---

## 🌍 Part 3: Environments Configuration

Navigate to: **Settings → Environments**

### Production Environment

**Purpose**: Controlled deployment to production with approval gates

```yaml
Environment Name: production

Deployment branches and tags:
  ✅ Selected branches: main
  
Deployment protection rules:
  ✅ Required reviewers: 
     - @ops-team
     - @tech-lead
     - @platform-team
  
  ✅ Wait timer: 5 minutes
     (Additional safety window before production deploy)

Secrets:
  PROD_DATABASE_URL
  PROD_API_KEYS
  PROD_ENCRYPTION_KEY
  PROD_MONITORING_WEBHOOK
  
  Note: Use environment-specific secrets instead of repository secrets
        for better security isolation
```

### Staging Environment

**Purpose**: Pre-production testing with minimal restrictions

```yaml
Environment Name: staging

Deployment branches and tags:
  ✅ Selected branches: develop
  
Deployment protection rules:
  ✅ Required reviewers: @qa-team (optional)
  
  ✅ Wait timer: 0 minutes
     (Fast iteration for testing)

Secrets:
  STAGING_DATABASE_URL
  STAGING_API_KEYS
  STAGING_ENCRYPTION_KEY
```

---

## ⚙️ Part 4: GitHub Actions Global Settings

Navigate to: **Settings → Actions → General**

### Actions Permissions

```yaml
Actions permissions:
  ✅ Allow all actions and reusable workflows
     (Recommended: Enterprise uses pre-approved actions)

Forked pull request workflows:
  ✅ Require approval for all outside collaborators
     (Security: Prevents malicious workflows from external PRs)

Workflow permissions:
  ✅ Read and write permissions
  ✅ Allow GitHub Actions to create and approve pull requests
```

### Artifact & Log Settings

```yaml
Artifact retention:
  ✅ Retention days: 90 (Balance between cost and auditability)

Log retention:
  ✅ Retention days: 90 (Required for compliance)

Fork pull request workflows from private repositories:
  ✅ Run workflows from fork pull requests: YES
```

---

## 👥 Part 5: CODEOWNERS Configuration

Create file: [.github/CODEOWNERS](.github/CODEOWNERS)

```
# ============================================================================
# CODEOWNERS - Automatic Code Review Assignment
# ============================================================================
# When files matching these patterns are changed, the listed owners
# are automatically requested as reviewers on pull requests.
#
# Format: <file-pattern> <@owner1> <@owner2>
# ============================================================================

# Global default owners
* @backend-team @platform-team

# ============================================================================
# Backend Services
# ============================================================================
/backend/ @backend-team
/backend/src/services/ @backend-team @security-team
/backend/src/routes/ @backend-team
/backend/migrations/ @backend-team @devops-team

# ============================================================================
# Infrastructure & DevOps
# ============================================================================
/infra/ @platform-team @devops-team
/terraform/ @platform-team @ops-team
/.github/workflows/ @platform-team @devops-team
/docker-compose.yml @platform-team

# ============================================================================
# Mobile Applications
# ============================================================================
/ios/ @ios-team
/android/ @android-team
/app/ @mobile-team

# ============================================================================
# Security & Core
# ============================================================================
/security/ @security-team
/auth/ @security-team @backend-team
*.jks @security-team
*.p12 @security-team
*.keystore @security-team

# ============================================================================
# Documentation
# ============================================================================
/docs/ @documentation-team
*.md @documentation-team
README.md @technical-lead @documentation-team

# ============================================================================
# GitHub Configuration
# ============================================================================
.github/ @platform-team @devops-team
.gitignore @platform-team
.gitattributes @platform-team

# ============================================================================
# Configuration Files
# ============================================================================
docker-compose.yml @devops-team
Dockerfile @devops-team
package.json @backend-team @platform-team
*.env.* @security-team

# ============================================================================
# CI/CD & Build
# ============================================================================
.github/workflows/ @platform-team @devops-team
.github/scripts/ @platform-team
Makefile @platform-team
build.gradle* @android-team
Podfile @ios-team
```

**How to Use**:
- GitHub automatically adds owners as reviewers when their files change
- Team members must approve before merging
- Use `@` mentions for GitHub teams or users
- Multiple owners can be specified (space-separated)
- More specific patterns override general ones

---

## 🔔 Part 6: Slack Notifications Setup

### Step 1: Create Slack Webhooks

In your Slack workspace:

1. Go to **Your Workspace → Settings & administration → Manage apps**
2. Search for "Incoming Webhooks"
3. Create new webhook for **#deployments** channel
   - Copy webhook URL → Add to GitHub as `SLACK_WEBHOOK`
4. Create new webhook for **#prod-deployments** channel (restricted access)
   - Copy webhook URL → Add to GitHub as `SLACK_WEBHOOK_PROD`

### Step 2: Add to GitHub Secrets

```
SLACK_WEBHOOK
Description: Webhook for staging/general notifications
Used by: 
  - 02-aws-deploy-staging.yml
  - 05-aws-ecs-deploy.yml
  - 01-aws-rds-migrations.yml

SLACK_WEBHOOK_PROD
Description: Webhook for production notifications (separate channel for compliance)
Used by:
  - 03-aws-deploy-production.yml
```

### Step 3: Notification Messages

Workflows automatically send:

**On Deployment Success**:
```
✅ Deployment: <APP_NAME> to <ENVIRONMENT>
📦 Version: <COMMIT_SHA>
👤 Author: <COMMIT_AUTHOR>
📝 Message: <COMMIT_MESSAGE>
🔗 Link: <DEPLOYMENT_LINK>
```

**On Deployment Failure**:
```
❌ Deployment Failed: <APP_NAME> to <ENVIRONMENT>
📦 Version: <COMMIT_SHA>
👤 Author: <COMMIT_AUTHOR>
⚠️ Error: <FAILURE_REASON>
🔗 Link: <WORKFLOW_RUN_LINK>
```

---

## 🔒 Part 7: AWS Secrets Manager Configuration (RDS & Database Credentials)

**Why AWS Secrets Manager?**: Database credentials should NOT be stored in GitHub. Use AWS Secrets Manager for:
- Centralized credential management
- Automatic rotation without code changes
- Audit logging via CloudTrail
- Encryption with AWS KMS
- Fine-grained IAM access control

### Step 1: Create Secrets in AWS Secrets Manager

```bash
# Set variables
ACCOUNT_ID="123456789012"
AWS_REGION="us-east-1"

# Create secret for Staging RDS credentials
aws secretsmanager create-secret \
  --name rupaya/rds/staging \
  --description "RDS staging database credentials" \
  --secret-string '{
    "username": "rupaya_staging_user",
    "password": "GenerateSecurePassword123!",
    "engine": "postgres",
    "host": "rupaya-staging.xxx.us-east-1.rds.amazonaws.com",
    "port": 5432,
    "dbname": "rupaya"
  }' \
  --region $AWS_REGION

# Create secret for Production RDS credentials
aws secretsmanager create-secret \
  --name rupaya/rds/production \
  --description "RDS production database credentials" \
  --secret-string '{
    "username": "rupaya_prod_user",
    "password": "GenerateSecurePassword456!",
    "engine": "postgres",
    "host": "rupaya-prod.xxx.us-east-1.rds.amazonaws.com",
    "port": 5432,
    "dbname": "rupaya"
  }' \
  --region $AWS_REGION

# Verify secrets created
aws secretsmanager list-secrets --region $AWS_REGION
```

### Step 2: Grant IAM Role Permission to Access Secrets Manager

```bash
cat > /tmp/secrets-manager-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": [
        "arn:aws:secretsmanager:us-east-1:123456789012:secret:rupaya/rds/staging*",
        "arn:aws:secretsmanager:us-east-1:123456789012:secret:rupaya/rds/production*"
      ]
    }
  ]
}
EOF

# Attach policy to staging role
aws iam put-role-policy \
  --role-name GitHubActionsRoleStaging \
  --policy-name SecretsManagerAccess \
  --policy-document file:///tmp/secrets-manager-policy.json

# Attach policy to production role
aws iam put-role-policy \
  --role-name GitHubActionsRoleProd \
  --policy-name SecretsManagerAccess \
  --policy-document file:///tmp/secrets-manager-policy.json
```

### Step 3: Update Workflows to Retrieve Secrets from AWS Secrets Manager

**Example workflow step** (replace hardcoded credentials):

```yaml
# OLD WAY (DON'T DO THIS)
env:
  DB_USER: ${{ secrets.RDS_STAGING_USER }}
  DB_PASSWORD: ${{ secrets.RDS_STAGING_PASSWORD }}

# NEW WAY (AWS Secrets Manager)
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          role-to-assume: ${{ secrets.AWS_OIDC_ROLE_STAGING }}
          aws-region: us-east-1

      - name: Get RDS credentials from Secrets Manager
        run: |
          SECRET=$(aws secretsmanager get-secret-value \
            --secret-id rupaya/rds/staging \
            --query SecretString \
            --output text)
          
          # Parse JSON and set environment variables
          DB_USER=$(echo $SECRET | jq -r '.username')
          DB_PASSWORD=$(echo $SECRET | jq -r '.password')
          DB_HOST=$(echo $SECRET | jq -r '.host')
          DB_PORT=$(echo $SECRET | jq -r '.port')
          DB_NAME=$(echo $SECRET | jq -r '.dbname')
          
          # Export for subsequent steps
          echo "DB_USER=$DB_USER" >> $GITHUB_ENV
          echo "DB_PASSWORD=$DB_PASSWORD" >> $GITHUB_ENV
          echo "DB_HOST=$DB_HOST" >> $GITHUB_ENV
          echo "DB_PORT=$DB_PORT" >> $GITHUB_ENV
          echo "DB_NAME=$DB_NAME" >> $GITHUB_ENV

      - name: Run database migrations
        run: |
          npm run migrate
```

### Step 4: Set Up Automatic Secret Rotation (Optional but Recommended)

```bash
# Enable automatic rotation for staging secret
aws secretsmanager rotate-secret \
  --secret-id rupaya/rds/staging \
  --rotation-rules AutomaticallyAfterDays=30 \
  --region us-east-1

# Enable automatic rotation for production secret
aws secretsmanager rotate-secret \
  --secret-id rupaya/rds/production \
  --rotation-rules AutomaticallyAfterDays=90 \
  --region us-east-1
```

### Step 5: Monitor Secret Access (CloudTrail)

```bash
# View all secret access in CloudTrail
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=ResourceName,AttributeValue=rupaya/rds/staging \
  --region us-east-1

# Example output shows:
# - Who accessed the secret (GitHub OIDC)
# - When (timestamp)
# - What action (GetSecretValue)
# - Success/failure
```

---

## 🔒 Part 8: AWS OIDC Configuration

**Why OIDC?**: Eliminates need to store long-lived AWS access keys in GitHub secrets. More secure and follows industry best practices.

### Step 1: Create IAM OIDC Provider

```bash
# Set your AWS account ID
ACCOUNT_ID="123456789012"

# Create OIDC provider
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
  --region us-east-1
```

**Output**: Note the OIDC Provider ARN (e.g., `arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com`)

### Step 2: Create IAM Role for GitHub Actions

```bash
cat > /tmp/trust-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "repo:YOUR_GITHUB_ORG/rupaya:ref:refs/heads/develop"
        }
      }
    }
  ]
}
EOF

# Create role
aws iam create-role \
  --role-name GitHubActionsRoleStaging \
  --assume-role-policy-document file:///tmp/trust-policy.json
```

### Step 3: Attach Policies to Role

```bash
# For staging deployments
aws iam attach-role-policy \
  --role-name GitHubActionsRoleStaging \
  --policy-arn arn:aws:iam::aws:policy/EC2ContainerRegistryPowerUser

aws iam attach-role-policy \
  --role-name GitHubActionsRoleStaging \
  --policy-arn arn:aws:iam::aws:policy/AmazonECS_FullAccess

aws iam attach-role-policy \
  --role-name GitHubActionsRoleStaging \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess

# Create production role with more restrictions
aws iam create-role \
  --role-name GitHubActionsRoleProd \
  --assume-role-policy-document file:///tmp/trust-policy.json
```

### Step 4: Add Role ARN to GitHub Secrets

```
AWS_OIDC_ROLE_STAGING
Value: arn:aws:iam::123456789012:role/GitHubActionsRoleStaging

AWS_OIDC_ROLE_PROD
Value: arn:aws:iam::123456789012:role/GitHubActionsRoleProd
```

---

## 🔒 Part 9: GCP Workload Identity Setup

**Why Workload Identity?**: Eliminates need for service account keys. Uses OpenID Connect tokens.

### Step 1: Create Workload Identity Pool

```bash
export PROJECT_ID="your-gcp-project"
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')

# Create workload identity pool
gcloud iam workload-identity-pools create "github-pool" \
  --project="$PROJECT_ID" \
  --location="global" \
  --display-name="GitHub Actions"
```

### Step 2: Create OIDC Provider

```bash
# Create provider
gcloud iam workload-identity-pools providers create-oidc "github-provider" \
  --project="$PROJECT_ID" \
  --location="global" \
  --workload-identity-pool="github-pool" \
  --display-name="GitHub Provider" \
  --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner" \
  --issuer-uri="https://token.actions.githubusercontent.com" \
  --attribute-condition="assertion.aud == 'sts.googleapis.com'"
```

### Step 3: Create Service Account

```bash
# Create service account for GitHub Actions
gcloud iam service-accounts create github-actions \
  --project="$PROJECT_ID" \
  --display-name="GitHub Actions"

# Grant permissions (example: Cloud Run deployer)
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/run.admin"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"
```

### Step 4: Create Workload Identity Binding

```bash
# Get workload identity pool resource name
WORKLOAD_IDENTITY_PROVIDER="projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/github-pool/providers/github-provider"

# Grant service account access to GitHub Actions
gcloud iam service-accounts add-iam-policy-binding \
  "github-actions@$PROJECT_ID.iam.gserviceaccount.com" \
  --project="$PROJECT_ID" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/github-pool/attribute.repository/YOUR_GITHUB_ORG/rupaya"
```

### Step 5: Add to GitHub Secrets

```
GCP_PROJECT_ID
Value: your-gcp-project

GCP_WORKLOAD_IDENTITY_PROVIDER
Value: projects/<PROJECT_NUMBER>/locations/global/workloadIdentityPools/github-pool/providers/github-provider

GCP_SERVICE_ACCOUNT_EMAIL
Value: github-actions@your-gcp-project.iam.gserviceaccount.com
```

---

## ✅ Part 10: Verification Checklist

### 1. Verify Secrets Configuration

```bash
# List all repository secrets
gh secret list

# Expected output should include:
# - AWS_OIDC_ROLE_ARN
# - AWS_OIDC_ROLE_STAGING
# - AWS_OIDC_ROLE_PROD
# - GCP_PROJECT_ID
# - GCP_WORKLOAD_IDENTITY_PROVIDER
# - GCP_SERVICE_ACCOUNT_EMAIL
# - SLACK_WEBHOOK
# - SLACK_WEBHOOK_PROD
# - And all mobile/testing secrets
```

### 2. Verify Branch Protection Rules

```bash
# Check main branch protection
gh api repos/YOUR_ORG/rupaya/branches/main/protection

# Check develop branch protection
gh api repos/YOUR_ORG/rupaya/branches/develop/protection

# Verify required status checks
gh api repos/YOUR_ORG/rupaya/branches/main/protection \
  --jq '.required_status_checks.contexts'
```

### 3. Test Feature Branch Workflow

```bash
# Create a test feature branch
git checkout -b feature/test-ci-setup
echo "# Test CI Setup" >> README.md
git add README.md
git commit -m "test: verify CI workflows"
git push -u origin feature/test-ci-setup

# Verify:
# ✅ GitHub Actions workflows trigger automatically
# ✅ Lint-and-quality job runs
# ✅ Backend tests job runs
# ✅ Security scan job runs
# ✅ Build check job runs
# ✅ All checks appear in commit status
```

### 4. Test Pull Request Requirements

```bash
# Visit PR on GitHub and verify:
# ✅ Required status checks show as pending
# ✅ Approval requirement is enforced
# ✅ "Merge" button is disabled until checks pass + approval

# Try to merge without approval:
# ❌ Button should be disabled with message:
#    "This branch has 1 of 2 required status checks pending"
```

### 5. Test Main Branch Protection (with caution)

```bash
# ⚠️ WARNING: Only test with a test PR, don't force push to main

# Create PR to main
git checkout -b test/test-main-protection
echo "# Test" >> README.md
git commit -am "test"
git push -u origin test/test-main-protection

# On GitHub, create PR to main and verify:
# ✅ Requires 2 approvals
# ✅ Requires all status checks to pass
# ✅ Dismiss stale approvals is enabled
# ✅ Cannot merge without both conditions met
```

### 6. Test Slack Notifications

```bash
# Push to develop to trigger staging deployment
git checkout develop
git pull origin develop
echo "# Test notification" >> README.md
git commit -am "test: slack notification"
git push origin develop

# Wait for workflows to complete
# ✅ Should receive Slack notification in #deployments
# ✅ Message includes version, author, environment
```

### 7. Verify Workflow Permissions

```bash
# Check workflow permissions for the repository
gh api repos/YOUR_ORG/rupaya/actions/permissions

# Expected output should show:
# - "read_write_permissions": true
# - "can_approve_pull_requests": true
```

### 8. Test OIDC Authentication (AWS)

```bash
# Run a test deployment to staging
git checkout develop
git commit --allow-empty -m "test: AWS OIDC authentication"
git push origin develop

# Verify in workflow logs:
# ✅ OIDC token is obtained from GitHub
# ✅ AWS role assumption succeeds (no access key errors)
# ✅ AWS CLI commands execute without credentials
```

### 9. Test OIDC Authentication (GCP)

```bash
# For GCP workflows, verify in logs:
# ✅ Workload identity token is obtained
# ✅ gcloud authentication succeeds
# ✅ gcloud CLI commands work without service account key
```

### 10. Test Environment Protection Rules

```bash
# Attempt to deploy to production
git checkout main
git commit --allow-empty -m "test: production deployment protection"
git push origin main

# Verify on GitHub:
# ✅ Workflow waits for required reviewers to approve
# ✅ Shows "Waiting for approvals from: @ops-team"
# ✅ Deployment does not proceed until approval given
```

---

## 🚀 Part 11: Deployment Workflow Guide

### Feature Branch Development

```
1. Developer creates feature branch from develop
   git checkout -b feature/my-feature develop

2. Push code to GitHub
   git push -u origin feature/my-feature

3. Automatic workflow execution:
   ✅ Lint and code quality checks
   ✅ Unit tests
   ✅ Security scans
   ✅ Build verification
   ✅ All checks must pass

4. Create Pull Request to develop branch
   - Can be done via GitHub UI or CLI

5. Code review process:
   - CODEOWNERS automatically requested as reviewers
   - Must have 1 approval to merge
   - All status checks must pass
   - Cannot merge until requirements met

6. Merge to develop
   git merge feature/my-feature

7. Automatic staging deployment:
   ✅ Deploy to staging environment
   ✅ Run smoke tests
   ✅ Send Slack notification to #deployments
```

### Release to Production

```
1. Create release branch from develop
   git checkout -b release/1.2.0 develop

2. Update version numbers
   - Update package.json, build.gradle, etc.
   - Commit: git commit -am "chore: bump version to 1.2.0"

3. Push release branch
   git push -u origin release/1.2.0

4. Create Pull Request to main branch
   - Title: "Release: 1.2.0"
   - Wait for all checks to pass

5. Code review (requires 2 approvals)
   - @tech-lead reviews
   - @ops-team reviews
   - Both must approve

6. Merge to main
   - Requires 2 approvals (enforced by branch protection)
   - All status checks must pass

7. Automatic production deployment:
   ✅ Deployment waits for environment reviewers
   ✅ @ops-team must approve production deployment
   ✅ 5-minute wait timer for additional safety
   ✅ Deploy to production
   ✅ Send Slack notification to #prod-deployments
   ✅ Notify @ops-team of successful deployment
```

### Hotfix to Production

```
1. Create hotfix branch from main
   git checkout -b hotfix/critical-fix main

2. Implement fix
   git commit -am "fix: critical security issue"

3. Push hotfix branch
   git push -u origin hotfix/critical-fix

4. Create Pull Request to main
   - Requires only 1 approval (faster)
   - All status checks still required
   - Security scan still required

5. Get approval and merge
   git checkout main
   git pull origin main
   git merge hotfix/critical-fix

6. Automatic production deployment:
   ✅ Fast-tracked deployment
   ✅ Still requires environment approval
   ✅ Deploy to production immediately

7. Backport to develop
   git checkout develop
   git pull origin develop
   git cherry-pick hotfix/critical-fix
   git push origin develop
```

---

## 🎯 Part 12: Result - Zero-Touch CI/CD Pipeline

Once all configurations are complete, your pipeline operates as follows:

### Automatic Actions (No Manual Intervention Needed)

```
✅ Feature Branch (feature/*)
   - Push code → Workflows run automatically
   - Tests run → Results show in commit status
   - Security scans → Results show in commit status
   - Cannot merge without passing checks

✅ Merge to Develop
   - Automatic deployment to staging
   - Smoke tests run automatically
   - Slack notification sent automatically
   - Deployment URL provided in Slack

✅ Merge to Main
   - Automatic deployment to production
   - Environment reviewers notified
   - Wait timer enforced automatically
   - Slack notification sent automatically
   - Team notified in #prod-deployments

✅ Mobile Builds
   - Automatic iOS build on every commit
   - Automatic Android build on every commit
   - Automatic TestFlight distribution
   - Automatic Google Play distribution (with approval)
```

### Required Manual Approvals (Minimized)

```
⚠️ Pull Request to Main (2 approvals)
   - Enforced by branch protection
   - Usually completed within 30 minutes during business hours

⚠️ Production Deployment (ops-team approval)
   - Enforced by environment protection
   - Must approve deployment before production release
   - Can be approved within GitHub UI

⚠️ Mobile App Store Releases (manual review optional)
   - iOS TestFlight distribution happens automatically
   - Google Play release can be manual after review
```

### Monitoring & Notifications

```
📊 Real-time Feedback
   - GitHub commit status shows check progress
   - Slack notifications provide deployment updates
   - Email notifications for failed workflows (optional)

🔍 Auditability
   - All deployments logged in GitHub Actions
   - Deployment approval chain recorded
   - Commit history shows all changes
   - Can trace every production change to a PR

🚨 Alerts
   - Failed workflow: Slack notification
   - Deployment failure: Slack notification
   - Security vulnerability: Slack + email
```

---

## 📊 Summary Table: All Required Configurations

| Component | Location | Required Secrets | Actions |
|-----------|----------|------------------|---------|
| **AWS Deployments** | Settings → Secrets | AWS_OIDC_ROLE_ARN, AWS_OIDC_ROLE_STAGING, AWS_OIDC_ROLE_PROD | 6 workflows |
| **GCP Deployments** | Settings → Secrets | GCP_PROJECT_ID, GCP_WORKLOAD_IDENTITY_PROVIDER, GCP_SERVICE_ACCOUNT_EMAIL | 4 workflows |
| **Mobile Builds** | Settings → Secrets | IOS_*, ANDROID_*, GOOGLE_PLAY_* | 2 workflows |
| **Notifications** | Settings → Secrets | SLACK_WEBHOOK, SLACK_WEBHOOK_PROD | All workflows |
| **Database** | AWS Secrets Manager | RDS credentials in Secrets Manager (NOT GitHub) | Migration workflow |
| **Main Branch** | Settings → Branches | N/A | 2 approvals, 5 checks required |
| **Develop Branch** | Settings → Branches | N/A | 1 approval, 5 checks required |
| **Environments** | Settings → Environments | Environment-specific secrets | Deployment gates |
| **CODEOWNERS** | .github/CODEOWNERS | N/A | Auto-assign reviewers |
| **GitHub Actions** | Settings → Actions | N/A | Enable read/write permissions |

---

## 🔗 Quick Reference Links

- [GitHub Branch Protection Docs](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)
- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [AWS OIDC Configuration](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
- [GCP Workload Identity](https://cloud.google.com/docs/authentication/workload-identity-federation)
- [CODEOWNERS Documentation](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners)
- [GitHub Environments](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment)

---

## ✨ Next Steps

1. **Complete Setup**: Follow this guide step-by-step
2. **Test Configuration**: Use the verification checklist
3. **Train Team**: Share deployment workflow guide with team
4. **Monitor**: Check Slack notifications and GitHub Actions logs
5. **Iterate**: Adjust settings based on team feedback

**Estimated Setup Time**: 2-3 hours  
**Team Ready Time**: After first successful deployment  
**Support**: Refer to troubleshooting section or GitHub documentation

---

**Document Version**: 1.0  
**Last Updated**: February 5, 2026  
**Maintained By**: Platform/DevOps Team  
**Status**: Ready for Implementation
