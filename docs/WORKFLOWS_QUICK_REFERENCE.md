# GitHub Workflows - Quick Reference Guide

## 🎯 TL;DR - Quick Start

### For Feature Development
```bash
git checkout -b feature/new-api
# Make changes...
git push origin feature/new-api
# Automatically runs: 01 + 02 + 04 (→ dev) + 05
# Result: ✅ Code validated, Docker built, deployed to dev
```

### For Pull Request
```bash
# Open PR from feature/new-api → develop
# Automatically runs: 01 + 02 + 06 + 05 (optional)
# Result: ✅ All tests pass, dev ready for QA
```

### For Release
```bash
git checkout -b release/v1.2.0
git push origin release/v1.2.0
# Open PR to main
# Automatically runs: 02 + 03 + 07
# After merge: 08 + 09 + 04 (→ staging)
# Result: ✅ Staging deployed and tested
```

### For Production
```bash
git tag v1.2.0
git push --tags
# Automatically runs: 08 + 09 + 04 (→ prod)
# Result: ✅ Production deployed (or auto-rollback if fails)
```

---

## 📋 Workflow Reference Table

| # | Name | Trigger | Time | What It Does |
|---|------|---------|------|-------------|
| **00** | Test OIDC | Manual | 2 min | Verify AWS authentication |
| **01** | Validation | feature/*, PR to dev | 5 min | Lint + unit tests |
| **02** | Mobile Build | Any branch | 5 min | Android/iOS gradle check |
| **03** | Android Build | main, PR, Manual | 10 min | Full Android release build |
| **04** | iOS Build | Manual | 15 min | Full iOS release build |
| **04** | **Unified Deploy** | **feature/*, release/*, main, tags** | **20-30 min** | **NEW: Terraform + Docker + ECS + Tests** |
| **05** | Dev Preview | feature/*, PR to dev | 15 min | Deploy to dev for testing |
| **06** | PR Tests | PR to develop | 8 min | Full PR validation suite |
| **07** | Release Tests | release/*, Manual | 12 min | Pre-production validation |
| **08** | Main Tests | main push | 10 min | Post-merge validation |
| **09** | Backend CI | main push/PR | 8 min | Docker build + tag |
| **10** | Terraform | feature/*, release/*, PR | 5-8 min | Terraform plan/apply |
| **11** | RDS Migrations | main, develop, Manual | 2 min | Database migrations |
| **12** | ECS Deploy | Manual | 3 min | Manual ECS redeployment |
| **13** | Staging Deploy | Manual | 15 min | Manual staging deployment |
| **14** | Prod Deploy | main, tags, Manual | 20 min | Manual production deployment |
| **15** | Feature Flags | Manual | 5 min | Manage feature flags UI |

---

## 🚀 Workflow Triggers

### Feature Branch Push (feature/*, bugfix/*, chore/*)
```
Simultaneous:
├─ 01: Validation ..................... 5 min
├─ 02: Mobile Build ................... 5 min
├─ 04: Unified Deploy → DEV .......... 20 min
└─ 05: Dev Preview ................... 15 min

Result: ✅ Feature deployed to dev, ready for PR
```

### Pull Request to Develop
```
Simultaneous:
├─ 01: Validation ..................... 5 min
├─ 02: Mobile Build ................... 5 min
├─ 06: PR Test Suite .................. 8 min
└─ 05: Dev Preview (optional) ....... 15 min

Result: ✅ PR fully tested, dev ready for QA
```

### Release Branch (release/v*.*.* PR to main)
```
Simultaneous:
├─ 02: Mobile Build ................... 5 min
├─ 03: Android Build ................. 10 min
└─ 07: Release Test Suite ............ 12 min

After Merge to Main:
├─ 08: Main Test Suite ............... 10 min
├─ 09: Backend CI/CD .................. 8 min
└─ 04: Unified Deploy → STAGING ..... 20 min

Result: ✅ Staging deployed and tested
```

### Main Branch Push (merge or direct)
```
Simultaneous:
├─ 02: Mobile Build ................... 5 min
├─ 03: Android Build ................. 10 min
├─ 08: Main Test Suite ............... 10 min
└─ 09: Backend CI/CD .................. 8 min

Result: ✅ Ready for production deployment
```

### Version Tag Push (git tag v1.2.0 && git push --tags)
```
Simultaneous:
├─ 08: Main Test Suite ............... 10 min
└─ 09: Backend CI/CD .................. 8 min

Then:
└─ 04: Unified Deploy → PROD ........ 25 min
   ├─ Terraform prod infrastructure
   ├─ Docker build + ECR push
   ├─ ECS deploy (3-10 tasks)
   ├─ Database migrations
   ├─ Health checks
   ├─ E2E tests
   └─ Auto-rollback if failure

Result: ✅ Production deployed live! (or rolled back)
```

---

## 🔧 Manual Workflows

These can be manually triggered from GitHub Actions:

### Utility
- **00 - Test OIDC**: Debug AWS authentication
- **04 - iOS Build**: Build iOS app
- **12 - ECS Deploy**: Redeploy to ECS
- **15 - Feature Flags**: Manage feature flags UI

### Deployments
- **13 - Staging Deploy**: Manual staging deployment
- **14 - Prod Deploy**: Manual production deployment

**How to run:**
1. Go to GitHub → Actions
2. Select workflow
3. Click "Run workflow"
4. Choose branch/environment
5. Run

---

## 📊 Estimated Duration

| Event | Duration | Bottleneck |
|-------|----------|-----------|
| Feature push → deployed to dev | 20 min | Terraform |
| Feature branch → PR → dev | 8 min | Tests |
| Release → Staging | 25 min | Terraform + tests |
| Main merge → Production | 25 min | Terraform + tests |
| **Total feature → production** | **60-80 min** | Tests + infrastructure |

---

## ✅ Success Criteria

### Feature Branch
- ✅ 01: Validation passes
- ✅ 02: Mobile build succeeds
- ✅ 04: Deployed to dev
- ✅ 05: Dev preview ready
→ **Feature is deployable**

### Pull Request
- ✅ 06: All PR tests pass
- ✅ 05: Dev environment ready
→ **Ready to merge**

### Release
- ✅ 07: Release tests pass
- ✅ 04: Staging deployed
- ✅ All E2E tests pass
→ **Ready for production**

### Production
- ✅ 08: Main tests pass
- ✅ 09: Backend CI passes
- ✅ 04: Deployed to prod
- ✅ Health checks pass
- ✅ E2E tests pass
→ **Production live!**

---

## ❌ Failure Handling

### If Test Fails
```
Workflow ❌ FAILED
  ↓
GitHub shows: red X on PR/commit
  ↓
Developer: Fix code + retry
  ↓
Rerun workflow: git add . && git push
```

### If Deployment Fails
```
Job ❌ FAILED during deploy
  ↓
Auto-rollback triggered 🔄
  ↓
Previous version restored
  ↓
Team notified in PR comment
  ↓
Manual investigation required
```

### If Terraform Fails
```
Terraform validation ❌ FAILED
  ↓
Error message shown in workflow logs
  ↓
No infrastructure changes applied
  ↓
Developer: Fix Terraform code
  ↓
Manual re-run in GitHub
```

---

## 🎨 Workflow Status Colors in GitHub

| Color | Status | Meaning |
|-------|--------|---------|
| 🟢 Green | Success | All jobs passed |
| 🔴 Red | Failed | Some job failed |
| 🟡 Yellow | In Progress | Currently running |
| ⚫ Dark | Cancelled | Manually stopped |
| ⚪ Gray | Skipped | Conditions not met |

---

## 📍 Where It Runs

### GitHub Actions Infrastructure
- **Region**: us-east-1
- **Runner Type**: ubuntu-latest (GitHub-hosted)
- **Concurrency**: 5 jobs in parallel
- **Timeout**: 6 hours per workflow

### AWS Resources Created
- **Terraform**: Creates VPC, RDS, ElastiCache, ECS, ALB
- **Docker**: Built on GitHub Actions runner
- **ECR**: Image pushed from GitHub Actions
- **Secrets**: Stored in GitHub + AWS Secrets Manager

---

## 🔐 Authentication Flow

```
1. Developer pushes code
2. GitHub detects branch
3. GitHub Actions starts workflow
4. OIDC authenticates to AWS (no credentials needed!)
5. Workflow uses IAM role (dev/staging/prod specific)
6. Resources created in AWS
7. Results posted back to GitHub
```

**No AWS credentials exposed!** Uses OpenID Connect (OIDC) federation.

---

## 🛠️ Troubleshooting

### Workflow Won't Start
- Check branch name matches trigger (feature/*, release/*, etc.)
- Check file path changes (backend/*, infra/*, etc.)
- Check if workflow is disabled in `.github/workflows/*.yml`

### Workflow Runs But No Output
- Check GitHub Actions logs
- Look for error in specific job
- Expand failed step to see full error

### Deployment Succeeded But App Not Working
- Check ECS service health
- Review CloudWatch logs
- Check if migrations ran successfully
- Verify security groups allow traffic

### How to View Logs
1. GitHub → Actions
2. Click workflow run
3. Click job name
4. Expand step to see output

---

## 💡 Tips & Tricks

### Skip A Workflow
Add to commit message: `[skip ci]`
```bash
git push origin feature/x -m "feat: add feature [skip ci]"
# 01, 02, 04, 05 won't run
```

### Force Rerun
GitHub UI → Click "Re-run failed jobs"
Or: Push empty commit
```bash
git commit --allow-empty -m "trigger workflows"
git push origin branch
```

### View Artifacts
GitHub → Actions → Workflow → Job → Artifacts
- Terraform plans
- Coverage reports
- Test results

### Download Logs
GitHub → Actions → Workflow → Download logs

---

## 🎯 Best Practices

### Do's ✅
- Write descriptive commit messages
- Push to feature branch first
- Ensure all tests pass before merging
- Use meaningful branch names (feature/*, release/*, etc.)
- Review Terraform plan before applying
- Monitor production deployments

### Don'ts ❌
- Don't push directly to main
- Don't tweak production manually (use workflow)
- Don't ignore failed tests
- Don't merge without passing PR tests
- Don't skip release notes

---

## 📚 Related Documentation

- [WORKFLOWS_EXECUTION_SEQUENCE.md](./WORKFLOWS_EXECUTION_SEQUENCE.md) - Detailed workflow sequences
- [UNIFIED_DEPLOYMENT_ARCHITECTURE.md](./UNIFIED_DEPLOYMENT_ARCHITECTURE.md) - 3-layer deployment architecture
- [.github/workflows/](../../../.github/workflows/) - All workflow files

---

## 🚀 Next Steps

1. **Push code to feature branch**
   ```bash
   git push origin feature/your-feature
   ```

2. **Monitor workflow in GitHub Actions**
   - Go to Actions tab
   - Watch real-time execution
   - Check logs for errors

3. **Open PR to develop**
   - Create PR on GitHub
   - Wait for PR tests to pass
   - Deploy to dev for QA

4. **Merge to release branch**
   - Create release/v*.*.* branch
   - Open PR to main
   - Wait for release tests

5. **Tag and deploy to production**
   - Create version tag: `git tag v1.2.0`
   - Push tag: `git push --tags`
   - Workflow 04 auto-deploys to prod!

---

**Questions?** Check the detailed docs or review workflow logs in GitHub Actions!
