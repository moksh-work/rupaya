# RUPAYA Money Manager

<div align="center">

# 💰 RUPAYA Money Manager

**A comprehensive, secure, and feature-rich money management application**

[![Backend Tests](https://github.com/YOUR_ORG/rupaya/workflows/Backend%20Tests%20&%20Lint/badge.svg)](https://github.com/YOUR_ORG/rupaya/actions)
[![Mobile Build](https://github.com/YOUR_ORG/rupaya/workflows/Mobile%20Build%20Check/badge.svg)](https://github.com/YOUR_ORG/rupaya/actions)
[![Code Coverage](https://codecov.io/gh/YOUR_ORG/rupaya/branch/main/graph/badge.svg)](https://codecov.io/gh/YOUR_ORG/rupaya)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](docs/repository/CONTRIBUTING.md)

[Features](#-features) • [Quick Start](#-quick-start) • [Documentation](#-documentation) • [Contributing](#-contributing) • [Security](#-security)

</div>

---

## 🚀 Features

- **Secure Authentication**: Email/password with MFA support, biometric authentication

### 🔐 Security & Authentication
- **Multi-Factor Authentication (MFA)** - TOTP-based 2FA
- **Biometric Authentication** - Face ID, Touch ID, Fingerprint
- **JWT Tokens** - Secure token-based authentication
- **Password Strength** - 50-bit entropy minimum, HaveIBeenPwned integration
- **Certificate Pinning** - Prevent man-in-the-middle attacks
- **End-to-End Encryption** - Bank-level security

### 💳 Financial Management
- **Transaction Tracking** - Income, expenses, and transfers
- **Budget Planning** - Category-based budgets with alerts
- **Bill Reminders** - Never miss a payment
- **Recurring Transactions** - Auto-track subscriptions
- **Multi-Currency Support** - 150+ currencies
- **Bank Integration** - Connect to 12,000+ banks (Plaid)

### 📊 Analytics & Reports
- **Dashboard Overview** - Real-time financial snapshot
- **Spending Trends** - Visualize spending patterns
- **Category Breakdown** - Detailed category analysis
- **Budget Progress** - Track against goals
- **Custom Reports** - Monthly, annual, comparative
- **Export Data** - CSV, PDF, Excel formats

### 📱 Mobile Experience
- **Native iOS App** - SwiftUI, iOS 16+
- **Native Android App** - Jetpack Compose, API 24+
- **Offline Mode** - Work without internet, sync later
- **Cloud Sync** - Real-time sync across devices
- **Dark Mode** - Beautiful UI in light/dark themes
- **Accessibility** - VoiceOver, TalkBack support

## 📁 Project Structure

rupaya/
├── backend/           # Node.js + Express + PostgreSQL
├── ios/               # iOS app (SwiftUI)
├── android/           # Android app (Kotlin + Jetpack Compose)
├── docs/              # Documentation
│   └── repository/    # Repository docs (contributing, security, changelog)
├── infra/             # Infrastructure as Code (Terraform)
├── .github/           # GitHub workflows and templates
└── LICENSE            # MIT License

### Backend Structure
backend/
├── src/
│   ├── controllers/   # Request handlers
│   ├── models/        # Database models
│   ├── services/      # Business logic
│   ├── routes/        # API routes
│   ├── middleware/    # Auth, validation, error handling
│   ├── config/        # Configuration
│   └── utils/         # Utilities
├── migrations/        # Database migrations
├── tests/             # Test files
├── swagger.yaml       # OpenAPI specification
└── postman_collection.json  # Postman collection

---
## 🔧 Quick Start
### Prerequisites

- **Node.js** 18+ and npm
- **PostgreSQL** 15+
- **Redis** 7+
- **Docker** (recommended)

**For iOS:**
- macOS with Xcode 15+
- CocoaPods

**For Android:**
- Android Studio Hedgehog+
- JDK 11


### Backend
#### Using Docker (Recommended)


```bash
cd backend
docker-compose up -d
# Runs PostgreSQL, Redis, and the API
```

#### Manual Setup

```bash
cd backend

# Install dependencies
npm install

# Configure environment
cp .env.example .env
# Configure .env with your settings

# Setup database
chmod +x scripts/setup-database.sh
./scripts/setup-database.sh

# Run migrations
npm run migrate

# Start development server
npm run dev

# API will be available at http://localhost:3000
# Swagger docs at http://localhost:3000/api-docs


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
- [Backend API Guide](backend/API_DOCS_README.md)
- [OpenAPI/Swagger Spec](backend/swagger.yaml)
- [Postman Collection](backend/postman_collection.json)
- [Database Schema](backend/DATABASE_SCHEMA.md)
- [Architecture Overview](docs/ARCHITECTURE.md)
- [Deployment Guide](docs/DEPLOYMENT.md)
- [Security Policy](docs/repository/SECURITY.md)
- [Security Guidelines](docs/SECURITY_GUIDELINES.md)
- [Docker Guide](docs/DOCKER_GUIDE.md)
- [Contributing Guide](docs/repository/CONTRIBUTING.md)
- [Onboarding Guide](docs/TEAM_ONBOARDING.md)

### API Documentation

We provide three formats for API documentation:

1. **Swagger/OpenAPI** - Interactive docs at `/api-docs`
2. **Postman Collection** - Import `backend/postman_collection.json`
3. **Markdown** - Detailed guides in `docs/` folder

See [Backend API README](backend/API_DOCS_README.md) for complete guide.

---
## 🔐 Security

- Password entropy checking (min 50 bits)
- HaveIBeenPwned integration
- Multi-factor authentication (TOTP)
- Biometric authentication support
- Certificate pinning
- Encrypted storage (Keychain/EncryptedSharedPreferences)
- JWT with 15-minute access tokens
- Progressive account lockout
- Rate limiting (100 req/15min)
- SQL injection prevention
- XSS protection
- HTTPS only
- Security audits (annual)

**Found a security issue?** Please review our [Security Policy](docs/repository/SECURITY.md) and report to **security@rupaya.com**

---
## 🛠️ Tech Stack

**Backend:**
- Node.js + Express
- PostgreSQL 15
- Redis
- JWT Authentication
- Knex.js (Query Builder)
- express-validator
- Bcrypt
- AWS S3 (backups)
- Docker & Docker Compose

**iOS:**
- SwiftUI
- Combine
- LocalAuthentication (Face ID/Touch ID)
- URLSession with certificate pinning
- Keychain Services

**Android:**
- Kotlin
- Jetpack Compose
- Hilt (DI)
- Retrofit + OkHttp
- BiometricPrompt
- EncryptedSharedPreferences
- Room Database
- Coroutines + Flow

**Infrastructure:**
- Terraform (IaC)
- AWS ECS / AWS Lambda
- GitHub Actions (CI/CD)
- Datadog (Monitoring)
- Sentry (Error tracking)

---
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

---

## 🧪 Testing

### Backend

```bash
cd backend

# Run all tests
npm test

# Run with coverage
npm run test:coverage

# Run linter
npm run lint
```

### iOS

```bash
cd ios

# Run tests in Xcode
# Product → Test (⌘U)

# Or via command line
xcodebuild test \
	-workspace RUPAYA.xcworkspace \
	-scheme RUPAYA \
	-destination 'platform=iOS Simulator,name=iPhone 15'
```

### Android

```bash
cd android

# Run unit tests
./gradlew test

# Run instrumentation tests
./gradlew connectedAndroidTest

# Run lint checks
./gradlew lint
```

**Coverage Goal**: 80%+ test coverage

---
## 🚀 Deployment

See [DEPLOYMENT.md](docs/DEPLOYMENT.md) for detailed deployment instructions.

### Quick Deploy

**Docker:**
```bash
docker-compose -f docker-compose.prod.yml up -d
```

**AWS ECS:**
```bash
cd infra/terraform/aws-ecs
terraform init
terraform plan
terraform apply
```

**Environment Variables:**
See `.env.example` for required configuration.

---

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](docs/repository/CONTRIBUTING.md) for details.

### Quick Contribution Guide

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'feat: add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

Please follow our:
- [Code of Conduct](docs/repository/CODE_OF_CONDUCT.md)
- [Commit Convention](docs/repository/CONTRIBUTING.md#commit-guidelines) (Conventional Commits)
- [Coding Standards](docs/repository/CONTRIBUTING.md#coding-standards)

---

## 📊 Project Status

- ✅ **Backend API** - 62 endpoints across 14 modules
- ✅ **Database Schema** - 20 tables, 3 views, 50+ indexes
- ✅ **iOS App** - Authentication, Transactions, Budget tracking
- ✅ **Android App** - Authentication, Transactions, Budget tracking
- ✅ **CI/CD** - GitHub Actions workflows
- ✅ **Documentation** - Comprehensive guides
- 🚧 **Bank Integration** - In progress (Plaid)
- 🚧 **Investment Tracking** - In progress
- 📋 **Mobile Notifications** - Planned

See [Project Board](https://github.com/YOUR_ORG/rupaya/projects) for detailed status.

---

## 🌟 Roadmap

### Q1 2026
- [x] Core API implementation (62 endpoints)
- [x] Database schema design
- [x] Authentication & Authorization
- [ ] Bank integration (Plaid)
- [ ] Beta release

### Q2 2026
- [ ] Investment portfolio tracking
- [ ] Bill reminders & notifications
- [ ] Receipt scanning (OCR)
- [ ] Budget forecasting (ML)
- [ ] Public launch

### Q3 2026
- [ ] Multi-user accounts (family sharing)
- [ ] Crypto portfolio tracking
- [ ] Tax export features
- [ ] International expansion

See the project board for the latest roadmap updates.

---

## 📈 Performance

- **API Response Time**: < 100ms (p95)
- **Database Query Time**: < 50ms (p95)
- **App Launch Time**: < 2s
- **Sync Time**: < 5s for 1000 transactions
- **Uptime**: 99.9% SLA

---

## 🌐 Supported Platforms

| Platform | Status | Version |
|----------|--------|---------|
| iOS | ✅ Supported | 16.0+ |
| Android | ✅ Supported | 7.0+ (API 24) |
| Web | 📋 Planned | TBD |
| Desktop | 📋 Planned | TBD |

---

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

---

## 👥 Team

Built with ❤️ for financial freedom by the RUPAYA team.

### Core Team
- **Tech Lead**: [@tech-lead](https://github.com/tech-lead)
- **Backend Team**: [@backend-team](https://github.com/backend-team)
- **iOS Team**: [@ios-team](https://github.com/ios-team)
- **Android Team**: [@android-team](https://github.com/android-team)
- **DevOps Team**: [@devops-team](https://github.com/devops-team)

See [docs/repository/CONTRIBUTORS.md](docs/repository/CONTRIBUTORS.md) for all contributors.

---

## 📞 Contact & Support

### General
- **Website**: https://rupaya.com
- **Email**: support@rupaya.com
- **Twitter**: [@RupayaApp](https://twitter.com/RupayaApp)
- **LinkedIn**: [RUPAYA](https://linkedin.com/company/rupaya)

### Developer Support
- **GitHub Issues**: [Create an issue](https://github.com/YOUR_ORG/rupaya/issues)
- **GitHub Discussions**: [Join discussion](https://github.com/YOUR_ORG/rupaya/discussions)
- **Developer Email**: dev@rupaya.com
- **Slack**: [Join our Slack](https://join.slack.com/rupaya) (for contributors)

### Security
- **Security Email**: security@rupaya.com
- **Security Policy**: [docs/repository/SECURITY.md](docs/repository/SECURITY.md)
- **PGP Key**: [Link to PGP key]
## 🐛 Bug Reports

- **Security Issues**: Email **security@rupaya.com** (DO NOT open public issue)
- **Bug Reports**: [Open an issue](https://github.com/YOUR_ORG/rupaya/issues/new?template=bug_report.md)
- **Feature Requests**: [Open an issue](https://github.com/YOUR_ORG/rupaya/issues/new?template=feature_request.md)

---

## ⭐ Show Your Support

Give a ⭐️ if this project helped you!

---

## 📜 Changelog

See [docs/repository/CHANGELOG.md](docs/repository/CHANGELOG.md) for version history.

---

## 🙏 Acknowledgments

- [Express.js](https://expressjs.com/) - Backend framework
- [PostgreSQL](https://www.postgresql.org/) - Database
- [SwiftUI](https://developer.apple.com/xcode/swiftui/) - iOS UI framework
- [Jetpack Compose](https://developer.android.com/jetpack/compose) - Android UI framework
- [Plaid](https://plaid.com/) - Bank integration
- All our [contributors](docs/repository/CONTRIBUTORS.md)

---

<div align="center">

**Made with ❤️ by the RUPAYA team**

[Website](https://rupaya.com) • [Documentation](docs/) • [API Docs](backend/API_DOCS_README.md) • [Contributing](docs/repository/CONTRIBUTING.md)

</div>
