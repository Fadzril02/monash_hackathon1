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
- **Low 'Safe to Spend' balance (< 30% of current balance or CRITICAL status):** Prioritize promotions that offer cost savings or flexible payments (e.g., 'bnpl', 'cashback').
- **High 'Safe to Spend' balance (> 30% of current balance or HEALTHY status):** Prioritize 'premium_perk' and high-value 'voucher' promotions.
- **Good financial habits (low DSR, on-time payments):** Reward users with relevant offers like cashback on timely BNPL payments.
- **WARNING status:** Balance between cashback/BNPL and premium perks based on specific amounts.

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

Promotions to rank:
${JSON.stringify(promotions, null, 2)}

Return ONLY a valid JSON array of promotions, sorted from most to least relevant. Maintain all original fields from each promotion.`;

  // Use Claude Sonnet model for ranking (better quality than Haiku)
  const response = await anthropic.messages.create({
    model: 'claude-sonnet-4-20250514',
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

  return rankedPromotions;
}

/**
 * Get ranked promotions for a user
 */
// Simple in-memory cache for rankings (5 minute TTL)
const rankingCache = new Map<string, { data: RankedPromotion[]; timestamp: number }>();
const CACHE_TTL = 5 * 60 * 1000; // 5 minutes

export async function getRankedPromotions(userExternalId: string): Promise<RankedPromotion[]> {
  const pool = createDbConnection();

  try {
    // Check cache first
    const cacheKey = userExternalId;
    const cached = rankingCache.get(cacheKey);
    if (cached && Date.now() - cached.timestamp < CACHE_TTL) {
      console.log(`✅ Using cached rankings for ${userExternalId}`);
      return cached.data;
    }

    // 1. Fetch user's financial summary and promotions in parallel
    const [userFinancialSummary, promotions] = await Promise.all([
      getUserFinancialSummary(pool, userExternalId),
      getAllActivePromotions(pool)
    ]);

    if (promotions.length === 0) {
      return [];
    }

    // 2. Rank promotions using AI (this is the slowest part)
    console.log(`🤖 Ranking ${promotions.length} promotions for ${userExternalId}...`);
    const startTime = Date.now();
    const rankedPromotions = await rankPromotionsWithAI(
      promotions,
      userFinancialSummary,
      userExternalId
    );
    const duration = Date.now() - startTime;
    console.log(`✅ Ranking completed in ${duration}ms`);

    // Cache the results
    rankingCache.set(cacheKey, { data: rankedPromotions, timestamp: Date.now() });

    return rankedPromotions;
  } catch (error) {
    console.error('Error getting ranked promotions:', error);
    throw error;
  } finally {
    await pool.end();
  }
}

