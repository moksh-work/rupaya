# GitHub Actions Workflow Execution Flow - Corrected by Trigger Order

**Updated:** February 18, 2026  
**Change:** Workflows renumbered to match actual execution order (01-12)

---

## What Triggers on Feature Branch Push

```
git push origin feature/add-feature
        │
        ▼
START: 01 - Code Validation & Linting ✅
       └─ ESLint Check
       └─ Prettier Check
       └─ Code Quality Scan
       
START: 02 - Backend Tests & Lint ✅ (if backend/** or shared/** changed)
       └─ Install dependencies  
       └─ Run unit tests
       └─ Generate coverage report

RESULT: Both workflows run in PARALLEL
        │
        └─→ Results visible in GitHub UI
        └─→ NO DEPLOYMENT (safe to test)
        └─→ Takes ~5-10 minutes
```

---

## What Triggers on Pull Request to Main

```
Create PR: feature/add-feature → main
        │
        ▼
RUN: 01 - Code Validation & Linting ✅
RUN: 02 - Backend Tests & Lint ✅ (if changed)
RUN: 03 - Full Test Suite ✅
     └─ Backend tests (Node.js)
     └─ iOS tests
     └─ Android tests
     └─ Coverage reports

RUN: 04 - Mobile Build Check ✅ (if iOS/Android/** changed)
     └─ iOS build
     └─ Android build

RESULT: Status checks visible on PR
        └─→ Merge blocking until all pass (if policy enabled)
        └─→ NO DEPLOYMENT
        └─→ Takes ~15-25 minutes total
```

---

## What Triggers on Push to Main (Complete Deployment Pipeline)

```
git push origin main  (or merge PR)
        │
        ▼ ALL STAGES RUN IN SEQUENCE (parallel within stages)

╔════════════════════════════════════════════════════════════╗
║ STAGE 1: CODE QUALITY (Parallel) - 3-5 minutes            ║
╟────────────────────────────────────────────────────────────╢
║ ✅ 01 - Code Validation & Linting                         ║
║ ✅ 02 - Backend Tests & Lint (if backend/** changed)      ║
╚════════════════════════════════════════════════════════════╝
        │
        ▼

╔════════════════════════════════════════════════════════════╗
║ STAGE 2: COMPREHENSIVE TESTING (Parallel) - 10-25 min     ║
╟────────────────────────────────────────────────────────────╢
║ ✅ 03 - Full Test Suite                                   ║
║    ├─ Backend tests                                       ║
║    ├─ Frontend tests                                      ║
║    └─ Coverage reports                                    ║
║                                                            ║
║ ✅ 04 - Mobile Build Check (parallel)                     ║
║    ├─ iOS build                                           ║
║    └─ Android build                                       ║
╚════════════════════════════════════════════════════════════╝
        │
        ▼

╔════════════════════════════════════════════════════════════╗
║ STAGE 3: BUILD & PUSH (Sequential) - 15-20 minutes        ║
╟────────────────────────────────────────────────────────────╢
║ ✅ 05 - Backend CI/CD Pipeline                            ║
║    1. Run all tests (skip, already passed)                ║
║    2. Build Docker image                                  ║
║    3. Push to ECR (Elastic Container Registry)            ║
║    └─ Output: Image URI in ECR                            ║
╚════════════════════════════════════════════════════════════╝
        │
        ▼

╔════════════════════════════════════════════════════════════╗
║ STAGE 4: INFRASTRUCTURE (Parallel) - 5-10 minutes         ║
╟────────────────────────────────────────────────────────────╢
║ ✅ 06 - Terraform Infrastructure Deploy (if infra/**)     ║
║    └─ Creates/updates: VPC, RDS, Redis, ALB, ECS clusters║
║                                                            ║
║ ✅ 07 - RDS Migrations (if migrations/** changed)         ║
║    └─ Runs database schema migrations                     ║
╚════════════════════════════════════════════════════════════╝
        │
        ▼

╔════════════════════════════════════════════════════════════╗
║ STAGE 5: DEPLOYMENT (Parallel) - 8-15 minutes             ║
╟────────────────────────────────────────────────────────────╢
║ ✅ 08 - ECS Deploy (Universal)                            ║
║    1. Register new task definition                        ║
║    2. Deploy to ECS service                               ║
║    3. Wait for service stabilization                      ║
║    4. Health checks                                       ║
║    └─ Updates both staging & production (auto-detect)     ║
║                                                            ║
║ ✅ 09 - Manual Deploy to Staging (manual trigger only)    ║
║    └─ Available for manual staging deployments            ║
║                                                            ║
║ ✅ 10 - Deploy to Production                              ║
║    └─ Triggers on version tags: v*.*.* or manual          ║
╚════════════════════════════════════════════════════════════╝
        │
        ▼

╔════════════════════════════════════════════════════════════╗
║ STAGE 6: MOBILE BUILDS (Manual/Separate) - 20-30 min      ║
╟────────────────────────────────────────────────────────────╢
║ ✅ 11 - Build Android (manual or app changes)             ║
║    └─ Builds debug APK                                    ║
║                                                            ║
║ ✅ 12 - Build iOS (manual or app changes)                 ║
║    └─ Builds iOS app for simulator/device                 ║
╚════════════════════════════════════════════════════════════╝

TOTAL TIME: ~60-90 minutes for full pipeline on main push
DEPLOYMENT TARGET: Production (automatic)
```

---

## Quick Reference Matrix

| Scenario | Workflows Run | Deployment | Time | 
|----------|---------------|------------|------|
| Feature branch push | 01, 02 | ❌ No | 5-10 min |
| PR to main | 01, 02, 03, 04 | ❌ No | 15-25 min |
| Push to main | All (01-12 applicable) | ✅ Yes to Prod | 60-90 min |
| Manual staging deploy (09) | 09 only | ✅ Yes to Staging | 8-12 min |
| Manual production deploy (10) | 10 only | ✅ Yes to Prod | 10-15 min |
| Version tag (v*.*.* on any branch) | 10 | ✅ Yes to Prod | 10-15 min |

---

## Key Takeaways

✅ **Early Feedback on Feature Branches:** Workflows 01-02 run within 5-10 minutes  
✅ **Comprehensive Testing Before Merge:** Workflows 03-04 run on all PRs  
✅ **Automatic Production Deployment:** Full pipeline triggers on main push  
✅ **Build After Verification:** Docker image only builds after 01-04 pass  
✅ **Infrastructure First:** Terraform (06) runs before deployments (08-10)  
✅ **Safe Rollout:** Health checks ensure services are stable before marking complete  
✅ **Manual Overrides Available:** Workflows 09-10, 11-12 can be triggered manually anytime  

---

## Workflow Numbers Now Match Execution Order ✅

| Old | New | Workflow | First Trigger |
|-----|-----|----------|---------------|
| 03 | 01 | Code Validation | Feature branch |
| 04 | 02 | Backend Tests | Feature branch |
| 05 | 03 | Full Test Suite | Main push |
| 12 | 04 | Mobile Build Check | Main push |
| 09 | 05 | Backend CI/CD | Main push |
| 01 | 06 | Terraform Infrastructure | Main push |
| 02 | 07 | RDS Migrations | Main push |
| 06 | 08 | ECS Deploy | Main push |
| 07 | 09 | Manual Staging | Manual trigger |
| 08 | 10 | Production Deploy | Main push/tags |
| 10 | 11 | Android Build | Manual |
| 11 | 12 | iOS Build | Manual |

**Result:** Workflow numbers (01-12) now logically represent execution stages!
