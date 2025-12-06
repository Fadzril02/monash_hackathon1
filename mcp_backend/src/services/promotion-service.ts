import mysql from "mysql2/promise";
import { Anthropic } from "@anthropic-ai/sdk";
import { Promotion, RankedPromotion } from "../models/promotion.js";

/**
 * Helper function to create database connection
 */
function createDbConnection(): mysql.Pool {
  const connectionString = process.env.DATABASE_URL;

  if (connectionString) {
    return mysql.createPool({
      uri: connectionString,
      ssl: {
        rejectUnauthorized: true,
        minVersion: 'TLSv1.2'
      }
    });
  }

  return mysql.createPool({
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '3306'),
    database: process.env.DB_NAME || 'ryt_guard',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    ssl: process.env.DB_SSL === 'true' ? {
      rejectUnauthorized: true,
      minVersion: 'TLSv1.2'
    } : undefined
  });
}

/**
 * Get user's financial summary for promotion ranking
 */
async function getUserFinancialSummary(
  pool: mysql.Pool, 
  userExternalId: string
): Promise<any> {
  const lookaheadDays = 30;

  // Optimize: Use view for safe balance (faster than complex query)
  // Run all queries in parallel for better performance
  const [userRows, balanceResults, incomeRows, expenseRows, debtRows] = await Promise.all([
    pool.query('SELECT user_id FROM users WHERE external_user_id = ?', [userExternalId]),
    pool.query('SELECT * FROM v_user_safe_balance WHERE external_user_id = ?', [userExternalId]),
    pool.query(
      `SELECT AVG(monthly_income) as avg_income FROM (
        SELECT DATE_FORMAT(transaction_date, '%Y-%m') as month,
               SUM(amount) as monthly_income
        FROM transactions t
        JOIN users u ON t.user_id = u.user_id
        WHERE u.external_user_id = ?
          AND t.transaction_type = 'CREDIT'
          AND t.transaction_date >= DATE_SUB(NOW(), INTERVAL 3 MONTH)
          AND t.category NOT IN ('Loan Disbursement', 'Refund')
        GROUP BY month
      ) monthly_totals`,
      [userExternalId]
    ),
    pool.query(
      `SELECT AVG(monthly_expense) as avg_expense FROM (
        SELECT DATE_FORMAT(transaction_date, '%Y-%m') as month,
               SUM(ABS(amount)) as monthly_expense
        FROM transactions t
        JOIN users u ON t.user_id = u.user_id
        WHERE u.external_user_id = ?
          AND t.transaction_type = 'DEBIT'
          AND t.transaction_date >= DATE_SUB(NOW(), INTERVAL 3 MONTH)
          AND t.category != 'LOAN'
        GROUP BY month
      ) monthly_totals`,
      [userExternalId]
    ),
    pool.query(
      `SELECT SUM(rl.amount) as total_debt
       FROM recurring_liabilities rl
       JOIN users u ON rl.user_id = u.user_id
       WHERE u.external_user_id = ?
         AND rl.is_active = true
         AND rl.liability_type IN ('LOAN', 'BNPL')`,
      [userExternalId]
    )
  ]);

  if (!Array.isArray(userRows[0]) || userRows[0].length === 0) {
    throw new Error(`User not found: ${userExternalId}`);
  }

  const balanceResultsArray = balanceResults[0] as any[];
  if (!balanceResultsArray || balanceResultsArray.length === 0) {
    throw new Error(`Could not calculate safe balance for user: ${userExternalId}`);
  }
  const balance = balanceResultsArray[0];

  const incomeRowsArray = incomeRows[0] as any[];
  const avgIncome = incomeRowsArray[0]?.avg_income ? parseFloat(incomeRowsArray[0].avg_income) : 0;

  const expenseRowsArray = expenseRows[0] as any[];
  const avgExpenses = expenseRowsArray[0]?.avg_expense ? parseFloat(expenseRowsArray[0].avg_expense) : 0;

  const debtRowsArray = debtRows[0] as any[];
  const totalDebt = debtRowsArray[0]?.total_debt ? parseFloat(debtRowsArray[0].total_debt) : 0;
  const dsr = avgIncome > 0 ? (totalDebt / avgIncome) * 100 : 0;

  return {
    safe_balance: parseFloat(balance.safe_balance),
    current_balance: parseFloat(balance.current_balance),
    upcoming_liabilities: parseFloat(balance.upcoming_liabilities || 0),
    status: balance.status,
    avg_monthly_income: avgIncome,
    avg_monthly_expenses: avgExpenses,
    current_dsr: dsr,
    dsr_status: dsr < 30 ? 'HEALTHY' : dsr < 40 ? 'WARNING' : 'CRITICAL'
  };
}

/**
 * Get all active promotions from database
 */
async function getAllActivePromotions(pool: mysql.Pool): Promise<Promotion[]> {
  const [rows] = await pool.query(
    'SELECT * FROM promotions WHERE is_active = true ORDER BY created_at DESC'
  );

  return (rows as any[]).map(row => ({
    promotion_id: row.promotion_id,
    title: row.title,
    subtitle: row.subtitle,
    description: row.description,
    image_url: row.image_url,
    promotion_type: row.promotion_type,
    conditions: row.conditions,
    is_active: row.is_active === 1 || row.is_active === true,
    created_at: row.created_at,
    updated_at: row.updated_at
  }));
}

/**
 * Rank promotions using Claude AI
 */
async function rankPromotionsWithAI(
  promotions: Promotion[],
  userFinancialSummary: any,
  userExternalId: string
): Promise<RankedPromotion[]> {
  if (!process.env.ANTHROPIC_API_KEY) {
    throw new Error('ANTHROPIC_API_KEY not configured');
  }

  const anthropic = new Anthropic({
    apiKey: process.env.ANTHROPIC_API_KEY
  });

  const systemPrompt = `You are a financial assistant. Your task is to rank promotions based on the user's financial situation.

Ranking Guidelines:
- **CRITICAL/RED status (Safe Balance < 0 or negative):** MANDATORY - ALWAYS prioritize BNPL promotions FIRST, followed by cashback. This is a DEMO requirement - BNPL must be #1 for CRITICAL status.
- **Low 'Safe to Spend' balance (< 30% of current balance or WARNING status):** Prioritize promotions that offer cost savings (e.g., 'cashback', then 'bnpl').
- **High 'Safe to Spend' balance (> 30% of current balance or HEALTHY status):** Prioritize 'premium_perk' and high-value 'voucher' promotions.
- **Good financial habits (low DSR, on-time payments):** Reward users with relevant offers like cashback on timely BNPL payments.

CRITICAL RULE: If status is 'CRITICAL', put ALL 'bnpl' type promotions at the TOP of the list, then cashback, then others.

Return the full list of promotions as a JSON array, sorted from most to least relevant. Each promotion should maintain all its original fields.`;

  const userMessage = `Please rank these ${promotions.length} promotions for user ${userExternalId}:

User Financial Summary:
- Safe Balance: RM ${userFinancialSummary.safe_balance.toFixed(2)}
- Current Balance: RM ${userFinancialSummary.current_balance.toFixed(2)}
- Upcoming Liabilities (30 days): RM ${userFinancialSummary.upcoming_liabilities.toFixed(2)}
- Financial Status: ${userFinancialSummary.status}
- Average Monthly Income: RM ${userFinancialSummary.avg_monthly_income.toFixed(2)}
- Average Monthly Expenses: RM ${userFinancialSummary.avg_monthly_expenses.toFixed(2)}
- Debt Service Ratio: ${userFinancialSummary.current_dsr.toFixed(1)}% (${userFinancialSummary.dsr_status})

${userFinancialSummary.status === 'CRITICAL' ? '⚠️ CRITICAL STATUS DETECTED - MANDATORY: Place ALL BNPL promotions (promotion_type: "bnpl") at the TOP of the ranking list!' : ''}

Promotions to rank:
${JSON.stringify(promotions, null, 2)}

Return ONLY a valid JSON array of promotions, sorted from most to least relevant. ${userFinancialSummary.status === 'CRITICAL' ? 'REMEMBER: BNPL promotions MUST be ranked first for CRITICAL status!' : 'Maintain all original fields from each promotion.'}`;

  // Use Claude Haiku 4.5 model for promotion ranking (faster for demo)
  const response = await anthropic.messages.create({
    model: 'claude-haiku-4-5-20251001',
    max_tokens: 4096,
    system: systemPrompt,
    messages: [{
      role: 'user',
      content: userMessage
    }]
  });

  // Extract JSON from response
  const textBlocks = response.content.filter(
    (block): block is Anthropic.TextBlock => block.type === 'text'
  );
  const responseText = textBlocks.map(block => block.text).join('\n');

  // Try to parse JSON from response
  let rankedPromotions: RankedPromotion[];
  try {
    // Extract JSON array from response (handle markdown code blocks)
    const jsonMatch = responseText.match(/\[[\s\S]*\]/);
    if (jsonMatch) {
      rankedPromotions = JSON.parse(jsonMatch[0]);
    } else {
      // Fallback: try parsing entire response
      rankedPromotions = JSON.parse(responseText);
    }
  } catch (error) {
    console.error('Failed to parse AI response as JSON:', responseText);
    // Fallback: return original promotions if parsing fails
    return promotions.map(p => ({ ...p }));
  }

  // DEMO REQUIREMENT: Force BNPL to top for CRITICAL status
  if (userFinancialSummary.status === 'CRITICAL') {
    console.log('🎯 CRITICAL status detected - Enforcing BNPL first policy');
    
    // Separate BNPL and non-BNPL promotions
    const bnplPromotions = rankedPromotions.filter(p => p.promotion_type === 'bnpl');
    const otherPromotions = rankedPromotions.filter(p => p.promotion_type !== 'bnpl');
    
    // Put BNPL first, then others
    rankedPromotions = [...bnplPromotions, ...otherPromotions];
    
    console.log(`✅ Reordered: ${bnplPromotions.length} BNPL promotions placed at top`);
  }

  return rankedPromotions;
}

/**
 * Get ranked promotions for a user
 * CACHED PER SESSION - Clears cache on each query, MCP does selection
 */
// Simple in-memory cache for rankings
const rankingCache = new Map<string, { data: RankedPromotion[]; safeBalance: number; status: string; timestamp: number }>();
const CACHE_TTL = 60 * 1000; // 1 minute - short cache to simulate "per session"

export async function getRankedPromotions(userExternalId: string, forceRefresh = false): Promise<RankedPromotion[]> {
  const pool = createDbConnection();

  try {
    // Check if we should use cached data
    const cached = rankingCache.get(userExternalId);
    const cacheValid = cached && !forceRefresh && (Date.now() - cached.timestamp < CACHE_TTL);
    
    if (cacheValid) {
      console.log(`✅ Using cached rankings for ${userExternalId} (Safe Balance: RM ${cached.safeBalance.toFixed(2)}, Status: ${cached.status})`);
      return cached.data;
    }
    
    if (forceRefresh) {
      console.log(`🔄 Force refresh requested for ${userExternalId}`);
    } else {
      console.log(`🔄 Cache expired or not found, fetching fresh rankings for ${userExternalId}...`);
    }
    
    // 1. Fetch user's current financial summary
    const userFinancialSummary = await getUserFinancialSummary(pool, userExternalId);
    const currentSafeBalance = userFinancialSummary.safeBalance ?? 0;
    const currentStatus = userFinancialSummary.status;
    
    console.log(`📊 Current financial status: Safe Balance RM ${currentSafeBalance.toFixed(2)}, Status: ${currentStatus}`);

    // 2. Fetch all active promotions
    const promotions = await getAllActivePromotions(pool);

    if (promotions.length === 0) {
      console.log('⚠️ No active promotions available');
      return [];
    }

    // 3. Rank promotions using AI/MCP based on current financial situation
    console.log(`🤖 Ranking ${promotions.length} promotions using AI/MCP...`);
    const startTime = Date.now();
    const rankedPromotions = await rankPromotionsWithAI(
      promotions,
      userFinancialSummary,
      userExternalId
    );
    const duration = Date.now() - startTime;
    console.log(`✅ Ranking completed in ${duration}ms`);

    // Cache the results with timestamp
    rankingCache.set(userExternalId, {
      data: rankedPromotions,
      safeBalance: currentSafeBalance,
      status: currentStatus,
      timestamp: Date.now()
    });
    
    console.log(`💾 Cached rankings for ${userExternalId} (TTL: ${CACHE_TTL/1000}s)`);

    return rankedPromotions;
  } catch (error) {
    console.error('Error getting ranked promotions:', error);
    throw error;
  } finally {
    await pool.end();
  }
}

/**
 * Clear cache for a user (call after reload/withdraw to invalidate)
 */
export function clearPromotionCache(userExternalId: string): void {
  rankingCache.delete(userExternalId);
  console.log(`🗑️ Cleared promotion cache for ${userExternalId}`);
}

