# RUPAYA Monorepo - Complete GitHub Structure & Strategy

## Repository Layout

```
rupaya/
│
├── README.md                          # Main project overview
├── .gitignore                         # Git ignore rules
├── .github/
│   ├── workflows/
│   │   ├── backend-tests.yml          # Backend CI/CD
│   │   ├── 11-common-mobile-build.yml  # Mobile build checks
│   │   └── deploy.yml                 # Production deployment
│   └── CODEOWNERS                     # Team ownership per folder
│
├── docs/
│   ├── ARCHITECTURE.md                # System design
│   ├── API_DOCUMENTATION.md           # Complete API reference
│   ├── DEPLOYMENT.md                  # AWS deployment guide
│   ├── SECURITY.md                    # Security best practices
│   ├── CONTRIBUTING.md                # Contribution guidelines
│   ├── ONBOARDING.md                  # Team onboarding
│   └── RUNBOOKS/                      # Production runbooks
│       ├── incident-response.md
│       ├── database-recovery.md
│       └── scaling-guide.md
│
├── shared/                            # Shared across all platforms
│   ├── models/
│   │   ├── user.ts                    # Shared TypeScript models
│   │   ├── transaction.ts
│   │   ├── account.ts
│   │   └── api-types.ts               # Common API request/response types
│   │
│   ├── constants/
│   │   ├── api-endpoints.ts           # All API endpoints
│   │   ├── error-codes.ts             # Standardized error codes
│   │   └── config.ts                  # Shared config values
│   │
│   ├── utils/
│   │   ├── date-utils.ts
│   │   ├── number-utils.ts
│   │   ├── validation.ts              # Email, password, etc validation
│   │   └── encryption.ts              # Encryption utilities
│   │
│   └── README.md                      # How to use shared libs
│
├── backend/                           # Node.js + Express API
│   ├── src/
│   │   ├── app.js                     # Express app
│   │   ├── server.js                  # Server entry point
│   │   │
│   │   ├── config/
│   │   │   ├── database.js
│   │   │   ├── redis.js
│   │   │   └── aws.js
│   │   │
│   │   ├── controllers/               # HTTP request handlers
│   │   │   ├── auth.js
│   │   │   ├── transactions.js
│   │   │   ├── accounts.js
│   │   │   ├── analytics.js
│   │   │   └── categories.js
│   │   │
│   │   ├── services/                  # Business logic
│   │   │   ├── AuthService.js
│   │   │   ├── TransactionService.js
│   │   │   ├── AnalyticsService.js
│   │   │   ├── AccountService.js
│   │   │   └── NotificationService.js
│   │   │
│   │   ├── models/                    # Data models
│   │   │   ├── User.js
│   │   │   ├── Transaction.js
│   │   │   ├── Account.js
│   │   │   └── Category.js
│   │   │
│   │   ├── middleware/
│   │   │   ├── auth.js                # JWT verification
│   │   │   ├── validation.js          # Input validation
│   │   │   ├── errorHandler.js
│   │   │   └── securityHeaders.js     # Helmet, CORS, etc
│   │   │
│   │   ├── routes/
│   │   │   ├── auth.js
│   │   │   ├── transactions.js
│   │   │   ├── accounts.js
│   │   │   ├── analytics.js
│   │   │   └── categories.js
│   │   │
│   │   ├── utils/
│   │   │   ├── logger.js              # Winston logging
│   │   │   ├── errors.js              # Custom error classes
│   │   │   ├── validators.js          # Validation helpers
│   │   │   └── jwt.js                 # Token management
│   │   │
│   │   └── jobs/                      # Background jobs
│   │       ├── emailQueue.js
│   │       ├── analyticsAggregator.js
│   │       └── backupScheduler.js
│   │
│   ├── migrations/                    # Database migrations
│   │   ├── 001_init.sql
│   │   ├── 002_add_mfa.sql
│   │   └── 003_add_audit_logs.sql
│   │
│   ├── seeds/                         # Database seed data
│   │   ├── categories.js
│   │   └── demo-users.js
│   │
│   ├── __tests__/                     # Test files (mirror src/)
│   │   ├── unit/
│   │   │   ├── services/
│   │   │   │   ├── AuthService.test.js
│   │   │   │   └── TransactionService.test.js
│   │   │   └── utils/
│   │   │       └── validators.test.js
│   │   │
│   │   ├── integration/
│   │   │   ├── auth.test.js
│   │   │   ├── transactions.test.js
│   │   │   └── analytics.test.js
│   │   │
│   │   └── fixtures/
│   │       ├── users.json
│   │       └── transactions.json
│   │
│   ├── .env.example
│   ├── .env.local                     # Local dev (don't commit)
│   ├── .env.test
│   ├── .env.production
│   │
│   ├── Dockerfile
│   ├── docker-compose.yml
│   ├── package.json
│   ├── package-lock.json
│   ├── jest.config.js
│   ├── .eslintrc.js
│   ├── .prettierrc
│   │
│   └── README.md                      # Backend-specific setup
│
├── ios/                               # Swift/SwiftUI iOS app
│   ├── RUPAYA/
│   │   ├── App/
│   │   │   ├── RUPAYAApp.swift        # App entry point
│   │   │   └── AppDelegate.swift
│   │   │
│   │   ├── Features/                  # Feature modules
│   │   │   ├── Authentication/
│   │   │   │   ├── Views/
│   │   │   │   │   ├── LoginView.swift
│   │   │   │   │   ├── SignupView.swift
│   │   │   │   │   └── MFAView.swift
│   │   │   │   ├── ViewModels/
│   │   │   │   │   └── AuthViewModel.swift
│   │   │   │   └── Models/
│   │   │   │       ├── LoginRequest.swift
│   │   │   │       └── AuthResponse.swift
│   │   │   │
│   │   │   ├── Dashboard/
│   │   │   │   ├── Views/
│   │   │   │   │   ├── DashboardView.swift
│   │   │   │   │   ├── AccountCard.swift
│   │   │   │   │   └── TransactionList.swift
│   │   │   │   └── ViewModels/
│   │   │   │       └── DashboardViewModel.swift
│   │   │   │
│   │   │   ├── Transactions/
│   │   │   │   ├── Views/
│   │   │   │   │   ├── TransactionDetailView.swift
│   │   │   │   │   └── AddTransactionView.swift
│   │   │   │   └── ViewModels/
│   │   │   │       └── TransactionViewModel.swift
│   │   │   │
│   │   │   └── Settings/
│   │   │       ├── Views/
│   │   │       │   ├── SettingsView.swift
│   │   │       │   └── MFASetupView.swift
│   │   │       └── ViewModels/
│   │   │           └── SettingsViewModel.swift
│   │   │
│   │   ├── Core/
│   │   │   ├── Networking/
│   │   │   │   ├── APIClient.swift    # Main API client
│   │   │   │   ├── Endpoints.swift    # API endpoints
│   │   │   │   └── NetworkError.swift
│   │   │   │
│   │   │   ├── Security/
│   │   │   │   ├── KeychainManager.swift
│   │   │   │   ├── BiometricManager.swift
│   │   │   │   └── CertificatePinning.swift
│   │   │   │
│   │   │   ├── Storage/
│   │   │   │   └── UserDefaults+Extensions.swift
│   │   │   │
│   │   │   └── Logging/
│   │   │       └── Logger.swift
│   │   │
│   │   ├── Models/                    # Data models
│   │   │   ├── User.swift
│   │   │   ├── Transaction.swift
│   │   │   ├── Account.swift
│   │   │   └── Budget.swift
│   │   │
│   │   ├── Resources/
│   │   │   ├── Assets.xcassets/
│   │   │   ├── Localizable.strings    # Localization
│   │   │   ├── Colors.xcassets/
│   │   │   └── Fonts/
│   │   │
│   │   ├── Modifiers/                 # Custom SwiftUI modifiers
│   │   │   ├── ButtonModifiers.swift
│   │   │   └── TextModifiers.swift
│   │   │
│   │   └── Utils/
│   │       ├── DateFormatter+Extensions.swift
│   │       ├── NumberFormatter+Extensions.swift
│   │       └── View+Extensions.swift
│   │
│   ├── RUPAYATests/
│   │   ├── AuthViewModelTests.swift
│   │   ├── APIClientTests.swift
│   │   └── KeychainManagerTests.swift
│   │
│   ├── RUPAYA.xcodeproj/
│   ├── Podfile
│   ├── Podfile.lock
│   │
│   └── README.md                      # iOS-specific setup
│
├── android/                           # Kotlin/Jetpack Compose Android app
│   ├── app/
│   │   ├── src/
│   │   │   ├── main/
│   │   │   │   ├── kotlin/com/rupaya/
│   │   │   │   │   ├── MainActivity.kt
│   │   │   │   │   │
│   │   │   │   │   ├── features/
│   │   │   │   │   │   ├── authentication/
│   │   │   │   │   │   │   ├── presentation/
│   │   │   │   │   │   │   │   ├── screens/
│   │   │   │   │   │   │   │   │   ├── LoginScreen.kt
│   │   │   │   │   │   │   │   │   ├── SignupScreen.kt
│   │   │   │   │   │   │   │   │   └── MFAScreen.kt
│   │   │   │   │   │   │   │   └── viewmodels/
│   │   │   │   │   │   │   │       └── AuthViewModel.kt
│   │   │   │   │   │   │   │
│   │   │   │   │   │   │   ├── data/
│   │   │   │   │   │   │   │   ├── api/
│   │   │   │   │   │   │   │   │   └── AuthApi.kt
│   │   │   │   │   │   │   │   ├── repository/
│   │   │   │   │   │   │   │   │   └── AuthRepository.kt
│   │   │   │   │   │   │   │   └── models/
│   │   │   │   │   │   │   │       ├── LoginRequest.kt
│   │   │   │   │   │   │   │       └── AuthResponse.kt
│   │   │   │   │   │   │   │
│   │   │   │   │   │   │   └── domain/
│   │   │   │   │   │   │       ├── usecase/
│   │   │   │   │   │   │       │   ├── LoginUseCase.kt
│   │   │   │   │   │   │       │   └── SignupUseCase.kt
│   │   │   │   │   │   │       └── model/
│   │   │   │   │   │   │           └── User.kt
│   │   │   │   │   │   │
│   │   │   │   │   │   ├── dashboard/
│   │   │   │   │   │   │   ├── presentation/
│   │   │   │   │   │   │   │   ├── screens/
│   │   │   │   │   │   │   │   │   └── DashboardScreen.kt
│   │   │   │   │   │   │   │   └── viewmodels/
│   │   │   │   │   │   │   │       └── DashboardViewModel.kt
│   │   │   │   │   │   │   │
│   │   │   │   │   │   │   ├── data/
│   │   │   │   │   │   │   │   └── repository/
│   │   │   │   │   │   │   │       └── DashboardRepository.kt
│   │   │   │   │   │   │   │
│   │   │   │   │   │   │   └── domain/
│   │   │   │   │   │   │       └── usecase/
│   │   │   │   │   │   │           └── GetDashboardUseCase.kt
│   │   │   │   │   │   │
│   │   │   │   │   │   ├── transactions/
│   │   │   │   │   │   │   ├── presentation/
│   │   │   │   │   │   │   ├── data/
│   │   │   │   │   │   │   └── domain/
│   │   │   │   │   │   │
│   │   │   │   │   │   └── settings/
│   │   │   │   │   │       ├── presentation/
│   │   │   │   │   │       ├── data/
│   │   │   │   │   │       └── domain/
│   │   │   │   │   │
│   │   │   │   │   ├── core/
│   │   │   │   │   │   ├── network/
│   │   │   │   │   │   │   ├── ApiClient.kt
│   │   │   │   │   │   │   ├── SecurityInterceptor.kt
│   │   │   │   │   │   │   └── RetryPolicy.kt
│   │   │   │   │   │   │
│   │   │   │   │   │   ├── security/
│   │   │   │   │   │   │   ├── SecureStorage.kt
│   │   │   │   │   │   │   ├── BiometricAuthManager.kt
│   │   │   │   │   │   │   └── CertificatePinning.kt
│   │   │   │   │   │   │
│   │   │   │   │   │   ├── di/
│   │   │   │   │   │   │   ├── NetworkModule.kt
│   │   │   │   │   │   │   ├── RepositoryModule.kt
│   │   │   │   │   │   │   └── UseCaseModule.kt
│   │   │   │   │   │   │
│   │   │   │   │   │   └── logging/
│   │   │   │   │   │       └── Logger.kt
│   │   │   │   │   │
│   │   │   │   │   ├── ui/
│   │   │   │   │   │   ├── theme/
│   │   │   │   │   │   │   ├── Color.kt
│   │   │   │   │   │   │   ├── Typography.kt
│   │   │   │   │   │   │   └── Theme.kt
│   │   │   │   │   │   │
│   │   │   │   │   │   └── components/
│   │   │   │   │   │       ├── Button.kt
│   │   │   │   │   │       ├── TextField.kt
│   │   │   │   │   │       └── Card.kt
│   │   │   │   │   │
│   │   │   │   │   └── RupayaApplication.kt
│   │   │   │   │
│   │   │   │   └── res/
│   │   │   │       ├── values/
│   │   │   │       │   ├── strings.xml
│   │   │   │       │   ├── colors.xml
│   │   │   │       │   └── dimens.xml
│   │   │   │       ├── drawable/
│   │   │   │       └── mipmap/
│   │   │   │
│   │   │   ├── test/
│   │   │   │   └── kotlin/com/rupaya/
│   │   │   │       ├── AuthViewModelTest.kt
│   │   │   │       └── ApiClientTest.kt
│   │   │   │
│   │   │   └── androidTest/
│   │   │       └── kotlin/com/rupaya/
│   │   │           └── AuthScreenTest.kt
│   │   │
│   │   ├── build.gradle.kts
│   │   └── proguard-rules.pro
│   │
│   ├── build.gradle.kts
│   ├── settings.gradle.kts
│   └── local.properties            # Local build config (don't commit)
│
└── deployment/                        # Infrastructure & DevOps
    ├── terraform/
    │   ├── main.tf                    # Main infrastructure
    │   ├── rds.tf                     # Database
    │   ├── elasticache.tf             # Redis
    │   ├── s3.tf                      # S3 buckets
    │   ├── ecr.tf                     # Docker registry
    │   ├── ecs.tf                     # Container orchestration
    │   ├── variables.tf               # Terraform variables
    │   ├── outputs.tf                 # Outputs
    │   └── terraform.tfvars.example
    │
    ├── docker/
    │   ├── Dockerfile.backend         # Backend image
    │   └── docker-compose.yml         # Local dev compose
    │
    ├── kubernetes/                    # K8s configs (if scaling)
    │   ├── backend-deployment.yaml
    │   ├── backend-service.yaml
    │   └── configmap.yaml
    │
    ├── scripts/
    │   ├── deploy.sh                  # Deployment script
    │   ├── setup-aws.sh               # AWS setup
    │   ├── backup.sh                  # Database backup
    │   └── health-check.sh            # Health checks
    │
    └── monitoring/
        ├── cloudwatch-alarms.yaml     # CloudWatch config
        └── prometheus-rules.yaml      # Prometheus rules
```

---

## Branch Strategy (Git Flow)

```
main (production)
  ↑
  └─ merge PR from release/
  
release/* (staging)
  ↑
  └─ merge PR from develop

develop (development)
  ↑
  ├─ feature/auth-2fa
  ├─ feature/transaction-filters
  ├─ feature/analytics-dashboard
  ├─ bugfix/login-crash
  └─ chore/update-dependencies
```

### Branch naming conventions:
- `feature/*` - New features (feature/transaction-export)
- `bugfix/*` - Bug fixes (bugfix/login-crash)
- `hotfix/*` - Emergency production fixes (hotfix/payment-bug)
- `chore/*` - Maintenance tasks (chore/update-deps)
- `docs/*` - Documentation (docs/api-guide)

---

## Pull Request (PR) Process

### Before submitting PR:
```bash
# Backend
cd backend
npm run lint
npm run test
npm run test:coverage

# iOS
cd ios
# Run tests in Xcode or: xcodebuild test

# Android
cd android
./gradlew lint
./gradlew test
```

### PR template (.github/pull_request_template.md):
```markdown
## Description
What does this PR do?

## Type of Change
- [ ] Backend (API, database, services)
- [ ] iOS app
- [ ] Android app
- [ ] Infrastructure
- [ ] Documentation

## Testing
How was this tested?

## Checklist
- [ ] Code follows style guide
- [ ] Tests written/updated
- [ ] Documentation updated
- [ ] No breaking changes
```

---

## CI/CD Workflows

### Backend Tests (.github/workflows/backend-tests.yml)
```yaml
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres: ...
      redis: ...
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
      - run: cd backend && npm install
      - run: cd backend && npm run lint
      - run: cd backend && npm test
      - run: cd backend && npm run test:coverage
      - uses: codecov/codecov-action@v3
```

### Mobile Build Check (.github/workflows/11-common-mobile-build.yml)
```yaml
on: [push, pull_request]
jobs:
  ios:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build iOS
        run: cd ios && pod install && xcodebuild build
  
  android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-java@v3
      - run: cd android && ./gradlew build lint
```

### Production Deploy (.github/workflows/deploy.yml)
```yaml
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Test
        run: cd backend && npm test
      - name: Build Docker image
        run: docker build -t rupaya:${{ github.sha }} ./backend
      - name: Push to ECR
        run: aws ecr push ...
      - name: Deploy to ECS
        run: aws ecs update-service ...
```

---

## CODEOWNERS (.github/CODEOWNERS)

```
# Backend
/backend/ @backend-team

# iOS
/ios/ @ios-team

# Android
/android/ @android-team

# Infrastructure
/deployment/ @devops-team

# Shared
/shared/ @all

# Docs
/docs/ @tech-lead
```

---

## Local Development Workflow

### Day 1: Setup
```bash
git clone https://github.com/yourname/rupaya.git
cd rupaya

# Copy env files
cp backend/.env.example backend/.env.local
cp android/local.properties.example android/local.properties

# Start all services
docker-compose -f backend/docker-compose.yml up -d

# Backend setup
cd backend
npm install
npm run migrate
npm run dev  # Runs on :3000

# iOS setup
cd ../ios
pod install
open RUPAYA.xcworkspace

# Android setup (in Android Studio)
cd ../android
# Open in Android Studio and build
```

### Day 2: Feature work
```bash
# Create feature branch
git checkout -b feature/my-feature

# Make changes, commit, push
git add .
git commit -m "feat: add my-feature"
git push origin feature/my-feature

# Create PR on GitHub
# Once merged to develop, test on staging
```

### Day 3: Testing before production
```bash
# Merge develop → release/v1.0.0 → main
git checkout main
git merge release/v1.0.0
git tag v1.0.0
git push --tags

# CI/CD deploys automatically
# Check CloudWatch dashboards
```

---

## File Organization Best Practices

### Backend: Feature-based + Clean Architecture
Each feature (auth, transactions) has:
- `/controllers` - HTTP handlers
- `/services` - Business logic
- `/models` - Data models
- `/routes` - Endpoints

### iOS: Feature-based + MVVM
Each feature has:
- `/Views` - SwiftUI screens
- `/ViewModels` - State & logic
- `/Models` - Data models

### Android: Clean Architecture + MVVM
Each feature has three layers:
- `presentation/` - UI (Jetpack Compose)
- `data/` - Repository & API calls
- `domain/` - Business logic (UseCases)

---

## Shared Code Usage

### Adding to shared/ (TypeScript types)

**shared/models/transaction.ts:**
```typescript
export interface Transaction {
  id: string;
  accountId: string;
  amount: number;
  currency: string;
  type: 'income' | 'expense';
  categoryId: string;
  description: string;
  date: string;
}
```

**Backend uses it:**
```javascript
// backend/src/models/Transaction.js
// Manual translation OR auto-generate from TS
const transactionSchema = {
  id: { type: String, required: true },
  accountId: { type: String, required: true },
  amount: { type: Number, required: true },
  // ...
};
```

**iOS imports it:**
```swift
// iOS/RUPAYA/Models/Transaction.swift
struct Transaction: Codable {
  let id: String
  let accountId: String
  let amount: Double
  // ...
}
```

**Android imports it:**
```kotlin
// android/.../models/Transaction.kt
data class Transaction(
  val id: String,
  val accountId: String,
  val amount: Double,
  // ...
)
```

---

## Dependency Management

### Backend (npm)
```json
{
  "dependencies": { ... },
  "devDependencies": { ... },
  "engines": { "node": ">=18.0.0" }
}
```

### iOS (CocoaPods)
```ruby
platform :ios, '14.0'

target 'RUPAYA' do
  pod 'Alamofire'
  pod 'SwiftKeychainWrapper'
  # ...
end
```

### Android (Gradle)
```kotlin
dependencies {
  implementation 'com.google.code.gson:gson:2.10.1'
  implementation 'com.squareup.retrofit2:retrofit:2.9.0'
  // ...
}
```

---

## Documentation Structure

- **README.md** - Project overview & links
- **docs/ARCHITECTURE.md** - System design
- **docs/API_DOCUMENTATION.md** - API reference
- **docs/DEPLOYMENT.md** - Deploy guide
- **docs/SECURITY.md** - Security practices
- **docs/CONTRIBUTING.md** - How to contribute
- **backend/README.md** - Backend setup
- **ios/README.md** - iOS setup
- **android/README.md** - Android setup

---

## Monitoring & Alerts

### What to track:
- **Backend**: API response time, error rate, DB performance
- **Mobile**: Crash rates, ANR (Android), hang time (iOS)
- **Infrastructure**: CPU, memory, database connections
- **Business**: Transaction volume, user signups

### Tools:
- **CloudWatch**: AWS native monitoring
- **Sentry**: Error tracking (optional)
- **DataDog**: APM (optional)

---

## Secrets Management

### Local development (.env.local files):
```bash
# backend/.env.local (don't commit)
DB_PASSWORD=dev_password
JWT_SECRET=dev_secret
```

### CI/CD (GitHub Secrets):
Settings → Secrets and variables → Actions
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `DATABASE_PASSWORD`
- `JWT_SECRET`

### Production (AWS Secrets Manager):
Terraform manages secret rotation and access.

---

## Team Roles & Responsibilities

### CODEOWNERS enforcement:
```
/backend/        → @backend-team (approval required)
/ios/            → @ios-team (approval required)
/android/        → @android-team (approval required)
/deployment/     → @devops-team (approval required)
```

### Code review expectations:
- **Backend changes**: 2 approvals before merge
- **Mobile changes**: 1 iOS/Android team approval
- **Infrastructure**: DevOps team + tech lead approval

---

This structure scales well for:
- ✅ Solo developer → full monorepo control
- ✅ Small team (5-10) → clear ownership boundaries
- ✅ Growing team → can split into separate repos later if needed
- ✅ Multiple products → duplicate folder structure for each product

Would you like me to create:
1. Actual GitHub workflow YAML files?
2. Detailed contribution guidelines?
3. PR template & issue templates?
4. Team onboarding documentation?
