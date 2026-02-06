# GitHub Workflows - Practical Examples

**Reference**: Complete command-line and GitHub UI examples for all workflows  
**Level**: Team members (developers, QA, ops)

---

## 🚀 Quick Reference

### Most Common Tasks

```bash
# Start a new feature
git checkout develop && git pull
git checkout -b feature/my-feature
# ... make changes ...
git add .
git commit -m "feat: add my feature"
git push -u origin feature/my-feature
# Create PR on GitHub → 5 minute deploy to staging

# Fix a bug on develop
git checkout develop && git pull
git checkout -b bugfix/my-bug
# ... fix it ...
git push -u origin bugfix/my-bug
# Create PR on GitHub → auto-deploy to staging

# Release to production
git checkout develop && git pull
git checkout -b release/1.2.0
# Update version, CHANGELOG, etc.
git push -u origin release/1.2.0
# Create PR to main → 2 reviews → production

# Emergency hotfix
git checkout main && git pull
git checkout -b hotfix/critical-issue
# ... fix it ...
git push -u origin hotfix/critical-issue
# Create PR to main → 1 review → < 5 min to production
```

---

## 📖 Scenario 1: Developing a New Feature

### Goal: Add user authentication feature and deploy to staging

### Step-by-Step

#### 1. Create Feature Branch

```bash
# Update local develop branch
git checkout develop
git pull origin develop

# Create feature branch
git checkout -b feature/user-authentication
# Convention: feature/short-description-of-feature
```

#### 2. Develop Locally

```bash
# Make your changes
# ... edit files ...

# Run local tests
npm run test:unit
npm run test:integration

# Run linting
npm run lint

# Run all tests
npm run test:all
```

#### 3. Commit Changes

```bash
# Stage your changes
git add .

# Commit with clear message
git commit -m "feat: implement user authentication with JWT

- Add login endpoint
- Add signup endpoint
- Add JWT token validation
- Add unit tests for auth service"

# Make more commits as needed
git commit -m "test: add integration tests for auth endpoints"
git commit -m "fix: handle token expiration gracefully"
```

#### 4. Push to GitHub

```bash
# Push feature branch to GitHub
git push -u origin feature/user-authentication
# -u sets upstream, future pushes don't need -u
```

#### 5. Create Pull Request on GitHub

**On GitHub UI:**

1. Navigate to the repository
2. Click "Pull Requests" tab
3. Click "New Pull Request"
4. Base: `develop`, Compare: `feature/user-authentication`
5. Add title: "feat: implement user authentication"
6. Add description:
   ```markdown
   ## Description
   Implements user authentication with JWT tokens
   
   ## Changes
   - Login endpoint
   - Signup endpoint
   - JWT validation middleware
   
   ## Testing
   - Unit tests: 15 tests added
   - Integration tests: 8 tests added
   - Manual testing: Verified on local
   
   ## Deployment
   - Ready for staging: Yes
   - Breaking changes: No
   - Database migrations: No
   ```
7. Click "Create Pull Request"

#### 6. Automated Workflows Run

**GitHub Actions automatically execute:**

```
1. 04-common-validate.yml starts
   ├─ Linting: 2 min ✅
   ├─ Unit tests: 8 min ✅
   ├─ Integration tests: 4 min ✅
   ├─ Security scan: 1 min ✅
   ├─ Build check: 2 min ✅
   └─ Total: 17 minutes ✅
```

**Check status in GitHub:**
- Green checkmark = all tests pass ✅
- Red X = tests failed ❌

#### 7. Code Review

**GitHub UI - Request Reviewers:**
1. Click "Reviewers" on the right
2. Select 1 team member (develop branch only needs 1)
3. Wait for review

**Reviewer gets notification:**
- Slack notification (if configured)
- Email notification

#### 8. Address Feedback

**If reviewer requests changes:**

```bash
# Make the requested changes
git add .
git commit -m "fix: address review feedback

- Rename variable for clarity
- Add additional error handling
- Update comments"

git push origin feature/user-authentication
# Workflows run again automatically
```

#### 9. Merge to Develop

**Once approved:**
1. Click "Squash and merge" (recommended)
2. GitHub merges PR to develop
3. Delete branch (optional but recommended)

#### 10. Automatic Staging Deployment

**GitHub Actions automatically execute:**

```
deploy-staging.yml starts
├─ Validation: 2 min
├─ Build Docker image: 5 min
├─ Deploy to ECS: 3 min
├─ Run smoke tests: 2 min
└─ Total: 12 minutes ✅
```

**Slack notification:**
```
✅ Staging deployment successful
Commit: a1b2c3d
Branch: develop
Environment: staging
URL: https://staging-api.rupaya.com
```

#### 11. QA Testing

Now your feature is live on staging:
- QA team can test at: https://staging-api.rupaya.com
- Use test accounts for authentication
- Report any issues

---

## 📖 Scenario 2: Bug Fix in Development

### Goal: Fix a critical bug in the authentication flow

### Step-by-Step

```bash
# 1. Create bugfix branch from develop
git checkout develop && git pull origin develop
git checkout -b bugfix/token-expiration-issue

# 2. Identify and fix the bug
# Edit src/services/AuthService.js
# Add test for the bug fix
git add .
git commit -m "fix: handle token expiration correctly

- Token refresh now happens before expiration
- Add unit test for refresh timing
- Fix: handles concurrent refresh requests"

# 3. Push and create PR (same as feature workflow)
git push -u origin bugfix/token-expiration-issue

# 4. On GitHub: Create PR to develop, request review
# Workflows run automatically, get approval, merge

# 5. Automatic deployment to staging
# → Available for QA testing within 15 minutes
```

---

## 🚀 Scenario 3: Release to Production

### Goal: Release version 1.2.0 to production

### Step-by-Step

#### 1. Create Release Branch

```bash
# Create from develop (always)
git checkout develop && git pull origin develop
git checkout -b release/1.2.0
```

#### 2. Prepare Release

```bash
# Update version in package.json
# package.json: "version": "1.2.0"

# Update CHANGELOG.md
# Add release notes, date, features, fixes

# Commit release preparation
git add package.json CHANGELOG.md
git commit -m "release: prepare version 1.2.0

- Update version number
- Add release notes
- Document breaking changes (if any)"

# Push release branch
git push -u origin release/1.2.0
```

#### 3. Create PR to Main

**On GitHub:**
1. Create Pull Request from `release/1.2.0` to `main`
2. Title: "Release: version 1.2.0"
3. Description:
   ```markdown
   ## Release Notes
   
   ### Version 1.2.0
   
   **Features:**
   - User authentication with JWT
   - Email verification
   - Password reset flow
   
   **Bug Fixes:**
   - Token expiration handling
   - CORS issue with mobile apps
   
   **Breaking Changes:**
   - API response format changed (v2)
   
   **Database Migrations:**
   - 001_init.sql
   - 002_add_email_column.sql
   
   ### Deployment Info
   - Staging tested: Yes
   - Performance impact: Minimal
   - Rollback plan: Simple (revert image tag in ECS)
   ```

#### 4. Code Review (2 Required)

**For main branch, need 2 approvals:**
1. Request from Tech Lead
2. Request from another senior developer
3. Wait for approvals

**During review:**
- Tech lead verifies release notes
- Reviewers check for any last-minute issues
- Questions are addressed

#### 5. Verify Tests

**All checks must pass:**
- ✅ Linting
- ✅ Unit tests
- ✅ Integration tests
- ✅ Security scan
- ✅ Build check

**Status page shows all checks: ✅**

#### 6. Merge to Main

**Once all conditions met:**
1. All tests passing: ✅
2. 2 approvals: ✅
3. Conversations resolved: ✅
4. Branch up to date: ✅

Click "Merge pull request" → "Squash and merge"

#### 7. Production Deployment Starts

**GitHub Actions automatically execute:**

```
deploy-production.yml starts immediately

Pre-deployment checks
├─ Verify main branch ✅
├─ Check commit message ✅
└─ Verify git history ✅

Build Docker image
├─ Generate tag: prod-a1b2c3d-1624567890
├─ Build for linux/amd64 ✅
└─ Push to ECR ✅

Database migrations
├─ Connect to RDS ✅
├─ Run pending migrations ✅
└─ Verify success ✅

Deploy to ECS
├─ Update task definition ✅
├─ Deploy service ✅
├─ Wait for stability ✅
└─ Verify health checks ✅

Post-deployment testing
├─ Run smoke tests ✅
├─ Check CloudWatch metrics ✅
└─ All systems operational ✅

Total time: ~20-25 minutes
```

#### 8. Production is Live ✅

**Slack notification:**
```
✅ Production deployment successful

Commit: a1b2c3d
Version: 1.2.0
Environment: production
URL: https://api.rupaya.com
Deployed by: GitHub Actions
Time: 22 minutes
```

#### 9. Release Tag Created

```bash
# GitHub automatically creates deployment tag
# Tag format: deploy-prod-YYYYMMDD-HHMMSS
# Example: deploy-prod-20240101-143022
```

#### 10. Auto-merge to Develop

**GitHub automatically:**
1. Merges main back to develop (keep develop up to date)
2. Closes release branch
3. Creates commit "Merge main to develop"

---

## 🔥 Scenario 4: Emergency Hotfix

### Goal: Fix critical security issue in production ASAP

### Step-by-Step

#### 1. Create Hotfix Branch

```bash
# IMPORTANT: Branch from main (not develop)
git checkout main && git pull origin main
git checkout -b hotfix/security-fix-sql-injection
```

#### 2. Fix the Issue

```bash
# Make the minimal necessary changes
# Only fix the security issue, nothing else

git add .
git commit -m "hotfix: patch SQL injection vulnerability

CRITICAL SECURITY FIX

- Parameterize all SQL queries in user endpoint
- Remove direct string concatenation
- Add input validation
- Tested on staging

This fix should be deployed immediately."

git push -u origin hotfix/security-fix-sql-injection
```

#### 3. Create PR (Urgent)

**On GitHub:**
1. Create PR from `hotfix/security-fix-sql-injection` to `main`
2. Title: "🔥 HOTFIX: Security patch - SQL injection vulnerability"
3. Mark as URGENT in description:
   ```markdown
   ## 🔥 CRITICAL SECURITY HOTFIX
   
   **Issue**: SQL injection vulnerability in /api/users endpoint
   **Severity**: CRITICAL
   **CVE**: TBD
   
   **Fix**: Parameterize all queries, add input validation
   
   **Deployment**: IMMEDIATE
   
   @ops-team @tech-lead - Please review and approve ASAP
   ```

#### 4. Expedited Review

**Talk to team:**
- Slack: "Critical hotfix waiting for approval"
- Call if urgent
- Tech lead can approve as needed

**Get 1-2 approvals quickly**

#### 5. Merge Immediately

1. All tests pass: ✅
2. Approval(s) received: ✅
3. Click "Merge" (expedited)

#### 6. Fast-Track Deployment

**GitHub Actions automatically deploy:**

```
deploy-production.yml (expedited)
├─ Pre-deployment checks: 1 min
├─ Build image: 3 min
├─ Deploy to ECS: 2 min
├─ Smoke tests: 1 min
└─ Total: ~7 minutes ⚡
```

**Slack alert (urgent):**
```
🚀 HOTFIX DEPLOYED TO PRODUCTION

Commit: a1b2c3d
Hotfix: Security patch - SQL injection
Deployed: Just now (7 min from approval)
Status: Live and stable ✅
```

#### 7. Back-Port to Develop

**GitHub automatically merges hotfix to develop**
(keeps develop in sync with production fixes)

#### 8. Post-Deployment

1. Monitor for any issues
2. Run extended smoke tests
3. Notify customers if needed
4. Add post-mortem to backlog

---

## 📊 Scenario 5: Monitoring & Troubleshooting

### Workflow Fails - How to Debug

#### Scenario: Tests failing in CI

```bash
# 1. Check what failed in GitHub Actions
# Go to the PR → Click "Checks" tab → Click failing test

# 2. View the error log
# Look for the error message

# 3. Fix locally and reproduce
git fetch origin feature/my-feature
git checkout feature/my-feature

# Run the same test locally
npm run test:integration

# 4. Fix the issue
# ... make changes ...

# 5. Commit and push
git add .
git commit -m "fix: update test to match database schema"
git push origin feature/my-feature

# Workflows run again automatically
# After fix, all checks should pass
```

#### Scenario: Deployment Fails

```bash
# 1. Check GitHub Actions logs
# Go to deploy-production.yml run → Click failed job

# 2. Common issues:
# - ECS service unavailable → Check AWS console
# - Database migration failed → Check RDS logs
# - Health check failed → Check application logs

# 3. Rollback if needed (manual)
# Contact ops team with rollback command

# 4. Fix the issue
# Create hotfix branch
git checkout main && git pull
git checkout -b hotfix/deployment-issue
# Fix the issue...
git push -u origin hotfix/deployment-issue
# Create PR and deploy again
```

### Monitor Deployments

```bash
# View recent deployments
gh run list --workflow deploy-production.yml --limit 10

# View specific deployment logs
gh run view <run-id> --log

# View deployment status
git tag | grep deploy-prod | sort -r | head -5
# Most recent deployments with timestamps
```

---

## 🎓 Learning Path

### Day 1: Understand the Strategy
1. Read: `docs/GIT_BRANCHING_STRATEGY.md`
2. Review: Branch protection rules in GitHub Settings
3. Understand: Why we use Git Flow

### Day 2: Make Your First Change
1. Create feature branch: `git checkout -b feature/my-first-change develop`
2. Make small change (e.g., update README)
3. Create PR
4. Watch workflows run
5. Get reviewed and merged

### Day 3: Monitor the Deployment
1. Watch staging deployment in GitHub Actions
2. Check Slack notification
3. Verify change is live on staging

### Week 2: Try Different Scenarios
1. Create a bugfix branch
2. Try a release branch
3. Ask for code review
4. See the full workflow in action

### Week 3+: Become an Expert
1. Help other team members
2. Suggest workflow improvements
3. Monitor production deployments
4. Participate in code reviews

---

## 🛟 Help & Support

### Getting Help

```bash
# Not sure what branch to use?
→ Review: docs/GIT_BRANCHING_STRATEGY.md

# Questions about workflows?
→ Ask: @platform-team

# Tests failing?
→ Check: GitHub Actions logs

# Deployment stuck?
→ Check: CloudWatch logs in AWS console
→ Ask: @devops-team

# Emergency issue?
→ Slack: @ops-team
```

### Useful Commands

```bash
# See current branch
git branch

# See all branches
git branch -a

# Switch to develop
git checkout develop

# See commits not in main
git log main..develop

# See changes since last commit
git status

# See what you'll commit
git diff --staged

# See workflow logs locally
gh run view <run-id> --log
```

---

## ✅ Checklist Before Merging

- [ ] All tests pass locally: `npm run test:all`
- [ ] Linting passes: `npm run lint`
- [ ] Commit message is clear
- [ ] PR description is complete
- [ ] Requested reviewer(s)
- [ ] No merge conflicts
- [ ] Only 1-3 commits (clean history)
- [ ] No debug code or console.logs
- [ ] Database migrations (if needed) are included
- [ ] CHANGELOG updated (for releases)

---

## 🎯 Key Takeaways

1. **Feature branches** are deployed to staging automatically
2. **Main branch** is production (automatic deployment)
3. **Develop branch** is staging (automatic deployment)
4. **All tests must pass** before merge
5. **Code review required** (1 for develop, 2 for main)
6. **Hotfixes** bypass release cycle (< 5 min)
7. **Slack notifications** alert team of deployments
8. **Monitoring** catches issues immediately

---

**Next**: Choose a scenario above that matches your task and follow the step-by-step guide!

