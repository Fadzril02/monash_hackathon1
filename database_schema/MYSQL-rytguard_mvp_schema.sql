-- ============================================================================
-- RytGuard MVP Schema - MySQL/TiDB Version
-- ============================================================================
-- Purpose: Minimum viable schema for Safe Balance calculation and AI analysis
-- Tables: 6 core tables only
-- Converted from PostgreSQL to MySQL syntax
-- ============================================================================

-- NOTE: This schema is optimized for MySQL 8.0+ and TiDB
-- Key changes from PostgreSQL version:
--   - UUID → CHAR(36) with UUID() function
--   - TIMESTAMPTZ → DATETIME
--   - TEXT[] arrays → JSON
--   - JSONB → JSON
--   - Removed PostgreSQL extensions (uuid-ossp, pg_trgm)
--   - Converted plpgsql functions to MySQL stored procedures
--   - GIN indexes → FULLTEXT indexes

-- ============================================================================
-- TABLE 1: USERS (Simplified)
-- ============================================================================
CREATE TABLE users (
    user_id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    external_user_id VARCHAR(100) UNIQUE NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    current_balance DECIMAL(15, 2) DEFAULT 0.00 NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL
);

-- ============================================================================
-- TABLE 2: TRANSACTIONS (Core Ledger)
-- ============================================================================
CREATE TABLE transactions (
    transaction_id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    user_id CHAR(36) NOT NULL,
    external_transaction_id VARCHAR(100) UNIQUE NOT NULL,

    amount DECIMAL(15, 2) NOT NULL,
    transaction_type VARCHAR(20) NOT NULL CHECK (transaction_type IN ('DEBIT', 'CREDIT', 'TRANSFER')),
    description TEXT,
    merchant_name VARCHAR(255),
    category VARCHAR(100),

    balance_after DECIMAL(15, 2) NOT NULL,
    transaction_date DATETIME NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,

    status VARCHAR(20) DEFAULT 'PROCESSED' CHECK (status IN ('PENDING', 'PROCESSED', 'FAILED')),

    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- ============================================================================
-- TABLE 3: RECURRING_LIABILITIES (Subscriptions, Loans, BNPL)
-- ============================================================================
CREATE TABLE recurring_liabilities (
    liability_id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    user_id CHAR(36) NOT NULL,

    liability_type VARCHAR(30) NOT NULL CHECK (liability_type IN ('SUBSCRIPTION', 'LOAN', 'BNPL', 'UTILITY', 'INSURANCE')),
    liability_name VARCHAR(255) NOT NULL,
    amount DECIMAL(15, 2) NOT NULL,

    recurrence_pattern VARCHAR(20) NOT NULL CHECK (recurrence_pattern IN ('WEEKLY', 'BIWEEKLY', 'MONTHLY', 'QUARTERLY', 'YEARLY')),
    next_due_date DATE NOT NULL,
    last_paid_date DATE,

    is_verified BOOLEAN DEFAULT FALSE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,

    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- ============================================================================
-- TABLE 4: PATTERN_LIBRARY (Pre-loaded Malaysian Patterns for AI)
-- ============================================================================
CREATE TABLE pattern_library (
    pattern_id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    service_name VARCHAR(100) NOT NULL UNIQUE,
    keywords JSON NOT NULL, -- Changed from TEXT[] to JSON array
    typical_amount_min DECIMAL(10, 2),
    typical_amount_max DECIMAL(10, 2),
    category VARCHAR(50) NOT NULL,
    description TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- ============================================================================
-- TABLE 5: PROJECTED_PAYMENTS (Pre-calculated upcoming bills)
-- ============================================================================
CREATE TABLE projected_payments (
    payment_id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    user_id CHAR(36) NOT NULL,
    liability_id CHAR(36) NOT NULL,

    payment_date DATE NOT NULL,
    amount DECIMAL(15, 2) NOT NULL,
    payment_status VARCHAR(20) DEFAULT 'UNPAID' CHECK (payment_status IN ('UNPAID', 'PAID', 'SKIPPED')),

    created_at DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,

    UNIQUE KEY unique_liability_date (liability_id, payment_date),
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (liability_id) REFERENCES recurring_liabilities(liability_id) ON DELETE CASCADE
);

-- ============================================================================
-- TABLE 6: CONVERSATION_HISTORY (For Claude AI Context)
-- ============================================================================
CREATE TABLE conversation_history (
    message_id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    user_id CHAR(36) NOT NULL,

    role VARCHAR(20) NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
    message_text TEXT NOT NULL,

    safe_balance_at_time DECIMAL(15, 2),
    metadata JSON, -- Changed from JSONB to JSON

    created_at DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,

    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- ============================================================================
-- INDEXES (Critical for Performance)
-- ============================================================================

-- User lookups
CREATE INDEX idx_users_external_id ON users(external_user_id);

-- Transaction queries
CREATE INDEX idx_transactions_user_date ON transactions(user_id, transaction_date DESC);
CREATE FULLTEXT INDEX idx_transactions_merchant ON transactions(merchant_name); -- Changed from GIN to FULLTEXT

-- Recurring liabilities
CREATE INDEX idx_liabilities_user_active ON recurring_liabilities(user_id, is_active);
CREATE INDEX idx_liabilities_next_due ON recurring_liabilities(next_due_date, is_active);

-- Projected payments (most queried)
CREATE INDEX idx_projected_user_upcoming ON projected_payments(user_id, payment_date, payment_status);

-- Conversation history
CREATE INDEX idx_conversation_user_time ON conversation_history(user_id, created_at DESC);

-- Pattern library keyword search
-- Note: JSON searching in MySQL uses JSON_CONTAINS or JSON_SEARCH functions

-- ============================================================================
-- VIEWS (Pre-calculated Safe Balance)
-- ============================================================================

-- View: User Safe Balance Summary
DROP VIEW IF EXISTS v_user_safe_balance;
CREATE VIEW v_user_safe_balance AS
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
    AND pp.payment_date BETWEEN CURRENT_DATE AND DATE_ADD(CURRENT_DATE, INTERVAL 30 DAY)
    AND pp.payment_status = 'UNPAID'
GROUP BY u.user_id, u.external_user_id, u.full_name, u.current_balance;

-- View: Upcoming Payments (Next 30 Days)
DROP VIEW IF EXISTS v_upcoming_payments_30days;
CREATE VIEW v_upcoming_payments_30days AS
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
WHERE pp.payment_date BETWEEN CURRENT_DATE AND DATE_ADD(CURRENT_DATE, INTERVAL 30 DAY)
    AND pp.payment_status = 'UNPAID'
ORDER BY pp.payment_date ASC;

-- ============================================================================
-- STORED PROCEDURES (MCP Tool Integration)
-- ============================================================================

-- Procedure 1: Calculate Safe Balance
DROP PROCEDURE IF EXISTS calculate_safe_balance;

DELIMITER $$

CREATE PROCEDURE calculate_safe_balance(
    IN p_user_id CHAR(36),
    IN p_lookahead_days INT
)
BEGIN
    SELECT
        u.current_balance,
        COALESCE(SUM(pp.amount), 0) AS upcoming_liabilities,
        (u.current_balance - COALESCE(SUM(pp.amount), 0)) AS safe_balance,
        CASE
            WHEN u.current_balance - COALESCE(SUM(pp.amount), 0) > u.current_balance * 0.3 THEN 'HEALTHY'
            WHEN u.current_balance - COALESCE(SUM(pp.amount), 0) > 0 THEN 'WARNING'
            ELSE 'CRITICAL'
        END AS status,
        COUNT(pp.payment_id) AS upcoming_count,
        MIN(pp.payment_date) AS next_payment_date,
        (SELECT amount FROM projected_payments
         WHERE user_id = p_user_id
         AND payment_status = 'UNPAID'
         AND payment_date >= CURRENT_DATE
         ORDER BY payment_date LIMIT 1) AS next_payment_amount
    FROM users u
    LEFT JOIN projected_payments pp ON u.user_id = pp.user_id
        AND pp.payment_date BETWEEN CURRENT_DATE AND DATE_ADD(CURRENT_DATE, INTERVAL p_lookahead_days DAY)
        AND pp.payment_status = 'UNPAID'
    WHERE u.user_id = p_user_id
    GROUP BY u.user_id, u.current_balance;
END$$

DELIMITER ;

-- Procedure 2: Get Recurring Liabilities
DROP PROCEDURE IF EXISTS get_recurring_liabilities;

DELIMITER $$

CREATE PROCEDURE get_recurring_liabilities(
    IN p_user_id CHAR(36),
    IN p_lookahead_days INT
)
BEGIN
    SELECT
        rl.liability_name,
        rl.liability_type,
        rl.amount,
        rl.next_due_date,
        rl.recurrence_pattern,
        rl.is_verified
    FROM recurring_liabilities rl
    WHERE rl.user_id = p_user_id
        AND rl.is_active = TRUE
        AND rl.next_due_date BETWEEN CURRENT_DATE AND DATE_ADD(CURRENT_DATE, INTERVAL p_lookahead_days DAY)
    ORDER BY rl.next_due_date ASC;
END$$

DELIMITER ;

-- Procedure 3: Generate Projected Payments
DROP PROCEDURE IF EXISTS generate_projected_payments;

DELIMITER $$

CREATE PROCEDURE generate_projected_payments(
    IN p_liability_id CHAR(36),
    IN p_months_ahead INT
)
BEGIN
    DECLARE v_user_id CHAR(36);
    DECLARE v_amount DECIMAL(15, 2);
    DECLARE v_next_due_date DATE;
    DECLARE v_recurrence_pattern VARCHAR(20);
    DECLARE v_payment_date DATE;
    DECLARE v_count INT DEFAULT 0;
    DECLARE v_end_date DATE;

    -- Get liability details
    SELECT user_id, amount, next_due_date, recurrence_pattern
    INTO v_user_id, v_amount, v_next_due_date, v_recurrence_pattern
    FROM recurring_liabilities
    WHERE liability_id = p_liability_id;

    -- Delete existing projected payments
    DELETE FROM projected_payments
    WHERE liability_id = p_liability_id AND payment_status = 'UNPAID';

    -- Calculate end date
    SET v_end_date = DATE_ADD(CURRENT_DATE, INTERVAL p_months_ahead MONTH);
    SET v_payment_date = v_next_due_date;

    -- Generate payments based on recurrence pattern
    WHILE v_payment_date <= v_end_date DO
        INSERT INTO projected_payments (user_id, liability_id, payment_date, amount)
        VALUES (v_user_id, p_liability_id, v_payment_date, v_amount)
        ON DUPLICATE KEY UPDATE amount = v_amount;

        SET v_count = v_count + 1;

        -- Calculate next payment date based on recurrence
        SET v_payment_date = CASE v_recurrence_pattern
            WHEN 'WEEKLY' THEN DATE_ADD(v_payment_date, INTERVAL 7 DAY)
            WHEN 'BIWEEKLY' THEN DATE_ADD(v_payment_date, INTERVAL 14 DAY)
            WHEN 'MONTHLY' THEN DATE_ADD(v_payment_date, INTERVAL 1 MONTH)
            WHEN 'QUARTERLY' THEN DATE_ADD(v_payment_date, INTERVAL 3 MONTH)
            WHEN 'YEARLY' THEN DATE_ADD(v_payment_date, INTERVAL 1 YEAR)
            ELSE DATE_ADD(v_payment_date, INTERVAL 1 MONTH)
        END;
    END WHILE;

    SELECT v_count AS payments_generated;
END$$

DELIMITER ;

-- ============================================================================
-- TRIGGERS (Automation)
-- ============================================================================

-- Auto-generate projected payments when liability is created/updated
DROP TRIGGER IF EXISTS trg_auto_generate_payments_insert;
DROP TRIGGER IF EXISTS trg_auto_generate_payments_update;

DELIMITER $$

CREATE TRIGGER trg_auto_generate_payments_insert
AFTER INSERT ON recurring_liabilities
FOR EACH ROW
BEGIN
    CALL generate_projected_payments(NEW.liability_id, 12);
END$$

CREATE TRIGGER trg_auto_generate_payments_update
AFTER UPDATE ON recurring_liabilities
FOR EACH ROW
BEGIN
    IF NEW.is_active = TRUE THEN
        CALL generate_projected_payments(NEW.liability_id, 12);
    END IF;
END$$

DELIMITER ;

-- Update user balance when transaction is inserted
DROP TRIGGER IF EXISTS trg_update_balance;

DELIMITER $$

CREATE TRIGGER trg_update_balance
AFTER INSERT ON transactions
FOR EACH ROW
BEGIN
    UPDATE users
    SET current_balance = NEW.balance_after,
        updated_at = CURRENT_TIMESTAMP
    WHERE user_id = NEW.user_id;
END$$

DELIMITER ;

-- ============================================================================
-- SEED DATA: Malaysian Pattern Library
-- ============================================================================

INSERT INTO pattern_library (service_name, keywords, typical_amount_min, typical_amount_max, category, description) VALUES
-- Subscriptions (JSON arrays instead of PostgreSQL arrays)
('Netflix', JSON_ARRAY('netflix', 'nflx'), 17.00, 55.00, 'SUBSCRIPTION', 'Video streaming service'),
('Spotify', JSON_ARRAY('spotify', 'spfy'), 9.90, 19.90, 'SUBSCRIPTION', 'Music streaming service'),
('Disney+', JSON_ARRAY('disney', 'disney+', 'disneyplus'), 34.90, 54.90, 'SUBSCRIPTION', 'Video streaming service'),
('YouTube Premium', JSON_ARRAY('youtube premium', 'yt premium', 'ytpremium'), 17.90, 33.90, 'SUBSCRIPTION', 'Video streaming without ads'),

-- BNPL Services
('SpayLater', JSON_ARRAY('spaylater', 'spay later', 'shopeepay later'), 10.00, 5000.00, 'BNPL', 'Shopee Buy Now Pay Later'),
('Atome', JSON_ARRAY('atome', 'atome payment'), 10.00, 5000.00, 'BNPL', 'Buy Now Pay Later service'),
('GrabPayLater', JSON_ARRAY('grabpaylater', 'grab pay later', 'gpl'), 10.00, 3000.00, 'BNPL', 'Grab Buy Now Pay Later'),
('Hoolah', JSON_ARRAY('hoolah', 'hoolah payment'), 10.00, 2000.00, 'BNPL', 'Buy Now Pay Later service'),

-- Loans
('PTPTN', JSON_ARRAY('ptptn', 'ptptn loan', 'education loan'), 50.00, 500.00, 'LOAN', 'Education loan repayment'),
('Car Loan', JSON_ARRAY('car loan', 'vehicle loan', 'auto loan', 'hire purchase'), 200.00, 2000.00, 'LOAN', 'Vehicle financing'),
('Housing Loan', JSON_ARRAY('housing loan', 'home loan', 'mortgage'), 500.00, 5000.00, 'LOAN', 'Property financing'),

-- Utilities
('TNB', JSON_ARRAY('tnb', 'tenaga nasional', 'electricity'), 50.00, 500.00, 'UTILITY', 'Electricity bill'),
('Air Selangor', JSON_ARRAY('air selangor', 'syabas', 'water bill'), 20.00, 200.00, 'UTILITY', 'Water bill'),
('Unifi', JSON_ARRAY('unifi', 'tm', 'telekom', 'streamyx'), 99.00, 299.00, 'UTILITY', 'Internet and phone service'),
('Maxis', JSON_ARRAY('maxis', 'hotlink'), 30.00, 200.00, 'UTILITY', 'Mobile service provider'),
('Celcom', JSON_ARRAY('celcom', 'xpax'), 30.00, 200.00, 'UTILITY', 'Mobile service provider'),
('Digi', JSON_ARRAY('digi', 'digi prepaid'), 30.00, 150.00, 'UTILITY', 'Mobile service provider'),

-- Appliances
('Cuckoo', JSON_ARRAY('cuckoo', 'cuckoo malaysia'), 50.00, 200.00, 'SUBSCRIPTION', 'Water purifier rental'),
('Coway', JSON_ARRAY('coway', 'coway malaysia'), 50.00, 300.00, 'SUBSCRIPTION', 'Water purifier and air purifier rental'),

-- Insurance
('Great Eastern', JSON_ARRAY('great eastern', 'great eastern life'), 100.00, 1000.00, 'INSURANCE', 'Life and health insurance'),
('Prudential', JSON_ARRAY('prudential', 'pru', 'pruventure'), 100.00, 1000.00, 'INSURANCE', 'Life and health insurance'),
('AIA', JSON_ARRAY('aia', 'aia insurance'), 100.00, 1000.00, 'INSURANCE', 'Life and health insurance'),
('Allianz', JSON_ARRAY('allianz', 'allianz malaysia'), 100.00, 800.00, 'INSURANCE', 'General and life insurance')

ON DUPLICATE KEY UPDATE service_name = service_name;

-- ============================================================================
-- EXAMPLE USAGE: For API/MCP Integration
-- ============================================================================

/*
-- Get user's safe balance
CALL calculate_safe_balance(
    (SELECT user_id FROM users WHERE external_user_id = 'user123'),
    30
);

-- Get upcoming liabilities for next 30 days
CALL get_recurring_liabilities(
    (SELECT user_id FROM users WHERE external_user_id = 'user123'),
    30
);

-- View safe balance dashboard
SELECT * FROM v_user_safe_balance WHERE external_user_id = 'user123';

-- View upcoming payments
SELECT * FROM v_upcoming_payments_30days WHERE external_user_id = 'user123';

-- Add a new recurring liability (will auto-generate projected payments via trigger)
INSERT INTO recurring_liabilities (
    user_id, liability_type, liability_name, amount, recurrence_pattern, next_due_date, is_verified
) VALUES (
    (SELECT user_id FROM users WHERE external_user_id = 'user123'),
    'SUBSCRIPTION',
    'Netflix Premium',
    55.00,
    'MONTHLY',
    '2024-12-15',
    TRUE
);
*/
