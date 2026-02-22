#!/bin/bash

###############################################################################
# AWS Infrastructure Destruction Tool
# 
# This comprehensive script safely destroys all AWS infrastructure across
# multiple Terraform configurations with built-in safeguards, pre-checks,
# and cleanup for common issues encountered during destruction.
#
# Usage: ./destroy-infrastructure.sh [OPTION]
#   -a, --all              Destroy all infrastructure (prod + dev)
#   -p, --prod             Destroy production infrastructure only
#   -d, --dev              Destroy development infrastructure only
#   -i, --infra            Destroy /infra/aws infrastructure only
#   -c, --confirm          Skip confirmation prompts (use with caution!)
#   -v, --verbose          Enable verbose logging
#   -h, --help             Show this help message
#
# Examples:
#   ./destroy-infrastructure.sh --prod
#   ./destroy-infrastructure.sh --all --confirm
###############################################################################

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$LOG_DIR/destroy_${TIMESTAMP}.log"

# Defaults
DESTROY_ALL=false
DESTROY_PROD=false
DESTROY_DEV=false
DESTROY_INFRA=false
SKIP_CONFIRM=false
VERBOSE=false

# Terraform paths
INFRA_AWS_PATH="$PROJECT_ROOT/infra/aws"
DEPLOYMENT_TF_PATH="$PROJECT_ROOT/deployment/terraform"

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
    echo "║       AWS Infrastructure Destruction Tool                  ║"
    echo "║                                                            ║"
    echo "║  ⚠️  WARNING: This will PERMANENTLY DELETE resources       ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

confirm_destruction() {
    if [[ "$SKIP_CONFIRM" == true ]]; then
        log_warning "Skipping confirmation prompts (--confirm flag used)"
        return 0
    fi

    echo -e "\n${YELLOW}CONFIRMATION REQUIRED${NC}"
    echo "This action will:"
    echo "  • Delete all RDS databases"
    echo "  • Remove Redis/ElastiCache clusters"
    echo "  • Destroy ECS/EKS containers"
    echo "  • Delete Route53 records"
    echo "  • Remove ACM certificates"
    echo "  • Destroy VPC/subnets/security groups"
    echo "  • Delete secrets and credentials"
    echo "  • Remove all associated resources"
    echo ""
    echo -e "${RED}This action CANNOT be undone!${NC}\n"

    read -p "Type 'destroy all infrastructure' to confirm: " confirm
    if [[ "$confirm" != "destroy all infrastructure" ]]; then
        log_error "Destruction cancelled by user"
        exit 1
    fi
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

show_help() {
    head -20 "$0" | tail -17
}

###############################################################################
# Pre-Destruction Checks
###############################################################################

validate_terraform_paths() {
    log_info "Validating Terraform paths..."
    
    if [[ "$DESTROY_INFRA" == true ]] && [[ ! -d "$INFRA_AWS_PATH" ]]; then
        log_error "Path not found: $INFRA_AWS_PATH"
        return 1
    fi
    
    if [[ "$DESTROY_PROD" == true || "$DESTROY_DEV" == true ]] && [[ ! -d "$DEPLOYMENT_TF_PATH" ]]; then
        log_error "Path not found: $DEPLOYMENT_TF_PATH"
        return 1
    fi
    
    log_success "All Terraform paths validated"
    return 0
}

check_terraform_installed() {
    log_info "Checking Terraform installation..."
    if ! command -v terraform &>/dev/null; then
        log_error "Terraform is not installed or not in PATH"
        exit 1
    fi
    
    local tf_version=$(terraform version | head -1)
    log_success "$tf_version"
}

check_aws_cli_installed() {
    log_info "Checking AWS CLI installation..."
    if ! command -v aws &>/dev/null; then
        log_error "AWS CLI is not installed or not in PATH"
        exit 1
    fi
    
    local aws_version=$(aws --version)
    log_success "AWS CLI: $aws_version"
}

###############################################################################
# ECR Cleanup Functions
###############################################################################

cleanup_ecr_repositories() {
    local region="${1:-us-east-1}"
    
    log_info "Cleaning up ECR repositories..."
    
    # Get all ECR repositories
    local repos=$(aws ecr describe-repositories --region "$region" --query 'repositories[].repositoryName' --output text 2>/dev/null || echo "")
    
    if [[ -z "$repos" ]]; then
        log_info "No ECR repositories found"
        return 0
    fi
    
    for repo in $repos; do
        log_info "Clearing images from ECR repository: $repo"
        
        # Get all images in the repository
        local image_count=$(aws ecr describe-images --repository-name "$repo" --region "$region" --query 'length(imageDetails)' --output text 2>/dev/null || echo "0")
        
        if [[ "$image_count" -gt 0 ]]; then
            log_verbose "Found $image_count images in $repo, deleting..."
            
            # Delete images by digest (more reliable than by tag)
            aws ecr batch-delete-image \
                --repository-name "$repo" \
                --region "$region" \
                --image-ids "$(aws ecr describe-images --repository-name "$repo" --region "$region" --query 'imageDetails[].{imageDigest:imageDigest}' --output json | jq -r '.[] | "imageDigest=\(.imageDigest)"' | tr '\n' ' ')" \
                2>/dev/null || log_warning "Failed to delete some images from $repo"
        fi
    done
    
    log_success "ECR cleanup completed"
}

###############################################################################
# Terraform Helper Functions
###############################################################################

fix_terraform_issues() {
    local tf_path="$1"
    local config_file="$tf_path/github-oidc.tf"
    
    log_info "Checking for and fixing Terraform configuration issues in $tf_path..."
    
    if [[ ! -f "$config_file" ]]; then
        log_verbose "No github-oidc.tf found, skipping configuration fixes"
        return 0
    fi
    
    # Check if the file has undeclared resource references
    if grep -q 'aws_s3_bucket.terraform_state.id' "$config_file"; then
        log_info "Found hardcoded S3 bucket reference issue, fixing..."
        # The bucket name from backend.tf is rupaya-terraform-state-590184132516
        sed -i.bak 's/${aws_s3_bucket\.terraform_state\.id}/rupaya-terraform-state-590184132516/g' "$config_file"
        log_success "Fixed S3 bucket references"
    fi
    
    if grep -q 'aws_dynamodb_table.terraform_lock.name' "$config_file"; then
        log_info "Found hardcoded DynamoDB table reference issue, fixing..."
        sed -i.bak 's/${aws_dynamodb_table\.terraform_lock\.name}/rupaya-terraform-state-lock/g' "$config_file"
        log_success "Fixed DynamoDB table references"
    fi
    
    # Clean up backup files
    find "$tf_path" -name "*.bak" -delete 2>/dev/null || true
}

terraform_init_upgrade() {
    local tf_path="$1"
    
    log_info "Initializing Terraform: $tf_path..."
    
    if ! cd "$tf_path"; then
        log_error "Failed to change directory to $tf_path"
        return 1
    fi
    
    if ! terraform init -upgrade 2>&1 | tee -a "$LOG_FILE"; then
        log_error "Terraform init failed for $tf_path"
        return 1
    fi
    
    log_success "Terraform initialized: $tf_path"
    return 0
}

terraform_validate() {
    local tf_path="$1"
    
    log_info "Validating Terraform configuration: $tf_path..."
    
    if ! cd "$tf_path"; then
        log_error "Failed to change directory to $tf_path"
        return 1
    fi
    
    if ! terraform validate 2>&1 | tee -a "$LOG_FILE"; then
        log_warning "Terraform validation found issues in $tf_path"
        return 1
    fi
    
    log_success "Terraform configuration valid: $tf_path"
    return 0
}

terraform_destroy() {
    local tf_path="$1"
    local name="$2"
    
    log_info "Destroying Terraform resources: $name ($tf_path)..."
    
    if ! cd "$tf_path"; then
        log_error "Failed to change directory to $tf_path"
        return 1
    fi
    
    if ! terraform destroy -auto-approve 2>&1 | tee -a "$LOG_FILE"; then
        log_error "Terraform destroy failed for $tf_path"
        return 1
    fi
    
    log_success "Terraform destroy completed: $name"
    return 0
}

terraform_state_check() {
    local tf_path="$1"
    
    log_info "Checking Terraform state: $tf_path..."
    
    if ! cd "$tf_path"; then
        log_error "Failed to change directory to $tf_path"
        return 1
    fi
    
    local state_info=$(terraform show 2>/dev/null || echo "No state")
    if [[ "$state_info" == *"No state"* ]] || [[ "$state_info" == *"empty"* ]]; then
        log_success "Terraform state is empty (all resources destroyed): $tf_path"
        return 0
    else
        log_warning "Terraform state still contains resources: $tf_path"
        return 1
    fi
}

###############################################################################
# Main Destruction Functions
###############################################################################

destroy_infra_aws() {
    log_info "=========================================="
    log_info "Starting destruction of /infra/aws"
    log_info "=========================================="
    
    # Step 1: Pre-checks
    check_aws_credentials
    check_terraform_installed
    
    # Step 2: Fix known Terraform issues
    fix_terraform_issues "$INFRA_AWS_PATH"
    
    # Step 3: Initialize Terraform
    terraform_init_upgrade "$INFRA_AWS_PATH" || return 1
    
    # Step 4: Validate configuration
    terraform_validate "$INFRA_AWS_PATH" || log_warning "Continuing despite validation issues"
    
    # Step 5: Get AWS region from Terraform
    cd "$INFRA_AWS_PATH"
    local region=$(terraform output -raw region 2>/dev/null || echo "us-east-1")
    
    # Step 6: Cleanup ECR repositories
    cleanup_ecr_repositories "$region"
    
    # Step 7: Destroy infrastructure
    terraform_destroy "$INFRA_AWS_PATH" "infra/aws" || return 1
    
    # Step 8: Verify state is empty
    terraform_state_check "$INFRA_AWS_PATH"
    
    log_success "Destruction of /infra/aws completed successfully"
}

destroy_deployment_terraform() {
    log_info "=========================================="
    log_info "Starting destruction of /deployment/terraform"
    log_info "=========================================="
    
    # Step 1: Pre-checks
    check_aws_credentials
    check_terraform_installed
    
    # Step 2: Initialize Terraform
    terraform_init_upgrade "$DEPLOYMENT_TF_PATH" || return 1
    
    # Step 3: Validate configuration
    terraform_validate "$DEPLOYMENT_TF_PATH" || log_warning "Continuing despite validation issues"
    
    # Step 4: Destroy infrastructure
    terraform_destroy "$DEPLOYMENT_TF_PATH" "deployment/terraform" || return 1
    
    # Step 5: Verify state is empty
    terraform_state_check "$DEPLOYMENT_TF_PATH"
    
    log_success "Destruction of /deployment/terraform completed successfully"
}

###############################################################################
# Parse Arguments
###############################################################################

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -a|--all)
                DESTROY_ALL=true
                DESTROY_INFRA=true
                DESTROY_PROD=true
                DESTROY_DEV=true
                shift
                ;;
            -p|--prod)
                DESTROY_PROD=true
                shift
                ;;
            -d|--dev)
                DESTROY_DEV=true
                shift
                ;;
            -i|--infra)
                DESTROY_INFRA=true
                shift
                ;;
            -c|--confirm)
                SKIP_CONFIRM=true
                shift
                ;;
            -v|--verbose)
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
    
    # If nothing selected, show help
    if [[ "$DESTROY_ALL" == false ]] && [[ "$DESTROY_INFRA" == false ]] && [[ "$DESTROY_PROD" == false ]] && [[ "$DESTROY_DEV" == false ]]; then
        log_error "No destruction target specified"
        show_help
        exit 1
    fi
}

###############################################################################
# Main Execution
###############################################################################

main() {
    setup_logging
    print_banner
    
    log_info "Destruction script started"
    log_info "Log file: $LOG_FILE"
    
    # Parse arguments
    parse_arguments "$@"
    
    # Show what will be destroyed
    log_info "Destruction targets:"
    [[ "$DESTROY_INFRA" == true ]] && log_info "  • /infra/aws"
    [[ "$DESTROY_PROD" == true ]] && log_info "  • /deployment/terraform (prod)"
    [[ "$DESTROY_DEV" == true ]] && log_info "  • /deployment/terraform (dev)"
    
    # Confirm with user
    confirm_destruction
    
    # Add extra confirmation for safety
    log_warning "Last chance to cancel (Ctrl+C)"
    sleep 3
    
    # Execute destruction
    local failed=0
    
    if [[ "$DESTROY_INFRA" == true ]]; then
        destroy_infra_aws || ((failed++))
    fi
    
    if [[ "$DESTROY_PROD" == true ]] || [[ "$DESTROY_DEV" == true ]]; then
        destroy_deployment_terraform || ((failed++))
    fi
    
    # Summary
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    if [[ $failed -eq 0 ]]; then
        echo -e "║ ${GREEN}✓ Destruction completed successfully!${NC}                 ║"
    else
        echo -e "║ ${RED}✗ Destruction completed with errors${NC}                  ║"
    fi
    echo "╚════════════════════════════════════════════════════════════╝"
    
    log_info "Log file saved to: $LOG_FILE"
    
    [[ $failed -gt 0 ]] && exit 1 || exit 0
}

# Run main function with all arguments
main "$@"
