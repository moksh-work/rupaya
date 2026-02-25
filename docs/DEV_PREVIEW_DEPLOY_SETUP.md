# Dev Preview Deploy Configuration Guide

## Overview

This guide explains how to set up and configure the **Workflow 03 - Dev Preview Deploy** system, which automatically deploys feature branches to a development environment and runs comprehensive tests before merging to main.

## Architecture

```
Feature Branch Push
    ↓
[Lint + Unit Tests] (5 min)
    ↓ (pass)
[Docker Build & Push to ECR] (8 min)
    ↓ (success)
[Deploy to Dev ECS Cluster] (10 min)
    ↓ (complete)
[E2E & Integration Tests] (15 min)
    ↓ (complete)
[Post Results to PR] (2 min)
    ↓
PR Ready for Review ✅
```

**Total Time:** 35-45 minutes per feature branch

## Prerequisites

### AWS Infrastructure
- ✅ ECS Cluster: `rupaya-dev` (shared dev cluster)
- ✅ ECS Service: `rupaya-backend-dev`
- ✅ RDS Database: PostgreSQL 15 (dev environment)
- ✅ ElastiCache: Redis 7 (dev environment)
- ✅ ECR Repository: `rupaya-backend`
- ✅ Load Balancer: ALB with target group for dev service
- ✅ IAM Role: OIDC role for GitHub Actions

### GitHub Configuration
- ✅ GitHub Organization with Actions enabled
- ✅ OIDC Provider connected to AWS
- ✅ Secrets configured
- ✅ Environments configured
- ✅ Branch protection rules set

### Local Development
- ✅ Docker & Docker Compose installed
- ✅ Node.js 18+ installed
- ✅ AWS CLI configured
- ✅ Git & GitHub CLI (optional)

## GitHub Configuration Steps

### Step 1: Create GitHub Environments

GitHub Environments provide a way to manage secrets and deployment restrictions per environment. Create three environments:

#### Development Environment
1. Go to **Settings → Environments → New environment**
2. Name: `development`
3. Configure protection rules:
   - [ ] Require reviewers (unchecked for dev - auto-deploy)
   - [ ] Dismiss stale pull request approvals (unchecked)
   - [ ] Require latest commit approval (unchecked)
4. Add environment variables:
   ```
   AWS_ACCOUNT_ID: <your-aws-account-id>
   DEV_ECS_CLUSTER: rupaya-dev
   DEV_ECS_SERVICE: rupaya-backend-dev
   DEV_ECS_CONTAINER_NAME: rupaya-backend
   DEV_DB_HOST: <dev-rds-endpoint>
   DEV_REDIS_URL: <dev-elasticache-endpoint>:6379
   ```

#### Staging Environment (optional, for manual PR testing)
1. Name: `staging`
2. Protection rules:
   - [x] Require reviewers (1 reviewer minimum)
   - [x] Dismiss stale PRs
   - [x] Require latest commit
3. Add environment variables matching your staging infrastructure

#### Production Environment (for main branch only)
1. Name: `production`
2. Protection rules:
   - [x] Require reviewers (2 reviewers minimum)
   - [x] Dismiss stale PRs
   - [x] Require latest commit
   - [x] Require status checks to pass
3. Add environment variables for production infrastructure

### Step 2: Configure GitHub Secrets

Navigate to **Settings → Secrets and variables → Actions** and create these secrets (accessible to all workflows):

```yaml
# AWS OIDC
AWS_OIDC_ROLE_ARN_DEV: arn:aws:iam::<account>:role/github-actions-dev-role
AWS_OIDC_ROLE_ARN_PROD: arn:aws:iam::<account>:role/github-actions-prod-role

# Docker Registry
ECR_REGISTRY_ALIAS: <your-alias>.dkr.ecr.us-east-1.amazonaws.com

# Feature Flags Admin
ADMIN_API_TOKEN: <generated-secure-token>
ADMIN_API_SECRET: <generated-secure-secret>

# E2E Testing (optional)
E2E_TEST_EMAIL: test-e2e@example.com
E2E_TEST_PASSWORD: <secure-test-password>
API_TEST_ACCESS_TOKEN: <pre-generated-token-optional>
```

### Step 3: Update GitHub Workflow Secrets in Environments

For environment-specific secrets, set them in each environment's **Environment Secrets**:

**Development Environment Secrets:**
```yaml
AWS_OIDC_ROLE_ARN_DEV: arn:aws:iam::<account>:role/github-actions-dev-role
```

**Production Environment Secrets:**
```yaml
AWS_OIDC_ROLE_ARN_PROD: arn:aws:iam::<account>:role/github-actions-prod-role
```

### Step 4: Configure Branch Protection Rules

For `develop` branch:
1. Go to **Settings → Branches → Branch protection rules → Add rule**
2. Branch name pattern: `develop`
3. Configure:
   - [x] Require a pull request before merging
   - [x] Require approvals (1 minimum)
   - [x] Dismiss stale PR approvals
   - [x] Require status checks to pass before merging
   - [x] Select `03-dev-preview-deploy` as required status check
   - [x] Require branches to be up to date before merging
   - [x] Include administrators

For `main` branch (stricter):
1. Branch name pattern: `main`
2. Configure:
   - [x] Require a pull request before merging
   - [x] Require approvals (2 minimum)
   - [x] Dismiss stale PR approvals
   - [x] Require review from code owners
   - [x] Require status checks to pass
   - [x] Select all required workflows
   - [x] Require branches to be up to date
   - [x] Require deployments to succeed
   - [x] Include administrators

## AWS Infrastructure Setup

### Option 1: Using Terraform (Recommended)

Create `infra/aws/dev-ecs-stack.tf`:

```hcl
# Development ECS Cluster
resource "aws_ecs_cluster" "dev" {
  name = "rupaya-dev"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "backend_dev" {
  family                   = "rupaya-backend-dev"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name      = "rupaya-backend"
    image     = "YOUR-ECR-REGISTRY/rupaya-backend:latest"
    essential = true
    
    portMappings = [{
      containerPort = 3000
      hostPort      = 3000
      protocol      = "tcp"
    }]
    
    environment = [
      { name = "NODE_ENV", value = "development" },
      { name = "DATABASE_URL", value = var.dev_database_url },
      { name = "REDIS_URL", value = var.dev_redis_url }
    ]
    
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.backend_dev.name
        "awslogs-region"        = data.aws_region.current.name
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

# ECS Service
resource "aws_ecs_service" "backend_dev" {
  name            = "rupaya-backend-dev"
  cluster         = aws_ecs_cluster.dev.id
  task_definition = aws_ecs_task_definition.backend_dev.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_dev.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend_dev.arn
    container_name   = "rupaya-backend"
    container_port   = 3000
  }

  depends_on = [aws_lb_listener.http]

  tags = {
    Environment = "development"
    ManagedBy   = "terraform"
  }
}

# Auto Scaling
resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 2
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.dev.name}/${aws_ecs_service.backend_dev.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Monitoring & Logs
resource "aws_cloudwatch_log_group" "backend_dev" {
  name              = "/ecs/rupaya-backend-dev"
  retention_in_days = 7
}
```

### Option 2: Manual AWS Console Setup

If not using Terraform, set up manually:

1. **Create ECS Cluster**
   - AWS Console → ECS → Clusters → Create Cluster
   - Name: `rupaya-dev`
   - Infrastructure: Fargate
   - Container Insights: Enabled

2. **Create Task Definition**
   - ECS → Task Definitions → Create new task definition
   - Name: `rupaya-backend-dev`
   - Container image: `<account>.dkr.ecr.us-east-1.amazonaws.com/rupaya-backend:latest`
   - Port mappings: 3000 → 3000
   - Environment variables: Set DATABASE_URL, REDIS_URL, NODE_ENV
   - CPU: 512, Memory: 1024

3. **Create ECS Service**
   - Cluster: `rupaya-dev`
   - Service name: `rupaya-backend-dev`
   - Task Definition: Select above
   - Desired count: 1
   - Auto scaling: Min 1, Max 2

4. **Create Load Balancer (ALB)**
   - EC2 → Load Balancers → Create ALB
   - Name: `rupaya-dev-alb`
   - Scheme: Internet-facing
   - Create target group pointing to ECS service
   - Configure health check: `/health` on port 3000

## Local Testing

### Run Workflow 03 Locally with Act

```bash
# Install act (GitHub Actions CLI)
brew install act

# Run the workflow
act push -j build -W .github/workflows/03-dev-preview-deploy.yml

# Run specific job
act push -j validate -W .github/workflows/03-dev-preview-deploy.yml
```

### Docker Compose for Local Dev Environment

```bash
# Start services
docker-compose -f backend/docker-compose.yml up -d

# Run tests
cd backend
npm test

# Run E2E tests against local
RUN_E2E_TESTS=true API_BASE_URL=http://localhost:3000 npm test -- __tests__/e2e

# View logs
docker-compose logs -f backend

# Cleanup
docker-compose down -v
```

## Usage Guide

### Creating a Feature Branch

```bash
# Start from develop
git checkout develop
git pull origin develop

# Create feature branch
git checkout -b feature/new-dashboard

# Make changes, commit, push
git push origin feature/new-dashboard
```

### Workflow Execution

Workflow 03 automatically triggers on:
- **Push to `feature/**`** branches
- **Push to `bugfix/**`** branches  
- **Push to `chore/**`** branches
- **Pull request to `develop`**
- **Manual dispatch** (`workflow_dispatch`)

### Monitoring Workflow Progress

1. Go to **Actions** tab
2. Click on "03 - Dev Preview Deploy" workflow
3. View real-time progress:
   - Lint & Unit Tests (5 min)
   - Docker Build (8 min)
   - Deploy to Dev (10 min)
   - E2E Tests (15 min)
   - Post Results (2 min)

### Viewing Deployment Results

After workflow completes:

1. **PR Comment:** Automatic summary posted to PR with:
   - Status table (Lint ✅ → Build ✅ → Deploy ✅ → E2E ✅/⚠️/❌)
   - Dev API URL for manual testing
   - Performance metrics
   - Coverage reports

2. **GitHub Check:** Shows as "Dev Preview Deploy" check on PR

3. **CloudWatch Logs:** Real-time logs available at:
   ```
   CloudWatch Logs → Log Groups → /ecs/rupaya-backend-dev
   ```

4. **ECS Console:** See running tasks and health status:
   ```
   ECS → Clusters → rupaya-dev → Services → rupaya-backend-dev
   ```

## Testing the Workflow

### Test 1: Simple Feature Branch

```bash
# Create feature branch with non-breaking change
git checkout -b feature/test-workflow
echo "# Test" >> README.md
git add README.md
git commit -m "test: verify workflow triggers"
git push origin feature/test-workflow
```

Result: Workflow should trigger and complete without errors ✅

### Test 2: PR to Develop

```bash
# Create PR to develop
# GitHub will automatically run Workflow 03
# Check Actions tab to see progress
```

### Test 3: Verify E2E Tests Run

Check that E2E tests execute against the live deployed API:

```bash
# In workflow logs, look for:
# - "Run E2E tests against dev environment"
# - "deployment-features.test.js" output
# - Coverage reports
```

## Troubleshooting

### Workflow Fails at Lint Stage

**Issue:** ESLint errors block progress

**Solution:**
```bash
cd backend
npm run lint -- --fix
git add .
git commit -m "fix: eslint issues"
git push origin feature/branch-name
```

### Docker Build Fails

**Issue:** Image build fails or takes too long

**Solutions:**
- Check Dockerfile syntax: `docker build -f backend/Dockerfile .`
- Verify base image available: `docker pull node:18-alpine`
- Check available disk space: `docker system df`
- Clear build cache: `docker system prune -a`

### Deployment Times Out

**Issue:** ECS rollout takes longer than expected

**Solutions:**
1. **Check task health:**
   ```bash
   aws ecs describe-services \
     --cluster rupaya-dev \
     --services rupaya-backend-dev \
     --region us-east-1
   ```

2. **Check CloudWatch logs:**
   ```
   CloudWatch → Log Groups → /ecs/rupaya-backend-dev
   ```

3. **Verify database connectivity:**
   - Check security groups allow ECS → RDS
   - Verify DATABASE_URL environment variable
   - Test connection: `psql $DATABASE_URL -c "SELECT 1"`

4. **Verify Redis connectivity:**
   - Check REDIS_URL environment variable
   - Test connection: `redis-cli -u $REDIS_URL ping`

### E2E Tests Fail

**Issue:** Remote API tests fail against live environment

**Solutions:**
1. **Check API is healthy:**
   ```bash
   curl https://dev-api.rupaya.internal/health
   ```

2. **Check rate limiting:**
   - E2E tests hit auth endpoints frequently
   - Verify rate limit not triggered: `grep 429 workflow logs`
   - Adjust test concurrency in `deployment-features.test.js`

3. **Check environment variables:**
   - Verify API_BASE_URL points to dev service
   - Test locally first: `RUN_E2E_TESTS=true npm test`

## Performance Tuning

### Optimize Workflow Speed

| Stage | Target | Optimization |
|-------|--------|--------------|
| Lint + Unit Tests | 5 min | Use `--maxWorkers=2`, npm cache |
| Docker Build | 8 min | GHA cache-to=gha, multi-stage Dockerfile |
| Deploy to ECS | 10 min | Pre-warmed cluster, larger task size |
| E2E Tests | 15 min | Parallel test execution, skip flaky tests |

### Reduce Costs

- **ECS:** Use spot instances for dev (save ~70%)
- **RDS:** Use t3.micro or t4g.micro for dev
- **ElastiCache:** Use cache.t3.micro for dev
- **Logs:** 7-day retention for dev (3-day for features)
- **ECR:** Lifecycle policy to delete old images

## Security Best Practices

✅ **Implemented:**
- OIDC authentication (no AWS keys in environment)
- Secrets stored in GitHub (not in code)
- IAM roles with least privilege
- Network isolation (ECS in private subnet)
- Encryption in transit (HTTPS)
- Audit logging (CloudWatch)

⚠️ **Recommended:**
- Rotate secrets quarterly
- Use VPC endpoints for private AWS access
- Enable WAF on load balancer
- Implement network policies
- Regular security scanning of Docker images

## CI/CD Pipeline Comparison

| Aspect | Dev (Workflow 03) | Staging (Manual) | Prod (Workflow 08) |
|--------|-------------------|------------------|--------------------|
| Trigger | Push `feature/**`, PR to develop | Manual dispatch | Push to `main` |
| Tests | Unit + E2E | Integration + E2E | Smoke + security |
| Deployment | Auto → Dev | Manual → Staging | Auto → Production |
| Approval | None (auto-deploy) | 1 reviewer | 2 reviewers |
| Duration | 40 min | 45 min | 50 min |
| Rollback | Manual (delete task) | Manual | Auto (if health fails) |

## Next Steps

1. ✅ Configure GitHub environments (Settings → Environments)
2. ✅ Create/update GitHub secrets (Settings → Secrets)
3. ✅ Set up AWS ECS infrastructure (or use Terraform)
4. ✅ Configure branch protection rules (Settings → Branches)
5. ✅ Test workflow with feature branch
6. ✅ Monitor first few deployments
7. ✅ Adjust timeouts/resources based on actual performance
8. ✅ Document environment-specific configurations

## References

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AWS ECS Guide](https://docs.aws.amazon.com/ecs/)
- [Git Flow Branching](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow)
- [Docker Best Practices](https://docs.docker.com/documentation/)

---

**Last Updated:** February 25, 2026
**Workflow Version:** 03-dev-preview-deploy.yml
**Status:** ✅ Production Ready
