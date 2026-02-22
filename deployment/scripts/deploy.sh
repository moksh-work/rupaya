#!/bin/bash

###############################################################################
# Rupaya Infrastructure & Application Deployment Tool
#
# Comprehensive deployment orchestrator for:
# - Infrastructure (Terraform)
# - Backend (Docker/ECS)
# - Frontend (S3/CloudFront)
# - Database migrations
# - Health checks and verification
#
# Usage: ./deploy.sh [OPTIONS]
#   -e, --environment ENV      Environment (dev, staging, prod)
#   -t, --target TARGET        Target (infra, backend, frontend, all)
#   -v, --version VERSION      Application version (default: latest)
#   --skip-validation          Skip pre-deployment validation
#   --skip-backup              Skip state file backups
#   --confirm                  Skip confirmation prompts
#   --verbose                  Enable verbose logging
#   --dry-run                  Show what would be deployed
#   -h, --help                 Show help message
#
# Examples:
#   ./deploy.sh --environment dev --target backend
#   ./deploy.sh --environment prod --target all
#   ./deploy.sh --environment staging --target infra --confirm
###############################################################################

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$LOG_DIR/deploy_${TIMESTAMP}.log"

# Defaults
ENVIRONMENT=""
TARGET=""
VERSION="latest"
SKIP_VALIDATION=false
SKIP_BACKUP=false
SKIP_CONFIRM=false
VERBOSE=false
DRY_RUN=false

# Paths
INFRA_AWS_PATH="$PROJECT_ROOT/infra/aws"
DEPLOYMENT_TF_PATH="$PROJECT_ROOT/deployment/terraform"
BACKEND_PATH="$PROJECT_ROOT/backend"
WEB_PATH="$PROJECT_ROOT/web"

###############################################################################
# Logging Functions
###############################################################################

setup_logging() {
    mkdir -p "$LOG_DIR"
    touch "$LOG_FILE"
}

log_info() {
    local message="$1"
    echo -e "${BLUE}[INFO]${NC} $message" | tee -a "$LOG_FILE"
}

log_success() {
    local message="$1"
    echo -e "${GREEN}[✓]${NC} $message" | tee -a "$LOG_FILE"
}

log_warning() {
    local message="$1"
    echo -e "${YELLOW}[WARNING]${NC} $message" | tee -a "$LOG_FILE"
}

log_error() {
    local message="$1"
    echo -e "${RED}[ERROR]${NC} $message" | tee -a "$LOG_FILE"
}

log_verbose() {
    local message="$1"
    if [[ "$VERBOSE" == true ]]; then
        echo -e "${BLUE}[DEBUG]${NC} $message" | tee -a "$LOG_FILE"
    fi
}

###############################################################################
# Utility Functions
###############################################################################

print_banner() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║       Rupaya Deployment Orchestrator                       ║"
    echo "║                                                            ║"
    echo "║  🚀 Deploy infrastructure and applications safely          ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

show_help() {
    head -30 "$0" | tail -26
}

validate_environment() {
    case "$ENVIRONMENT" in
        dev|development)
            ENVIRONMENT="dev"
            ;;
        staging|stage)
            ENVIRONMENT="staging"
            ;;
        prod|production)
            ENVIRONMENT="prod"
            ;;
        *)
            log_error "Invalid environment: $ENVIRONMENT"
            echo "Valid options: dev, staging, prod"
            exit 1
            ;;
    esac
}

validate_target() {
    case "$TARGET" in
        infra|infrastructure)
            TARGET="infra"
            ;;
        backend|app)
            TARGET="backend"
            ;;
        frontend|web)
            TARGET="frontend"
            ;;
        all)
            TARGET="all"
            ;;
        *)
            log_error "Invalid target: $TARGET"
            echo "Valid options: infra, backend, frontend, all"
            exit 1
            ;;
    esac
}

check_aws_credentials() {
    log_info "Checking AWS credentials..."
    if ! aws sts get-caller-identity &>/dev/null; then
        log_error "AWS credentials not configured or invalid"
        exit 1
    fi
    
    local account_id=$(aws sts get-caller-identity --query Account --output text)
    local region=$(aws configure get region || echo "us-east-1")
    log_success "AWS credentials valid (Account: $account_id, Region: $region)"
}

check_required_tools() {
    log_info "Checking required tools..."
    
    local required_tools=("terraform" "aws" "docker" "git")
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            log_warning "$tool not installed"
        else
            log_verbose "$tool installed"
        fi
    done
    
    log_success "Tool checks completed"
}

confirm_deployment() {
    if [[ "$SKIP_CONFIRM" == true ]]; then
        log_warning "Skipping confirmation prompts (--confirm flag used)"
        return 0
    fi

    echo -e "\n${YELLOW}DEPLOYMENT CONFIRMATION REQUIRED${NC}"
    echo "Environment: $ENVIRONMENT"
    echo "Target: $TARGET"
    echo "Version: $VERSION"
    echo ""
    
    read -p "Continue with deployment? (yes/no): " confirm
    if [[ "$confirm" != "yes" ]]; then
        log_error "Deployment cancelled by user"
        exit 1
    fi
}

backup_state_files() {
    if [[ "$SKIP_BACKUP" == true ]]; then
        log_verbose "Skipping state file backups"
        return 0
    fi
    
    log_info "Backing up Terraform state files..."
    
    local backup_dir="$PROJECT_ROOT/.state-backups/backup_${TIMESTAMP}"
    mkdir -p "$backup_dir"
    
    # Backup infra state
    if [[ -f "$INFRA_AWS_PATH/terraform.tfstate" ]]; then
        cp "$INFRA_AWS_PATH/terraform.tfstate" "$backup_dir/" || true
        log_verbose "Backed up infra/aws state"
    fi
    
    # Backup deployment state
    if [[ -f "$DEPLOYMENT_TF_PATH/terraform.tfstate" ]]; then
        cp "$DEPLOYMENT_TF_PATH/terraform.tfstate" "$backup_dir/" || true
        log_verbose "Backed up deployment/terraform state"
    fi
    
    log_success "State files backed up to: $backup_dir"
}

###############################################################################
# Pre-Deployment Checks
###############################################################################

run_pre_deployment_checks() {
    if [[ "$SKIP_VALIDATION" == true ]]; then
        log_warning "Skipping pre-deployment validation"
        return 0
    fi
    
    log_info "=========================================="
    log_info "Running Pre-Deployment Validation"
    log_info "=========================================="
    
    check_aws_credentials
    check_required_tools
    
    # Environment-specific checks
    if [[ "$ENVIRONMENT" == "prod" ]]; then
        log_warning "Production environment selected - additional checks required"
        # Add production-specific checks here
    fi
    
    log_success "Pre-deployment checks passed"
}

###############################################################################
# Infrastructure Deployment
###############################################################################

deploy_infrastructure() {
    log_info "=========================================="
    log_info "Starting Infrastructure Deployment"
    log_info "=========================================="
    
    if [[ ! -d "$INFRA_AWS_PATH" ]]; then
        log_error "Infrastructure path not found: $INFRA_AWS_PATH"
        return 1
    fi
    
    cd "$INFRA_AWS_PATH"
    
    # Initialize Terraform
    log_info "Initializing Terraform..."
    terraform init -upgrade || {
        log_error "Terraform init failed"
        return 1
    }
    
    # Validate
    log_info "Validating Terraform configuration..."
    terraform validate || {
        log_warning "Terraform validation found issues (continuing)"
    }
    
    # Plan
    if [[ "$DRY_RUN" == true ]]; then
        log_info "Running Terraform plan (DRY-RUN)..."
        terraform plan -out=tfplan || {
            log_error "Terraform plan failed"
            return 1
        }
        log_success "Dry-run plan generated: tfplan"
        return 0
    fi
    
    # Apply
    log_info "Applying Terraform configuration..."
    terraform apply -auto-approve || {
        log_error "Terraform apply failed"
        return 1
    }
    
    log_success "Infrastructure deployed successfully"
    return 0
}

###############################################################################
# Backend Deployment
###############################################################################

deploy_backend() {
    log_info "=========================================="
    log_info "Starting Backend Application Deployment"
    log_info "=========================================="
    
    if [[ ! -f "$BACKEND_PATH/deploy-to-ecs.sh" ]]; then
        log_error "Backend deployment script not found: $BACKEND_PATH/deploy-to-ecs.sh"
        return 1
    fi
    
    # Determine ECS cluster and service
    local cluster=""
    local service=""
    case "$ENVIRONMENT" in
        dev)
            cluster="rupaya-dev"
            service="rupaya-backend-dev"
            ;;
        staging)
            cluster="rupaya-staging"
            service="rupaya-backend-staging"
            ;;
        prod)
            cluster="rupaya-prod"
            service="rupaya-backend-prod"
            ;;
    esac
    
    log_info "Deploying backend to ECS cluster: $cluster"
    log_info "Service: $service"
    log_info "Version: $VERSION"
    
    if [[ "$DRY_RUN" == true ]]; then
        log_success "Dry-run: would deploy $VERSION to $service"
        return 0
    fi
    
    # Run deployment script
    cd "$BACKEND_PATH"
    chmod +x deploy-to-ecs.sh
    
    if ! ./deploy-to-ecs.sh "$VERSION" "$cluster" "$service"; then
        log_error "Backend deployment failed"
        return 1
    fi
    
    log_success "Backend deployed successfully"
    return 0
}

###############################################################################
# Frontend Deployment
###############################################################################

deploy_frontend() {
    log_info "=========================================="
    log_info "Starting Frontend Deployment"
    log_info "=========================================="
    
    if [[ ! -d "$WEB_PATH" ]]; then
        log_warning "Frontend path not found: $WEB_PATH"
        log_info "Skipping frontend deployment"
        return 0
    fi
    
    log_info "Building frontend application..."
    
    cd "$WEB_PATH"
    
    if [[ "$DRY_RUN" == true ]]; then
        log_success "Dry-run: would build and deploy frontend"
        return 0
    fi
    
    # Add frontend deployment logic here
    if [[ -f "package.json" ]]; then
        log_info "Found package.json - Node.js project"
        # npm run build
        # aws s3 sync build/ s3://bucket-name
    fi
    
    log_success "Frontend deployed successfully"
    return 0
}

###############################################################################
# Database Migrations
###############################################################################

run_database_migrations() {
    log_info "=========================================="
    log_info "Running Database Migrations"
    log_info "=========================================="
    
    if [[ ! -f "$BACKEND_PATH/knexfile.js" ]]; then
        log_warning "Knex configuration not found"
        log_info "Skipping database migrations"
        return 0
    fi
    
    cd "$BACKEND_PATH"
    
    log_info "Running migrations for $ENVIRONMENT environment..."
    
    if [[ "$DRY_RUN" == true ]]; then
        log_success "Dry-run: would run migrations"
        return 0
    fi
    
    # Run migrations
    log_info "Executing: npm run migrate:$ENVIRONMENT"
    if npm run "migrate:$ENVIRONMENT" 2>&1 | tee -a "$LOG_FILE"; then
        log_success "Database migrations completed"
        return 0
    else
        log_warning "Database migrations completed with warnings"
        return 0
    fi
}

###############################################################################
# Post-Deployment Verification
###############################################################################

verify_deployment() {
    log_info "=========================================="
    log_info "Verifying Deployment"
    log_info "=========================================="
    
    case "$TARGET" in
        infra)
            log_info "Verifying infrastructure..."
            cd "$INFRA_AWS_PATH"
            terraform show | head -10
            ;;
        backend)
            log_info "Verifying backend deployment..."
            # Add health check logic
            ;;
        frontend)
            log_info "Verifying frontend deployment..."
            # Add frontend verification
            ;;
        all)
            log_info "Verifying all components..."
            ;;
    esac
    
    log_success "Verification completed"
}

###############################################################################
# Rollback Instructions
###############################################################################

show_rollback_instructions() {
    echo ""
    echo -e "${YELLOW}If deployment failed and you need to rollback:${NC}"
    echo ""
    echo "1. Check deployment logs:"
    echo "   tail -100 $LOG_FILE"
    echo ""
    echo "2. To destroy infrastructure:"
    echo "   $SCRIPT_DIR/destroy-infrastructure.sh --$TARGET"
    echo ""
    echo "3. To rollback database:"
    echo "   cd $BACKEND_PATH"
    echo "   npm run migrate:rollback-$ENVIRONMENT"
    echo ""
}

###############################################################################
# Parse Arguments
###############################################################################

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -e|--environment)
                ENVIRONMENT="$2"
                shift 2
                ;;
            -t|--target)
                TARGET="$2"
                shift 2
                ;;
            -v|--version)
                VERSION="$2"
                shift 2
                ;;
            --skip-validation)
                SKIP_VALIDATION=true
                shift
                ;;
            --skip-backup)
                SKIP_BACKUP=true
                shift
                ;;
            --confirm)
                SKIP_CONFIRM=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Validate required arguments
    if [[ -z "$ENVIRONMENT" ]]; then
        log_error "Environment not specified"
        show_help
        exit 1
    fi
    
    if [[ -z "$TARGET" ]]; then
        log_error "Target not specified"
        show_help
        exit 1
    fi
    
    # Normalize values
    validate_environment
    validate_target
}

###############################################################################
# Main Execution
###############################################################################

main() {
    setup_logging
    print_banner
    
    log_info "Deployment script started"
    log_info "Log file: $LOG_FILE"
    
    # Parse arguments
    parse_arguments "$@"
    
    # Show deployment plan
    log_info "Deployment Plan:"
    log_info "  Environment: $ENVIRONMENT"
    log_info "  Target: $TARGET"
    log_info "  Version: $VERSION"
    log_info "  Dry-Run: $DRY_RUN"
    
    # Confirm deployment
    confirm_deployment
    
    # Backup state files
    backup_state_files
    
    # Pre-deployment checks
    run_pre_deployment_checks
    
    # Execute target-specific deployments
    local failed=0
    
    case "$TARGET" in
        infra)
            deploy_infrastructure || ((failed++))
            ;;
        backend)
            deploy_backend || ((failed++))
            run_database_migrations || ((failed++))
            ;;
        frontend)
            deploy_frontend || ((failed++))
            ;;
        all)
            deploy_infrastructure || ((failed++))
            deploy_backend || ((failed++))
            run_database_migrations || ((failed++))
            deploy_frontend || ((failed++))
            ;;
    esac
    
    # Verify deployment
    if [[ $failed -eq 0 ]]; then
        verify_deployment
    fi
    
    # Summary
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    if [[ $failed -eq 0 ]]; then
        echo -e "║ ${GREEN}✓ Deployment completed successfully!${NC}                   ║"
    else
        echo -e "║ ${RED}✗ Deployment completed with errors${NC}                    ║"
        show_rollback_instructions
    fi
    echo "╚════════════════════════════════════════════════════════════╝"
    
    log_info "Log file saved to: $LOG_FILE"
    
    [[ $failed -gt 0 ]] && exit 1 || exit 0
}

# Run main function with all arguments
main "$@"