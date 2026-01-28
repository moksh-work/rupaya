# Local E2E Testing Guide for Rupaya

This guide provides professional, repeatable steps for running end-to-end (E2E) tests locally. Update the tool-specific sections (Playwright, Cypress, Detox) as needed for your stack.

---

## 1. Prerequisites
- **Node.js** (v18+ recommended)
- **npm** (v9+ recommended)
- **Backend and frontend servers running locally**
- **E2E test framework installed** (Playwright, Cypress, or Detox)

---

## 2. Environment Setup
- Ensure backend and frontend are running on the expected ports (see `.env` or E2E config).
- Install E2E dependencies:
  ```
  cd assest-code
  npm install  # or yarn install, if applicable
  ```

---

## 3. Playwright E2E Tests (if used)
- Install Playwright (if not already):
  ```
  npx playwright install
  ```
- Run all E2E tests:
  ```
  npx playwright test
  ```
- View HTML report:
  ```
  npx playwright show-report
  ```

---

## 4. Cypress E2E Tests (if used)
- Run Cypress tests in headless mode:
  ```
  npx cypress run
  ```
- Open Cypress UI:
  ```
  npx cypress open
  ```

---

## 5. Detox E2E Tests (React Native/Mobile, if used)
- Build the app for testing:
  ```
  detox build --configuration android.emu.debug
  # or for iOS:
  detox build --configuration ios.sim.debug
  ```
- Run tests:
  ```
  detox test --configuration android.emu.debug
  # or for iOS:
  detox test --configuration ios.sim.debug
  ```

---

## 6. Troubleshooting
- Ensure all required servers are running before starting E2E tests.
- Check E2E config files for correct base URLs and ports.
- Review HTML or CLI reports for failed tests and debug accordingly.

---

## 7. Clean Up
- Stop any test servers or emulators after testing.

---

## 8. Additional Notes
- Keep E2E dependencies up to date for best reliability.
- Integrate E2E tests into your CI/CD pipeline for full automation.

---

_This guide ensures a professional, repeatable local E2E test setup for all developers._
