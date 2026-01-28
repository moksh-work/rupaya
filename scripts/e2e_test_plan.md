# End-to-End Test Plan

## Scenarios
- User signup/login (iOS, Android, Web)
- Phone/OTP authentication
- Transaction creation/view (iOS, Android)
- Biometric authentication (iOS Face ID, Android fingerprint)
- Cross-platform data sync (create on one, view on another)
- API error handling (invalid token, network failure)

## Example E2E Steps
1. Launch app (iOS/Android)
2. Sign up with new email/phone
3. Login with credentials/OTP
4. Create a transaction
5. Enable biometric auth, logout, login with biometrics
6. Verify transaction appears on both platforms
7. Attempt API call with invalid token (expect error)

## Automation
- Use Playwright/Cypress for web/API
- Use Detox/Appium/XCUITest/Espresso for mobile
- See scripts/script_3.py for automation hooks
