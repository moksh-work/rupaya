# GitHub Actions Workflows - Complete Execution Sequence

## Overview: 16 Workflows (00-15) + 1 Unified Deployment

This document shows how workflows trigger and execute in sequence based on Git events.

---

## 📋 Workflow Index

| # | Name | Trigger | Type |
|---|------|---------|------|
| 00 | Test OIDC | Manual | Utility |
| 01 | Fast Feedback | Feature/* push, PR | Validation |
| 02 | Mobile Build Check | Any branch push/PR | Mobile Build |
| 03 | Android Build & Release | main push, PR, Manual | Android Build |
| 04 | iOS Build & Release | Manual only | iOS Build |
| **04** | **Unified Multi-Env Deploy** | **feature/*, release/*, main, tags, Manual** | **NEW - Replaces 10-14** |
| 05 | Dev Preview Deploy | feature/*, PR to develop | Dev Deploy |
| 06 | PR Test Suite | PR to develop | PR Validation |
| 07 | Release Test Suite | release/* PR/push, Manual | Release Validation |
| 08 | Main Test Suite | main push | Production Validation |
| 09 | Backend CI/CD | main PR/push | Backend Deploy |
| 10 | Terraform Infrastructure | feature/*, release/*, main, PR, Manual | Infrastructure |
| 11 | RDS Migrations | main, develop, release/*, Manual | Database |
| 12 | ECS Deploy | Manual only | ECS Deploy |
| 13 | Deploy to Staging | Manual only | Staging Deploy |
| 14 | Deploy to Production | main push, v*.*.* tags, Manual | Prod Deploy |
| 15 | Manage Feature Flags | Manual only | Feature Management |

---

## 🔄 Execution Sequences

### Scenario 1: Feature Branch Development
**Trigger:** Developer pushes to `feature/new-api-endpoint`

```
Time  Workflow                Status
─────────────────────────────────────────────────────
1ms   → 01-validation         START (lint, unit tests)
5ms   → 02-mobile-build       START (parallel with 01)
10ms  ← 01-validation         ✅ PASS (5 min)
15ms  ← 02-mobile-build       ✅ PASS (5 min)
      
20ms  → 04-unified-deploy     START (detects: feature/* → dev)
      ├─ determine-env        → dev
      ├─ validate            → tests
      ├─ build               → Docker image
      ├─ terraform-plan      → Infrastructure plan
      ├─ terraform-apply     → Create RDS, Redis, ECS, ALB
      ├─ deploy-ecs          → Deploy app to ECS
      ├─ migrations          → Run DB migrations
      ├─ health-check        → Verify app is healthy
      └─ e2e-tests           → Full integration tests
      ✨ (20-30 min total)
      
50ms  → 05-dev-preview        START (parallel with 04)
      ├─ validate
      ├─ build               → Docker image
      ├─ deploy              → Deploy to dev ECS
      ├─ e2e-tests
      └─ PR comment          → Post results
      ✨ (15-20 min)
      
      ← 04-unified-deploy    ✅ COMPLETE (dev deployed)
      ← 05-dev-preview       ✅ COMPLETE (dev preview deployed)

RESULT: Feature deployed to dev environment, ready for testing
```

---

### Scenario 2: Pull Request to Develop
**Trigger:** Developer creates PR from `feature/new-api-endpoint` → `develop`

```
Time  Workflow                Status
─────────────────────────────────────────────────────
1ms   → 01-validation         START
5ms   → 02-mobile-build       START (parallel)
10ms  → 06-pr-test-suite      START (parallel)
      ├─ Lint
      ├─ Unit tests
      ├─ Integration tests
      ├─ Coverage report
      └─ Security scan
      
15ms  ← 01-validation         ✅ (5 min)
20ms  ← 02-mobile-build       ✅ (5 min)
25ms  ← 06-pr-test-suite      ✅ (8 min)
      
30ms  → 05-dev-preview        START (optional, if config enabled)
      
50ms  ← 05-dev-preview        ✅ (dev env ready for testing)

RESULT: PR is fully tested, dev environment is ready, PR is mergeable
```

---

### Scenario 3: Release Branch Creation
**Trigger:** Release manager creates PR from `release/v1.2.0` → `main`

```
Time  Workflow                Status
─────────────────────────────────────────────────────
1ms   → 02-mobile-build       START
5ms   → 03-android-build      START (parallel)
10ms  → 07-release-test       START (parallel)
      ├─ Full test suite
      ├─ E2E tests
      ├─ Performance tests
      ├─ Security scan
      └─ Coverage report (must pass)
      
15ms  ← 02-mobile-build       ✅
20ms  ← 03-android-build      ✅
25ms  ← 07-release-test       ✅ (10 min)

IF PR is merged to main:
30ms  → 08-main-test-suite    START (on main merge)
      ├─ Full validation
      ├─ Integration tests
      └─ Pre-deployment checks
      
40ms  ← 08-main-test-suite    ✅ (8 min)
      
45ms  → 04-unified-deploy     START (release/* detected)
      └─ Deploys to STAGING (if branch is release/*)
      
50ms  → 10-terraform          START (staging env)
60ms  → 11-rds-migrations     START (after terraform)
70ms  ← 10-terraform          ✅ Create staging infra
75ms  ← 11-rds-migrations     ✅ Run migrations
80ms  ← 04-unified-deploy     ✅ Staging deployed

RESULT: Staging environment fully deployed and tested
```

---

### Scenario 4: Main Branch Merge / Production Release
**Trigger:** Release merged to `main` OR version tag `v1.2.0` pushed

```
Time  Workflow                Status
─────────────────────────────────────────────────────
1ms   → 02-mobile-build       START
5ms   → 03-android-build      START (parallel)
10ms  → 08-main-test-suite    START (parallel)
      ├─ Full validation suite
      ├─ Integration tests
      ├─ Performance benchmarks
      └─ Coverage report
      
20ms  → 09-backend-cicd       START (main detected)
      ├─ Build verification
      ├─ Docker build
      └─ Tag image
      
25ms  ← 02-mobile-build       ✅
30ms  ← 03-android-build      ✅
35ms  ← 08-main-test-suite    ✅ (10 min)
40ms  ← 09-backend-cicd       ✅ (8 min)

IF version tag (v*.*.*)
45ms  → 04-unified-deploy     START (prod detected)
      ├─ Validate code
      ├─ Build Docker image (immutable tag)
      ├─ terraform-plan      (prod)
      ├─ terraform-apply     (prod: db.r6g.large, Redis cluster)
      ├─ deploy-ecs          (prod: 3-10 tasks)
      ├─ migrations          (prod schema)
      ├─ health-check        (comprehensive)
      ├─ e2e-tests           (full suite)
      └─ rollback if failure (auto-revert to previous)
      
50ms  → 14-deploy-prod        START (legacy, parallel)
      
60ms  ← 04-unified-deploy     ✅ (prod deployed)
      ← 14-deploy-prod        ✅ (if running)

RESULT: Production deployed, all tests passed, auto-rollback enabled
```

---

## 📊 Workflow Timeline by Git Event

### Push to Feature Branch (e.g., `feature/auth-tokens`)

```
Git Event: git push origin feature/auth-tokens
                            ↓
         GitHub detects: branches: [feature/*, bugfix/*, chore/*]
                            ↓
    ┌─────────────────────────────────────────────┐
    │ RUNS IN PARALLEL:                           │
    ├─────────────────────────────────────────────┤
    │ • 01 - Validation & Tests        (5 min)    │
    │ • 02 - Mobile Build              (5 min)    │
    │ • 04 - Unified Deploy → DEV      (20 min)   │
    │   ├─ Terraform (create infra)                │
    │   ├─ Docker build/push                      │
    │   ├─ ECS deploy                             │
    │   └─ E2E tests                              │
    │ • 05 - Dev Preview Deploy        (15 min)   │
    │   └─ Posts PR comment with results          │
    └─────────────────────────────────────────────┘
                            ↓
                    All pass → ✅ Feature ready for PR
                    Any fail → ❌ Fix and retry
```

### Pull Request to Develop

```
Git Event: Open PR from feature/auth-tokens → develop
                            ↓
         GitHub detects: pull_request: branches=[develop]
                            ↓
    ┌─────────────────────────────────────────────┐
    │ RUNS IN PARALLEL:                           │
    ├─────────────────────────────────────────────┤
    │ • 01 - Validation & Tests        (5 min)    │
    │ • 02 - Mobile Build              (5 min)    │
    │ • 06 - PR Test Suite             (8 min)    │
    │   ├─ Linting                                │
    │   ├─ Unit tests                             │
    │   ├─ Integration tests                      │
    │   ├─ Coverage report                        │
    │   └─ Security scanning                      │
    │ • 05 - Dev Preview (optional)    (15 min)   │
    │   └─ Deploy to dev for manual QA            │
    └─────────────────────────────────────────────┘
                            ↓
                    All pass → ✅ Ready to merge
                    Any fail → ❌ Request changes
```

### Pull Request to Release (release/v1.2.0)

```
Git Event: Open PR from release/v1.2.0 → main
                            ↓
         GitHub detects: pull_request: branches=[release/*]
                            ↓
    ┌─────────────────────────────────────────────┐
    │ RUNS IN PARALLEL:                           │
    ├─────────────────────────────────────────────┤
    │ • 02 - Mobile Build              (5 min)    │
    │ • 03 - Android Build             (10 min)   │
    │ • 07 - Release Test Suite        (12 min)   │
    │   ├─ Full test coverage                     │
    │   ├─ E2E tests                              │
    │   ├─ Performance tests                      │
    │   └─ Security audit                         │
    └─────────────────────────────────────────────┘
                            ↓
           After Merge to Main: (automatic)
                            ↓
    ┌─────────────────────────────────────────────┐
    │ THEN RUNS:                                  │
    ├─────────────────────────────────────────────┤
    │ • 08 - Main Test Suite           (10 min)   │
    │   └─ Final validation before prod           │
    │ • 09 - Backend CI/CD             (8 min)    │
    │   └─ Docker build and tag                   │
    │ • 04 - Unified Deploy → STAGING (20 min)    │
    │   ├─ Terraform staging infra                │
    │   ├─ Deploy app to staging                  │
    │   └─ Full test suite                        │
    └─────────────────────────────────────────────┘
```

### Push to Main (Production)

```
Git Event: git push origin main (after merge)
          OR git tag v1.2.0 && git push --tags
                            ↓
         GitHub detects: push: branches=[main]
                         OR tags: [v*.*.*]
                            ↓
    ┌─────────────────────────────────────────────┐
    │ PHASE 1 - VALIDATION (parallel)             │
    ├─────────────────────────────────────────────┤
    │ • 02 - Mobile Build              (5 min)    │
    │ • 03 - Android Build             (10 min)   │
    │ • 08 - Main Test Suite           (10 min)   │
    │ • 09 - Backend CI/CD             (8 min)    │
    └─────────────────────────────────────────────┘
                            ↓
    All tests pass → ✅ Proceed to production deployment
    Any test fails → ❌ Abort (manual intervention needed)
                            ↓
    ┌─────────────────────────────────────────────┐
    │ PHASE 2 - PRODUCTION DEPLOY                 │
    ├─────────────────────────────────────────────┤
    │ • 04 - Unified Deploy → PROD    (25 min)    │
    │   ├─ Terraform prod infra                   │
    │   │  (db.r6g.large, cache.r6g.xlarge)       │
    │   ├─ Docker build (immutable)               │
    │   ├─ Push to ECR prod                       │
    │   ├─ ECS deploy (3-10 tasks)                │
    │   ├─ Running DB migrations                  │
    │   ├─ Health checks (comprehensive)          │
    │   ├─ E2E test suite (full)                  │
    │   └─ Auto-rollback if failure               │
    │ • 14 - Deploy to Prod (legacy)  (if enabled)│
    │                                             │
    │ OR (Alternative) - Manual workflow_dispatch │
    │ • 13 - Manual Staging Deploy                │
    │ • 14 - Manual Prod Deploy                   │
    └─────────────────────────────────────────────┘
                            ↓
         Success → ✅ Production live!
         Failure → ❌ Auto-rollback to previous version
```

---

## 🎯 Key Execution Patterns

### Pattern 1: Feature Development Flow
```
Feature branch push → Validate → Build → Deploy to Dev → Test
                              ↓
                         Ready for PR
                              ↓
                     PR to develop → Full PR tests
                              ↓
                           Ready to merge
```

### Pattern 2: Release Flow
```
Release branch PR → Release tests → Merge to main
                                    ↓
                            Main tests + Backend CI
                                    ↓
                            Deploy to Staging
                                    ↓
                            Staging tests
                                    ↓
                            Ready for production
```

### Pattern 3: Production Deployment
```
Version tag push (v1.2.0) → All tests → Terraform
                                             ↓
                                        Docker build
                                             ↓
                                        ECS deploy
                                             ↓
                                        Health check
                                             ↓
                            Production live! ✨
                                    (or auto-rollback)
```

---

## ⏱️ Typical Execution Times

| Stage | Duration | Bottleneck |
|-------|----------|-----------|
| Validation (01) | 5 min | Unit tests |
| Mobile Build (02) | 5 min | Android build |
| Unified Deploy (04) | 20-25 min | Terraform + Docker |
| Dev Preview (05) | 15 min | ECS deployment |
| PR Test Suite (06) | 8 min | Test execution |
| Release Test (07) | 12 min | Full suite + perf |
| Main Test (08) | 10 min | Comprehensive tests |
| Backend CI (09) | 8 min | Docker build |
| Android Build (03) | 10 min | Gradle build |
| **Total Feature → Prod** | **60-80 min** | Terraform + tests |

---

## 🚨 Failure Handling

### If Test Fails (01, 02, 06, 07, 08, 09)
```
Test Fails → Workflow STOPS
           → GitHub marks workflow as ❌ FAILED
           → PR shows red in GitHub UI
           → Requires manual fix + re-run
```

### If Deployment Fails (04, 05, 10, 11, 12, 14)
```
Deployment Fails → Automatic ROLLBACK triggered
                 → Previous working version restored
                 → Team notified in PR comment
                 → Post-mortem investigation
```

### If Terraform Fails (04, 10)
```
Terraform validation fails → Error shown in workflow
                           → No infrastructure changes applied
                           → Manual Terraform debugging needed
```

---

## 🔧 Manual Workflow Triggers

These workflows can be manually triggered via GitHub UI:

### Utility Workflows
- **00** - Test OIDC: Verify AWS authentication works
- **04** - iOS Build: Build iOS app (normally disabled)
- **12** - ECS Deploy: Manual ECS redeployment
- **13** - Staging Deploy: Manual staging deployment
- **14** - Prod Deploy: Manual production deployment
- **15** - Feature Flags: Manage feature flags UI

### Example: Manual Dev Deploy
```
Go to: Actions → Select "04 - Unified Deployment"
      → Click "Run workflow"
      → Choose environment: dev
      → Click "Run"
      → Workflow executes with manual override
```

---

## 📌 Important Notes

### New Workflow (04 - Unified Deployment)
- **Replaces:** Workflows 10, 11, 12, 13, 14 functionality
- **Trigger:** Automatic on feature/*, release/*, main branches
- **Advantage:** Single workflow, environment-specific config
- **Jobs:** 11 sequential with proper dependencies

### Old Workflows (10-14)
- Still available for manual use
- Can run in parallel if needed
- Eventually should be deprecated
- Keep for backward compatibility

### Workflow 04 vs 05
- **04:** NEW - Unified, uses Terraform, for all environments
- **05:** OLD - Dev-only, faster for feature branches
- Both can run simultaneously
- 05 is backup/alternative approach

---

## 🎯 Recommended Workflow Setup

### For Feature Development
```
Feature branch → 01 (validate) + 02 (mobile) + 04 (unified deploy)
              → 05 (dev preview)
              → Ready for PR
```

### For Release
```
Release PR → 02 (mobile) + 03 (android) + 07 (release test)
         → Merge to main
         → 08 (main test) + 09 (backend CI)
         → 04 (unified deploy to staging)
         → Ready for production
```

### For Production
```
Version tag → 08 (main test) + 09 (backend CI)
          → 04 (unified deploy to prod)
          → Auto-rollback if failure
          → Production live!
```

---

## ✅ Status Dashboard

Open `/Actions` in GitHub to see:
- ✅ Green: Passing workflows
- ❌ Red: Failed workflows
- ⏳ Yellow: In-progress workflows
- ⊘ Gray: Skipped workflows

Click any workflow to see:
- Detailed logs
- Execution time
- Jobs status
- Failed step
- Error messages
