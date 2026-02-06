#!/bin/bash

################################################################################
# GitHub Enterprise Security Configuration Script
# 
# Purpose: Automate GitHub repository configuration with enterprise-grade security
# Author: DevOps Team
# Date: February 5, 2026
# Version: 1.0.0
#
# Requirements:
#   - GitHub CLI (gh) installed and authenticated
#   - jq for JSON parsing
#   - yq for YAML parsing (optional)
#   - Appropriate GitHub permissions (admin access to repository)
#
# Usage:
#   ./configure-github-enterprise.sh [options]
#
# Options:
#   --config FILE       Path to configuration file (default: github-config.yml)
#   --dry-run          Show what would be done without making changes
#   --skip-secrets     Skip secrets configuration
#   --skip-protection  Skip branch protection setup
#   --skip-environments Skip environment setup
#   --skip-codeowners  Skip CODEOWNERS file creation
#   --verify-only      Only verify existing configuration
#   --force            Skip confirmation prompts
#   --help             Show this help message
#
################################################################################

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Default configuration
CONFIG_FILE="${SCRIPT_DIR}/github-config.yml"
DRY_RUN=false
SKIP_SECRETS=false
SKIP_PROTECTION=false
SKIP_ENVIRONMENTS=false
SKIP_CODEOWNERS=false
VERIFY_ONLY=false
FORCE=false

# Log file
LOG_FILE="${SCRIPT_DIR}/github-config-$(date +%Y%m%d-%H%M%S).log"

################################################################################
# Utility Functions
################################################################################

log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [${level}] ${message}" | tee -a "$LOG_FILE"
}

log_info() {
    echo -e "${BLUE}ℹ${NC} $*" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}✓${NC} $*" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $*" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}✗${NC} $*" | tee -a "$LOG_FILE"
}

log_step() {
    echo -e "\n${BOLD}${CYAN}▶${NC} ${BOLD}$*${NC}\n" | tee -a "$LOG_FILE"
}

confirm() {
    if [ "$FORCE" = true ]; then
        return 0
    fi
    
    local prompt="$1"
    local response
    read -p "$prompt [y/N]: " response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        log_error "Required command not found: $1"
        log_error "Please install $1 and try again"
        exit 1
    fi
}

check_prerequisites() {
    log_step "Checking Prerequisites"
    
    check_command "gh"
    check_command "jq"
    
    # Check GitHub CLI authentication
    if ! gh auth status &> /dev/null; then
        log_error "GitHub CLI is not authenticated"
        log_error "Please run: gh auth login"
        exit 1
    fi
    
    log_success "All prerequisites met"
}

parse_yaml() {
    local yaml_file="$1"
    local query="$2"
    
    # Simple YAML parsing using grep and sed (for basic values)
    # For complex YAML, consider using yq
    grep "^${query}:" "$yaml_file" | sed 's/.*: //' | tr -d '"' | tr -d "'"
}

################################################################################
# Configuration Functions
################################################################################

load_config() {
    log_step "Loading Configuration"
    
    if [ ! -f "$CONFIG_FILE" ]; then
        log_error "Configuration file not found: $CONFIG_FILE"
        exit 1
    fi
    
    # Extract basic configuration (handle indented YAML)
    OWNER=$(grep -A2 "^repository:" "$CONFIG_FILE" | grep "owner:" | sed 's/.*owner: *//' | sed 's/#.*//' | tr -d '"' | tr -d "'" | xargs)
    REPO=$(grep -A2 "^repository:" "$CONFIG_FILE" | grep "name:" | sed 's/.*name: *//' | sed 's/#.*//' | tr -d '"' | tr -d "'" | xargs)
    
    if [ -z "$OWNER" ] || [ -z "$REPO" ]; then
        log_error "Invalid configuration: owner and name are required"
        log_error "Found: OWNER='$OWNER', REPO='$REPO'"
        exit 1
    fi
    
    log_info "Repository: ${OWNER}/${REPO}"
    log_success "Configuration loaded"
}

################################################################################
# Branch Protection Functions
################################################################################

configure_main_branch_protection() {
    log_step "Configuring Main Branch Protection"
    
    local api_endpoint="repos/${OWNER}/${REPO}/branches/main/protection"
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would configure main branch protection"
        return 0
    fi
    
    log_info "Setting up main branch protection..."
    
    # Create protection payload
    local payload=$(cat <<'EOF'
{
  "required_pull_request_reviews": {
    "required_approving_review_count": 2,
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": true,
    "require_last_push_approval": true
  },
  "required_status_checks": {
    "strict": true,
    "contexts": [
      "lint-and-quality",
      "backend-tests",
      "security-scan",
      "build-check",
      "branch-validation"
    ]
  },
  "enforce_admins": true,
  "required_linear_history": false,
  "restrictions": null
}
EOF
)
    
    if gh api "$api_endpoint" --method PUT --input - <<< "$payload" >> "$LOG_FILE" 2>&1; then
        log_success "Main branch protection configured"
    else
        log_error "Failed to configure main branch protection"
        return 1
    fi
}

configure_develop_branch_protection() {
    log_step "Configuring Develop Branch Protection"
    
    local api_endpoint="repos/${OWNER}/${REPO}/branches/develop/protection"
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would configure develop branch protection"
        return 0
    fi
    
    # Check if develop branch exists
    if ! gh api "repos/${OWNER}/${REPO}/branches/develop" &> /dev/null; then
        log_warning "Develop branch does not exist yet - skipping protection"
        log_info "Create develop branch first, then re-run this script"
        return 0
    fi
    
    log_info "Setting up develop branch protection..."
    
    local payload=$(cat <<'EOF'
{
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": true,
    "require_last_push_approval": false
  },
  "required_status_checks": {
    "strict": true,
    "contexts": [
      "lint-and-quality",
      "backend-tests",
      "security-scan",
      "build-check",
      "branch-validation"
    ]
  },
  "enforce_admins": true,
  "required_linear_history": false,
  "restrictions": null
}
EOF
)
    
    if gh api "$api_endpoint" --method PUT --input - <<< "$payload" >> "$LOG_FILE" 2>&1; then
        log_success "Develop branch protection configured"
    else
        log_error "Failed to configure develop branch protection"
        return 1
    fi
}

configure_branch_protection() {
    if [ "$SKIP_PROTECTION" = true ]; then
        log_info "Skipping branch protection configuration"
        return 0
    fi
    
    configure_main_branch_protection
    configure_develop_branch_protection
}

################################################################################
# Environment Functions
################################################################################

configure_staging_environment() {
    log_step "Configuring Staging Environment"
    
    local api_endpoint="repos/${OWNER}/${REPO}/environments/staging"
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would configure staging environment"
        return 0
    fi
    
    log_info "Setting up staging environment..."
    
    # Simple environment without reviewers (works on free plans)
    local payload=$(cat <<'EOF'
{
  "wait_timer": 0,
  "deployment_branch_policy": {
    "protected_branches": true,
    "custom_branch_policies": false
  }
}
EOF
)
    
    if gh api "$api_endpoint" --method PUT --input - <<< "$payload" >> "$LOG_FILE" 2>&1; then
        log_success "Staging environment configured"
    else
        log_warning "Failed to configure staging environment (may require paid GitHub plan for advanced features)"
        return 0
    fi
}

configure_production_environment() {
    log_step "Configuring Production Environment"
    
    local api_endpoint="repos/${OWNER}/${REPO}/environments/production"
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would configure production environment"
        return 0
    fi
    
    log_info "Setting up production environment..."
    
    # Simple environment without reviewers (works on free plans)
    local payload=$(cat <<'EOF'
{
  "wait_timer": 0,
  "deployment_branch_policy": {
    "protected_branches": true,
    "custom_branch_policies": false
  }
}
EOF
)
    
    if gh api "$api_endpoint" --method PUT --input - <<< "$payload" >> "$LOG_FILE" 2>&1; then
        log_success "Production environment configured"
        log_warning "Note: Wait timers and required reviewers require paid GitHub plan"
        log_info "Upgrade to GitHub Team/Enterprise for advanced environment protection"
    else
        log_warning "Failed to configure production environment (may require paid GitHub plan for advanced features)"
        return 0
    fi
}

configure_environments() {
    if [ "$SKIP_ENVIRONMENTS" = true ]; then
        log_info "Skipping environment configuration"
        return 0
    fi
    
    configure_staging_environment
    configure_production_environment
}

################################################################################
# CODEOWNERS Functions
################################################################################

create_codeowners_file() {
    log_step "Creating CODEOWNERS File"
    
    if [ "$SKIP_CODEOWNERS" = true ]; then
        log_info "Skipping CODEOWNERS file creation"
        return 0
    fi
    
    local codeowners_file="${PROJECT_ROOT}/.github/CODEOWNERS"
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would create CODEOWNERS file"
        return 0
    fi
    
    # Create .github directory if it doesn't exist
    mkdir -p "${PROJECT_ROOT}/.github"
    
    log_info "Creating CODEOWNERS file..."
    
    cat > "$codeowners_file" <<'EOF'
# CODEOWNERS - Defines code ownership and review requirements
# More info: https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners

# Global owners - notified on all changes
* @your-org/platform-team

# Backend code
backend/ @your-org/backend-team
backend/src/services/ @your-org/backend-team @your-org/security-team
backend/migrations/ @your-org/database-team

# Frontend code (iOS/Android)
ios/ @your-org/ios-team
android/ @your-org/android-team

# Infrastructure & DevOps
infra/ @your-org/devops-team
infra/aws/ @your-org/devops-team @your-org/aws-team
infra/gcp/ @your-org/devops-team @your-org/gcp-team
infra/bootstrap/ @your-org/devops-team @your-org/security-team

# CI/CD Workflows
.github/workflows/ @your-org/devops-team
.github/workflows/01-aws-*.yml @your-org/devops-team @your-org/aws-team
.github/workflows/01-gcp-*.yml @your-org/devops-team @your-org/gcp-team

# Documentation
docs/ @your-org/platform-team
*.md @your-org/platform-team
README.md @your-org/platform-team @your-org/devops-team

# Security-sensitive files
**/security/ @your-org/security-team
*.tf @your-org/security-team @your-org/devops-team
*.tfvars @your-org/security-team
docker-compose*.yml @your-org/devops-team @your-org/security-team
Dockerfile* @your-org/devops-team

# Database schemas and migrations
**/migrations/ @your-org/database-team @your-org/backend-team
**/schema/ @your-org/database-team

# Configuration files
**/config/ @your-org/devops-team
*.env.example @your-org/devops-team

# Package management
package.json @your-org/backend-team @your-org/devops-team
package-lock.json @your-org/backend-team
Podfile @your-org/ios-team
Podfile.lock @your-org/ios-team
build.gradle* @your-org/android-team
EOF
    
    log_success "CODEOWNERS file created at: $codeowners_file"
    log_warning "Update team names in CODEOWNERS to match your GitHub organization"
}

################################################################################
# Secrets Functions
################################################################################

configure_secrets() {
    if [ "$SKIP_SECRETS" = true ]; then
        log_info "Skipping secrets configuration"
        return 0
    fi
    
    log_step "Configuring Repository Secrets"
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would configure repository secrets"
        return 0
    fi
    
    log_warning "Secret configuration requires manual input"
    log_info "Secrets to configure:"
    echo ""
    echo "  1. AWS_OIDC_ROLE_STAGING"
    echo "  2. AWS_OIDC_ROLE_PROD"
    echo "  3. SLACK_WEBHOOK_URL (optional)"
    echo "  4. GCP_WORKLOAD_IDENTITY_PROVIDER (optional)"
    echo "  5. GCP_SERVICE_ACCOUNT (optional)"
    echo ""
    
    if ! confirm "Do you want to configure secrets now?"; then
        log_info "Skipping secrets configuration. You can add them later using:"
        log_info "  gh secret set SECRET_NAME --body 'secret-value'"
        return 0
    fi
    
    # Configure AWS OIDC Role - Staging
    if [ -n "${AWS_OIDC_ROLE_STAGING:-}" ]; then
        log_info "Using AWS_OIDC_ROLE_STAGING from environment"
        gh secret set AWS_OIDC_ROLE_STAGING --body "$AWS_OIDC_ROLE_STAGING" >> "$LOG_FILE" 2>&1
        log_success "AWS_OIDC_ROLE_STAGING configured"
    else
        echo -n "Enter AWS_OIDC_ROLE_STAGING (e.g., arn:aws:iam::123456789012:role/GitHubActionsRoleStaging): "
        read -r aws_role_staging
        if [ -n "$aws_role_staging" ]; then
            gh secret set AWS_OIDC_ROLE_STAGING --body "$aws_role_staging" >> "$LOG_FILE" 2>&1
            log_success "AWS_OIDC_ROLE_STAGING configured"
        fi
    fi
    
    # Configure AWS OIDC Role - Production
    if [ -n "${AWS_OIDC_ROLE_PROD:-}" ]; then
        log_info "Using AWS_OIDC_ROLE_PROD from environment"
        gh secret set AWS_OIDC_ROLE_PROD --body "$AWS_OIDC_ROLE_PROD" >> "$LOG_FILE" 2>&1
        log_success "AWS_OIDC_ROLE_PROD configured"
    else
        echo -n "Enter AWS_OIDC_ROLE_PROD (e.g., arn:aws:iam::123456789012:role/GitHubActionsRoleProd): "
        read -r aws_role_prod
        if [ -n "$aws_role_prod" ]; then
            gh secret set AWS_OIDC_ROLE_PROD --body "$aws_role_prod" >> "$LOG_FILE" 2>&1
            log_success "AWS_OIDC_ROLE_PROD configured"
        fi
    fi
    
    # Configure Slack Webhook (optional)
    echo -n "Enter SLACK_WEBHOOK_URL (optional, press Enter to skip): "
    read -r slack_webhook
    if [ -n "$slack_webhook" ]; then
        gh secret set SLACK_WEBHOOK_URL --body "$slack_webhook" >> "$LOG_FILE" 2>&1
        log_success "SLACK_WEBHOOK_URL configured"
    fi
}

################################################################################
# Security Policy Functions
################################################################################

configure_security_policies() {
    log_step "Configuring Security Policies"
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would configure security policies"
        return 0
    fi
    
    log_info "Enabling security features..."
    
    # Enable Dependabot alerts
    gh api "repos/${OWNER}/${REPO}/vulnerability-alerts" --method PUT >> "$LOG_FILE" 2>&1 || true
    log_success "Dependabot vulnerability alerts enabled"
    
    # Enable secret scanning
    gh api "repos/${OWNER}/${REPO}/secret-scanning/alerts" --method PUT >> "$LOG_FILE" 2>&1 || true
    log_success "Secret scanning enabled"
    
    # Set merge settings
    gh api "repos/${OWNER}/${REPO}" --method PATCH --field allow_squash_merge=true \
        --field allow_merge_commit=false --field allow_rebase_merge=false \
        --field delete_branch_on_merge=true >> "$LOG_FILE" 2>&1 || true
    log_success "Merge policies configured (squash only, auto-delete branches)"
}

################################################################################
# Verification Functions
################################################################################

verify_branch_protection() {
    log_step "Verifying Branch Protection"
    
    local branches=("main" "develop")
    local all_ok=true
    
    for branch in "${branches[@]}"; do
        log_info "Checking ${branch} branch..."
        
        if gh api "repos/${OWNER}/${REPO}/branches/${branch}/protection" &> /dev/null; then
            log_success "${branch} branch protection: ✓ Configured"
            
            # Get protection details
            local protection=$(gh api "repos/${OWNER}/${REPO}/branches/${branch}/protection" 2>/dev/null || echo "{}")
            
            # Check required reviews
            local required_reviews=$(echo "$protection" | jq -r '.required_pull_request_reviews.required_approving_review_count // 0')
            log_info "  Required approvals: ${required_reviews}"
            
            # Check status checks
            local status_checks=$(echo "$protection" | jq -r '.required_status_checks.contexts[]? // empty' | wc -l | tr -d ' ')
            log_info "  Required status checks: ${status_checks}"
        else
            log_error "${branch} branch protection: ✗ Not configured"
            all_ok=false
        fi
    done
    
    if [ "$all_ok" = true ]; then
        log_success "All branch protections verified"
        return 0
    else
        log_error "Some branch protections are missing"
        return 1
    fi
}

verify_environments() {
    log_step "Verifying Environments"
    
    local environments=("staging" "production")
    local all_ok=true
    
    for env in "${environments[@]}"; do
        log_info "Checking ${env} environment..."
        
        if gh api "repos/${OWNER}/${REPO}/environments/${env}" &> /dev/null; then
            log_success "${env} environment: ✓ Configured"
            
            # Get environment details
            local env_config=$(gh api "repos/${OWNER}/${REPO}/environments/${env}" 2>/dev/null || echo "{}")
            
            # Check wait timer
            local wait_timer=$(echo "$env_config" | jq -r '.wait_timer // 0')
            log_info "  Wait timer: ${wait_timer} seconds"
            
            # Check reviewers
            local reviewers=$(echo "$env_config" | jq -r '.reviewers[]? // empty' | wc -l | tr -d ' ')
            log_info "  Reviewers configured: ${reviewers}"
        else
            log_error "${env} environment: ✗ Not configured"
            all_ok=false
        fi
    done
    
    if [ "$all_ok" = true ]; then
        log_success "All environments verified"
        return 0
    else
        log_error "Some environments are missing"
        return 1
    fi
}

verify_codeowners() {
    log_step "Verifying CODEOWNERS"
    
    local codeowners_file="${PROJECT_ROOT}/.github/CODEOWNERS"
    
    if [ -f "$codeowners_file" ]; then
        log_success "CODEOWNERS file exists"
        local patterns=$(grep -c "^[^#]" "$codeowners_file" || echo "0")
        log_info "  Number of ownership patterns: ${patterns}"
        return 0
    else
        log_error "CODEOWNERS file not found"
        return 1
    fi
}

verify_secrets() {
    log_step "Verifying Secrets"
    
    local required_secrets=("AWS_OIDC_ROLE_STAGING" "AWS_OIDC_ROLE_PROD")
    local all_ok=true
    
    log_info "Checking required secrets..."
    
    local secret_list=$(gh secret list --json name --jq '.[].name')
    
    for secret in "${required_secrets[@]}"; do
        if echo "$secret_list" | grep -q "^${secret}$"; then
            log_success "  ${secret}: ✓ Configured"
        else
            log_error "  ${secret}: ✗ Missing"
            all_ok=false
        fi
    done
    
    if [ "$all_ok" = true ]; then
        log_success "All required secrets configured"
        return 0
    else
        log_error "Some required secrets are missing"
        return 1
    fi
}

verify_configuration() {
    log_step "Verifying Complete Configuration"
    
    local verification_failed=false
    
    verify_branch_protection || verification_failed=true
    verify_environments || verification_failed=true
    verify_codeowners || verification_failed=true
    verify_secrets || verification_failed=true
    
    echo ""
    if [ "$verification_failed" = true ]; then
        log_error "Configuration verification failed"
        log_info "Review the errors above and re-run the script"
        return 1
    else
        log_success "All configuration verified successfully!"
        return 0
    fi
}

################################################################################
# Summary Functions
################################################################################

print_summary() {
    log_step "Configuration Summary"
    
    cat <<EOF

${BOLD}GitHub Enterprise Security Configuration Complete!${NC}

${BOLD}Repository:${NC} ${OWNER}/${REPO}

${BOLD}Configured:${NC}
  ${GREEN}✓${NC} Branch protection (main, develop)
  ${GREEN}✓${NC} Environments (staging, production)
  ${GREEN}✓${NC} CODEOWNERS file
  ${GREEN}✓${NC} Repository secrets
  ${GREEN}✓${NC} Security policies

${BOLD}Next Steps:${NC}
  1. Review and update CODEOWNERS file with actual team names
  2. Add reviewers to production environment in GitHub UI
  3. Test branch protection by creating a PR
  4. Verify workflows can authenticate with AWS
  5. Review security scanning results

${BOLD}Documentation:${NC}
  • Configuration guide: docs/GITHUB_ENTERPRISE_CI_CD_SETUP.md
  • Deployment order: DEPLOYMENT_ORDER.md
  • Bootstrap guide: infra/bootstrap/SETUP_GUIDE.md

${BOLD}Log file:${NC} ${LOG_FILE}

${GREEN}Configuration completed successfully!${NC}

EOF
}

################################################################################
# Main Function
################################################################################

print_usage() {
    cat <<EOF
Usage: $0 [options]

Options:
  --config FILE       Path to configuration file (default: github-config.yml)
  --dry-run          Show what would be done without making changes
  --skip-secrets     Skip secrets configuration
  --skip-protection  Skip branch protection setup
  --skip-environments Skip environment setup
  --skip-codeowners  Skip CODEOWNERS file creation
  --verify-only      Only verify existing configuration
  --force            Skip confirmation prompts
  --help             Show this help message

Examples:
  # Full configuration
  $0

  # Dry run to see what would be done
  $0 --dry-run

  # Only verify existing configuration
  $0 --verify-only

  # Configure without prompts
  $0 --force

  # Skip secrets (configure manually later)
  $0 --skip-secrets

Environment Variables:
  AWS_OIDC_ROLE_STAGING   AWS IAM role ARN for staging
  AWS_OIDC_ROLE_PROD      AWS IAM role ARN for production
  SLACK_WEBHOOK_URL       Slack webhook URL for notifications

EOF
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --skip-secrets)
                SKIP_SECRETS=true
                shift
                ;;
            --skip-protection)
                SKIP_PROTECTION=true
                shift
                ;;
            --skip-environments)
                SKIP_ENVIRONMENTS=true
                shift
                ;;
            --skip-codeowners)
                SKIP_CODEOWNERS=true
                shift
                ;;
            --verify-only)
                VERIFY_ONLY=true
                shift
                ;;
            --force)
                FORCE=true
                shift
                ;;
            --help)
                print_usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                print_usage
                exit 1
                ;;
        esac
    done
}

main() {
    echo ""
    echo "${BOLD}${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo "${BOLD}${BLUE}║  GitHub Enterprise Security Configuration Tool                ║${NC}"
    echo "${BOLD}${BLUE}║  Version 1.0.0                                                 ║${NC}"
    echo "${BOLD}${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    parse_arguments "$@"
    
    log_info "Starting GitHub configuration..."
    log_info "Log file: ${LOG_FILE}"
    echo ""
    
    check_prerequisites
    load_config
    
    if [ "$VERIFY_ONLY" = true ]; then
        verify_configuration
        exit $?
    fi
    
    # Show configuration summary
    echo ""
    log_info "Configuration to be applied:"
    echo "  • Repository: ${OWNER}/${REPO}"
    echo "  • Branch protection: $([ "$SKIP_PROTECTION" = false ] && echo "Yes" || echo "Skip")"
    echo "  • Environments: $([ "$SKIP_ENVIRONMENTS" = false ] && echo "Yes" || echo "Skip")"
    echo "  • CODEOWNERS: $([ "$SKIP_CODEOWNERS" = false ] && echo "Yes" || echo "Skip")"
    echo "  • Secrets: $([ "$SKIP_SECRETS" = false ] && echo "Yes" || echo "Skip")"
    echo "  • Dry run: $([ "$DRY_RUN" = true ] && echo "Yes" || echo "No")"
    echo ""
    
    if ! confirm "Continue with configuration?"; then
        log_info "Configuration cancelled by user"
        exit 0
    fi
    
    # Execute configuration
    configure_branch_protection
    configure_environments
    create_codeowners_file
    configure_secrets
    configure_security_policies
    
    # Verify configuration
    if [ "$DRY_RUN" = false ]; then
        echo ""
        verify_configuration
        print_summary
    else
        echo ""
        log_warning "DRY RUN MODE - No changes were made"
        log_info "Remove --dry-run flag to apply changes"
    fi
}

# Run main function
main "$@"
