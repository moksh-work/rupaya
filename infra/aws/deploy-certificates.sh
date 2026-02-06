#!/bin/bash

# ========== SSL/TLS Certificate Deployment Script ==========
# Deploy AWS Certificate Manager certificates and HTTPS setup
# Usage: ./deploy-certificates.sh <domain> <email>

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ========== CONFIGURATION ==========

DOMAIN="${1:-example.com}"
EMAIL="${2:-ops@example.com}"
PROJECT_NAME="rupaya"
REGION="us-east-1"

# ========== FUNCTIONS ==========

print_header() {
    echo -e "\n${BLUE}========== $1 ==========${NC}\n"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# ========== VALIDATION ==========

validate_domain() {
    print_header "Validating Domain Format"
    
    if [[ $DOMAIN =~ ^([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$ ]]; then
        print_success "Domain format valid: $DOMAIN"
    else
        print_error "Invalid domain format: $DOMAIN"
        print_info "Example: example.com"
        exit 1
    fi
}

validate_email() {
    print_header "Validating Email Format"
    
    if [[ $EMAIL =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        print_success "Email format valid: $EMAIL"
    else
        print_error "Invalid email format: $EMAIL"
        exit 1
    fi
}

check_aws_credentials() {
    print_header "Checking AWS Credentials"
    
    if aws sts get-caller-identity &> /dev/null; then
        ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
        ACCOUNT_USER=$(aws sts get-caller-identity --query Arn --output text)
        print_success "AWS credentials configured"
        print_info "Account ID: $ACCOUNT_ID"
        print_info "User: $ACCOUNT_USER"
    else
        print_error "AWS credentials not configured"
        print_info "Run: aws configure"
        exit 1
    fi
}

check_terraform() {
    print_header "Checking Terraform"
    
    if command -v terraform &> /dev/null; then
        VERSION=$(terraform version | head -1)
        print_success "Terraform installed: $VERSION"
    else
        print_error "Terraform not installed"
        exit 1
    fi
    
    if [ -f "infra/aws/acm.tf" ]; then
        print_success "ACM configuration found"
    else
        print_error "ACM configuration not found"
        print_info "Run from project root directory"
        exit 1
    fi
}

# ========== TERRAFORM OPERATIONS ==========

update_tfvars() {
    print_header "Updating terraform.tfvars"
    
    TFVARS_FILE="infra/aws/terraform.tfvars"
    
    if [ ! -f "$TFVARS_FILE" ]; then
        print_warning "terraform.tfvars not found, copying from example"
        cp infra/aws/terraform.tfvars.example "$TFVARS_FILE"
    fi
    
    # Update values (using sed)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s/route53_domain = .*/route53_domain = \"$DOMAIN\"/" "$TFVARS_FILE"
        sed -i '' "s/certificate_alert_email = .*/certificate_alert_email = \"$EMAIL\"/" "$TFVARS_FILE"
    else
        # Linux
        sed -i "s/route53_domain = .*/route53_domain = \"$DOMAIN\"/" "$TFVARS_FILE"
        sed -i "s/certificate_alert_email = .*/certificate_alert_email = \"$EMAIL\"/" "$TFVARS_FILE"
    fi
    
    print_success "Updated terraform.tfvars with:"
    print_info "  Domain: $DOMAIN"
    print_info "  Email: $EMAIL"
}

terraform_init() {
    print_header "Initializing Terraform"
    
    cd infra/aws
    terraform init
    cd - > /dev/null
    
    print_success "Terraform initialized"
}

terraform_validate() {
    print_header "Validating Terraform Configuration"
    
    cd infra/aws
    if terraform validate; then
        print_success "Terraform configuration valid"
    else
        print_error "Terraform validation failed"
        cd - > /dev/null
        exit 1
    fi
    cd - > /dev/null
}

terraform_plan() {
    print_header "Planning Terraform Deployment"
    
    cd infra/aws
    terraform plan -out=tfplan
    PLAN_STATUS=$?
    cd - > /dev/null
    
    if [ $PLAN_STATUS -eq 0 ]; then
        print_success "Terraform plan completed"
        print_warning "Review plan above before applying"
    else
        print_error "Terraform plan failed"
        exit 1
    fi
}

terraform_apply() {
    print_header "Applying Terraform Configuration"
    
    echo -e "${YELLOW}This will create:${NC}"
    echo "  - ACM certificates for production and staging"
    echo "  - Route53 DNS records and validation"
    echo "  - ALB HTTPS listeners"
    echo "  - SNS topic for certificate alerts"
    echo ""
    
    read -p "Continue? (yes/no): " CONFIRM
    
    if [ "$CONFIRM" != "yes" ]; then
        print_warning "Deployment cancelled"
        exit 0
    fi
    
    cd infra/aws
    terraform apply tfplan
    APPLY_STATUS=$?
    cd - > /dev/null
    
    if [ $APPLY_STATUS -eq 0 ]; then
        print_success "Terraform apply completed"
    else
        print_error "Terraform apply failed"
        exit 1
    fi
}

# ========== POST-DEPLOYMENT ==========

show_outputs() {
    print_header "Deployment Outputs"
    
    cd infra/aws
    
    PROD_ENDPOINT=$(terraform output -raw api_production_endpoint 2>/dev/null || echo "https://api.$DOMAIN")
    STAGING_ENDPOINT=$(terraform output -raw api_staging_endpoint 2>/dev/null || echo "https://staging-api.$DOMAIN")
    NAMESERVERS=$(terraform output -json route53_zone_nameservers 2>/dev/null | jq -r '.[]' | tr '\n' ' ')
    
    cd - > /dev/null
    
    echo -e "${GREEN}API Endpoints:${NC}"
    echo "  Production: $PROD_ENDPOINT"
    echo "  Staging:    $STAGING_ENDPOINT"
    echo ""
    echo -e "${GREEN}Route53 Nameservers:${NC}"
    echo "  $NAMESERVERS"
    echo ""
}

show_next_steps() {
    print_header "Next Steps"
    
    echo -e "${YELLOW}1. Update Domain Registrar${NC}"
    echo "   - Log in to your domain registrar"
    echo "   - Update nameservers to the Route53 values shown above"
    echo "   - Wait 24-48 hours for DNS propagation"
    echo ""
    
    echo -e "${YELLOW}2. Confirm SNS Subscription${NC}"
    echo "   - Check email: $EMAIL"
    echo "   - Click confirmation link from AWS SNS"
    echo "   - You'll receive certificate expiration alerts"
    echo ""
    
    echo -e "${YELLOW}3. Verify HTTPS Access${NC}"
    echo "   - Wait for DNS to propagate"
    echo "   - Test: curl -v https://api.$DOMAIN"
    echo "   - Should show valid SSL certificate"
    echo ""
    
    echo -e "${YELLOW}4. Monitor Deployment${NC}"
    echo "   - Watch CloudWatch logs"
    echo "   - Check ALB target health"
    echo "   - Verify ECS task health"
    echo ""
}

show_commands() {
    print_header "Useful Commands"
    
    echo "Check certificate status:"
    echo "  aws acm list-certificates --region $REGION"
    echo ""
    
    echo "Verify HTTPS:"
    echo "  curl -v https://api.$DOMAIN"
    echo ""
    
    echo "Check ALB listeners:"
    echo "  aws elbv2 describe-listeners --load-balancer-arn <alb-arn>"
    echo ""
    
    echo "View outputs:"
    echo "  cd infra/aws && terraform output"
    echo ""
    
    echo "Destroy certificates (cleanup):"
    echo "  cd infra/aws && terraform destroy"
    echo ""
}

# ========== MAIN EXECUTION ==========

main() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║          SSL/TLS Certificate Deployment Script              ║"
    echo "║          AWS Certificate Manager + HTTPS Setup              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    print_info "Domain: $DOMAIN"
    print_info "Email: $EMAIL"
    print_info "Region: $REGION"
    echo ""
    
    # Pre-deployment checks
    validate_domain
    validate_email
    check_aws_credentials
    check_terraform
    
    # Terraform deployment
    update_tfvars
    terraform_init
    terraform_validate
    terraform_plan
    terraform_apply
    
    # Post-deployment
    show_outputs
    show_next_steps
    show_commands
    
    print_header "Deployment Complete"
    print_success "SSL/TLS certificates deployed successfully!"
    print_info "Check your email ($EMAIL) for SNS subscription confirmation"
    
}

# ========== ERROR HANDLING ==========

trap 'print_error "Script failed"; exit 1' ERR

# ========== SCRIPT EXECUTION ==========

if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    echo "Usage: $0 [domain] [email]"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Interactive (prompts for input)"
    echo "  $0 example.com                        # Uses default email"
    echo "  $0 example.com ops@example.com        # Uses provided domain and email"
    exit 0
fi

main
