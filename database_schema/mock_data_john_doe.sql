-- ============================================================================
-- REALISTIC MOCK DATA FOR JOHN DOE - 12 Months of Financial Activity
-- ============================================================================
-- User: John Doe
-- Starting Balance: MYR 2,800 (January 2025)
-- Primary Income: MYR 4,500 (monthly salary)
-- Side Income: Freelance work (irregular)
-- Period: January 2025 - December 2025
-- ============================================================================

-- Clean up existing data (if any) for this user
DO $$
DECLARE
    v_user_id UUID;
BEGIN
    SELECT user_id INTO v_user_id FROM users WHERE external_user_id = 'john_doe_001';
    IF v_user_id IS NOT NULL THEN
        DELETE FROM conversation_history WHERE user_id = v_user_id;
        DELETE FROM projected_payments WHERE user_id = v_user_id;
        DELETE FROM recurring_liabilities WHERE user_id = v_user_id;
        DELETE FROM transactions WHERE user_id = v_user_id;
        DELETE FROM users WHERE user_id = v_user_id;
    END IF;
END $$;

-- ============================================================================
-- 1. CREATE USER: JOHN DOE
-- ============================================================================
INSERT INTO users (external_user_id, full_name, email, current_balance, created_at, updated_at)
VALUES (
    'john_doe_001',
    'John Doe',
    'john.doe@example.com',
    2800.00, -- Starting balance
    '2025-01-01 08:00:00+08',
    CURRENT_TIMESTAMP
);

-- Get John Doe's user_id for subsequent inserts
DO $$
DECLARE
    v_user_id UUID;
    v_balance DECIMAL(15, 2);
    v_transaction_date TIMESTAMPTZ;
BEGIN
    SELECT user_id, current_balance INTO v_user_id, v_balance
    FROM users WHERE external_user_id = 'john_doe_001';

    -- ========================================================================
    -- 2. CREATE RECURRING LIABILITIES
    -- ========================================================================

    INSERT INTO recurring_liabilities (user_id, liability_type, liability_name, amount, recurrence_pattern, next_due_date, last_paid_date, is_verified, is_active)
    VALUES
    (v_user_id, 'SUBSCRIPTION', 'Netflix Premium', 55.00, 'MONTHLY', '2025-12-05', '2025-11-05', true, true),
    (v_user_id, 'SUBSCRIPTION', 'Spotify Premium', 19.90, 'MONTHLY', '2025-12-10', '2025-11-10', true, true),
    (v_user_id, 'SUBSCRIPTION', 'YouTube Premium', 17.90, 'MONTHLY', '2025-12-15', '2025-11-15', true, true),
    (v_user_id, 'UTILITY', 'TNB Electricity Bill', 185.50, 'MONTHLY', '2025-12-20', '2025-11-20', true, true),
    (v_user_id, 'UTILITY', 'Air Selangor Water Bill', 48.20, 'MONTHLY', '2025-12-22', '2025-11-22', true, true),
    (v_user_id, 'UTILITY', 'Unifi Internet', 139.00, 'MONTHLY', '2025-12-01', '2025-11-01', true, true),
    (v_user_id, 'UTILITY', 'Maxis Mobile Plan', 98.00, 'MONTHLY', '2025-12-08', '2025-11-08', true, true),
    (v_user_id, 'INSURANCE', 'Prudential Life Insurance', 285.00, 'MONTHLY', '2025-12-03', '2025-11-03', true, true),
    (v_user_id, 'LOAN', 'Car Loan Payment', 850.00, 'MONTHLY', '2025-12-12', '2025-11-12', true, true),
    (v_user_id, 'LOAN', 'PTPTN Education Loan', 200.00, 'MONTHLY', '2025-12-28', '2025-11-28', true, true);

    v_balance := 2800.00;

    -- ========================================================================
    -- JANUARY 2025
    -- ========================================================================
    v_transaction_date := '2025-01-01 09:00:00+08';
    v_balance := v_balance + 4500.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-JAN-001', 4500.00, 'CREDIT', 'Monthly Salary', 'TechCorp Malaysia', 'INCOME', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-01-01 10:30:00+08';
    v_balance := v_balance - 600.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-JAN-002', -600.00, 'DEBIT', 'Savings transfer', 'Maybank Savings', 'TRANSFER', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-01-01 14:20:00+08';
    v_balance := v_balance - 139.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-JAN-003', -139.00, 'DEBIT', 'Internet', 'Unifi', 'UTILITY', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-01-03 10:15:00+08';
    v_balance := v_balance - 285.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-JAN-004', -285.00, 'DEBIT', 'Insurance', 'Prudential', 'INSURANCE', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-01-05 08:05:00+08';
    v_balance := v_balance - 55.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-JAN-005', -55.00, 'DEBIT', 'Subscription', 'Netflix', 'SUBSCRIPTION', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-01-06 17:45:00+08';
    v_balance := v_balance - 245.80;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-JAN-006', -245.80, 'DEBIT', 'Groceries', 'AEON Big', 'GROCERIES', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-01-08 11:30:00+08';
    v_balance := v_balance - 98.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-JAN-007', -98.00, 'DEBIT', 'Mobile', 'Maxis', 'UTILITY', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-01-10 07:50:00+08';
    v_balance := v_balance - 19.90;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-JAN-008', -19.90, 'DEBIT', 'Music', 'Spotify', 'SUBSCRIPTION', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-01-12 09:00:00+08';
    v_balance := v_balance - 850.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-JAN-009', -850.00, 'DEBIT', 'Car loan', 'Maybank Auto', 'LOAN', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-01-13 10:00:00+08';
    v_balance := v_balance - 400.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-JAN-010', -400.00, 'DEBIT', 'Parents support', 'DuitNow', 'TRANSFER', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-01-15 08:10:00+08';
    v_balance := v_balance - 17.90;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-JAN-011', -17.90, 'DEBIT', 'Subscription', 'YouTube', 'SUBSCRIPTION', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-01-15 12:30:00+08';
    v_balance := v_balance - 125.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-JAN-012', -125.00, 'DEBIT', 'Petrol', 'Petronas', 'TRANSPORT', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-01-18 16:00:00+08';
    v_balance := v_balance + 750.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-JAN-013', 750.00, 'CREDIT', 'Freelance project', 'Client', 'INCOME', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-01-20 15:45:00+08';
    v_balance := v_balance - 185.50;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-JAN-014', -185.50, 'DEBIT', 'Electricity', 'TNB', 'UTILITY', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-01-20 18:20:00+08';
    v_balance := v_balance - 198.40;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-JAN-015', -198.40, 'DEBIT', 'Groceries', 'Giant', 'GROCERIES', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-01-22 12:30:00+08';
    v_balance := v_balance - 48.20;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-JAN-016', -48.20, 'DEBIT', 'Water', 'Air Selangor', 'UTILITY', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-01-25 20:00:00+08';
    v_balance := v_balance - 156.90;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-JAN-017', -156.90, 'DEBIT', 'Shopping', 'Shopee', 'SHOPPING', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-01-28 10:00:00+08';
    v_balance := v_balance - 200.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-JAN-018', -200.00, 'DEBIT', 'Education loan', 'PTPTN', 'LOAN', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-01-30 07:30:00+08';
    v_balance := v_balance - 118.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-JAN-019', -118.00, 'DEBIT', 'Petrol', 'Shell', 'TRANSPORT', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    -- ========================================================================
    -- FEBRUARY 2025
    -- ========================================================================
    v_transaction_date := '2025-02-01 09:00:00+08';
    v_balance := v_balance + 4500.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-FEB-001', 4500.00, 'CREDIT', 'Monthly Salary', 'TechCorp Malaysia', 'INCOME', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-02-01 10:30:00+08';
    v_balance := v_balance - 700.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-FEB-002', -700.00, 'DEBIT', 'Savings', 'Maybank Savings', 'TRANSFER', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-02-01 14:20:00+08';
    v_balance := v_balance - 139.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-FEB-003', -139.00, 'DEBIT', 'Internet', 'Unifi', 'UTILITY', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-02-03 10:15:00+08';
    v_balance := v_balance - 285.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-FEB-004', -285.00, 'DEBIT', 'Insurance', 'Prudential', 'INSURANCE', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-02-05 08:05:00+08';
    v_balance := v_balance - 55.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-FEB-005', -55.00, 'DEBIT', 'Subscription', 'Netflix', 'SUBSCRIPTION', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-02-07 17:45:00+08';
    v_balance := v_balance - 289.50;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-FEB-006', -289.50, 'DEBIT', 'Groceries', 'AEON Big', 'GROCERIES', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-02-08 11:30:00+08';
    v_balance := v_balance - 98.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-FEB-007', -98.00, 'DEBIT', 'Mobile', 'Maxis', 'UTILITY', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-02-10 07:50:00+08';
    v_balance := v_balance - 19.90;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-FEB-008', -19.90, 'DEBIT', 'Music', 'Spotify', 'SUBSCRIPTION', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    -- Chinese New Year spending
    v_transaction_date := '2025-02-11 15:00:00+08';
    v_balance := v_balance - 450.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-FEB-009', -450.00, 'DEBIT', 'CNY shopping', 'Shopping mall', 'SHOPPING', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-02-12 09:00:00+08';
    v_balance := v_balance - 850.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-FEB-010', -850.00, 'DEBIT', 'Car loan', 'Maybank Auto', 'LOAN', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-02-13 10:00:00+08';
    v_balance := v_balance - 400.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-FEB-011', -400.00, 'DEBIT', 'Parents support', 'DuitNow', 'TRANSFER', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-02-14 19:00:00+08';
    v_balance := v_balance - 185.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-FEB-012', -185.00, 'DEBIT', 'Valentine dinner', 'Restaurant', 'DINING', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-02-15 08:10:00+08';
    v_balance := v_balance - 17.90;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-FEB-013', -17.90, 'DEBIT', 'Subscription', 'YouTube', 'SUBSCRIPTION', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-02-16 12:30:00+08';
    v_balance := v_balance - 135.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-FEB-014', -135.00, 'DEBIT', 'Petrol', 'Petronas', 'TRANSPORT', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-02-20 15:45:00+08';
    v_balance := v_balance - 185.50;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-FEB-015', -185.50, 'DEBIT', 'Electricity', 'TNB', 'UTILITY', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-02-21 18:20:00+08';
    v_balance := v_balance - 167.80;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-FEB-016', -167.80, 'DEBIT', 'Groceries', 'Tesco', 'GROCERIES', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-02-22 12:30:00+08';
    v_balance := v_balance - 48.20;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-FEB-017', -48.20, 'DEBIT', 'Water', 'Air Selangor', 'UTILITY', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-02-28 10:00:00+08';
    v_balance := v_balance - 200.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-FEB-018', -200.00, 'DEBIT', 'Education loan', 'PTPTN', 'LOAN', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    -- ========================================================================
    -- MARCH 2025
    -- ========================================================================
    v_transaction_date := '2025-03-01 09:00:00+08';
    v_balance := v_balance + 4500.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-MAR-001', 4500.00, 'CREDIT', 'Monthly Salary', 'TechCorp Malaysia', 'INCOME', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-03-01 10:30:00+08';
    v_balance := v_balance - 800.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-MAR-002', -800.00, 'DEBIT', 'Savings', 'Maybank Savings', 'TRANSFER', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-03-01 14:20:00+08';
    v_balance := v_balance - 139.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-MAR-003', -139.00, 'DEBIT', 'Internet', 'Unifi', 'UTILITY', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-03-03 10:15:00+08';
    v_balance := v_balance - 285.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-MAR-004', -285.00, 'DEBIT', 'Insurance', 'Prudential', 'INSURANCE', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-03-05 08:05:00+08';
    v_balance := v_balance - 55.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-MAR-005', -55.00, 'DEBIT', 'Subscription', 'Netflix', 'SUBSCRIPTION', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-03-06 17:45:00+08';
    v_balance := v_balance - 312.30;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-MAR-006', -312.30, 'DEBIT', 'Groceries', 'AEON Big', 'GROCERIES', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-03-08 11:30:00+08';
    v_balance := v_balance - 98.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-MAR-007', -98.00, 'DEBIT', 'Mobile', 'Maxis', 'UTILITY', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-03-10 07:50:00+08';
    v_balance := v_balance - 19.90;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-MAR-008', -19.90, 'DEBIT', 'Music', 'Spotify', 'SUBSCRIPTION', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-03-11 07:30:00+08';
    v_balance := v_balance - 142.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-MAR-009', -142.00, 'DEBIT', 'Petrol', 'Petronas', 'TRANSPORT', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-03-12 09:00:00+08';
    v_balance := v_balance - 850.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-MAR-010', -850.00, 'DEBIT', 'Car loan', 'Maybank Auto', 'LOAN', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-03-13 10:00:00+08';
    v_balance := v_balance - 400.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-MAR-011', -400.00, 'DEBIT', 'Parents support', 'DuitNow', 'TRANSFER', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-03-15 08:10:00+08';
    v_balance := v_balance - 17.90;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-MAR-012', -17.90, 'DEBIT', 'Subscription', 'YouTube', 'SUBSCRIPTION', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-03-18 16:00:00+08';
    v_balance := v_balance + 650.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-MAR-013', 650.00, 'CREDIT', 'Freelance', 'Client', 'INCOME', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-03-20 15:45:00+08';
    v_balance := v_balance - 185.50;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-MAR-014', -185.50, 'DEBIT', 'Electricity', 'TNB', 'UTILITY', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-03-21 18:20:00+08';
    v_balance := v_balance - 223.40;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-MAR-015', -223.40, 'DEBIT', 'Groceries', 'Giant', 'GROCERIES', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-03-22 12:30:00+08';
    v_balance := v_balance - 48.20;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-MAR-016', -48.20, 'DEBIT', 'Water', 'Air Selangor', 'UTILITY', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-03-25 20:00:00+08';
    v_balance := v_balance - 198.50;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-MAR-017', -198.50, 'DEBIT', 'Shopping', 'Lazada', 'SHOPPING', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-03-28 10:00:00+08';
    v_balance := v_balance - 200.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-MAR-018', -200.00, 'DEBIT', 'Education loan', 'PTPTN', 'LOAN', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-03-30 07:30:00+08';
    v_balance := v_balance - 128.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-MAR-019', -128.00, 'DEBIT', 'Petrol', 'Shell', 'TRANSPORT', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    -- ========================================================================
    -- APRIL 2025
    -- ========================================================================
    v_transaction_date := '2025-04-01 09:00:00+08';
    v_balance := v_balance + 4500.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-APR-001', 4500.00, 'CREDIT', 'Salary', 'TechCorp Malaysia', 'INCOME', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-04-01 10:30:00+08';
    v_balance := v_balance - 750.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-APR-002', -750.00, 'DEBIT', 'Savings', 'Maybank Savings', 'TRANSFER', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-04-01 14:20:00+08';
    v_balance := v_balance - 139.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-APR-003', -139.00, 'DEBIT', 'Internet', 'Unifi', 'UTILITY', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    -- Ramadan period - more dining out for iftar
    v_transaction_date := '2025-04-02 19:00:00+08';
    v_balance := v_balance - 78.50;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-APR-004', -78.50, 'DEBIT', 'Iftar', 'Restaurant', 'DINING', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-04-03 10:15:00+08';
    v_balance := v_balance - 285.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-APR-005', -285.00, 'DEBIT', 'Insurance', 'Prudential', 'INSURANCE', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-04-05 08:05:00+08';
    v_balance := v_balance - 55.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-APR-006', -55.00, 'DEBIT', 'Subscription', 'Netflix', 'SUBSCRIPTION', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-04-06 17:45:00+08';
    v_balance := v_balance - 298.70;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-APR-007', -298.70, 'DEBIT', 'Groceries', 'AEON Big', 'GROCERIES', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-04-08 11:30:00+08';
    v_balance := v_balance - 98.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-APR-008', -98.00, 'DEBIT', 'Mobile', 'Maxis', 'UTILITY', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-04-10 07:50:00+08';
    v_balance := v_balance - 19.90;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-APR-009', -19.90, 'DEBIT', 'Music', 'Spotify', 'SUBSCRIPTION', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-04-11 07:30:00+08';
    v_balance := v_balance - 138.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-APR-010', -138.00, 'DEBIT', 'Petrol', 'Petronas', 'TRANSPORT', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-04-12 09:00:00+08';
    v_balance := v_balance - 850.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-APR-011', -850.00, 'DEBIT', 'Car loan', 'Maybank Auto', 'LOAN', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-04-13 10:00:00+08';
    v_balance := v_balance - 400.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-APR-012', -400.00, 'DEBIT', 'Parents support', 'DuitNow', 'TRANSFER', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-04-15 08:10:00+08';
    v_balance := v_balance - 17.90;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-APR-013', -17.90, 'DEBIT', 'Subscription', 'YouTube', 'SUBSCRIPTION', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-04-20 15:45:00+08';
    v_balance := v_balance - 185.50;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-APR-014', -185.50, 'DEBIT', 'Electricity', 'TNB', 'UTILITY', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-04-21 18:20:00+08';
    v_balance := v_balance - 187.90;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-APR-015', -187.90, 'DEBIT', 'Groceries', 'Tesco', 'GROCERIES', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-04-22 12:30:00+08';
    v_balance := v_balance - 48.20;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-APR-016', -48.20, 'DEBIT', 'Water', 'Air Selangor', 'UTILITY', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-04-28 10:00:00+08';
    v_balance := v_balance - 200.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-APR-017', -200.00, 'DEBIT', 'Education loan', 'PTPTN', 'LOAN', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-04-30 07:30:00+08';
    v_balance := v_balance - 132.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-APR-018', -132.00, 'DEBIT', 'Petrol', 'Shell', 'TRANSPORT', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    -- ========================================================================
    -- MAY 2025 (Continued with similar patterns through December)
    -- Due to length constraints, I'll continue with similar monthly patterns
    -- ========================================================================

    v_transaction_date := '2025-05-01 09:00:00+08';
    v_balance := v_balance + 4500.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-MAY-001', 4500.00, 'CREDIT', 'Salary', 'TechCorp Malaysia', 'INCOME', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-05-01 10:30:00+08';
    v_balance := v_balance - 800.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-MAY-002', -800.00, 'DEBIT', 'Savings', 'Maybank Savings', 'TRANSFER', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    -- Hari Raya expenses
    v_transaction_date := '2025-05-02 14:00:00+08';
    v_balance := v_balance - 680.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-MAY-003', -680.00, 'DEBIT', 'Raya shopping', 'Shopping mall', 'SHOPPING', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    -- Monthly bills continue...
    v_transaction_date := '2025-05-01 14:20:00+08';
    v_balance := v_balance - 139.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-MAY-004', -139.00, 'DEBIT', 'Internet', 'Unifi', 'UTILITY', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-05-03 10:15:00+08';
    v_balance := v_balance - 285.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-MAY-005', -285.00, 'DEBIT', 'Insurance', 'Prudential', 'INSURANCE', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-05-05 08:05:00+08';
    v_balance := v_balance - 55.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-MAY-006', -55.00, 'DEBIT', 'Netflix', 'Netflix', 'SUBSCRIPTION', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-05-08 11:30:00+08';
    v_balance := v_balance - 98.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-MAY-007', -98.00, 'DEBIT', 'Mobile', 'Maxis', 'UTILITY', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-05-10 07:50:00+08';
    v_balance := v_balance - 19.90;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-MAY-008', -19.90, 'DEBIT', 'Spotify', 'Spotify', 'SUBSCRIPTION', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-05-12 09:00:00+08';
    v_balance := v_balance - 850.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-MAY-009', -850.00, 'DEBIT', 'Car loan', 'Maybank Auto', 'LOAN', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-05-13 10:00:00+08';
    v_balance := v_balance - 400.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-MAY-010', -400.00, 'DEBIT', 'Parents', 'DuitNow', 'TRANSFER', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-05-15 08:10:00+08';
    v_balance := v_balance - 17.90;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-MAY-011', -17.90, 'DEBIT', 'YouTube', 'YouTube', 'SUBSCRIPTION', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-05-20 15:45:00+08';
    v_balance := v_balance - 185.50;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-MAY-012', -185.50, 'DEBIT', 'TNB', 'TNB', 'UTILITY', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-05-22 12:30:00+08';
    v_balance := v_balance - 48.20;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-MAY-013', -48.20, 'DEBIT', 'Water', 'Air Selangor', 'UTILITY', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-05-28 10:00:00+08';
    v_balance := v_balance - 200.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-MAY-014', -200.00, 'DEBIT', 'PTPTN', 'PTPTN', 'LOAN', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    -- Add groceries/fuel for May-Dec with similar patterns
    v_transaction_date := '2025-05-10 17:00:00+08';
    v_balance := v_balance - 276.50;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-MAY-015', -276.50, 'DEBIT', 'Groceries', 'AEON Big', 'GROCERIES', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-05-15 07:30:00+08';
    v_balance := v_balance - 145.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-MAY-016', -145.00, 'DEBIT', 'Petrol', 'Petronas', 'TRANSPORT', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-05-25 18:00:00+08';
    v_balance := v_balance - 198.30;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-MAY-017', -198.30, 'DEBIT', 'Groceries', 'Giant', 'GROCERIES', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    -- I'll create a simplified pattern for June-September to keep the file manageable
    -- Each month will have: Salary, Savings, Bills, Loans, Transfers, and typical expenses

    -- JUNE through SEPTEMBER (simplified with key transactions)
    FOR month_num IN 6..9 LOOP
        -- Salary
        v_transaction_date := make_timestamptz(2025, month_num, 1, 9, 0, 0, '+08');
        v_balance := v_balance + 4500.00;
        INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-' || to_char(v_transaction_date, 'MON') || '-001', 4500.00, 'CREDIT', 'Salary', 'TechCorp Malaysia', 'INCOME', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

        -- Savings
        v_transaction_date := make_timestamptz(2025, month_num, 1, 10, 30, 0, '+08');
        v_balance := v_balance - 800.00;
        INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-' || to_char(v_transaction_date, 'MON') || '-002', -800.00, 'DEBIT', 'Savings', 'Maybank', 'TRANSFER', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

        -- Bills (Unifi, Insurance, Netflix, Maxis, Spotify, YouTube)
        v_transaction_date := make_timestamptz(2025, month_num, 1, 14, 0, 0, '+08');
        v_balance := v_balance - 139.00;
        INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-' || to_char(v_transaction_date, 'MON') || '-003', -139.00, 'DEBIT', 'Internet', 'Unifi', 'UTILITY', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

        v_transaction_date := make_timestamptz(2025, month_num, 3, 10, 0, 0, '+08');
        v_balance := v_balance - 285.00;
        INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-' || to_char(v_transaction_date, 'MON') || '-004', -285.00, 'DEBIT', 'Insurance', 'Prudential', 'INSURANCE', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

        v_transaction_date := make_timestamptz(2025, month_num, 5, 8, 0, 0, '+08');
        v_balance := v_balance - 55.00;
        INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-' || to_char(v_transaction_date, 'MON') || '-005', -55.00, 'DEBIT', 'Netflix', 'Netflix', 'SUBSCRIPTION', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

        v_transaction_date := make_timestamptz(2025, month_num, 8, 11, 0, 0, '+08');
        v_balance := v_balance - 98.00;
        INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-' || to_char(v_transaction_date, 'MON') || '-006', -98.00, 'DEBIT', 'Mobile', 'Maxis', 'UTILITY', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

        v_transaction_date := make_timestamptz(2025, month_num, 10, 8, 0, 0, '+08');
        v_balance := v_balance - 19.90;
        INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-' || to_char(v_transaction_date, 'MON') || '-007', -19.90, 'DEBIT', 'Spotify', 'Spotify', 'SUBSCRIPTION', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

        v_transaction_date := make_timestamptz(2025, month_num, 15, 8, 0, 0, '+08');
        v_balance := v_balance - 17.90;
        INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-' || to_char(v_transaction_date, 'MON') || '-008', -17.90, 'DEBIT', 'YouTube', 'YouTube', 'SUBSCRIPTION', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

        -- Loans
        v_transaction_date := make_timestamptz(2025, month_num, 12, 9, 0, 0, '+08');
        v_balance := v_balance - 850.00;
        INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-' || to_char(v_transaction_date, 'MON') || '-009', -850.00, 'DEBIT', 'Car loan', 'Maybank', 'LOAN', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

        v_transaction_date := make_timestamptz(2025, month_num, 28, 10, 0, 0, '+08');
        v_balance := v_balance - 200.00;
        INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-' || to_char(v_transaction_date, 'MON') || '-010', -200.00, 'DEBIT', 'PTPTN', 'PTPTN', 'LOAN', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

        -- Utilities
        v_transaction_date := make_timestamptz(2025, month_num, 20, 15, 0, 0, '+08');
        v_balance := v_balance - 185.50;
        INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-' || to_char(v_transaction_date, 'MON') || '-011', -185.50, 'DEBIT', 'TNB', 'TNB', 'UTILITY', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

        v_transaction_date := make_timestamptz(2025, month_num, 22, 12, 0, 0, '+08');
        v_balance := v_balance - 48.20;
        INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-' || to_char(v_transaction_date, 'MON') || '-012', -48.20, 'DEBIT', 'Water', 'Air Selangor', 'UTILITY', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

        -- Parents
        v_transaction_date := make_timestamptz(2025, month_num, 13, 10, 0, 0, '+08');
        v_balance := v_balance - 400.00;
        INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-' || to_char(v_transaction_date, 'MON') || '-013', -400.00, 'DEBIT', 'Parents', 'DuitNow', 'TRANSFER', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

        -- Groceries (2-3 times per month)
        v_transaction_date := make_timestamptz(2025, month_num, 7, 17, 0, 0, '+08');
        v_balance := v_balance - (250 + (random() * 100)::numeric(10,2));
        INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-' || to_char(v_transaction_date, 'MON') || '-014', -(250 + (random() * 100)::numeric(10,2)), 'DEBIT', 'Groceries', 'AEON Big', 'GROCERIES', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

        v_transaction_date := make_timestamptz(2025, month_num, 18, 18, 0, 0, '+08');
        v_balance := v_balance - (200 + (random() * 80)::numeric(10,2));
        INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-' || to_char(v_transaction_date, 'MON') || '-015', -(200 + (random() * 80)::numeric(10,2)), 'DEBIT', 'Groceries', 'Giant', 'GROCERIES', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

        -- Fuel (2 times per month)
        v_transaction_date := make_timestamptz(2025, month_num, 11, 7, 30, 0, '+08');
        v_balance := v_balance - (130 + (random() * 20)::numeric(10,2));
        INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-' || to_char(v_transaction_date, 'MON') || '-016', -(130 + (random() * 20)::numeric(10,2)), 'DEBIT', 'Petrol', 'Petronas', 'TRANSPORT', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

        v_transaction_date := make_timestamptz(2025, month_num, 25, 8, 0, 0, '+08');
        v_balance := v_balance - (130 + (random() * 20)::numeric(10,2));
        INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-' || to_char(v_transaction_date, 'MON') || '-017', -(130 + (random() * 20)::numeric(10,2)), 'DEBIT', 'Petrol', 'Shell', 'TRANSPORT', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

        -- Occasional freelance income (30% chance each month)
        IF random() < 0.3 THEN
            v_transaction_date := make_timestamptz(2025, month_num, 15 + (random() * 10)::int, 16, 0, 0, '+08');
            v_balance := v_balance + (600 + (random() * 400)::numeric(10,2));
            INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-' || to_char(v_transaction_date, 'MON') || '-018', (600 + (random() * 400)::numeric(10,2)), 'CREDIT', 'Freelance', 'Client', 'INCOME', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');
        END IF;
    END LOOP;

    -- ========================================================================
    -- OCTOBER - DECEMBER 2025 (Full detail as before)
    -- ========================================================================

    -- Continue with Oct-Dec as provided earlier...
    v_transaction_date := '2025-10-01 09:00:00+08';
    v_balance := v_balance + 4500.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-OCT-001', 4500.00, 'CREDIT', 'Salary', 'TechCorp Malaysia', 'INCOME', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-10-01 10:30:00+08';
    v_balance := v_balance - 800.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-OCT-002', -800.00, 'DEBIT', 'Savings', 'Maybank', 'TRANSFER', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-10-01 14:20:00+08';
    v_balance := v_balance - 139.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-OCT-003', -139.00, 'DEBIT', 'Internet', 'Unifi', 'UTILITY', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-10-03 10:15:00+08';
    v_balance := v_balance - 285.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-OCT-004', -285.00, 'DEBIT', 'Insurance', 'Prudential', 'INSURANCE', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-10-05 08:05:00+08';
    v_balance := v_balance - 55.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-OCT-005', -55.00, 'DEBIT', 'Netflix', 'Netflix', 'SUBSCRIPTION', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-10-07 15:20:00+08';
    v_balance := v_balance + 600.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-OCT-006', 600.00, 'CREDIT', 'Freelance', 'Client', 'INCOME', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-10-08 11:30:00+08';
    v_balance := v_balance - 98.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-OCT-007', -98.00, 'DEBIT', 'Mobile', 'Maxis', 'UTILITY', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-10-10 07:50:00+08';
    v_balance := v_balance - 19.90;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-OCT-008', -19.90, 'DEBIT', 'Spotify', 'Spotify', 'SUBSCRIPTION', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-10-12 09:00:00+08';
    v_balance := v_balance - 850.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-OCT-009', -850.00, 'DEBIT', 'Car loan', 'Maybank', 'LOAN', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-10-13 10:00:00+08';
    v_balance := v_balance - 400.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-OCT-010', -400.00, 'DEBIT', 'Parents', 'DuitNow', 'TRANSFER', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-10-15 08:10:00+08';
    v_balance := v_balance - 17.90;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-OCT-011', -17.90, 'DEBIT', 'YouTube', 'YouTube', 'SUBSCRIPTION', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-10-20 15:45:00+08';
    v_balance := v_balance - 185.50;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-OCT-012', -185.50, 'DEBIT', 'TNB', 'TNB', 'UTILITY', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-10-22 12:30:00+08';
    v_balance := v_balance - 48.20;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-OCT-013', -48.20, 'DEBIT', 'Water', 'Air Selangor', 'UTILITY', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-10-28 10:00:00+08';
    v_balance := v_balance - 200.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-OCT-014', -200.00, 'DEBIT', 'PTPTN', 'PTPTN', 'LOAN', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-10-10 17:00:00+08';
    v_balance := v_balance - 278.50;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-OCT-015', -278.50, 'DEBIT', 'Groceries', 'AEON Big', 'GROCERIES', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-10-23 18:00:00+08';
    v_balance := v_balance - 198.40;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-OCT-016', -198.40, 'DEBIT', 'Groceries', 'Giant', 'GROCERIES', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-10-11 07:30:00+08';
    v_balance := v_balance - 140.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-OCT-017', -140.00, 'DEBIT', 'Petrol', 'Petronas', 'TRANSPORT', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-10-26 08:00:00+08';
    v_balance := v_balance - 135.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-OCT-018', -135.00, 'DEBIT', 'Petrol', 'Shell', 'TRANSPORT', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    -- NOVEMBER 2025
    v_transaction_date := '2025-11-01 09:00:00+08';
    v_balance := v_balance + 4500.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-NOV-001', 4500.00, 'CREDIT', 'Salary', 'TechCorp Malaysia', 'INCOME', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-11-01 10:30:00+08';
    v_balance := v_balance - 800.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-NOV-002', -800.00, 'DEBIT', 'Savings', 'Maybank', 'TRANSFER', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-11-01 14:20:00+08';
    v_balance := v_balance - 139.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-NOV-003', -139.00, 'DEBIT', 'Internet', 'Unifi', 'UTILITY', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-11-03 10:15:00+08';
    v_balance := v_balance - 285.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-NOV-004', -285.00, 'DEBIT', 'Insurance', 'Prudential', 'INSURANCE', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-11-05 08:05:00+08';
    v_balance := v_balance - 55.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-NOV-005', -55.00, 'DEBIT', 'Netflix', 'Netflix', 'SUBSCRIPTION', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-11-08 11:30:00+08';
    v_balance := v_balance - 98.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-NOV-006', -98.00, 'DEBIT', 'Mobile', 'Maxis', 'UTILITY', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-11-10 07:50:00+08';
    v_balance := v_balance - 19.90;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-NOV-007', -19.90, 'DEBIT', 'Spotify', 'Spotify', 'SUBSCRIPTION', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    -- 11.11 Sale
    v_transaction_date := '2025-11-11 23:59:00+08';
    v_balance := v_balance - 567.80;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-NOV-008', -567.80, 'DEBIT', '11.11 sale', 'Shopee', 'SHOPPING', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-11-12 09:00:00+08';
    v_balance := v_balance - 850.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-NOV-009', -850.00, 'DEBIT', 'Car loan', 'Maybank', 'LOAN', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-11-13 10:00:00+08';
    v_balance := v_balance - 400.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-NOV-010', -400.00, 'DEBIT', 'Parents', 'DuitNow', 'TRANSFER', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-11-15 08:10:00+08';
    v_balance := v_balance - 17.90;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-NOV-011', -17.90, 'DEBIT', 'YouTube', 'YouTube', 'SUBSCRIPTION', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-11-20 15:45:00+08';
    v_balance := v_balance - 185.50;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-NOV-012', -185.50, 'DEBIT', 'TNB', 'TNB', 'UTILITY', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-11-22 12:30:00+08';
    v_balance := v_balance - 48.20;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-NOV-013', -48.20, 'DEBIT', 'Water', 'Air Selangor', 'UTILITY', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-11-27 16:00:00+08';
    v_balance := v_balance + 850.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-NOV-014', 850.00, 'CREDIT', 'Freelance', 'Client', 'INCOME', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-11-28 10:00:00+08';
    v_balance := v_balance - 200.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-NOV-015', -200.00, 'DEBIT', 'PTPTN', 'PTPTN', 'LOAN', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-11-06 17:45:00+08';
    v_balance := v_balance - 312.80;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-NOV-016', -312.80, 'DEBIT', 'Groceries', 'AEON Big', 'GROCERIES', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-11-18 16:20:00+08';
    v_balance := v_balance - 189.30;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-NOV-017', -189.30, 'DEBIT', 'Groceries', 'Giant', 'GROCERIES', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-11-09 07:30:00+08';
    v_balance := v_balance - 145.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-NOV-018', -145.00, 'DEBIT', 'Petrol', 'Petronas', 'TRANSPORT', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-11-23 08:15:00+08';
    v_balance := v_balance - 138.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-NOV-019', -138.00, 'DEBIT', 'Petrol', 'Shell', 'TRANSPORT', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    -- DECEMBER 2025 (Current month)
    v_transaction_date := '2025-12-01 09:00:00+08';
    v_balance := v_balance + 4500.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-DEC-001', 4500.00, 'CREDIT', 'Salary', 'TechCorp Malaysia', 'INCOME', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-12-01 10:00:00+08';
    v_balance := v_balance - 1000.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-DEC-002', -1000.00, 'DEBIT', 'Year-end investment', 'Public Mutual', 'TRANSFER', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-12-01 14:20:00+08';
    v_balance := v_balance - 139.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-DEC-003', -139.00, 'DEBIT', 'Internet', 'Unifi', 'UTILITY', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-12-03 10:15:00+08';
    v_balance := v_balance - 285.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-DEC-004', -285.00, 'DEBIT', 'Insurance', 'Prudential', 'INSURANCE', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-12-05 08:05:00+08';
    v_balance := v_balance - 55.00;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-DEC-005', -55.00, 'DEBIT', 'Netflix', 'Netflix', 'SUBSCRIPTION', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    v_transaction_date := '2025-12-02 17:30:00+08';
    v_balance := v_balance - 245.70;
    INSERT INTO transactions VALUES (gen_random_uuid(), v_user_id, 'TXN-DEC-006', -245.70, 'DEBIT', 'Groceries', 'AEON Big', 'GROCERIES', v_balance, v_transaction_date, CURRENT_TIMESTAMP, 'PROCESSED');

    -- Update final balance
    UPDATE users SET current_balance = v_balance, updated_at = CURRENT_TIMESTAMP
    WHERE user_id = v_user_id;

    RAISE NOTICE '============================================';
    RAISE NOTICE 'Mock data created successfully for John Doe';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Period: January 2025 - December 2025 (12 months)';
    RAISE NOTICE 'Final Balance: MYR %', v_balance;
    RAISE NOTICE 'Total Monthly Debt: MYR 1,050 (Car: 850 + PTPTN: 200)';
    RAISE NOTICE 'Average Monthly Income: MYR 4,500 + occasional freelance';
    RAISE NOTICE 'Calculated DSR: ~23%% (1050/4500*100) - HEALTHY';
    RAISE NOTICE '============================================';

END $$;

-- Verification
SELECT
    'Total Transactions' as metric,
    COUNT(*)::TEXT as value
FROM transactions
WHERE user_id = (SELECT user_id FROM users WHERE external_user_id = 'john_doe_001');
