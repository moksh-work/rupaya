# Quick Start: Running Tests

## Backend Testing

### Prerequisites
```bash
# Install dependencies
cd backend
npm install

# Ensure PostgreSQL and Redis are running
# For Docker:
docker-compose up -d postgres redis
```

### Run Tests

**All tests**:
```bash
npm test
```

**By type**:
```bash
npm run test:unit          # Unit tests only
npm run test:integration   # Integration tests only
npm run test:smoke         # Smoke tests only
npm run test:e2e          # End-to-end tests only
```

**Watch mode** (re-run on file changes):
```bash
npm run test:watch
```

**With detailed output**:
```bash
npm run test:verbose
```

**Stop on first failure**:
```bash
npm run test:bail
```

### Sample Output

```
PASS  __tests__/unit/services/AuthService.test.js
  AuthService
    generateJWT
      ✓ should generate valid JWT token (5ms)
      ✓ should throw error if JWT generation fails (2ms)
    verifyJWT
      ✓ should verify valid JWT token (3ms)
      ✓ should throw error for invalid token (2ms)
    hashPassword
      ✓ should hash password successfully (45ms)
    comparePasswords
      ✓ should return true for matching passwords (52ms)
    validatePasswordStrength
      ✓ should pass strong password (1ms)
      ✓ should fail weak password (1ms)

PASS  __tests__/integration/routes/auth.test.js
  Authentication Routes - Integration Tests
    POST /api/auth/signup
      ✓ should create new user (125ms)
      ✓ should reject invalid email (45ms)
      ✓ should reject weak password (38ms)
    POST /api/auth/login
      ✓ should login with correct credentials (110ms)
      ✓ should reject incorrect password (95ms)

PASS  __tests__/smoke/smoke-tests.test.js
  Smoke Tests - Core API
    Health Endpoint
      ✓ should return OK status (15ms)
    Authentication Flow
      ✓ should complete full auth cycle (250ms)
    Dashboard Endpoint
      ✓ should return dashboard data (120ms)

Test Suites: 3 passed, 3 total
Tests:       28 passed, 28 total
Snapshots:   0 total
Time:        12.543 s
Coverage Summary:
  Statements   : 85.2% (234/274)
  Branches     : 78.5% (120/153)
  Functions    : 82.1% (55/67)
  Lines        : 86.3% (240/278)
```

---

## iOS Testing

### Prerequisites
```bash
# Xcode must be installed
xcode-select --install

# Open workspace
cd ios
open RUPAYA.xcworkspace
```

### Run Tests in Xcode

**All tests**:
- Product → Test (or ⌘U)

**Specific test file**:
- Select test file → Product → Test

**With coverage**:
- Product → Scheme → Edit Scheme
- Test → Code Coverage → Check "Gather coverage data"

### Command Line Testing

```bash
cd ios

# Run all tests
xcodebuild test -workspace RUPAYA.xcworkspace -scheme RUPAYA

# Run specific test class
xcodebuild test \
  -workspace RUPAYA.xcworkspace \
  -scheme RUPAYA \
  -testclass LoginViewModelTests

# Run on specific simulator
xcodebuild test \
  -workspace RUPAYA.xcworkspace \
  -scheme RUPAYA \
  -destination "generic/platform=iOS Simulator,name=iPhone 15"
```

---

## Android Testing

### Prerequisites
```bash
# Android SDK must be installed
# Open Android Studio and sync project

cd android
```

### Run Tests in Android Studio

**All tests**:
- Right-click project → Run 'All Tests'

**Specific test file**:
- Right-click test file → Run

**With coverage**:
- Right-click project → Run with Coverage

### Command Line Testing

```bash
cd android

# Run all unit tests
./gradlew testDebugUnitTest

# Run specific test class
./gradlew testDebugUnitTest --tests "*LoginViewModelTests"

# Generate coverage report
./gradlew testDebugUnitTestCoverage
```

---

## CI/CD Testing (GitHub Actions)

### Automatic Testing

Tests run automatically on:
- Push to `main` branch
- Pull requests to `main`

### View Results

1. Go to GitHub repo
2. Click "Actions" tab
3. Select workflow run
4. See test results

### Manual Trigger

```bash
# Via GitHub CLI
gh workflow run tests.yml

# Via GitHub UI
Actions → Tests → Run workflow
```

---

## Test Reports

### Coverage Report (Backend)

```bash
cd backend

# Generate HTML report
npm test -- --coverage

# View report
open coverage/lcov-report/index.html
```

### Interpreting Coverage

```
Statements: 85%  - % of code lines executed
Branches:   78%  - % of conditional branches tested
Functions:  82%  - % of functions called
Lines:      86%  - % of lines executed
```

**Target**: 80%+ for production code

---

## Debugging Failed Tests

### View Detailed Error

```bash
npm run test:verbose
```

### Run Single Test

```bash
npm test -- -t "test name"
# Example: npm test -- -t "should create new user"
```

### Debug with Node Inspector

```bash
node --inspect-brk node_modules/.bin/jest --runInBand
```

### Check Logs

```bash
# Database logs
docker-compose logs postgres

# Redis logs
docker-compose logs redis
```

---

## Common Issues

### "Cannot find module" error

**Fix**:
```bash
npm install
npm run migrate:test
```

### "Connection refused" (Database/Redis)

**Fix**:
```bash
# Start services
docker-compose up -d

# Verify running
docker-compose ps
```

### "Port already in use"

**Fix**:
```bash
# Kill process on port 5432 or 6379
lsof -ti:5432 | xargs kill -9
lsof -ti:6379 | xargs kill -9
```

### Tests timeout

**Fix**:
```bash
# Increase timeout
npm test -- --testTimeout=60000
```

---

## Example Workflows

### Before Committing

```bash
# 1. Run all tests
npm test

# 2. Check results (must pass)
# If any fail, fix and commit again

# 3. Check coverage
npm test -- --coverage

# 4. Commit
git add .
git commit -m "Fix: resolved test failures"
```

### Feature Branch

```bash
# 1. Create branch
git checkout -b feature/add-budgets

# 2. Write test first
# Create file: __tests__/integration/budgets.test.js

# 3. Run tests (should fail)
npm run test:integration

# 4. Write code to pass test
# Create file: src/routes/budgets.js

# 5. Run tests again (should pass)
npm run test:integration

# 6. Commit
git add .
git commit -m "Add: budget endpoints with tests"

# 7. Push and create PR
git push origin feature/add-budgets
```

### Pre-Release Checklist

```bash
# 1. Run full test suite
npm test

# 2. Run all platforms
# - Backend: npm test
# - iOS: xcodebuild test -workspace RUPAYA.xcworkspace -scheme RUPAYA
# - Android: ./gradlew testDebugUnitTest

# 3. Verify coverage
npm test -- --coverage

# 4. Create release notes
echo "## v1.0.0 Release - All tests passing ✓"

# 5. Tag release
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

---

## Performance Tips

### Speed Up Tests

```bash
# Run tests in parallel (default)
npm test

# Run specific suite only
npm run test:unit

# Skip coverage generation
jest --no-coverage

# Run only changed tests
npm test -- --onlyChanged
```

### Expected Times

| Test Type | Time |
|-----------|------|
| Unit | ~5-10s |
| Integration | ~10-15s |
| Smoke | ~5-10s |
| E2E | ~15-20s |
| **All** | **~45s** |

---

## Next Steps

✅ **Now you have:**
- Unit tests for services
- Integration tests for API endpoints
- Smoke tests for critical paths
- E2E tests for user workflows
- GitHub Actions CI/CD automation
- iOS and Android test suites

**To add more tests:**
1. Create `.test.js` file in `__tests__/` folder
2. Write tests using Jest syntax
3. Run `npm test`
4. Push to trigger CI/CD

**Coverage goals:**
- Target: 80%+ code coverage
- Focus: Critical business logic
- Maintain: Add tests for new features

---

**Status**: ✅ Ready to use
**Last Updated**: 2026-02-01
