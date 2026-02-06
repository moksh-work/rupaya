# 📱 iOS App Local Testing Guide - RUPAYA

## Overview

This guide walks you through setting up and testing the RUPAYA iOS app locally with your Docker backend running at `http://localhost:3000`.

---

## Prerequisites

### Required Software
- **Xcode 14.0+** (preferably latest version)
- **macOS Monterey 12.0+** or later
- **CocoaPods** (for dependency management)
- **Backend running** on Docker at `http://localhost:3000`

### Check Installation
```bash
# Check Xcode
xcode-select --version

# Check CocoaPods
pod --version

# If CocoaPods not installed:
sudo gem install cocoapods
```

---

## Step 1: Configure API Endpoint for Local Testing

The iOS app currently points to production (`https://api.rupaya.in`). We need to change it to your local backend.

### Option A: Quick Testing (Recommended)

Create a configuration file for environment-based API URLs:

**Create:** `ios/RUPAYA/Core/Networking/APIConfig.swift`

```swift
import Foundation

struct APIConfig {
    #if DEBUG
    static let baseURL = "http://localhost:3000"  // Local Docker
    #else
    static let baseURL = "https://api.rupaya.in"  // Production
    #endif
    
    static let apiVersion = "v1"
    
    // For iOS Simulator testing with local backend
    static var resolvedBaseURL: String {
        #if targetEnvironment(simulator)
        // Simulator can access host's localhost directly
        return baseURL
        #else
        // Physical device needs your Mac's IP address
        // Replace with your Mac's local IP (ifconfig | grep inet)
        return baseURL.replacingOccurrences(of: "localhost", with: "YOUR_MAC_IP")
        #endif
    }
}
```

### Option B: Using Scheme-Based Configuration

1. Open Xcode project
2. Product → Scheme → Edit Scheme
3. Run → Arguments → Environment Variables
4. Add: `API_BASE_URL = http://localhost:3000`

---

## Step 2: Update APIClient for Local Backend

Update the `APIClient.swift` to use local backend:

**Edit:** `ios/RUPAYA/Core/Networking/APIClient.swift`

Find line:
```swift
private let baseURL = "https://api.rupaya.in"
```

Replace with:
```swift
#if DEBUG
private let baseURL = "http://localhost:3000"
#else
private let baseURL = "https://api.rupaya.in"
#endif
```

---

## Step 3: Configure App Transport Security

iOS requires HTTPS by default. To allow HTTP connections to localhost:

**Edit:** `ios/RUPAYA/Info.plist` (or create if doesn't exist)

Add these keys:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsLocalNetworking</key>
    <true/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>localhost</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
        </dict>
    </dict>
</dict>
```

**Note:** This only allows localhost HTTP connections, keeping production secure.

---

## Step 4: Install Dependencies

```bash
cd ios

# Install CocoaPods dependencies
pod install

# If Podfile.lock exists but dependencies missing:
pod install --repo-update

# Clean install (if issues):
pod deintegrate && pod install
```

Expected output:
```
Installing dependencies...
Pod installation complete! X pods installed.
```

---

## Step 5: Open Project in Xcode

```bash
# IMPORTANT: Open .xcworkspace, NOT .xcodeproj
open RUPAYA.xcworkspace
```

Or double-click `RUPAYA.xcworkspace` in Finder.

---

## Step 6: Configure Signing & Capabilities

### For Simulator (No Apple Developer Account Needed)
1. Select project in navigator (top)
2. Select RUPAYA target
3. Signing & Capabilities tab
4. **Uncheck** "Automatically manage signing" (for local testing)
5. Team: Select "None" or your personal team

### For Physical Device (Apple Developer Account Required)
1. Same steps as above
2. Check "Automatically manage signing"
3. Team: Select your Apple Developer account
4. Bundle Identifier: Make it unique (e.g., `com.yourname.rupaya`)

---

## Step 7: Select Simulator or Device

### Simulator Testing (Easiest)
1. Top toolbar: Click device dropdown
2. Select iOS Simulator (e.g., "iPhone 15 Pro")
3. Recommended: iPhone 14 Pro or iPhone 15 Pro

### Physical Device Testing
1. Connect iPhone via USB
2. Trust computer if prompted
3. Select your device from dropdown
4. Enable Developer Mode on iPhone:
   - Settings → Privacy & Security → Developer Mode → Enable

---

## Step 8: Run the App

### Start Backend First
```bash
# In backend directory
cd /Users/rsingh/Documents/Projects/rupaya/backend
docker-compose -f docker-compose.dev.yml up -d

# Verify it's running
curl http://localhost:3000/health
```

### Build and Run iOS App

**Option 1: Xcode GUI**
1. Press `⌘ + R` (Command + R)
2. Or click ▶️ Play button in top toolbar
3. Wait for build to complete (~1-2 minutes first time)

**Option 2: Command Line**
```bash
cd ios

# List available simulators
xcrun simctl list devices available

# Build and run
xcodebuild -workspace RUPAYA.xcworkspace \
  -scheme RUPAYA \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -configuration Debug \
  build
```

---

## Step 9: Testing the App

### Initial Launch
1. App should open to **Login/Signup** screen
2. Check Xcode console for network logs

### Test Signup Flow
1. Tap "Sign Up"
2. Enter:
   - Email: `test-ios@example.com`
   - Password: `TestPass123`
   - Confirm password
3. Tap "Create Account"
4. Check Xcode console for API response

### Verify Backend Connection
In Xcode console, you should see:
```
[Network] POST http://localhost:3000/api/v1/auth/signup
[Network] Response: 200 OK
[Auth] User created: test-ios@example.com
```

### Test Login Flow
1. Use the account you just created
2. Enter credentials
3. Tap "Sign In"
4. Should navigate to Main App screen

---

## Step 10: Debug Tools

### Xcode Console Logs
- View → Debug Area → Activate Console (`⌘ + Shift + Y`)
- Watch for network requests and responses

### Network Debugging
Add to `APIClient.swift` for detailed logging:

```swift
func request<T: Decodable>(_ endpoint: String, method: String = "GET", body: Encodable? = nil) -> AnyPublisher<T, Error> {
    #if DEBUG
    print("🌐 [Network] \(method) \(baseURL)\(endpoint)")
    if let body = body {
        print("📤 [Request Body] \(body)")
    }
    #endif
    
    // ... existing code
}
```

### Xcode Debugger
- Set breakpoints: Click line number gutter
- Step through code: Debug toolbar controls
- Inspect variables: Debug area bottom panel

### Network Traffic Monitor
```bash
# Monitor backend logs while testing
docker-compose -f backend/docker-compose.dev.yml logs -f backend
```

---

## Testing Scenarios

### 1. Authentication Flow
- ✅ Signup with valid credentials
- ✅ Login with existing account
- ✅ Logout and re-login
- ✅ Invalid credentials error handling

### 2. Account Management
- ✅ Create new account (bank, cash, etc.)
- ✅ View account list
- ✅ Update account details
- ✅ Delete account

### 3. Transactions
- ✅ Add expense transaction
- ✅ Add income transaction
- ✅ View transaction history
- ✅ Filter transactions by date/category

### 4. UI/UX
- ✅ Navigation between screens
- ✅ Form validation feedback
- ✅ Loading states
- ✅ Error messages display

---

## Troubleshooting

### Issue: "Could not connect to the server"

**Solution:**
```bash
# 1. Verify backend is running
curl http://localhost:3000/health

# 2. Check iOS app is using correct URL
# Open APIClient.swift and verify baseURL = "http://localhost:3000"

# 3. Check Info.plist has NSAllowsLocalNetworking set to true
```

### Issue: "Build Failed - Missing Dependencies"

**Solution:**
```bash
cd ios
pod deintegrate
rm -rf Pods
pod install
```

### Issue: "Signing Certificate Error"

**Solution:**
1. Xcode → Preferences → Accounts
2. Add Apple ID
3. Download certificates
4. Or use "Sign to Run Locally" (Xcode 14+)

### Issue: "Simulator Not Booting"

**Solution:**
```bash
# Reset simulator
xcrun simctl shutdown all
xcrun simctl erase all

# Restart Xcode
killall Xcode
open -a Xcode
```

### Issue: Physical Device Shows "Untrusted Developer"

**Solution:**
1. iPhone Settings → General → VPN & Device Management
2. Trust your developer certificate
3. Run app again

---

## Hot Reload Development

### SwiftUI Preview
1. Open any SwiftUI view file
2. Canvas panel (right side) → Resume Preview
3. Live preview updates as you code
4. Press ▶️ in preview to interact

### Quick Rebuild
- Press `⌘ + B` to build without running
- Press `⌘ + R` to build and run
- Press `⌘ + .` to stop running app

---

## Testing on Physical iPhone

### Get Your Mac's IP Address
```bash
# Find your local IP
ifconfig | grep "inet " | grep -v 127.0.0.1

# Example output: 192.168.1.100
```

### Update App Configuration
In `APIConfig.swift`:
```swift
#if targetEnvironment(simulator)
static let baseURL = "http://localhost:3000"
#else
static let baseURL = "http://192.168.1.100:3000"  // Your Mac's IP
#endif
```

### Ensure Backend Accessible
```bash
# Backend must bind to 0.0.0.0, not 127.0.0.1
# Check docker-compose.dev.yml ports section:
# ports:
#   - "3000:3000"  # ✅ Accessible from network

# Test from another device
curl http://YOUR_MAC_IP:3000/health
```

---

## Performance Profiling

### Memory Leaks
1. Xcode → Product → Profile (`⌘ + I`)
2. Select "Leaks" instrument
3. Run app and test flows
4. Check for memory leaks

### Network Performance
1. Xcode → Debug → Network Link Conditioner
2. Simulate 3G/4G/LTE speeds
3. Test app performance

---

## Continuous Testing

### Watch Mode
Keep Xcode open with app running on simulator. Code changes can be hot-reloaded with SwiftUI previews.

### Backend + iOS Development Flow
```bash
# Terminal 1: Backend logs
cd backend
docker-compose -f docker-compose.dev.yml logs -f backend

# Terminal 2: Backend commands (if needed)
docker-compose -f docker-compose.dev.yml exec backend sh

# Xcode: iOS app development with live preview
```

---

## Quick Reference Commands

```bash
# Start backend
cd backend && docker-compose -f docker-compose.dev.yml up -d

# Check backend health
curl http://localhost:3000/health

# Install iOS dependencies
cd ios && pod install

# Open Xcode
open ios/RUPAYA.xcworkspace

# Build iOS app
xcodebuild -workspace ios/RUPAYA.xcworkspace -scheme RUPAYA -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Backend API test
curl -X POST http://localhost:3000/api/v1/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"email":"ios-test@example.com","password":"Test123","deviceId":"iphone-sim","deviceName":"iPhone Simulator"}'

# View backend logs
docker-compose -f backend/docker-compose.dev.yml logs -f backend

# Reset simulator
xcrun simctl erase all
```

---

## Next Steps After Local Testing

1. ✅ **Test all features** on simulator
2. ✅ **Test on physical device** (optional)
3. ✅ **Fix any bugs** found during testing
4. 🚀 **Deploy backend** to production
5. 📱 **Update iOS app** to use production URL
6. 🍎 **Submit to App Store** (requires Apple Developer Program)

---

## Additional Resources

- [Xcode Documentation](https://developer.apple.com/documentation/xcode)
- [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)
- [iOS Networking](https://developer.apple.com/documentation/foundation/url_loading_system)
- [TestFlight Beta Testing](https://developer.apple.com/testflight/)

---

**Status:** Ready for iOS App Testing  
**Backend:** http://localhost:3000  
**iOS Simulator:** Recommended for initial testing  
**Physical Device:** Optional, requires Developer Account  

Happy testing! 📱✨
