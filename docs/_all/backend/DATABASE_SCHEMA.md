# Database Schema Documentation

## Overview

This document describes the complete database schema for the RUPAYA Money Manager application, covering all implemented API endpoints.

## Database Information

- **Database Engine**: PostgreSQL 15+
- **Schema Version**: 3.0
- **Total Tables**: 20
- **Total Views**: 3
- **Total Indexes**: 50+

## Table Categories

### 1. User Management (3 tables)
- `users` - User accounts and authentication
- `devices` - Registered user devices
- `user_settings` - User preferences and configuration

### 2. Financial Core (4 tables)
- `accounts` - User financial accounts
- `categories` - Expense/income categories (system + custom)
- `transactions` - General transactions
- `recurring_transactions` - Recurring transaction patterns

### 3. Expense & Income (2 tables)
- `expenses` - Expense tracking with receipts
- `income` - Income tracking with sources

### 4. Budget Management (1 table)
- `budgets` - Budget tracking with alerts

### 5. Bank Integration (2 tables)
- `bank_accounts` - Connected bank accounts
- `bank_transactions` - Imported bank transactions

### 6. Investments (1 table)
- `investments` - Investment portfolio tracking

### 7. Notifications (2 tables)
- `notifications` - User notifications
- `notification_preferences` - Notification settings

### 8. Settings & Security (2 tables)
- `security_settings` - Security configurations
- `data_exports` - Data export requests
- `data_access_requests` - GDPR/privacy requests

### 9. Audit (1 table)
- `audit_logs` - System audit trail

## Detailed Schema

### Users Table
```sql
users (
    user_id UUID PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    email_verified BOOLEAN DEFAULT FALSE,
    password_hash VARCHAR(255),
    name VARCHAR(255),
    phone_number VARCHAR(20),
    currency_preference VARCHAR(3) DEFAULT 'INR',
    mfa_enabled BOOLEAN DEFAULT FALSE,
    account_status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP,
    updated_at TIMESTAMP
)
```

**Key Features**:
- UUID primary key for security
- Email validation constraint
- MFA support
- Account status tracking
- Soft delete support

**Indexes**:
- `idx_users_email` - Fast email lookup
- `idx_users_created_at` - Registration tracking
- `idx_users_status` - Active user filtering

### Accounts Table
```sql
accounts (
    account_id UUID PRIMARY KEY,
    user_id UUID REFERENCES users,
    name VARCHAR(255) NOT NULL,
    account_type VARCHAR(20) CHECK IN ('cash', 'bank', 'credit_card', 'investment', 'savings'),
    current_balance NUMERIC(15,2) DEFAULT 0,
    is_default BOOLEAN DEFAULT FALSE,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
)
```

**Key Features**:
- Multiple account types
- Real-time balance tracking
- Default account support
- Soft delete for history

### Categories Table
```sql
categories (
    category_id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES users (nullable for system categories),
    name VARCHAR(100) NOT NULL,
    category_type VARCHAR(20) CHECK IN ('income', 'expense', 'transfer'),
    icon VARCHAR(50),
    color VARCHAR(7),
    is_system BOOLEAN DEFAULT FALSE,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP
)
```

**Key Features**:
- System vs custom categories
- Icon and color customization
- Categorization for income/expense/transfer
- 12 pre-populated system categories

**System Categories**:
- Income: Salary, Business, Investment
- Expense: Groceries, Dining, Transportation, Shopping, Entertainment, Healthcare, Bills, Education
- Transfer: Account transfers

### Expenses Table
```sql
expenses (
    expense_id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES users,
    category_id INTEGER REFERENCES categories,
    amount NUMERIC(15,2) CHECK (amount > 0),
    description VARCHAR(255),
    expense_date DATE NOT NULL,
    merchant VARCHAR(255),
    tags JSONB,
    receipt_url VARCHAR(500),
    is_recurring BOOLEAN DEFAULT FALSE,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
)
```

**Key Features**:
- Receipt attachment support
- JSONB tags for flexible categorization
- Recurring expense tracking
- Full-text search on descriptions
- Merchant tracking

### Income Table
```sql
income (
    income_id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES users,
    category_id INTEGER REFERENCES categories,
    amount NUMERIC(15,2) CHECK (amount > 0),
    description VARCHAR(255),
    income_date DATE NOT NULL,
    source VARCHAR(255),
    tags JSONB,
    is_recurring BOOLEAN DEFAULT FALSE,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
)
```

**Key Features**:
- Source tracking (employer, client, etc.)
- Recurring income patterns
- JSONB tags for categorization
- Date-based queries optimized

### Budgets Table
```sql
budgets (
    budget_id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES users,
    category_id INTEGER REFERENCES categories,
    name VARCHAR(255) NOT NULL,
    amount NUMERIC(15,2) NOT NULL,
    period VARCHAR(20) CHECK IN ('daily', 'weekly', 'monthly', 'quarterly', 'yearly', 'custom'),
    start_date DATE NOT NULL,
    end_date DATE,
    alert_threshold NUMERIC(5,2) CHECK (0-100) DEFAULT 80.00,
    is_active BOOLEAN DEFAULT TRUE,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
)
```

**Key Features**:
- Flexible period types
- Alert threshold (percentage)
- Category-based budgets
- Active/inactive state management
- Date range support

### Bank Accounts Table
```sql
bank_accounts (
    bank_account_id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES users,
    bank_name VARCHAR(255) NOT NULL,
    account_number VARCHAR(100),
    account_type VARCHAR(50),
    access_token TEXT (encrypted),
    refresh_token TEXT (encrypted),
    expires_at TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    last_sync TIMESTAMP,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
)
```

**Key Features**:
- OAuth token storage (encrypted)
- Sync status tracking
- Multiple bank support
- Token expiration handling

### Bank Transactions Table
```sql
bank_transactions (
    bank_transaction_id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES users,
    bank_account_id INTEGER REFERENCES bank_accounts,
    transaction_id VARCHAR(255) UNIQUE,
    amount NUMERIC(15,2) NOT NULL,
    transaction_type VARCHAR(20),
    description TEXT,
    merchant_name VARCHAR(255),
    transaction_date DATE NOT NULL,
    posted_date DATE,
    category_id INTEGER REFERENCES categories,
    is_categorized BOOLEAN DEFAULT FALSE,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
)
```

**Key Features**:
- Automatic categorization
- Merchant name extraction
- Transaction vs posted date tracking
- Duplicate prevention via unique transaction_id

### Investments Table
```sql
investments (
    investment_id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES users,
    investment_type VARCHAR(50) CHECK IN ('stock', 'bond', 'mutual_fund', 'etf', 'crypto', 'real_estate', 'commodity', 'other'),
    symbol VARCHAR(20),
    name VARCHAR(255) NOT NULL,
    quantity NUMERIC(20,8) CHECK (quantity > 0),
    purchase_price NUMERIC(15,2) NOT NULL,
    current_price NUMERIC(15,2) NOT NULL,
    purchase_date DATE NOT NULL,
    notes TEXT,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
)
```

**Key Features**:
- Multiple investment types
- High-precision quantity (8 decimals for crypto)
- Gain/loss calculation support
- Symbol tracking for stocks/crypto
- Purchase vs current price tracking

### Notifications Table
```sql
notifications (
    notification_id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES users,
    type VARCHAR(50) CHECK IN ('expense', 'income', 'budget_alert', 'goal_reached', 'investment_update', 'bank_sync', 'general'),
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    related_entity_type VARCHAR(50),
    related_entity_id VARCHAR(100),
    action_url VARCHAR(500),
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
)
```

**Key Features**:
- Multiple notification types
- Entity relationship tracking
- Deep linking support (action_url)
- Read status tracking
- Timestamp for read actions

### Notification Preferences Table
```sql
notification_preferences (
    preference_id SERIAL PRIMARY KEY,
    user_id UUID UNIQUE REFERENCES users,
    email_on_expense BOOLEAN DEFAULT TRUE,
    email_on_income BOOLEAN DEFAULT TRUE,
    email_on_budget_alert BOOLEAN DEFAULT TRUE,
    push_on_expense BOOLEAN DEFAULT TRUE,
    push_on_income BOOLEAN DEFAULT TRUE,
    push_on_budget_alert BOOLEAN DEFAULT TRUE,
    in_app_notifications BOOLEAN DEFAULT TRUE,
    daily_digest BOOLEAN DEFAULT FALSE,
    weekly_report BOOLEAN DEFAULT FALSE,
    monthly_report BOOLEAN DEFAULT TRUE,
    quiet_hours_enabled BOOLEAN DEFAULT FALSE,
    quiet_hours_start TIME DEFAULT '22:00:00',
    quiet_hours_end TIME DEFAULT '08:00:00',
    created_at TIMESTAMP,
    updated_at TIMESTAMP
)
```

**Key Features**:
- Granular notification control
- Email and push preferences
- Digest scheduling
- Quiet hours support
- Per-event-type configuration

### Security Settings Table
```sql
security_settings (
    security_id SERIAL PRIMARY KEY,
    user_id UUID UNIQUE REFERENCES users,
    two_factor_enabled BOOLEAN DEFAULT FALSE,
    two_factor_method VARCHAR(20) CHECK IN ('email', 'sms', 'authenticator'),
    biometric_enabled BOOLEAN DEFAULT FALSE,
    login_alerts_enabled BOOLEAN DEFAULT TRUE,
    password_changed_at TIMESTAMP,
    last_login_at TIMESTAMP,
    session_timeout_minutes INTEGER DEFAULT 30,
    allow_remember_device BOOLEAN DEFAULT TRUE,
    ip_whitelist_enabled BOOLEAN DEFAULT FALSE,
    active_sessions INTEGER DEFAULT 1,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
)
```

**Key Features**:
- Multi-factor authentication
- Biometric support
- Session management
- IP whitelisting capability
- Login alert tracking

### Audit Logs Table
```sql
audit_logs (
    log_id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES users,
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50),
    entity_id VARCHAR(100),
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP
)
```

**Key Features**:
- Complete change tracking
- JSONB for flexible data storage
- IP and user agent logging
- Entity relationship tracking
- Immutable (no updates/deletes)

## Views

### Monthly Expense Summary
```sql
monthly_expense_summary
- Aggregates expenses by month and category
- Includes count, total, and average
- Excludes soft-deleted records
```

### Monthly Income Summary
```sql
monthly_income_summary
- Aggregates income by month and category
- Includes count, total, and average
- Excludes soft-deleted records
```

### Budget Progress
```sql
budget_progress
- Real-time budget vs actual spending
- Percentage used calculation
- Remaining amount tracking
- Joins budgets with expenses
```

## Indexes

All tables include strategic indexes for:
- User ID lookups (all tables)
- Date range queries (expenses, income, transactions)
- Soft delete filtering (is_deleted)
- Category filtering
- Status fields
- JSONB fields (GIN indexes for tags)

## Constraints

### Check Constraints
- Amount fields: Must be positive
- Enum fields: Validated against allowed values
- Email format: Regex validation
- Percentage fields: 0-100 range

### Foreign Keys
- All user-related tables cascade on user deletion
- Category references allow NULL for uncategorized items
- Account references maintain referential integrity

## Triggers

### Auto-Update Timestamps
All tables with `updated_at` columns have triggers to automatically update the timestamp on row modification.

## Security

### Application User
- Role: `rupaya_app`
- Permissions: SELECT, INSERT, UPDATE, DELETE on all tables
- Permissions: SELECT on all views
- Permissions: USAGE on all sequences

### Token Storage
- All tokens (OAuth, access, refresh) stored encrypted
- Never logged in audit trails
- Secure deletion on logout

## Data Retention

- Soft deletes used throughout
- Audit logs: 2 years retention
- Expired tokens: Auto-cleanup via cron
- Data exports: 30-day expiration

## Performance Considerations

### Partitioning (Future)
Consider partitioning for:
- `transactions` by month
- `audit_logs` by quarter
- `expenses` by year

### Archival Strategy
- Archive deleted records older than 1 year
- Move old audit logs to cold storage
- Export historical data for analytics

## Backup Strategy

- Automated daily backups
- Point-in-time recovery enabled
- 30-day backup retention
- Encrypted backups to S3

## Migration History

- `001_init.sql` - Initial schema
- `002_add_phone_otp.sql` - Phone verification
- `003_complete_api_schema.sql` - Complete API implementation (Current)

## Usage

### Setup Database
```bash
chmod +x backend/scripts/setup-database.sh
./backend/scripts/setup-database.sh
```

### Manual Migration
```bash
psql -h localhost -U postgres -d rupaya -f backend/migrations/003_complete_api_schema.sql
```

### Verify Setup
```sql
-- Count tables
SELECT COUNT(*) FROM information_schema.tables 
WHERE table_schema = 'public' AND table_type = 'BASE TABLE';

-- Count indexes
SELECT COUNT(*) FROM pg_indexes WHERE schemaname = 'public';

-- Check system categories
SELECT * FROM categories WHERE is_system = TRUE;
```

## Support

For database issues:
1. Check connection settings in `.env`
2. Verify PostgreSQL is running
3. Review migration logs
4. Check audit_logs for errors
