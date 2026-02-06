# Expense Management API Endpoints

All expense endpoints require authentication via JWT token in the `Authorization: Bearer <token>` header.

## Expense CRUD Operations

### 1. Create Expense
**POST** `/api/v1/expenses`

Create a new expense record.

**Request:**
```json
{
  "amount": 2500.50,
  "account_id": "550e8400-e29b-41d4-a716-446655440000",
  "category_id": "660e8400-e29b-41d4-a716-446655440001",
  "description": "Grocery shopping at local market",
  "expense_date": "2026-02-01T10:30:00Z",
  "merchant": "Fresh Mart",
  "notes": "Weekly groceries",
  "tags": ["groceries", "weekly"],
  "location": "Market Street, Downtown"
}
```

**Validations:**
- `amount` - Float, must be > 0
- `account_id` - String, required
- `category_id` - String, required
- `description` - String, 1-255 chars, required
- `expense_date` - ISO8601 date, optional (defaults to now)
- `merchant` - String, max 100 chars
- `notes` - String, max 500 chars
- `tags` - Array of strings
- `location` - String, max 255 chars

**Response:** `201 Created`
```json
{
  "success": true,
  "message": "Expense created successfully",
  "data": {
    "expense_id": "770e8400-e29b-41d4-a716-446655440002",
    "user_id": "550e8400-e29b-41d4-a716-446655440000",
    "account_id": "550e8400-e29b-41d4-a716-446655440000",
    "amount": 2500.50,
    "currency": "INR",
    "category_id": "660e8400-e29b-41d4-a716-446655440001",
    "category_name": "Groceries",
    "description": "Grocery shopping at local market",
    "merchant": "Fresh Mart",
    "notes": "Weekly groceries",
    "tags": ["groceries", "weekly"],
    "location": "Market Street, Downtown",
    "expense_date": "2026-02-01T10:30:00Z",
    "receipt_url": null,
    "is_recurring": false,
    "created_at": "2026-02-01T10:35:00Z",
    "updated_at": "2026-02-01T10:35:00Z"
  }
}
```

**Errors:**
- `400` - Validation error (missing/invalid fields)
- `401` - Unauthorized

---

### 2. List Expenses
**GET** `/api/v1/expenses`

Retrieve paginated list of all expenses for authenticated user.

**Query Parameters:**
- `accountId` - Filter by account ID
- `categoryId` - Filter by category ID
- `merchant` - Filter by merchant name (partial match)
- `startDate` - ISO8601 date (inclusive)
- `endDate` - ISO8601 date (inclusive)
- `minAmount` - Filter by minimum amount
- `maxAmount` - Filter by maximum amount
- `tags` - Filter by tags (comma-separated or array)
- `limit` - Results per page (1-100, default: 20)
- `offset` - Pagination offset (default: 0)

**Example Request:**
```bash
curl -X GET "http://localhost:3000/api/v1/expenses?categoryId=660e8400-e29b-41d4-a716-446655440001&startDate=2026-01-01&endDate=2026-02-01&limit=20&offset=0" \
  -H "Authorization: Bearer <token>"
```

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "expenses": [
      {
        "expense_id": "770e8400-e29b-41d4-a716-446655440002",
        "description": "Grocery shopping",
        "amount": 2500.50,
        "currency": "INR",
        "category_name": "Groceries",
        "merchant": "Fresh Mart",
        "expense_date": "2026-02-01T10:30:00Z",
        "tags": ["groceries", "weekly"]
      }
    ],
    "total": 45,
    "limit": 20,
    "offset": 0
  }
}
```

**Errors:**
- `400` - Invalid query parameters
- `401` - Unauthorized

---

### 3. Get Single Expense
**GET** `/api/v1/expenses/{id}`

Retrieve a specific expense by ID.

**Path Parameters:**
- `id` - Expense ID (required)

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "expense_id": "770e8400-e29b-41d4-a716-446655440002",
    "user_id": "550e8400-e29b-41d4-a716-446655440000",
    "account_id": "550e8400-e29b-41d4-a716-446655440000",
    "account_name": "Checking Account",
    "amount": 2500.50,
    "currency": "INR",
    "category_id": "660e8400-e29b-41d4-a716-446655440001",
    "category_name": "Groceries",
    "description": "Grocery shopping at local market",
    "merchant": "Fresh Mart",
    "notes": "Weekly groceries",
    "tags": ["groceries", "weekly"],
    "location": "Market Street, Downtown",
    "receipt_url": "/uploads/receipts/receipt-123.pdf",
    "expense_date": "2026-02-01T10:30:00Z",
    "is_recurring": false,
    "created_at": "2026-02-01T10:35:00Z",
    "updated_at": "2026-02-01T10:35:00Z"
  }
}
```

**Errors:**
- `401` - Unauthorized
- `404` - Expense not found

---

### 4. Update Expense
**PUT** `/api/v1/expenses/{id}`

Update an existing expense.

**Request:**
```json
{
  "amount": 2600.00,
  "description": "Weekly grocery shopping",
  "merchant": "Fresh Mart Super Store",
  "notes": "Updated notes",
  "expense_date": "2026-02-01T11:00:00Z",
  "category_id": "660e8400-e29b-41d4-a716-446655440001"
}
```

**Validations:**
- `amount` - Float, must be > 0 (optional)
- `description` - String, 1-255 chars (optional)
- `merchant` - String, max 100 chars (optional)
- `notes` - String, max 500 chars (optional)
- `expense_date` - ISO8601 date (optional)
- `category_id` - String (optional)
- `tags` - Array of strings (optional)
- `location` - String, max 255 chars (optional)

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Expense updated successfully",
  "data": {
    "expense_id": "770e8400-e29b-41d4-a716-446655440002",
    "amount": 2600.00,
    "description": "Weekly grocery shopping",
    "merchant": "Fresh Mart Super Store",
    "updated_at": "2026-02-01T12:00:00Z"
  }
}
```

**Errors:**
- `400` - Validation error
- `401` - Unauthorized
- `404` - Expense not found

---

### 5. Delete Expense
**DELETE** `/api/v1/expenses/{id}`

Soft-delete an expense (preserves audit trail).

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Expense deleted successfully"
}
```

**Errors:**
- `401` - Unauthorized
- `404` - Expense not found

---

## Bulk Operations

### 6. Bulk Delete Expenses
**POST** `/api/v1/expenses/bulk-delete`

Delete multiple expenses at once.

**Request:**
```json
{
  "expense_ids": [
    "770e8400-e29b-41d4-a716-446655440002",
    "770e8400-e29b-41d4-a716-446655440003",
    "770e8400-e29b-41d4-a716-446655440004"
  ]
}
```

**Validations:**
- `expense_ids` - Array of strings, required and non-empty

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "3 expenses deleted successfully",
  "deletedCount": 3
}
```

**Errors:**
- `400` - Invalid request (missing or empty array)
- `401` - Unauthorized

---

## Analytics & Reporting

### 7. Get Expense Statistics
**GET** `/api/v1/expenses/statistics`

Get expense statistics for a date range.

**Query Parameters:**
- `startDate` - ISO8601 date (required)
- `endDate` - ISO8601 date (required)

**Example Request:**
```bash
curl -X GET "http://localhost:3000/api/v1/expenses/statistics?startDate=2026-01-01&endDate=2026-02-01" \
  -H "Authorization: Bearer <token>"
```

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "total": 15000.75,
    "count": 12,
    "average": 1250.06,
    "byCategory": {
      "Groceries": 5000.50,
      "Transportation": 3500.25,
      "Entertainment": 2000.00,
      "Utilities": 2500.00,
      "Others": 2000.00
    },
    "startDate": "2026-01-01",
    "endDate": "2026-02-01"
  }
}
```

**Errors:**
- `400` - Missing or invalid date parameters
- `401` - Unauthorized

---

### 8. Export Expenses
**GET** `/api/v1/expenses/export`

Export expenses in CSV format.

**Query Parameters:**
- `format` - Export format: `csv` or `pdf` (default: csv)
- `startDate` - ISO8601 date (optional)
- `endDate` - ISO8601 date (optional)
- `categoryId` - Filter by category (optional)

**Example Request:**
```bash
curl -X GET "http://localhost:3000/api/v1/expenses/export?format=csv&startDate=2026-01-01&endDate=2026-02-01" \
  -H "Authorization: Bearer <token>" \
  -o expenses.csv
```

**Response:** `200 OK` (CSV file)
```csv
expense_id,description,amount,currency,category_name,merchant,expense_date,notes
770e8400-e29b-41d4-a716-446655440002,Grocery shopping,2500.50,INR,Groceries,Fresh Mart,2026-02-01,Weekly groceries
```

**Headers:**
- `Content-Type: text/csv`
- `Content-Disposition: attachment; filename="expenses.csv"`

**Errors:**
- `400` - Invalid format or date parameters
- `401` - Unauthorized

---

### 9. Filter Expenses
**GET** `/api/v1/expenses/filter`

Advanced filtering of expenses with multiple criteria.

**Query Parameters:**
- `accountId` - Filter by account ID
- `categoryId` - Filter by category ID
- `merchant` - Filter by merchant name
- `startDate` - ISO8601 date (inclusive)
- `endDate` - ISO8601 date (inclusive)
- `minAmount` - Minimum amount
- `maxAmount` - Maximum amount
- `tags` - Filter by tags (comma-separated)
- `limit` - Results per page (1-100, default: 20)
- `offset` - Pagination offset (default: 0)

**Example Request:**
```bash
curl -X GET "http://localhost:3000/api/v1/expenses/filter?minAmount=1000&maxAmount=5000&tags=groceries,weekly&limit=10" \
  -H "Authorization: Bearer <token>"
```

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "expenses": [...],
    "total": 15,
    "limit": 10,
    "offset": 0
  }
}
```

**Errors:**
- `400` - Invalid query parameters
- `401` - Unauthorized

---

## Expense Management Features

### 10. Duplicate Expense
**POST** `/api/v1/expenses/{id}/duplicate`

Create a duplicate of an existing expense.

**Response:** `201 Created`
```json
{
  "success": true,
  "message": "Expense duplicated successfully",
  "data": {
    "expense_id": "880e8400-e29b-41d4-a716-446655440005",
    "description": "Grocery shopping at local market",
    "amount": 2500.50,
    "merchant": "Fresh Mart",
    "parent_expense_id": "770e8400-e29b-41d4-a716-446655440002",
    "created_at": "2026-02-01T13:00:00Z"
  }
}
```

**Errors:**
- `401` - Unauthorized
- `404` - Expense not found

---

### 11. Attach Receipt
**POST** `/api/v1/expenses/{id}/receipt`

Attach a receipt URL to an expense.

**Request:**
```json
{
  "receipt_url": "https://s3.amazonaws.com/receipts/receipt-123.pdf"
}
```

**Validations:**
- `receipt_url` - Valid URL, required

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Receipt attached successfully",
  "data": {
    "expense_id": "770e8400-e29b-41d4-a716-446655440002",
    "receipt_url": "https://s3.amazonaws.com/receipts/receipt-123.pdf",
    "updated_at": "2026-02-01T13:05:00Z"
  }
}
```

**Errors:**
- `400` - Invalid or missing receipt URL
- `401` - Unauthorized
- `404` - Expense not found

---

### 12. Create Recurring Expense
**POST** `/api/v1/expenses/recurring`

Create a recurring expense that will repeat periodically.

**Request:**
```json
{
  "amount": 50.00,
  "account_id": "550e8400-e29b-41d4-a716-446655440000",
  "category_id": "660e8400-e29b-41d4-a716-446655440006",
  "description": "Monthly subscription",
  "recurring_frequency": "monthly",
  "recurring_end_date": "2026-12-31T23:59:59Z",
  "merchant": "Subscription Service",
  "notes": "Premium membership",
  "tags": ["subscription", "monthly"],
  "start_date": "2026-02-01T00:00:00Z"
}
```

**Validations:**
- `amount` - Float, must be > 0, required
- `account_id` - String, required
- `category_id` - String, required
- `description` - String, 1-255 chars, required
- `recurring_frequency` - One of: daily, weekly, monthly, yearly (required)
- `recurring_end_date` - ISO8601 date (optional)
- `merchant` - String, max 100 chars (optional)
- `notes` - String, max 500 chars (optional)
- `tags` - Array of strings (optional)
- `start_date` - ISO8601 date (optional, defaults to now)

**Response:** `201 Created`
```json
{
  "success": true,
  "message": "Recurring expense created successfully",
  "data": {
    "expense_id": "990e8400-e29b-41d4-a716-446655440007",
    "amount": 50.00,
    "description": "Monthly subscription",
    "merchant": "Subscription Service",
    "is_recurring": true,
    "recurring_frequency": "monthly",
    "recurring_end_date": "2026-12-31T23:59:59Z",
    "tags": ["subscription", "monthly"],
    "created_at": "2026-02-01T13:10:00Z"
  }
}
```

**Errors:**
- `400` - Validation error (missing fields or invalid frequency)
- `401` - Unauthorized

---

## Error Response Format

```json
{
  "error": "Error message",
  "errors": [
    {
      "location": "body",
      "param": "fieldName",
      "msg": "Field validation error"
    }
  ]
}
```

## Example Requests

### Create Expense
```bash
curl -X POST http://localhost:3000/api/v1/expenses \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 2500.50,
    "account_id": "550e8400-e29b-41d4-a716-446655440000",
    "category_id": "660e8400-e29b-41d4-a716-446655440001",
    "description": "Grocery shopping",
    "merchant": "Fresh Mart"
  }'
```

### List Expenses with Filters
```bash
curl -X GET "http://localhost:3000/api/v1/expenses?categoryId=660e8400-e29b-41d4-a716-446655440001&startDate=2026-01-01&endDate=2026-02-01" \
  -H "Authorization: Bearer <token>"
```

### Get Statistics
```bash
curl -X GET "http://localhost:3000/api/v1/expenses/statistics?startDate=2026-01-01&endDate=2026-02-01" \
  -H "Authorization: Bearer <token>"
```

### Export to CSV
```bash
curl -X GET "http://localhost:3000/api/v1/expenses/export?format=csv&startDate=2026-01-01" \
  -H "Authorization: Bearer <token>" \
  -o expenses.csv
```

### Create Recurring Expense
```bash
curl -X POST http://localhost:3000/api/v1/expenses/recurring \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 50.00,
    "account_id": "550e8400-e29b-41d4-a716-446655440000",
    "category_id": "660e8400-e29b-41d4-a716-446655440006",
    "description": "Monthly subscription",
    "recurring_frequency": "monthly"
  }'
```

### Bulk Delete
```bash
curl -X POST http://localhost:3000/api/v1/expenses/bulk-delete \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "expense_ids": ["770e8400-e29b-41d4-a716-446655440002", "770e8400-e29b-41d4-a716-446655440003"]
  }'
```
