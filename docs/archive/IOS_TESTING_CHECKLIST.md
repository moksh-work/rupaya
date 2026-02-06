# 📱 iOS App Testing Checklist

## Pre-Testing Setup

- [ ] Backend running: `http://localhost:3000/health` returns `{"status":"OK"}`
- [ ] Xcode installed (version 14.0+)
- [ ] CocoaPods installed: `pod --version`
- [ ] iOS Simulator selected (iPhone 15 Pro recommended)
- [ ] APIClient.swift updated to use `APIConfig.resolvedBaseURL`
- [ ] Info.plist has `NSAllowsLocalNetworking` set to `true`

## Quick Start

```bash
cd /Users/rsingh/Documents/Projects/rupaya/ios
./ios-start.sh
```

## Testing Scenarios

### 1. Authentication ✓
- [ ] Launch app shows Login/Signup screen
- [ ] Tap "Sign Up" button
- [ ] Enter email: `test-ios@example.com`
- [ ] Enter password: `TestPass123` (minimum 8 characters)
- [ ] Confirm password matches
- [ ] Tap "Create Account"
- [ ] Success: Navigate to main app
- [ ] Error handling: Invalid credentials show error message
- [ ] Logout and login with same credentials

### 2. Main Navigation ✓
- [ ] Tab bar displays (Dashboard, Transactions, Accounts, Settings)
- [ ] Tap each tab and verify navigation
- [ ] Navigation animations smooth
- [ ] Back buttons work correctly

### 3. Account Management ✓
- [ ] Tap "Accounts" tab
- [ ] Tap "+" to add new account
- [ ] Enter account name: "My Test Account"
- [ ] Select account type: Bank/Cash/Credit Card
- [ ] Enter initial balance: 5000
- [ ] Save account
- [ ] Verify account appears in list
- [ ] Tap account to view details
- [ ] Edit account name
- [ ] Delete account (with confirmation)

### 4. Transactions ✓
- [ ] Tap "Transactions" tab
- [ ] Tap "+" to add transaction
- [ ] Select transaction type: Income/Expense
- [ ] Select account
- [ ] Enter amount: 100
- [ ] Select category
- [ ] Enter description
- [ ] Save transaction
- [ ] Verify transaction in list
- [ ] Filter transactions by date
- [ ] Filter transactions by category
- [ ] Search transactions

### 5. Dashboard ✓
- [ ] Tap "Dashboard" tab
- [ ] Verify total balance displays
- [ ] Income/Expense summary shows
- [ ] Recent transactions list
- [ ] Spending by category chart
- [ ] Pull to refresh updates data

### 6. Settings ✓
- [ ] Tap "Settings" tab
- [ ] View profile information
- [ ] Change currency preference
- [ ] Change theme (Light/Dark/System)
- [ ] Enable biometric authentication
- [ ] Test Face ID/Touch ID login
- [ ] Logout button works

## Network Testing

### Console Logs to Check
```
🌐 [Network] POST http://localhost:3000/api/v1/auth/signup
✅ [Network] Response [200]: /api/v1/auth/signup
ℹ️ [Auth] Token saved to keychain
✅ [Auth] User authenticated
```

### Backend Logs to Monitor
```bash
# In separate terminal
cd backend
docker-compose -f docker-compose.dev.yml logs -f backend
```

Expected logs:
```
info: POST /api/v1/auth/signup - 200
info: POST /api/v1/accounts - 201
info: GET /api/v1/transactions - 200
```

## Error Scenarios

### Test Network Errors
- [ ] Turn off backend: `docker-compose down`
- [ ] App shows "Cannot connect to server" error
- [ ] Restart backend: `docker-compose up -d`
- [ ] App reconnects automatically

### Test Invalid Data
- [ ] Signup with existing email → "User already exists"
- [ ] Login with wrong password → "Invalid credentials"
- [ ] Create transaction with 0 amount → Validation error
- [ ] Create account with empty name → Validation error

### Test Token Expiration
- [ ] Login successfully
- [ ] Wait 15 minutes (token expiry)
- [ ] Make API call (add transaction)
- [ ] Token auto-refreshes
- [ ] Transaction succeeds

## UI/UX Testing

### Visual Checks
- [ ] All text is readable
- [ ] Buttons are tappable (not too small)
- [ ] Colors are consistent with design
- [ ] Icons display correctly
- [ ] Loading indicators show during API calls
- [ ] Error messages are user-friendly

### Accessibility
- [ ] VoiceOver reads screen elements
- [ ] Text size adjusts with system settings
- [ ] Color contrast passes WCAG guidelines
- [ ] All interactive elements have labels

### Performance
- [ ] App launches in < 3 seconds
- [ ] Screen transitions are smooth (60 FPS)
- [ ] No memory leaks (test with Instruments)
- [ ] Network calls complete in < 2 seconds

## Device-Specific Testing

### Simulator Testing ✓
- [ ] iPhone SE (small screen)
- [ ] iPhone 15 Pro (standard)
- [ ] iPhone 15 Pro Max (large screen)
- [ ] iPad Air (tablet)

### Physical Device Testing
- [ ] Update APIConfig.swift with Mac's IP address
- [ ] Connect iPhone via USB
- [ ] Enable Developer Mode on device
- [ ] Build and run on device
- [ ] Test biometric authentication (Face ID/Touch ID)
- [ ] Test in poor network conditions

## Data Persistence

- [ ] Login, close app, reopen → Still logged in
- [ ] Add transaction, close app, reopen → Transaction persists
- [ ] Logout → All local data cleared
- [ ] Login again → Fresh data from server

## Edge Cases

- [ ] Create 100+ transactions → List scrolls smoothly
- [ ] Enter very long account name → Truncated properly
- [ ] Enter amount > 1,000,000 → Displays correctly
- [ ] Rotate device → Layout adapts
- [ ] Background app for 30 minutes → Resumes correctly
- [ ] App interrupted by phone call → Handles gracefully

## Security Testing

- [ ] Tokens stored in Keychain (not UserDefaults)
- [ ] Password not visible when typing
- [ ] API calls use HTTPS in production
- [ ] Sensitive data not logged in release builds
- [ ] Biometric prompt appears correctly
- [ ] Auto-lock after inactivity (if configured)

## Final Verification

### Before Production
- [ ] All critical bugs fixed
- [ ] No crashes during testing session
- [ ] Backend switched to production URL
- [ ] TestFlight beta test completed
- [ ] App Store screenshots prepared
- [ ] Privacy policy updated
- [ ] App Store submission ready

## Test Results Log

**Test Date:** _________________  
**Tester:** _________________  
**Device/Simulator:** _________________  
**iOS Version:** _________________  
**Backend URL:** _________________  

**Overall Status:** [ ] Pass [ ] Fail  

**Critical Issues Found:**
1. _________________
2. _________________
3. _________________

**Notes:**
_________________
_________________
_________________

---

## Quick Commands Reference

```bash
# Start backend
cd backend && docker-compose -f docker-compose.dev.yml up -d

# Start iOS app development
cd ios && ./ios-start.sh

# View backend logs
docker-compose -f backend/docker-compose.dev.yml logs -f backend

# Reset iOS simulator
xcrun simctl erase all

# Build iOS app
xcodebuild -workspace ios/RUPAYA.xcworkspace -scheme RUPAYA -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Run tests
xcodebuild test -workspace ios/RUPAYA.xcworkspace -scheme RUPAYA -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

---

**Happy Testing! 📱✨**
