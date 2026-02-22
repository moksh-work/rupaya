# GitHub Actions Secrets Setup

## Overview

The GitHub Actions workflows now use secrets instead of hardcoding AWS account details. This provides:
- ✅ No hardcoded credentials in workflows
- ✅ Easy to update if account changes
- ✅ Single source of truth for configuration
- ✅ Better security and auditability

## Required Secrets

### 1. `AWS_OIDC_ROLE_ARN` (Most Important)
The ARN of the GitHub Actions CI/CD role in AWS.

**Where to get it:**
```bash
cd infra/aws
terraform output github_actions_role_arn
```

Or from AWS console:
```
IAM → Roles → rupaya-terraform-cicd → Copy ARN
```

**Format:**
```
arn:aws:iam::590184132516:role/rupaya-terraform-cicd
```

**How to set in GitHub:**
1. Go to your GitHub repository
2. Settings → Secrets and variables → Actions
3. Click "New repository secret"
4. Name: `AWS_OIDC_ROLE_ARN`
5. Value: Paste the ARN from above
6. Click "Add secret"

### 2. `ECR_REGISTRY` (Optional but Recommended)
The ECR registry URL for Docker image storage.

**Format:**
```
590184132516.dkr.ecr.us-east-1.amazonaws.com
```

**How to set:**
1. Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Name: `ECR_REGISTRY`
4. Value: Your ECR registry URL
5. Click "Add secret"

### 3. `TFSTATE_BUCKET_NAME` (Optional)
The S3 bucket name for Terraform state storage.

**Format:**
```
rupaya-terraform-state-590184132516
```

**How to set:**
1. Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Name: `TFSTATE_BUCKET_NAME`
4. Value: Your terraform state bucket name
5. Click "Add secret"

## Setup Instructions (One-Time)

### Step 1: Generate Terraform Outputs
```bash
cd /Users/rsingh/Documents/Projects/rupaya/infra/aws
terraform output -json
```

This will display:
```json
{
  "github_actions_role_arn": {
    "value": "arn:aws:iam::590184132516:role/rupaya-terraform-cicd"
  },
  "github_oidc_provider_arn": {
    "value": "arn:aws:iam::590184132516:oidc-provider/token.actions.githubusercontent.com"
  },
  "tfstate_bucket": {
    "value": "rupaya-terraform-state-590184132516"
  }
}
```

### Step 2: Create GitHub Repository Secrets

Go to: **Settings → Secrets and variables → Actions**

Create 3 secrets:

| Secret Name | Value | Source |
|------------|-------|--------|
| `AWS_OIDC_ROLE_ARN` | `arn:aws:iam::590184132516:role/rupaya-terraform-cicd` | terraform output |
| `ECR_REGISTRY` | `590184132516.dkr.ecr.us-east-1.amazonaws.com` | AWS ECR console |
| `TFSTATE_BUCKET_NAME` | `rupaya-terraform-state-590184132516` | terraform output |

### Step 3: Verify Secrets Are Set
1. Go to Settings → Secrets and variables → Actions
2. You should see 3 secrets listed
3. All should show checkmark (✓)

## How Workflows Use Secrets

### Example 1: ECS Deploy Workflow
```yaml
- name: Configure AWS credentials via OIDC
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ secrets.AWS_OIDC_ROLE_ARN }}
    aws-region: us-east-1
```

The `${{ secrets.AWS_OIDC_ROLE_ARN }}` is automatically replaced with the secret value at runtime.

### Example 2: Terraform Workflow
```yaml
env:
  TFSTATE_BUCKET: ${{ secrets.TFSTATE_BUCKET_NAME }}
  AWS_ROLE_ARN: ${{ secrets.AWS_OIDC_ROLE_ARN }}
```

### Example 3: Multiple Workflows
All workflows reference the same secrets:
- `08-aws-ecs-deploy.yml`
- `05-common-backend-cicd.yml`
- `06-terraform-infrastructure.yml`
- `09-aws-deploy-staging.yml`
- `10-aws-deploy-production.yml`

## Updating Secrets

If you change AWS accounts or roles in the future:

1. **Update Terraform variables**:
   ```bash
   cd infra/aws
   terraform apply
   ```

2. **Get new values**:
   ```bash
   terraform output github_actions_role_arn
   ```

3. **Update GitHub secrets**:
   - Go to Settings → Secrets and variables → Actions
   - Click on the secret to edit
   - Update the value
   - Click "Update secret"

## Security Best Practices

✅ **Do:**
- Store sensitive values in GitHub secrets
- Use OIDC authentication (no static credentials)
- Rotate secrets periodically
- Use branch protection rules
- Require code reviews before merge
- Monitor secret usage in audit logs

❌ **Don't:**
- Hardcode credentials in workflow files
- Commit secrets to Git repositories
- Share secret values in Slack/email
- Use overly permissive IAM policies
- Store secrets in `terraform.tfvars` file

## Troubleshooting

### Error: "Invalid token"
**Cause:** AWS OIDC role ARN is incorrect or doesn't exist
**Solution:** 
1. Verify the role exists in AWS
2. Check the role ARN is correct
3. Update the `AWS_OIDC_ROLE_ARN` secret

### Error: "AccessDenied" on S3/ECR operations
**Cause:** IAM role doesn't have required permissions
**Solution:**
1. Check the IAM role has correct policies attached
2. Verify TFSTATE_BUCKET_NAME is correct
3. Check ECR registry URL is correct

### Secret not being used in workflow
**Cause:** Secret might not be available to the workflow
**Solution:**
1. Ensure secret name matches exactly (case-sensitive)
2. Verify secret exists in repository (not organization)
3. Check workflow has permission to use secrets
4. Redeploy the workflow

### "Repository secret not found"
**Cause:** Secret name typo or secret doesn't exist
**Solution:**
1. Go to Settings → Secrets and variables → Actions
2. Verify secret exists and name is spelled correctly
3. Check the workflow file for typos in the secret reference

## Verification Steps

After setting up secrets, verify everything works:

### 1. Check Secrets Exist
```bash
# In GitHub Settings → Secrets and variables → Actions
# You should see:
✓ AWS_OIDC_ROLE_ARN
✓ ECR_REGISTRY  
✓ TFSTATE_BUCKET_NAME
```

### 2. Test from Workflow
Push a small change to trigger a workflow:
```bash
git add .
git commit -m "ci: verify secrets are working"
git push origin main
```

### 3. Check Workflow Logs
1. Go to Actions tab in GitHub
2. Click the latest workflow run
3. Expand the "Configure AWS credentials" step
4. Verify it says "✓ Successfully authenticated"

### 4. Verify No Secrets in Logs
1. Expand any step with raw logs
2. Search for "590184132516"
3. You should NOT find the account ID (it's masked)

## Related Files

- [github-oidc.tf](../infra/aws/github-oidc.tf) - OIDC provider and IAM role
- [08-aws-ecs-deploy.yml](../.github/workflows/08-aws-ecs-deploy.yml) - ECS deployment
- [05-common-backend-cicd.yml](../.github/workflows/05-common-backend-cicd.yml) - Backend CI/CD
- [06-terraform-infrastructure.yml](../.github/workflows/06-terraform-infrastructure.yml) - Terraform
- [GITHUB_ACTIONS_SETUP_COMPLETE.md](GITHUB_ACTIONS_SETUP_COMPLETE.md) - Full setup guide

## Summary

By using GitHub Actions secrets:
1. ✅ No hardcoded credentials in repository
2. ✅ Easy to update if infrastructure changes
3. ✅ Secure OIDC authentication
4. ✅ Automatic credential rotation
5. ✅ Better auditability and compliance

All workflows reference the same 3 secrets, making it easy to maintain and update! 🔒
