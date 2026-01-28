-- Add phone fields to users
ALTER TABLE users
    ADD COLUMN phone_number VARCHAR(20) UNIQUE,
    ADD COLUMN phone_verified BOOLEAN DEFAULT FALSE;

CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone_number);

-- OTP table for phone-based auth
CREATE TABLE IF NOT EXISTS phone_otps (
    otp_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone_number VARCHAR(20) NOT NULL,
    code_hash VARCHAR(255) NOT NULL,
    purpose VARCHAR(20) NOT NULL DEFAULT 'signup',
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    attempt_count INT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_phone_otps_phone ON phone_otps(phone_number);
CREATE INDEX IF NOT EXISTS idx_phone_otps_expires_at ON phone_otps(expires_at);
