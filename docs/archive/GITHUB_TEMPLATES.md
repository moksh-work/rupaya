# RUPAYA GitHub Templates & Workflows

## GitHub Action Workflows (CI/CD)

### 1. Backend Tests Workflow

**File: `.github/workflows/backend-tests.yml`**

```yaml
name: Backend Tests & Lint

on:
  push:
    branches: [ main, develop ]
    paths:
      - 'backend/**'
      - 'shared/**'
  pull_request:
    branches: [ main, develop ]
    paths:
      - 'backend/**'
      - 'shared/**'

env:
  NODE_VERSION: '18'

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:15-alpine
        env:
          POSTGRES_USER: rupaya_test
          POSTGRES_PASSWORD: test_password
          POSTGRES_DB: rupaya_test
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432
      
      redis:
        image: redis:7-alpine
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 6379:6379

    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
          cache-dependency-path: backend/package-lock.json
      
      - name: Install dependencies
        run: |
          cd backend
          npm install
      
      - name: Run linter
        run: |
          cd backend
          npm run lint
      
      - name: Run tests
        env:
          NODE_ENV: test
          DB_HOST: localhost
          DB_PORT: 5432
          DB_USER: rupaya_test
          DB_PASSWORD: test_password
          DB_NAME: rupaya_test
          REDIS_HOST: localhost
          REDIS_PORT: 6379
          JWT_SECRET: test_secret_min_32_chars_long
          JWT_REFRESH_SECRET: test_refresh_min_32_chars_long
        run: |
          cd backend
          npm test
      
      - name: Generate coverage report
        run: |
          cd backend
          npm run test:coverage
      
      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          files: ./backend/coverage/coverage-final.json
          flags: backend
          name: backend-coverage
          fail_ci_if_error: false
      
      - name: Comment PR with coverage
        if: github.event_name == 'pull_request'
        uses: romeovs/lcov-reporter-action@v0.3.1
        with:
          lcov-file: ./backend/coverage/lcov.info
```

---

### 2. Mobile Build Check Workflow

**File: `.github/workflows/mobile-build.yml`**

```yaml
name: Mobile Build Check

on:
  push:
    branches: [ main, develop ]
    paths:
      - 'ios/**'
      - 'android/**'
      - 'shared/**'
  pull_request:
    branches: [ main, develop ]
    paths:
      - 'ios/**'
      - 'android/**'
      - 'shared/**'

jobs:
  ios-build:
    name: iOS Build & Tests
    runs-on: macos-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.0'
          bundler-cache: true
      
      - name: Install CocoaPods
        run: |
          cd ios
          pod install
      
      - name: Build iOS app
        run: |
          cd ios
          xcodebuild build \
            -workspace RUPAYA.xcworkspace \
            -scheme RUPAYA \
            -configuration Debug \
            -destination 'generic/platform=iOS Simulator' \
            -derivedDataPath build
      
      - name: Run iOS tests
        run: |
          cd ios
          xcodebuild test \
            -workspace RUPAYA.xcworkspace \
            -scheme RUPAYA \
            -configuration Debug \
            -destination 'platform=iOS Simulator,name=iPhone 15' \
            -derivedDataPath build \
            -resultBundlePath TestResults.xcresult
      
      - name: Upload test results
        if: failure()
        uses: actions/upload-artifact@v3
        with:
          name: ios-test-results
          path: ios/TestResults.xcresult
  
  android-build:
    name: Android Build & Tests
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Java
        uses: actions/setup-java@v3
        with:
          distribution: 'temurin'
          java-version: '11'
          cache: 'gradle'
      
      - name: Setup Android SDK
        uses: android-actions/setup-android@v2
      
      - name: Run lint checks
        run: |
          cd android
          ./gradlew lint
      
      - name: Build debug APK
        run: |
          cd android
          ./gradlew assembleDebug
      
      - name: Run unit tests
        run: |
          cd android
          ./gradlew test
      
      - name: Run instrumented tests
        run: |
          cd android
          ./gradlew connectedAndroidTest
      
      - name: Upload build artifacts
        if: success()
        uses: actions/upload-artifact@v3
        with:
          name: android-apk
          path: android/app/build/outputs/apk/debug/

      - name: Upload test results
        if: failure()
        uses: actions/upload-artifact@v3
        with:
          name: android-test-results
          path: android/app/build/reports/
```

---

### 3. Production Deploy Workflow

**File: `.github/workflows/deploy-production.yml`**

```yaml
name: Deploy to Production

on:
  push:
    branches: [ main ]
    tags:
      - 'v*.*.*'

env:
  AWS_REGION: ap-south-1
  ECR_REPOSITORY: rupaya-backend
  ECS_SERVICE: rupaya-service
  ECS_CLUSTER: rupaya-cluster
  ECS_TASK_DEFINITION: rupaya-task

jobs:
  deploy:
    name: Deploy Backend to Production
    runs-on: ubuntu-latest
    
    permissions:
      contents: read
      id-token: write
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'
          cache-dependency-path: backend/package-lock.json
      
      - name: Install dependencies
        run: |
          cd backend
          npm install
      
      - name: Run linter
        run: |
          cd backend
          npm run lint
      
      - name: Run tests
        env:
          NODE_ENV: test
          DB_HOST: localhost
          DB_PORT: 5432
          DB_USER: rupaya_test
          DB_PASSWORD: test_password
          DB_NAME: rupaya_test
          REDIS_HOST: localhost
          REDIS_PORT: 6379
          JWT_SECRET: test_secret_min_32_chars_long
          JWT_REFRESH_SECRET: test_refresh_min_32_chars_long
        run: |
          cd backend
          npm test
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_TO_ASSUME }}
          aws-region: ${{ env.AWS_REGION }}
      
      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v1
      
      - name: Build, tag, and push Docker image to ECR
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          IMAGE_TAG: ${{ github.sha }}
        run: |
          docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG ./backend
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
          docker tag $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG $ECR_REGISTRY/$ECR_REPOSITORY:latest
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:latest
      
      - name: Download task definition
        run: |
          aws ecs describe-task-definition \
            --task-definition ${{ env.ECS_TASK_DEFINITION }} \
            --query taskDefinition \
            > task-definition.json
      
      - name: Update ECS task definition with new Docker image
        id: task-def
        uses: aws-actions/amazon-ecs-render-task-definition@v1
        with:
          task-definition: task-definition.json
          container-name: rupaya-backend
          image: ${{ steps.login-ecr.outputs.registry }}/${{ env.ECR_REPOSITORY }}:${{ github.sha }}
      
      - name: Deploy to Amazon ECS service
        uses: aws-actions/amazon-ecs-deploy-task-definition@v1
        with:
          task-definition: ${{ steps.task-def.outputs.task-definition }}
          service: ${{ env.ECS_SERVICE }}
          cluster: ${{ env.ECS_CLUSTER }}
          wait-for-service-stability: true
      
      - name: Notify Slack on success
        if: success()
        uses: slackapi/slack-github-action@v1.24.0
        with:
          webhook-url: ${{ secrets.SLACK_WEBHOOK_PROD }}
          payload: |
            {
              "text": "✅ Production deployment successful",
              "blocks": [
                {
                  "type": "section",
                  "text": {
                    "type": "mrkdwn",
                    "text": "*Production Deployment Successful* ✅\n*Commit:* <${{ github.server_url }}/${{ github.repository }}/commit/${{ github.sha }}|${{ github.sha }}>\n*Branch:* main\n*Docker Image:* ${{ steps.login-ecr.outputs.registry }}/${{ env.ECR_REPOSITORY }}:${{ github.sha }}"
                  }
                }
              ]
            }
      
      - name: Notify Slack on failure
        if: failure()
        uses: slackapi/slack-github-action@v1.24.0
        with:
          webhook-url: ${{ secrets.SLACK_WEBHOOK_PROD }}
          payload: |
            {
              "text": "❌ Production deployment failed",
              "blocks": [
                {
                  "type": "section",
                  "text": {
                    "type": "mrkdwn",
                    "text": "*Production Deployment Failed* ❌\n*Commit:* <${{ github.server_url }}/${{ github.repository }}/commit/${{ github.sha }}|${{ github.sha }}>\n*Branch:* main\n*Action:* <${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}|View Logs>"
                  }
                }
              ]
            }
```

---

## Pull Request Template

**File: `.github/pull_request_template.md`**

```markdown
## Description
<!-- Clearly describe what this PR does -->
Resolves #[issue number]

## Type of Change
<!-- Mark the relevant option with an "x" -->
- [ ] 🐛 Backend (API, database, services)
- [ ] 📱 iOS app (Swift/SwiftUI)
- [ ] 🤖 Android app (Kotlin/Compose)
- [ ] 🔧 Infrastructure (Terraform, Docker)
- [ ] 📚 Documentation
- [ ] ♻️ Refactor (no new features)

## Changes Made
<!-- List specific changes -->
- Change 1
- Change 2
- Change 3

## Testing
<!-- Describe how you tested this -->

### Test Coverage
- [ ] Unit tests written/updated (>80%)
- [ ] Integration tests written/updated
- [ ] Manual testing completed

### Test Results
```
Frontend test passes: ✓
Backend test passes: ✓
Coverage: 92%
```

## Screenshots/Demo (if UI change)
<!-- Add screenshots or video of the feature -->

## Checklist
<!-- Verify all items before requesting review -->
- [ ] Code follows project style guide
- [ ] Linting passes (`npm run lint` or equivalent)
- [ ] Tests pass and coverage >80%
- [ ] Documentation updated (if needed)
- [ ] No breaking changes (or clearly documented)
- [ ] Commits follow conventional commits format
- [ ] No debug logs, console.logs, or comments left in
- [ ] No hardcoded secrets or credentials
- [ ] No unnecessary dependencies added

## Performance Impact
<!-- Describe any performance implications -->
- [ ] No performance impact
- [ ] Improves performance (describe)
- [ ] May impact performance (describe mitigation)

## Security Considerations
<!-- Any security implications? -->
- [ ] No security considerations
- [ ] Reviewed for OWASP Top 10
- [ ] Requires security audit

## Deployment Notes
<!-- Any special deployment requirements? -->
- [ ] No database migrations needed
- [ ] Database migrations included (describe)
- [ ] Environment variables changed (describe)
- [ ] Requires feature flag (describe)

## Rollback Plan
<!-- How to rollback if issues arise? -->
Can be rolled back by reverting this commit: `git revert <hash>`

## Related Issues
- Closes #[issue]
- Related to #[issue]
- Depends on #[issue]

## Reviewer Notes
<!-- Any specific areas for review? -->

## Before Merge
- [ ] All feedback addressed
- [ ] All checks passing (CI/CD green)
- [ ] At least 1 approval (backend/mobile team)
```

---

## Issue Templates

### Bug Report

**File: `.github/ISSUE_TEMPLATE/bug_report.md`**

```markdown
---
name: Bug Report
about: Report a bug to help us improve
title: "[BUG] "
labels: bug, needs-triage
assignees: ''

---

## Describe the Bug
<!-- Clear description of what the bug is -->

## To Reproduce
Steps to reproduce the behavior:
1. Go to '...'
2. Click on '....'
3. Scroll down to '....'
4. See error

## Expected Behavior
<!-- Describe what should happen -->

## Actual Behavior
<!-- Describe what actually happens -->

## Screenshots/Logs
<!-- Add screenshots or error logs -->
```

### Feature Request

**File: `.github/ISSUE_TEMPLATE/feature_request.md`**

```markdown
---
name: Feature Request
about: Suggest a new feature
title: "[FEATURE] "
labels: enhancement, needs-triage
assignees: ''

---

## Is your feature request related to a problem?
<!-- Describe the problem. E.g., "I'm always frustrated when..." -->

## Describe the Solution You'd Like
<!-- Clear description of what you want to happen -->

## Describe Alternatives You've Considered
<!-- Any alternative solutions or features you've considered? -->

## Additional Context
<!-- Any other context? -->
```

---

## Code Owners

**File: `.github/CODEOWNERS`**

```
# Global
* @tech-lead

# Backend
backend/ @backend-team
backend/src/controllers/ @backend-team
backend/src/services/ @backend-team
backend/migrations/ @backend-team @database-admin

# iOS
ios/ @ios-team
ios/RUPAYA/Features/Authentication/ @ios-team
ios/RUPAYA/Core/Networking/ @security-team

# Android
android/ @android-team
android/app/src/main/kotlin/com/rupaya/features/authentication/ @android-team
android/app/src/main/kotlin/com/rupaya/core/network/ @security-team

# Shared
shared/ @tech-lead

# Infrastructure
deployment/ @devops-team
deployment/terraform/ @devops-team @aws-admin

# Documentation
docs/ @tech-lead
*.md @tech-lead

# Security
*.lock @devops-team
Dockerfile* @devops-team
```

---

## Branch Protection Rules

**Settings → Branches → Add Rule**

### For `main` branch:
```
Branch name pattern: main

✅ Require pull request reviews before merging
   - Dismiss stale pull request approvals: YES
   - Require code owner reviews: YES
   - Number of approvals required: 2

✅ Require status checks to pass before merging
   - Backend Tests & Lint
   - Mobile Build Check
   - Codecov/Project

✅ Require branches to be up to date before merging

✅ Restrict who can push to matching branches
   - @tech-lead
   - @devops-team
```

### For `develop` branch:
```
Branch name pattern: develop

✅ Require pull request reviews before merging
   - Dismiss stale pull request approvals: YES
   - Number of approvals required: 1

✅ Require status checks to pass before merging
   - Backend Tests & Lint
   - Mobile Build Check

✅ Require branches to be up to date before merging
```

---

## GitHub Secrets (for CI/CD)

**Settings → Secrets and variables → Actions → New repository secret**

```
AWS_REGION = "ap-south-1"
AWS_ROLE_TO_ASSUME = "arn:aws:iam::ACCOUNT_ID:role/github-actions-role"
ECR_REPOSITORY = "rupaya-backend"
ECS_CLUSTER = "rupaya-cluster"
ECS_SERVICE = "rupaya-service"
ECS_TASK_DEFINITION = "rupaya-task"

SLACK_WEBHOOK_PROD = "https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
SLACK_WEBHOOK_DEV = "https://hooks.slack.com/services/YOUR/WEBHOOK/URL"

# Optional: For app signing
APPLE_DEVELOPER_EMAIL = "dev@company.com"
APPLE_DEVELOPER_PASSWORD = "***"
APPLE_APP_SPECIFIC_PASSWORD = "***"

# Firebase (if using)
FIREBASE_PROJECT_ID = "rupaya-prod"
FIREBASE_API_KEY = "***"
```

---

## Conventional Commits Format

Use this format for all commits:

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types:
- `feat` - A new feature
- `fix` - A bug fix
- `docs` - Documentation changes
- `style` - Code style changes (formatting, etc)
- `refactor` - Code refactoring
- `perf` - Performance improvements
- `test` - Test-related changes
- `chore` - Build process, dependencies, etc

### Examples:

```
feat(auth): add biometric login support
- Implement FaceID/TouchID on iOS
- Implement biometric on Android
- Update API to support biometric tokens

fix(transactions): prevent duplicate entries on retry
- Add idempotency key to transaction creation
- Handle network timeout gracefully

docs: update deployment guide for AWS

refactor(api): extract common validation logic

perf(db): add index on transactions.user_id

test(auth): add unit tests for login service
```

---

## Summary: GitHub Workflow

```
Developer creates feature branch
    ↓
Developer commits with conventional format
    ↓
Developer pushes and creates PR
    ↓
CI/CD runs: lint, test, build, coverage
    ↓
Code reviewers review (need 1-2 approvals)
    ↓
Developer addresses feedback (if any)
    ↓
Maintainer merges PR
    ↓
Branch deleted automatically
    ↓
On merge to main: CI/CD deploys to production
```

---

## Useful GitHub CLI Commands

```bash
# List open PRs
gh pr list --state open

# Create PR from current branch
gh pr create --title "My feature" --body "Description"

# Review PR
gh pr review <number> --approve
gh pr review <number> --comment -b "Looks good but..."

# Merge PR (from main branch)
gh pr merge <number> --squash --delete-branch

# View PR details
gh pr view <number>

# Comment on issue
gh issue comment <number> -b "My comment"
```

---

This GitHub setup ensures:
✅ All code is tested before merge
✅ All PRs are reviewed by team
✅ Automatic deployment on main branch
✅ Clear commit history with conventional format
✅ Slack notifications for critical events
✅ Code coverage tracking
✅ Team ownership and code reviews

Let your tech lead set this up initially, then you can focus on coding! 🚀
