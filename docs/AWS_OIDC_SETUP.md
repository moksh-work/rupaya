# AWS OIDC Setup for GitHub Actions (Zero Credentials)

This guide enables GitHub Actions to authenticate to AWS via OpenID Connect (OIDC), eliminating the need for stored AWS credentials.

---

## Overview

**What:** GitHub Actions assumes an IAM role via OIDC federation  
**Why:** No AWS Access Keys, Secret Keys, or credentials in GitHub repo  
**How:** GitHub OIDC provider → IAM role with trust policy → AWS STS AssumeRole  
**Result:** Short-lived session tokens (~1 hour), automatic expiration  

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ GitHub Actions Workflow (workflow file)                      │
│ - Requests OIDC token from GitHub OIDC provider              │
│ - Sends token to AWS STS (Security Token Service)            │
└──────────────────┬──────────────────────────────────────────┘
                   │ OIDC Token
                   ▼
┌─────────────────────────────────────────────────────────────┐
│ AWS IAM OIDC Provider (github.com)                           │
│ - Validates GitHub token signature                           │
│ - Checks trust policy on rupaya-github-oidc role             │
└──────────────────┬──────────────────────────────────────────┘
                   │ Valid token + trust match
                   ▼
┌─────────────────────────────────────────────────────────────┐
│ AWS IAM Role: rupaya-github-oidc                             │
│ - Trust Policy: GitHub OIDC provider + repo conditions       │
│ - Inline Policy: ECR, ECS, S3, RDS, Secrets Manager perms    │
│ - MFA tags: optional (repo, branch, environment)             │
└──────────────────┬──────────────────────────────────────────┘
                   │ AssumeRole succeeds
                   ▼
┌─────────────────────────────────────────────────────────────┐
│ GitHub Actions: Session (1 hour credentials)                 │
│ - AWS_ACCESS_KEY_ID (temporary)                              │
│ - AWS_SECRET_ACCESS_KEY (temporary)                          │
│ - AWS_SESSION_TOKEN (temporary)                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Step 1: Create AWS IAM OIDC Provider

This one-time setup enables GitHub to authenticate to your AWS account.

### Via AWS Console

1. **Navigate:** IAM → Identity Providers → Add Provider
2. **Provider Type:** OpenID Connect
3. **Provider URL:** `https://token.actions.githubusercontent.com`
4. **Audience:** `sts.amazonaws.com`
5. **Thumbprint:** `6938fd4d98bab03faadb97b34396831e3780aea1` (GitHub's federated token signing cert)
   - *Note:* AWS auto-populates this; if not, leave blank and AWS fills it on save
6. **Click:** "Add provider"

### Via AWS CLI

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
  --region us-east-1
```

**Result:** Provider ARN (e.g., `arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com`)

---

## Step 2: Create IAM Role with Trust Policy

### Option A: Manual (AWS Console)

1. **IAM → Roles → Create role**
2. **Trusted entity type:** Custom trust policy
3. **Paste trust policy** (see below)
4. **Create role name:** `rupaya-github-oidc`
5. **Attach inline policy** (see Step 3)

### Option B: Terraform (Recommended)

See `terraform/aws-oidc-role.tf` below.

### Trust Policy (JSON)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowGitHubOIDCRupaya",
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": [
            "repo:YOUR_GITHUB_ORG/rupaya:ref:refs/heads/develop",
            "repo:YOUR_GITHUB_ORG/rupaya:ref:refs/heads/main",
            "repo:YOUR_GITHUB_ORG/rupaya:ref:refs/heads/release/*",
            "repo:YOUR_GITHUB_ORG/rupaya:environment:development",
            "repo:YOUR_GITHUB_ORG/rupaya:environment:staging",
            "repo:YOUR_GITHUB_ORG/rupaya:environment:production"
          ]
        }
      }
    }
  ]
}
```

**Replace:**
- `123456789012` → Your AWS Account ID
- `YOUR_GITHUB_ORG` → Your GitHub organization (e.g., `mycompany`)

### Trust Policy Explanation

- **Federated:** GitHub's OIDC provider in your account
- **Sub condition:** Restricts role assumption to:
  - Pushes on `develop`, `main`, `release/*` branches
  - Runs in `development`, `staging`, `production` GitHub environments
  - Other repos cannot assume this role

---

## Step 3: Create Inline IAM Policy

Grants the role permissions to:
- Push Docker images to ECR
- Update ECS task definitions & services
- Read/write S3 (Terraform state)
- Start RDS migrations
- Access Secrets Manager

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ECRAuthPush",
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ECRPushImage",
      "Effect": "Allow",
      "Action": [
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ],
      "Resource": "arn:aws:ecr:*:123456789012:repository/rupaya*"
    },
    {
      "Sid": "ECSUpdateService",
      "Effect": "Allow",
      "Action": [
        "ecs:UpdateService",
        "ecs:DescribeServices",
        "ecs:DescribeTaskDefinition",
        "ecs:RegisterTaskDefinition",
        "ecs:ListTaskDefinitions"
      ],
      "Resource": [
        "arn:aws:ecs:*:123456789012:service/rupaya-dev/*",
        "arn:aws:ecs:*:123456789012:service/rupaya-staging/*",
        "arn:aws:ecs:*:123456789012:service/rupaya-prod/*",
        "arn:aws:ecs:*:123456789012:task-definition/rupaya*"
      ]
    },
    {
      "Sid": "IAMPassRole",
      "Effect": "Allow",
      "Action": [
        "iam:PassRole"
      ],
      "Resource": [
        "arn:aws:iam::123456789012:role/ecsTaskExecutionRole",
        "arn:aws:iam::123456789012:role/ecsTaskRole"
      ]
    },
    {
      "Sid": "TerraformStateS3",
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": [
        "arn:aws:s3:::rupaya-terraform-state",
        "arn:aws:s3:::rupaya-terraform-state/*"
      ]
    },
    {
      "Sid": "TerraformStateDynamoDB",
      "Effect": "Allow",
      "Action": [
        "dynamodb:DescribeTable",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "arn:aws:dynamodb:*:123456789012:table/rupaya-terraform-lock"
    },
    {
      "Sid": "TerraformInfra",
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "rds:*",
        "elasticache:*",
        "acm:*",
        "cloudformation:*",
        "logs:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "RDSMigrations",
      "Effect": "Allow",
      "Action": [
        "rds:DescribeDBInstances",
        "rds:DescribeDBClusters"
      ],
      "Resource": "arn:aws:rds:*:123456789012:db/*"
    },
    {
      "Sid": "SecretsManagerRDS",
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": [
        "arn:aws:secretsmanager:*:123456789012:secret:rupaya/rds/*",
        "arn:aws:secretsmanager:*:123456789012:secret:rupaya/docker/*"
      ]
    }
  ]
}
```

**Replace:**
- `123456789012` → Your AWS Account ID
- Bucket/table names → Your actual S3 bucket and DynamoDB table names

---

## Step 4: Terraform Code (Automated Setup)

Create `infra/aws/terraform/aws-oidc-role.tf`:

```hcl
# AWS OIDC Provider for GitHub Actions
data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]

  tags = {
    Name        = "github-oidc-provider"
    Environment = "shared"
    ManagedBy   = "terraform"
  }
}

# IAM Role for GitHub Actions
resource "aws_iam_role" "github_oidc" {
  name               = "rupaya-github-oidc"
  assume_role_policy = data.aws_iam_policy_document.github_assume_role.json

  tags = {
    Name        = "rupaya-github-oidc"
    Environment = "shared"
    ManagedBy   = "terraform"
  }
}

# Trust Policy
data "aws_iam_policy_document" "github_assume_role" {
  statement {
    sid     = "AllowGitHubOIDCRupaya"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/develop",
        "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/main",
        "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/release/*",
        "repo:${var.github_org}/${var.github_repo}:environment:development",
        "repo:${var.github_org}/${var.github_repo}:environment:staging",
        "repo:${var.github_org}/${var.github_repo}:environment:production"
      ]
    }
  }
}

# Inline Policy
resource "aws_iam_role_policy" "github_oidc_inline" {
  name   = "rupaya-github-oidc-policy"
  role   = aws_iam_role.github_oidc.id
  policy = data.aws_iam_policy_document.github_oidc_policy.json
}

data "aws_iam_policy_document" "github_oidc_policy" {
  statement {
    sid    = "ECRAuthPush"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ECRPushImage"
    effect = "Allow"
    actions = [
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload"
    ]
    resources = ["arn:aws:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/rupaya*"]
  }

  statement {
    sid    = "ECSUpdateService"
    effect = "Allow"
    actions = [
      "ecs:UpdateService",
      "ecs:DescribeServices",
      "ecs:DescribeTaskDefinition",
      "ecs:RegisterTaskDefinition",
      "ecs:ListTaskDefinitions"
    ]
    resources = [
      "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:service/rupaya-dev/*",
      "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:service/rupaya-staging/*",
      "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:service/rupaya-prod/*",
      "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:task-definition/rupaya*"
    ]
  }

  statement {
    sid    = "IAMPassRole"
    effect = "Allow"
    actions = [
      "iam:PassRole"
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ecsTaskExecutionRole",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ecsTaskRole"
    ]
  }

  statement {
    sid    = "TerraformStateS3"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      "arn:aws:s3:::rupaya-terraform-state",
      "arn:aws:s3:::rupaya-terraform-state/*"
    ]
  }

  statement {
    sid    = "TerraformStateDynamoDB"
    effect = "Allow"
    actions = [
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]
    resources = ["arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/rupaya-terraform-lock"]
  }

  statement {
    sid    = "TerraformInfra"
    effect = "Allow"
    actions = [
      "ec2:*",
      "rds:*",
      "elasticache:*",
      "acm:*",
      "cloudformation:*",
      "logs:*"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "RDSMigrations"
    effect = "Allow"
    actions = [
      "rds:DescribeDBInstances",
      "rds:DescribeDBClusters"
    ]
    resources = ["arn:aws:rds:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:db/*"]
  }

  statement {
    sid    = "SecretsManagerRDS"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = [
      "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:rupaya/rds/*",
      "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:rupaya/docker/*"
    ]
  }
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Output role ARN for GitHub Actions
output "github_oidc_role_arn" {
  description = "ARN of the GitHub OIDC role for use in GitHub Actions"
  value       = aws_iam_role.github_oidc.arn
  sensitive   = false
}

# Variables to add to terraform.tfvars or terraform.auto.tfvars
variable "github_org" {
  description = "GitHub organization name"
  type        = string
  default     = "YOUR_GITHUB_ORG"
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = "rupaya"
}
```

### Run Terraform

```bash
cd infra/aws/terraform

# Plan OIDC setup
terraform plan -target=aws_iam_openid_connect_provider.github \
                -target=aws_iam_role.github_oidc \
                -target=aws_iam_role_policy.github_oidc_inline

# Apply (creates OIDC provider + role)
terraform apply -target=aws_iam_openid_connect_provider.github \
                 -target=aws_iam_role.github_oidc \
                 -target=aws_iam_role_policy.github_oidc_inline

# Retrieve role ARN
terraform output github_oidc_role_arn
```

**Output Example:**
```
github_oidc_role_arn = "arn:aws:iam::123456789012:role/rupaya-github-oidc"
```

---

## Step 5: Configure GitHub Repository Secrets

### Create Secret: `AWS_OIDC_ROLE_ARN`

1. Go to **GitHub → Repository → Settings → Secrets and variables → Actions**
2. Click **New repository secret**
3. **Name:** `AWS_OIDC_ROLE_ARN`
4. **Value:** (paste output from Terraform above, e.g., `arn:aws:iam::123456789012:role/rupaya-github-oidc`)
5. Click **Add secret**

✅ **Note:** This is NOT sensitive; it's a role ARN (not a credential). But storing in secrets keeps repo clean.

### Create Environments & Variables

Create GitHub environments with OIDC-only variables:

#### Development Environment

1. **Settings → Environments → New environment → `development`**
2. Add variables:
   - `DEV_ECS_CLUSTER` = `rupaya-dev-cluster`
   - `DEV_ECS_SERVICE` = `rupaya-backend-dev`
   - `DEV_ECS_TASK_FAMILY` = `rupaya-backend-dev`
   - `DEV_API_BASE_URL` = `https://api-dev.rupaya.io`
   - `DEV_DOCKER_REGISTRY` = `123456789012.dkr.ecr.us-east-1.amazonaws.com`
   - `AWS_REGION` = `us-east-1`

#### Staging Environment

1. **Settings → Environments → New environment → `staging`**
2. Add variables:
   - `STAGING_ECS_CLUSTER` = `rupaya-staging-cluster`
   - `STAGING_ECS_SERVICE` = `rupaya-backend-staging`
   - `STAGING_ECS_TASK_FAMILY` = `rupaya-backend-staging`
   - `STAGING_API_BASE_URL` = `https://api-staging.rupaya.io`
   - `STAGING_DOCKER_REGISTRY` = `123456789012.dkr.ecr.us-east-1.amazonaws.com`
   - `AWS_REGION` = `us-east-1`
   - (Optional) **Required reviewers:** Enable to mandate approval before deploy

#### Production Environment

1. **Settings → Environments → New environment → `production`**
2. Add variables:
   - `PROD_ECS_CLUSTER` = `rupaya-prod-cluster`
   - `PROD_ECS_SERVICE` = `rupaya-backend-prod`
   - `PROD_ECS_TASK_FAMILY` = `rupaya-backend-prod`
   - `PROD_API_BASE_URL` = `https://api.rupaya.io`
   - `PROD_DOCKER_REGISTRY` = `123456789012.dkr.ecr.us-east-1.amazonaws.com`
   - `AWS_REGION` = `us-east-1`
   - **Required reviewers:** `@your-team` (mandatory approval before production deploy)
   - **Deployment branches:** `main` only

---

## Step 6: Test OIDC Authentication

Create a test workflow to verify OIDC is working:

**`.github/workflows/00-test-oidc.yml`**

```yaml
name: Test OIDC Authentication

on:
  workflow_dispatch:

jobs:
  test-oidc:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Configure AWS Credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_OIDC_ROLE_ARN }}
          aws-region: us-east-1

      - name: Verify OIDC Authentication
        run: |
          echo "AWS Identity:"
          aws sts get-caller-identity
          
          echo ""
          echo "ECR Repositories:"
          aws ecr describe-repositories --region us-east-1 | jq '.repositories[].repositoryName'
          
          echo ""
          echo "✅ OIDC Authentication Successful!"
```

**Run:**
1. Go to GitHub → Actions → Workflows → "Test OIDC Authentication"
2. Click **Run workflow** → **Run workflow**
3. Watch logs → should see `assume-role` success + AWS Account ID

**If it works:**
```
AWS Identity:
{
    "UserId": "AIDA...",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:assumed-role/rupaya-github-oidc/github-actions"
}

✅ OIDC Authentication Successful!
```

---

## Step 7: Secure CloudTrail Verification (Audit Trail)

Verify OIDC logins appear in CloudTrail (not hardcoded credentials):

```bash
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=AssumeRole \
  --region us-east-1 \
  --max-results 10 \
  --query 'Events[?contains(CloudTrailEvent, `rupaya-github-oidc`)].{Time:EventTime, Principal:CloudTrailEvent, Status:EventStatus}'
```

**Expected output:**
```json
{
  "Time": "2024-01-15T10:30:45Z",
  "Principal": "...token.actions.githubusercontent.com...",
  "Status": "Success"
}
```

**Key point:** Event origin is `token.actions.githubusercontent.com` (GitHub OIDC), not an AWS Access Key.

---

## Troubleshooting

### "AssumeRole Failed" Error

1. **Check trust policy:**
   ```bash
   aws iam get-role --role-name rupaya-github-oidc | jq '.Role.AssumeRolePolicyDocument'
   ```
   - Verify `Principal.Federated` matches OIDC provider ARN
   - Verify `Sub` condition includes your repo/branch

2. **Verify OIDC provider exists:**
   ```bash
   aws iam list-open-id-connect-providers
   ```
   - Should show `arn:aws:iam::ACCOUNT:oidc-provider/token.actions.githubusercontent.com`

3. **Check GitHub environment:**
   - Workflow must reference the correct GitHub environment in `jobs.*.environment`
   - Environment must be created in Settings → Environments

4. **Verify ARN format:**
   ```bash
   aws iam get-role --role-name rupaya-github-oidc --query 'Role.Arn'
   # Should output: arn:aws:iam::123456789012:role/rupaya-github-oidc
   ```

### "AccessDenied" After AssumeRole

1. **Check inline policy permissions:**
   ```bash
   aws iam get-role-policy --role-name rupaya-github-oidc --policy-name rupaya-github-oidc-policy | jq '.RolePolicyDocument'
   ```

2. **Verify resource ARNs in policy match your infrastructure:**
   - `ECR` repo names
   - `ECS` cluster/service names
   - `S3` bucket names
   - `DynamoDB` table names

3. **Add missing permissions** to inline policy as needed.

---

## Security Best Practices

✅ **What this setup provides:**
- Zero AWS credentials stored in GitHub
- Short-lived tokens (1 hour max)
- Audit trail in CloudTrail
- Condition-based access (branch/environment restrictions)
- Automatic credential rotation (GitHub manages token lifecycle)

✅ **Additional hardening (optional):**
1. Restrict `Sub` condition to specific GitHub org (already done)
2. Add branch/environment conditions (already done)
3. Use GitHub environment required reviewers for production
4. Enable MFA for `aws_iam_role_policy` changes (via `aws:MultiFactorAuthPresent` condition)
5. Log all OIDC assume-role calls to CloudWatch
6. Set role session duration to 1 hour (default)

---

## Summary Checklist

- [ ] Step 1: Create OIDC provider in AWS (`https://token.actions.githubusercontent.com`)
- [ ] Step 2: Create IAM role `rupaya-github-oidc` with trust policy
- [ ] Step 3: Add inline policy with ECR, ECS, S3, RDS, Secrets Manager permissions
- [ ] Step 4: (Optional) Use Terraform to automate steps 1-3
- [ ] Step 5: Create GitHub secret `AWS_OIDC_ROLE_ARN` + environments + variables
- [ ] Step 6: Test OIDC with `00-test-oidc.yml` workflow
- [ ] Step 7: Verify CloudTrail shows assume-role events (no credentials)
- [ ] ✅ Ready for workflows 05-07 (PR, release, main deployments)

---

**Next Steps:**
1. Run Terraform or manually create OIDC provider + role
2. Retrieve role ARN
3. Add `AWS_OIDC_ROLE_ARN` secret to GitHub
4. Create `development`, `staging`, `production` environments + variables
5. Run test workflow to verify
6. Deploy workflows 05-07 (they will now work with OIDC)
