# Rupaya Utility Scripts

This folder contains scripts for data management, testing, automation, and GitHub enterprise configuration.

## 🔧 Data Management Scripts
- `add_remaining_txns.py` - Add remaining transactions
- `check_app_data.py` - Verify application data
- `check_dashboard.py` - Dashboard validation
- `check_transactions.py` - Transaction verification
- `create_test_data.py` - Generate test data
- `manage.sh` - Management utilities
- `quick_check.py` - Quick validation checks
- `verify_data.py` - Data verification

## 🔐 GitHub Enterprise Configuration

### Files

**`github-config.yml`** - Configuration file defining security policies, branch protection, environments, and CODEOWNERS patterns

**`configure-github-enterprise.sh`** - Automated GitHub repository configuration script with enterprise-grade security

### Quick Start

1. **Install prerequisites**:
   ```bash
   brew install gh jq
   gh auth login
   ```

2. **Update configuration**:
   ```bash
   vim github-config.yml
   # Update 'owner' and team names
   ```

3. **Dry run** (see what would be done):
   ```bash
   ./configure-github-enterprise.sh --dry-run
   ```

4. **Apply configuration**:
   ```bash
   ./configure-github-enterprise.sh
   ```

5. **Verify**:
   ```bash
   ./configure-github-enterprise.sh --verify-only
   ```

### Features

✅ Branch protection (main, develop, release/*, hotfix/*)  
✅ Environment protection (staging, production)  
✅ CODEOWNERS file generation  
✅ Repository secrets configuration  
✅ Security policy enforcement  
✅ Compliance controls (SOC2, PCI-DSS)  
✅ Dry-run mode  
✅ Comprehensive logging  

### Security Configuration Includes

- **Branch Protection**: 2 approvals for main, 1 for develop, signed commits
- **Environment Protection**: 5-minute wait timer for production, required reviewers
- **CODEOWNERS**: Automatic code review assignments by file pattern
- **Secrets**: OIDC role ARNs, Slack webhooks (no credentials in GitHub)
- **Security Policies**: Secret scanning, Dependabot, vulnerability alerts

### Usage Examples

```bash
# Full configuration (interactive)
./configure-github-enterprise.sh

# Dry run
./configure-github-enterprise.sh --dry-run

# Skip secrets (configure later)
./configure-github-enterprise.sh --skip-secrets

# Non-interactive with environment variables
export AWS_OIDC_ROLE_STAGING="arn:aws:iam::123456789012:role/GitHubActionsRoleStaging"
export AWS_OIDC_ROLE_PROD="arn:aws:iam::123456789012:role/GitHubActionsRoleProd"
./configure-github-enterprise.sh --force

# Verify existing configuration
./configure-github-enterprise.sh --verify-only
```

### Options

```
--config FILE       Path to configuration file (default: github-config.yml)
--dry-run          Show what would be done without making changes
--skip-secrets     Skip secrets configuration
--skip-protection  Skip branch protection setup
--skip-environments Skip environment setup
--skip-codeowners  Skip CODEOWNERS file creation
--verify-only      Only verify existing configuration
--force            Skip confirmation prompts
--help             Show help message
```

### Before Running

- [ ] Update `owner` in `github-config.yml`
- [ ] Update team names in CODEOWNERS patterns
- [ ] Prepare AWS role ARNs (from bootstrap setup)
- [ ] Ensure admin access to repository
- [ ] Run dry-run first to preview changes

### Related Documentation

- [GitHub Enterprise CI/CD Setup](../docs/GITHUB_ENTERPRISE_CI_CD_SETUP.md)
- [Deployment Order](../DEPLOYMENT_ORDER.md)
- [Bootstrap Setup Guide](../infra/bootstrap/SETUP_GUIDE.md)

---

See individual files for detailed usage instructions.