# Git Flow Quick Reference Guide

A quick reference guide for developers working with Rupaya's Git Flow branching strategy and automated CI/CD pipelines.

## Quick Start

### Starting a Feature

```bash
# Update develop with latest
git checkout develop
git pull origin develop

# Create your feature branch
git checkout -b feature/JIRA-123-add-budget-alerts

# Make changes and commit with conventional commits
git add .
git commit -m "feat: add budget alert notifications to user dashboard"

# Push to remote
git push origin feature/JIRA-123-add-budget-alerts

# Create Pull Request on GitHub
# → Automatic: git-flow-feature workflow runs
# → Automatic: 02-common-backend.yml test suite runs
# → Manual: Get 1 approval from code reviewer
# → Click: Merge Pull Request (squash and merge)
```

### Creating a Release

```bash
# Create release branch from develop
git checkout develop
git pull origin develop
git checkout -b release/1.2.0

# Update version numbers
# Edit VERSION file → 1.2.0
# Edit CHANGELOG.md → Add section for v1.2.0 with changes

git add VERSION CHANGELOG.md
git commit -m "chore: release v1.2.0 - budget alerts feature"
git push origin release/1.2.0

# Create Pull Request to main
# → Automatic: git-flow-release workflow runs
# → Automatic: Full test suite
# → Manual: Get 2 approvals (1 from release manager)
# → Click: Merge Pull Request (create merge commit)

# After merge:
# → Automatic: Tag created (v1.2.0)
# → Automatic: Deploys to production
# → Automatic: Merges back to develop
```

### Emergency Hotfix

```bash
# Create hotfix from main (NOT from develop!)
git checkout main
git pull origin main
git checkout -b hotfix/critical-security-fix

# Fix the critical issue
git add .
git commit -m "fix: prevent token replay attack vulnerability"
git push origin hotfix/critical-security-fix

# Create Pull Request to main
# → Automatic: git-flow-hotfix workflow runs
# → Automatic: Full test suite + security scan
# → Manual: Get 1 approval (expedited review)
# → Click: Merge Pull Request

# After merge:
# → Automatic: Tag created (v1.2.1)
# → Automatic: High-priority deploy to production
# → Automatic: Merges back to develop
```

## Branch Naming Guide

### Feature Branches
```bash
feature/JIRA-123-add-user-preferences
feature/JIRA-456-implement-2fa
feature/JIRA-789-improve-api-performance

Format: feature/JIRA-{NUMBER}-{kebab-case-description}
```

### Bug Fix Branches
```bash
bugfix/JIRA-111-fix-login-crash
bugfix/JIRA-222-resolve-payment-timeout
bugfix/JIRA-333-prevent-duplicate-charges

Format: bugfix/JIRA-{NUMBER}-{kebab-case-description}
```

### Chore Branches
```bash
chore/update-dependencies
chore/refactor-auth-service
chore/add-monitoring-alerts

Format: chore/{kebab-case-description}
```

### Release Branches
```bash
release/1.2.0
release/2.0.0-rc1
release/1.2.3-beta

Format: release/{SEMVER}
```

### Hotfix Branches
```bash
hotfix/critical-security-vulnerability
hotfix/database-connection-pooling-fix
hotfix/payment-gateway-timeout

Format: hotfix/{kebab-case-description}
```

## Commit Message Convention

Use **Conventional Commits** format:

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Code style (formatting, semicolons)
- `refactor`: Code refactoring
- `perf`: Performance improvement
- `test`: Adding/updating tests
- `chore`: Maintenance, dependencies
- `ci`: CI/CD configuration
- `security`: Security fixes

### Examples

```
feat(auth): implement token revocation on logout

- Add endpoint to revoke tokens
- Store revoked tokens in Redis cache
- Update mobile app to call new endpoint

Closes: JIRA-123
```

```
fix(backend): prevent race condition in order processing

The order service was creating duplicate orders due to
missing database constraints. Added unique constraint
and transactional updates.

Fixes: JIRA-456
```

```
chore(deps): update dependencies to latest versions

- Update express from 4.17 to 4.18
- Update typescript from 4.8 to 4.9
- Update jest from 28 to 29
```

## Pull Request Checklist

### For All PRs

- [ ] Branch created from correct base (`develop` or `main`)
- [ ] Branch name follows convention (feature/JIRA-XXX-description)
- [ ] Commit messages follow Conventional Commits
- [ ] All tests pass locally
- [ ] No console.logs or debug code
- [ ] No secrets committed
- [ ] Code formatted (ESLint, Prettier)
- [ ] Updated CHANGELOG.md (if public API change)

### For Feature/Bugfix PRs

- [ ] Tests added for new functionality
- [ ] Existing tests still pass
- [ ] Code review checklist items completed
- [ ] 1 approval received

### For Release PRs

- [ ] VERSION file updated to new version
- [ ] CHANGELOG.md updated with release notes
- [ ] All tests passing
- [ ] Performance impact assessed
- [ ] 2 approvals received (1 from release manager)

### For Hotfix PRs

- [ ] Critical issue clearly described in PR
- [ ] Fix tested in staging environment
- [ ] Root cause analysis in PR description
- [ ] 1 approval received (expedited)

## Workflow Status Checks

### Feature Branch PR

```
✓ Lint Check (02-common-backend.yml)
✓ Unit Tests (02-common-backend.yml)
✓ Security Scan (git-flow-feature.yml)
✓ Code Quality Check (git-flow-feature.yml)
```

**What happens after merge to develop:**
1. Runs: 02-common-backend.yml (full test suite)
2. Runs: terraform-staged-deploy.yml (staging infrastructure)
3. Runs: deploy-staging.yml (deploys to staging)
4. Result: Code deployed to staging within 5-10 minutes

### Release PR

```
✓ Version Validation (git-flow-release.yml)
✓ Changelog Validation (git-flow-release.yml)
✓ Full Test Suite (02-common-backend.yml)
✓ Security Scan (git-flow-release.yml)
```

**What happens after merge to main:**
1. Runs: terraform-staged-deploy.yml (production infrastructure)
2. Runs: deploy-production.yml (deploys to production)
3. Creates: Git tag (v1.2.0)
4. Result: Code deployed to production within 10-15 minutes
5. Auto-merge: Back to develop (to keep in sync)

### Hotfix PR

```
✓ Hotfix Validation (git-flow-hotfix.yml)
✓ Full Test Suite (02-common-backend.yml)
✓ Security Scan (git-flow-hotfix.yml)
```

**What happens after merge to main:**
1. Runs: terraform-staged-deploy.yml (production infrastructure)
2. Runs: deploy-production.yml (HIGH PRIORITY deployment)
3. Creates: Git tag (v1.2.1)
4. Result: Code deployed to production within 5 minutes (urgent)
5. Auto-merge: Back to develop
6. Alert: Team notified of hotfix deployment

## Environment Details

### Staging Environment

- **Triggered by:** `develop` branch push
- **Auto-deploy:** Yes (immediate)
- **Approval:** Not required
- **AWS Resources:** Separate staging RDS, Redis, ECS cluster
- **Data:** Test data fixtures, no production data
- **Access:** Full team access
- **Deployment Time:** 5-10 minutes

### Production Environment

- **Triggered by:** `main` branch push, hotfix merge
- **Auto-deploy:** Yes (main), Urgent (hotfix)
- **Approval:** Manual for `release/*` branch
- **AWS Resources:** Production RDS with backups, Redis, ECS cluster
- **Data:** Real production data
- **Access:** Limited to release manager and ops team
- **Deployment Time:** 10-15 minutes (normal), 5 minutes (hotfix)
- **Rollback:** Available within 1 hour via previous ECS task definition

## Common Tasks

### View Deployment Logs

```bash
# View latest 20 log lines from staging
aws logs tail /ecs/rupaya-staging --follow --since 1h

# View specific time range
aws logs filter-log-events \
  --log-group /ecs/rupaya-staging \
  --start-time $(date -d '30 minutes ago' +%s)000
```

### Rollback Production

```bash
# Manual rollback (if auto-rollback fails)
aws ecs update-service \
  --cluster rupaya-production \
  --service rupaya-backend \
  --task-definition rupaya-task:PREVIOUS_VERSION \
  --region us-east-1
```

### View Terraform Changes

```bash
# Check infrastructure changes in PR
# Look for "Terraform Plan" comment on PR

# Or check locally
cd infra/aws
terraform plan
```

### Trigger Manual Deployment

```bash
# If automated deployment fails, manually trigger from GitHub
# 1. Go to: Actions → Terraform Infrastructure Deploy
# 2. Click: "Run workflow"
# 3. Select: Environment (staging/production)
# 4. Select: Auto-apply (true/false)
# 5. Click: "Run workflow"
```

## Troubleshooting

### Tests Failing on Feature Branch

```bash
# Run tests locally to debug
cd backend
npm install
npm test

# Check specific test file
npm test -- --testPathPattern=auth.test.js

# Update snapshot if intentional
npm test -- -u
```

### Deployment Stuck in Progress

```bash
# Check ECS service status
aws ecs describe-services \
  --cluster rupaya-staging \
  --services rupaya-backend \
  --region us-east-1

# View task logs
aws logs tail /ecs/rupaya-staging --follow
```

### Can't Merge PR - Status Checks Failing

```bash
# Common causes:
1. Tests failing → Run locally and fix
2. Linting issues → Run: npm run lint --fix
3. Coverage dropped → Add tests
4. Security scan failed → Check npm audit output

# After fixes:
git add .
git commit -m "fix: resolve test failures"
git push origin feature/JIRA-123-description

# GitHub will automatically re-run checks
```

### Wrong Branch for PR

```bash
# If you created PR from wrong branch:
1. On GitHub: Close the PR
2. Locally:
   git checkout correct-base-branch
   git pull origin correct-base-branch
   git checkout your-branch
   git rebase correct-base-branch
   git push -f origin your-branch
3. Create new PR to correct base
```

## Tips & Best Practices

✅ **DO:**
- Keep feature branches small and focused
- Commit frequently with clear messages
- Push to remote daily to backup work
- Review your own PR first before requesting review
- Use GitHub issue/PR templates
- Test locally before pushing
- Rebase instead of merge locally

❌ **DON'T:**
- Commit directly to `develop` or `main`
- Force push to shared branches
- Leave feature branches stale
- Commit secrets or credentials
- Use generic commit messages ("fix", "update", "work")
- Skip code reviews
- Ignore failing tests

## Getting Help

- **Questions about Git Flow?** → Read [GIT_BRANCHING_STRATEGY.md](./GIT_BRANCHING_STRATEGY.md)
- **Workflow documentation?** → Read [GITHUB_WORKFLOWS_GITFLOW.md](./GITHUB_WORKFLOWS_GITFLOW.md)
- **AWS deployment issues?** → Read [AWS_DEPLOYMENT_GUIDE.md](./AWS_DEPLOYMENT_GUIDE.md)
- **Need to discuss?** → Post in team Slack #engineering channel

## References

- [Conventional Commits](https://www.conventionalcommits.org/)
- [Semantic Versioning](https://semver.org/)
- [Git Flow Model](https://nvie.com/posts/a-successful-git-branching-model/)
- [GitHub Flow](https://guides.github.com/introduction/flow/)
