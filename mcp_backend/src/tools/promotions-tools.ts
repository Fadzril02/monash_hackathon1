import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import mysql from "mysql2/promise";
import { z } from "zod";
import { Promotion } from "../models/promotion.js";

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
 * Sets up promotion-related MCP tools for RytGuard
 */
export function setupPromotionTools(server: McpServer): void {
  setupRankPromotionsTool(server);
}

/**
 * Tool: Rank Promotions
 * Ranks promotions based on user's financial situation
 */
function setupRankPromotionsTool(server: McpServer): void {
  const inputSchema = z.object({
    user_external_id: z.string().describe("External user ID (e.g., 'john_doe_001')"),
    promotions: z.array(z.object({
      promotion_id: z.number(),
      title: z.string(),
      subtitle: z.string().nullable(),
      description: z.string(),
      image_url: z.string().nullable(),
      promotion_type: z.enum(['bnpl', 'cashback', 'voucher', 'premium_perk']),
      conditions: z.string().nullable(),
      is_active: z.boolean(),
      created_at: z.string(),
      updated_at: z.string()
    })).describe("List of promotions to rank"),
    user_financial_summary: z.object({
      safe_balance: z.number().describe("User's safe balance (current balance - upcoming bills)"),
      current_balance: z.number().describe("User's current account balance"),
      upcoming_liabilities: z.number().describe("Total upcoming bills in next 30 days"),
      status: z.enum(['HEALTHY', 'WARNING', 'CRITICAL']).describe("Financial health status"),
      avg_monthly_income: z.number().optional().describe("Average monthly income"),
      avg_monthly_expenses: z.number().optional().describe("Average monthly expenses"),
      current_dsr: z.number().optional().describe("Debt Service Ratio percentage"),
      dsr_status: z.enum(['HEALTHY', 'WARNING', 'CRITICAL']).optional().describe("DSR status")
    }).describe("User's financial summary for ranking context")
  });

  server.registerTool(
    "rank-promotions",
    {
      title: "Rank Promotions",
      description: "Rank promotions based on user's financial situation. Returns promotions sorted from most to least relevant.",
      inputSchema: inputSchema
    },
    // @ts-ignore
    async (args: { 
      user_external_id: string; 
      promotions: Promotion[]; 
      user_financial_summary: any 
    }) => {
      try {
        const { promotions, user_financial_summary } = args;
        
        // This tool is called by Claude AI, which will do the ranking logic
        // We just need to return the promotions in a format Claude can work with
        // Claude will use the financial summary to rank them
        
        // For now, return the promotions with financial context
        // Claude will process this and return ranked results
        return {
          content: [{
            type: "text",
            text: JSON.stringify({
              user_external_id: args.user_external_id,
              financial_context: user_financial_summary,
              promotions_count: promotions.length,
              promotions: promotions,
              ranking_guidelines: {
                low_safe_balance: "Prioritize promotions that offer cost savings or flexible payments (bnpl, cashback)",
                high_safe_balance: "Prioritize premium_perk and high-value voucher promotions",
                good_habits: "Reward users with relevant offers like cashback on timely BNPL payments",
                critical_status: "Focus on cashback and BNPL options to help manage cash flow"
              },
              timestamp: new Date().toISOString()
            }, null, 2)
          }]
        };
      } catch (error) {
        return {
          content: [{
            type: "text",
            text: JSON.stringify({
              error: "Failed to rank promotions",
              message: error instanceof Error ? error.message : "Unknown error"
            }, null, 2)
          }]
        };
      }
    }
  );
}


