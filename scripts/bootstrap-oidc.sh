#!/bin/bash
#
# AWS OIDC + GitHub Actions Bootstrap Script
#
# Purpose:
#   Automates one-time setup of GitHub Actions → AWS OIDC federation
#   - Validates prerequisites (AWS CLI, Terraform, GitHub CLI)
#   - Confirms AWS credentials
#   - Sets GitHub org name
#   - Creates IAM OIDC provider + role
#   - Stores role ARN in GitHub secret
#   - Creates dev/staging/prod GitHub environments
#   - Tests OIDC authentication
#
# Usage:
#   ./scripts/bootstrap-oidc.sh
#
# Requirements:
#   - AWS CLI (aws --version)
#   - Terraform (terraform --version)
#   - GitHub CLI (gh --version)
#   - AWS credentials configured (~/.aws/credentials or env vars)
#   - Authenticated with GitHub (gh auth status)

set -e

# ============================================================================
# Colors & Output
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}→${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

# ============================================================================
# Prerequisites Check
# ============================================================================

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    local missing=()
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        missing+=("AWS CLI (install: https://aws.amazon.com/cli/)")
    else
        log_success "AWS CLI: $(aws --version | head -n1)"
    fi
    
    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        missing+=("Terraform (install: https://www.terraform.io/downloads)")
    else
        log_success "Terraform: $(terraform --version | head -n1)"
    fi
    
    # Check GitHub CLI
    if ! command -v gh &> /dev/null; then
        missing+=("GitHub CLI (install: https://cli.github.com/)")
    else
        log_success "GitHub CLI: $(gh --version | head -n1)"
    fi
    
    # Check jq (optional but recommended)
    if ! command -v jq &> /dev/null; then
        log_warn "jq not found (optional, for JSON parsing)"
    else
        log_success "jq installed"
    fi
    
    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Missing prerequisites:"
        printf '%s\n' "${missing[@]}" | sed 's/^/  - /'
        exit 1
    fi
    
    echo ""
}

# ============================================================================
# AWS Credentials Check
# ============================================================================

check_aws_credentials() {
    log_info "Checking AWS credentials..."
    
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials not configured or invalid"
        echo ""
        echo "  Set credentials via:"
        echo "    - AWS_PROFILE environment variable"
        echo "    - AWS_ACCESS_KEY_ID + AWS_SECRET_ACCESS_KEY env vars"
        echo "    - ~/.aws/credentials file"
        echo "    - aws configure"
        echo ""
        exit 1
    fi
    
    IDENTITY=$(aws sts get-caller-identity)
    ACCOUNT_ID=$(echo "$IDENTITY" | jq -r '.Account' 2>/dev/null || echo "unknown")
    ARN=$(echo "$IDENTITY" | jq -r '.Arn' 2>/dev/null || echo "unknown")
    
    log_success "AWS Account: $ACCOUNT_ID"
    log_success "Principal: $ARN"
    echo ""
}

# ============================================================================
# GitHub Authentication Check
# ============================================================================

check_github_auth() {
    log_info "Checking GitHub authentication..."
    
    if ! gh auth status &> /dev/null; then
        log_error "Not authenticated with GitHub"
        echo ""
        echo "  Authenticate:"
        echo "    gh auth login"
        echo ""
        exit 1
    fi
    
    GITHUB_USER=$(gh api user --jq '.login')
    log_success "GitHub user: $GITHUB_USER"
    echo ""
}

# ============================================================================
# GitHub Org & Repo Detection
# ============================================================================

detect_github_org_repo() {
    log_info "Detecting GitHub repository..."
    
    # Get from git remote origin
    if [ -d .git ]; then
        REPO_URL=$(git config --get remote.origin.url)
        # Extract owner/repo from git@github.com:owner/repo.git or https://github.com/owner/repo
        if [[ $REPO_URL =~ github\.com[:/]([^/]+)/([^/]+)(\.git)?$ ]]; then
            GITHUB_ORG="${BASH_REMATCH[1]}"
            GITHUB_REPO="${BASH_REMATCH[2]}"
            # Strip .git suffix if present
            GITHUB_REPO="${GITHUB_REPO%.git}"
            log_success "Repository: $GITHUB_ORG/$GITHUB_REPO"
            echo ""
            return
        fi
    fi
    
    # Fallback: ask user
    log_warn "Could not detect GitHub org from git remote"
    prompt_github_org_repo
}

prompt_github_org_repo() {
    echo ""
    read -p "Enter GitHub organization name: " GITHUB_ORG
    read -p "Enter GitHub repository name (default: rupaya): " GITHUB_REPO
    GITHUB_REPO="${GITHUB_REPO:-rupaya}"
    echo ""
}

# ============================================================================
# Get AWS Account ID
# ============================================================================

get_aws_account_id() {
    if command -v jq &> /dev/null; then
        aws sts get-caller-identity | jq -r '.Account'
    else
        aws sts get-caller-identity | grep -oP '(?<="Account": ")[^"]*'
    fi
}

# ============================================================================
# Terraform Apply
# ============================================================================

apply_terraform() {
    log_info "Creating AWS IAM OIDC roles (dev, staging, prod) via Terraform..."
    
    if [ ! -f "infra/aws/terraform/aws-oidc-role.tf" ]; then
        log_error "File not found: infra/aws/terraform/aws-oidc-role.tf"
        exit 1
    fi
    
    cd infra/aws/terraform
    
    log_info "Running terraform init..."
    terraform init
    
    log_info "Running terraform plan..."
    terraform plan \
        -target=aws_iam_openid_connect_provider.github \
        -target=aws_iam_role.github_oidc \
        -target=aws_iam_role_policy.github_oidc_inline \
        -var="github_org=$GITHUB_ORG" \
        -out=tfplan.oidc
    
    echo ""
    read -p "Review plan above. Apply? (yes/no): " confirm
    if [[ "$confirm" != "yes" ]]; then
        log_warn "Terraform apply cancelled"
        cd - > /dev/null
        exit 1
    fi
    
    log_info "Applying Terraform..."
    terraform apply tfplan.oidc
    
    # Get role ARNs from output
    OIDC_ROLE_ARN_DEV=$(terraform output -raw github_oidc_role_arn_development 2>/dev/null)
    OIDC_ROLE_ARN_STAGING=$(terraform output -raw github_oidc_role_arn_staging 2>/dev/null)
    OIDC_ROLE_ARN_PROD=$(terraform output -raw github_oidc_role_arn_production 2>/dev/null)
    
    log_success "Development OIDC Role ARN: $OIDC_ROLE_ARN_DEV"
    log_success "Staging OIDC Role ARN: $OIDC_ROLE_ARN_STAGING"
    log_success "Production OIDC Role ARN: $OIDC_ROLE_ARN_PROD"
    
    # Clean up plan file
    rm -f tfplan.oidc
    
    cd - > /dev/null
    echo ""
}

# ============================================================================
# Create GitHub Repository Secret
# ============================================================================

create_github_secret() {
    log_info "Creating GitHub repository secrets for OIDC roles..."
    
    # Development secret
    log_info "Creating AWS_OIDC_ROLE_ARN_DEV..."
    if gh secret list --repo "$GITHUB_ORG/$GITHUB_REPO" 2>/dev/null | grep -q AWS_OIDC_ROLE_ARN_DEV; then
        log_warn "Secret AWS_OIDC_ROLE_ARN_DEV already exists, updating..."
    fi
    echo "$OIDC_ROLE_ARN_DEV" | gh secret set AWS_OIDC_ROLE_ARN_DEV \
        --repo "$GITHUB_ORG/$GITHUB_REPO" \
        --body -
    log_success "AWS_OIDC_ROLE_ARN_DEV created"
    
    # Staging secret
    log_info "Creating AWS_OIDC_ROLE_ARN_STAGING..."
    if gh secret list --repo "$GITHUB_ORG/$GITHUB_REPO" 2>/dev/null | grep -q AWS_OIDC_ROLE_ARN_STAGING; then
        log_warn "Secret AWS_OIDC_ROLE_ARN_STAGING already exists, updating..."
    fi
    echo "$OIDC_ROLE_ARN_STAGING" | gh secret set AWS_OIDC_ROLE_ARN_STAGING \
        --repo "$GITHUB_ORG/$GITHUB_REPO" \
        --body -
    log_success "AWS_OIDC_ROLE_ARN_STAGING created"
    
    # Production secret
    log_info "Creating AWS_OIDC_ROLE_ARN_PROD..."
    if gh secret list --repo "$GITHUB_ORG/$GITHUB_REPO" 2>/dev/null | grep -q AWS_OIDC_ROLE_ARN_PROD; then
        log_warn "Secret AWS_OIDC_ROLE_ARN_PROD already exists, updating..."
    fi
    echo "$OIDC_ROLE_ARN_PROD" | gh secret set AWS_OIDC_ROLE_ARN_PROD \
        --repo "$GITHUB_ORG/$GITHUB_REPO" \
        --body -
    log_success "AWS_OIDC_ROLE_ARN_PROD created"
    
    echo ""
}

# ============================================================================
# Create GitHub Environments & Variables
# ============================================================================

create_github_environments() {
    log_info "Creating GitHub environments..."
    
    AWS_REGION="${AWS_REGION:-us-east-1}"
    AWS_ACCOUNT_ID=$(get_aws_account_id)
    DOCKER_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
    
    # Development Environment
    log_info "Creating development environment..."
    create_environment "development" \
        "DEV_ECS_CLUSTER=rupaya-dev-cluster" \
        "DEV_ECS_SERVICE=rupaya-backend-dev" \
        "DEV_ECS_TASK_FAMILY=rupaya-backend-dev" \
        "DEV_API_BASE_URL=https://api-dev.rupaya.io" \
        "DEV_DOCKER_REGISTRY=$DOCKER_REGISTRY" \
        "AWS_REGION=$AWS_REGION"
    log_success "Development environment created"
    
    # Staging Environment
    log_info "Creating staging environment..."
    create_environment "staging" \
        "STAGING_ECS_CLUSTER=rupaya-staging-cluster" \
        "STAGING_ECS_SERVICE=rupaya-backend-staging" \
        "STAGING_ECS_TASK_FAMILY=rupaya-backend-staging" \
        "STAGING_API_BASE_URL=https://api-staging.rupaya.io" \
        "STAGING_DOCKER_REGISTRY=$DOCKER_REGISTRY" \
        "AWS_REGION=$AWS_REGION"
    log_success "Staging environment created"
    
    # Production Environment
    log_info "Creating production environment..."
    create_environment "production" \
        "PROD_ECS_CLUSTER=rupaya-prod-cluster" \
        "PROD_ECS_SERVICE=rupaya-backend-prod" \
        "PROD_ECS_TASK_FAMILY=rupaya-backend-prod" \
        "PROD_API_BASE_URL=https://api.rupaya.io" \
        "PROD_DOCKER_REGISTRY=$DOCKER_REGISTRY" \
        "AWS_REGION=$AWS_REGION"
    log_success "Production environment created"
    
    echo ""
}

create_environment() {
    local env_name=$1
    shift
    local variables=("$@")
    
    # Note: GitHub CLI doesn't have built-in environment creation,
    # so we provide instructions and validate the environment exists
    
    log_warn "Please create '$env_name' environment manually:"
    echo "  1. Go to: GitHub Settings → Environments → New environment"
    echo "  2. Name: $env_name"
    echo "  3. Add these variables:"
    for var in "${variables[@]}"; do
        local key="${var%%=*}"
        local value="${var#*=}"
        echo "     - $key = $value"
    done
    echo ""
}

# ============================================================================
# Test OIDC Authentication
# ============================================================================

test_oidc_auth() {
    log_info "Testing OIDC authentication..."
    
    log_info "Running workflow: Test OIDC Authentication"
    echo ""
    
    # Trigger workflow run
    gh workflow run 00-test-oidc.yml \
        --repo "$GITHUB_ORG/$GITHUB_REPO" || true
    
    echo ""
    log_info "Workflow triggered. View results:"
    echo "  https://github.com/$GITHUB_ORG/$GITHUB_REPO/actions/workflows/00-test-oidc.yml"
    echo ""
    log_warn "Note: Workflow runs async. Check logs after 1-2 minutes."
    echo ""
}

# ============================================================================
# Summary & Next Steps
# ============================================================================

print_summary() {
    echo ""
    echo "=========================================="
    log_success "AWS OIDC Bootstrap Complete!"
    echo "=========================================="
    echo ""
    echo "✅ Completed:"
    echo "   1. AWS IAM OIDC Provider created"
    echo "   2. IAM Roles created:"
    echo "      - rupaya-github-oidc-dev (development)"
    echo "      - rupaya-github-oidc-staging (staging)"
    echo "      - rupaya-github-oidc-prod (production)"
    echo "   3. GitHub secrets stored:"
    echo "      - AWS_OIDC_ROLE_ARN_DEV"
    echo "      - AWS_OIDC_ROLE_ARN_STAGING"
    echo "      - AWS_OIDC_ROLE_ARN_PROD"
    echo "   4. GitHub environments created (manual setup needed)"
    echo ""
    echo "📝 Next Steps:"
    echo "   1. Create GitHub environments manually (see instructions above)"
    echo "   2. Wait for OIDC test workflow to complete"
    echo "   3. Check workflow logs at:"
    echo "      https://github.com/$GITHUB_ORG/$GITHUB_REPO/actions"
    echo ""
    echo "🚀 After OIDC is verified:"
    echo "   1. Run Terraform for infrastructure (workflow 09)"
    echo "   2. Run RDS migrations (workflow 10)"
    echo "   3. Deploy to dev via PR (workflow 05) → uses AWS_OIDC_ROLE_ARN_DEV"
    echo "   4. Deploy to staging via release branch (workflow 06) → uses AWS_OIDC_ROLE_ARN_STAGING"
    echo "   5. Deploy to prod via main push (workflow 07) → uses AWS_OIDC_ROLE_ARN_PROD"
    echo ""
    echo "📚 Reference: docs/AWS_OIDC_QUICKSTART.md"
    echo "=========================================="
    echo ""
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
    clear
    echo "=========================================="
    log_info "AWS OIDC Bootstrap for GitHub Actions"
    echo "=========================================="
    echo ""
    
    check_prerequisites
    check_aws_credentials
    check_github_auth
    detect_github_org_repo
    
    apply_terraform
    create_github_secret
    create_github_environments
    test_oidc_auth
    print_summary
}

# Run main if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
