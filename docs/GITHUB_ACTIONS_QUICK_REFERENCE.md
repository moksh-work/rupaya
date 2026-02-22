# GitHub Actions Secrets - Quick Reference

## 3-Step Setup

### Step 1: Get Values from Terraform ✓
```bash
cd infra/aws
terraform output -json
```

Copy these values:
- `github_actions_role_arn` → Use for `AWS_OIDC_ROLE_ARN`
- `tfstate_bucket` → Use for `TFSTATE_BUCKET_NAME`

Also get:
- ECR Registry: `590184132516.dkr.ecr.us-east-1.amazonaws.com` (ask AWS)

### Step 2: Create Secrets in GitHub
URL: `https://github.com/your-org/rupaya/settings/secrets/actions`

| Secret Name | Value | Example |
|------------|-------|---------|
| `AWS_OIDC_ROLE_ARN` | From terraform output | `arn:aws:iam::590184132516:role/rupaya-terraform-cicd` |
| `TFSTATE_BUCKET_NAME` | From terraform output | `rupaya-terraform-state-590184132516` |
| `ECR_REGISTRY` | ECR registry URL | `590184132516.dkr.ecr.us-east-1.amazonaws.com` |

### Step 3: Test
```bash
git add .
git commit -m "ci: setup complete"
git push origin main
```

Watch Actions tab - should see ✓ "Successfully authenticated"

---

## Before vs After

### ❌ Old Way (Hardcoded - INSECURE)
```yaml
# .github/workflows/deploy.yml
- name: Configure AWS
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::590184132516:role/rupaya-terraform-cicd  # ← HARDCODED!
```

**Problems:**
- Account visible in source code
- Impossible to hide from code review
- Cannot be changed without code update
- Completely exposed in Git history

### ✅ New Way (Secrets - SECURE)
```yaml
# .github/workflows/deploy.yml
- name: Configure AWS
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ secrets.AWS_OIDC_ROLE_ARN }}  # ← SECRET!
```

**Benefits:**
- Account hidden in GitHub secrets
- Can be rotated without code changes
- Protected by GitHub security
- Masked in all logs

---

## All Secrets at a Glance

```yaml
# How workflows use secrets

env:
  AWS_REGION: "us-east-1"
  AWS_ROLE_ARN: ${{ secrets.AWS_OIDC_ROLE_ARN }}      # ← Used by all workflows
  ECR_REGISTRY: ${{ secrets.ECR_REGISTRY }}            # ← Used by build workflows
  TFSTATE_BUCKET: ${{ secrets.TFSTATE_BUCKET_NAME }}  # ← Used by terraform

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ env.AWS_ROLE_ARN }}
          aws-region: ${{ env.AWS_REGION }}
```

---

## Verification Checklist

- [ ] Ran `terraform output -json` and got all values
- [ ] Created `AWS_OIDC_ROLE_ARN` secret in GitHub
- [ ] Created `TFSTATE_BUCKET_NAME` secret in GitHub
- [ ] Created `ECR_REGISTRY` secret in GitHub
- [ ] All 3 secrets show ✓ in GitHub Settings
- [ ] Pushed a test commit to main
- [ ] Workflow ran successfully
- [ ] No hardcoded credentials visible in logs

---

## If Something Goes Wrong

### Error: "Invalid token"
**Solution:** Check `AWS_OIDC_ROLE_ARN` secret value is correct

### Error: "AccessDenied"  
**Solution:** Check IAM role has correct permissions `aws_iam_role_policy.github_actions_*`

### Error: "Credential could not be loaded"
**Solution:** Check secret names match exactly (case-sensitive):
- `AWS_OIDC_ROLE_ARN` ✓ (not `aws_oidc_role_arn`)
- `TFSTATE_BUCKET_NAME` ✓ (not `tfstate_bucket_name`)
- `ECR_REGISTRY` ✓ (not `ecr_registry`)

### Workflows still show hardcoded values
**Solution:** GitHub might cache workflows. Try:
```bash
git commit --allow-empty -m "ci: refresh workflows"
git push origin main
```

---

## 📚 Full Guides

- **Setup Instructions:** [GITHUB_ACTIONS_SECRETS_SETUP.md](GITHUB_ACTIONS_SECRETS_SETUP.md)
- **Complete Reference:** [GITHUB_ACTIONS_SETUP_COMPLETE.md](GITHUB_ACTIONS_SETUP_COMPLETE.md)  
- **No More Hardcoding:** [NO_MORE_HARDCODED_CREDENTIALS.md](NO_MORE_HARDCODED_CREDENTIALS.md)

---

## Secret Values Cheat Sheet

```bash
# Get all values you need:
cd infra/aws

# Get OIDC role ARN
terraform output github_actions_role_arn
# Output: arn:aws:iam::590184132516:role/rupaya-terraform-cicd

# Get S3 bucket name  
terraform output tfstate_bucket
# Output: rupaya-terraform-state-590184132516

# Get ECR registry (or it's usually account-id.dkr.ecr.region.amazonaws.com)
aws ecr describe-repositories --region us-east-1 --query 'repositories[0].repositoryUri' --output text | cut -d'/' -f1
# Output: 590184132516.dkr.ecr.us-east-1.amazonaws.com
```

Then copy those values into GitHub secrets! 🔒
