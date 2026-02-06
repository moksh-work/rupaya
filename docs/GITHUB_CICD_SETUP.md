# GitHub CI/CD Configuration Guide

This guide walks through setting up GitHub Actions with AWS IAM role assumption using OIDC for secure Terraform deployments.

## Prerequisites

- GitHub repository with admin access
- AWS account with appropriate permissions
- Terraform state management infrastructure deployed (✅ Complete)

## Step 1: Create GitHub OIDC Provider in AWS

Run the following commands to set up OIDC trust for GitHub:

```bash
# Create OIDC provider (one-time setup per AWS account)
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
  2>/dev/null || echo "OIDC provider already exists"

# Verify it was created
aws iam list-open-id-connect-providers
```

Expected output:
```
OpenIDConnectProviderList:
  - Arn: arn:aws:iam::767397779454:oidc-provider/token.actions.githubusercontent.com
```

## Step 2: Create/Update IAM Role Trust Policy for GitHub Actions

Update the Terraform CI/CD role to trust GitHub OIDC:

```bash
# Get your GitHub org/repo info:
GITHUB_ORG="rsingh"           # Your GitHub username
GITHUB_REPO="rupaya"          # Your repository name

# Create trust policy JSON
cat > /tmp/trust-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::767397779454:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:rsingh/rupaya:ref:refs/heads/main"
        }
      }
    }
  ]
}
EOF

# Update the role trust policy
aws iam update-assume-role-policy \
  --role-name rupaya-terraform-cicd \
  --policy-document file:///tmp/trust-policy.json
```

## Step 3: Add GitHub Repository Secrets

These secrets will be used by GitHub Actions to deploy infrastructure.

**Via GitHub UI:**
1. Go to: `Settings → Secrets and variables → Actions`
2. Click "New repository secret" and add each:

| Secret Name | Value | Description |
|-------------|-------|-------------|
| `AWS_ACCOUNT_ID` | `767397779454` | AWS account ID |
| `AWS_ROLE_NAME` | `rupaya-terraform-cicd` | IAM role name for Terraform |
| `TFSTATE_BUCKET` | `rupaya-terraform-state-767397779454` | S3 bucket for Terraform state |
| `TFSTATE_DYNAMODB_TABLE` | `rupaya-terraform-state-lock` | DynamoDB table for state locking |
| `TFSTATE_KEY` | `prod/infrastructure/terraform.tfstate` | Path to state file in S3 |
| `AWS_REGION` | `us-east-1` | AWS region |

**Via CLI (optional):**
```bash
#!/bin/bash
GITHUB_ORG="rsingh"
GITHUB_REPO="rupaya"

gh secret set AWS_ACCOUNT_ID --body "767397779454" -R "$GITHUB_ORG/$GITHUB_REPO"
gh secret set AWS_ROLE_NAME --body "rupaya-terraform-cicd" -R "$GITHUB_ORG/$GITHUB_REPO"
gh secret set TFSTATE_BUCKET --body "rupaya-terraform-state-767397779454" -R "$GITHUB_ORG/$GITHUB_REPO"
gh secret set TFSTATE_DYNAMODB_TABLE --body "rupaya-terraform-state-lock" -R "$GITHUB_ORG/$GITHUB_REPO"
gh secret set TFSTATE_KEY --body "prod/infrastructure/terraform.tfstate" -R "$GITHUB_ORG/$GITHUB_REPO"
gh secret set AWS_REGION --body "us-east-1" -R "$GITHUB_ORG/$GITHUB_REPO"
```

## Step 4: Verify Workflow Configuration

Check that `.github/workflows/terraform-staged-deploy.yml` exists and has correct environment variables:

```yaml
env:
  AWS_REGION: us-east-1
  TFSTATE_BUCKET: rupaya-terraform-state-767397779454
  TFSTATE_DYNAMODB_TABLE: rupaya-terraform-state-lock
  TFSTATE_KEY: prod/infrastructure/terraform.tfstate
```

The workflow uses:
```yaml
- uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::${{ secrets.AWS_ACCOUNT_ID }}:role/${{ secrets.AWS_ROLE_NAME }}
    aws-region: ${{ secrets.AWS_REGION }}
```

## Step 5: Test the Workflow

### Option A: Trigger via Pull Request
```bash
# Make a small change to test (e.g., update a tag)
cd /Users/rsingh/Documents/Projects/rupaya/infra/aws
vi main.tf  # Add a comment or update a tag

git add .
git commit -m "test: trigger terraform workflow"
git push origin feature/test-workflow
# Create PR on GitHub
```

### Option B: Trigger via Workflow Dispatch
```bash
# Direct trigger (requires gh CLI)
gh workflow run terraform-staged-deploy.yml -R rsingh/rupaya
```

### Option C: Check Workflow Status
```bash
# List recent workflow runs
gh run list -R rsingh/rupaya --workflow=terraform-staged-deploy.yml -L 5

# Watch a specific run (replace RUN_ID)
gh run watch RUN_ID -R rsingh/rupaya
```

## Step 6: Monitor Deployment

The workflow has two stages:

**Stage 1: Certificates**
- Deploys ACM certificates and waits for issuance
- Timeout: 30 minutes
- Runs automatically

**Stage 2: Infrastructure**
- Deploys all other AWS resources
- Requires manual approval in production
- Triggered by pull request or manual dispatch

View logs:
1. Go to: `Actions → Terraform Staged Deploy`
2. Click on the latest run
3. Expand each job to see detailed logs

## Troubleshooting

### "Role does not exist" Error
```
Error: InvalidClientTokenId
  status code: 401
```

**Fix:** Ensure IAM role trust policy was updated with OIDC conditions.

```bash
aws iam get-role --role-name rupaya-terraform-cicd
aws iam get-role-policy --role-name rupaya-terraform-cicd --policy-name rupaya-terraform-backend-access
```

### "Access Denied" on S3 State
```
Error: AccessDenied: Access Denied
```

**Fix:** Ensure the CICD role has permission to access S3 and DynamoDB:

```bash
aws iam list-role-policies --role-name rupaya-terraform-cicd
aws iam get-role-policy --role-name rupaya-terraform-cicd \
  --policy-name rupaya-terraform-backend-access
```

### State Lock Issues
```
Error: Error acquiring the state lock
```

**Fix:** Check DynamoDB lock table:

```bash
# List locks
aws dynamodb scan --table-name rupaya-terraform-state-lock

# Force remove lock (use with caution!)
aws dynamodb delete-item \
  --table-name rupaya-terraform-state-lock \
  --key '{"LockID": {"S": "rupaya-terraform-state-767397779454/prod/infrastructure/terraform.tfstate"}}'
```

## Security Best Practices

✅ **Implemented:**
- OIDC for keyless authentication (no long-lived AWS credentials)
- External ID validation in trust policy
- S3 bucket encryption (KMS)
- State locking (DynamoDB)
- Access logging (CloudTrail)
- Versioning (disaster recovery)

⚠️ **Recommended Next Steps:**
- Enable MFA Delete on production S3 bucket
- Add GitHub CODEOWNERS for approval gates
- Set up Terraform Cloud notifications
- Implement drift detection automation

## Reference

**AWS Resources:**
- OIDC Provider: `arn:aws:iam::767397779454:oidc-provider/token.actions.githubusercontent.com`
- IAM Role: `rupaya-terraform-cicd`
- S3 Bucket: `rupaya-terraform-state-767397779454`
- DynamoDB Table: `rupaya-terraform-state-lock`
- Region: `us-east-1`

**GitHub Workflow:**
- File: `.github/workflows/terraform-staged-deploy.yml`
- Trigger: Push to main, pull requests
- Approval: Required for production stage

---

**Status:** Ready for CI/CD deployment ✅
