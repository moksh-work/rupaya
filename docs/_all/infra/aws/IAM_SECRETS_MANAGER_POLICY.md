# IAM Policy: GitHub Actions Secrets Manager Access

**File**: [infra/aws/iam-secrets-manager-policy.json](infra/aws/iam-secrets-manager-policy.json)  
**Purpose**: IAM policy allowing GitHub Actions OIDC roles to read RDS credentials from AWS Secrets Manager  
**Environments**: Staging & Production  

---

## 📋 Policy Definition

### Staging Environment Policy

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ReadRDSCredentialsStaging",
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": [
        "arn:aws:secretsmanager:us-east-1:123456789012:secret:rupaya/rds/staging*"
      ]
    },
    {
      "Sid": "DecryptSecrets",
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt",
        "kms:DescribeKey"
      ],
      "Resource": [
        "arn:aws:kms:us-east-1:123456789012:key/*"
      ],
      "Condition": {
        "StringEquals": {
          "kms:ViaService": "secretsmanager.us-east-1.amazonaws.com"
        }
      }
    }
  ]
}
```

### Production Environment Policy

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ReadRDSCredentialsProduction",
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": [
        "arn:aws:secretsmanager:us-east-1:123456789012:secret:rupaya/rds/production*"
      ]
    },
    {
      "Sid": "DecryptSecrets",
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt",
        "kms:DescribeKey"
      ],
      "Resource": [
        "arn:aws:kms:us-east-1:123456789012:key/*"
      ],
      "Condition": {
        "StringEquals": {
          "kms:ViaService": "secretsmanager.us-east-1.amazonaws.com"
        }
      }
    }
  ]
}
```

---

## 🔐 Policy Actions Explained

| Action | Purpose | Required |
|--------|---------|----------|
| `secretsmanager:GetSecretValue` | Read the secret JSON payload | ✅ Yes |
| `secretsmanager:DescribeSecret` | Get secret metadata (creation date, etc.) | ⚠️ Optional |
| `kms:Decrypt` | Decrypt secret with AWS KMS key | ✅ Yes |
| `kms:DescribeKey` | View KMS key properties | ⚠️ Optional |

---

## 🚀 Application Commands

### Attach to Staging Role

```bash
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
        "Resource": "arn:aws:secretsmanager:us-east-1:123456789012:secret:rupaya/rds/staging*"
      },
      {
        "Effect": "Allow",
        "Action": ["kms:Decrypt", "kms:DescribeKey"],
        "Resource": "arn:aws:kms:us-east-1:123456789012:key/*",
        "Condition": {
          "StringEquals": {
            "kms:ViaService": "secretsmanager.us-east-1.amazonaws.com"
          }
        }
      }
    ]
  }'
```

### Attach to Production Role

```bash
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
        "Resource": "arn:aws:secretsmanager:us-east-1:123456789012:secret:rupaya/rds/production*"
      },
      {
        "Effect": "Allow",
        "Action": ["kms:Decrypt", "kms:DescribeKey"],
        "Resource": "arn:aws:kms:us-east-1:123456789012:key/*",
        "Condition": {
          "StringEquals": {
            "kms:ViaService": "secretsmanager.us-east-1.amazonaws.com"
          }
        }
      }
    ]
  }'
```

### Verify Policy Attached

```bash
# Check staging role policy
aws iam get-role-policy \
  --role-name GitHubActionsRoleStaging \
  --policy-name SecretsManagerAccess

# Check production role policy
aws iam get-role-policy \
  --role-name GitHubActionsRoleProd \
  --policy-name SecretsManagerAccess
```

---

## 🔍 Policy Conditions Explained

### KMS Service-Based Condition

```json
"Condition": {
  "StringEquals": {
    "kms:ViaService": "secretsmanager.us-east-1.amazonaws.com"
  }
}
```

**Purpose**: Only allow decryption when request comes from Secrets Manager service  
**Security Benefit**: Prevents direct KMS access from GitHub Actions that could bypass Secrets Manager

---

## 🧪 Testing the Policy

### Test 1: Verify Staging Role Can Read Secret

```bash
# Get temporary credentials for staging role
CREDENTIALS=$(aws sts assume-role \
  --role-arn arn:aws:iam::123456789012:role/GitHubActionsRoleStaging \
  --role-session-name test-staging)

# Extract credentials
export AWS_ACCESS_KEY_ID=$(echo $CREDENTIALS | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo $CREDENTIALS | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo $CREDENTIALS | jq -r '.Credentials.SessionToken')

# Test: Read staging secret
aws secretsmanager get-secret-value \
  --secret-id rupaya/rds/staging \
  --region us-east-1 | jq '.SecretString | fromjson'

# Expected output:
# {
#   "username": "rupaya_staging_user",
#   "password": "GeneratedPassword123!",
#   "engine": "postgres",
#   "host": "rupaya-staging.xxx.us-east-1.rds.amazonaws.com",
#   "port": 5432,
#   "dbname": "rupaya_staging"
# }
```

### Test 2: Verify Staging Role Cannot Read Production Secret

```bash
# Test: Try to read production secret (should fail)
aws secretsmanager get-secret-value \
  --secret-id rupaya/rds/production \
  --region us-east-1

# Expected error:
# An error occurred (AccessDeniedException) when calling the GetSecretValue operation:
# User: arn:aws:iam::123456789012:role/GitHubActionsRoleStaging
# is not authorized to perform: secretsmanager:GetSecretValue
```

### Test 3: Verify Production Role Cannot Read Staging Secret

```bash
# Get temporary credentials for production role
CREDENTIALS=$(aws sts assume-role \
  --role-arn arn:aws:iam::123456789012:role/GitHubActionsRoleProd \
  --role-session-name test-prod)

# Extract credentials
export AWS_ACCESS_KEY_ID=$(echo $CREDENTIALS | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo $CREDENTIALS | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo $CREDENTIALS | jq -r '.Credentials.SessionToken')

# Test: Try to read staging secret (should fail)
aws secretsmanager get-secret-value \
  --secret-id rupaya/rds/staging \
  --region us-east-1

# Expected error: AccessDeniedException
```

---

## 📊 Permission Scope

### Staging Role Permissions

| Resource | GetSecretValue | DescribeSecret | Notes |
|----------|---|---|---|
| `rupaya/rds/staging` | ✅ YES | ✅ YES | Can read staging credentials |
| `rupaya/rds/production` | ❌ NO | ❌ NO | Cannot access production |
| Other secrets | ❌ NO | ❌ NO | Cannot access other secrets |

### Production Role Permissions

| Resource | GetSecretValue | DescribeSecret | Notes |
|----------|---|---|---|
| `rupaya/rds/staging` | ❌ NO | ❌ NO | Cannot access staging |
| `rupaya/rds/production` | ✅ YES | ✅ YES | Can read production credentials |
| Other secrets | ❌ NO | ❌ NO | Cannot access other secrets |

---

## 🔄 Policy Updates

To modify permissions, use:

```bash
# Update staging policy
aws iam put-role-policy \
  --role-name GitHubActionsRoleStaging \
  --policy-name SecretsManagerAccess \
  --policy-document file://new-policy.json

# Update production policy
aws iam put-role-policy \
  --role-name GitHubActionsRoleProd \
  --policy-name SecretsManagerAccess \
  --policy-document file://new-policy.json
```

**Note**: This overwrites the entire policy, so include all necessary statements

---

## 🗑️ Policy Removal

If you need to remove Secrets Manager access:

```bash
# Remove from staging role
aws iam delete-role-policy \
  --role-name GitHubActionsRoleStaging \
  --policy-name SecretsManagerAccess

# Remove from production role
aws iam delete-role-policy \
  --role-name GitHubActionsRoleProd \
  --policy-name SecretsManagerAccess
```

---

## 📋 Audit & Compliance

### View Policy Inline

```bash
# View the current policy JSON
aws iam get-role-policy \
  --role-name GitHubActionsRoleStaging \
  --policy-name SecretsManagerAccess \
  --query 'RolePolicyDocument' | jq
```

### Track Policy Changes

```bash
# View IAM access history
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=PutRolePolicy \
  --region us-east-1 \
  --max-results 10
```

### Compliance Checks

```bash
# Verify all GitHub Actions roles have Secrets Manager access
for role in GitHubActionsRoleStaging GitHubActionsRoleProd; do
  echo "Checking $role..."
  aws iam get-role-policy \
    --role-name $role \
    --policy-name SecretsManagerAccess \
    2>/dev/null && echo "✅ Policy attached" || echo "❌ Policy NOT attached"
done
```

---

## 🚨 Security Best Practices

### ✅ DO:
- Use different policies for staging and production roles
- Limit access to specific secrets (use ARN wildcards carefully)
- Include KMS decrypt permission for encrypted secrets
- Regularly audit who has access
- Monitor CloudTrail for policy changes

### ❌ DON'T:
- Use wildcard "*" for resources (unless absolutely necessary)
- Grant `secretsmanager:*` permissions
- Allow `kms:*` permissions without conditions
- Share policies between production and non-production roles
- Store policy documents in version control without review

---

## 🔗 Related Resources

- [AWS Secrets Manager Documentation](https://docs.aws.amazon.com/secretsmanager/)
- [IAM Policy Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [Least Privilege Access](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html#grant-least-privilege)
- [GitHub Actions OIDC Configuration](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)

---

**Status**: Ready for Implementation  
**Last Updated**: February 5, 2026  
**Maintained By**: Security/DevOps Team
