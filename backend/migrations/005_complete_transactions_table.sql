-- Add missing columns to transactions table
ALTER TABLE transactions 
ADD COLUMN IF NOT EXISTS account_id UUID REFERENCES accounts(account_id),
ADD COLUMN IF NOT EXISTS to_account_id UUID REFERENCES accounts(account_id),
ADD COLUMN IF NOT EXISTS amount NUMERIC(15,2),
ADD COLUMN IF NOT EXISTS currency VARCHAR(3) DEFAULT 'INR',
ADD COLUMN IF NOT EXISTS transaction_type VARCHAR(20),
ADD COLUMN IF NOT EXISTS category_id UUID REFERENCES categories(category_id),
ADD COLUMN IF NOT EXISTS description TEXT,
ADD COLUMN IF NOT EXISTS notes TEXT,
ADD COLUMN IF NOT EXISTS location VARCHAR(255),
ADD COLUMN IF NOT EXISTS merchant VARCHAR(255),
ADD COLUMN IF NOT EXISTS tags TEXT[],
ADD COLUMN IF NOT EXISTS attachment_url VARCHAR(500),
ADD COLUMN IF NOT EXISTS transaction_date DATE,
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN DEFAULT FALSE;

-- Add constraints
ALTER TABLE transactions
ADD CONSTRAINT amount_positive CHECK (amount > 0),
ADD CONSTRAINT transaction_type_check CHECK (transaction_type IN ('income', 'expense', 'transfer'));

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_transactions_account_id ON transactions(account_id);
CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(user_id, transaction_date DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_type ON transactions(transaction_type);
CREATE INDEX IF NOT EXISTS idx_transactions_category ON transactions(category_id);
