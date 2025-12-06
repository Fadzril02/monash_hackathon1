-- ============================================================================
-- MOCK PROMOTIONS DATA - MySQL/TiDB Version
-- ============================================================================
-- Purpose: Populate promotions table with diverse examples for AI ranking
-- ============================================================================

-- Clean up existing promotions (optional - comment out if you want to keep existing data)
-- DELETE FROM promotions;

-- ============================================================================
-- PROMOTION 1: BNPL Example - Atome
-- ============================================================================
INSERT INTO promotions (title, subtitle, description, image_url, promotion_type, conditions, is_active)
VALUES (
    'Pay Later with Atome',
    'Split your purchase into 3 easy payments',
    'Split your next electronics purchase into 3 easy payments with Atome. No interest, no hidden fees. Perfect for managing your budget while getting what you need.',
    'promo_1.png',
    'bnpl',
    'Minimum purchase: RM 50. Available at selected merchants. Terms and conditions apply.',
    TRUE
);

-- ============================================================================
-- PROMOTION 2: Premium Perk Example - Plaza Premium Lounge
-- ============================================================================
INSERT INTO promotions (title, subtitle, description, image_url, promotion_type, conditions, is_active)
VALUES (
    'Free Plaza Premium Lounge Access',
    'Complimentary lounge access with flight bookings',
    'Purchase any international flight ticket with your RytGuard card and enjoy free access to Plaza Premium Lounge. Relax in comfort before your flight with complimentary food, drinks, and Wi-Fi.',
    'promo_2.png',
    'premium_perk',
    'Valid for international flight bookings only. Minimum transaction: RM 500. One-time use per booking.',
    TRUE
);

-- ============================================================================
-- PROMOTION 3: Cashback Example - Fuel
-- ============================================================================
INSERT INTO promotions (title, subtitle, description, image_url, promotion_type, conditions, is_active)
VALUES (
    '10% Cashback on Petrol',
    'Save on fuel at Petronas stations',
    'Refuel at any Petronas station and get 10% cashback on your purchase, up to RM50 cashback this month. Use your RytGuard card at the pump or in-store.',
    'promo_3.png',
    'cashback',
    'Maximum cashback: RM 50 per month. Valid at all Petronas stations. Cashback credited within 7 days.',
    TRUE
);

-- ============================================================================
-- PROMOTION 4: Voucher Example - Retail
-- ============================================================================
INSERT INTO promotions (title, subtitle, description, image_url, promotion_type, conditions, is_active)
VALUES (
    'RM20 Off at Lazada',
    'Exclusive voucher for RytGuard users',
    'Spend RM100 or more at Lazada and get an exclusive RM20 discount voucher. Shop for electronics, fashion, home essentials, and more with this special offer.',
    'promo_4.png',
    'voucher',
    'Minimum spend: RM 100. Valid for one-time use. Cannot be combined with other promotions.',
    TRUE
);

-- ============================================================================
-- PROMOTION 5: BNPL Cashback Example
-- ============================================================================
INSERT INTO promotions (title, subtitle, description, image_url, promotion_type, conditions, is_active)
VALUES (
    'On-Time BNPL Reward',
    'Get 5% cashback when you pay on time',
    'Use SpayLater or any BNPL service and pay your bill on time to earn 5% cashback. Build good credit habits while earning rewards. Perfect for responsible spenders.',
    'promo_5.png',
    'cashback',
    'Valid for BNPL payments made on or before due date. Maximum cashback: RM 100 per month. Cashback credited after payment confirmation.',
    TRUE
);

-- ============================================================================
-- PROMOTION 6: Premium Perk - Dining
-- ============================================================================
INSERT INTO promotions (title, subtitle, description, image_url, promotion_type, conditions, is_active)
VALUES (
    'VIP Dining Experience',
    'Complimentary dessert at selected restaurants',
    'Dine at selected premium restaurants and enjoy a complimentary dessert when you pay with your RytGuard card. Perfect for special occasions and date nights.',
    'promo_6.png',
    'premium_perk',
    'Valid at selected restaurants. Minimum spend: RM 150. One complimentary dessert per table. Reservation recommended.',
    TRUE
);

-- ============================================================================
-- PROMOTION 7: Cashback - Groceries
-- ============================================================================
INSERT INTO promotions (title, subtitle, description, image_url, promotion_type, conditions, is_active)
VALUES (
    '5% Cashback on Groceries',
    'Save on your weekly shopping',
    'Get 5% cashback on all grocery purchases at Giant, Tesco, and AEON. Stock up on essentials and save money every time you shop.',
    'promo_7.png',
    'cashback',
    'Valid at Giant, Tesco, and AEON stores. Maximum cashback: RM 30 per month. Cashback credited within 5 days.',
    TRUE
);

-- ============================================================================
-- PROMOTION 8: Voucher - Entertainment
-- ============================================================================
INSERT INTO promotions (title, subtitle, description, image_url, promotion_type, conditions, is_active)
VALUES (
    'Buy 1 Get 1 Free Movie Tickets',
    'Enjoy movies with a friend',
    'Purchase movie tickets at GSC or TGV cinemas and get a second ticket free. Perfect for weekend entertainment without breaking the bank.',
    'promo_8.png',
    'voucher',
    'Valid at GSC and TGV cinemas. Buy 1 ticket at regular price, get 1 free. Cannot be used with other promotions.',
    TRUE
);

-- ============================================================================
-- PROMOTION 9: BNPL - Fashion
-- ============================================================================
INSERT INTO promotions (title, subtitle, description, image_url, promotion_type, conditions, is_active)
VALUES (
    'Shop Now, Pay Later',
    'Flexible payments for fashion purchases',
    'Use GrabPayLater to split your fashion purchases at Zara, H&M, and Uniqlo into 3 interest-free installments. Stay stylish while managing your budget.',
    'promo_1.png',
    'bnpl',
    'Valid at Zara, H&M, and Uniqlo stores. Minimum purchase: RM 100. Interest-free for 3 months.',
    TRUE
);

-- ============================================================================
-- PROMOTION 10: Premium Perk - Travel
-- ============================================================================
INSERT INTO promotions (title, subtitle, description, image_url, promotion_type, conditions, is_active)
VALUES (
    'Free Travel Insurance',
    'Complimentary coverage for your trips',
    'Book any travel package or flight with your RytGuard card and receive complimentary travel insurance coverage up to RM 100,000. Travel with peace of mind.',
    'promo_2.png',
    'premium_perk',
    'Valid for travel bookings above RM 1,000. Coverage includes medical, trip cancellation, and baggage loss. Terms apply.',
    TRUE
);


