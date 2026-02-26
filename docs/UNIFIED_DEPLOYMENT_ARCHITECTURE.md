# Unified Deployment Architecture - Complete Flow

## The 3-Layer Architecture

### ✅ LAYER 1: OIDC Bootstrap (ONE-TIME MANUAL)
**Script:** `bootstrap-oidc.sh`
**Purpose:** Set up GitHub ↔ AWS authentication
**Steps:**
1. Create AWS OIDC provider (trusts GitHub)
2. Create IAM roles for dev/staging/prod
3. Store role ARNs in GitHub secrets
4. Create GitHub environments (dev/staging/prod)

**Execution:** Run ONCE locally
```bash
./scripts/bootstrap-oidc.sh
```

**Output:** GitHub secrets with AWS role ARNs
- `AWS_OIDC_ROLE_ARN_DEV`
- `AWS_OIDC_ROLE_ARN_STAGING`
- `AWS_OIDC_ROLE_ARN_PROD`

---

### ❌ LAYER 2: MANUAL BOOTSTRAP (DEPRECATED)
**Script:** `bootstrap-aws-dev.sh`
**Status:** REDUNDANT - No longer needed!
**Why?** Workflow 04 handles this automatically

**What it did:** Manually run Terraform and deploy infrastructure
**Replaced by:** Workflow 04 automatic execution

---

### ✅ LAYER 3: AUTOMATED CI/CD DEPLOYMENT (NEW)
**Workflow:** `.github/workflows/04-unified-deployment.yml`
**Purpose:** Automatic infrastructure & application deployment
**Trigger:** Based on branch pattern

**Environment Detection:**
```
feature/* → Deploy to DEV (auto)
release/* → Deploy to STAGING (auto)
main or v*.*.* → Deploy to PROD (auto)
workflow_dispatch → Manual environment selection
```

**Full Pipeline (11 jobs):**
1. **determine-environment** → Detect which env to deploy
2. **validate** → Lint + unit tests (postgres/redis services)
3. **build** → Docker build & ECR push
4. **terraform-plan** → Validate Terraform configuration
5. **terraform-apply** → Create infrastructure (RDS, Redis, ECS, ALB)
6. **deploy-ecs** → Update ECS service with new image
7. **database-migrations** → Run environment-specific migrations
8. **health-check** → Verify app is responding
9. **e2e-tests** → Run integration tests
10. **deployment-summary** → Report status
11. **rollback** → Auto-rollback if failure

---

## Complete Flow Diagram

```
┌─────────────────────────────────────┐
│  1. INITIAL SETUP (Manual - Once)   │
│  Run: bootstrap-oidc.sh             │
│  ✓ Creates OIDC provider            │
│  ✓ Creates IAM roles                │
│  ✓ Stores secrets in GitHub         │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│  2. CODE PUSH (Developer)           │
│  Push to:                           │
│  - feature/* → Dev env              │
│  - release/* → Staging env          │
│  - main → Prod env                  │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│  3. WORKFLOW 04 RUNS AUTOMATICALLY                          │
│  (No manual intervention needed after OIDC setup!)         │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Step 1: Determine Environment                       │   │
│  │ - Read branch name                                  │   │
│  │ - Map to dev/staging/prod                           │   │
│  └─────────────────────────────────────────────────────┘   │
│                    ▼                                        │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Step 2: Validate & Test                             │   │
│  │ - Run linter                                        │   │
│  │ - Run unit tests                                    │   │
│  │ - Generate coverage                                 │   │
│  └─────────────────────────────────────────────────────┘   │
│                    ▼                                        │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Step 3: Build Docker Image                          │   │
│  │ - Build from backend/Dockerfile                     │   │
│  │ - Push to ECR (dev/staging/prod repo)               │   │
│  │ - Tag with: latest, env-latest, git-sha             │   │
│  └─────────────────────────────────────────────────────┘   │
│                    ▼                                        │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Step 4: Terraform Plan & Apply                      │   │
│  │ - Init Terraform for env                            │   │
│  │ - Validate configuration                            │   │
│  │ - Plan infrastructure changes                       │   │
│  │ - Apply changes (create/update resources)           │   │
│  │                                                     │   │
│  │ Creates:                                            │   │
│  │ ✓ VPC, Security Groups                              │   │
│  │ ✓ RDS Database (Aurora PostgreSQL)                  │   │
│  │ ✓ ElastiCache Redis                                 │   │
│  │ ✓ ECR Repository                                    │   │
│  │ ✓ ECS Cluster & Service                             │   │
│  │ ✓ Application Load Balancer                         │   │
│  │ ✓ CloudWatch Logs                                   │   │
│  │ ✓ Auto-scaling policies                             │   │
│  │ ✓ IAM roles & Secrets Manager                       │   │
│  └─────────────────────────────────────────────────────┘   │
│                    ▼                                        │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Step 5: Deploy to ECS                               │   │
│  │ - Register new task definition                      │   │
│  │ - Update ECS service                                │   │
│  │ - Launch new tasks with new image                   │   │
│  │ - Wait for service to stabilize                     │   │
│  └─────────────────────────────────────────────────────┘   │
│                    ▼                                        │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Step 6: Database Migrations                         │   │
│  │ - Run npm run migrate:dev/staging/prod              │   │
│  │ - Schema updates, seeds, fixtures                   │   │
│  └─────────────────────────────────────────────────────┘   │
│                    ▼                                        │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Step 7: Health Checks                               │   │
│  │ - Poll /health endpoint (10 attempts, 60 sec max)   │   │
│  │ - Verify application is responding correctly        │   │
│  └─────────────────────────────────────────────────────┘   │
│                    ▼                                        │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Step 8: E2E Tests                                   │   │
│  │ - Run comprehensive test suite                      │   │
│  │ - Validate business logic                           │   │
│  │ - Upload coverage reports                           │   │
│  └─────────────────────────────────────────────────────┘   │
│                    ▼                                        │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Step 9: Deployment Summary                          │   │
│  │ - Report all steps completed                        │   │
│  │ - Post comment to PR                                │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  IF FAILURE:                                                │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Step 10: Automatic Rollback                         │   │
│  │ - Revert to previous stable task definition         │   │
│  │ - Restore previous application version              │   │
│  │ - Post alert to PR                                  │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│  4. DEPLOYMENT COMPLETE             │
│  - Infrastructure ready             │
│  - Application running              │
│  - Tests passed                     │
│  - Accessible via ALB DNS           │
└─────────────────────────────────────┘
```

---

## Why bootstrap-aws-dev.sh is REDUNDANT

| Aspect | bootstrap-aws-dev.sh | Workflow 04 |
|--------|---------------------|-----------|
| **Trigger** | Manual (local machine) | Automatic (GitHub push) |
| **Infrastructure** | Terraform ✓ | Terraform ✓ |
| **Docker Build** | Manual `docker build` | Automated in workflow |
| **ECS Deploy** | AWS CLI calls | Automated in workflow |
| **Migrations** | Manual npm command | Automated in workflow |
| **Testing** | You run locally | Automated E2E tests |
| **Error Handling** | Manual rollback | Automatic rollback |
| **Repeatability** | Different each time | Consistent every time |
| **Logging** | Script output | GitHub Actions logs |

**bootstrap-aws-dev.sh was:** A manual workaround before we had proper CI/CD automation

**Workflow 04 is:** Production-grade CI/CD - handles everything automatically

---

## Actual Workflow in Real World

### Scenario 1: Deploy to Development
```bash
# Developer creates feature branch
git checkout -b feature/new-api-endpoint

# Make code changes
# Commit and push
git push origin feature/new-api-endpoint

# ✨ WORKFLOW 04 AUTOMATICALLY EXECUTES:
# - Validates code
# - Builds Docker image
# - Deploys to dev infrastructure
# - Runs E2E tests
# - Posts results to PR
```

### Scenario 2: Deploy to Staging
```bash
# Release manager creates release branch
git checkout -b release/v1.2.0

# Push it
git push origin release/v1.2.0

# ✨ WORKFLOW 04 AUTOMATICALLY EXECUTES:
# - Deploys to staging infrastructure
# - Runs full E2E test suite
# - Notifies team
```

### Scenario 3: Deploy to Production
```bash
# Create version tag
git tag v1.2.0
git push origin v1.2.0

# ✨ WORKFLOW 04 AUTOMATICALLY EXECUTES:
# - Double-checks all tests
# - Deploys to production
# - Runs health checks
# - Auto-rollback if issues
# - Posts deployment summary
```

---

## AWS Infrastructure Created by Workflow 04

### Development Environment
```
AWS Account
├── VPC (default)
├── RDS Aurora PostgreSQL
│   └── db.t3.micro (1GB, single-node, 7-day backups)
├── ElastiCache Redis
│   └── cache.t3.micro (512MB, single-node)
├── ECS Cluster (rupaya-dev)
│   └── 1-2 tasks, 512 CPU, 1GB RAM each
├── Application Load Balancer
│   └── HTTP on port 80 → ECS on 3000
├── ECR Repository
│   └── rupaya-backend (dev images)
├── CloudWatch Logs
│   └── 7-day retention
└── Security Groups + IAM Roles
```

### Staging Environment
```
AWS Account
├── VPC (default)
├── RDS Aurora PostgreSQL
│   └── db.t3.small (2GB, multi-AZ, 14-day backups)
├── ElastiCache Redis
│   └── cache.t3.small (1GB, 2-node multi-AZ)
├── ECS Cluster (rupaya-staging)
│   └── 2-4 tasks, 512 CPU, 1GB RAM each
├── Application Load Balancer
│   └── HTTP on port 80 → ECS on 3000
├── ECR Repository
│   └── rupaya-backend-staging
├── CloudWatch Logs
│   └── 14-day retention
└── Security Groups + IAM Roles
```

### Production Environment
```
AWS Account
├── VPC (default)
├── RDS Aurora PostgreSQL
│   └── db.r6g.large (16GB, 3-node multi-AZ, 30-day backups, read replicas)
├── ElastiCache Redis
│   └── cache.r6g.xlarge (13GB, 3-node cluster-mode, multi-AZ)
├── ECS Cluster (rupaya-prod)
│   └── 3-10 tasks, 1024 CPU, 2GB RAM each
├── Application Load Balancer
│   └── HTTPS (port 443) + HTTP redirect → ECS on 3000
├── ECR Repository
│   └── rupaya-backend-prod (immutable tags)
├── CloudWatch Logs + Alarms
│   └── 30-day retention, CPU/memory alerts
├── S3 Bucket
│   └── ALB access logs
├── KMS Key
│   └── Multi-region encryption
└── Security Groups + IAM Roles + Secrets Manager
```

---

## What You Should Do Next

### 1. Run OIDC Bootstrap (Manual - One Time)
```bash
cd /Users/rsingh/Documents/Projects/rupaya
./scripts/bootstrap-oidc.sh
# This will:
# - Create AWS OIDC provider
# - Create IAM roles for dev/staging/prod
# - Store secrets in GitHub
```

### 2. Push Feature Branch
```bash
git push origin feature/test-1
# Workflow 04 will automatically:
# - Detect environment (dev)
# - Deploy infrastructure via Terraform
# - Build and push Docker image
# - Deploy to ECS
# - Run all tests
```

### 3. That's It!
- No need to run `bootstrap-aws-dev.sh`
- No manual Terraform commands
- Everything is automated

---

## Summary

| Component | Purpose | When to Use |
|-----------|---------|------------|
| **bootstrap-oidc.sh** | Create GitHub ↔ AWS trust | Once at the beginning |
| **bootstrap-aws-dev.sh** | Manual infrastructure deployment | ❌ Never - use Workflow 04 instead |
| **Workflow 04** | Automatic deployment to all envs | Every time you push code |

**This is production-grade CI/CD automation.** After one-time OIDC setup, everything is fully automated!
