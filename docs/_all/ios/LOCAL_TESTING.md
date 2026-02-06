# Local iOS Testing Guide for Rupaya

This guide provides professional, repeatable steps for building, running, and testing the iOS app locally.

---

## 1. Prerequisites
- **macOS** (latest recommended)
- **Xcode** (latest stable)
- **CocoaPods** (if not installed: `sudo gem install cocoapods`)
- **iOS Simulator** or physical device

---

## 2. Environment Setup
- Open the `ios/RUPAYA.xcworkspace` in Xcode.
- Run `pod install` in the `ios` directory if not already done.
- Ensure Xcode command line tools are set: `sudo xcode-select -s /Applications/Xcode.app`

---

## 3. Build the App
- In Xcode: Select the `RUPAYAApp` scheme and your target device/simulator.
- Click **Product > Build** or press `Cmd+B`.

---

## 4. Run the App
- Click **Run** in Xcode or press `Cmd+R`.
- Or, from terminal:
  ```
  xcodebuild -workspace RUPAYA.xcworkspace -scheme RUPAYAApp -destination 'platform=iOS Simulator,name=iPhone 15' build
  ```

---

## 5. Run Unit & UI Tests
- In Xcode: **Product > Test** or press `Cmd+U`.
- Or, from terminal:
  ```
  xcodebuild test -workspace RUPAYA.xcworkspace -scheme RUPAYAApp -destination 'platform=iOS Simulator,name=iPhone 15'
  ```
- Test results appear in the Xcode Test navigator and logs.

---

## 6. Lint and Static Analysis
- Use **SwiftLint** if configured:
  ```
  brew install swiftlint
  swiftlint
  ```
- Review warnings in Xcode for code style and best practices.

---

## 7. Troubleshooting
- If builds fail, check for missing pods: `pod install`.
- For simulator issues, reset or restart the simulator.
- For test failures, review the Xcode Test navigator and logs.

---

## 8. Clean Build
- In Xcode: **Product > Clean Build Folder** (`Shift+Cmd+K`).
- Or, from terminal:
  ```
  xcodebuild clean -workspace RUPAYA.xcworkspace -scheme RUPAYAApp
  ```

---

## 9. Additional Notes
- Keep Xcode and CocoaPods up to date.
- Use Xcode's Profiler and Debug tools for performance and bug fixing.
- For CI/CD, use the same xcodebuild commands as above.

---

_This guide ensures a professional, repeatable local iOS test setup for all developers._
