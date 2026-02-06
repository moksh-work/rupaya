# RUPAYA Money Manager - API Documentation

Professional API documentation for the RUPAYA Money Manager backend services.

## 📚 Documentation Formats

We provide three comprehensive documentation formats to suit different needs:

### 1. **Swagger/OpenAPI** (Interactive Documentation)
- **File**: `swagger.yaml`
- **Purpose**: Interactive API documentation with live testing
- **Best for**: Developers exploring the API, understanding request/response structures
- **Access**: 
  - View the YAML file directly
  - Host with Swagger UI (see setup below)
  - Import into Swagger Editor: https://editor.swagger.io/

### 2. **Postman Collection** (Testing & Development)
- **Files**: 
  - `postman_collection.json` - Complete API collection
  - `postman_environment_local.json` - Local development environment
  - `postman_environment_staging.json` - Staging environment
  - `postman_environment_production.json` - Production environment
- **Purpose**: Ready-to-use API testing tool with automated scripts
- **Best for**: QA testing, development, team collaboration
- **Features**:
  - Pre-configured requests for all 62 endpoints
  - Automatic token management (saves tokens after login)
  - Environment variables for easy switching
  - Example request bodies

### 3. **Markdown Documentation** (Reference)
- **Files**: 
  - `DATABASE_SCHEMA.md` - Complete database structure
  - `docs/API_DOCUMENTATION.md` - General API reference
- **Purpose**: Detailed technical documentation and reference
- **Best for**: Understanding system architecture, database design

---

## 🚀 Quick Start

### Option 1: Postman (Recommended for Testing)

1. **Install Postman**: Download from [postman.com](https://www.postman.com/downloads/)

2. **Import Collection**:
   - Open Postman
   - Click "Import" button
   - Select `postman_collection.json`
   - Click "Import"

3. **Import Environment**:
   - Click gear icon (⚙️) in top right
   - Click "Import"
   - Select `postman_environment_local.json` (or staging/production)
   - Select the environment from the dropdown

4. **Start Testing**:
   - Navigate to "Authentication" folder
   - Run "Sign Up" or "Sign In" request
   - Token will be automatically saved
   - All other requests will use the saved token

### Option 2: Swagger UI (Interactive Docs)

1. **Install Dependencies**:
```bash
npm install swagger-ui-express yamljs
```

2. **Add to your Express app** (`src/app.js`):
```javascript
const swaggerUi = require('swagger-ui-express');
const YAML = require('yamljs');

const swaggerDocument = YAML.load('./swagger.yaml');

app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument));
```

3. **Access Documentation**:
   - Start your server: `npm start`
   - Visit: http://localhost:3000/api-docs
   - Click "Authorize" button to add your Bearer token

### Option 3: Manual API Calls

Using curl or any HTTP client:

```bash
# Sign In
curl -X POST http://localhost:3000/api/v1/auth/signin \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"password123"}'

# Use the returned token
TOKEN="your_access_token_here"

# Get Expenses
curl http://localhost:3000/api/v1/expenses \
  -H "Authorization: Bearer $TOKEN"
```

---

## 📖 API Overview

### Base URL
```
Local:      http://localhost:3000/api/v1
Staging:    https://staging-api.rupaya.com/api/v1
Production: https://api.rupaya.com/api/v1
```

### Authentication
All protected endpoints require a Bearer token:
```
Authorization: Bearer YOUR_ACCESS_TOKEN
```

Get your token by calling `/auth/signin` or `/auth/signup`.

---

## 🗂️ API Categories

### 1. **Authentication** (3 endpoints)
- Sign Up - Create new user account
- Sign In - Login and get access token
- Refresh Token - Get new access token

### 2. **Expenses** (7 endpoints)
- Create, Read, Update, Delete expenses
- Get expense statistics
- Export expenses to CSV/PDF
- Filter by date range and category

### 3. **Income** (6 endpoints)
- Manage income entries
- Track income sources
- Get income statistics
- Support for recurring income

### 4. **Budgets** (7 endpoints)
- Create and manage budgets
- Track budget progress
- Set alert thresholds
- Compare budget periods

### 5. **Reports** (8 endpoints)
- Dashboard overview
- Spending trends
- Category analysis
- Monthly/Annual reports
- Income vs Expense comparison
- Goals progress tracking

### 6. **Bank Integration** (8 endpoints)
- Connect bank accounts (Plaid, Yodlee, etc.)
- Sync transactions automatically
- Categorize bank transactions
- Track account balances

### 7. **Investments** (5 endpoints)
- Track stocks, bonds, crypto, etc.
- Portfolio summary with gains/losses
- Support for 8 investment types
- Current vs purchase price tracking

### 8. **Notifications** (6 endpoints)
- List notifications
- Mark as read/unread
- Manage notification preferences
- Quiet hours support

### 9. **Settings** (5 endpoints)
- User preferences (theme, language, currency)
- Security settings (2FA, biometric)
- Data export (GDPR compliance)
- Request data access

### 10. **Categories** (6 endpoints)
- Manage expense/income categories
- Custom categories with colors and icons
- Category statistics

---

## 🔐 Security

- **JWT Authentication**: Secure token-based auth with refresh tokens
- **Rate Limiting**: Prevents abuse
- **Input Validation**: All inputs validated with express-validator
- **SQL Injection Protection**: Parameterized queries
- **Password Hashing**: bcrypt with salt rounds
- **HTTPS Only**: Production endpoints enforce HTTPS

---

## 📊 Response Format

All API responses follow this structure:

**Success Response:**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": {
    // Response data here
  }
}
```

**Error Response:**
```json
{
  "success": false,
  "message": "Error description",
  "errors": [
    {
      "field": "email",
      "message": "Invalid email format"
    }
  ]
}
```

---

## 🧪 Testing Workflow

### Using Postman:

1. **Setup**:
   - Import collection and environment
   - Select environment (Local/Staging/Production)

2. **Authentication**:
   - Run "Sign Up" or "Sign In" request
   - Token is automatically saved

3. **Test Endpoints**:
   - All requests use the saved token automatically
   - Modify request bodies as needed
   - Check response status and data

4. **Environment Switching**:
   - Select different environment from dropdown
   - Same requests work across all environments

### Example Test Flow:

```
1. Sign In → Get token (auto-saved)
2. Create Expense → Returns expense ID
3. List Expenses → See your expense
4. Get Expense Statistics → View aggregated data
5. Create Budget → Set spending limits
6. Get Budget Progress → Check against expenses
7. Get Dashboard Report → Full overview
```

---

## 🌍 Environment Variables

Required for running the API:

```env
# Server
PORT=3000
NODE_ENV=development

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=rupaya_db
DB_USER=rupaya_app
DB_PASSWORD=your_secure_password

# JWT
JWT_SECRET=your_jwt_secret_key_min_32_chars
JWT_REFRESH_SECRET=your_refresh_secret_key
JWT_EXPIRES_IN=1h
JWT_REFRESH_EXPIRES_IN=7d

# Bank Integration
PLAID_CLIENT_ID=your_plaid_client_id
PLAID_SECRET=your_plaid_secret
PLAID_ENV=sandbox

# Optional
LOG_LEVEL=info
RATE_LIMIT_WINDOW=15m
RATE_LIMIT_MAX=100
```

---

## 📝 Database Schema

Complete database documentation available in `DATABASE_SCHEMA.md`.

**Key Tables:**
- users, accounts, categories
- transactions, expenses, income
- budgets, bank_accounts, investments
- notifications, user_settings
- audit_logs (for compliance)

**Features:**
- 20 tables with foreign key relationships
- 50+ indexes for performance
- 3 materialized views for reporting
- Soft-delete support
- Automatic timestamps
- JSONB for flexible data

---

## 🛠️ Development Setup

1. **Install Dependencies**:
```bash
cd backend
npm install
```

2. **Setup Database**:
```bash
chmod +x scripts/setup-database.sh
./scripts/setup-database.sh
```

3. **Configure Environment**:
```bash
cp .env.example .env
# Edit .env with your values
```

4. **Start Server**:
```bash
npm run dev  # Development with hot reload
npm start    # Production
```

5. **Access API**:
   - API: http://localhost:3000/api/v1
   - Swagger UI: http://localhost:3000/api-docs (if configured)

---

## 📦 Deployment

### Docker Support:
```bash
docker-compose up -d
```

### Manual Deployment:
1. Set production environment variables
2. Run database migrations
3. Build and start application
4. Configure reverse proxy (nginx)
5. Enable HTTPS with SSL certificate

See `docs/DEPLOYMENT.md` for detailed instructions.

---

## 🤝 Team Collaboration

### For Developers:
- Use Swagger UI for interactive exploration
- Review Markdown docs for architecture understanding
- Check `DATABASE_SCHEMA.md` for data structures

### For QA/Testing:
- Import Postman collection
- Use environment variables for different test environments
- Create test suites using collection runner

### For Frontend Developers:
- Swagger provides request/response schemas
- Postman examples show real usage
- All endpoints have validation rules documented

---

## 🔄 API Versioning

Current version: **v1**

All endpoints are prefixed with `/api/v1/`

Future versions will be introduced as `/api/v2/` without breaking existing integrations.

---

## 📞 Support

For questions or issues:
- Check Swagger documentation first
- Review example requests in Postman
- Consult `DATABASE_SCHEMA.md` for data questions
- Contact: dev@rupaya.com

---

## 📄 License

MIT License - See LICENSE file for details

---

**Happy Testing! 🚀**

---

## Appendix: Complete Endpoint List

### Authentication
- `POST /auth/signup` - Create account
- `POST /auth/signin` - Login
- `POST /auth/refresh` - Refresh token

### Expenses
- `POST /expenses` - Create expense
- `GET /expenses` - List expenses
- `GET /expenses/:id` - Get expense
- `PUT /expenses/:id` - Update expense
- `DELETE /expenses/:id` - Delete expense
- `GET /expenses/statistics` - Get statistics
- `GET /expenses/export` - Export to CSV/PDF

### Income
- `POST /income` - Create income
- `GET /income` - List income
- `GET /income/:id` - Get income
- `PUT /income/:id` - Update income
- `DELETE /income/:id` - Delete income
- `GET /income/statistics` - Get statistics

### Budgets
- `POST /budgets` - Create budget
- `GET /budgets` - List budgets
- `GET /budgets/:id` - Get budget
- `PUT /budgets/:id` - Update budget
- `DELETE /budgets/:id` - Delete budget
- `GET /budgets/:id/progress` - Get progress
- `GET /budgets/comparison` - Compare periods

### Reports
- `GET /reports/dashboard` - Dashboard overview
- `GET /reports/trends` - Spending trends
- `GET /reports/category-spending` - Category analysis
- `GET /reports/monthly` - Monthly report
- `GET /reports/annual` - Annual report
- `GET /reports/goals-progress` - Goals tracking
- `GET /reports/income-vs-expense` - Income vs Expense
- `GET /reports/comparison` - Period comparison

### Banks
- `POST /banks/connect` - Connect bank
- `POST /banks/callback` - OAuth callback
- `GET /banks/accounts` - List accounts
- `POST /banks/accounts/:id/sync` - Sync transactions
- `GET /banks/accounts/:id/transactions` - Get transactions
- `PUT /banks/transactions/:id/category` - Categorize
- `DELETE /banks/accounts/:id` - Disconnect
- `GET /banks/accounts/:id/balance` - Get balance

### Investments
- `POST /investments` - Add investment
- `GET /investments` - List investments
- `GET /investments/portfolio` - Portfolio summary
- `PUT /investments/:id` - Update investment
- `DELETE /investments/:id` - Delete investment

### Notifications
- `GET /notifications` - List notifications
- `PUT /notifications/:id/read` - Mark as read
- `PUT /notifications/mark-all-read` - Mark all as read
- `DELETE /notifications/:id` - Delete notification
- `GET /notifications/preferences` - Get preferences
- `PUT /notifications/preferences` - Update preferences

### Settings
- `GET /settings` - Get settings
- `PUT /settings` - Update settings
- `GET /settings/security` - Get security settings
- `POST /settings/export-data` - Export user data
- `POST /settings/request-data-access` - Request data access

### Categories
- `GET /categories` - List categories
- `POST /categories` - Create category
- `GET /categories/:id` - Get category
- `PUT /categories/:id` - Update category
- `DELETE /categories/:id` - Delete category
- `GET /categories/:id/statistics` - Category stats

**Total: 62 Endpoints** ✅
