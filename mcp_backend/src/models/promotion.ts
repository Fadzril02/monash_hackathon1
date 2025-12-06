/**
 * Promotion Model
 * Represents a promotional offer in the database
 */
export interface Promotion {
  promotion_id: number;
  title: string;
  subtitle: string | null;
  description: string;
  image_url: string | null;
  promotion_type: 'bnpl' | 'cashback' | 'voucher' | 'premium_perk';
  conditions: string | null;
  is_active: boolean;
  created_at: Date;
  updated_at: Date;
}

/**
 * Promotion ranking result from AI
 */
export interface RankedPromotion extends Promotion {
  relevance_score?: number;
  ranking_reason?: string;
}


