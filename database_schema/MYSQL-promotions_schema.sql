-- ============================================================================
-- Promotions Table Schema - MySQL/TiDB Version
-- ============================================================================
-- Purpose: Store promotional offers that can be ranked by AI based on user finances
-- ============================================================================

CREATE TABLE IF NOT EXISTS promotions (
    promotion_id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL,
    subtitle VARCHAR(255),
    description TEXT NOT NULL,
    image_url VARCHAR(255),
    promotion_type ENUM('bnpl', 'cashback', 'voucher', 'premium_perk') NOT NULL,
    conditions TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
    
    INDEX idx_promotions_active (is_active),
    INDEX idx_promotions_type (promotion_type)
);


