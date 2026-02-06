# Quick Reference: RDS Credentials Migration

**Status**: ✅ Implementation Complete  
**Date**: February 5, 2026  

---

## 📋 What Changed

### GitHub Secrets
```
❌ REMOVED (after verification):
  - RDS_STAGING_USER
  - RDS_STAGING_PASSWORD
  - RDS_PROD_USER
  - RDS_PROD_PASSWORD

✅ KEEP ONLY:
  - AWS_OIDC_ROLE_STAGING
  - AWS_OIDC_ROLE_PROD
```

### AWS Secrets Manager
```
✅ CREATED:
  - rupaya/rds/staging (JSON with all connection details)
  - rupaya/rds/production (JSON with all connection details)
  - Automatic 30-day rotation enabled
```

### Workflow
```
OLD:
  DB_USER: ${{ secrets.RDS_STAGING_USER }}
  DB_PASSWORD: ${{ secrets.RDS_STAGING_PASSWORD }}

NEW:
  - Retrieve secret from Secrets Manager
  - Parse JSON to get username, password, host, port, dbname
  - Use in migration commands
```

---

## 🚀 Quick Deploy

### 1. Deploy Infrastructure (5 min)
```bash
cd infra/aws
terraform apply
```

### 2. Add IAM Permissions (5 min)
```bash
# Copy commands from IAM_SECRETS_MANAGER_POLICY.md
aws iam put-role-policy --role-name GitHubActionsRoleStaging ...
aws iam put-role-policy --role-name GitHubActionsRoleProd ...
```

### 3. Test Staging (15 min)
```bash
git push origin develop
# Wait for workflow to complete
gh run view <run-id> --log
```

### 4. Deploy to Production (30 min)
```bash
# Via PR to main with 2 approvals
git push origin release/secrets-manager-migration
# Create PR to main, get approvals, merge
```

### 5. Cleanup (after 1 week)
```bash
gh secret remove RDS_STAGING_USER
gh secret remove RDS_STAGING_PASSWORD
gh secret remove RDS_PROD_USER
gh secret remove RDS_PROD_PASSWORD
```

---

## 📁 Files Created/Updated

### Created
- ✅ [infra/aws/SECRETS_MANAGER_SETUP.md](infra/aws/SECRETS_MANAGER_SETUP.md) - Setup guide
- ✅ [infra/aws/IAM_SECRETS_MANAGER_POLICY.md](infra/aws/IAM_SECRETS_MANAGER_POLICY.md) - IAM reference
- ✅ [RDS_MIGRATION_SUMMARY.md](RDS_MIGRATION_SUMMARY.md) - Complete summary

### Updated
- ✅ [infra/aws/secrets.tf](infra/aws/secrets.tf) - Terraform: Added staging/prod secrets
- ✅ [.github/workflows/01-aws-rds-migrations.yml](.github/workflows/01-aws-rds-migrations.yml) - Retrieve from Secrets Manager
- ✅ [docs/GITHUB_ENTERPRISE_CI_CD_SETUP.md](docs/GITHUB_ENTERPRISE_CI_CD_SETUP.md) - Added Part 7: Secrets Manager

---

## 🔐 Security Model

```
GitHub Actions OIDC Token
    ↓
Assume AWS Role (staging/prod)
    ↓
AWS IAM Permissions
    ↓
Read from Secrets Manager
    ↓
CloudTrail Logs Access
    ↓
AWS KMS Decryption
    ↓
Use Credentials (no logging)
```

**Key**: No credentials ever stored in GitHub ✅

---

## ✅ Verification Commands

```bash
# 1. Check secrets created
aws secretsmanager list-secrets \
  --filters Key=name,Values=rupaya/rds

# 2. Verify IAM policies attached
aws iam get-role-policy \
  --role-name GitHubActionsRoleStaging \
  --policy-name SecretsManagerAccess

# 3. Test workflow locally
aws configure
aws secretsmanager get-secret-value \
  --secret-id rupaya/rds/staging

# 4. Monitor CloudTrail
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=ResourceName,AttributeValue=rupaya/rds/staging
```

---

## 🎯 Next Steps

1. **Read**: [infra/aws/SECRETS_MANAGER_SETUP.md](infra/aws/SECRETS_MANAGER_SETUP.md)
2. **Review**: [infra/aws/IAM_SECRETS_MANAGER_POLICY.md](infra/aws/IAM_SECRETS_MANAGER_POLICY.md)
3. **Deploy**: Follow Phase 1-5 in [RDS_MIGRATION_SUMMARY.md](RDS_MIGRATION_SUMMARY.md)
4. **Verify**: Use verification commands above
5. **Monitor**: Check CloudTrail and workflow logs
6. **Cleanup**: Remove old GitHub secrets after 1 week

---

## 🆘 Help

- Setup issues? → See [infra/aws/SECRETS_MANAGER_SETUP.md](infra/aws/SECRETS_MANAGER_SETUP.md#troubleshooting)
- IAM questions? → See [infra/aws/IAM_SECRETS_MANAGER_POLICY.md](infra/aws/IAM_SECRETS_MANAGER_POLICY.md)
- Workflow help? → See [.github/workflows/01-aws-rds-migrations.yml](.github/workflows/01-aws-rds-migrations.yml)
- Full details? → See [RDS_MIGRATION_SUMMARY.md](RDS_MIGRATION_SUMMARY.md)

---

**Time to Deploy**: 1-2 hours  
**Estimated Benefit**: Massive (zero credentials in GitHub + automatic rotation)
