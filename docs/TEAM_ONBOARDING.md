# RUPAYA Team Onboarding Guide

Welcome to the RUPAYA Money Manager project! This guide will get you productive in the first day and fully integrated in the first week.

---

## Table of Contents

1. [Day 1: Setup & Environment](#day-1-setup--environment)
2. [Day 2: Understanding the Codebase](#day-2-understanding-the-codebase)
3. [Day 3: Making Your First Contribution](#day-3-making-your-first-contribution)
4. [Week 2: Deep Dives by Role](#week-2-deep-dives-by-role)
5. [Quick Reference](#quick-reference)

---

## Day 1: Setup & Environment

### Step 1: Access & Permissions (10 minutes)

**Request from tech lead:**
- [ ] GitHub access to `rupaya` repository
- [ ] AWS account access (if backend team)
- [ ] Apple Developer account access (if iOS team)
- [ ] Google Play Console access (if Android team)
- [ ] Slack channels: #rupaya-general, #rupaya-backend, #rupaya-ios, #rupaya-android
- [ ] 1Password or LastPass for secrets
- [ ] Jira/Linear for task tracking

**Verify you have:**
```bash
# GitHub
git config --global user.name "Your Name"
git config --global user.email "your.email@company.com"
git config --list

# AWS CLI (if backend)
aws configure
aws sts get-caller-identity  # Should show your account

# Xcode (if iOS)
xcode-select --install

# Android SDK (if Android)
echo $ANDROID_HOME  # Should be set
```

### Step 2: Clone Repository (5 minutes)

```bash
# Clone the repo
git clone https://github.com/yourcompany/rupaya.git
cd rupaya

# Verify directory structure
ls -la
# You should see: backend/ ios/ android/ shared/ deployment/ docs/
```

### Step 3: Choose Your Path

**What's your role?**

---

#### **Path A: Backend Developer**

```bash
cd backend

# Copy environment files
cp .env.example .env.local

# Install dependencies
npm install

# Start database & cache (uses Docker)
docker-compose up -d postgres redis

# Run migrations
npm run migrate

# Verify setup
npm run dev

# You should see:
# ✓ Server running on http://localhost:3000
# ✓ Connected to PostgreSQL
# ✓ Connected to Redis

# Test it works
curl http://localhost:3000/health
# Response: { "status": "ok", "timestamp": "2026-01-30T21:00:00Z" }

# Stop services when done
docker-compose down
```

**Environment variables you need (.env.local):**
```env
# Server
NODE_ENV=development
PORT=3000

# Database
DB_HOST=localhost
DB_PORT=5432
DB_USER=rupaya_dev
DB_PASSWORD=dev_password
DB_NAME=rupaya_dev

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_DB=0

# JWT
JWT_SECRET=your_jwt_secret_min_32_chars
JWT_REFRESH_SECRET=your_refresh_secret_min_32_chars
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d

# Email (optional for development)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your_email@gmail.com
SMTP_PASSWORD=your_app_password

# AWS (leave blank for local dev)
AWS_REGION=ap-south-1
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=

# App
APP_NAME=RUPAYA
APP_URL=http://localhost:3000
FRONTEND_URL=http://localhost:3000
```

---

#### **Path B: iOS Developer**

```bash
cd ios

# Install dependencies (CocoaPods)
pod install

# Open in Xcode
open RUPAYA.xcworkspace

# In Xcode:
# 1. Select "RUPAYA" scheme (top left)
# 2. Select "iPhone 15" simulator
# 3. Press Cmd+R to build & run
# 4. You should see login screen

# Test local backend connection
# In RUPAYA/Core/Networking/APIClient.swift
// Uncomment this for local testing:
// let baseURL = "http://localhost:3000"

# First-time setup in app:
# 1. Tap "Create Account"
# 2. Email: test@rupaya.local
# 3. Password: Test@1234567
# 4. MFA code: (skip for now)
# 5. You should see dashboard
```

**Requirements:**
- macOS 13+ with Xcode 14+
- iPhone simulator or physical iPhone
- CocoaPods: `sudo gem install cocoapods`

**Common issues:**
```bash
# Pod install fails
rm Podfile.lock
pod install --repo-update

# Xcode build fails
rm -rf ~/Library/Developer/Xcode/DerivedData/RUPAYA*
rm -rf Pods/
pod install
open RUPAYA.xcworkspace
```

---

#### **Path C: Android Developer**

```bash
cd android

# Open in Android Studio
# File → Open → select android/ folder

# Android Studio will:
# - Detect Kotlin/Gradle
# - Download SDK if needed
# - Index files (wait for completion)

# Configure emulator
# Tools → Device Manager → Create Virtual Device
# - Device: Pixel 7 or similar
# - OS: Android 14 (API 34)
# - RAM: 4GB+

# Build & run (or press Shift+F10)
./gradlew build
./gradlew installDebug

# First-time setup in app:
# 1. Tap "Create Account"
# 2. Email: test@rupaya.local
# 3. Password: Test@1234567
# 4. Biometric: Skip for now (or use emulator fingerprint)
# 5. You should see dashboard
```

**Requirements:**
- Android Studio 2023.1+
- JDK 11+
- Android SDK 34+
- Emulator or physical Android device

**Common issues:**
```bash
# Gradle sync fails
./gradlew clean
./gradlew build --refresh-dependencies

# Emulator doesn't launch
android avd  # Or use Android Studio Device Manager

# Can't connect to localhost backend
# Use 10.0.2.2:3000 instead of localhost:3000 on emulator
```

---

### Step 4: Verify Your Environment

**For all roles:**

```bash
# Check Git configuration
git config --global user.name
git config --global user.email

# Check you can pull
git pull origin develop

# Create a test branch
git checkout -b onboarding/your-name

# Make a tiny change (optional)
echo "# Onboarded at $(date)" >> docs/ONBOARDING_LOG.md
git add docs/ONBOARDING_LOG.md
git commit -m "docs: add onboarding log"
git push origin onboarding/your-name

# Create Pull Request on GitHub
# (You'll do this via web UI: https://github.com/yourcompany/rupaya/pulls)
```

**By end of Day 1, you should have:**
- ✅ Repository cloned
- ✅ Development environment running
- ✅ Git configured
- ✅ First branch created

---

## Day 2: Understanding the Codebase

### Step 1: Read Core Documentation (30 minutes)

**In order:**

1. **README.md** (5 min) - Project overview
   ```bash
   cat README.md
   ```

2. **docs/ARCHITECTURE.md** (15 min) - System design
   ```bash
   cat docs/ARCHITECTURE.md
   ```

3. **docs/API_DOCUMENTATION.md** (10 min) - API endpoints
   ```bash
   cat docs/API_DOCUMENTATION.md
   ```

### Step 2: Understand the Tech Stack

**Backend Team:**
- Node.js runtime
- Express.js framework
- PostgreSQL database
- Redis cache
- JWT authentication
- Docker deployment

**iOS Team:**
- Swift 5.9+ language
- SwiftUI framework
- MVVM architecture
- URLSession networking
- Combine reactive framework

**Android Team:**
- Kotlin language
- Jetpack Compose UI
- MVVM + Coroutines architecture
- Retrofit networking
- Hilt dependency injection

### Step 3: Explore the Codebase Structure

**All roles:**
```bash
# Backend structure
tree backend/src -L 2

# iOS structure
tree ios/RUPAYA -L 2

# Android structure
tree android/app/src/main/kotlin -L 2

# Shared code
tree shared -L 2
```

**Key files to understand:**

**Backend:**
- `src/app.js` - Express app setup
- `src/server.js` - Server entry point
- `src/controllers/auth.js` - Auth logic
- `src/models/User.js` - User data model

**iOS:**
- `RUPAYA/App/RUPAYAApp.swift` - App entry
- `RUPAYA/Features/Authentication/Views/LoginView.swift` - UI
- `RUPAYA/Core/Networking/APIClient.swift` - API calls
- `RUPAYA/Core/Security/KeychainManager.swift` - Secure storage

**Android:**
- `app/src/main/kotlin/com/rupaya/MainActivity.kt` - App entry
- `features/authentication/presentation/screens/LoginScreen.kt` - UI
- `core/network/ApiClient.kt` - API calls
- `core/security/SecureStorage.kt` - Secure storage

### Step 4: Run Tests to Verify Understanding

**Backend:**
```bash
cd backend

# Run unit tests
npm test

# Run with coverage
npm run test:coverage

# You should see:
# PASS __tests__/unit/services/AuthService.test.js
# ✓ should hash password correctly
# ✓ should verify password correctly
```

**iOS:**
```bash
cd ios

# Run tests in Xcode
# Cmd+U

# Or from command line
xcodebuild test -workspace RUPAYA.xcworkspace -scheme RUPAYA
```

**Android:**
```bash
cd android

# Run unit tests
./gradlew test

# Run instrumented tests
./gradlew connectedAndroidTest
```

### Step 5: Map the User Journey

**Complete the flow mentally:**

```
User opens app
    ↓
APIClient.swift (iOS) / ApiClient.kt (Android)
    ↓
HTTPS → api.rupaya.in
    ↓
AWS Load Balancer
    ↓
ECS → Express.js server (port 3000)
    ↓
Auth Controller → Auth Service → User Model
    ↓
PostgreSQL query: SELECT * FROM users WHERE email = ?
    ↓
Response: { token, refreshToken, user }
    ↓
Keychain (iOS) / EncryptedSharedPreferences (Android)
    ↓
User sees Dashboard
```

**By end of Day 2, you should:**
- ✅ Have read architecture docs
- ✅ Understand the tech stack
- ✅ Have explored the codebase
- ✅ Have run tests locally

---

## Day 3: Making Your First Contribution

### Step 1: Pick a Small Task

**Ask your tech lead for a task from this list:**

**Backend tasks:**
- [ ] Add a new API endpoint for exporting transactions
- [ ] Add input validation to transaction creation
- [ ] Write unit tests for a service (>80% coverage)
- [ ] Add a new field to the User model (schema + API)
- [ ] Optimize a slow database query with an index

**iOS tasks:**
- [ ] Add a new screen (e.g., Budget Details view)
- [ ] Improve error message display
- [ ] Add unit tests for a ViewModel
- [ ] Add a new color to the design system
- [ ] Add loading skeleton during API call

**Android tasks:**
- [ ] Add a new screen (e.g., Settings screen)
- [ ] Improve error handling in a ViewModel
- [ ] Add unit tests for an API service
- [ ] Add a new drawable/icon
- [ ] Implement pull-to-refresh functionality

### Step 2: Create a Feature Branch

```bash
git checkout develop
git pull origin develop

# Create feature branch (use standard naming)
git checkout -b feature/your-task-name

# Example:
# git checkout -b feature/add-export-endpoint
# git checkout -b feature/budget-details-screen
# git checkout -b feature/settings-screen
```

### Step 3: Implement Your Task

**Backend example:**
```bash
cd backend

# 1. Write test first (TDD)
cat > __tests__/unit/controllers/export.test.js << 'EOF'
describe('Export Controller', () => {
  it('should export transactions as CSV', () => {
    // Test code
  });
});
EOF

# 2. Run test (should fail)
npm test -- __tests__/unit/controllers/export.test.js

# 3. Implement feature
# Edit src/controllers/export.js

# 4. Run test again (should pass)
npm test -- __tests__/unit/controllers/export.test.js

# 5. Verify linting
npm run lint

# 6. Commit
git add .
git commit -m "feat: add transaction export endpoint

- Add /api/transactions/export POST endpoint
- Support CSV and JSON formats
- Include user email in export
- Add comprehensive tests"
```

**iOS example:**
```bash
cd ios

# 1. Create new View
# File → New → File → SwiftUI View
# Name: BudgetDetailsView.swift

# 2. Implement UI in Views/BudgetDetailsView.swift

# 3. Create ViewModel
# File → New → File → Swift File
# Name: BudgetDetailsViewModel.swift

# 4. Write tests
# File → New → File → Test Case Class
# Name: BudgetDetailsViewModelTests.swift

# 5. Run tests (Cmd+U)

# 6. Commit
git add .
git commit -m "feat: add budget details screen

- New BudgetDetailsView with transaction breakdown
- BudgetDetailsViewModel with filtering logic
- Full test coverage (100%)
- Matches design system colors and typography"
```

**Android example:**
```bash
cd android

# 1. Create new package
# right-click features/ → New → Package
# Name: settings

# 2. Create structure:
# settings/presentation/screens/SettingsScreen.kt
# settings/presentation/viewmodels/SettingsViewModel.kt
# settings/data/repository/SettingsRepository.kt

# 3. Write SettingsScreen.kt (Compose)
# Write SettingsViewModel.kt (StateFlow + logic)

# 4. Write tests
# src/test/kotlin/.../SettingsViewModelTest.kt

# 5. Run tests
./gradlew test

# 6. Commit
git add .
git commit -m "feat: add settings screen

- New Settings screen with user preferences
- MFA toggle, language selection, logout
- SettingsViewModel with state management
- 95% test coverage"
```

### Step 4: Run Quality Checks

```bash
# Backend
cd backend
npm run lint
npm test
npm run test:coverage  # Verify >80%

# iOS
cd ios
xcodebuild build -workspace RUPAYA.xcworkspace -scheme RUPAYA
xcodebuild test -workspace RUPAYA.xcworkspace -scheme RUPAYA

# Android
cd android
./gradlew lint
./gradlew test
```

### Step 5: Create Pull Request

```bash
# Push your branch
git push origin feature/your-task-name

# Go to GitHub: https://github.com/yourcompany/rupaya/pulls
# Click "New Pull Request"

# Fill in PR template:
```

**PR Template:**
```markdown
## Description
I've added a transaction export feature that allows users to download their transactions as CSV/JSON files.

## Type of Change
- [x] Backend (API, database, services)
- [ ] iOS app
- [ ] Android app
- [ ] Infrastructure
- [ ] Documentation

## Changes Made
- Added `/api/transactions/export` endpoint
- Added ExportService with CSV/JSON formatting
- Added input validation for date ranges
- Added comprehensive tests (95% coverage)

## Testing
- Unit tests: ✓ All passing
- Integration tests: ✓ All passing
- Manual testing: ✓ Tested with CSV/JSON formats
- Coverage: 95% (exceeds 80% requirement)

## Screenshots (if UI change)
[Add screenshots if applicable]

## Checklist
- [x] Code follows style guide
- [x] Tests written/updated (>80% coverage)
- [x] Documentation updated
- [x] No breaking changes
- [x] Linting passes (npm run lint)

## Related Issues
Closes #123 (optional)
```

### Step 6: Code Review Process

**What happens next:**

1. **Automated checks** (GitHub Actions)
   - ✓ Tests pass
   - ✓ Linting passes
   - ✓ Coverage >80%
   - ✓ Build succeeds

2. **Code review** (2-3 team members)
   - Backend: @backend-team
   - iOS: @ios-team
   - Android: @android-team
   - Anyone can comment & suggest changes

3. **Address feedback**
   ```bash
   # Make requested changes
   git add .
   git commit -m "refactor: address code review feedback"
   git push origin feature/your-task-name
   
   # Don't create new PR, just update existing one
   ```

4. **Approval & Merge**
   - Once approved, maintainer merges to develop
   - Your branch is deleted
   - Your work is live on develop branch

**By end of Day 3, you should:**
- ✅ Have made a feature branch
- ✅ Have implemented a real feature
- ✅ Have submitted a PR
- ✅ Have received code review feedback

---

## Week 2: Deep Dives by Role

### Backend Developer Track

#### Day 4-5: Database & Queries

**Learn:**
```bash
# 1. Understand schema
cat backend/migrations/001_init.sql

# 2. Run a migration
npm run migrate

# 3. Write SQL query
npm run db:shell
# SELECT * FROM users LIMIT 10;

# 4. Understand ORM (if using Prisma/Sequelize)
cat backend/src/models/User.js

# 5. Write an optimized query
# Add an index:
# CREATE INDEX idx_users_email ON users(email);

# Task: Optimize a slow query
# Example: Finding all transactions for a user
# Before: SELECT * FROM transactions WHERE user_id = $1
# After: (with proper index)
```

**Resources:**
- PostgreSQL documentation: https://www.postgresql.org/docs/
- SQL performance tuning: Check docs/SECURITY.md

#### Day 6-7: API Development

**Learn:**
```bash
# 1. Understand Express routing
cat backend/src/routes/transactions.js

# 2. Understand controllers
cat backend/src/controllers/transactions.js

# 3. Understand middleware
cat backend/src/middleware/auth.js

# 4. Write a new endpoint
# Create backend/src/routes/budgets.js
# Create backend/src/controllers/budgets.js
# Add tests in __tests__/integration/budgets.test.js

# 5. Test with curl
curl -X GET http://localhost:3000/api/budgets \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Next task:**
- Add 2-3 new endpoints
- Write integration tests
- Document in API_DOCUMENTATION.md

---

### iOS Developer Track

#### Day 4-5: SwiftUI & State Management

**Learn:**
```bash
# 1. Understand state management
cat ios/RUPAYA/Features/Dashboard/ViewModels/DashboardViewModel.swift

# 2. Understand networking
cat ios/RUPAYA/Core/Networking/APIClient.swift

# 3. Create a new View
# File → New → File → SwiftUI View
# Name: TransactionDetailView.swift

# 4. Understand data binding
@State, @ObservedObject, @EnvironmentObject

# 5. Build a screen
# - Create TransactionDetailView
# - Create TransactionDetailViewModel
# - Connect with @ObservedObject
# - Write tests
```

**Resources:**
- SwiftUI docs: https://developer.apple.com/documentation/swiftui
- Combine docs: https://developer.apple.com/documentation/combine

#### Day 6-7: Testing & Debugging

**Learn:**
```bash
# 1. Write unit tests
cat ios/RUPAYATests/AuthViewModelTests.swift

# 2. Run tests (Cmd+U)
xcodebuild test -workspace RUPAYA.xcworkspace -scheme RUPAYA

# 3. Use Xcode debugger
# Set breakpoint → Cmd+Y → Step through

# 4. Profile performance
# Debug → Gauges → CPU/Memory

# 5. Write integration tests
```

**Next task:**
- Create a complete new screen (View + ViewModel + Tests)
- Add 95%+ test coverage
- Ensure zero warnings in Xcode

---

### Android Developer Track

#### Day 4-5: Jetpack Compose & Architecture

**Learn:**
```bash
# 1. Understand MVVM
cat android/app/src/main/kotlin/.../viewmodels/AuthViewModel.kt

# 2. Understand Compose
cat android/app/src/main/kotlin/.../screens/LoginScreen.kt

# 3. Understand StateFlow & Coroutines
# @State, StateFlow, Coroutine launch

# 4. Create a new screen
# Create screens/BudgetScreen.kt
# Create viewmodels/BudgetViewModel.kt
# Create repository/BudgetRepository.kt

# 5. Write tests
cat android/app/src/test/kotlin/.../AuthViewModelTest.kt
```

**Resources:**
- Jetpack Compose docs: https://developer.android.com/develop/ui/compose
- Coroutines docs: https://developer.android.com/kotlin/coroutines

#### Day 6-7: Testing & Debugging

**Learn:**
```bash
# 1. Write unit tests
./gradlew test

# 2. Write UI tests (Espresso)
./gradlew connectedAndroidTest

# 3. Use Android Studio debugger
# Debug → Debug app

# 4. Profile performance
# Build → Analyze APK

# 5. Test on actual device
adb devices
adb install app-debug.apk
```

**Next task:**
- Create a complete new screen (Screen + ViewModel + Repository)
- Add 90%+ test coverage
- Test on both emulator and real device

---

## Week 3: Specialization & Scaling

### Backend: Advanced Topics

**Pick one to deep-dive:**

1. **Database Optimization**
   - Write complex queries
   - Add strategic indices
   - Measure query performance
   - Optimize slow endpoints

2. **Caching Strategy**
   - Understand Redis usage
   - Implement cache-aside pattern
   - Set TTLs appropriately
   - Monitor cache hit ratio

3. **Security Hardening**
   - Review OWASP Top 10
   - Add rate limiting
   - Implement CORS properly
   - Test for SQL injection

4. **Performance & Scalability**
   - Load testing (k6, JMeter)
   - Database connection pooling
   - API response time optimization
   - Horizontal scaling readiness

### iOS/Android: Advanced Topics

**Pick one to deep-dive:**

1. **Offline-First Architecture**
   - Local caching strategy
   - Sync when online
   - Conflict resolution
   - Offline-first UI patterns

2. **Security & Biometrics**
   - Implement biometric auth
   - Secure token storage
   - Certificate pinning
   - Data encryption

3. **Performance Optimization**
   - Profile app performance
   - Optimize memory usage
   - Reduce app startup time
   - Smooth animations

4. **Testing Expertise**
   - Unit testing advanced patterns
   - UI/Integration testing
   - Snapshot testing
   - Performance testing

---

## Quick Reference

### Essential Commands

**Git:**
```bash
git checkout develop              # Switch to develop
git pull origin develop           # Pull latest changes
git checkout -b feature/x         # Create feature branch
git add .                         # Stage changes
git commit -m "type: message"     # Commit with conventional format
git push origin feature/x         # Push to GitHub
git merge develop                 # Merge develop into current branch
```

**Backend:**
```bash
npm install                       # Install dependencies
npm run dev                       # Start server with auto-reload
npm test                          # Run tests
npm run lint                      # Check code style
npm run migrate                   # Run database migrations
docker-compose up -d              # Start database & Redis
```

**iOS:**
```bash
pod install                       # Install dependencies
open RUPAYA.xcworkspace           # Open project
xcodebuild build                  # Build from command line
xcodebuild test                   # Run tests from command line
```

**Android:**
```bash
./gradlew build                   # Build app
./gradlew test                    # Run unit tests
./gradlew connectedAndroidTest    # Run UI tests
./gradlew lint                    # Check code style
```

### Key Files to Know

**Backend:**
- `src/app.js` - Express setup
- `src/server.js` - Entry point
- `src/controllers/` - HTTP handlers
- `src/services/` - Business logic
- `src/middleware/auth.js` - JWT verification
- `migrations/` - Database schema changes

**iOS:**
- `RUPAYA/App/RUPAYAApp.swift` - App entry
- `RUPAYA/Features/` - Feature modules
- `RUPAYA/Core/Networking/APIClient.swift` - API calls
- `RUPAYA/Core/Security/KeychainManager.swift` - Secure storage

**Android:**
- `MainActivity.kt` - App entry
- `features/*/presentation/screens/` - UI screens
- `core/network/ApiClient.kt` - API calls
- `core/security/SecureStorage.kt` - Secure storage

### Communication Channels

- **#rupaya-general** - Team announcements
- **#rupaya-backend** - Backend discussions
- **#rupaya-ios** - iOS discussions
- **#rupaya-android** - Android discussions
- **#rupaya-alerts** - Prod alerts (don't talk here)
- **Tech Lead DM** - Blockers & urgent questions
- **Weekly standup** - Sync with team

### Important Links

- **GitHub:** https://github.com/yourcompany/rupaya
- **AWS Console:** https://console.aws.amazon.com
- **App Store Connect:** https://appstoreconnect.apple.com
- **Google Play Console:** https://play.google.com/console
- **Architecture Docs:** `/docs/ARCHITECTURE.md`
- **API Docs:** `/docs/API_DOCUMENTATION.md`
- **Deployment Guide:** `/docs/DEPLOYMENT.md`

### Code Review Checklist

**Before submitting a PR:**
- [ ] Code runs locally without errors
- [ ] Tests pass and coverage >80%
- [ ] Linting passes (no warnings)
- [ ] No debug logs or commented code
- [ ] Documentation updated (if needed)
- [ ] Commit messages follow convention
- [ ] No hardcoded secrets or credentials

**What reviewers look for:**
- Does it solve the problem described?
- Is the code maintainable & readable?
- Are tests comprehensive?
- Are there security concerns?
- Does it follow team patterns?
- Is documentation clear?

### Common Questions

**Q: Where do I run commands?**
A: Backend commands in `/backend`, iOS in `/ios`, Android in `/android`.

**Q: How do I test locally?**
A: Backend: `npm run dev`. iOS: Xcode simulator. Android: Android Studio emulator.

**Q: What if I need AWS access?**
A: Ask tech lead → receives AWS IAM user → add to 1Password.

**Q: How do I report a bug?**
A: GitHub Issues → Add label "bug" → Assign to relevant team.

**Q: When should I ask for help?**
A: Anytime! After 30 min of being stuck, ask in Slack or #rupaya-general.

**Q: How are releases coordinated?**
A: Tech lead creates release/* branch → all teams sync → tag v*.*.* → CI/CD deploys.

**Q: What's the merge strategy?**
A: feature/x → develop → release/v* → main (production).

---

## Your First Week Checklist

### Day 1 ✅
- [ ] Repository cloned
- [ ] Development environment working
- [ ] Git configured
- [ ] Can run local server/app

### Day 2 ✅
- [ ] Read ARCHITECTURE.md
- [ ] Read API_DOCUMENTATION.md
- [ ] Ran test suite
- [ ] Can navigate codebase

### Day 3 ✅
- [ ] Created feature branch
- [ ] Implemented a real feature
- [ ] Submitted PR
- [ ] Received code review feedback

### Day 4-5 ✅
- [ ] Completed role-specific deep dive
- [ ] Completed second feature
- [ ] 80%+ test coverage

### Day 6-7 ✅
- [ ] Completed third feature
- [ ] Merged code to develop
- [ ] Can confidently work independently

---

## Success Metrics

By the end of Week 1, you should:

✅ **Technical**
- Can run the entire project locally
- Can navigate the codebase independently
- Can write tests for your code
- Can submit a PR without help

✅ **Process**
- Understand Git workflow
- Know the code review process
- Know who to ask for help
- Can read and understand API documentation

✅ **Team**
- Know your team members' roles
- Know how to communicate issues
- Understand the deployment process
- Familiar with team conventions

✅ **Confidence**
- Could implement a small feature end-to-end
- Could debug an issue
- Could review someone else's code
- Could deploy (with supervision)

---

## Next Steps After Week 1

### Week 2-4: Own a Feature
- Pick a feature from backlog
- Implement end-to-end (backend + mobile)
- Get it to production
- Monitor in production

### Month 2: Deep Specialization
- Become expert in your platform
- Lead architectural discussions
- Mentor new team members
- Own critical systems

### Month 3+: Leadership
- Lead cross-team initiatives
- Design new systems
- Mentor multiple people
- Make architectural decisions

---

## Final Tips

1. **Ask questions** - Better to ask now than make wrong assumptions
2. **Read code first** - Before asking, search the codebase
3. **Write tests** - Every feature should have >80% coverage
4. **Commit often** - Small, logical commits are easier to review
5. **Communicate** - Update team on blockers immediately
6. **Document** - Leave comments for future developers
7. **Stay curious** - Understand the *why* behind decisions
8. **Celebrate wins** - Shipping is hard, celebrate each merge!

---

## Troubleshooting

### I can't connect to localhost:3000

**Backend:**
```bash
# Is the server running?
ps aux | grep "node server.js"

# Check the port
lsof -i :3000

# Restart server
cd backend
npm run dev
```

**iOS:**
```bash
# Change APIClient.baseURL to:
// http://localhost:3000 (for iPhone on same network)
// http://127.0.0.1:3000 (for simulator)
```

**Android:**
```bash
# Use 10.0.2.2 instead of localhost:3000
// Change ApiClient.BASE_URL to:
// "http://10.0.2.2:3000"
```

### Tests are failing

```bash
# Backend
cd backend
npm run test -- --verbose  # See detailed output
npm run test -- --watch    # Watch mode for TDD

# iOS
# In Xcode: Product → Scheme → Edit Scheme → Test → Run
# Select "Show execution logs"

# Android
./gradlew test --info      # Verbose output
./gradlew test --debug     # Debug mode
```

### Git conflicts

```bash
# When merging develop into your feature branch:
git merge develop

# See conflicts
git status

# Fix conflicts in your editor

# Mark as resolved
git add .
git commit -m "merge: resolve conflicts with develop"
git push origin feature/your-branch
```

### I don't have AWS/App Store access yet

- Email tech lead
- Request specific service access
- Wait 24 hours for provisioning
- In the meantime, work on local features

---

## Welcome to RUPAYA! 🚀

You're now ready to start building. Go crush it! 💪

Questions? Ask in Slack or during standup.
