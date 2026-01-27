# RUPAYA Backend API Documentation

## Base URL
```
http://localhost:3000/api/v1
```

## Authentication
All protected endpoints require a JWT token in the `Authorization` header:
```
Authorization: Bearer <access_token>
```

---

## 🔐 Authentication Endpoints

### 1. Sign Up
**POST** `/auth/signup`

Create a new user account.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "SecurePass123!",
  "deviceId": "device-uuid",
  "deviceName": "iPhone 15"
}
```

**Response:** `201 Created`
```json
{
  "userId": "550e8400-e29b-41d4-a716-446655440000",
  "accessToken": "eyJhbGc...",
  "refreshToken": "eyJhbGc...",
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "user@example.com",
    "name": "user",
    "currency": "INR",
    "timezone": "Asia/Kolkata",
    "theme": "system",
    "language": "en"
  }
}
```

**Errors:**
- `400` - Invalid input or user already exists
- `400` - Password is too weak
- `400` - Password has been breached

---

### 2. Sign In
**POST** `/auth/signin`

Authenticate user and get tokens.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "SecurePass123!",
  "deviceId": "device-uuid"
}
```

**Response:** `200 OK`
```json
{
  "userId": "550e8400-e29b-41d4-a716-446655440000",
  "accessToken": "eyJhbGc...",
  "refreshToken": "eyJhbGc...",
  "user": { ... },
  "mfaRequired": false
}
```

**Errors:**
- `401` - Invalid email or password
- `401` - Account temporarily locked

---

### 3. Refresh Token
**POST** `/auth/refresh`

Get a new access token using refresh token.

**Request:**
```json
{
  "refreshToken": "eyJhbGc..."
}
```

**Response:** `200 OK`
```json
{
  "accessToken": "eyJhbGc...",
  "refreshToken": "eyJhbGc..."
}
```

**Errors:**
- `401` - Invalid refresh token

---

### 4. Setup MFA
**POST** `/auth/mfa/setup`

Initialize multi-factor authentication (requires auth token).

**Request Headers:**
```
Authorization: Bearer <access_token>
```

**Response:** `200 OK`
```json
{
  "secret": "JBSWY3DPEBLW64TMMQ======",
  "qrCode": "data:image/png;base64,...",
  "backupCodes": [
    "ABC12345",
    "DEF67890",
    ...
  ]
}
```

---

### 5. Verify MFA
**POST** `/auth/mfa/verify`

Verify MFA token and get new tokens.

**Request:**
```json
{
  "token": "123456",
  "deviceId": "device-uuid"
}
```

**Response:** `200 OK`
```json
{
  "accessToken": "eyJhbGc...",
  "refreshToken": "eyJhbGc..."
}
```

**Errors:**
- `400` - Invalid MFA token

---

## 💰 Account Endpoints

### 1. List Accounts
**GET** `/accounts`

Get all accounts for the authenticated user.

**Query Parameters:** None

**Response:** `200 OK`
```json
[
  {
    "account_id": "550e8400-e29b-41d4-a716-446655440000",
    "user_id": "550e8400-e29b-41d4-a716-446655440001",
    "name": "Checking Account",
    "account_type": "bank",
    "currency": "INR",
    "current_balance": 50000.00,
    "is_default": true,
    "icon": "bank",
    "color": "#3B82F6",
    "created_at": "2026-01-27T10:00:00Z",
    "updated_at": "2026-01-27T10:00:00Z"
  }
]
```

---

### 2. Create Account
**POST** `/accounts`

Create a new account.

**Request:**
```json
{
  "name": "Savings Account",
  "account_type": "savings",
  "currency": "INR",
  "current_balance": 0,
  "is_default": false,
  "icon": "piggy-bank",
  "color": "#10B981"
}
```

**Response:** `201 Created`
```json
{
  "account_id": "550e8400-e29b-41d4-a716-446655440000",
  "user_id": "550e8400-e29b-41d4-a716-446655440001",
  "name": "Savings Account",
  "account_type": "savings",
  ...
}
```

**Valid account_types:**
- `cash`
- `bank`
- `credit_card`
- `investment`
- `savings`

---

### 3. Update Account
**PUT** `/accounts/:accountId`

Update account details.

**Request:**
```json
{
  "name": "Primary Savings",
  "current_balance": 100000,
  "is_default": true
}
```

**Response:** `200 OK`
```json
{ ... updated account ... }
```

---

### 4. Delete Account
**DELETE** `/accounts/:accountId`

Delete an account.

**Response:** `200 OK`
```json
{
  "success": true
}
```

---

## 💳 Transaction Endpoints

### 1. List Transactions
**GET** `/transactions`

Get transactions for the authenticated user.

**Query Parameters:**
- `accountId` (optional) - UUID
- `categoryId` (optional) - UUID
- `type` (optional) - `income`, `expense`, or `transfer`
- `startDate` (optional) - ISO 8601 date
- `endDate` (optional) - ISO 8601 date
- `limit` (optional) - Default: 100, Max: 500
- `offset` (optional) - Default: 0

**Example:**
```
GET /transactions?accountId=550e8400-e29b-41d4-a716-446655440000&type=expense&limit=50&offset=0
```

**Response:** `200 OK`
```json
[
  {
    "transaction_id": "550e8400-e29b-41d4-a716-446655440000",
    "user_id": "550e8400-e29b-41d4-a716-446655440001",
    "account_id": "550e8400-e29b-41d4-a716-446655440002",
    "amount": 500.50,
    "currency": "INR",
    "transaction_type": "expense",
    "category_id": "550e8400-e29b-41d4-a716-446655440003",
    "category_name": "Groceries",
    "category_type": "expense",
    "account_name": "Checking Account",
    "description": "Weekly groceries",
    "notes": null,
    "transaction_date": "2026-01-27",
    "created_at": "2026-01-27T10:00:00Z",
    "updated_at": "2026-01-27T10:00:00Z"
  }
]
```

---

### 2. Create Transaction
**POST** `/transactions`

Record a new transaction.

**Request:**
```json
{
  "accountId": "550e8400-e29b-41d4-a716-446655440000",
  "toAccountId": null,
  "amount": 500.50,
  "type": "expense",
  "categoryId": "550e8400-e29b-41d4-a716-446655440003",
  "currency": "INR",
  "description": "Grocery shopping",
  "notes": "Weekly shopping",
  "tags": ["groceries", "food"],
  "date": "2026-01-27"
}
```

**Response:** `201 Created`
```json
{
  "transaction_id": "550e8400-e29b-41d4-a716-446655440000",
  "user_id": "550e8400-e29b-41d4-a716-446655440001",
  "account_id": "550e8400-e29b-41d4-a716-446655440000",
  ...
}
```

**Valid transaction types:**
- `income` - Money coming in (increases balance)
- `expense` - Money going out (decreases balance)
- `transfer` - Between two accounts (requires `toAccountId`)

**Validations:**
- Amount must be positive
- Account must exist and belong to user
- For expense: account balance must be sufficient
- For transfer: destination account must be provided

**Errors:**
- `400` - Insufficient balance
- `400` - Account not found
- `400` - Invalid input

---

### 3. Delete Transaction
**DELETE** `/transactions/:transactionId`

Soft delete a transaction and revert balance changes.

**Response:** `200 OK`
```json
{
  "success": true
}
```

**Behavior:**
- If income: balance decreased by amount
- If expense: balance increased by amount
- If transfer: both account balances reverted

---

## 📊 Analytics Endpoints

### 1. Dashboard Stats
**GET** `/analytics/dashboard`

Get financial overview for a period.

**Query Parameters:**
- `period` (optional) - `week`, `month`, or `year` (default: `month`)

**Example:**
```
GET /analytics/dashboard?period=month
```

**Response:** `200 OK`
```json
{
  "period": "month",
  "startDate": "2025-12-27T00:00:00Z",
  "endDate": "2026-01-27T00:00:00Z",
  "income": 50000.00,
  "expenses": 15000.00,
  "savings": 35000.00,
  "savingsRate": "70.00",
  "spendingByCategory": [
    {
      "category": "Groceries",
      "amount": 5000.00
    },
    {
      "category": "Dining & Restaurants",
      "amount": 3000.00
    },
    {
      "category": "Transportation",
      "amount": 2500.00
    }
  ]
}
```

---

### 2. Budget Progress
**GET** `/analytics/budget-progress`

Track spending against budgets.

**Response:** `200 OK`
```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "category": "550e8400-e29b-41d4-a716-446655440003",
    "limit": 5000.00,
    "spent": 3200.00,
    "remaining": 1800.00,
    "progress": "64.00"
  }
]
```

---

## 🏷️ Category Endpoints

### 1. List Categories
**GET** `/categories`

Get all available categories (system + user custom).

**Query Parameters:**
- `type` (optional) - `income`, `expense`, or `transfer`

**Example:**
```
GET /categories?type=expense
```

**Response:** `200 OK`
```json
[
  {
    "category_id": "550e8400-e29b-41d4-a716-446655440000",
    "user_id": null,
    "name": "Groceries",
    "category_type": "expense",
    "icon": "shopping-cart",
    "color": "#EF4444",
    "is_system": true,
    "created_at": "2026-01-27T10:00:00Z"
  },
  {
    "category_id": "550e8400-e29b-41d4-a716-446655440001",
    "user_id": null,
    "name": "Salary",
    "category_type": "income",
    "icon": "briefcase",
    "color": "#10B981",
    "is_system": true,
    "created_at": "2026-01-27T10:00:00Z"
  }
]
```

**Default Categories:**

**Income:**
- Salary
- Business
- Investment

**Expense:**
- Groceries
- Dining & Restaurants
- Transportation
- Shopping
- Entertainment
- Healthcare
- Bills & Utilities
- Education

**Transfer:**
- Transfer

---

## ✅ Health Check

### Health Status
**GET** `/health`

Check API health (no auth required).

**Response:** `200 OK`
```json
{
  "status": "OK",
  "timestamp": "2026-01-27T10:00:00Z"
}
```

---

## Error Responses

All errors follow this format:

```json
{
  "error": "Error message",
  "errors": [
    {
      "location": "body",
      "param": "email",
      "msg": "Invalid email"
    }
  ]
}
```

**Common Status Codes:**
- `200` - Success
- `201` - Created
- `400` - Bad request / validation error
- `401` - Unauthorized / authentication required
- `404` - Not found
- `500` - Internal server error

---

## Rate Limiting

- **General endpoints:** 100 requests per 15 minutes
- **Auth endpoints:** 5 requests per 15 minutes

When rate limited: `429 Too Many Requests`

---

## Testing with cURL

### Sign Up
```bash
curl -X POST http://localhost:3000/api/v1/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "SecurePass123!",
    "deviceId": "test-device",
    "deviceName": "Test Device"
  }'
```

### Create Account
```bash
curl -X POST http://localhost:3000/api/v1/accounts \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Savings",
    "account_type": "savings",
    "currency": "INR",
    "current_balance": 0
  }'
```

### Create Transaction
```bash
curl -X POST http://localhost:3000/api/v1/transactions \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "accountId": "ACCOUNT_UUID",
    "amount": 500,
    "type": "expense",
    "categoryId": "CATEGORY_UUID",
    "description": "Groceries"
  }'
```

### Get Dashboard
```bash
curl -X GET "http://localhost:3000/api/v1/analytics/dashboard?period=month" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## Environment Variables

```env
PORT=3000
NODE_ENV=development

# Database
DB_HOST=localhost
DB_PORT=5432
DB_USER=rupaya
DB_PASSWORD=password
DB_NAME=rupaya_dev

# JWT
JWT_SECRET=your_secret_min_32_chars_long
REFRESH_TOKEN_SECRET=your_refresh_secret_min_32_chars

# URLs
FRONTEND_URL=http://localhost:3000

# Logging
LOG_LEVEL=info
```

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "SecurePassword123!",
  "deviceId": "device-unique-id"
}
```

**Response:**
```json
{
  "userId": "uuid",
  "accessToken": "jwt-token",
  "refreshToken": "jwt-refresh-token",
  "user": { ... },
  "mfaRequired": false
}
```

#### POST /api/v1/auth/refresh
Refresh access token.

**Request Body:**
```json
{
  "refreshToken": "jwt-refresh-token"
}
```

**Response:**
```json
{
  "accessToken": "new-jwt-token",
  "refreshToken": "jwt-refresh-token"
}
```

#### POST /api/v1/auth/mfa/setup
Setup MFA for user account.

**Headers:** Requires authentication

**Response:**
```json
{
  "secret": "base32-secret",
  "qrCode": "data:image/png;base64,...",
  "backupCodes": ["CODE1", "CODE2", ...]
}
```

#### POST /api/v1/auth/mfa/verify
Verify MFA token.

**Request Body:**
```json
{
  "token": "123456",
  "deviceId": "device-unique-id"
}
```

**Response:**
```json
{
  "accessToken": "jwt-token",
  "refreshToken": "jwt-refresh-token"
}
```

## Error Responses

All errors follow this format:
```json
{
  "error": "Error message"
}
```

**HTTP Status Codes:**
- `400` - Bad Request
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `429` - Too Many Requests
- `500` - Internal Server Error

## Rate Limiting

- General endpoints: 100 requests per 15 minutes per IP
- Auth endpoints: 5 requests per 15 minutes per IP

Rate limit headers:
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 99
X-RateLimit-Reset: 1234567890
```

## Security Headers

All requests include:
- `X-API-Version: v1`
- `X-Request-ID: uuid`
- `X-Timestamp: epoch-ms`
- `X-Device-ID: device-fingerprint`
