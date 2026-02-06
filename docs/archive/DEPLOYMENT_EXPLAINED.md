# RUPAYA - Deployment Architecture: What Goes Where

## Visual Deployment Map

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         RUPAYA MONOREPO (GitHub)                             │
│                                                                               │
│  ┌─────────────┐  ┌─────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │  backend/   │  │    ios/     │  │   android/   │  │  deployment/    │  │
│  │ (Node.js)   │  │  (SwiftUI)  │  │   (Kotlin)   │  │  (Terraform)    │  │
│  └──────┬──────┘  └──────┬──────┘  └──────┬───────┘  └────────┬─────────┘  │
│         │                │                │                   │             │
└─────────┼────────────────┼────────────────┼───────────────────┼─────────────┘
          │                │                │                   │
          │ (CI/CD)        │ (CI/CD)        │ (CI/CD)           │ (CI/CD)
          │ npm test       │ xcodebuild     │ ./gradlew test    │ terraform
          │ npm run dev    │ build          │ build             │ plan/apply
          │                │                │                   │
    ┌─────▼──────────┐   ┌─▼────────────┐ ┌─▼────────────┐ ┌──▼─────────────┐
    │                │   │              │ │              │ │                │
    │ AWS ECS        │   │  App Store   │ │  Play Store  │ │ AWS Services   │
    │ + Load Balancer│   │              │ │              │ │ (RDS, Redis)   │
    │ :443 / :80     │   │ (TestFlight) │ │ (Internal)   │ │                │
    │                │   │              │ │              │ │                │
    └────────────────┘   └──────────────┘ └──────────────┘ └────────────────┘
          ▲
          │
    ┌─────┴─────────────────────────────────────────┐
    │                                               │
    │  iOS & Android apps point to:                │
    │  APIClient.baseURL = "https://api.rupaya.in" │
    │                                               │
    └───────────────────────────────────────────────┘
```

---

## Component Deployment Summary

### 1. Backend (deployed to AWS)

**What:** Node.js + Express API + Database + Cache  
**Where:** AWS (ECS, RDS, ElastiCache)  
**How:** 
- GitHub push to `main` → CI/CD tests → Docker build → ECR push → ECS deploy
- Uses: `deployment/terraform/`

**Components deployed:**
```
AWS Region (ap-south-1)
├── ECS Cluster
│   └── Backend Service
│       └── Task (Docker image from ECR)
│           └── Node.js app (port 3000)
│
├── RDS (PostgreSQL)
│   └── rupaya_production database
│
├── ElastiCache (Redis)
│   └── rupaya-cache
│
├── Application Load Balancer
│   ├── HTTPS (443) → ECS backend
│   └── Custom domain: api.rupaya.in
│
├── S3 bucket (backups)
└── CloudWatch (monitoring)
```

**CI/CD triggers:**
```yaml
# .github/workflows/deploy.yml
on:
  push:
    branches: [main]

jobs:
  test:
    # Run backend tests
  build:
    # Build Docker image
  push:
    # Push to ECR
  deploy:
    # Update ECS service
```

---

### 2. iOS App (deployed to App Store)

**What:** SwiftUI app + networking layer  
**Where:** App Store / TestFlight (Apple's servers)  
**How:**
- Xcode build → App Store Connect → TestFlight/Production
- Does NOT deploy backend code
- Talks to backend via API at `https://api.rupaya.in`

**Components deployed:**
```
App Store (Apple)
├── RUPAYA app binary (IPA)
│   ├── SwiftUI screens
│   ├── APIClient pointing to api.rupaya.in
│   ├── Keychain secrets
│   ├── Biometric auth
│   └── Local storage
│
└── TestFlight
    └── Beta builds for testing
```

**Build process:**
```
1. Developer:
   cd ios
   pod install
   xcodebuild build -scheme RUPAYA

2. Submit to App Store:
   - Increment version in Xcode
   - Build for release
   - Archive in Xcode
   - Validate with App Store
   - Submit for review

3. App Store Review (24-48 hours)

4. Users download from App Store
   - Users: iPhone device
   - Users make API calls to api.rupaya.in
   - Users see responses from backend
```

---

### 3. Android App (deployed to Play Store)

**What:** Jetpack Compose app + networking layer  
**Where:** Play Store (Google's servers)  
**How:**
- Gradle build → signed APK/AAB → Play Store Console → Production
- Does NOT deploy backend code
- Talks to backend via API at `https://api.rupaya.in`

**Components deployed:**
```
Play Store (Google)
├── RUPAYA app bundle (AAB)
│   ├── Jetpack Compose screens
│   ├── ApiClient pointing to api.rupaya.in
│   ├── EncryptedSharedPreferences
│   ├── Biometric auth
│   └── Local storage
│
└── Internal testing track
    └── Beta builds for team testing
```

**Build process:**
```
1. Developer:
   cd android
   ./gradlew build
   ./gradlew bundleRelease

2. Sign APK/AAB:
   ./gradlew bundleRelease -x build \
     -Pandroid.injected.signing.store.file=keystore.jks \
     -Pandroid.injected.signing.store.password=... \
     -Pandroid.injected.signing.key.alias=... \
     -Pandroid.injected.signing.key.password=...

3. Upload to Play Store:
   - Open Play Store Console
   - Upload AAB
   - Set version, release notes
   - Roll out to internal testing first

4. Users download from Play Store
   - Users: Android device
   - Users make API calls to api.rupaya.in
   - Users see responses from backend
```

---

### 4. Web (optional - deployed to AWS/Amplify)

**What:** React/Next.js frontend + networking  
**Where:** AWS S3 + CloudFront OR Amplify  
**How:**
- GitHub push → CI/CD builds Next.js → Deploy to S3 → CloudFront serves
- Talks to same backend at `https://api.rupaya.in`

**If you build web:**
```
AWS
├── S3 bucket
│   └── Built Next.js files (HTML/JS/CSS)
│
├── CloudFront
│   ├── HTTPS (443)
│   └── Custom domain: rupaya.com
│
└── Route 53 (DNS)
```

---

## File Matrix: What Gets Deployed Where?

| Folder | Backend Deployment | iOS Deployment | Android Deployment | Web Deployment |
|--------|:------------------:|:--------------:|:------------------:|:--------------:|
| `backend/` | ✅ (Docker→ECS) | ❌ | ❌ | ❌ |
| `ios/` | ❌ | ✅ (App Store) | ❌ | ❌ |
| `android/` | ❌ | ❌ | ✅ (Play Store) | ❌ |
| `web/` (if exists) | ❌ | ❌ | ❌ | ✅ (S3+CF) |
| `shared/` | ✅ (as code) | ✅ (copied) | ✅ (copied) | ✅ (copied) |
| `docs/` | ❌ | ❌ | ❌ | ✅ (GitHub Pages) |
| `deployment/` | ✅ (Terraform) | ❌ | ❌ | ✅ (if web) |

---

## Real Example: Complete Release

### Timeline: Rolling out v1.2.0

```
Week 1 (Development)
├─ Feature branches: feature/new-dashboard, feature/export-transactions
├─ PRs to develop branch, code reviews
└─ Merge to develop when approved

End of Week 1 (Release Prep)
├─ Backend:
│  ├─ Bump version in package.json (1.2.0)
│  ├─ Update CHANGELOG.md
│  └─ Create release notes
├─ iOS:
│  ├─ Bump version in Xcode (1.2.0)
│  ├─ Update app screenshots (if needed)
│  └─ Test on TestFlight
└─ Android:
   ├─ Bump version in build.gradle.kts (1.2.0)
   ├─ Update Google Play screenshots
   └─ Test on internal testing track

Friday (Release)
├─ Create release/v1.2.0 branch from develop
├─ Create PR: release/v1.2.0 → main
├─ Code review, merge to main
├─ Tag: v1.2.0
└─ CI/CD triggers:

  ┌─ Backend release ───────────────────────────┐
  │ 1. Run tests (npm test)                     │
  │ 2. Build Docker: rupaya:v1.2.0              │
  │ 3. Push to ECR                              │
  │ 4. Update ECS task definition               │
  │ 5. Deploy to ECS                            │
  │ 6. Monitor CloudWatch                       │
  │ ✓ Live in 5 minutes                         │
  └─────────────────────────────────────────────┘

Saturday (App Releases)
├─ iOS release:
│  │ 1. Xcode: Product → Archive
│  │ 2. Validate & submit to App Store
│  │ 3. App Review (24-48 hours)
│  │ 4. Release to all users
│  └─ Live when Apple approves
│
└─ Android release:
   │ 1. ./gradlew bundleRelease
   │ 2. Sign with production keystore
   │ 3. Upload to Play Store Console
   │ 4. Roll out to internal → 25% → 50% → 100%
   │ 5. Monitor crash rates
   └─ Live within 4 hours (rolled out)

Sunday (Verification)
├─ Check backend metrics (CloudWatch)
├─ Monitor iOS reviews/ratings
├─ Monitor Android reviews/ratings
├─ Check Sentry for errors
└─ If issue found: hotfix/v1.2.1 → main
```

---

## Environment Separation

### Backend (All environments point to different DBs)

```
Production (main branch)
├─ api.rupaya.in
├─ PostgreSQL: rupaya_production
├─ Redis: rupaya-prod-cache
└─ CloudWatch: rupaya-prod

Staging (release/* branch)
├─ api-staging.rupaya.in
├─ PostgreSQL: rupaya_staging
├─ Redis: rupaya-staging-cache
└─ CloudWatch: rupaya-staging

Development (develop branch)
├─ api-dev.rupaya.in
├─ PostgreSQL: rupaya_dev
├─ Redis: rupaya-dev-cache
└─ CloudWatch: rupaya-dev
```

### Mobile Apps (All point to same API, but can switch)

```
iOS:
├─ Production: api.rupaya.in
├─ Staging: api-staging.rupaya.in (via settings)
└─ Local dev: http://localhost:3000 (hardcoded for testing)

Android:
├─ Production: api.rupaya.in
├─ Staging: api-staging.rupaya.in (via settings)
└─ Local dev: http://10.0.2.2:3000 (emulator)
```

---

## Quick Deployment Checklist

### Before Deploy:
- [ ] All tests pass locally: `npm test`, `xcodebuild test`, `./gradlew test`
- [ ] Code review approved
- [ ] No open TODOs in critical files
- [ ] Security scan passed (OWASP, dependency check)
- [ ] Database migrations tested
- [ ] Environment variables configured

### Backend Deploy:
- [ ] Merge to main branch
- [ ] Wait for CI/CD to complete (~5 min)
- [ ] Verify ECS deployment healthy
- [ ] Check CloudWatch metrics
- [ ] Test critical endpoints: health, auth, transactions

### iOS Deploy:
- [ ] Build in Xcode succeeds
- [ ] TestFlight build uploads
- [ ] Internal testers approve
- [ ] Submit to App Store
- [ ] Wait for App Review (24-48 hrs)
- [ ] Release to all users

### Android Deploy:
- [ ] Build with gradlew succeeds
- [ ] APK/AAB signs correctly
- [ ] Upload to Play Store
- [ ] Roll out: internal → 25% → 50% → 100%
- [ ] Monitor crash rates

### Post-Deploy:
- [ ] Monitor error rates (should be <0.1%)
- [ ] Check user reviews
- [ ] Monitor performance metrics
- [ ] Have rollback plan ready
- [ ] Document deployment in runbooks

---

## Rollback Procedures

### Backend Rollback (if critical issue)
```bash
# AWS ECS
aws ecs update-service \
  --cluster rupaya-cluster \
  --service rupaya-service \
  --task-definition rupaya:v1.1.0  # Previous version
```

### iOS Rollback (Apple App Store)
```
1. Open App Store Connect
2. Version Release
3. Click "Remove from Sale" or "Hold from Release"
4. Previous version auto-available to users
```

### Android Rollback (Google Play)
```
1. Open Play Store Console
2. Release → Manage releases
3. Reduce rollout percentage to 0%
4. Previous version auto-available to users
```

---

## Monitoring & Alerts

### What's monitored post-deploy:

**Backend (CloudWatch):**
- API error rate (threshold: >1%)
- Response time (threshold: >500ms)
- Database connections (threshold: >80%)
- Cache hit ratio (target: >80%)

**Mobile (via app analytics):**
- Crash rate (threshold: >0.5%)
- ANR / hang time (threshold: any increase)
- User sessions (track for uptick in issues)

**Alerts trigger:**
- Slack notification to #rupaya-alerts
- PagerDuty on-call (if critical)
- Automatic rollback (if configured)

---

## Summary: Deploy vs Don't Deploy

| Component | Deploy? | Where | How Often |
|-----------|---------|-------|-----------|
| Backend Node.js code | ✅ | AWS ECS | Every push to main |
| Backend database | ✅ (migrations) | AWS RDS | Before code deploy |
| Backend config | ✅ | AWS Secrets Manager | On change |
| iOS app | ✅ | App Store | Weekly/monthly |
| iOS config (API URL) | ❌ | Built in binary | Change = new build |
| Android app | ✅ | Play Store | Weekly/monthly |
| Android config (API URL) | ❌ | Built in binary | Change = new build |
| Web frontend | ✅ (optional) | S3 + CloudFront | Every push |
| Docs | ✅ | GitHub Pages | On docs push |

---

This is the typical **one backend, two mobile apps** deployment model used by Netflix, Amazon, Zerodha, and others. 🚀
