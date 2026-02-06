# Expense Management System - Implementation Checklist

## ✅ Completed Items

### Core Files Created
- [x] **backend/src/models/Expense.js** - Expense data model with all CRUD operations
- [x] **backend/src/services/ExpenseService.js** - Business logic layer for expense management
- [x] **backend/src/controllers/ExpenseController.js** - HTTP handlers for all 11 endpoints
- [x] **backend/src/routes/expenseRoutes.js** - Route definitions with comprehensive validation
- [x] **backend/src/app.js** - Updated to wire expense routes with auth middleware

### Documentation
- [x] **docs/EXPENSE_API.md** - Complete API documentation (12 endpoints)
- [x] **docs/EXPENSE_DATABASE_MIGRATION.md** - Database schema migration guide
- [x] **backend/package.json** - Updated with json2csv and multer dependencies

### Endpoints Implemented

#### CRUD Operations (5 endpoints)
- [x] **POST /api/v1/expenses** - Create new expense
- [x] **GET /api/v1/expenses** - List expenses with pagination & filters
- [x] **GET /api/v1/expenses/{id}** - Get single expense
- [x] **PUT /api/v1/expenses/{id}** - Update expense
- [x] **DELETE /api/v1/expenses/{id}** - Delete expense (soft-delete)

#### Bulk Operations (1 endpoint)
- [x] **POST /api/v1/expenses/bulk-delete** - Delete multiple expenses

#### Analytics & Reporting (3 endpoints)
- [x] **GET /api/v1/expenses/statistics** - Get expense statistics by category
- [x] **GET /api/v1/expenses/export** - Export expenses to CSV
- [x] **GET /api/v1/expenses/filter** - Advanced filtering with multiple criteria

#### Special Features (3 endpoints)
- [x] **POST /api/v1/expenses/{id}/duplicate** - Duplicate expense
- [x] **POST /api/v1/expenses/{id}/receipt** - Attach receipt URL
- [x] **POST /api/v1/expenses/recurring** - Create recurring expense

### Features Implemented

#### Input Validation
- [x] Amount validation (must be > 0)
- [x] Description validation (1-255 chars)
- [x] Date validation (ISO8601 format)
- [x] URL validation for receipts
- [x] Merchant validation (max 100 chars)
- [x] Recurring frequency validation (daily, weekly, monthly, yearly)
- [x] File type validation for attachments

#### Database Features
- [x] Soft-delete support (audit trail preservation)
- [x] JSONB tags support for flexible categorization
- [x] Recurring expense fields (frequency, end date)
- [x] Parent expense tracking (for duplicates)
- [x] Receipt URL storage
- [x] Location and merchant tracking

#### Security
- [x] JWT authentication required on all endpoints
- [x] User isolation (users can only access their own expenses)
- [x] Password confirmation for sensitive operations (not applicable for expenses)
- [x] Input sanitization via express-validator
- [x] Error handling with asyncHandler wrapper

#### Performance
- [x] Pagination support (limit/offset)
- [x] Database indexes for common queries
- [x] Composite indexes for complex filters
- [x] JSONB GIN index for tag searches
- [x] Relationship joins optimized

---

## ⏳ Pending Items

### Database Setup (MUST DO FIRST)
- [ ] **Run migration** - Create expenses table and indexes in PostgreSQL
  - Command: `npm run migrate`
  - Or manually execute SQL from EXPENSE_DATABASE_MIGRATION.md
  - Verify with: `psql -d rupaya_db -c "SELECT * FROM expenses;"`

### Dependencies Installation
- [ ] **Install npm packages** - json2csv and multer
  - Command: `cd backend && npm install`
  - Verify: `npm ls json2csv multer`

### Testing
- [ ] **Unit tests** - Test ExpenseService methods
  - Test create, update, delete, list operations
  - Test validation logic
  - Test edge cases
- [ ] **Integration tests** - Test all 11 endpoints
  - Test authentication flows
  - Test validation errors
  - Test pagination
  - Test filtering capabilities
  - Test export functionality
- [ ] **Manual testing** - Use cURL or Postman
  - Verify each endpoint works correctly
  - Test with various filters and parameters
  - Test error scenarios

### File Upload Configuration
- [ ] **Configure receipt storage** - Choose S3 or local storage
  - Option 1: AWS S3 (recommended for production)
    - Set up S3 bucket
    - Configure multer-s3 middleware
    - Update ExpenseController receipt upload handler
  - Option 2: Local file storage
    - Create /uploads/receipts directory
    - Configure multer disk storage
    - Add file serving middleware

### Database Optimization
- [ ] **Create materialized views** (optional)
  - Pre-calculate expense statistics
  - Cache monthly aggregations
- [ ] **Set up partitioning** (if data grows large)
  - Partition expenses table by date
  - Improve query performance on large datasets

### API Documentation Updates
- [ ] **Update main API_DOCUMENTATION.md** - Add expense endpoints
- [ ] **Update ENDPOINT_COVERAGE.md** - Mark expense endpoints as implemented
- [ ] **Create Postman collection** - For easy testing
- [ ] **Add webhook support** (optional)
  - Notify on expense creation/deletion

### Frontend Integration
- [ ] **Create expense UI screens** (mobile & web)
  - Add expense form
  - List expenses view
  - Expense detail view
  - Edit/delete expense
  - Statistics dashboard
  - Export functionality
- [ ] **Connect to backend API**
  - Implement API client functions
  - Handle authentication
  - Display results

### DevOps & Deployment
- [ ] **Test in staging environment**
  - Deploy to staging
  - Run full integration tests
  - Verify database migrations
- [ ] **Update CI/CD pipelines**
  - Add database migration step to deploy-production.yml
  - Add test coverage for new endpoints
- [ ] **Production deployment**
  - Schedule migration (during maintenance window if needed)
  - Deploy backend code
  - Verify in production

### Monitoring & Logging
- [ ] **Set up alerts** for expense operation failures
- [ ] **Add database monitoring** for query performance
- [ ] **Create dashboards** for expense metrics
- [ ] **Review logs** for any issues

---

## 🚀 Quick Start Guide

### 1. Install Dependencies
```bash
cd backend
npm install
```

### 2. Run Database Migration
```bash
npm run migrate
```

### 3. Start Backend Server
```bash
npm run dev
```

### 4. Test Endpoints
```bash
# Create expense
curl -X POST http://localhost:3000/api/v1/expenses \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 2500.50,
    "account_id": "account-uuid",
    "category_id": "category-uuid",
    "description": "Test expense"
  }'

# List expenses
curl -X GET http://localhost:3000/api/v1/expenses \
  -H "Authorization: Bearer YOUR_TOKEN"

# Get statistics
curl -X GET "http://localhost:3000/api/v1/expenses/statistics?startDate=2026-01-01&endDate=2026-02-01" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## 📋 Implementation Details

### Files Modified
1. **backend/src/app.js**
   - Added `const expenseRoutes = require('./routes/expenseRoutes');`
   - Added `app.use('/api/v1/expenses', authMiddleware, expenseRoutes);`

2. **backend/package.json**
   - Added `"json2csv": "^6.0.0"`
   - Added `"multer": "^1.4.5-lts.1"`

### Files Created
1. **backend/src/models/Expense.js** (210 lines)
   - Static methods for CRUD operations
   - Relationship joins with categories and accounts
   - Statistics and export queries

2. **backend/src/services/ExpenseService.js** (130 lines)
   - Business logic for all operations
   - Input validation and error handling
   - CSV export functionality

3. **backend/src/controllers/ExpenseController.js** (180 lines)
   - 11 async endpoint handlers
   - Request/response handling
   - Parameter parsing and validation delegation

4. **backend/src/routes/expenseRoutes.js** (150 lines)
   - 11 routes with express-validator rules
   - Comprehensive input validation
   - Error handling middleware

5. **docs/EXPENSE_API.md** (550+ lines)
   - Complete API documentation
   - Request/response examples
   - cURL examples for all endpoints

6. **docs/EXPENSE_DATABASE_MIGRATION.md** (300+ lines)
   - SQL migration scripts
   - Knex migration file template
   - Verification procedures

---

## 🔍 Testing Scenarios

### Scenario 1: Create and List Expenses
1. Create 3 expenses with different categories
2. List expenses (should see all 3)
3. Filter by category (should see 1)
4. Check pagination (limit 2, offset 0)

### Scenario 2: Update and Delete
1. Create an expense
2. Update description and amount
3. Verify update
4. Soft-delete expense
5. Verify expense not in list
6. Verify it can be recovered via direct ID query with soft-delete override

### Scenario 3: Statistics and Export
1. Create 10 expenses across different categories
2. Request statistics for date range
3. Verify totals are correct
4. Request CSV export
5. Verify CSV contains all expenses

### Scenario 4: Recurring Expenses
1. Create recurring monthly expense
2. Verify `is_recurring` is true
3. Verify frequency is stored correctly
4. Create duplicate of recurring expense
5. Verify parent_expense_id is set

### Scenario 5: Advanced Filtering
1. Create expenses with:
   - Different amounts
   - Different dates
   - Multiple merchants
   - Various tags
2. Filter by amount range (minAmount, maxAmount)
3. Filter by date range
4. Filter by merchant
5. Filter by tags
6. Combine multiple filters

---

## 📊 Database Schema Summary

```
expenses (11 endpoints)
├── Basic CRUD (5)
│   ├── Create (POST)
│   ├── Read (GET)
│   ├── Update (PUT)
│   ├── Delete (DELETE)
│   └── List (GET)
├── Bulk Operations (1)
│   └── Bulk Delete
├── Analytics (3)
│   ├── Statistics
│   ├── Export
│   └── Filter
└── Features (3)
    ├── Duplicate
    ├── Receipt
    └── Recurring
```

---

## 🎯 Next Steps

1. **Immediate (Today)**
   - [x] Code implementation complete
   - [ ] Run database migration
   - [ ] Install npm packages
   - [ ] Basic testing with cURL

2. **Short-term (This Week)**
   - [ ] Unit tests for service layer
   - [ ] Integration tests for all endpoints
   - [ ] Document any discovered issues

3. **Medium-term (This Month)**
   - [ ] Frontend UI implementation
   - [ ] Staging deployment
   - [ ] Performance testing

4. **Long-term (Ongoing)**
   - [ ] Production deployment
   - [ ] Monitoring and optimization
   - [ ] User feedback integration

---

## 📞 Support

For issues or questions:
1. Check EXPENSE_API.md for endpoint documentation
2. Check EXPENSE_DATABASE_MIGRATION.md for schema details
3. Review error messages in API responses
4. Check application logs
