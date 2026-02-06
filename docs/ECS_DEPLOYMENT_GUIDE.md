# ECS Deployment Guide

## Overview

This guide ensures correct Docker image builds for AWS ECS Fargate deployments. The critical requirement is building images for the **linux/amd64** platform, not ARM64 (macOS native).

## Quick Deploy Commands

### Option 1: Manual Deployment (Immediate)

```bash
cd /Users/rsingh/Documents/Projects/rupaya/backend

# Deploy with default version tag
./deploy-to-ecs.sh

# Deploy with custom version
./deploy-to-ecs.sh v2.0 rupaya-ecs rupaya-backend
```

### Option 2: GitHub Actions CI/CD (Automated)

Push to `main` branch - automatically triggers build and deploy:

```bash
git push origin main
```

Manual trigger via GitHub Actions UI with custom version:
- Go to Actions → "Deploy to ECS" → "Run workflow"
- Enter version tag (e.g., v2.0)

### Option 3: Command Line CI/CD Trigger

```bash
# Via GitHub CLI
gh workflow run deploy-ecs.yml -f version=v2.0

# Via GitHub API
curl -X POST \
  -H "Authorization: token YOUR_GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/YOUR_USER/rupaya/actions/workflows/deploy-ecs.yml/dispatches \
  -d '{"ref":"main","inputs":{"version":"v2.0"}}'
```

## What Gets Deployed

### build-and-push.sh (6 Steps)

1. **Verify Docker available** - Check docker version and daemon running
2. **Verify docker buildx** - Ensure multi-platform build support
3. **Verify Dockerfile exists** - Check dockerfile-path is readable
4. **ECR authentication** - Auto-login to AWS ECR if needed
5. **Build & Push image** - `docker buildx build --platform linux/amd64 --push`
6. **Verify in ECR** - Confirm image exists with correct platform

### deploy-to-ecs.sh (7 Steps)

1. **Build image** - Calls build-and-push.sh
2. **Get current task definition** - Retrieve existing ECS task configuration
3. **Register new task definition** - Create new version with updated image
4. **Update ECS service** - Deploy new task definition
5. **Wait for stabilization** - Monitor deployment (5-minute timeout)
6. **Verify deployment** - Check running tasks match desired count
7. **Health checks** - Test `/health` endpoint with retries

### GitHub Actions Workflow

1. **Checkout code** - Clone repository
2. **Configure AWS credentials** - Set up authentication
3. **Setup Docker Buildx** - Enable multi-platform builds
4. **Login to ECR** - Authenticate with registry
5. **Build & Push image** - Multi-platform build for linux/amd64
6. **Verify image** - Confirm in ECR
7. **Get current task def** - Retrieve existing configuration
8. **Register new task def** - Create new version with updated image
9. **Update service** - Deploy to ECS
10. **Wait for stability** - Monitor deployment
11. **Verify & health check** - Confirm service is healthy

## Critical: linux/amd64 Platform

### Why This Matters

**Problem**: The previous deployment failed with this error:
```
CannotPullContainerError: image Manifest does not contain descriptor matching platform 'linux/amd64'
```

**Root Cause**: Docker image built on macOS creates ARM64 architecture (Apple Silicon native)
- macOS (Apple Silicon): `linux/arm64`
- AWS ECS Fargate: requires `linux/amd64`

**Solution**: Always specify `--platform linux/amd64` when building:

```bash
# ✓ CORRECT - ECS compatible
docker buildx build --platform linux/amd64 -t myimage:latest --push .

# ✗ WRONG - Will fail on ECS
docker build -t myimage:latest .
docker buildx build -t myimage:latest --push .
```

## Setup Instructions

### 1. Prerequisites

```bash
# Verify Docker installed
docker --version

# Verify docker buildx available
docker buildx version

# Verify AWS CLI installed
aws --version

# Verify jq installed (JSON processor)
jq --version  # Or: brew install jq
```

### 2. GitHub Actions Setup (First Time Only)

**Add AWS credentials to GitHub Secrets:**

1. Go to GitHub repo → Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Add three secrets:
   ```
   AWS_ACCESS_KEY_ID: <your-access-key>
   AWS_SECRET_ACCESS_KEY: <your-secret-key>
   AWS_ACCOUNT_ID: 843976229340
   ```

**Verify workflow file:**
```bash
cd /Users/rsingh/Documents/Projects/rupaya
cat .github/workflows/deploy-ecs.yml
```

### 3. Local Script Setup

Scripts are already executable:

```bash
cd /Users/rsingh/Documents/Projects/rupaya/backend
ls -la build-and-push.sh deploy-to-ecs.sh
# Should show: -rwxr-xr-x (executable)
```

If not executable, fix with:
```bash
chmod +x build-and-push.sh deploy-to-ecs.sh
```

## Deployment Workflows

### Workflow A: Quick Manual Deploy

**When**: Make changes to backend, want to deploy immediately

```bash
cd /Users/rsingh/Documents/Projects/rupaya/backend
./deploy-to-ecs.sh latest rupaya-ecs rupaya-backend
```

**Output**:
```
🐳 Build-and-Push Pipeline
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ Step 1: Docker available (v27.0.0)
✓ Step 2: docker buildx available
✓ Step 3: Dockerfile found
✓ Step 4: ECR authenticated
✓ Step 5: Image built and pushed (linux/amd64)
✓ Step 6: Image verified in ECR

Image URI: 843976229340.dkr.ecr.us-east-1.amazonaws.com/rupaya-backend:latest
...
```

### Workflow B: Automated Git Push Deploy

**When**: Using GitHub for version control, want auto-deploy

```bash
cd /Users/rsingh/Documents/Projects/rupaya

# Make backend changes
vim backend/src/app.js

# Commit and push
git add backend/
git commit -m "Add new feature"
git push origin main
```

**Result**: GitHub Actions automatically:
1. Triggers on push to main
2. Builds `linux/amd64` image
3. Tags as `v{run_number}-{commit_sha}`
4. Pushes to ECR
5. Updates ECS service
6. Verifies health

**Monitor in GitHub UI**:
- Go to Actions tab
- Click "Deploy to ECS" workflow
- Watch real-time build progress

### Workflow C: Versioned Release Deploy

**When**: Preparing production release with version number

```bash
cd /Users/rsingh/Documents/Projects/rupaya

# Make backend changes
git add backend/
git commit -m "Release v2.0 - Add budget tracking"
git push origin main

# Trigger deployment with specific version via GitHub Actions UI
# Or use: gh workflow run deploy-ecs.yml -f version=v2.0
```

**Result**: Deployment tagged as `v2.0` in ECR and ECS

## Deployment Verification

### Check Deployment Status

```bash
# List running tasks
aws ecs list-tasks \
  --cluster rupaya-ecs \
  --service-name rupaya-backend \
  --desired-status RUNNING \
  --region us-east-1

# Get service status
aws ecs describe-services \
  --cluster rupaya-ecs \
  --services rupaya-backend \
  --region us-east-1 \
  --query 'services[0].[serviceName,status,runningCount,desiredCount]'

# Check task details
aws ecs describe-tasks \
  --cluster rupaya-ecs \
  --tasks <task-arn> \
  --region us-east-1 \
  --query 'tasks[0].[taskArn,lastStatus,pullStartedAt,startedAt]'
```

### Health Check

```bash
# Get ALB DNS
ALB_DNS=$(aws elbv2 describe-load-balancers \
  --query "LoadBalancers[?LoadBalancerName=='rupaya-alb'].DNSName" \
  --output text \
  --region us-east-1)

# Test health endpoint
curl -s http://$ALB_DNS/health | jq .
# Expected: {"status":"OK","timestamp":"2026-02-01T16:03:15.386Z"}

# Test API endpoint
curl -s http://$ALB_DNS/api/dashboard -H "Authorization: Bearer YOUR_TOKEN" | jq .
```

### View Logs

```bash
# Get latest logs from CloudWatch
aws logs tail /ecs/rupaya-backend --follow --region us-east-1

# Get last 100 lines
aws logs tail /ecs/rupaya-backend --max-items 100 --region us-east-1

# Get logs from specific time
aws logs tail /ecs/rupaya-backend \
  --since 1h \
  --follow \
  --region us-east-1
```

## Image Platform Verification

### Verify Image in ECR Has Correct Platform

```bash
# Get image manifest
aws ecr batch-get-image \
  --repository-name rupaya-backend \
  --image-ids imageTag=latest \
  --region us-east-1 \
  --query 'images[0].imageManifest' | jq .

# Check platform in manifest
aws ecr batch-get-image \
  --repository-name rupaya-backend \
  --image-ids imageTag=latest \
  --region us-east-1 \
  --query 'images[0].imageManifest' | \
  jq '.manifests[] | select(.platform.architecture=="amd64")'
```

**Expected output**: Should show `"architecture":"amd64"` (NOT `arm64`)

### List All Image Variants

```bash
aws ecr describe-images \
  --repository-name rupaya-backend \
  --region us-east-1 \
  --query 'imageDetails[*].[imageTags[0],imageSizeInBytes,imagePushedAt]' \
  --output table
```

## Troubleshooting

### Problem: "image Manifest does not contain descriptor matching platform"

**Cause**: Image was built on macOS without `--platform linux/amd64`

**Fix**:
```bash
# Rebuild with correct platform
cd backend
docker buildx build --platform linux/amd64 -t 843976229340.dkr.ecr.us-east-1.amazonaws.com/rupaya-backend:latest --push .
```

### Problem: "CannotPullContainerError: image not found in repository"

**Cause**: Image wasn't pushed to ECR or wrong repository name

**Fix**:
```bash
# Login to ECR first
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin 843976229340.dkr.ecr.us-east-1.amazonaws.com

# Rebuild and push
cd backend
docker buildx build --platform linux/amd64 \
  -t 843976229340.dkr.ecr.us-east-1.amazonaws.com/rupaya-backend:latest \
  --push .

# Verify image exists
aws ecr describe-images \
  --repository-name rupaya-backend \
  --region us-east-1
```

### Problem: "UnknownServiceException: The specified service does not exist"

**Cause**: Wrong cluster or service name

**Fix**:
```bash
# List available services
aws ecs list-services --cluster rupaya-ecs --region us-east-1

# Update deploy script with correct values
./deploy-to-ecs.sh latest rupaya-ecs rupaya-backend
```

### Problem: "Task failed with error 'insufficient memory'"

**Cause**: Container needs more memory allocated

**Fix**:
```bash
# Edit Terraform variable
vi /Users/rsingh/Documents/Projects/rupaya/infra/aws/variables.tf

# Find: variable "container_memory"
# Increase from 512 to 1024

# Redeploy infrastructure
cd infra/aws
terraform plan -out=tfplan
terraform apply tfplan
```

## Rollback Procedure

If deployment has issues, quickly rollback to previous version:

```bash
# List previous task definitions
aws ecs describe-task-definition \
  --task-definition rupaya-backend \
  --region us-east-1

# Get previous revision number
PREVIOUS_REVISION=$(aws ecs describe-task-definition \
  --task-definition rupaya-backend:N \
  --region us-east-1 \
  --query 'taskDefinition.taskDefinitionArn' \
  --output text)

# Rollback service to previous task definition
aws ecs update-service \
  --cluster rupaya-ecs \
  --service rupaya-backend \
  --task-definition $PREVIOUS_REVISION \
  --region us-east-1

# Wait for rollback
aws ecs wait services-stable \
  --cluster rupaya-ecs \
  --services rupaya-backend \
  --region us-east-1

echo "✓ Rolled back to previous version"
```

## Automated Deployment Checklist

Before each deployment, verify:

- [ ] Code is committed to git
- [ ] Backend changes tested locally
- [ ] No uncommitted changes: `git status`
- [ ] Dockerfile is present: `cat backend/Dockerfile | head -5`
- [ ] Docker buildx available: `docker buildx version`
- [ ] AWS credentials configured: `aws sts get-caller-identity`
- [ ] ECR repository exists: `aws ecr describe-repositories --repository-names rupaya-backend --region us-east-1`
- [ ] ECS cluster exists: `aws ecs describe-clusters --clusters rupaya-ecs --region us-east-1`
- [ ] ECS service exists: `aws ecs describe-services --cluster rupaya-ecs --services rupaya-backend --region us-east-1`

## Reference

### Key Files

- **Manual Deploy Scripts**:
  - [build-and-push.sh](../backend/build-and-push.sh) - Docker build validation
  - [deploy-to-ecs.sh](../backend/deploy-to-ecs.sh) - Complete deployment pipeline

- **Automated Deploy**:
  - [.github/workflows/deploy-ecs.yml](../.github/workflows/deploy-ecs.yml) - GitHub Actions workflow

- **Infrastructure as Code**:
  - [infra/aws/](../infra/aws/) - Terraform configuration

### AWS Resources

- **ECS Cluster**: rupaya-ecs (us-east-1)
- **ECR Repository**: rupaya-backend
- **Load Balancer**: rupaya-alb (ALB)
- **API Endpoint**: `http://rupaya-alb-252480753.us-east-1.elb.amazonaws.com`
- **Health Endpoint**: `/health`

### Deployment Metrics

- **Build Time**: ~2-3 minutes (local), ~3-5 minutes (GitHub Actions)
- **Deployment Time**: ~2-3 minutes (ECS stabilization)
- **Total Time**: ~5-8 minutes (end-to-end)
- **Rollback Time**: ~1-2 minutes

---

**Last Updated**: 2026-02-01
**Status**: Production Ready ✓
