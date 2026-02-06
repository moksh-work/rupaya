# Database Migration for Expense Management

## Overview
This document outlines the database schema changes required to support the new expense management system.

## SQL Migration Script

Run this migration to set up the expenses table:

```sql
-- Create expenses table
CREATE TABLE IF NOT EXISTS expenses (
  expense_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  account_id UUID NOT NULL REFERENCES accounts(account_id) ON DELETE CASCADE,
  amount DECIMAL(15, 2) NOT NULL CHECK (amount > 0),
  currency VARCHAR(3) NOT NULL DEFAULT 'INR',
  category_id UUID REFERENCES categories(category_id) ON DELETE SET NULL,
  description VARCHAR(255) NOT NULL,
  notes TEXT,
  location VARCHAR(255),
  merchant VARCHAR(100),
  tags JSONB,
  receipt_url VARCHAR(2048),
  expense_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  is_recurring BOOLEAN DEFAULT FALSE,
  recurring_frequency VARCHAR(20),
  recurring_end_date TIMESTAMP,
  parent_expense_id UUID REFERENCES expenses(expense_id) ON DELETE SET NULL,
  is_deleted BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX idx_expenses_user_id ON expenses(user_id);
CREATE INDEX idx_expenses_account_id ON expenses(account_id);
CREATE INDEX idx_expenses_category_id ON expenses(category_id);
CREATE INDEX idx_expenses_expense_date ON expenses(expense_date);
CREATE INDEX idx_expenses_is_deleted ON expenses(is_deleted);
CREATE INDEX idx_expenses_is_recurring ON expenses(is_recurring);
CREATE INDEX idx_expenses_user_date ON expenses(user_id, expense_date DESC);

-- Create GIST index for JSONB tags search
CREATE INDEX idx_expenses_tags_gin ON expenses USING GIN(tags);

-- Add helper function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_expenses_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for updated_at
DROP TRIGGER IF EXISTS trigger_expenses_updated_at ON expenses;
CREATE TRIGGER trigger_expenses_updated_at
BEFORE UPDATE ON expenses
FOR EACH ROW
EXECUTE FUNCTION update_expenses_updated_at();
```

## Knex Migration File

Create a new Knex migration file:

**File:** `migrations/XXX_create_expenses_table.js`

```javascript
exports.up = async function(knex) {
  return knex.schema.createTable('expenses', (table) => {
    table.uuid('expense_id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.uuid('user_id').notNullable().references('user_id').inTable('users').onDelete('CASCADE');
    table.uuid('account_id').notNullable().references('account_id').inTable('accounts').onDelete('CASCADE');
    table.decimal('amount', 15, 2).notNullable().checkPositive();
    table.string('currency', 3).notNullable().defaultTo('INR');
    table.uuid('category_id').references('category_id').inTable('categories').onDelete('SET NULL');
    table.string('description', 255).notNullable();
    table.text('notes').nullable();
    table.string('location', 255).nullable();
    table.string('merchant', 100).nullable();
    table.jsonb('tags').nullable();
    table.string('receipt_url', 2048).nullable();
    table.timestamp('expense_date').notNullable().defaultTo(knex.fn.now());
    table.boolean('is_recurring').defaultTo(false);
    table.string('recurring_frequency', 20).nullable();
    table.timestamp('recurring_end_date').nullable();
    table.uuid('parent_expense_id').references('expense_id').inTable('expenses').onDelete('SET NULL');
    table.boolean('is_deleted').defaultTo(false);
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.timestamp('updated_at').defaultTo(knex.fn.now());

    // Indexes
    table.index('user_id');
    table.index('account_id');
    table.index('category_id');
    table.index('expense_date');
    table.index('is_deleted');
    table.index('is_recurring');
    table.index(['user_id', 'expense_date']);
  });
};

exports.down = async function(knex) {
  return knex.schema.dropTable('expenses');
};
```

## Running the Migration

### Option 1: Using Knex CLI
```bash
cd backend
npm run migrate
```

### Option 2: Using SQL File
```bash
# Copy the SQL migration script to a file
cat > migrations/expenses.sql << 'EOF'
[SQL code from above]
EOF

# Execute migration
psql -U postgres -d rupaya_db -f migrations/expenses.sql
```

### Option 3: Using Docker
```bash
# Connect to PostgreSQL container and run migration
docker exec -it rupaya-db psql -U postgres -d rupaya_db -f /migrations/expenses.sql
```

## Verification

After migration, verify the table was created:

```sql
-- List the expenses table structure
\d expenses;

-- Check table size
SELECT pg_size_pretty(pg_total_relation_size('expenses'));

-- Verify indexes
SELECT * FROM pg_indexes WHERE tablename = 'expenses';

-- Test insert a sample expense
INSERT INTO expenses (
  user_id,
  account_id,
  amount,
  currency,
  category_id,
  description,
  expense_date
) VALUES (
  'user-id-here',
  'account-id-here',
  2500.50,
  'INR',
  'category-id-here',
  'Test expense',
  NOW()
);
```

## Schema Details

### expenses Table Columns

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| expense_id | UUID | PRIMARY KEY | Unique identifier for expense |
| user_id | UUID | FK → users, NOT NULL | Owner of the expense |
| account_id | UUID | FK → accounts, NOT NULL | Associated account |
| amount | DECIMAL(15,2) | NOT NULL, > 0 | Expense amount |
| currency | VARCHAR(3) | NOT NULL, DEFAULT 'INR' | Currency code (ISO 4217) |
| category_id | UUID | FK → categories | Expense category |
| description | VARCHAR(255) | NOT NULL | Expense description |
| notes | TEXT | NULLABLE | Additional notes |
| location | VARCHAR(255) | NULLABLE | Location of expense |
| merchant | VARCHAR(100) | NULLABLE | Merchant/vendor name |
| tags | JSONB | NULLABLE | Array of tags for categorization |
| receipt_url | VARCHAR(2048) | NULLABLE | URL to receipt document |
| expense_date | TIMESTAMP | NOT NULL | Date of expense |
| is_recurring | BOOLEAN | DEFAULT FALSE | Is this a recurring expense |
| recurring_frequency | VARCHAR(20) | NULLABLE | Frequency: daily, weekly, monthly, yearly |
| recurring_end_date | TIMESTAMP | NULLABLE | When recurring expenses should stop |
| parent_expense_id | UUID | FK → expenses | Reference to parent if duplicated |
| is_deleted | BOOLEAN | DEFAULT FALSE | Soft delete flag |
| created_at | TIMESTAMP | DEFAULT NOW() | Creation timestamp |
| updated_at | TIMESTAMP | DEFAULT NOW() | Last update timestamp |

### Indexes Created

1. **idx_expenses_user_id** - Fast lookup by user
2. **idx_expenses_account_id** - Fast lookup by account
3. **idx_expenses_category_id** - Fast lookup by category
4. **idx_expenses_expense_date** - Fast date range queries
5. **idx_expenses_is_deleted** - Filter soft-deleted records
6. **idx_expenses_is_recurring** - Filter recurring expenses
7. **idx_expenses_user_date** - Composite index for most common queries
8. **idx_expenses_tags_gin** - JSONB index for tag searches

## Rollback

If you need to rollback the migration:

### Using Knex
```bash
npm run migrate:rollback
```

### Using SQL
```sql
DROP TABLE IF EXISTS expenses CASCADE;
DROP FUNCTION IF EXISTS update_expenses_updated_at();
```

## Notes

- **Soft Deletes**: The `is_deleted` column enables soft-deletion, preserving audit trails
- **JSONB Tags**: PostgreSQL's JSONB type allows flexible tag storage and efficient searching
- **Cascading Deletes**: User/account deletion will automatically cascade to expenses
- **Recurring Support**: `is_recurring`, `recurring_frequency`, and `recurring_end_date` fields support recurring expense functionality
- **Audit Trail**: The `parent_expense_id` tracks duplicated expenses
- **Performance**: Composite indexes on frequently accessed columns optimize query performance

## Testing

After migration, test the expense endpoints:

```bash
# Create test expense
curl -X POST http://localhost:3000/api/v1/expenses \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 2500.50,
    "account_id": "account-uuid",
    "category_id": "category-uuid",
    "description": "Test expense"
  }'

# List expenses
curl -X GET http://localhost:3000/api/v1/expenses \
  -H "Authorization: Bearer <token>"

# Get statistics
curl -X GET "http://localhost:3000/api/v1/expenses/statistics?startDate=2026-01-01&endDate=2026-02-01" \
  -H "Authorization: Bearer <token>"
```
