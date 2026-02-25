# Bootstrap Scripts

Quick-start automation scripts for project setup and CI/CD configuration.

## Scripts

### `bootstrap-oidc.sh` — AWS OIDC + GitHub Actions Setup

**Purpose:** Automate one-time setup of secure GitHub Actions → AWS authentication via OIDC federation.

**What it does:**
1. ✓ Checks prerequisites (AWS CLI, Terraform, GitHub CLI)
2. ✓ Validates AWS credentials
3. ✓ Detects GitHub org/repo from git remote
4. ✓ Creates IAM OIDC provider + role via Terraform
5. ✓ Stores role ARN in GitHub secret
6. ✓ Creates dev/staging/prod GitHub environments
7. ✓ Triggers OIDC test workflow
8. ✓ Provides next steps

**Prerequisite Setup:**

```bash
# 1. Install AWS CLI (if needed)
# macOS
brew install awscli

# 2. Configure AWS credentials (choose one)
# Option A: AWS CLI profile
aws configure --profile YOUR_PROFILE

# Option B: Environment variables
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"

# Option C: AWS SSO
aws sso login --profile YOUR_PROFILE

# 3. Verify credentials work
aws sts get-caller-identity

# 4. Install Terraform (if needed)
# macOS
brew install terraform

# 5. Install GitHub CLI (if needed)
# macOS
brew install gh

# 6. Authenticate with GitHub
gh auth login
# Follow prompts to authenticate
```

**Usage:**

```bash
# From repo root
cd /Users/rsingh/Documents/Projects/rupaya

# Run bootstrap
./scripts/bootstrap-oidc.sh
```

**What the script prompts for:**
- AWS Account ID (detected automatically)
- GitHub org/repo (detected from git remote, or ask)
- Terraform apply confirmation (shows plan first)
- Manual GitHub environment creation (instructions provided)

**Output:**
- AWS IAM OIDC Provider created
- IAM Role `rupaya-github-oidc` created with trust policy
- Role ARN stored in GitHub secret `AWS_OIDC_ROLE_ARN`
- Instructions for manual GitHub environment setup

**Example Run:**

```bash
$ ./scripts/bootstrap-oidc.sh

==========================================
→ AWS OIDC Bootstrap for GitHub Actions
==========================================

→ Checking prerequisites...
✓ AWS CLI: aws-cli/2.14.0
✓ Terraform: Terraform v1.6.6
✓ GitHub CLI: gh version 2.36.0

→ Checking AWS credentials...
✓ AWS Account: 123456789012
✓ Principal: arn:aws:iam::123456789012:user/your-user

→ Checking GitHub authentication...
✓ GitHub user: your-username

→ Detecting GitHub repository...
✓ Repository: myorg/rupaya

→ Creating AWS IAM OIDC role via Terraform...
→ Running terraform init...
→ Running terraform plan...

... terraform plan output ...

Review plan above. Apply? (yes/no): yes

→ Applying Terraform...
... terraform apply output ...

✓ OIDC Role ARN: arn:aws:iam::123456789012:role/rupaya-github-oidc

→ Creating GitHub repository secret: AWS_OIDC_ROLE_ARN
✓ GitHub secret created: AWS_OIDC_ROLE_ARN

→ Creating GitHub environments...
→ Creating development environment...
⚠ Please create 'development' environment manually:
  1. Go to: GitHub Settings → Environments → New environment
  2. Name: development
  3. Add these variables:
     - DEV_ECS_CLUSTER = rupaya-dev-cluster
     - DEV_ECS_SERVICE = rupaya-backend-dev
     ...

... (staging and production instructions) ...

→ Testing OIDC authentication...
→ Running workflow: Test OIDC Authentication

✓ Workflow triggered. View results:
  https://github.com/myorg/rupaya/actions/workflows/00-test-oidc.yml

==========================================
✓ AWS OIDC Bootstrap Complete!
==========================================

✅ Completed:
   1. AWS IAM OIDC Provider created
   2. IAM Role 'rupaya-github-oidc' created
   3. GitHub secret 'AWS_OIDC_ROLE_ARN' stored
   4. GitHub environments created (manual setup needed)

📝 Next Steps:
   1. Create GitHub environments manually (see instructions above)
   2. Wait for OIDC test workflow to complete
   3. Check workflow logs at:
      https://github.com/myorg/rupaya/actions

🚀 After OIDC is verified:
   1. Run Terraform for infrastructure (workflow 09)
   2. Run RDS migrations (workflow 10)
   3. Deploy to dev via PR (workflow 05)
   4. Deploy to staging via release branch (workflow 06)
   5. Deploy to prod via main push (workflow 07)

📚 Reference: docs/AWS_OIDC_QUICKSTART.md
==========================================
```

**Troubleshooting:**

| Error | Cause | Fix |
|-------|-------|-----|
| `AWS credentials not configured` | No AWS credentials found | Run `aws configure` or set `AWS_ACCESS_KEY_ID` + `AWS_SECRET_ACCESS_KEY` |
| `Not authenticated with GitHub` | GitHub CLI not logged in | Run `gh auth login` |
| `File not found: infra/aws/terraform/aws-oidc-role.tf` | Script run from wrong directory | Run from repo root: `cd /Users/rsingh/Documents/Projects/rupaya` |
| `Terraform init failed` | AWS credentials issue during Terraform | Verify credentials with `aws sts get-caller-identity` |

**Security Notes:**

✓ Bootstrap script is **one-time only**  
✓ AWS credentials are **temporary** (only during Terraform apply)  
✓ Role ARN stored in GitHub is **not sensitive** (just a resource reference)  
✓ After bootstrap completes, GitHub Actions uses **OIDC only** (no long-lived credentials)  

**See Also:**

- [AWS_OIDC_QUICKSTART.md](../docs/AWS_OIDC_QUICKSTART.md) — Fast 5-step setup guide
- [AWS_OIDC_SETUP.md](../docs/AWS_OIDC_SETUP.md) — Complete reference documentation
- [aws-oidc-role.tf](../infra/aws/terraform/aws-oidc-role.tf) — Terraform code for OIDC setup
