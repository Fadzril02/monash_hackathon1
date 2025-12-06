-- ============================================================================
-- MOCK DATA FOR JOHN DOE - 3 Months of Realistic Financial Activity
-- ============================================================================
-- User: John Doe
-- Starting Balance: MYR 5,000
-- Monthly Income: MYR 4,000
-- Period: September 2025 - November 2025
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
    5000.00, -- Starting balance
    '2025-09-01 08:00:00+08',
    CURRENT_TIMESTAMP
);

-- Get John Doe's user_id for subsequent inserts
DO $$
DECLARE
    v_user_id UUID;
    v_balance DECIMAL(15, 2);
    v_transaction_date TIMESTAMPTZ;

    -- Liability IDs
    v_netflix_id UUID;
    v_spotify_id UUID;
    v_youtube_id UUID;
    v_tnb_id UUID;
    v_water_id UUID;
    v_unifi_id UUID;
    v_maxis_id UUID;
    v_prudential_id UUID;
    v_car_loan_id UUID;
    v_ptptn_id UUID;
BEGIN
    -- Get user_id
    SELECT user_id, current_balance INTO v_user_id, v_balance
    FROM users WHERE external_user_id = 'john_doe_001';

    -- ========================================================================
    -- 2. CREATE RECURRING LIABILITIES
    -- ========================================================================

    -- SUBSCRIPTIONS
    INSERT INTO recurring_liabilities (user_id, liability_type, liability_name, amount, recurrence_pattern, next_due_date, last_paid_date, is_verified, is_active)
    VALUES (v_user_id, 'SUBSCRIPTION', 'Netflix Premium', 55.00, 'MONTHLY', '2025-12-05', '2025-11-05', true, true)
    RETURNING liability_id INTO v_netflix_id;

    INSERT INTO recurring_liabilities (user_id, liability_type, liability_name, amount, recurrence_pattern, next_due_date, last_paid_date, is_verified, is_active)
    VALUES (v_user_id, 'SUBSCRIPTION', 'Spotify Premium', 19.90, 'MONTHLY', '2025-12-10', '2025-11-10', true, true)
    RETURNING liability_id INTO v_spotify_id;

    INSERT INTO recurring_liabilities (user_id, liability_type, liability_name, amount, recurrence_pattern, next_due_date, last_paid_date, is_verified, is_active)
    VALUES (v_user_id, 'SUBSCRIPTION', 'YouTube Premium', 17.90, 'MONTHLY', '2025-12-15', '2025-11-15', true, true)
    RETURNING liability_id INTO v_youtube_id;

    -- UTILITIES
    INSERT INTO recurring_liabilities (user_id, liability_type, liability_name, amount, recurrence_pattern, next_due_date, last_paid_date, is_verified, is_active)
    VALUES (v_user_id, 'UTILITY', 'TNB Electricity Bill', 185.50, 'MONTHLY', '2025-12-20', '2025-11-20', true, true)
    RETURNING liability_id INTO v_tnb_id;

    INSERT INTO recurring_liabilities (user_id, liability_type, liability_name, amount, recurrence_pattern, next_due_date, last_paid_date, is_verified, is_active)
    VALUES (v_user_id, 'UTILITY', 'Air Selangor Water Bill', 48.20, 'MONTHLY', '2025-12-22', '2025-11-22', true, true)
    RETURNING liability_id INTO v_water_id;

    INSERT INTO recurring_liabilities (user_id, liability_type, liability_name, amount, recurrence_pattern, next_due_date, last_paid_date, is_verified, is_active)
    VALUES (v_user_id, 'UTILITY', 'Unifi Internet', 139.00, 'MONTHLY', '2025-12-01', '2025-11-01', true, true)
    RETURNING liability_id INTO v_unifi_id;

    INSERT INTO recurring_liabilities (user_id, liability_type, liability_name, amount, recurrence_pattern, next_due_date, last_paid_date, is_verified, is_active)
    VALUES (v_user_id, 'UTILITY', 'Maxis Mobile Plan', 98.00, 'MONTHLY', '2025-12-08', '2025-11-08', true, true)
    RETURNING liability_id INTO v_maxis_id;

    -- INSURANCE
    INSERT INTO recurring_liabilities (user_id, liability_type, liability_name, amount, recurrence_pattern, next_due_date, last_paid_date, is_verified, is_active)
    VALUES (v_user_id, 'INSURANCE', 'Prudential Life Insurance', 285.00, 'MONTHLY', '2025-12-03', '2025-11-03', true, true)
    RETURNING liability_id INTO v_prudential_id;

    -- LOANS
    INSERT INTO recurring_liabilities (user_id, liability_type, liability_name, amount, recurrence_pattern, next_due_date, last_paid_date, is_verified, is_active)
    VALUES (v_user_id, 'LOAN', 'Car Loan Payment', 650.00, 'MONTHLY', '2025-12-12', '2025-11-12', true, true)
    RETURNING liability_id INTO v_car_loan_id;

    INSERT INTO recurring_liabilities (user_id, liability_type, liability_name, amount, recurrence_pattern, next_due_date, last_paid_date, is_verified, is_active)
    VALUES (v_user_id, 'LOAN', 'PTPTN Education Loan', 150.00, 'MONTHLY', '2025-12-28', '2025-11-28', true, true)
    RETURNING liability_id INTO v_ptptn_id;

    -- ========================================================================
    -- 3. CREATE TRANSACTIONS - SEPTEMBER 2025
    -- ========================================================================

    -- Starting balance at Sept 1: MYR 5,000
    v_balance := 5000.00;

    -- Sept 1: Salary Credit
    v_transaction_date := '2025-09-01 09:30:00+08';
    v_balance := v_balance + 4000.00;
    INSERT INTO transactions (user_id, external_transaction_id, amount, transaction_type, description, merchant_name, category, balance_after, transaction_date, status)
    VALUES (v_user_id, 'TXN-SEP-001', 4000.00, 'CREDIT', 'Monthly Salary', 'ABC Corporation Sdn Bhd', 'INCOME', v_balance, v_transaction_date, 'PROCESSED');

    -- Sept 1: Unifi Internet
    v_transaction_date := '2025-09-01 14:20:00+08';
    v_balance := v_balance - 139.00;
    INSERT INTO transactions (user_id, external_transaction_id, amount, transaction_type, description, merchant_name, category, balance_after, transaction_date, status)
    VALUES (v_user_id, 'TXN-SEP-002', -139.00, 'DEBIT', 'Internet bill payment', 'Unifi', 'UTILITY', v_balance, v_transaction_date, 'PROCESSED');

    -- Sept 3: Insurance
    v_transaction_date := '2025-09-03 10:15:00+08';
    v_balance := v_balance - 285.00;
    INSERT INTO transactions (user_id, external_transaction_id, amount, transaction_type, description, merchant_name, category, balance_after, transaction_date, status)
    VALUES (v_user_id, 'TXN-SEP-003', -285.00, 'DEBIT', 'Monthly insurance premium', 'Prudential', 'INSURANCE', v_balance, v_transaction_date, 'PROCESSED');

    -- Sept 5: Netflix
    v_transaction_date := '2025-09-05 08:05:00+08';
    v_balance := v_balance - 55.00;
    INSERT INTO transactions (user_id, external_transaction_id, amount, transaction_type, description, merchant_name, category, balance_after, transaction_date, status)
    VALUES (v_user_id, 'TXN-SEP-004', -55.00, 'DEBIT', 'Subscription renewal', 'Netflix', 'SUBSCRIPTION', v_balance, v_transaction_date, 'PROCESSED');

    -- Sept 7: Groceries
    v_transaction_date := '2025-09-07 18:45:00+08';
    v_balance := v_balance - 245.80;
    INSERT INTO transactions (user_id, external_transaction_id, amount, transaction_type, description, merchant_name, category, balance_after, transaction_date, status)
    VALUES (v_user_id, 'TXN-SEP-005', -245.80, 'DEBIT', 'Weekly grocery shopping', 'AEON Big', 'GROCERIES', v_balance, v_transaction_date, 'PROCESSED');

    -- Sept 8: Maxis
    v_transaction_date := '2025-09-08 11:30:00+08';
    v_balance := v_balance - 98.00;
    INSERT INTO transactions (user_id, external_transaction_id, amount, transaction_type, description, merchant_name, category, balance_after, transaction_date, status)
    VALUES (v_user_id, 'TXN-SEP-006', -98.00, 'DEBIT', 'Mobile plan payment', 'Maxis', 'UTILITY', v_balance, v_transaction_date, 'PROCESSED');

    -- Sept 10: Spotify
    v_transaction_date := '2025-09-10 07:50:00+08';
    v_balance := v_balance - 19.90;
    INSERT INTO transactions (user_id, external_transaction_id, amount, transaction_type, description, merchant_name, category, balance_after, transaction_date, status)
    VALUES (v_user_id, 'TXN-SEP-007', -19.90, 'DEBIT', 'Subscription renewal', 'Spotify', 'SUBSCRIPTION', v_balance, v_transaction_date, 'PROCESSED');

    -- Sept 12: Car Loan
    v_transaction_date := '2025-09-12 09:00:00+08';
    v_balance := v_balance - 650.00;
    INSERT INTO transactions (user_id, external_transaction_id, amount, transaction_type, description, merchant_name, category, balance_after, transaction_date, status)
    VALUES (v_user_id, 'TXN-SEP-008', -650.00, 'DEBIT', 'Monthly car loan installment', 'Maybank Auto Finance', 'LOAN', v_balance, v_transaction_date, 'PROCESSED');

    -- Sept 14: Dining Out
    v_transaction_date := '2025-09-14 20:15:00+08';
    v_balance := v_balance - 89.50;
    INSERT INTO transactions (user_id, external_transaction_id, amount, transaction_type, description, merchant_name, category, balance_after, transaction_date, status)
    VALUES (v_user_id, 'TXN-SEP-009', -89.50, 'DEBIT', 'Dinner with friends', 'The Chicken Rice Shop', 'DINING', v_balance, v_transaction_date, 'PROCESSED');

    -- Sept 15: YouTube Premium
    v_transaction_date := '2025-09-15 08:10:00+08';
    v_balance := v_balance - 17.90;
    INSERT INTO transactions (user_id, external_transaction_id, amount, transaction_type, description, merchant_name, category, balance_after, transaction_date, status)
    VALUES (v_user_id, 'TXN-SEP-010', -17.90, 'DEBIT', 'Subscription renewal', 'YouTube Premium', 'SUBSCRIPTION', v_balance, v_transaction_date, 'PROCESSED');

    -- Sept 16: Fuel
    v_transaction_date := '2025-09-16 07:30:00+08';
    v_balance := v_balance - 120.00;
    INSERT INTO transactions (user_id, external_transaction_id, amount, transaction_type, description, merchant_name, category, balance_after, transaction_date, status)
    VALUES (v_user_id, 'TXN-SEP-011', -120.00, 'DEBIT', 'Petrol refill', 'Petronas Station', 'TRANSPORT', v_balance, v_transaction_date, 'PROCESSED');

    -- Sept 20: TNB
    v_transaction_date := '2025-09-20 15:45:00+08';
    v_balance := v_balance - 185.50;
    INSERT INTO transactions (user_id, external_transaction_id, amount, transaction_type, description, merchant_name, category, balance_after, transaction_date, status)
    VALUES (v_user_id, 'TXN-SEP-012', -185.50, 'DEBIT', 'Electricity bill payment', 'TNB', 'UTILITY', v_balance, v_transaction_date, 'PROCESSED');

    -- Sept 21: Groceries
    v_transaction_date := '2025-09-21 17:20:00+08';
    v_balance := v_balance - 198.40;
    INSERT INTO transactions (user_id, external_transaction_id, amount, transaction_type, description, merchant_name, category, balance_after, transaction_date, status)
    VALUES (v_user_id, 'TXN-SEP-013', -198.40, 'DEBIT', 'Weekly grocery shopping', 'Tesco', 'GROCERIES', v_balance, v_transaction_date, 'PROCESSED');

    -- Sept 22: Water Bill
    v_transaction_date := '2025-09-22 12:30:00+08';
    v_balance := v_balance - 48.20;
    INSERT INTO transactions (user_id, external_transaction_id, amount, transaction_type, description, merchant_name, category, balance_after, transaction_date, status)
    VALUES (v_user_id, 'TXN-SEP-014', -48.20, 'DEBIT', 'Water bill payment', 'Air Selangor', 'UTILITY', v_balance, v_transaction_date, 'PROCESSED');

    -- Sept 25: Online Shopping
    v_transaction_date := '2025-09-25 21:00:00+08';
    v_balance := v_balance - 156.90;
    INSERT INTO transactions (user_id, external_transaction_id, amount, transaction_type, description, merchant_name, category, balance_after, transaction_date, status)
    VALUES (v_user_id, 'TXN-SEP-015', -156.90, 'DEBIT', 'Online purchase', 'Shopee', 'SHOPPING', v_balance, v_transaction_date, 'PROCESSED');

    -- Sept 28: PTPTN
    v_transaction_date := '2025-09-28 10:00:00+08';
    v_balance := v_balance - 150.00;
    INSERT INTO transactions (user_id, external_transaction_id, amount, transaction_type, description, merchant_name, category, balance_after, transaction_date, status)
    VALUES (v_user_id, 'TXN-SEP-016', -150.00, 'DEBIT', 'Education loan repayment', 'PTPTN', 'LOAN', v_balance, v_transaction_date, 'PROCESSED');

    -- Sept 29: Dining
    v_transaction_date := '2025-09-29 19:30:00+08';
    v_balance := v_balance - 72.50;
    INSERT INTO transactions (user_id, external_transaction_id, amount, transaction_type, description, merchant_name, category, balance_after, transaction_date, status)
    VALUES (v_user_id, 'TXN-SEP-017', -72.50, 'DEBIT', 'Weekend dinner', 'Old Town White Coffee', 'DINING', v_balance, v_transaction_date, 'PROCESSED');

    -- Sept 30: Fuel
    v_transaction_date := '2025-09-30 08:15:00+08';
    v_balance := v_balance - 115.00;
    INSERT INTO transactions (user_id, external_transaction_id, amount, transaction_type, description, merchant_name, category, balance_after, transaction_date, status)
    VALUES (v_user_id, 'TXN-SEP-018', -115.00, 'DEBIT', 'Petrol refill', 'Shell Station', 'TRANSPORT', v_balance, v_transaction_date, 'PROCESSED');

    -- ========================================================================
    -- 4. CREATE TRANSACTIONS - OCTOBER 2025
    -- ========================================================================

    -- Oct 1: Salary Credit
    v_transaction_date := '2025-10-01 09:30:00+08';
    v_balance := v_balance + 4000.00;
    INSERT INTO transactions (user_id, external_transaction_id, amount, transaction_type, description, merchant_name, category, balance_after, transaction_date, status)
    VALUES (v_user_id, 'TXN-OCT-001', 4000.00, 'CREDIT', 'Monthly Salary', 'ABC Corporation Sdn Bhd', 'INCOME', v_balance, v_transaction_date, 'PROCESSED');

    -- Oct 1: Unifi
    v_transaction_date := '2025-10-01 14:20:00+08';
    v_balance := v_balance - 139.00;
    INSERT INTO transactions (user_id, external_transaction_id, amount, transaction_type, description, merchant_name, category, balance_after, transaction_date, status)
    VALUES (v_user_id, 'TXN-OCT-002', -139.00, 'DEBIT', 'Internet bill payment', 'Unifi', 'UTILITY', v_balance, v_transaction_date, 'PROCESSED');

    -- Oct 3: Insurance
    v_transaction_date := '2025-10-03 10:15:00+08';
    v_balance := v_balance - 285.00;
    INSERT INTO transactions (user_id, external_transaction_id, amount, transaction_type, description, merchant_name, category, balance_after, transaction_date, status)
    VALUES (v_user_id, 'TXN-OCT-003', -285.00, 'DEBIT', 'Monthly insurance premium', 'Prudential', 'INSURANCE', v_balance, v_transaction_date, 'PROCESSED');

    -- Oct 5: Netflix
    v_transaction_date := '2025-10-05 08:05:00+08';
    v_balance := v_balance - 55.00;
    INSERT INTO transactions (user_id, external_transaction_id, amount, transaction_type, description, merchant_name, category, balance_after, transaction_date, status)
    VALUES (v_user_id, 'TXN-OCT-004', -55.00, 'DEBIT', 'Subscription renewal', 'Netflix', 'SUBSCRIPTION', v_balance, v_transaction_date, 'PROCESSED');

    -- Oct 6: Groceries
    v_transaction_date := '2025-10-06 16:30:00+08';
    v_balance := v_balance - 267.30;
    INSERT INTO transactions (user_id, external_transaction_id, amount, transaction_type, description, merchant_name, category, balance_after, transaction_date, status)
    VALUES (v_user_id, 'TXN-OCT-005', -267.30, 'DEBIT', 'Weekly grocery shopping', 'Giant Hypermarket', 'GROCERIES', v_balance, v_transaction_date, 'PROCESSED');

    -- Oct 8: Maxis
    v_transaction_date := '2025-10-08 11:30:00+08';
    v_balance := v_balance - 98.00;
    INSERT INTO transactions (user_id, external_transaction_id, amount, transaction_type, description, merchant_name, category, balance_after, transaction_date, status)
    VALUES (v_user_id, 'TXN-OCT-006', -98.00, 'DEBIT', 'Mobile plan payment', 'Maxis', 'UTILITY', v_balance, v_transaction_date, 'PROCESSED');

    -- Oct 10: Spotify
    v_transaction_date := '2025-10-10 07:50:00+08';
    v_balance := v_balance - 19.90;
    INSERT INTO transactions (user_id, external_transaction_id, amount, transaction_type, description, merchant_name, category, balance_after, transaction_date, status)
    VALUES (v_user_id, 'TXN-OCT-007', -19.90, 'DEBIT', 'Subscription renewal', 'Spotify', 'SUBSCRIPTION', v_balance, v_transaction_date, 'PROCESSED');

    -- Oct 11: Fuel
    v_transaction_date := '2025-10-11 07:45:00+08';
    v_balance := v_balance - 125.00;
    INSERT INTO transactions (user_id, external_transaction_id, amount, transaction_type, description, merchant_name, category, balance_after, transaction_date, status)
    VALUES (v_user_id, 'TXN-OCT-008', -125.00, 'DEBIT', 'Petrol refill', 'Petronas Station', 'TRANSPORT', v_balance, v_transaction_date, 'PROCESSED');

    -- Oct 12: Car Loan
    v_transaction_date := '2025-10-12 09:00:00+08';
    v_balance := v_balance - 650.00;
    INSERT INTO transactions (user_id, external_transaction_id, amount, transaction_type, description, merchant_name, category, balance_after, transaction_date, status)
    VALUES (v_user_id, 'TXN-OCT-009', -650.00, 'DEBIT', 'Monthly car loan installment', 'Maybank Auto Finance', 'LOAN', v_balance, v_transaction_date, 'PROCESSED');

    -- Oct 13: Medical
    v_transaction_date := '2025-10-13 14:20:00+08';
    v_balance := v_balance - 185.00;
    INSERT INTO transactions (user_id, external_transaction_id, amount, transaction_type, description, merchant_name, category, balance_after, transaction_date, status)
    VALUES (v_user_id, 'TXN-OCT-010', -185.00, 'DEBIT', 'Medical consultation and medication', 'Klinik Mediviron', 'HEALTHCARE', v_balance, v_transaction_date, 'PROCESSED');

    -- Oct 15: YouTube Premium
    v_transaction_date := '2025-10-15 08:10:00+08';
    v_balance := v_balance - 17.90;
    INSERT INTO transactions (user_id, external_transaction_id, amount, transaction_type, description, merchant_name, category, balance_after, transaction_date, status)
    VALUES (v_user_id, 'TXN-OCT-011', -17.90, 'DEBIT', 'Subscription renewal', 'YouTube Premium', 'SUBSCRIPTION', v_balance, v_transaction_date, 'PROCESSED');

    -- Oct 18: Dining
    v_transaction_date := '2025-10-18 20:00:00+08';
    v_balance := v_balance - 145.80;
    INSERT INTO transactions (user_id, external_transaction_id, amount, transaction_type, description, merchant_name, category, balance_after, transaction_date, status)
    VALUES (v_user_id, 'TXN-OCT-012', -145.80, 'DEBIT', 'Family dinner', 'Secret Recipe', 'DINING', v_balance, v_transaction_date, 'PROCESSED');

    -- Oct 20: TNB
    v_transaction_date := '2025-10-20 15:45:00+08';
    v_balance := v_balance - 185.50;
    INSERT INTO transactions (user_id, external_transaction_id, amount, transaction_type, description, merchant_name, category, balance_after, transaction_date, status)
    VALUES (v_user_id, 'TXN-OCT-013', -185.50, 'DEBIT', 'Electricity bill payment', 'TNB', 'UTILITY', v_balance, v_transaction_date, 'PROCESSED');

    -- Oct 20: Groceries
    v_transaction_date := '2025-10-20 17:15:00+08';
    v_balance := v_balance - 213.60;
    INSERT INTO transactions (user_id, external_transaction_id, amount, transaction_type, description, merchant_name, category, balance_after, transaction_date, status)
    VALUES (v_user_id, 'TXN-OCT-014', -213.60, 'DEBIT', 'Weekly grocery shopping', 'AEON Big', 'GROCERIES', v_balance, v_transaction_date, 'PROCESSED');

    -- Oct 22: Water Bill
    v_transaction_date := '2025-10-22 12:30:00+08';
    v_balance := v_balance - 48.20;
    INSERT INTO transactions (user_id, external_transaction_id, amount, transaction_type, description, merchant_name, category, balance_after, transaction_date, status)
    VALUES (v_user_id, 'TXN-OCT-015', -48.20, 'DEBIT', 'Water bill payment', 'Air Selangor', 'UTILITY', v_balance, v_transaction_date, 'PROCESSED');

    -- Oct 24: Online Shopping
    v_transaction_date := '2025-10-24 22:30:00+08';
    v_balance := v_balance - 289.90;
    INSERT INTO transactions (user_id, external_transaction_id, amount, transaction_type, description, merchant_name, category, balance_after, transaction_date, status)
    VALUES (v_user_id, 'TXN-OCT-016', -289.90, 'DEBIT', 'Online purchase', 'Lazada', 'SHOPPING', v_balance, v_transaction_date, 'PROCESSED');

    -- Oct 26: Fuel
    v_transaction_date := '2025-10-26 08:00:00+08';
    v_balance := v_balance - 118.00;
    INSERT INTO transactions (user_id, external_transaction_id, amount, transaction_type, description, merchant_name, category, balance_after, transaction_date, status)
    VALUES (v_user_id, 'TXN-OCT-017', -118.00, 'DEBIT', 'Petrol refill', 'Shell Station', 'TRANSPORT', v_balance, v_transaction_date, 'PROCESSED');

    -- Oct 28: PTPTN
    v_transaction_date := '2025-10-28 10:00:00+08';
    v_balance := v_balance - 150.00;
    INSERT INTO transactions (user_id, external_transaction_id, amount, transaction_type, description, merchant_name, category, balance_after, transaction_date, status)
    VALUES (v_user_id, 'TXN-OCT-018', -150.00, 'DEBIT', 'Education loan repayment', 'PTPTN', 'LOAN', v_balance, v_transaction_date, 'PROCESSED');

    -- Oct 30: Entertainment
    v_transaction_date := '2025-10-30 21:15:00+08';
    v_balance := v_balance - 95.00;
    INSERT INTO transactions (user_id, external_transaction_id, amount, transaction_type, description, merchant_name, category, balance_after, transaction_date, status)
    VALUES (v_user_id, 'TXN-OCT-019', -95.00, 'DEBIT', 'Movie tickets and snacks', 'GSC Cinema', 'ENTERTAINMENT', v_balance, v_transaction_date, 'PROCESSED');

    -- ========================================================================
    -- 5. CREATE TRANSACTIONS - NOVEMBER 2025
    -- ========================================================================

    -- Nov 1: Salary Credit
    v_transaction_date := '2025-11-01 09:30:00+08';
    v_balance := v_balance + 4000.00;
    INSERT INTO transactions (user_id, external_transaction_id, amount, transaction_type, description, merchant_name, category, balance_after, transaction_date, status)
    VALUES (v_user_id, 'TXN-NOV-001', 4000.00, 'CREDIT', 'Monthly Salary', 'ABC Corporation Sdn Bhd', 'INCOME', v_balance, v_transaction_date, 'PROCESSED');

    -- Nov 1: Unifi
    v_transaction_date := '2025-11-01 14:20:00+08';
    v_balance := v_balance - 139.00;
    INSERT INTO transactions (user_id, external_transaction_id, amount, transaction_type, description, merchant_name, category, balance_after, transaction_date, status)
    VALUES (v_user_id, 'TXN-NOV-002', -139.00, 'DEBIT', 'Internet bill payment', 'Unifi', 'UTILITY', v_balance, v_transaction_date, 'PROCESSED');

    -- Nov 3: Insurance
    v_transaction_date := '2025-11-03 10:15:00+08';
    v_balance := v_balance - 285.00;
    INSERT INTO transactions (user_id, external_transaction_id, amount, transaction_type, description, merchant_name, category, balance_after, transaction_date, status)
    VALUES (v_user_id, 'TXN-NOV-003', -285.00, 'DEBIT', 'Monthly insurance premium', 'Prudential', 'INSURANCE', v_balance, v_transaction_date, 'PROCESSED');

    -- Nov 5: Netflix
    v_transaction_date := '2025-11-05 08:05:00+08';
    v_balance := v_balance - 55.00;
    INSERT INTO transactions (user_id, external_transaction_id, amount, transaction_type, description, merchant_name, category, balance_after, transaction_date, status)
    VALUES (v_user_id, 'TXN-NOV-004', -55.00, 'DEBIT', 'Subscription renewal', 'Netflix', 'SUBSCRIPTION', v_balance, v_transaction_date, 'PROCESSED');

    -- Nov 6: Groceries
    v_transaction_date := '2025-11-06 17:45:00+08';
    v_balance := v_balance - 234.70;
    INSERT INTO transactions (user_id, external_transaction_id, amount, transaction_type, description, merchant_name, category, balance_after, transaction_date, status)
    VALUES (v_user_id, 'TXN-NOV-005', -234.70, 'DEBIT', 'Weekly grocery shopping', 'Tesco', 'GROCERIES', v_balance, v_transaction_date, 'PROCESSED');

    -- Nov 8: Maxis
    v_transaction_date := '2025-11-08 11:30:00+08';
    v_balance := v_balance - 98.00;
    INSERT INTO transactions (user_id, external_transaction_id, amount, transaction_type, description, merchant_name, category, balance_after, transaction_date, status)
    VALUES (v_user_id, 'TXN-NOV-006', -98.00, 'DEBIT', 'Mobile plan payment', 'Maxis', 'UTILITY', v_balance, v_transaction_date, 'PROCESSED');

    -- Nov 9: Fuel
    v_transaction_date := '2025-11-09 07:30:00+08';
    v_balance := v_balance - 122.00;
    INSERT INTO transactions (user_id, external_transaction_id, amount, transaction_type, description, merchant_name, category, balance_after, transaction_date, status)
    VALUES (v_user_id, 'TXN-NOV-007', -122.00, 'DEBIT', 'Petrol refill', 'Petronas Station', 'TRANSPORT', v_balance, v_transaction_date, 'PROCESSED');

    -- Nov 10: Spotify
    v_transaction_date := '2025-11-10 07:50:00+08';
    v_balance := v_balance - 19.90;
    INSERT INTO transactions (user_id, external_transaction_id, amount, transaction_type, description, merchant_name, category, balance_after, transaction_date, status)
    VALUES (v_user_id, 'TXN-NOV-008', -19.90, 'DEBIT', 'Subscription renewal', 'Spotify', 'SUBSCRIPTION', v_balance, v_transaction_date, 'PROCESSED');

    -- Nov 11: 11.11 Sale Shopping
    v_transaction_date := '2025-11-11 23:59:00+08';
    v_balance := v_balance - 425.50;
    INSERT INTO transactions (user_id, external_transaction_id, amount, transaction_type, description, merchant_name, category, balance_after, transaction_date, status)
    VALUES (v_user_id, 'TXN-NOV-009', -425.50, 'DEBIT', '11.11 sale purchases', 'Shopee', 'SHOPPING', v_balance, v_transaction_date, 'PROCESSED');

    -- Nov 12: Car Loan
    v_transaction_date := '2025-11-12 09:00:00+08';
    v_balance := v_balance - 650.00;
    INSERT INTO transactions (user_id, external_transaction_id, amount, transaction_type, description, merchant_name, category, balance_after, transaction_date, status)
    VALUES (v_user_id, 'TXN-NOV-010', -650.00, 'DEBIT', 'Monthly car loan installment', 'Maybank Auto Finance', 'LOAN', v_balance, v_transaction_date, 'PROCESSED');

    -- Nov 15: YouTube Premium
    v_transaction_date := '2025-11-15 08:10:00+08';
    v_balance := v_balance - 17.90;
    INSERT INTO transactions (user_id, external_transaction_id, amount, transaction_type, description, merchant_name, category, balance_after, transaction_date, status)
    VALUES (v_user_id, 'TXN-NOV-011', -17.90, 'DEBIT', 'Subscription renewal', 'YouTube Premium', 'SUBSCRIPTION', v_balance, v_transaction_date, 'PROCESSED');

    -- Nov 16: Dining
    v_transaction_date := '2025-11-16 19:45:00+08';
    v_balance := v_balance - 78.90;
    INSERT INTO transactions (user_id, external_transaction_id, amount, transaction_type, description, merchant_name, category, balance_after, transaction_date, status)
    VALUES (v_user_id, 'TXN-NOV-012', -78.90, 'DEBIT', 'Weekend dinner', 'Kenny Rogers Roasters', 'DINING', v_balance, v_transaction_date, 'PROCESSED');

    -- Nov 18: Groceries
    v_transaction_date := '2025-11-18 16:20:00+08';
    v_balance := v_balance - 189.30;
    INSERT INTO transactions (user_id, external_transaction_id, amount, transaction_type, description, merchant_name, category, balance_after, transaction_date, status)
    VALUES (v_user_id, 'TXN-NOV-013', -189.30, 'DEBIT', 'Weekly grocery shopping', 'Giant Hypermarket', 'GROCERIES', v_balance, v_transaction_date, 'PROCESSED');

    -- Nov 20: TNB
    v_transaction_date := '2025-11-20 15:45:00+08';
    v_balance := v_balance - 185.50;
    INSERT INTO transactions (user_id, external_transaction_id, amount, transaction_type, description, merchant_name, category, balance_after, transaction_date, status)
    VALUES (v_user_id, 'TXN-NOV-014', -185.50, 'DEBIT', 'Electricity bill payment', 'TNB', 'UTILITY', v_balance, v_transaction_date, 'PROCESSED');

    -- Nov 22: Water Bill
    v_transaction_date := '2025-11-22 12:30:00+08';
    v_balance := v_balance - 48.20;
    INSERT INTO transactions (user_id, external_transaction_id, amount, transaction_type, description, merchant_name, category, balance_after, transaction_date, status)
    VALUES (v_user_id, 'TXN-NOV-015', -48.20, 'DEBIT', 'Water bill payment', 'Air Selangor', 'UTILITY', v_balance, v_transaction_date, 'PROCESSED');

    -- Nov 23: Fuel
    v_transaction_date := '2025-11-23 08:15:00+08';
    v_balance := v_balance - 119.00;
    INSERT INTO transactions (user_id, external_transaction_id, amount, transaction_type, description, merchant_name, category, balance_after, transaction_date, status)
    VALUES (v_user_id, 'TXN-NOV-016', -119.00, 'DEBIT', 'Petrol refill', 'Shell Station', 'TRANSPORT', v_balance, v_transaction_date, 'PROCESSED');

    -- Nov 25: Dining
    v_transaction_date := '2025-11-25 20:30:00+08';
    v_balance := v_balance - 112.40;
    INSERT INTO transactions (user_id, external_transaction_id, amount, transaction_type, description, merchant_name, category, balance_after, transaction_date, status)
    VALUES (v_user_id, 'TXN-NOV-017', -112.40, 'DEBIT', 'Family dinner', 'Nandos', 'DINING', v_balance, v_transaction_date, 'PROCESSED');

    -- Nov 28: PTPTN
    v_transaction_date := '2025-11-28 10:00:00+08';
    v_balance := v_balance - 150.00;
    INSERT INTO transactions (user_id, external_transaction_id, amount, transaction_type, description, merchant_name, category, balance_after, transaction_date, status)
    VALUES (v_user_id, 'TXN-NOV-018', -150.00, 'DEBIT', 'Education loan repayment', 'PTPTN', 'LOAN', v_balance, v_transaction_date, 'PROCESSED');

    -- Nov 29: Coffee
    v_transaction_date := '2025-11-29 15:00:00+08';
    v_balance := v_balance - 24.50;
    INSERT INTO transactions (user_id, external_transaction_id, amount, transaction_type, description, merchant_name, category, balance_after, transaction_date, status)
    VALUES (v_user_id, 'TXN-NOV-019', -24.50, 'DEBIT', 'Coffee and pastry', 'Starbucks', 'DINING', v_balance, v_transaction_date, 'PROCESSED');

    -- Nov 30: Groceries (month end)
    v_transaction_date := '2025-11-30 18:00:00+08';
    v_balance := v_balance - 156.80;
    INSERT INTO transactions (user_id, external_transaction_id, amount, transaction_type, description, merchant_name, category, balance_after, transaction_date, status)
    VALUES (v_user_id, 'TXN-NOV-020', -156.80, 'DEBIT', 'Weekly grocery shopping', 'AEON Big', 'GROCERIES', v_balance, v_transaction_date, 'PROCESSED');

    -- Update final balance
    UPDATE users SET current_balance = v_balance, updated_at = CURRENT_TIMESTAMP
    WHERE user_id = v_user_id;

    -- ========================================================================
    -- 6. ADD SAMPLE CONVERSATION HISTORY
    -- ========================================================================

    INSERT INTO conversation_history (user_id, role, message_text, safe_balance_at_time, metadata, created_at)
    VALUES
    (v_user_id, 'user', 'What is my safe balance?', NULL, '{"context": "initial_query"}'::jsonb, '2025-11-30 20:00:00+08'),
    (v_user_id, 'assistant', 'Your current balance is MYR 5,000.00. After accounting for your upcoming bills in the next 30 days (MYR 1,648.50), your safe balance is MYR 3,351.50. Your financial status is HEALTHY.', v_balance - 1648.50, '{"calculation": {"current_balance": 5000.00, "upcoming_liabilities": 1648.50, "safe_balance": 3351.50, "status": "HEALTHY"}}'::jsonb, '2025-11-30 20:00:15+08');

END $$;

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Check user details
SELECT
    user_id,
    external_user_id,
    full_name,
    email,
    current_balance,
    created_at
FROM users
WHERE external_user_id = 'john_doe_001';

-- Check recurring liabilities
SELECT
    liability_type,
    liability_name,
    amount,
    recurrence_pattern,
    next_due_date,
    is_active
FROM recurring_liabilities
WHERE user_id = (SELECT user_id FROM users WHERE external_user_id = 'john_doe_001')
ORDER BY next_due_date;

-- Transaction summary by month
SELECT
    TO_CHAR(transaction_date, 'YYYY-MM') as month,
    transaction_type,
    COUNT(*) as transaction_count,
    SUM(amount) as total_amount
FROM transactions
WHERE user_id = (SELECT user_id FROM users WHERE external_user_id = 'john_doe_001')
GROUP BY TO_CHAR(transaction_date, 'YYYY-MM'), transaction_type
ORDER BY month, transaction_type;

-- Check safe balance
SELECT * FROM v_user_safe_balance
WHERE external_user_id = 'john_doe_001';

-- Check upcoming payments
SELECT * FROM v_upcoming_payments_30days
WHERE external_user_id = 'john_doe_001'
ORDER BY payment_date;

-- Total spending by category
SELECT
    category,
    COUNT(*) as count,
    SUM(ABS(amount)) as total_spent
FROM transactions
WHERE user_id = (SELECT user_id FROM users WHERE external_user_id = 'john_doe_001')
    AND transaction_type = 'DEBIT'
GROUP BY category
ORDER BY total_spent DESC;

-- ============================================================================
-- SUMMARY STATISTICS
-- ============================================================================

SELECT
    'Total Transactions' as metric,
    COUNT(*)::TEXT as value
FROM transactions
WHERE user_id = (SELECT user_id FROM users WHERE external_user_id = 'john_doe_001')
UNION ALL
SELECT
    'Total Income' as metric,
    'MYR ' || SUM(amount)::TEXT as value
FROM transactions
WHERE user_id = (SELECT user_id FROM users WHERE external_user_id = 'john_doe_001')
    AND transaction_type = 'CREDIT'
UNION ALL
SELECT
    'Total Expenses' as metric,
    'MYR ' || ABS(SUM(amount))::TEXT as value
FROM transactions
WHERE user_id = (SELECT user_id FROM users WHERE external_user_id = 'john_doe_001')
    AND transaction_type = 'DEBIT'
UNION ALL
SELECT
    'Active Recurring Liabilities' as metric,
    COUNT(*)::TEXT as value
FROM recurring_liabilities
WHERE user_id = (SELECT user_id FROM users WHERE external_user_id = 'john_doe_001')
    AND is_active = true
UNION ALL
SELECT
    'Monthly Recurring Cost' as metric,
    'MYR ' || SUM(amount)::TEXT as value
FROM recurring_liabilities
WHERE user_id = (SELECT user_id FROM users WHERE external_user_id = 'john_doe_001')
    AND is_active = true
    AND recurrence_pattern = 'MONTHLY';
