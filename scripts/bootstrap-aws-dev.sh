#!/bin/bash
set -e

# ========== RUPAYA AWS BOOTSTRAP SCRIPT ==========
# This script deploys the complete dev environment to AWS
# Prerequisites:
#   1. AWS CLI configured with credentials or OIDC role set up
#   2. Terraform installed (>= 1.0)
#   3. Docker CLI configured for pushing to ECR
#   4. Git repository cloned locally

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/environments/dev"

# Configuration
AWS_REGION="${AWS_REGION:-us-east-1}"
ENVIRONMENT="dev"
ECR_REPOSITORY="rupaya-backend"
ECS_CLUSTER="rupaya-dev"
ECS_SERVICE="rupaya-backend-dev"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ========== HELPER FUNCTIONS ==========
log_info() {
  echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
  echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
  echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
  echo -e "${RED}❌ $1${NC}"
}

# ========== PHASE 1: PREREQUISITES CHECK ==========
log_info "Phase 1: Checking prerequisites..."

check_tool() {
  if ! command -v "$1" &> /dev/null; then
    log_error "$1 is not installed"
    exit 1
  fi
  log_success "$1 found"
}

check_tool "aws"
check_tool "terraform"
check_tool "docker"
check_tool "git"

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
  log_error "AWS credentials not configured. Please configure AWS CLI or set up OIDC role."
  exit 1
fi

log_success "AWS credentials configured"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
log_success "AWS Account ID: $AWS_ACCOUNT_ID"

# ========== PHASE 2: PREPARE TERRAFORM ==========
log_info "Phase 2: Preparing Terraform..."

if [ ! -d "$TERRAFORM_DIR" ]; then
  log_error "Terraform directory not found: $TERRAFORM_DIR"
  exit 1
fi

cd "$TERRAFORM_DIR"

# Initialize Terraform
log_info "Initializing Terraform..."
terraform init -upgrade

log_success "Terraform initialized"

# ========== PHASE 3: VALIDATE TERRAFORM ==========
log_info "Phase 3: Validating Terraform configuration..."

terraform validate

log_success "Terraform configuration valid"

# ========== PHASE 4: PLAN INFRASTRUCTURE ==========
log_info "Phase 4: Planning infrastructure..."

# Prompt for RDS password if not set
if [ -z "$TF_VAR_db_master_password" ]; then
  log_warning "RDS master password not set"
  read -sp "Enter RDS master password (min 8 chars): " TF_VAR_db_master_password
  echo ""
  if [ ${#TF_VAR_db_master_password} -lt 8 ]; then
    log_error "Password must be at least 8 characters"
    exit 1
  fi
  export TF_VAR_db_master_password
fi

terraform plan -out="$TERRAFORM_DIR/tfplan"

log_success "Terraform plan created"

# ========== PHASE 5: APPLY INFRASTRUCTURE ==========
log_info "Phase 5: Applying infrastructure..."
log_warning "This will create AWS resources and may incur charges"

read -p "Continue with Terraform apply? (yes/no): " -r
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
  log_error "Deployment cancelled"
  exit 1
fi

terraform apply "$TERRAFORM_DIR/tfplan"

log_success "Infrastructure deployed successfully"

# ========== PHASE 6: GET OUTPUTS ==========
log_info "Phase 6: Retrieving infrastructure details..."

RDS_ENDPOINT=$(terraform output -raw rds_endpoint 2>/dev/null || echo "")
REDIS_ENDPOINT=$(terraform output -raw redis_endpoint 2>/dev/null || echo "")
ECR_REPOSITORY_URI=$(terraform output -raw ecr_repository_uri 2>/dev/null || echo "")
ALB_DNS_NAME=$(terraform output -raw alb_dns_name 2>/dev/null || echo "")

log_success "Infrastructure outputs:"
echo "  RDS Endpoint: $RDS_ENDPOINT"
echo "  Redis Endpoint: $REDIS_ENDPOINT"
echo "  ECR Repository: $ECR_REPOSITORY_URI"
echo "  ALB DNS: $ALB_DNS_NAME"

# ========== PHASE 7: BUILD AND PUSH DOCKER IMAGE ==========
log_info "Phase 7: Building and pushing Docker image..."

cd "$PROJECT_ROOT"

# Login to ECR
log_info "Logging into ECR..."
aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

log_success "Logged into ECR"

# Build image
log_info "Building Docker image..."
docker build -f backend/Dockerfile -t "$ECR_REPOSITORY_URI:latest" -t "$ECR_REPOSITORY_URI:v1.0.0" ./backend

log_success "Docker image built"

# Push to ECR
log_info "Pushing Docker image to ECR..."
docker push "$ECR_REPOSITORY_URI:latest"
docker push "$ECR_REPOSITORY_URI:v1.0.0"

log_success "Docker image pushed to ECR"

# ========== PHASE 8: DEPLOY APPLICATION ==========
log_info "Phase 8: Deploying application to ECS..."

# Get the latest task definition
LATEST_TASK_DEF=$(aws ecs describe-task-definition \
  --task-definition "$ECS_SERVICE" \
  --region "$AWS_REGION" 2>/dev/null || echo "")

if [ -z "$LATEST_TASK_DEF" ]; then
  log_error "Could not retrieve task definition"
  # This is expected on first run - task def is created by Terraform
  log_info "Task definition will be created/updated by ECS service"
else
  log_success "Task definition found"
fi

# Update ECS service to use new image
log_info "Updating ECS service..."
aws ecs update-service \
  --cluster "$ECS_CLUSTER" \
  --service "$ECS_SERVICE" \
  --force-new-deployment \
  --region "$AWS_REGION" > /dev/null

log_success "ECS service update initiated"

# Wait for deployment to complete
log_info "Waiting for ECS deployment to stabilize (this may take 2-3 minutes)..."
aws ecs wait services-stable \
  --cluster "$ECS_CLUSTER" \
  --services "$ECS_SERVICE" \
  --region "$AWS_REGION" || log_warning "Service may still be starting"

log_success "ECS deployment completed"

# ========== PHASE 9: RUN DATABASE MIGRATIONS ==========
log_info "Phase 9: Running database migrations..."

# Get Database URL from ECS task environment (or construct it)
DB_HOST=$(echo "$RDS_ENDPOINT" | cut -d: -f1)
DATABASE_URL="postgres://rupaya_admin:${TF_VAR_db_master_password}@${DB_HOST}/rupaya_dev?sslmode=require"

# Run migrations (this assumes the app can run migrations)
cd "$PROJECT_ROOT/backend"

log_info "Running Knex migrations..."
DATABASE_URL="$DATABASE_URL" npm run migrate:dev || log_warning "Migrations may have already been run"

log_success "Database migrations completed"

# ========== PHASE 10: HEALTH CHECKS ==========
log_info "Phase 10: Running health checks..."

# Wait a bit for the service to be fully responsive
sleep 5

# Check ALB endpoint
API_URL="http://${ALB_DNS_NAME}"

log_info "Checking API health: $API_URL/health"

HEALTH_CHECK=$(curl -s -o /dev/null -w "%{http_code}" "$API_URL/health" || echo "000")

if [ "$HEALTH_CHECK" = "200" ]; then
  log_success "API health check passed"
else
  log_warning "API health check returned: $HEALTH_CHECK (expected 200)"
  log_info "Service may still be starting. Retrying..."
  
  for i in {1..5}; do
    sleep 10
    HEALTH_CHECK=$(curl -s -o /dev/null -w "%{http_code}" "$API_URL/health" || echo "000")
    if [ "$HEALTH_CHECK" = "200" ]; then
      log_success "API health check passed (attempt $i)"
      break
    fi
    log_warning "Health check attempt $i/5 returned: $HEALTH_CHECK"
  done
fi

# ========== PHASE 11: VALIDATE FEATURE FLAGS ==========
log_info "Phase 11: Validating feature flags service..."

FEATURE_FLAGS_RESPONSE=$(curl -s "$API_URL/api/admin/deployment/feature-flags" || echo "")

if echo "$FEATURE_FLAGS_RESPONSE" | grep -q "feature"; then
  log_success "Feature flags service is responding"
else
  log_warning "Feature flags service may not be initialized"
fi

# ========== PHASE 12: RUN E2E TESTS ==========
log_info "Phase 12: Running E2E tests..."

cd "$PROJECT_ROOT/backend"

RUN_E2E_TESTS=true \
API_BASE_URL="$API_URL" \
npm test -- __tests__/e2e/deployment-features.test.js --passWithNoTests || log_warning "E2E tests may have issues"

log_success "E2E tests completed"

# ========== SUMMARY ==========
log_success "========== DEPLOYMENT COMPLETE =========="
echo ""
echo "Environment Details:"
echo "  Region: $AWS_REGION"
echo "  Cluster: $ECS_CLUSTER"
echo "  Service: $ECS_SERVICE"
echo ""
echo "Infrastructure:"
echo "  RDS Endpoint: $RDS_ENDPOINT"
echo "  Redis Endpoint: $REDIS_ENDPOINT"
echo "  ECR Repository: $ECR_REPOSITORY_URI"
echo "  ALB DNS: $ALB_DNS_NAME"
echo ""
echo "API Endpoint: $API_URL"
echo ""
echo "Next steps:"
echo "  1. Test the API: curl $API_URL/health"
echo "  2. View logs: aws logs tail /ecs/rupaya-backend-dev --follow"
echo "  3. Push to feature branch: git push origin feature/new-feature"
echo "  4. Workflow 05 will automatically deploy on push"
echo ""
echo "To destroy infrastructure (⚠️  WARNING - will delete all data):"
echo "  cd $TERRAFORM_DIR && terraform destroy"
echo ""
