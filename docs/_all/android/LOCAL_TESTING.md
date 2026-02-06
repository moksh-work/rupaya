# Local Android Testing Guide for Rupaya

This guide provides professional, repeatable steps for building, running, and testing the Android app locally.

---

## 1. Prerequisites
- **Android Studio** (latest stable recommended)
- **JDK 17**
- **Android SDK** (API 34+)
- **Android Emulator** or physical device
- **Gradle** (wrapper included)

---

## 2. Environment Setup
- Open the `android` folder in Android Studio.
- Ensure your `JAVA_HOME` points to JDK 17.
- Install required SDKs and emulator images via Android Studio SDK Manager.

---

## 3. Build the App

```
./gradlew clean assembleDebug
```

---

## 4. Run the App
- Launch an emulator or connect a device.
- Click "Run" in Android Studio, or use:
  ```
  ./gradlew installDebug
  ```

---

## 5. Run Instrumented Tests

```
./gradlew :app:connectedDebugAndroidTest
```
- Results: `android/app/build/reports/androidTests/connected/debug/index.html`

---

## 6. Run Unit Tests

```
./gradlew :app:testDebugUnitTest
```
- Results: `android/app/build/reports/tests/testDebugUnitTest/index.html`

---

## 7. Lint and Static Analysis

```
./gradlew lint
./gradlew detekt  # If detekt is configured
```
- Results: `android/app/build/reports/lint-results.html`

---

## 8. Troubleshooting
- If builds fail, check Gradle sync and dependencies.
- For emulator issues, restart ADB: `adb kill-server && adb start-server`.
- For test failures, review the HTML reports for details.

---

## 9. Clean Build

```
./gradlew clean
```

---

## 10. Additional Notes
 - Use Android Studio's Profiler and Logcat for debugging.
 - Keep dependencies and plugins up to date for best compatibility.
 - For CI/CD, use the same Gradle commands as above.

## 11. Allow HTTP (Cleartext) for Local Backend (10.0.2.2)

If you see this error in the emulator:

> CLEARTEXT communication to 10.0.2.2 not permitted by network security policy

You must allow HTTP for local development:

1. **Create or edit** `android/app/src/main/res/xml/network_security_config.xml`:
   ```xml
   <?xml version="1.0" encoding="utf-8"?>
   <network-security-config>
     <domain-config cleartextTrafficPermitted="true">
       <domain includeSubdomains="true">10.0.2.2</domain>
     </domain-config>
   </network-security-config>
   ```
2. **Reference this config** in your `AndroidManifest.xml` `<application>` tag:
   ```xml
   <application
     ...
     android:networkSecurityConfig="@xml/network_security_config"
     ... >
     ...
   </application>
   ```
3. **Rebuild and rerun** your app.

This allows HTTP connections to your Docker backend for local testing. For production, always use HTTPS.
---
_This guide ensures a professional, repeatable local Android test setup for all developers._
