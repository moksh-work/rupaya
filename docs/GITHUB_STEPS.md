# GitHub Setup Steps - Rupaya

**Date**: February 6, 2026  
**Audience**: DevOps + Engineering  

---

## 1) Prerequisites
- GitHub CLI installed
- Admin access to the repository
- AWS OIDC role ARNs ready (from infra/bootstrap/SETUP_GUIDE.md)

Install and authenticate GitHub CLI:
```bash
brew install gh jq
gh auth login
```

---

## 2) Update GitHub configuration file
Edit the configuration file to match your org/team names:
```bash
cd scripts
vim github-config.yml
```

Update:
- `owner`
- Team names in CODEOWNERS patterns
- Environment names (if needed)

---

## 3) Run GitHub enterprise configuration script
Dry-run first:
```bash
./configure-github-enterprise.sh --dry-run
```

Apply configuration:
```bash
./configure-github-enterprise.sh
```

Verify configuration:
```bash
./configure-github-enterprise.sh --verify-only
```

---

## 4) Add required GitHub secrets (OIDC)
```bash
gh secret set AWS_OIDC_ROLE_STAGING \
  --body "arn:aws:iam::YOUR_ACCOUNT:role/GitHubActionsRoleStaging"

gh secret set AWS_OIDC_ROLE_PROD \
  --body "arn:aws:iam::YOUR_ACCOUNT:role/GitHubActionsRoleProd"
```

Optional Slack notifications:
```bash
gh secret set SLACK_WEBHOOK_URL \
  --body "https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
```

---

## 5) Confirm repository settings
- Branch protection enabled for `main`, `develop`, `release/*`
- CODEOWNERS auto-review active
- Required status checks configured
- Environments created (staging, production)

---

## 6) Test workflow trigger
From GitHub UI:
- Actions → Terraform Staged Deploy
- Run workflow with `auto_apply=false`

Or via CLI:
```bash
gh workflow run 01-common-terraform-staged-deploy.yml --ref main -f auto_apply=false
```

Monitor:
```bash
gh run list -R rsingh/rupaya --workflow=01-common-terraform-staged-deploy.yml -L 5
```

---

## 7) Team workflow (Git Flow)
- Start new work from `develop`
- Use `feature/*`, `release/*`, `hotfix/*` branches
- Follow approvals and status checks before merge

Reference: GIT_FLOW_GUIDE.md

---

## 8) Troubleshooting
- Review logs: `scripts/github-config-*.log`
- Verify branch rules in GitHub Settings → Branches
- Re-run verification: `./configure-github-enterprise.sh --verify-only`

---

## 9) Related documentation
- GIT_FLOW_GUIDE.md
- GITHUB_CONFIGURATION_SUMMARY.md
- docs/GITHUB_ENTERPRISE_CI_CD_SETUP.md
- DEPLOYMENT_ORDER.md
- infra/bootstrap/SETUP_GUIDE.md
