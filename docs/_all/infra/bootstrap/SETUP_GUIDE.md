# AWS Bootstrap Setup: OIDC & IAM Configuration

**Purpose**: One-time setup of AWS OIDC provider and IAM roles  
**Frequency**: Run once per AWS account  
**Time Required**: 30 minutes  
**Prerequisites**: AWS CLI, Terraform, Admin access to AWS account  

---

## 📋 Overview

This guide sets up the AWS-side infrastructure required by the GitHub Actions workflows. This **must be completed before** deploying the main Rupaya infrastructure.

### What Gets Created

```
AWS Account (123456789012)
├─ OIDC Provider
│  └─ Verifies GitHub Actions tokens
├─ IAM Role: GitHubActionsRoleStaging
│  ├─ Trust policy (GitHub OIDC provider)
│  └─ Permissions (Secrets Manager, ECR, ECS, etc.)
└─ IAM Role: GitHubActionsRoleProd
   ├─ Trust policy (GitHub OIDC provider)
   └─ Permissions (Secrets Manager, ECR, ECS, etc.)
```

### Outputs Needed for GitHub

After bootstrap setup completes, you'll have:
```
AWS_OIDC_ROLE_STAGING = arn:aws:iam::123456789012:role/GitHubActionsRoleStaging
AWS_OIDC_ROLE_PROD = arn:aws:iam::123456789012:role/GitHubActionsRoleProd
```

Add these as GitHub repository secrets → used by all workflows.

---

## 🚀 Step 1: Set Environment Variables

```bash
# Set your AWS account details
export AWS_ACCOUNT_ID="123456789012"  # Replace with your account ID
export AWS_REGION="us-east-1"
export GITHUB_ORG="your-github-org"
export GITHUB_REPO="rupaya"

# Verify
echo "AWS Account: $AWS_ACCOUNT_ID"
echo "Region: $AWS_REGION"
echo "GitHub: $GITHUB_ORG/$GITHUB_REPO"
```

---

## 🔄 Step 2: Create OIDC Provider (One-time)

### Option A: Using AWS CLI (Recommended)

```bash
# Create the OIDC Provider
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list \
    6938fd4d98bab03faadb97b34396831e3780aea1 \
    1b511abead59c6ce207077c0ef0302ef1e1d0e5e \
  --region $AWS_REGION

# Output should show:
# {
#   "OpenIDConnectProviderArn": "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
# }

# Store for later use
export OIDC_PROVIDER_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
```

### Option B: Using Terraform

```bash
cd infra/bootstrap

terraform init
terraform plan -var="aws_account_id=$AWS_ACCOUNT_ID"
terraform apply -var="aws_account_id=$AWS_ACCOUNT_ID"

# Get outputs
terraform output oidc_provider_arn
```

---

## 🔐 Step 3: Create IAM Roles

### Staging Role Trust Policy

```bash
cat > /tmp/staging-trust-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::AWS_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "repo:GITHUB_ORG/GITHUB_REPO:ref:refs/heads/develop"
        }
      }
    }
  ]
}
EOF

# Replace placeholders
sed -i.bak "s/AWS_ACCOUNT_ID/$AWS_ACCOUNT_ID/g" /tmp/staging-trust-policy.json
sed -i.bak "s/GITHUB_ORG/$GITHUB_ORG/g" /tmp/staging-trust-policy.json
sed -i.bak "s/GITHUB_REPO/$GITHUB_REPO/g" /tmp/staging-trust-policy.json

# Create role
aws iam create-role \
  --role-name GitHubActionsRoleStaging \
  --assume-role-policy-document file:///tmp/staging-trust-policy.json \
  --tags Key=Environment,Value=staging Key=ManagedBy,Value=GitHub
```

### Production Role Trust Policy

```bash
cat > /tmp/prod-trust-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::AWS_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "repo:GITHUB_ORG/GITHUB_REPO:ref:refs/heads/main"
        }
      }
    }
  ]
}
EOF

# Replace placeholders
sed -i.bak "s/AWS_ACCOUNT_ID/$AWS_ACCOUNT_ID/g" /tmp/prod-trust-policy.json
sed -i.bak "s/GITHUB_ORG/$GITHUB_ORG/g" /tmp/prod-trust-policy.json
sed -i.bak "s/GITHUB_REPO/$GITHUB_REPO/g" /tmp/prod-trust-policy.json

# Create role
aws iam create-role \
  --role-name GitHubActionsRoleProd \
  --assume-role-policy-document file:///tmp/prod-trust-policy.json \
  --tags Key=Environment,Value=production Key=ManagedBy,Value=GitHub
```

---

## 📋 Step 4: Attach Policies

### Staging Role - Required Permissions

```bash
# Database access
aws iam attach-role-policy \
  --role-name GitHubActionsRoleStaging \
  --policy-arn arn:aws:iam::aws:policy/AmazonRDSFullAccess

# Secrets Manager access
aws iam put-role-policy \
  --role-name GitHubActionsRoleStaging \
  --policy-name SecretsManagerAccess \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        "Resource": "arn:aws:secretsmanager:*:*:secret:rupaya/rds/staging*"
      },
      {
        "Effect": "Allow",
        "Action": ["kms:Decrypt", "kms:DescribeKey"],
        "Resource": "arn:aws:kms:*:*:key/*",
        "Condition": {
          "StringEquals": {
            "kms:ViaService": "secretsmanager.*.amazonaws.com"
          }
        }
      }
    ]
  }'

# ECR access
aws iam attach-role-policy \
  --role-name GitHubActionsRoleStaging \
  --policy-arn arn:aws:iam::aws:policy/EC2ContainerRegistryPowerUser

# ECS access
aws iam attach-role-policy \
  --role-name GitHubActionsRoleStaging \
  --policy-arn arn:aws:iam::aws:policy/AmazonECS_FullAccess

# EC2 access
aws iam attach-role-policy \
  --role-name GitHubActionsRoleStaging \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess
```

### Production Role - Required Permissions

```bash
# Database access
aws iam attach-role-policy \
  --role-name GitHubActionsRoleProd \
  --policy-arn arn:aws:iam::aws:policy/AmazonRDSFullAccess

# Secrets Manager access (production only)
aws iam put-role-policy \
  --role-name GitHubActionsRoleProd \
  --policy-name SecretsManagerAccess \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        "Resource": "arn:aws:secretsmanager:*:*:secret:rupaya/rds/production*"
      },
      {
        "Effect": "Allow",
        "Action": ["kms:Decrypt", "kms:DescribeKey"],
        "Resource": "arn:aws:kms:*:*:key/*",
        "Condition": {
          "StringEquals": {
            "kms:ViaService": "secretsmanager.*.amazonaws.com"
          }
        }
      }
    ]
  }'

# ECR access
aws iam attach-role-policy \
  --role-name GitHubActionsRoleProd \
  --policy-arn arn:aws:iam::aws:policy/EC2ContainerRegistryPowerUser

# ECS access
aws iam attach-role-policy \
  --role-name GitHubActionsRoleProd \
  --policy-arn arn:aws:iam::aws:policy/AmazonECS_FullAccess

# EC2 access  
aws iam attach-role-policy \
  --role-name GitHubActionsRoleProd \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess

# Lambda access
aws iam attach-role-policy \
  --role-name GitHubActionsRoleProd \
  --policy-arn arn:aws:iam::aws:policy/AWSLambdaFullAccess
```

---

## ✅ Step 5: Verify Setup

### Get Role ARNs

```bash
# Get staging role ARN
STAGING_ROLE_ARN=$(aws iam get-role \
  --role-name GitHubActionsRoleStaging \
  --query 'Role.Arn' \
  --output text)

# Get production role ARN
PROD_ROLE_ARN=$(aws iam get-role \
  --role-name GitHubActionsRoleProd \
  --query 'Role.Arn' \
  --output text)

echo "Staging Role ARN: $STAGING_ROLE_ARN"
echo "Production Role ARN: $PROD_ROLE_ARN"
```

### Verify OIDC Provider

```bash
# List OIDC providers
aws iam list-open-id-connect-providers

# Should output:
# {
#   "OpenIDConnectProviderList": [
#     {
#       "Arn": "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
#     }
#   ]
# }
```

### Verify Role Trust Policy

```bash
# Check staging role can be assumed by GitHub
aws iam get-role \
  --role-name GitHubActionsRoleStaging \
  --query 'Role.AssumeRolePolicyDocument'

# Verify "Principal" includes the OIDC provider ARN
# Verify "Condition.sub" includes "repo:GITHUB_ORG/GITHUB_REPO:ref:refs/heads/develop"
```

---

## 🔗 Step 6: Add to GitHub Repository

Once verification passes, add the role ARNs to GitHub:

```bash
# Via GitHub CLI
gh secret set AWS_OIDC_ROLE_STAGING --body "$STAGING_ROLE_ARN"
gh secret set AWS_OIDC_ROLE_PROD --body "$PROD_ROLE_ARN"

# Verify
gh secret list
```

Or manually:
1. Go to GitHub repo → **Settings → Secrets and variables → Actions**
2. Click **New repository secret**
3. Name: `AWS_OIDC_ROLE_STAGING`
   Value: `arn:aws:iam::123456789012:role/GitHubActionsRoleStaging`
4. Click **New repository secret**
5. Name: `AWS_OIDC_ROLE_PROD`
   Value: `arn:aws:iam::123456789012:role/GitHubActionsRoleProd`

---

## 🧪 Step 7: Test OIDC Authentication

### Test Staging Role

```bash
# Push a test commit to develop branch
git checkout develop
git commit --allow-empty -m "test: verify OIDC authentication"
git push origin develop

# Watch workflow execute
gh run list --workflow 01-aws-rds-migrations.yml --branch develop

# View logs
gh run view <run-id> --log

# Look for these lines:
# ✅ "Assuming role: arn:aws:iam::123456789012:role/GitHubActionsRoleStaging"
# ✅ Successfully assumed session
```

### Test Production Role

```bash
# Create test PR to main
git checkout -b test/oidc-prod
git commit --allow-empty -m "test: verify prod OIDC"
git push -u origin test/oidc-prod

# Create PR, get 2 approvals, merge to main
# gh pr create --base main --title "test: OIDC prod"

# After merge, check workflow
gh run list --workflow 01-aws-rds-migrations.yml --branch main
```

---

## ✅ Verification Checklist

### AWS Setup
- [ ] OIDC provider created
- [ ] GitHub OIDC thumbprints added
- [ ] GitHubActionsRoleStaging created
- [ ] GitHubActionsRoleProd created
- [ ] Trust policies configured correctly
- [ ] Staging role ARN obtained
- [ ] Production role ARN obtained

### GitHub Configuration
- [ ] `AWS_OIDC_ROLE_STAGING` secret added
- [ ] `AWS_OIDC_ROLE_PROD` secret added
- [ ] Secrets verified with `gh secret list`

### Testing
- [ ] Test commit pushed to develop branch
- [ ] Workflow triggered successfully
- [ ] OIDC role assumption logged in workflow output
- [ ] Staging role tested successfully
- [ ] Production role tested successfully
- [ ] No "AccessDenied" errors in logs

---

## 🔄 What Happens Next

After bootstrap setup completes:

1. ✅ GitHub Actions can authenticate to AWS without storing access keys
2. ✅ Workflows assume OIDC roles to get temporary credentials
3. ✅ Deploy main infrastructure from `infra/aws/`
4. ✅ Create Secrets Manager secrets for RDS credentials
5. ✅ Database migrations can retrieve credentials securely

---

## 🚨 Troubleshooting

### "AssumeRoleUnauthorizedOperation" Error

**Cause**: OIDC provider not set up or trust policy incorrect

**Solution**:
```bash
# Verify OIDC provider exists
aws iam list-open-id-connect-providers

# If not exists, run Step 2 again
# If exists, verify trust policy:
aws iam get-role --role-name GitHubActionsRoleStaging \
  --query 'Role.AssumeRolePolicyDocument'

# Check that Federated principal matches OIDC provider ARN
# Check that sub condition includes "repo:GITHUB_ORG/GITHUB_REPO"
```

### "InvalidParameterException" When Creating Role

**Cause**: Role already exists

**Solution**:
```bash
# Check existing role
aws iam get-role --role-name GitHubActionsRoleStaging

# If exists and need to recreate:
aws iam delete-role --role-name GitHubActionsRoleStaging
# Repeat role creation steps
```

### Workflow Can't Access Secrets Manager

**Cause**: SecretsManager policy not attached

**Solution**:
```bash
# Verify policy attached
aws iam get-role-policy \
  --role-name GitHubActionsRoleStaging \
  --policy-name SecretsManagerAccess

# If missing, rerun policy attachment commands
```

---

## 📚 Related Documentation

- [docs/GITHUB_ENTERPRISE_CI_CD_SETUP.md](../../docs/GITHUB_ENTERPRISE_CI_CD_SETUP.md#part-8-aws-oidc-configuration)
- [infra/aws/SECRETS_MANAGER_SETUP.md](../SECRETS_MANAGER_SETUP.md)
- [AWS OIDC Documentation](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)

---

**Status**: One-time setup required before deploying main infrastructure  
**Time**: 30 minutes  
**Frequency**: Once per AWS account  
**Dependencies**: AWS CLI, Terraform (optional)  
**Next Step**: Deploy main infrastructure from `infra/aws/`
