# Expense API - Quick Reference

## Base URL
```
http://localhost:3000/api/v1/expenses
```

## Authentication
All endpoints require JWT token in header:
```
Authorization: Bearer <your_jwt_token>
```

---

## ⚡ Quick Endpoint Reference

### CRUD Operations
| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | `/` | Create expense |
| GET | `/` | List expenses |
| GET | `/{id}` | Get expense |
| PUT | `/{id}` | Update expense |
| DELETE | `/{id}` | Delete expense |

### Bulk & Special
| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | `/bulk-delete` | Delete multiple |
| POST | `/{id}/duplicate` | Duplicate expense |
| POST | `/{id}/receipt` | Attach receipt |
| POST | `/recurring` | Create recurring |

### Analytics
| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/statistics` | Get statistics |
| GET | `/export` | Export to CSV |
| GET | `/filter` | Advanced filter |

---

## 🔨 Common Operations

### Create Expense
```bash
POST /api/v1/expenses
Content-Type: application/json

{
  "amount": 2500.50,
  "account_id": "uuid",
  "category_id": "uuid",
  "description": "Shopping",
  "merchant": "Store",
  "expense_date": "2026-02-01T10:30:00Z",
  "tags": ["groceries"]
}
```

### List Expenses
```bash
GET /api/v1/expenses?limit=20&offset=0
```

### Filter Expenses
```bash
GET /api/v1/expenses?categoryId=uuid&startDate=2026-01-01&endDate=2026-02-01&minAmount=1000&maxAmount=5000
```

### Get Statistics
```bash
GET /api/v1/expenses/statistics?startDate=2026-01-01&endDate=2026-02-01
```

### Export to CSV
```bash
GET /api/v1/expenses/export?format=csv&startDate=2026-01-01
```

### Create Recurring
```bash
POST /api/v1/expenses/recurring
Content-Type: application/json

{
  "amount": 50.00,
  "account_id": "uuid",
  "category_id": "uuid",
  "description": "Monthly subscription",
  "recurring_frequency": "monthly"
}
```

---

## ✅ Input Validation Rules

### Amounts
- Must be > 0
- Decimal format (up to 2 places)

### Descriptions
- Min: 1 character
- Max: 255 characters
- Required

### Dates
- ISO8601 format required
- Example: `2026-02-01T10:30:00Z`

### Merchant
- Max: 100 characters
- Optional

### Recurring Frequency
- Must be one of: `daily`, `weekly`, `monthly`, `yearly`

### Tags
- Array of strings
- Example: `["groceries", "weekly"]`

---

## 📊 Response Format

### Success Response
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { /* payload */ }
}
```

### Error Response
```json
{
  "error": "Error message",
  "errors": [
    {
      "location": "body",
      "param": "fieldName",
      "msg": "Validation error"
    }
  ]
}
```

---

## 🔢 HTTP Status Codes

| Code | Meaning |
|------|---------|
| 200 | Success (GET, PUT, DELETE) |
| 201 | Created (POST) |
| 400 | Bad Request (validation error) |
| 401 | Unauthorized (missing/invalid token) |
| 404 | Not Found |
| 500 | Server Error |

---

## 📋 Query Parameters

### Pagination
- `limit` - Results per page (1-100, default: 20)
- `offset` - Pagination offset (default: 0)

### Filtering
- `accountId` - Filter by account
- `categoryId` - Filter by category
- `merchant` - Filter by merchant
- `startDate` - Filter from date
- `endDate` - Filter to date
- `minAmount` - Minimum amount
- `maxAmount` - Maximum amount
- `tags` - Filter by tags

### Export
- `format` - Export format (csv, pdf)

---

## 🎯 Workflow Examples

### Example 1: Track Weekly Groceries
1. Create expense (POST)
2. Add tags: ["groceries", "weekly"]
3. Attach receipt: POST /{id}/receipt
4. List monthly: GET ?startDate=2026-02-01&endDate=2026-02-28
5. Export report: GET /export

### Example 2: Track Subscriptions
1. Create recurring: POST /recurring
2. frequency: "monthly"
3. Add end_date: "2026-12-31"
4. Get statistics: GET /statistics
5. Check by category

### Example 3: Bulk Operations
1. Filter expenses: GET /filter?category=X
2. Duplicate some: POST /{id}/duplicate
3. Bulk delete old: POST /bulk-delete

---

## 🚫 Common Errors

### 400 Bad Request
**Cause:** Missing or invalid field  
**Solution:** Check all required fields and validation rules

### 401 Unauthorized
**Cause:** Missing or invalid JWT token  
**Solution:** Include valid token in Authorization header

### 404 Not Found
**Cause:** Expense doesn't exist  
**Solution:** Verify expense ID

### 500 Server Error
**Cause:** Database or server issue  
**Solution:** Check server logs

---

## 🔑 Required Fields by Endpoint

### POST /expenses
- `amount` ✓
- `account_id` ✓
- `category_id` ✓
- `description` ✓

### PUT /expenses/{id}
- None (all fields optional)

### POST /recurring
- `amount` ✓
- `account_id` ✓
- `category_id` ✓
- `description` ✓
- `recurring_frequency` ✓

### POST /{id}/receipt
- `receipt_url` ✓

### GET /statistics
- `startDate` ✓
- `endDate` ✓

---

## 💡 Pro Tips

1. **Use pagination** - Always add `limit` to avoid large responses
2. **Filter early** - Use query parameters to reduce data transfer
3. **Date format** - Always use ISO8601 format for dates
4. **Soft deletes** - Deleted expenses remain in database (audit trail)
5. **Recurring** - Set `recurring_end_date` to prevent infinite expenses
6. **Tags** - Use consistent tag names for better filtering
7. **Export** - CSV export includes all matching expenses (useful for spreadsheets)
8. **Statistics** - Group expenses by category for budget tracking

---

## 📞 Need Help?

1. Check **EXPENSE_API.md** for detailed documentation
2. Review **EXPENSE_DATABASE_MIGRATION.md** for schema details
3. See **EXPENSE_IMPLEMENTATION_CHECKLIST.md** for implementation status
4. Check application logs for errors
5. Verify JWT token is valid and not expired

---

## 🔗 Related Endpoints

- **Users**: `/api/v1/users/` - User profile management
- **Accounts**: `/api/v1/accounts/` - Bank accounts
- **Categories**: `/api/v1/categories/` - Expense categories
- **Transactions**: `/api/v1/transactions/` - All transactions
- **Analytics**: `/api/v1/analytics/` - Financial analytics

---

## 📚 File Locations

- **Model**: `backend/src/models/Expense.js`
- **Service**: `backend/src/services/ExpenseService.js`
- **Controller**: `backend/src/controllers/ExpenseController.js`
- **Routes**: `backend/src/routes/expenseRoutes.js`
- **Docs**: `backend/docs/EXPENSE_API.md`
