# RUPAYA Money Manager

A comprehensive, secure, and feature-rich money management application for iOS and Android with a robust Node.js backend.

## 🚀 Features

- **Secure Authentication**: Email/password with MFA support, biometric authentication
- **Transaction Management**: Track income, expenses, and transfers
- **Budget Planning**: Set and monitor budgets by category
- **Analytics**: Comprehensive financial insights and reports
- **Multi-Currency**: Support for multiple currencies
- **Cloud Sync**: Real-time sync across devices
- **Bank-Level Security**: End-to-end encryption, certificate pinning

## 📁 Project Structure

```
rupaya/
├── backend/          # Node.js + Express + PostgreSQL
├── ios/              # iOS app (SwiftUI)
├── android/          # Android app (Kotlin + Jetpack Compose)
└── docs/             # Documentation
```

## 🔧 Quick Start

### Backend

```bash
cd backend
npm install
cp .env.example .env
# Configure .env with your settings
docker-compose up -d
npm run migrate
npm run dev
```

### iOS

```bash
cd ios
pod install
open RUPAYA.xcworkspace
# Build and run in Xcode
```

### Android

```bash
cd android
./gradlew assembleDebug
# Open in Android Studio and run
```

## 📚 Documentation

- [API Documentation](docs/API_DOCUMENTATION.md)
- [Deployment Guide](docs/DEPLOYMENT.md)
- [Security Guidelines](docs/SECURITY.md)

## 🔐 Security

- Password entropy checking (min 50 bits)
- HaveIBeenPwned integration
- Multi-factor authentication (TOTP)
- Biometric authentication support
- Certificate pinning
- Encrypted storage (Keychain/EncryptedSharedPreferences)
- JWT with 15-minute access tokens
- Progressive account lockout

## 🛠️ Tech Stack

**Backend:**
- Node.js + Express
- PostgreSQL 15
- Redis
- JWT Authentication
- AWS S3 (backups)

**iOS:**
- SwiftUI
- Combine
- LocalAuthentication (Face ID/Touch ID)
- URLSession with certificate pinning

**Android:**
- Kotlin
- Jetpack Compose
- Hilt (DI)
- Retrofit + OkHttp
- BiometricPrompt
- EncryptedSharedPreferences

## 📱 Requirements

**Backend:**
- Node.js 18+
- PostgreSQL 15+
- Redis 7+

**iOS:**
- iOS 16.0+
- Xcode 15+
- CocoaPods

**Android:**
- Android 7.0+ (API 24)
- Android Studio Hedgehog+
- Gradle 8.0+

## 🚀 Deployment

See [DEPLOYMENT.md](docs/DEPLOYMENT.md) for detailed deployment instructions.

## 📄 License

Proprietary - All rights reserved

## 👥 Team

Built with ❤️ for financial freedom

## 🐛 Bug Reports

Please report security issues to: security@rupaya.in

## 📮 Contact

- Website: https://rupaya.in
- Email: support@rupaya.in
- Twitter: @RupayaApp
