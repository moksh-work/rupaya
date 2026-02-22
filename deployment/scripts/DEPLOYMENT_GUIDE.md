# Rupaya Deployment Guide

Comprehensive guide for deploying Rupaya infrastructure and applications using the updated `deploy.sh` orchestrator.

## Overview

The `deploy.sh` script provides a unified entry point for:

- **Infrastructure Deployment** (Terraform)
- **Backend Application** (Docker/ECS)
- **Frontend Application** (S3/CloudFront)
- **Database Migrations** (Knex)
- **Health Verification** (Post-deployment checks)

## Quick Start

```bash
# Make script executable
chmod +x deployment/scripts/deploy.sh

# View help
./deployment/scripts/deploy.sh --help

# Deploy backend to development
./deployment/scripts/deploy.sh --environment dev --target backend

# Deploy entire stack to staging
./deployment/scripts/deploy.sh --environment staging --target all

# Deploy infrastructure to production
./deployment/scripts/deploy.sh --environment prod --target infra
```

## Command Reference

### Basic Syntax

```bash
./deployment/scripts/deploy.sh [OPTIONS]
```

### Required Options

| Option | Values | Description |
|--------|--------|-------------|
| `-e, --environment` | dev, staging, prod | Target environment |
| `-t, --target` | infra, backend, frontend, all | What to deploy |

### Optional Options

| Option | Description |
|--------|-------------|
| `-v, --version VERSION` | Application version (default: latest) |
| `--skip-validation` | Skip pre-deployment checks |
| `--skip-backup` | Skip state file backups |
| `--confirm` | Skip confirmation prompts |
| `--dry-run` | Show what would be deployed (no actual changes) |
| `--verbose` | Enable verbose logging |
| `-h, --help` | Display help message |

## Usage Examples

### Development Environment

```bash
# Deploy backend only to dev
./deployment/scripts/deploy.sh --environment dev --target backend

# Deploy everything to dev
./deployment/scripts/deploy.sh --environment dev --target all

# Deploy with specific version
./deployment/scripts/deploy.sh --environment dev --target backend --version v1.2.3

# Dry-run to see what would be deployed
./deployment/scripts/deploy.sh --environment dev --target backend --dry-run

# Verbose deployment for debugging
./deployment/scripts/deploy.sh --environment dev --target backend --verbose
```

### Staging Environment

```bash
# Deploy updated infrastructure
./deployment/scripts/deploy.sh --environment staging --target infra

# Full stack deployment
./deployment/scripts/deploy.sh --environment staging --target all --confirm

# Frontend only
./deployment/scripts/deploy.sh --environment staging --target frontend
```

### Production Environment

```bash
# Infrastructure deployment (requires confirmation)
./deployment/scripts/deploy.sh --environment prod --target infra

# Backend with specific version
./deployment/scripts/deploy.sh --environment prod --target backend --version v1.2.3

# Critical: Deploy everything with confirmations (CAREFUL!)
./deployment/scripts/deploy.sh --environment prod --target all

# Full deployment without prompts (use in CI/CD)
./deployment/scripts/deploy.sh --environment prod --target all --confirm
```

## Deployment Targets

### Infrastructure (`--target infra`)

Deploys AWS infrastructure using Terraform.

**What's deployed:**
- VPC and networking
- RDS databases
- ElastiCache clusters
- ECR repositories
- ECS clusters
- Load balancers
- Security groups
- IAM roles

**Pre-checks:**
- Terraform installation
- AWS credentials validation
- Account ID verification

**Process:**
1. Initialize Terraform
2. Validate configuration
3. Generate plan
4. Apply configuration
5. Verify deployment

### Backend (`--target backend`)

Deploys the backend application to ECS.

**What's deployed:**
- Docker image build and push to ECR
- ECS task definition update
- ECS service update
- Database migrations
- Health checks

**Environment-specific:**
- Dev: `rupaya-dev` cluster → `rupaya-backend-dev` service
- Staging: `rupaya-staging` cluster → `rupaya-backend-staging` service
- Prod: `rupaya-prod` cluster → `rupaya-backend-prod` service

**Process:**
1. Build Docker image
2. Push to ECR
3. Update ECS task definition
4. Update ECS service
5. Run database migrations
6. Verify deployment health

### Frontend (`--target frontend`)

Deploys the frontend application to S3/CloudFront.

**What's deployed:**
- Build React/Vue/Next.js application
- Upload to S3 bucket
- Invalidate CloudFront cache
- Update DNS records

**Process:**
1. Build frontend
2. Upload to S3
3. Invalidate cache
4. Verify deployment

### All (`--target all`)

Complete stack deployment in proper order:

1. Infrastructure (if needed)
2. Backend application
3. Database migrations
4. Frontend application
5. Health verification

**Used for:**
- Fresh environment setup
- Complete rebuilds
- Major version upgrades

## Features

### Pre-Deployment Validation

Automatic checks before deployment:

- ✓ AWS credentials validation
- ✓ Required tools installation (terraform, aws, docker, git)
- ✓ Environment-specific checks (production safety checks)
- ✓ State file verification
- ✓ Configuration validation

**Skip with:** `--skip-validation`

### State File Backups

Automatic backup of Terraform state files before deployment:

**Location:** `.state-backups/backup_YYYYMMDD_HHMMSS/`

**Backed up:**
- `infra/aws/terraform.tfstate`
- `deployment/terraform/terraform.tfstate`

**Skip with:** `--skip-backup`

### User Confirmation

Multi-step confirmation workflow:

```
Environment: dev
Target: backend
Version: latest

Continue with deployment? (yes/no): yes
```

**Skip with:** `--confirm` flag

**Note:** Always use `--confirm` in CI/CD pipelines

### Logging

All operations logged to:

```
deployment/scripts/logs/deploy_YYYYMMDD_HHMMSS.log
```

**Contains:**
- Timestamps for each operation
- AWS resource IDs and changes
- Terraform plans and applies
- Deployment status
- Error messages
- Recovery instructions

### Dry-Run Mode

Preview deployment without making changes:

```bash
./deployment/scripts/deploy.sh --environment dev --target backend --dry-run
```

**Shows:**
- What would be deployed
- Version information
- Target services
- No actual changes made

### Verbose Logging

Enable detailed debugging output:

```bash
./deployment/scripts/deploy.sh --environment dev --target backend --verbose
```

**Shows:**
- Detailed operation steps
- Command outputs
- Debug information
- Full error traces

## Deployment Process

### Infrastructure Deployment Flow

```
AWS Credentials Check
        ↓
Terraform Init -upgrade
        ↓
Terraform Validate
        ↓
Terraform Plan
        ↓
(Dry-run? Return)
        ↓
Terraform Apply
        ↓
Verify Deployment
        ↓
✓ Success or ✗ Failure
```

### Backend Deployment Flow

```
AWS Credentials Check
        ↓
Docker Build
        ↓
ECR Push
        ↓
Get Current Task Definition
        ↓
Update Task Definition Image
        ↓
Update ECS Service
        ↓
Run Database Migrations
        ↓
Wait for Service Convergence
        ↓
Health Check
        ↓
✓ Success or ✗ Failure
```

## Log Files

### Location

```
deployment/scripts/logs/
├── deploy_20260218_102030.log
├── deploy_20260218_143045.log
└── ...
```

### Viewing Logs

```bash
# View latest logs
tail -100 deployment/scripts/logs/deploy_*.log

# Search for errors
grep -i error deployment/scripts/logs/deploy_*.log

# Watch real-time deployment
tail -f deployment/scripts/logs/deploy_*.log
```

### Log Contents Example

```
[INFO] Deployment script started
[INFO] Log file: deployment/scripts/logs/deploy_20260218_102030.log
[INFO] Deployment Plan:
[INFO]   Environment: dev
[INFO]   Target: backend
[INFO]   Version: latest
[INFO]   Dry-Run: false
[✓] AWS credentials valid (Account: 590184132516)
[INFO] Checking required tools...
[DEBUG] terraform installed
[DEBUG] aws installed
[DEBUG] docker installed
[✓] Pre-deployment checks passed
[INFO] ==========================================
[INFO] Starting Backend Application Deployment
[INFO] ==========================================
[INFO] Deploying backend to ECS cluster: rupaya-dev
[INFO] Found task definition revision
[INFO] Updated task definition
[INFO] Updated ECS service
[✓] Backend deployed successfully
```

## Environment-Specific Configurations

### Development (`--environment dev`)

- **AWS Cluster:** `rupaya-dev`
- **Services:** `rupaya-backend-dev`, `rupaya-frontend-dev`
- **Database:** Development database (smaller instance)
- **Confirmations:** Required
- **Backups:** Optional

### Staging (`--environment staging`)

- **AWS Cluster:** `rupaya-staging`
- **Services:** `rupaya-backend-staging`, `rupaya-frontend-staging`
- **Database:** Staging database (medium instance)
- **Confirmations:** Required
- **Backups:** Enabled
- **Monitoring:** Enhanced

### Production (`--environment prod`)

- **AWS Cluster:** `rupaya-prod`
- **Services:** `rupaya-backend-prod`, `rupaya-frontend-prod`
- **Database:** Production database (large instance)
- **Confirmations:** Required
- **Backups:** Always enabled
- **Monitoring:** Full monitoring
- **Safety Checks:** Enhanced production checks

## Error Handling & Recovery

### Deployment Failures

If deployment fails:

1. **Check logs:**
   ```bash
   tail -100 deployment/scripts/logs/deploy_*.log
   ```

2. **Review error message** in console

3. **Fix the issue**

4. **Retry deployment:**
   ```bash
   ./deployment/scripts/deploy.sh --environment dev --target backend
   ```

### Common Errors

#### AWS Credentials Error

```
ERROR: AWS credentials not configured or invalid
```

**Fix:**
```bash
aws configure
# or
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
```

#### Terraform Error

```
Error: Failed to initialize Terraform
```

**Fix:**
```bash
cd infra/aws
terraform init -upgrade
terraform validate
```

#### Docker Build Error

```
Error: Failed to build Docker image
```

**Fix:**
```bash
cd backend
docker build --no-cache -t rupaya .
```

#### ECS Deployment Error

```
Error: Failed to update ECS service
```

**Fix:**
```bash
# Check service status
aws ecs describe-services --cluster rupaya-dev --services rupaya-backend-dev

# Check for running tasks
aws ecs list-tasks --cluster rupaya-dev

# View service events
aws ecs describe-services --cluster rupaya-dev --services rupaya-backend-dev | jq '.services[0].events'
```

### Rollback Procedures

If deployment causes issues:

#### Rollback Infrastructure

```bash
# Revert to previous Terraform state
cd infra/aws
terraform show # Check what's deployed
terraform state list # List resources

# Revert specific resource
terraform destroy -target 'aws_ecs_service.backend'

# Or use destruction tool
deployment/scripts/destroy-infrastructure.sh --infra
```

#### Rollback Backend

```bash
# Update service to previous image
aws ecs update-service \
  --cluster rupaya-dev \
  --service rupaya-backend-dev \
  --force-new-deployment

# Or rollback database migrations
cd backend
npm run migrate:rollback-dev
```

#### Rollback Frontend

```bash
# Restore previous CloudFront invalidation
aws cloudfront create-invalidation \
  --distribution-id YOUR_DISTRIBUTION_ID \
  --paths "/*"

# Or revert S3 bucket version
aws s3api list-object-versions --bucket rupaya-frontend-dev
```

## Integration with CI/CD

### GitHub Actions

```yaml
name: Deploy

on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy'
        required: true
        type: choice
        options:
          - dev
          - staging
          - prod
      target:
        description: 'What to deploy'
        required: true
        type: choice
        options:
          - infra
          - backend
          - frontend
          - all

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Deploy
        run: |
          chmod +x deployment/scripts/deploy.sh
          deployment/scripts/deploy.sh \
            --environment ${{ github.event.inputs.environment }} \
            --target ${{ github.event.inputs.target }} \
            --confirm \
            --verbose
```

### GitLab CI

```yaml
deploy:
  stage: deploy
  script:
    - chmod +x deployment/scripts/deploy.sh
    - ./deployment/scripts/deploy.sh --environment $DEPLOY_ENV --target $DEPLOY_TARGET --confirm --verbose
  when: manual
  only:
    - main
    - develop
```

### Makefile Integration

```makefile
# Deploy targets
deploy-dev-backend:
	./deployment/scripts/deploy.sh --environment dev --target backend

deploy-staging-all:
	./deployment/scripts/deploy.sh --environment staging --target all --confirm

deploy-prod-infra:
	./deployment/scripts/deploy.sh --environment prod --target infra

deploy-prod-all:
	./deployment/scripts/deploy.sh --environment prod --target all --confirm --verbose
```

## Best Practices

### Before Deployment

- [ ] Review changes in code
- [ ] Run tests locally
- [ ] Check git status is clean
- [ ] Have backup/rollback plan
- [ ] Notify team of deployment
- [ ] Schedule during maintenance window (prod)

### During Deployment

- [ ] Monitor logs in real-time
- [ ] Watch AWS console for resource creation
- [ ] Keep rollback instructions handy
- [ ] Don't close terminal until complete

### After Deployment

- [ ] Verify health checks pass
- [ ] Test application functionality
- [ ] Check monitoring dashboards
- [ ] Document any issues
- [ ] Notify team of completion

## Troubleshooting

### Deployment Hung

```bash
# Check what's running
ps aux | grep terraform
ps aux | grep docker

# View logs
tail -f deployment/scripts/logs/deploy_*.log

# Kill stuck process
kill -9 <PID>
```

### State File Inconsistency

```bash
# Check state
terraform -chdir=infra/aws state list
terraform -chdir=infra/aws state show 'aws_ecs_service.backend'

# Refresh state
terraform -chdir=infra/aws refresh

# If corrupted, restore from backup
cp .state-backups/backup_XXX/terraform.tfstate infra/aws/
```

### Resources Not Updating

```bash
# Force new deployment
aws ecs update-service --cluster rupaya-dev --service rupaya-backend-dev --force-new-deployment

# Or redeploy
./deployment/scripts/deploy.sh --environment dev --target backend
```

## Version History

- **v1.0** (2026-02-18): Initial release
  - Infrastructure deployment
  - Backend deployment
  - Frontend deployment
  - Database migrations
  - Pre-deployment validation
  - Comprehensive logging
  - Dry-run support

## Related Documentation

- [DESTRUCTION_GUIDE.md](DESTRUCTION_GUIDE.md) - Infrastructure teardown
- [README.md](README.md) - Destruction tool overview
- [AWS_DEPLOYMENT_GUIDE.md](../AWS_DEPLOYMENT_GUIDE.md) - AWS best practices
- [DEPLOYMENT.md](../DEPLOYMENT.md) - Deployment overview
