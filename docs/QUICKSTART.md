# RUPAYA Money Manager - Quick Start Guide

## 🚀 5-Minute Local Setup

### Prerequisites
- Node.js 18+ (`node --version`)
- Docker & Docker Compose (`docker --version`)
- Git (`git --version`)

### Step 1: Clone & Install (1 min)
```bash
git clone https://github.com/yourusername/rupaya.git
cd rupaya/backend
npm install
```

### Step 2: Start Services (1 min)
```bash
# From rupaya root directory
docker-compose up -d

# Verify services running
docker-compose ps
```

### Step 3: Setup Database (2 min)
```bash
cd backend
npm run migrate
npm run seed
```

### Step 4: Start Backend (1 min)
```bash
npm run dev
# Backend running at http://localhost:3000
# Test: curl http://localhost:3000/health
```

---

## 📱 iOS Setup

### Requirements
- macOS 12+
- Xcode 14+
- CocoaPods (`sudo gem install cocoapods`)

### Installation
```bash
cd ios
pod install
open RUPAYA.xcworkspace
```

### Configuration
1. Open `RUPAYAApp.swift`
2. Update API endpoint in `APIClient.swift`:
   ```swift
   private let baseURL = "http://localhost:3000"  // For local development
   ```

### Running
- Select simulator or device
- Press Cmd+R to build & run

---

## 🤖 Android Setup

### Requirements
- Android Studio 2022+
- Android SDK 24+ (API level)
- Kotlin 1.8+

### Installation
```bash
cd android
./gradlew build
```

### Configuration
1. Update `ApiClient.kt`:
   ```kotlin
   private const val BASE_URL = "http://10.0.2.2:3000"  // For emulator
   // OR
   private const val BASE_URL = "http://localhost:3000"  // For physical device
   ```

### Running
- Open in Android Studio
- Press Shift+F10 to build & run

---

## 🧪 Running Tests

### Backend Tests
```bash
cd backend

# Unit tests
npm test

# Integration tests
npm run test:integration

# E2E tests
npm run test:e2e

# Coverage report
npm run test:coverage
```

### Expected Results
- Unit tests: ~50 tests
- Integration tests: ~30 tests
- Coverage: >80%

---

## 📊 Testing API Endpoints

### Using cURL
```bash
# Signup
curl -X POST http://localhost:3000/api/v1/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email":"test@example.com",
    "password":"SecurePass123!",
    "deviceId":"test-device",
    "deviceName":"Test Device"
  }'

# Signin
curl -X POST http://localhost:3000/api/v1/auth/signin \
  -H "Content-Type: application/json" \
  -d '{
    "email":"test@example.com",
    "password":"SecurePass123!",
    "deviceId":"test-device"
  }'

# Create Transaction (replace TOKEN with actual JWT)
curl -X POST http://localhost:3000/api/v1/transactions \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "accountId":"account-uuid",
    "amount":500,
    "type":"expense",
    "categoryId":"category-uuid",
    "description":"Grocery shopping"
  }'
```

### Using Postman
1. Import `/docs/postman_collection.json`
2. Set `{{baseUrl}}` to `http://localhost:3000`
3. Run requests

---

## 🗂️ Project Structure

```
rupaya/
├── backend/                   # Node.js Express API
│   ├── src/
│   │   ├── app.js            # Express app setup
│   │   ├── config/           # Database config
│   │   ├── controllers/      # API controllers
│   │   ├── services/         # Business logic
│   │   ├── models/           # Data models
│   │   ├── middleware/       # Auth, validation, etc
│   │   ├── routes/           # API routes
│   │   └── utils/            # Helpers, logger
│   ├── migrations/           # Database migrations
│   ├── __tests__/            # Test files
│   ├── .env.example          # Environment template
│   ├── package.json
│   └── docker-compose.yml
│
├── ios/                       # iOS app (SwiftUI)
│   ├── RUPAYA/
│   │   ├── App/              # Entry point
│   │   ├── Features/         # Feature modules
│   │   ├── Core/             # Shared utilities
│   │   └── Models/           # Data models
│   └── Podfile               # CocoaPods dependencies
│
├── android/                   # Android app (Kotlin)
│   ├── app/
│   │   ├── src/main/
│   │   │   ├── kotlin/       # Kotlin source
│   │   │   └── res/          # Resources
│   │   └── build.gradle.kts  # Dependencies
│   └── build.gradle.kts      # Project config
│
└── docs/                      # Documentation
    ├── API_DOCUMENTATION.md
    ├── DEPLOYMENT.md
    └── SECURITY.md
```

---

## 🔑 Environment Variables

### Backend (.env)
```env
# Server
PORT=3000
NODE_ENV=development

# Database
DB_HOST=localhost
DB_PORT=5432
DB_USER=rupaya
DB_PASSWORD=secure_password_here
DB_NAME=rupaya_dev

# Auth
JWT_SECRET=your_secret_key_min_32_chars_long
REFRESH_TOKEN_SECRET=your_refresh_secret_min_32_chars_long

# Redis
REDIS_URL=redis://localhost:6379

# AWS (optional for local dev)
AWS_REGION=ap-south-1
AWS_ACCESS_KEY_ID=your_key_here
AWS_SECRET_ACCESS_KEY=your_secret_here

# Encryption
ENCRYPTION_KEY=your_encryption_key_min_32_chars_long

# Logging
LOG_LEVEL=info
DEBUG=rupaya:*
```

---

## 🐛 Troubleshooting

### Port Already in Use
```bash
# Port 3000 already in use
lsof -i :3000
kill -9 <PID>

# Or use different port
PORT=3001 npm run dev
```

### Database Connection Error
```bash
# Check PostgreSQL running
docker-compose ps

# Restart services
docker-compose restart postgres

# Check logs
docker-compose logs postgres
```

### Redis Connection Error
```bash
# Check Redis running
docker-compose ps redis

# Verify connectivity
redis-cli -h localhost ping
# Should return: PONG
```

### iOS Build Fails
```bash
# Clear pods
rm -rf ios/Pods ios/Podfile.lock

# Reinstall
cd ios && pod install
```

### Android Build Fails
```bash
# Clean build
./gradlew clean

# Rebuild
./gradlew build
```

---

## 📈 Production Deployment

### AWS Deployment
```bash
cd terraform

# Initialize Terraform
terraform init

# Plan deployment
terraform plan -var-file="prod.tfvars"

# Apply infrastructure
terraform apply -var-file="prod.tfvars"

# Get outputs (API endpoint, DB endpoint, etc)
terraform output
```

### Docker Deployment
```bash
# Build image
docker build -t rupaya:latest -f backend/Dockerfile ./backend

# Run container
docker run -p 3000:3000 \
  -e DB_HOST=your-rds-endpoint \
  -e DB_PASSWORD=your-password \
  -e JWT_SECRET=your-secret \
  rupaya:latest
```

### GitHub Actions CI/CD
1. Push to `main` branch
2. Automated tests run
3. Docker image built & pushed to ECR
4. Deployed to ECS automatically
5. Monitor at CloudWatch

---

## 📚 Documentation Files

| File | Purpose |
|------|---------|
| `API_DOCUMENTATION.md` | Complete API reference |
| `DEPLOYMENT.md` | Step-by-step deployment guide |
| `SECURITY.md` | Security best practices |
| `ARCHITECTURE.md` | System design & decisions |
| `TESTING.md` | Testing strategy & setup |

---

## 🤝 Contributing

1. Create feature branch: `git checkout -b feature/your-feature`
2. Make changes & test: `npm test`
3. Commit: `git commit -am 'Add feature'`
4. Push: `git push origin feature/your-feature`
5. Create Pull Request

### Code Style
- Use ESLint for JavaScript
- Use ktlint for Kotlin
- Use SwiftLint for Swift
- Run linter before committing

---

## 📞 Support

- **Issues**: GitHub Issues
- **Discussions**: GitHub Discussions
- **Email**: support@rupaya.com
- **Slack**: #rupaya-dev

---

## 📄 License

RUPAYA is licensed under MIT License. See LICENSE file for details.

---

## 🎯 Next Steps

1. ✅ Clone & setup locally
2. ✅ Run backend tests
3. ✅ Explore API with cURL/Postman
4. ✅ Build & run iOS app
5. ✅ Build & run Android app
6. ✅ Review architecture diagrams
7. ✅ Read security documentation
8. ✅ Deploy to AWS (optional)

**Happy coding! 🚀**
