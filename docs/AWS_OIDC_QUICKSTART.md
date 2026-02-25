# AWS OIDC Setup Quickstart

> **Goal:** Enable GitHub Actions to deploy to AWS without storing any credentials in the repo.

---

## Quick Checklist (5 Steps, ~10 Minutes)

### Step 1: Substitute Your GitHub Organization

In `infra/aws/terraform/aws-oidc-role.tf`, update:

```hcl
variable "github_org" {
  # Change this to your actual GitHub org
  type        = string
  # ↓ EXAMPLE: "mycompany" or "your-username"
  default     = "YOUR_GITHUB_ORG"
}
```

Also in `docs/AWS_OIDC_SETUP.md`, replace **all instances** of `YOUR_GITHUB_ORG` with your actual GitHub organization.

### Step 2: Deploy IAM OIDC Role with Terraform

```bash
cd infra/aws/terraform

# Verify your GitHub org is set
cat aws-oidc-role.tf | grep "github_org ="

# Plan OIDC resources
terraform plan \
  -target=aws_iam_openid_connect_provider.github \
  -target=aws_iam_role.github_oidc \
  -target=aws_iam_role_policy.github_oidc_inline \
  -var="github_org=YOUR_GITHUB_ORG"

# Apply (creates OIDC provider + role in AWS)
terraform apply \
  -target=aws_iam_openid_connect_provider.github \
  -target=aws_iam_role.github_oidc \
  -target=aws_iam_role_policy.github_oidc_inline \
  -var="github_org=YOUR_GITHUB_ORG"

# Copy the role ARN from output
OIDC_ROLE_ARN=$(terraform output -raw github_oidc_role_arn)
echo "Role ARN: $OIDC_ROLE_ARN"
```

**Output:**
```
Outputs:

github_oidc_role_arn = "arn:aws:iam::123456789012:role/rupaya-github-oidc"
```

Save this ARN—you'll need it in Step 3.

### Step 3: Create GitHub Repository Secret

1. Go to **GitHub → Your Repo → Settings → Secrets and variables → Actions**
2. Click **New repository secret**
3. **Name:** `AWS_OIDC_ROLE_ARN`
4. **Value:** Paste the ARN from Step 2 (e.g., `arn:aws:iam::123456789012:role/rupaya-github-oidc`)
5. Click **Add secret**

✅ **Done!** This secret is not sensitive (it's a role ARN), but keeps your repo clean.

### Step 4: Create GitHub Environments

Go to **Settings → Environments** and create three environments:

#### 4a. Development Environment
1. Click **New environment → `development`**
2. Add these **variables** (these are NOT secrets):
   ```
   DEV_ECS_CLUSTER=rupaya-dev-cluster
   DEV_ECS_SERVICE=rupaya-backend-dev
   DEV_ECS_TASK_FAMILY=rupaya-backend-dev
   DEV_API_BASE_URL=https://api-dev.rupaya.io
   DEV_DOCKER_REGISTRY=123456789012.dkr.ecr.us-east-1.amazonaws.com
   AWS_REGION=us-east-1
   ```

#### 4b. Staging Environment
1. Click **New environment → `staging`**
2. Add these **variables**:
   ```
   STAGING_ECS_CLUSTER=rupaya-staging-cluster
   STAGING_ECS_SERVICE=rupaya-backend-staging
   STAGING_ECS_TASK_FAMILY=rupaya-backend-staging
   STAGING_API_BASE_URL=https://api-staging.rupaya.io
   STAGING_DOCKER_REGISTRY=123456789012.dkr.ecr.us-east-1.amazonaws.com
   AWS_REGION=us-east-1
   ```
3. (Optional) **Required reviewers:** Add team members to mandate approval before deploy

#### 4c. Production Environment
1. Click **New environment → `production`**
2. Add these **variables**:
   ```
   PROD_ECS_CLUSTER=rupaya-prod-cluster
   PROD_ECS_SERVICE=rupaya-backend-prod
   PROD_ECS_TASK_FAMILY=rupaya-backend-prod
   PROD_API_BASE_URL=https://api.rupaya.io
   PROD_DOCKER_REGISTRY=123456789012.dkr.ecr.us-east-1.amazonaws.com
   AWS_REGION=us-east-1
   ```
3. **Required reviewers:** Add team leads (mandatory approval before production deploy)
4. **Deployment branches:** Restrict to `main` only

**Note:** Replace placeholder values with your actual AWS account ID, domain names, and service names.

### Step 5: Test OIDC Authentication

1. Go to **GitHub → Actions → Workflows → "Test OIDC Authentication"**
2. Click **Run workflow → Run workflow**
3. Check logs—should see:
   ```
   AWS Identity:
   {
       "UserId": "AIDA...",
       "Account": "123456789012",
       "Arn": "arn:aws:iam::123456789012:assumed-role/rupaya-github-oidc/github-actions"
   }
   
   ✅ OIDC Authentication Successful!
   ```

If you see `assumed-role/rupaya-github-oidc`, **OIDC is working! ✅**

---

## Verification: CloudTrail Audit

Verify GitHub is using OIDC (not hardcoded credentials):

```bash
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=AssumeRole \
  --region us-east-1 \
  --max-results 5 \
  --query 'Events[?contains(CloudTrailEvent, `rupaya-github-oidc`)].{Time:EventTime, Source:CloudTrailEvent}' \
  --output table
```

**Expected:** Event shows `token.actions.githubusercontent.com` as the principal (GitHub's OIDC token), NOT an AWS Access Key.

---

## Next: Deploy Infrastructure & Run CI/CD

Once OIDC is verified:

1. **Provision infrastructure:** Run workflow 09 (Terraform) → creates ECS clusters, RDS, ACM certs
2. **Migrate database:** Run workflow 10 (RDS Migrations) → applies schema
3. **Deploy to dev:** Push to feature branch → workflow 05 (PR) → deploys to dev ECS
4. **Deploy to staging:** Push to release branch → workflow 06 (Release) → deploys to staging ECS
5. **Deploy to prod:** Push to main → workflow 07 (Main) → validates prod readiness

All without any AWS credentials in the repo! ✅

---

## Troubleshooting

| Issue | Cause | Fix |
|-------|-------|-----|
| `AssumeRole Failed` | Trust policy mismatch | Verify `${{ secrets.AWS_OIDC_ROLE_ARN }}` is correct in workflow |
| `AccessDenied` | Role lacks permissions | Check inline policy includes ECR, ECS, S3, RDS actions |
| `Environment not found` | GitHub environment doesn't exist | Create `development`, `staging`, `production` in Settings |
| `Variable not defined` | Environment variable missing | Add `DEV_*`, `STAGING_*`, `PROD_*` vars to respective environments |

For detailed troubleshooting, see [AWS_OIDC_SETUP.md](AWS_OIDC_SETUP.md#troubleshooting).

---

## Security Summary

✅ **What's protected:**
- Zero AWS credentials in GitHub repo
- Short-lived tokens (1 hour expiration)
- CloudTrail audit trail of all assume-role calls
- Branch/environment-based access restrictions
- Automatic credential rotation (GitHub manages token lifecycle)

✅ **What's exposed:**
- Role ARN in `AWS_OIDC_ROLE_ARN` secret (not sensitive—just a role reference)
- Environment variables in `development`, `staging`, `production` environments (not secrets—just config)
- GitHub org/repo name in workflows (already public)

✅ **No exposure:**
- AWS Access Keys ❌ Not stored
- AWS Secret Keys ❌ Not stored
- Account IDs in workflows ❌ Only in env vars
- Database passwords ❌ Fetched from Secrets Manager at runtime
- Docker credentials ❌ Obtained via ECR GetAuthorizationToken

---

**You're ready to deploy! 🚀**

See [AWS_OIDC_SETUP.md](AWS_OIDC_SETUP.md) for detailed reference docs.
