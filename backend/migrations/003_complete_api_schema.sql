-- ====================================================================
-- RUPAYA Database Schema - Complete API Implementation
-- Version: 3.0
-- Date: 2026-02-01
-- Description: Complete schema for all implemented API endpoints
-- ====================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ====================================================================
-- USER MANAGEMENT TABLES
-- ====================================================================

-- Users Table (Enhanced)
CREATE TABLE IF NOT EXISTS users (
    user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    email_verified BOOLEAN DEFAULT FALSE,
    password_hash VARCHAR(255),
    name VARCHAR(255),
    phone_number VARCHAR(20),
    phone_verified BOOLEAN DEFAULT FALSE,
    country_code VARCHAR(2) DEFAULT 'IN',
    currency_preference VARCHAR(3) DEFAULT 'INR',
    timezone VARCHAR(50) DEFAULT 'UTC',
    theme_preference VARCHAR(20) DEFAULT 'light',
    language_preference VARCHAR(10) DEFAULT 'en',
    oauth_provider VARCHAR(20),
    oauth_provider_id VARCHAR(255),
    mfa_enabled BOOLEAN DEFAULT FALSE,
    mfa_secret VARCHAR(255),
    account_status VARCHAR(20) DEFAULT 'active',
    last_login_at TIMESTAMP WITH TIME ZONE,
    last_login_device_id VARCHAR(255),
    login_attempt_count INT DEFAULT 0,
    login_attempt_last_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT email_valid CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$'),
    CONSTRAINT account_status_check CHECK (account_status IN ('active', 'inactive', 'suspended', 'deleted'))
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at);
CREATE INDEX IF NOT EXISTS idx_users_status ON users(account_status);

-- Devices Table
CREATE TABLE IF NOT EXISTS devices (
    device_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    device_name VARCHAR(255),
    device_type VARCHAR(20),
    device_fingerprint VARCHAR(255) UNIQUE,
    is_active BOOLEAN DEFAULT TRUE,
    last_used_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_devices_user_id ON devices(user_id);
CREATE INDEX IF NOT EXISTS idx_devices_fingerprint ON devices(device_fingerprint);

-- ====================================================================
-- ACCOUNT & TRANSACTION TABLES
-- ====================================================================

-- Accounts Table
CREATE TABLE IF NOT EXISTS accounts (
    account_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    account_type VARCHAR(20) NOT NULL,
    currency VARCHAR(3) DEFAULT 'INR',
    current_balance NUMERIC(15,2) DEFAULT 0,
    is_default BOOLEAN DEFAULT FALSE,
    icon VARCHAR(50),
    color VARCHAR(7),
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT account_type_check CHECK (account_type IN ('cash', 'bank', 'credit_card', 'investment', 'savings'))
);

CREATE INDEX IF NOT EXISTS idx_accounts_user_id ON accounts(user_id);
CREATE INDEX IF NOT EXISTS idx_accounts_type ON accounts(account_type);
CREATE INDEX IF NOT EXISTS idx_accounts_deleted ON accounts(is_deleted);

-- Categories Table
CREATE TABLE IF NOT EXISTS categories (
    category_id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES users(user_id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(200),
    category_type VARCHAR(20) NOT NULL,
    icon VARCHAR(50),
    color VARCHAR(7),
    is_system BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT category_type_check CHECK (category_type IN ('income', 'expense', 'transfer'))
);

CREATE INDEX IF NOT EXISTS idx_categories_user_id ON categories(user_id);
CREATE INDEX IF NOT EXISTS idx_categories_type ON categories(category_type);
CREATE INDEX IF NOT EXISTS idx_categories_deleted ON categories(is_deleted);

-- Insert system categories if not exists
INSERT INTO categories (name, category_type, icon, color, is_system) 
SELECT * FROM (VALUES
    ('Salary', 'income', 'briefcase', '#10B981', TRUE),
    ('Business', 'income', 'trending-up', '#10B981', TRUE),
    ('Investment', 'income', 'pie-chart', '#10B981', TRUE),
    ('Groceries', 'expense', 'shopping-cart', '#EF4444', TRUE),
    ('Dining & Restaurants', 'expense', 'utensils', '#EF4444', TRUE),
    ('Transportation', 'expense', 'car', '#EF4444', TRUE),
    ('Shopping', 'expense', 'shopping-bag', '#EF4444', TRUE),
    ('Entertainment', 'expense', 'film', '#EF4444', TRUE),
    ('Healthcare', 'expense', 'activity', '#EF4444', TRUE),
    ('Bills & Utilities', 'expense', 'file-text', '#EF4444', TRUE),
    ('Education', 'expense', 'book', '#EF4444', TRUE),
    ('Transfer', 'transfer', 'refresh-cw', '#3B82F6', TRUE)
) AS v(name, category_type, icon, color, is_system)
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE is_system = TRUE);

-- Transactions Table
CREATE TABLE IF NOT EXISTS transactions (
    transaction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    account_id UUID NOT NULL REFERENCES accounts(account_id),
    to_account_id UUID REFERENCES accounts(account_id),
    amount NUMERIC(15,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'INR',
    transaction_type VARCHAR(20) NOT NULL,
    category_id INTEGER REFERENCES categories(category_id),
    description TEXT,
    notes TEXT,
    location VARCHAR(255),
    merchant VARCHAR(255),
    tags TEXT[],
    attachment_url VARCHAR(500),
    transaction_date DATE NOT NULL,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT amount_positive CHECK (amount > 0),
    CONSTRAINT transaction_type_check CHECK (transaction_type IN ('income', 'expense', 'transfer'))
);

CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_account_id ON transactions(account_id);
CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(user_id, transaction_date DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_type ON transactions(transaction_type);
CREATE INDEX IF NOT EXISTS idx_transactions_category ON transactions(category_id);
CREATE INDEX IF NOT EXISTS idx_transactions_deleted ON transactions(is_deleted);

-- ====================================================================
-- EXPENSE MANAGEMENT TABLES
-- ====================================================================

-- Expenses Table
CREATE TABLE IF NOT EXISTS expenses (
    expense_id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    category_id INTEGER REFERENCES categories(category_id),
    amount NUMERIC(15,2) NOT NULL,
    description VARCHAR(255),
    notes TEXT,
    expense_date DATE NOT NULL,
    merchant VARCHAR(255),
    payment_method VARCHAR(50),
    tags JSONB,
    receipt_url VARCHAR(500),
    is_recurring BOOLEAN DEFAULT FALSE,
    recurring_pattern VARCHAR(50),
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT amount_positive CHECK (amount > 0)
);

CREATE INDEX IF NOT EXISTS idx_expenses_user_id ON expenses(user_id);
CREATE INDEX IF NOT EXISTS idx_expenses_category ON expenses(category_id);
CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses(expense_date DESC);
CREATE INDEX IF NOT EXISTS idx_expenses_deleted ON expenses(is_deleted);
CREATE INDEX IF NOT EXISTS idx_expenses_tags ON expenses USING GIN (tags);

-- ====================================================================
-- INCOME MANAGEMENT TABLES
-- ====================================================================

-- Income Table
CREATE TABLE IF NOT EXISTS income (
    income_id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    category_id INTEGER REFERENCES categories(category_id),
    amount NUMERIC(15,2) NOT NULL,
    description VARCHAR(255),
    notes TEXT,
    income_date DATE NOT NULL,
    source VARCHAR(255),
    payment_method VARCHAR(50),
    tags JSONB,
    is_recurring BOOLEAN DEFAULT FALSE,
    recurring_pattern VARCHAR(50),
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT amount_positive CHECK (amount > 0)
);

CREATE INDEX IF NOT EXISTS idx_income_user_id ON income(user_id);
CREATE INDEX IF NOT EXISTS idx_income_category ON income(category_id);
CREATE INDEX IF NOT EXISTS idx_income_date ON income(income_date DESC);
CREATE INDEX IF NOT EXISTS idx_income_deleted ON income(is_deleted);
CREATE INDEX IF NOT EXISTS idx_income_tags ON income USING GIN (tags);

-- ====================================================================
-- BUDGET MANAGEMENT TABLES
-- ====================================================================

-- Budgets Table
CREATE TABLE IF NOT EXISTS budgets (
    budget_id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    category_id INTEGER REFERENCES categories(category_id),
    name VARCHAR(255) NOT NULL,
    amount NUMERIC(15,2) NOT NULL,
    period VARCHAR(20) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    alert_threshold NUMERIC(5,2) DEFAULT 80.00,
    is_active BOOLEAN DEFAULT TRUE,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT period_check CHECK (period IN ('daily', 'weekly', 'monthly', 'quarterly', 'yearly', 'custom')),
    CONSTRAINT threshold_check CHECK (alert_threshold >= 0 AND alert_threshold <= 100)
);

CREATE INDEX IF NOT EXISTS idx_budgets_user_id ON budgets(user_id);
CREATE INDEX IF NOT EXISTS idx_budgets_category_id ON budgets(category_id);
CREATE INDEX IF NOT EXISTS idx_budgets_active ON budgets(is_active);
CREATE INDEX IF NOT EXISTS idx_budgets_deleted ON budgets(is_deleted);

-- ====================================================================
-- BANK INTEGRATION TABLES
-- ====================================================================

-- Bank Accounts Table
CREATE TABLE IF NOT EXISTS bank_accounts (
    bank_account_id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    bank_name VARCHAR(255) NOT NULL,
    account_number VARCHAR(100),
    account_type VARCHAR(50),
    access_token TEXT,
    refresh_token TEXT,
    expires_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE,
    last_sync TIMESTAMP WITH TIME ZONE,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_bank_accounts_user_id ON bank_accounts(user_id);
CREATE INDEX IF NOT EXISTS idx_bank_accounts_active ON bank_accounts(is_active);
CREATE INDEX IF NOT EXISTS idx_bank_accounts_deleted ON bank_accounts(is_deleted);

-- Bank Transactions Table
CREATE TABLE IF NOT EXISTS bank_transactions (
    bank_transaction_id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    bank_account_id INTEGER NOT NULL REFERENCES bank_accounts(bank_account_id) ON DELETE CASCADE,
    transaction_id VARCHAR(255) UNIQUE,
    amount NUMERIC(15,2) NOT NULL,
    transaction_type VARCHAR(20) NOT NULL,
    description TEXT,
    merchant_name VARCHAR(255),
    transaction_date DATE NOT NULL,
    posted_date DATE,
    category_id INTEGER REFERENCES categories(category_id),
    is_categorized BOOLEAN DEFAULT FALSE,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_bank_transactions_user_id ON bank_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_bank_transactions_account_id ON bank_transactions(bank_account_id);
CREATE INDEX IF NOT EXISTS idx_bank_transactions_date ON bank_transactions(posted_date DESC);
CREATE INDEX IF NOT EXISTS idx_bank_transactions_deleted ON bank_transactions(is_deleted);

-- ====================================================================
-- INVESTMENT MANAGEMENT TABLES
-- ====================================================================

-- Investments Table
CREATE TABLE IF NOT EXISTS investments (
    investment_id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    investment_type VARCHAR(50) NOT NULL,
    symbol VARCHAR(20),
    name VARCHAR(255) NOT NULL,
    quantity NUMERIC(20,8) NOT NULL,
    purchase_price NUMERIC(15,2) NOT NULL,
    current_price NUMERIC(15,2) NOT NULL,
    purchase_date DATE NOT NULL,
    notes TEXT,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT investment_type_check CHECK (investment_type IN ('stock', 'bond', 'mutual_fund', 'etf', 'crypto', 'real_estate', 'commodity', 'other')),
    CONSTRAINT quantity_positive CHECK (quantity > 0)
);

CREATE INDEX IF NOT EXISTS idx_investments_user_id ON investments(user_id);
CREATE INDEX IF NOT EXISTS idx_investments_type ON investments(investment_type);
CREATE INDEX IF NOT EXISTS idx_investments_deleted ON investments(is_deleted);

-- ====================================================================
-- NOTIFICATION TABLES
-- ====================================================================

-- Notifications Table
CREATE TABLE IF NOT EXISTS notifications (
    notification_id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    related_entity_type VARCHAR(50),
    related_entity_id VARCHAR(100),
    action_url VARCHAR(500),
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP WITH TIME ZONE,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT notification_type_check CHECK (type IN ('expense', 'income', 'budget_alert', 'goal_reached', 'investment_update', 'bank_sync', 'general'))
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created ON notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_deleted ON notifications(is_deleted);

-- Notification Preferences Table
CREATE TABLE IF NOT EXISTS notification_preferences (
    preference_id SERIAL PRIMARY KEY,
    user_id UUID UNIQUE NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    email_on_expense BOOLEAN DEFAULT TRUE,
    email_on_income BOOLEAN DEFAULT TRUE,
    email_on_budget_alert BOOLEAN DEFAULT TRUE,
    email_on_goal_reached BOOLEAN DEFAULT TRUE,
    email_on_investment_update BOOLEAN DEFAULT TRUE,
    email_on_bank_sync BOOLEAN DEFAULT TRUE,
    push_on_expense BOOLEAN DEFAULT TRUE,
    push_on_income BOOLEAN DEFAULT TRUE,
    push_on_budget_alert BOOLEAN DEFAULT TRUE,
    push_on_goal_reached BOOLEAN DEFAULT TRUE,
    push_on_investment_update BOOLEAN DEFAULT TRUE,
    push_on_bank_sync BOOLEAN DEFAULT TRUE,
    in_app_notifications BOOLEAN DEFAULT TRUE,
    daily_digest BOOLEAN DEFAULT FALSE,
    weekly_report BOOLEAN DEFAULT FALSE,
    monthly_report BOOLEAN DEFAULT TRUE,
    quiet_hours_enabled BOOLEAN DEFAULT FALSE,
    quiet_hours_start TIME DEFAULT '22:00:00',
    quiet_hours_end TIME DEFAULT '08:00:00',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notification_preferences_user_id ON notification_preferences(user_id);

-- ====================================================================
-- SETTINGS TABLES
-- ====================================================================

-- User Settings Table
CREATE TABLE IF NOT EXISTS user_settings (
    setting_id SERIAL PRIMARY KEY,
    user_id UUID UNIQUE NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    theme VARCHAR(20) DEFAULT 'light',
    language VARCHAR(10) DEFAULT 'en',
    currency VARCHAR(3) DEFAULT 'USD',
    date_format VARCHAR(20) DEFAULT 'MM/DD/YYYY',
    timezone VARCHAR(50) DEFAULT 'UTC',
    notifications_enabled BOOLEAN DEFAULT TRUE,
    two_factor_enabled BOOLEAN DEFAULT FALSE,
    auto_logout_minutes INTEGER DEFAULT 30,
    data_retention_days INTEGER DEFAULT 365,
    privacy_level VARCHAR(20) DEFAULT 'private',
    allow_analytics BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT theme_check CHECK (theme IN ('light', 'dark')),
    CONSTRAINT language_check CHECK (language IN ('en', 'es', 'fr', 'de', 'pt', 'ja', 'zh')),
    CONSTRAINT privacy_level_check CHECK (privacy_level IN ('private', 'friends', 'public'))
);

CREATE INDEX IF NOT EXISTS idx_user_settings_user_id ON user_settings(user_id);

-- Security Settings Table
CREATE TABLE IF NOT EXISTS security_settings (
    security_id SERIAL PRIMARY KEY,
    user_id UUID UNIQUE NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    two_factor_enabled BOOLEAN DEFAULT FALSE,
    two_factor_method VARCHAR(20) DEFAULT 'email',
    biometric_enabled BOOLEAN DEFAULT FALSE,
    login_alerts_enabled BOOLEAN DEFAULT TRUE,
    password_changed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login_at TIMESTAMP WITH TIME ZONE,
    session_timeout_minutes INTEGER DEFAULT 30,
    allow_remember_device BOOLEAN DEFAULT TRUE,
    ip_whitelist_enabled BOOLEAN DEFAULT FALSE,
    active_sessions INTEGER DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT two_factor_method_check CHECK (two_factor_method IN ('email', 'sms', 'authenticator'))
);

CREATE INDEX IF NOT EXISTS idx_security_settings_user_id ON security_settings(user_id);

-- Data Export Requests Table
CREATE TABLE IF NOT EXISTS data_exports (
    export_id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    export_type VARCHAR(50) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    file_path VARCHAR(500),
    requested_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT export_type_check CHECK (export_type IN ('full', 'expenses', 'income', 'budgets', 'transactions')),
    CONSTRAINT status_check CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'expired'))
);

CREATE INDEX IF NOT EXISTS idx_data_exports_user_id ON data_exports(user_id);
CREATE INDEX IF NOT EXISTS idx_data_exports_status ON data_exports(status);

-- Data Access Requests Table
CREATE TABLE IF NOT EXISTS data_access_requests (
    request_id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    request_type VARCHAR(50) NOT NULL,
    reason TEXT NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    requested_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    approved_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT request_status_check CHECK (status IN ('pending', 'approved', 'rejected', 'completed'))
);

CREATE INDEX IF NOT EXISTS idx_data_access_requests_user_id ON data_access_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_data_access_requests_status ON data_access_requests(status);

-- ====================================================================
-- RECURRING TRANSACTIONS TABLE
-- ====================================================================

CREATE TABLE IF NOT EXISTS recurring_transactions (
    recurring_id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    account_id UUID REFERENCES accounts(account_id),
    category_id INTEGER REFERENCES categories(category_id),
    amount NUMERIC(15,2) NOT NULL,
    transaction_type VARCHAR(20) NOT NULL,
    description VARCHAR(255),
    frequency VARCHAR(20) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    next_occurrence DATE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT recurring_frequency_check CHECK (frequency IN ('daily', 'weekly', 'biweekly', 'monthly', 'quarterly', 'yearly'))
);

CREATE INDEX IF NOT EXISTS idx_recurring_transactions_user_id ON recurring_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_recurring_transactions_next_occurrence ON recurring_transactions(next_occurrence);
CREATE INDEX IF NOT EXISTS idx_recurring_transactions_active ON recurring_transactions(is_active);

-- ====================================================================
-- AUDIT LOG TABLE
-- ====================================================================

CREATE TABLE IF NOT EXISTS audit_logs (
    log_id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES users(user_id),
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50),
    entity_id VARCHAR(100),
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON audit_logs(action);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created ON audit_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_entity ON audit_logs(entity_type, entity_id);

-- ====================================================================
-- FUNCTIONS & TRIGGERS
-- ====================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply updated_at trigger to all tables
DO $$
DECLARE
    t text;
BEGIN
    FOR t IN
        SELECT table_name 
        FROM information_schema.columns 
        WHERE column_name = 'updated_at' 
        AND table_schema = 'public'
    LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS update_%I_updated_at ON %I', t, t);
        EXECUTE format('CREATE TRIGGER update_%I_updated_at 
                       BEFORE UPDATE ON %I 
                       FOR EACH ROW 
                       EXECUTE FUNCTION update_updated_at_column()', t, t);
    END LOOP;
END;
$$ language 'plpgsql';

-- ====================================================================
-- VIEWS FOR REPORTING
-- ====================================================================

-- Monthly Expense Summary View
CREATE OR REPLACE VIEW monthly_expense_summary AS
SELECT 
    e.user_id,
    DATE_TRUNC('month', e.expense_date) AS month,
    c.name AS category_name,
    COUNT(*) AS transaction_count,
    SUM(e.amount) AS total_amount,
    AVG(e.amount) AS average_amount
FROM expenses e
LEFT JOIN categories c ON e.category_id = c.category_id
WHERE e.is_deleted = FALSE
GROUP BY e.user_id, DATE_TRUNC('month', e.expense_date), c.name;

-- Monthly Income Summary View
CREATE OR REPLACE VIEW monthly_income_summary AS
SELECT 
    i.user_id,
    DATE_TRUNC('month', i.income_date) AS month,
    c.name AS category_name,
    COUNT(*) AS transaction_count,
    SUM(i.amount) AS total_amount,
    AVG(i.amount) AS average_amount
FROM income i
LEFT JOIN categories c ON i.category_id = c.category_id
WHERE i.is_deleted = FALSE
GROUP BY i.user_id, DATE_TRUNC('month', i.income_date), c.name;

-- Budget Progress View
CREATE OR REPLACE VIEW budget_progress AS
SELECT 
    b.budget_id,
    b.user_id,
    b.name AS budget_name,
    b.amount AS budget_amount,
    b.period,
    b.start_date,
    b.end_date,
    COALESCE(SUM(e.amount), 0) AS spent_amount,
    b.amount - COALESCE(SUM(e.amount), 0) AS remaining_amount,
    CASE 
        WHEN b.amount > 0 THEN (COALESCE(SUM(e.amount), 0) / b.amount * 100)
        ELSE 0 
    END AS percentage_used
FROM budgets b
LEFT JOIN expenses e ON b.category_id = e.category_id 
    AND e.user_id = b.user_id 
    AND e.expense_date BETWEEN b.start_date AND COALESCE(b.end_date, CURRENT_DATE)
    AND e.is_deleted = FALSE
WHERE b.is_deleted = FALSE
GROUP BY b.budget_id, b.user_id, b.name, b.amount, b.period, b.start_date, b.end_date;

-- ====================================================================
-- GRANTS (Application User)
-- ====================================================================

-- Create application user if not exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'rupaya_app') THEN
        CREATE ROLE rupaya_app WITH LOGIN PASSWORD 'change_me_in_production';
    END IF;
END
$$;

-- Grant necessary permissions
GRANT CONNECT ON DATABASE postgres TO rupaya_app;
GRANT USAGE ON SCHEMA public TO rupaya_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO rupaya_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO rupaya_app;

-- Grant permissions on views
GRANT SELECT ON monthly_expense_summary TO rupaya_app;
GRANT SELECT ON monthly_income_summary TO rupaya_app;
GRANT SELECT ON budget_progress TO rupaya_app;

-- ====================================================================
-- INITIAL DATA VERIFICATION
-- ====================================================================

-- Verify tables created
DO $$
DECLARE
    table_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO table_count
    FROM information_schema.tables
    WHERE table_schema = 'public' 
    AND table_type = 'BASE TABLE';
    
    RAISE NOTICE 'Total tables created: %', table_count;
END
$$;

-- ====================================================================
-- END OF MIGRATION
-- ====================================================================
