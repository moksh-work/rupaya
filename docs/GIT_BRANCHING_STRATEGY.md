# Git Branching Strategy & Workflow

This document defines the branching strategy used by Rupaya, following industry best practices used by companies like Spotify, Netflix, and Google.

## Branch Strategy: Git Flow + Trunk-Based Development Hybrid

We use a hybrid approach optimized for continuous deployment with safety gates:

```
main (production)
  ↑
  ├── release/1.x.x (release candidates)
  │
develop (staging/pre-production)
  ↑
  ├── feature/FEATURE-NAME
  ├── bugfix/BUG-NAME
  ├── hotfix/ISSUE-NAME
  └── chore/TASK-NAME
```

## Branch Naming Conventions

### Main Branches (Protected)

| Branch | Purpose | Deployments | Protection |
|--------|---------|-------------|-----------|
| `main` | Production ready | AWS Production (ECS, RDS) | ✅ Code review required<br/>✅ All tests pass<br/>✅ 2 approvals min |
| `develop` | Integration/Staging | AWS Staging (ECS, RDS) | ✅ Code review required<br/>✅ All tests pass<br/>✅ 1 approval min |

### Supporting Branches

#### Feature Branches
```
feature/JIRA-123-add-budget-alerts
feature/JIRA-456-mobile-offline-mode
```
- **Source**: `develop`
- **Naming**: `feature/JIRA-XXXXX-kebab-case-description`
- **Lifecycle**: Delete after merge
- **Deployment**: Pull Request preview environment

#### Bug Fix Branches
```
bugfix/JIRA-789-fix-login-crash
bugfix/JIRA-101-token-expiry-issue
```
- **Source**: `develop`
- **Naming**: `bugfix/JIRA-XXXXX-kebab-case-description`
- **Lifecycle**: Delete after merge
- **Deployment**: PR staging preview

#### Hotfix Branches (Production Bugs)
```
hotfix/security-token-revocation
hotfix/critical-database-corruption
```
- **Source**: `main` (production)
- **Naming**: `hotfix/SEVERITY-kebab-case-description`
- **Lifecycle**: Delete after merge
- **Deployment**: Urgent AWS Production deployment
- **Process**: 
  1. Fix in hotfix branch
  2. Merge to `main` + `develop`
  3. Tag with version

#### Release Branches
```
release/1.2.0
release/2.0.0-beta
```
- **Source**: `develop`
- **Naming**: `release/SEMVER`
- **Lifecycle**: Delete after production release
- **Deployment**: Final staging validation → Production
- **Process**:
  1. Version bump
  2. Final testing in staging
  3. Merge to `main`
  4. Merge back to `develop`
  5. Tag: `v1.2.0`

#### Chore Branches
```
chore/update-dependencies
chore/refactor-auth-service
chore/add-monitoring-alerts
```
- **Source**: `develop`
- **Naming**: `chore/kebab-case-description`
- **Lifecycle**: Delete after merge
- **Deployment**: Staging only

## Workflow Examples

### Creating a Feature
```bash
# Update develop with latest changes
git checkout develop
git pull origin develop

# Create feature branch
git checkout -b feature/JIRA-123-budget-alerts

# Make changes and commit
git add .
git commit -m "feat: add budget alert notifications"
git push origin feature/JIRA-123-budget-alerts

# Create Pull Request to develop
# - Automated tests run
# - Preview deployment to staging
# - Request code review
# - Merge after approvals
```

### Release Process
```bash
# Create release branch from develop
git checkout -b release/1.2.0 develop

# Update version numbers and changelog
npm version minor --no-git-tag-version
# Update VERSION file, changelog

git add .
git commit -m "chore: release v1.2.0"
git push origin release/1.2.0

# Create PR to main
# - Final staging validation
# - Performance testing
# - Merge to main
# - Tag release

git checkout main
git pull
git merge --no-ff release/1.2.0 -m "chore: merge release v1.2.0"
git tag -a v1.2.0 -m "Version 1.2.0"
git push origin main --tags

# Merge back to develop
git checkout develop
git merge --no-ff release/1.2.0
git push origin develop

# Delete release branch
git push origin --delete release/1.2.0
```

### Emergency Hotfix
```bash
# Create hotfix from main
git checkout -b hotfix/critical-security-fix main

# Fix issue
git add .
git commit -m "fix: security token revocation bug"
git push origin hotfix/critical-security-fix

# Create PR to main (expedited review)
# Merge immediately
git checkout main
git merge --no-ff hotfix/critical-security-fix
git tag -a v1.2.1 -m "Hotfix: security issue"
git push origin main --tags

# Also merge to develop
git checkout develop
git merge --no-ff hotfix/critical-security-fix
git push origin develop

# Delete hotfix branch
git push origin --delete hotfix/critical-security-fix
```

## Branch Protection Rules

### `main` Branch
```
- Require a pull request before merging
- Require code review before merging (2 approvals)
- Require status checks to pass:
  - backend-tests
  - backend-lint
  - mobile-tests
  - security-scan
  - deployment-preview
- Require branches to be up to date
- Require linear history (no merge commits)
- Restrict force pushes
- Dismiss stale reviews when new commits pushed
```

### `develop` Branch
```
- Require a pull request before merging
- Require code review before merging (1 approval)
- Require status checks to pass:
  - backend-tests
  - backend-lint
  - mobile-tests
- Require branches to be up to date
- Restrict force pushes
- Dismiss stale reviews when new commits pushed
```

## Versioning Strategy

### Semantic Versioning (SemVer)
```
MAJOR.MINOR.PATCH[-PRERELEASE][+BUILD]

Examples:
- v1.0.0      (initial release)
- v1.2.3      (patch fix)
- v2.0.0      (breaking changes)
- v1.2.0-rc1  (release candidate)
- v1.2.0-beta (beta release)
```

### Tagging
```bash
# Production release
git tag -a v1.2.0 -m "Production release v1.2.0"

# Beta release
git tag -a v1.2.0-beta -m "Beta release v1.2.0-beta"

# Release candidate
git tag -a v1.2.0-rc1 -m "Release candidate v1.2.0-rc1"

# Push tags
git push origin --tags
```

## Commit Message Convention

Follow Conventional Commits format:

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Code style (formatting, missing semicolons)
- `refactor`: Code refactoring
- `perf`: Performance improvement
- `test`: Adding/updating tests
- `chore`: Maintenance, dependencies, version bumps
- `ci`: CI/CD configuration
- `security`: Security fixes

### Examples
```
feat(auth): implement token revocation on logout
fix(backend): prevent token replay attacks
docs(readme): add AWS deployment guide
chore(deps): update dependencies to latest versions
security(jwt): extend token validation checks
```

## Pull Request Process

### 1. Create Pull Request
```
Title: [JIRA-123] Add budget alerts feature

Description:
## Overview
Brief description of changes

## Changes Made
- [ ] Feature 1
- [ ] Feature 2
- [ ] Tests added

## Testing
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing completed

## Deployment
- [ ] Database migrations tested
- [ ] Backward compatible
- [ ] No breaking changes
```

### 2. Automated Checks
- ✅ Tests pass (backend, mobile)
- ✅ Linting passes
- ✅ Code coverage maintained (min 70%)
- ✅ Security scan passes
- ✅ Preview environment deploys

### 3. Code Review
- Review for code quality
- Check for security issues
- Verify test coverage
- Validate API contracts

### 4. Merge Strategy
```bash
# Keep commit history clean with squash + rebase
# On GitHub: "Squash and merge" for feature branches
# On GitHub: "Create a merge commit" for release branches
```

## Deployment Flow

```
feature/ → PR → develop → staging deploy → tests pass
                                             ↓
                                        release/ → main → production deploy
                                        (tag version)
```

### Environments
| Environment | Branch | Auto-Deploy | Tests | Scale |
|-------------|--------|-------------|-------|-------|
| **Dev** | Feature | Manual PR | Unit | Local |
| **Staging** | develop | Auto | All | AWS (staging) |
| **Production** | main | Manual | All | AWS (prod) |

## Team Guidelines

### For Developers
✅ **DO:**
- Create feature branches from `develop`
- Use meaningful branch names
- Keep commits atomic and well-messaged
- Push to remote daily to avoid loss
- Rebase instead of merge locally (keep history clean)

❌ **DON'T:**
- Commit directly to `main` or `develop`
- Force push to shared branches
- Leave feature branches stale (merge/delete)
- Skip tests before pushing
- Ignore code review comments

### For Code Reviewers
✅ **DO:**
- Review within 24 hours
- Check tests and coverage
- Look for security issues
- Provide constructive feedback
- Approve when satisfied

❌ **DON'T:**
- Approve without testing locally
- Block on style preferences
- Ask for unnecessary changes
- Merge others' PRs (they should do it)

### For Release Manager
✅ **DO:**
- Create release branch from `develop`
- Update version numbers consistently
- Update CHANGELOG.md
- Test thoroughly in staging
- Tag production releases
- Communicate deployment status

## Troubleshooting

### Accidentally committed to `main`
```bash
git reset HEAD~1
git stash
git checkout -b feature/my-feature
git stash pop
git push origin feature/my-feature
```

### Need to merge `main` changes into feature
```bash
git checkout feature/my-feature
git fetch origin
git rebase origin/main
# Resolve conflicts if any
git push -f origin feature/my-feature
```

### Merge conflicts
```bash
# Update both branches
git fetch origin
git rebase origin/develop

# Fix conflicts in editor
# Then:
git add .
git rebase --continue
git push -f origin feature/my-feature
```

## References
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Semantic Versioning](https://semver.org/)
- [Git Flow](https://nvie.com/posts/a-successful-git-branching-model/)
- [GitHub Flow](https://guides.github.com/introduction/flow/)
