# Git Flow Workflow Guide - Rupaya Project

**Enterprise-Grade GitHub Workflow for Rupaya**  
**Last Updated**: February 5, 2026

---

## 🎯 Overview

Your repository is now configured with **Git Flow** - a proven branching strategy for enterprise projects. This guide shows your team how to work with the configured branch protection rules.

---

## 📋 Branch Strategy (Git Flow)

### Production Branches

#### 1. **main** - Production Release
- **Purpose**: Live production code
- **Protection Rules**:
  - ✅ Requires 2 code review approvals
  - ✅ Code owners must review
  - ✅ All status checks must pass (5 required)
  - ✅ Requires signed commits
  - ✅ No force pushes allowed
  
**Merge from**: `release/*` or `hotfix/*` branches only

```bash
# View main branch
git log origin/main --oneline | head -10

# Create release PR
git checkout -b release/1.0.0
# ... make final changes ...
git push origin release/1.0.0
# Create PR → Merge to main (with 2 approvals)
```

---

#### 2. **develop** - Integration/Staging Branch
- **Purpose**: Integration branch for staging deployments
- **Protection Rules**:
  - ✅ Requires 1 code review approval
  - ✅ Code owners must review
  - ✅ All status checks must pass (5 required)
  - ✅ Auto-delete branches after merge
  - ✅ Squash merging enforced
  
**Merge from**: `feature/*` and `bugfix/*` branches

```bash
# View develop branch
git log origin/develop --oneline | head -10

# Create feature branch from develop
git checkout develop
git pull origin develop
git checkout -b feature/new-feature
```

---

### Temporary Branches (Auto-Protected)

#### 3. **feature/*** - Feature Development
- **Naming**: `feature/auth-mfa`, `feature/wallet-sync`, etc.
- **Created from**: `develop`
- **Protection Rules**:
  - ✅ Status checks must pass
  - ✅ CODEOWNERS review required
  - ✅ Squash merge only
  
**Workflow**:
```bash
# 1. Create from develop
git checkout develop
git pull origin develop
git checkout -b feature/my-feature

# 2. Make changes
git add .
git commit -m "feat: add new feature description"
git push origin feature/my-feature

# 3. Create Pull Request to develop
# (Automatic status checks will run)

# 4. Get 1 approval + code owner review
# (Code owners auto-notified by CODEOWNERS file)

# 5. Merge to develop (squash)
# Branch auto-deleted after merge
```

#### 4. **bugfix/*** - Bug Fixes (Optional)
- **Naming**: `bugfix/login-error`, `bugfix/transaction-sync`, etc.
- **Created from**: `develop`
- **Same rules as feature branches**

```bash
git checkout develop
git checkout -b bugfix/fix-description
# ... make fixes ...
git push origin bugfix/fix-description
# Create PR to develop
```

#### 5. **release/*** - Release Preparation
- **Naming**: `release/1.0.0`, `release/2.1.0`, etc.
- **Created from**: `develop`
- **Purpose**: Final testing, version bumps, changelog updates
- **Rules**: 1 approval, status checks pass

**Workflow**:
```bash
# 1. Create release branch
git checkout develop
git pull origin develop
git checkout -b release/1.0.0

# 2. Update version numbers, changelog
# (No new features, only fixes and documentation)
vim package.json  # Update version
vim CHANGELOG.md   # Document changes
git add . && git commit -m "chore: version bump to 1.0.0"
git push origin release/1.0.0

# 3. Create PR to main
# (Requires 2 approvals)

# 4. Merge to main (PR automatically creates production release)

# 5. Create PR back to develop (for sync)
```

#### 6. **hotfix/*** - Production Emergency Fixes
- **Naming**: `hotfix/critical-security`, `hotfix/payment-bug`, etc.
- **Created from**: `main` ONLY
- **Priority**: Higher priority than normal PRs
- **Rules**: 1 approval, fast-track merge

**Workflow**:
```bash
# 1. Create from main (ONLY)
git checkout main
git pull origin main
git checkout -b hotfix/critical-issue

# 2. Fix the issue
git commit -m "fix: critical issue description"
git push origin hotfix/critical-issue

# 3. Create PR to main
# (Emergency fixes - fast track approval)

# 4. Once merged to main, create PR back to develop
git checkout develop
git pull origin develop
git merge --no-ff origin/hotfix/critical-issue
git push origin develop
```

---

## 🔄 Complete Workflow Examples

### Adding a New Feature

```bash
# Step 1: Start from develop
git checkout develop
git pull origin develop

# Step 2: Create feature branch
git checkout -b feature/add-budget-analytics

# Step 3: Make changes
vim src/features/analytics/budget.ts
git add src/features/analytics/
git commit -m "feat: add budget analytics dashboard"

# Step 4: Push to GitHub
git push -u origin feature/add-budget-analytics

# Step 5: Create PR on GitHub (web UI or CLI)
# - Description: What does this feature do?
# - Link to issue: #123
# - Screenshots/demo if applicable

# Step 6: Wait for:
#   ✓ Status checks to pass (lint, tests, build, security)
#   ✓ Code owner review (@moksh-work)
#   ✓ 1 approval minimum
#   ✓ Conversation resolution

# Step 7: CODEOWNERS auto-review based on files changed
# - backend/ changes → backend team notified
# - ios/ changes → iOS team notified
# - infra/ changes → DevOps team notified

# Step 8: Merge (automatically squashed)
# GitHub squashes commits: "feat: add budget analytics dashboard (#456)"

# Result: Branch auto-deleted, feature merged to develop
```

### Releasing a Version

```bash
# Step 1: Create release branch
git checkout develop
git pull origin develop
git checkout -b release/1.5.0

# Step 2: Version bump
npm version minor  # Updates package.json
git add package.json package-lock.json

# Step 3: Update changelog
echo "## [1.5.0] - 2026-02-05" >> CHANGELOG.md
echo "### Added" >> CHANGELOG.md
echo "- Budget analytics" >> CHANGELOG.md
git add CHANGELOG.md
git commit -m "chore: prepare release 1.5.0"

# Step 4: Push and create PR to main
git push -u origin release/1.5.0
# Create PR: release/1.5.0 → main

# Step 5: Get 2 approvals (main branch requirement)
# Typically:
#   - Approval 1: Tech Lead
#   - Approval 2: DevOps/Release Manager

# Step 6: Merge to main
# This triggers:
#   - GitHub creates release tag
#   - CI/CD deploys to production
#   - Notifications sent

# Step 7: Sync back to develop
git checkout develop
git pull origin develop
git merge origin/release/1.5.0
git push origin develop
```

### Emergency Production Fix

```bash
# Step 1: CRITICAL: Create hotfix from main ONLY
git checkout main
git pull origin main
git checkout -b hotfix/payment-processing-error

# Step 2: Fix the critical issue
vim backend/src/services/PaymentService.ts
git add backend/src/services/
git commit -m "fix: resolve payment processing error (#789)"

# Step 3: Push immediately
git push -u origin hotfix/payment-processing-error

# Step 4: Create emergency PR to main
# Mark as 🔴 CRITICAL in title

# Step 5: Fast-track review
# - DevOps/On-call engineer: 1 approval
# - Status checks: all pass

# Step 6: Merge to main
# This triggers immediate production deployment

# Step 7: Backport to develop
# Ensure develop also has the fix
git checkout develop
git pull origin develop
git merge --no-ff origin/hotfix/payment-processing-error
git push origin develop
```

---

## ✅ Pre-Merge Checklist

Before creating a PR, ensure:

- [ ] **Code Quality**
  - [ ] All tests passing locally: `npm test`
  - [ ] Linting passes: `npm run lint`
  - [ ] No console warnings/errors
  
- [ ] **Security**
  - [ ] No secrets/credentials committed
  - [ ] No security anti-patterns
  - [ ] Dependencies up to date
  
- [ ] **Documentation**
  - [ ] Code comments for complex logic
  - [ ] README updated if needed
  - [ ] API docs updated (backend changes)
  
- [ ] **Git Cleanliness**
  - [ ] Branch up to date with develop: `git pull origin develop`
  - [ ] Commits are logical and squashed
  - [ ] Commit messages follow convention (feat:, fix:, chore:)
  
- [ ] **Deployment Readiness**
  - [ ] Configuration/env vars documented
  - [ ] Database migrations (if applicable)
  - [ ] Backwards compatible changes

---

## 🚫 Branch Protection Rules in Action

### What IS Protected

✅ Pushing directly to `main` → BLOCKED  
✅ Pushing directly to `develop` → BLOCKED  
✅ Force pushing to any branch → BLOCKED  
✅ Merging without approvals → BLOCKED  
✅ Merging with failing tests → BLOCKED  
✅ Merging without code owner review → BLOCKED  

### What You CAN Do

✓ Push to `feature/*` branches directly  
✓ Push to `release/*` branches directly  
✓ Push to `hotfix/*` branches directly  
✓ Create pull requests (trigger status checks)  
✓ Request reviews from code owners  
✓ Approve other PRs (if authorized)  

---

## 📊 Status Checks (CI/CD Pipelines)

Every PR must pass these checks:

| Check | Purpose | On Failure |
|-------|---------|-----------|
| `lint-and-quality` | Code style & linting | Fix linting issues, run `npm run lint --fix` |
| `backend-tests` | Backend unit/integration tests | Run `npm test` locally, fix failing tests |
| `security-scan` | Security vulnerability scan | Review security findings, update dependencies |
| `build-check` | Build verification | Fix build errors, check dependencies |
| `branch-validation` | Naming convention check | Use correct branch prefix: `feature/`, `release/`, etc. |

**View status in PR**: Look for ✅ green checks or ❌ red X marks

---

## 👥 CODEOWNERS - Auto Review Assignment

Based on files changed, these teams are auto-assigned for review:

```
* @moksh-work                               # All changes
backend/ @moksh-work                        # Backend changes
backend/migrations/ @moksh-work             # Database migrations
ios/ @moksh-work                            # iOS app changes
android/ @moksh-work                        # Android app changes
infra/ @moksh-work                          # Infrastructure
.github/workflows/ @moksh-work              # CI/CD workflow changes
docs/ @moksh-work                           # Documentation
*.md @moksh-work                            # Any markdown files
```

---

## 🔐 Signing Your Commits

Main branch requires **signed commits**. Set this up:

```bash
# 1. Generate GPG key (if you don't have one)
gpg --full-generate-key

# 2. Configure Git to use your key
git config --global user.signingkey <KEY_ID>
git config --global commit.gpgsign true

# 3. Export public key to GitHub
gpg --armor --export <KEY_ID> | pbcopy
# Then add to GitHub: Settings → SSH & GPG Keys → New GPG Key

# 4. Now all commits are automatically signed
git commit -m "feat: signed commit"
# Shows "Verified" badge on GitHub

# If you need to skip signing temporarily:
git commit --no-verify -m "message"
```

---

## 📝 Commit Message Convention

Follow this format for clear history:

```
type(scope): description

body (optional)

footer (optional)
```

**Types**:
- `feat:` New feature
- `fix:` Bug fix
- `chore:` Build, dependencies, tooling
- `docs:` Documentation changes
- `style:` Formatting (no code changes)
- `refactor:` Code restructure (no behavior change)
- `perf:` Performance improvement
- `test:` Test changes

**Examples**:
```
feat(auth): add two-factor authentication
fix(payment): resolve transaction timeout issue
chore(deps): update dependencies
docs(readme): clarify deployment steps
refactor(api): simplify error handling
```

---

## 🆘 Common Issues & Solutions

### Issue: "Can't push to main/develop"
**Solution**: You can't push directly. Create a PR instead:
```bash
git checkout -b feature/my-feature
# ... make changes ...
git push origin feature/my-feature
# Create PR on GitHub web UI
```

### Issue: "PR blocked - missing approval"
**Solution**: Wait for code owner approval
- Check who was auto-assigned in CODEOWNERS
- @ mention them in PR: `@moksh-work please review`
- Use GitHub UI to request review

### Issue: "PR blocked - status checks failing"
**Solution**: 
```bash
# Run locally to debug
npm run lint --fix   # Fix linting
npm test             # Run tests
npm run build        # Check build
git add .
git commit -m "fix: address linting/test issues"
git push origin feature/my-feature
```

### Issue: "Need to update with latest develop"
**Solution**: Rebase on develop
```bash
git checkout feature/my-feature
git fetch origin
git rebase origin/develop
# Resolve any conflicts if needed
git push --force-with-lease origin feature/my-feature
```

### Issue: "Accidentally pushed to main"
**Solution**: Contact DevOps immediately
- Don't force push (it's blocked anyway)
- Create a revert commit
- Requires 2 approvals to merge the revert

---

## 🎓 Team Onboarding

For new team members:

1. **Clone repository**:
   ```bash
   git clone https://github.com/moksh-work/rupaya.git
   cd rupaya
   git checkout develop
   git pull
   ```

2. **Configure Git**:
   ```bash
   git config user.name "Your Name"
   git config user.email "your.email@company.com"
   
   # Optional: Enable signed commits
   git config --global commit.gpgsign true
   ```

3. **Read this guide**: Understand feature/release/hotfix workflow

4. **Try creating a branch**:
   ```bash
   git checkout -b feature/test-branch
   # Make small change
   git push -u origin feature/test-branch
   # Create PR, wait for checks, merge
   ```

---

## 📞 Support & Questions

**For questions about**:
- **Workflows**: Check this guide or ask DevOps team
- **Branch protection**: See "Branch Protection Rules" section
- **CI/CD failures**: Check status check details in PR
- **Merging issues**: Contact DevOps/Release Manager
- **Emergency fixes**: Use hotfix/* with critical label

---

## 🔍 Quick Reference

```bash
# Setup
git checkout develop && git pull
git checkout -b feature/description

# Work
git add file.ts
git commit -m "feat: add description"
git push -u origin feature/description

# Create PR on GitHub web UI
# Wait for 1 approval + checks to pass
# GitHub merges automatically (squash)

# Verify merge
git checkout develop
git pull
git log --oneline | head -5
```

---

**Document Version**: 1.0.0  
**Last Updated**: February 5, 2026  
**Audience**: Development Team  
**Maintained by**: DevOps Team

---

*For more information on Git Flow, see: https://nvie.com/posts/a-successful-git-branching-model/*
