-- ============================================================================
-- RytGuard MVP Schema - Simplified for Hackathon
-- ============================================================================
-- Purpose: Minimum viable schema for Safe Balance calculation and AI analysis
-- Tables: 6 core tables only
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- For fuzzy merchant matching

-- ============================================================================
-- TABLE 1: USERS (Simplified)
-- ============================================================================
CREATE TABLE users (
    user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    external_user_id VARCHAR(100) UNIQUE NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    current_balance DECIMAL(15, 2) DEFAULT 0.00 NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- ============================================================================
-- TABLE 2: TRANSACTIONS (Core Ledger)
-- ============================================================================
CREATE TABLE transactions (
    transaction_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    external_transaction_id VARCHAR(100) UNIQUE NOT NULL,

    amount DECIMAL(15, 2) NOT NULL,
    transaction_type VARCHAR(20) NOT NULL CHECK (transaction_type IN ('DEBIT', 'CREDIT', 'TRANSFER')),
    description TEXT,
    merchant_name VARCHAR(255),
    category VARCHAR(100),

    balance_after DECIMAL(15, 2) NOT NULL,
    transaction_date TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,

    status VARCHAR(20) DEFAULT 'PROCESSED' CHECK (status IN ('PENDING', 'PROCESSED', 'FAILED'))
);

-- ============================================================================
-- TABLE 3: RECURRING_LIABILITIES (Subscriptions, Loans, BNPL)
-- ============================================================================
CREATE TABLE recurring_liabilities (
    liability_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,

    liability_type VARCHAR(30) NOT NULL CHECK (liability_type IN ('SUBSCRIPTION', 'LOAN', 'BNPL', 'UTILITY', 'INSURANCE')),
    liability_name VARCHAR(255) NOT NULL,
    amount DECIMAL(15, 2) NOT NULL,

    recurrence_pattern VARCHAR(20) NOT NULL CHECK (recurrence_pattern IN ('WEEKLY', 'BIWEEKLY', 'MONTHLY', 'QUARTERLY', 'YEARLY')),
    next_due_date DATE NOT NULL,
    last_paid_date DATE,

    is_verified BOOLEAN DEFAULT FALSE NOT NULL, -- User confirmed this recurring payment
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- ============================================================================
-- TABLE 4: PATTERN_LIBRARY (Pre-loaded Malaysian Patterns for AI)
-- ============================================================================
CREATE TABLE pattern_library (
    pattern_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    service_name VARCHAR(100) NOT NULL UNIQUE,
    keywords TEXT[] NOT NULL, -- Array of keywords for matching
    typical_amount_min DECIMAL(10, 2),
    typical_amount_max DECIMAL(10, 2),
    category VARCHAR(50) NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- ============================================================================
-- TABLE 5: PROJECTED_PAYMENTS (Pre-calculated upcoming bills)
-- ============================================================================
CREATE TABLE projected_payments (
    payment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    liability_id UUID NOT NULL REFERENCES recurring_liabilities(liability_id) ON DELETE CASCADE,

    payment_date DATE NOT NULL,
    amount DECIMAL(15, 2) NOT NULL,
    payment_status VARCHAR(20) DEFAULT 'UNPAID' CHECK (payment_status IN ('UNPAID', 'PAID', 'SKIPPED')),

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,

    UNIQUE(liability_id, payment_date)
);

-- ============================================================================
-- TABLE 6: CONVERSATION_HISTORY (For Claude AI Context)
-- ============================================================================
CREATE TABLE conversation_history (
    message_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,

    role VARCHAR(20) NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
    message_text TEXT NOT NULL,

    safe_balance_at_time DECIMAL(15, 2), -- Safe balance when message was sent
    metadata JSONB, -- Store tool calls, thinking, etc.

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- ============================================================================
-- INDEXES (Critical for Performance)
-- ============================================================================

-- User lookups
CREATE INDEX idx_users_external_id ON users(external_user_id);

-- Transaction queries
CREATE INDEX idx_transactions_user_date ON transactions(user_id, transaction_date DESC);
CREATE INDEX idx_transactions_merchant ON transactions USING gin(merchant_name gin_trgm_ops);

-- Recurring liabilities
CREATE INDEX idx_liabilities_user_active ON recurring_liabilities(user_id) WHERE is_active = true;
CREATE INDEX idx_liabilities_next_due ON recurring_liabilities(next_due_date) WHERE is_active = true;

-- Projected payments (most queried)
CREATE INDEX idx_projected_user_upcoming ON projected_payments(user_id, payment_date) WHERE payment_status = 'UNPAID';

-- Conversation history
CREATE INDEX idx_conversation_user_time ON conversation_history(user_id, created_at DESC);

-- Pattern library fuzzy search
CREATE INDEX idx_pattern_keywords ON pattern_library USING gin(keywords);

-- ============================================================================
-- VIEWS (Pre-calculated Safe Balance)
-- ============================================================================

-- View: User Safe Balance Summary
CREATE OR REPLACE VIEW v_user_safe_balance AS
SELECT
    u.user_id,
    u.external_user_id,
    u.full_name,
    u.current_balance,
    COALESCE(SUM(pp.amount), 0) AS upcoming_liabilities_30days,
    u.current_balance - COALESCE(SUM(pp.amount), 0) AS safe_balance,
    CASE
        WHEN u.current_balance - COALESCE(SUM(pp.amount), 0) > u.current_balance * 0.3 THEN 'HEALTHY'
        WHEN u.current_balance - COALESCE(SUM(pp.amount), 0) > 0 THEN 'WARNING'
        ELSE 'CRITICAL'
    END AS status
FROM users u
LEFT JOIN projected_payments pp ON u.user_id = pp.user_id
    AND pp.payment_date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '30 days'
    AND pp.payment_status = 'UNPAID'
GROUP BY u.user_id, u.external_user_id, u.full_name, u.current_balance;

-- View: Upcoming Payments (Next 30 Days)
CREATE OR REPLACE VIEW v_upcoming_payments_30days AS
SELECT
    pp.user_id,
    u.external_user_id,
    rl.liability_name,
    rl.liability_type,
    pp.payment_date,
    pp.amount,
    pp.payment_status
FROM projected_payments pp
JOIN users u ON pp.user_id = u.user_id
JOIN recurring_liabilities rl ON pp.liability_id = rl.liability_id
WHERE pp.payment_date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '30 days'
    AND pp.payment_status = 'UNPAID'
ORDER BY pp.payment_date ASC;

-- ============================================================================
-- FUNCTIONS (MCP Tool Integration)
-- ============================================================================

-- Function 1: Calculate Safe Balance
CREATE OR REPLACE FUNCTION calculate_safe_balance(
    p_user_id UUID,
    p_lookahead_days INTEGER DEFAULT 30
)
RETURNS TABLE (
    current_balance DECIMAL(15, 2),
    upcoming_liabilities DECIMAL(15, 2),
    safe_balance DECIMAL(15, 2),
    status TEXT,
    upcoming_count INTEGER,
    next_payment_date DATE,
    next_payment_amount DECIMAL(15, 2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        u.current_balance,
        COALESCE(SUM(pp.amount), 0)::DECIMAL(15, 2) AS upcoming_liabilities,
        (u.current_balance - COALESCE(SUM(pp.amount), 0))::DECIMAL(15, 2) AS safe_balance,
        CASE
            WHEN u.current_balance - COALESCE(SUM(pp.amount), 0) > u.current_balance * 0.3 THEN 'HEALTHY'
            WHEN u.current_balance - COALESCE(SUM(pp.amount), 0) > 0 THEN 'WARNING'
            ELSE 'CRITICAL'
        END AS status,
        COUNT(pp.payment_id)::INTEGER AS upcoming_count,
        MIN(pp.payment_date) AS next_payment_date,
        (SELECT amount FROM projected_payments
         WHERE user_id = p_user_id
         AND payment_status = 'UNPAID'
         AND payment_date >= CURRENT_DATE
         ORDER BY payment_date LIMIT 1)::DECIMAL(15, 2) AS next_payment_amount
    FROM users u
    LEFT JOIN projected_payments pp ON u.user_id = pp.user_id
        AND pp.payment_date BETWEEN CURRENT_DATE AND CURRENT_DATE + p_lookahead_days
        AND pp.payment_status = 'UNPAID'
    WHERE u.user_id = p_user_id
    GROUP BY u.user_id, u.current_balance;
END;
$$ LANGUAGE plpgsql;

-- Function 2: Get Recurring Liabilities (MCP Tool)
CREATE OR REPLACE FUNCTION get_recurring_liabilities(
    p_user_id UUID,
    p_lookahead_days INTEGER DEFAULT 30
)
RETURNS TABLE (
    liability_name VARCHAR(255),
    liability_type VARCHAR(30),
    amount DECIMAL(15, 2),
    next_due_date DATE,
    recurrence_pattern VARCHAR(20),
    is_verified BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        rl.liability_name,
        rl.liability_type,
        rl.amount,
        rl.next_due_date,
        rl.recurrence_pattern,
        rl.is_verified
    FROM recurring_liabilities rl
    WHERE rl.user_id = p_user_id
        AND rl.is_active = true
        AND rl.next_due_date BETWEEN CURRENT_DATE AND CURRENT_DATE + p_lookahead_days
    ORDER BY rl.next_due_date ASC;
END;
$$ LANGUAGE plpgsql;

-- Function 3: Generate Projected Payments (Auto-run when liability added)
CREATE OR REPLACE FUNCTION generate_projected_payments(
    p_liability_id UUID,
    p_months_ahead INTEGER DEFAULT 12
)
RETURNS INTEGER AS $$
DECLARE
    v_user_id UUID;
    v_amount DECIMAL(15, 2);
    v_next_due_date DATE;
    v_recurrence_pattern VARCHAR(20);
    v_payment_date DATE;
    v_count INTEGER := 0;
BEGIN
    -- Get liability details
    SELECT user_id, amount, next_due_date, recurrence_pattern
    INTO v_user_id, v_amount, v_next_due_date, v_recurrence_pattern
    FROM recurring_liabilities
    WHERE liability_id = p_liability_id;

    -- Delete existing projected payments
    DELETE FROM projected_payments WHERE liability_id = p_liability_id AND payment_status = 'UNPAID';

    -- Generate payments based on recurrence pattern
    v_payment_date := v_next_due_date;

    WHILE v_payment_date <= CURRENT_DATE + (p_months_ahead || ' months')::INTERVAL LOOP
        INSERT INTO projected_payments (user_id, liability_id, payment_date, amount)
        VALUES (v_user_id, p_liability_id, v_payment_date, v_amount)
        ON CONFLICT (liability_id, payment_date) DO NOTHING;

        v_count := v_count + 1;

        -- Calculate next payment date based on recurrence
        v_payment_date := CASE v_recurrence_pattern
            WHEN 'WEEKLY' THEN v_payment_date + INTERVAL '7 days'
            WHEN 'BIWEEKLY' THEN v_payment_date + INTERVAL '14 days'
            WHEN 'MONTHLY' THEN v_payment_date + INTERVAL '1 month'
            WHEN 'QUARTERLY' THEN v_payment_date + INTERVAL '3 months'
            WHEN 'YEARLY' THEN v_payment_date + INTERVAL '1 year'
            ELSE v_payment_date + INTERVAL '1 month' -- Default to monthly
        END;
    END LOOP;

    RETURN v_count;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- TRIGGERS (Automation)
-- ============================================================================

-- Auto-generate projected payments when liability is created/updated
CREATE OR REPLACE FUNCTION trigger_generate_projected_payments()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND NEW.is_active = TRUE)) THEN
        PERFORM generate_projected_payments(NEW.liability_id, 12);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_auto_generate_payments
AFTER INSERT OR UPDATE ON recurring_liabilities
FOR EACH ROW
EXECUTE FUNCTION trigger_generate_projected_payments();

-- Update user balance when transaction is inserted
CREATE OR REPLACE FUNCTION trigger_update_user_balance()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE users
    SET current_balance = NEW.balance_after,
        updated_at = CURRENT_TIMESTAMP
    WHERE user_id = NEW.user_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_balance
AFTER INSERT ON transactions
FOR EACH ROW
EXECUTE FUNCTION trigger_update_user_balance();

-- ============================================================================
-- SEED DATA: Malaysian Pattern Library
-- ============================================================================

INSERT INTO pattern_library (service_name, keywords, typical_amount_min, typical_amount_max, category, description) VALUES
-- Subscriptions
('Netflix', ARRAY['netflix', 'nflx'], 17.00, 55.00, 'SUBSCRIPTION', 'Video streaming service'),
('Spotify', ARRAY['spotify', 'spfy'], 9.90, 19.90, 'SUBSCRIPTION', 'Music streaming service'),
('Disney+', ARRAY['disney', 'disney+', 'disneyplus'], 34.90, 54.90, 'SUBSCRIPTION', 'Video streaming service'),
('YouTube Premium', ARRAY['youtube premium', 'yt premium', 'ytpremium'], 17.90, 33.90, 'SUBSCRIPTION', 'Video streaming without ads'),

-- BNPL Services
('SpayLater', ARRAY['spaylater', 'spay later', 'shopeepay later'], 10.00, 5000.00, 'BNPL', 'Shopee Buy Now Pay Later'),
('Atome', ARRAY['atome', 'atome payment'], 10.00, 5000.00, 'BNPL', 'Buy Now Pay Later service'),
('GrabPayLater', ARRAY['grabpaylater', 'grab pay later', 'gpl'], 10.00, 3000.00, 'BNPL', 'Grab Buy Now Pay Later'),
('Hoolah', ARRAY['hoolah', 'hoolah payment'], 10.00, 2000.00, 'BNPL', 'Buy Now Pay Later service'),

-- Loans
('PTPTN', ARRAY['ptptn', 'ptptn loan', 'education loan'], 50.00, 500.00, 'LOAN', 'Education loan repayment'),
('Car Loan', ARRAY['car loan', 'vehicle loan', 'auto loan', 'hire purchase'], 200.00, 2000.00, 'LOAN', 'Vehicle financing'),
('Housing Loan', ARRAY['housing loan', 'home loan', 'mortgage'], 500.00, 5000.00, 'LOAN', 'Property financing'),

-- Utilities
('TNB', ARRAY['tnb', 'tenaga nasional', 'electricity'], 50.00, 500.00, 'UTILITY', 'Electricity bill'),
('Air Selangor', ARRAY['air selangor', 'syabas', 'water bill'], 20.00, 200.00, 'UTILITY', 'Water bill'),
('Unifi', ARRAY['unifi', 'tm', 'telekom', 'streamyx'], 99.00, 299.00, 'UTILITY', 'Internet and phone service'),
('Maxis', ARRAY['maxis', 'hotlink'], 30.00, 200.00, 'UTILITY', 'Mobile service provider'),
('Celcom', ARRAY['celcom', 'xpax'], 30.00, 200.00, 'UTILITY', 'Mobile service provider'),
('Digi', ARRAY['digi', 'digi prepaid'], 30.00, 150.00, 'UTILITY', 'Mobile service provider'),

-- Appliances
('Cuckoo', ARRAY['cuckoo', 'cuckoo malaysia'], 50.00, 200.00, 'SUBSCRIPTION', 'Water purifier rental'),
('Coway', ARRAY['coway', 'coway malaysia'], 50.00, 300.00, 'SUBSCRIPTION', 'Water purifier and air purifier rental'),

-- Insurance
('Great Eastern', ARRAY['great eastern', 'great eastern life'], 100.00, 1000.00, 'INSURANCE', 'Life and health insurance'),
('Prudential', ARRAY['prudential', 'pru', 'pruventure'], 100.00, 1000.00, 'INSURANCE', 'Life and health insurance'),
('AIA', ARRAY['aia', 'aia insurance'], 100.00, 1000.00, 'INSURANCE', 'Life and health insurance'),
('Allianz', ARRAY['allianz', 'allianz malaysia'], 100.00, 800.00, 'INSURANCE', 'General and life insurance')

ON CONFLICT (service_name) DO NOTHING;

-- ============================================================================
-- EXAMPLE QUERY: For API/MCP Integration
-- ============================================================================

/*
-- Get user's safe balance
SELECT * FROM calculate_safe_balance(
    (SELECT user_id FROM users WHERE external_user_id = 'user123'),
    30
);

-- Get upcoming liabilities for next 30 days
SELECT * FROM get_recurring_liabilities(
    (SELECT user_id FROM users WHERE external_user_id = 'user123'),
    30
);

-- View safe balance dashboard
SELECT * FROM v_user_safe_balance WHERE external_user_id = 'user123';

-- View upcoming payments
SELECT * FROM v_upcoming_payments_30days WHERE external_user_id = 'user123';

-- Add a new recurring liability (will auto-generate projected payments)
INSERT INTO recurring_liabilities (
    user_id, liability_type, liability_name, amount, recurrence_pattern, next_due_date, is_verified
) VALUES (
    (SELECT user_id FROM users WHERE external_user_id = 'user123'),
    'SUBSCRIPTION',
    'Netflix Premium',
    55.00,
    'MONTHLY',
    '2024-12-15',
    true
);
*/
