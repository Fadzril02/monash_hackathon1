import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { Pool } from "pg";
import { z } from "zod";

/**
 * Helper function to create database connection
 */
function createDbConnection(): Pool {
  const connectionString = process.env.DATABASE_URL ||
    `postgresql://${process.env.DB_USER || 'postgres'}:${process.env.DB_PASSWORD || '420690'}@${process.env.DB_HOST || '127.0.0.1'}:${process.env.DB_PORT || '5433'}/${process.env.DB_NAME || 'ryt_guard'}`;

  return new Pool({ connectionString });
}

/**
 * Sets up all banking-specific MCP tools for RytGuard
 */
export function setupBankingTools(server: McpServer): void {
  // Tool 1: get-safe-balance
  setupGetSafeBalanceTool(server);

  // Tool 2: get-upcoming-bills
  setupGetUpcomingBillsTool(server);

  // Tool 3: check-affordability
  setupCheckAffordabilityTool(server);

  // Tool 4: get-spending-summary
  setupGetSpendingSummaryTool(server);

  // Tool 5: save-conversation
  setupSaveConversationTool(server);
}

/**
 * Tool 1: Get Safe Balance
 * Calculates user's safe balance (current balance - upcoming bills)
 */
function setupGetSafeBalanceTool(server: McpServer): void {
  const inputSchema = z.object({
    user_external_id: z.string().describe("External user ID (e.g., 'john_doe_001')"),
    lookahead_days: z.number().optional().default(30).describe("Number of days to look ahead for bills (default: 30)")
  });

  server.registerTool(
    "get-safe-balance",
    {
      title: "Get Safe Balance",
      description: "Calculate user's safe balance by subtracting upcoming bills from current balance",
      inputSchema: inputSchema
    },
    // @ts-ignore
    async (args: { user_external_id: string; lookahead_days?: number }) => {
      const pool = createDbConnection();

      try {
        // Get user_id from external_user_id
        const userResult = await pool.query(
          'SELECT user_id FROM users WHERE external_user_id = $1',
          [args.user_external_id]
        );

        if (userResult.rows.length === 0) {
          return {
            content: [{
              type: "text",
              text: JSON.stringify({
                error: "User not found",
                user_external_id: args.user_external_id
              }, null, 2)
            }]
          };
        }

        const userId = userResult.rows[0].user_id;
        const lookaheadDays = args.lookahead_days || 30;

        // Call calculate_safe_balance function
        const result = await pool.query(
          'SELECT * FROM calculate_safe_balance($1, $2)',
          [userId, lookaheadDays]
        );

        const data = result.rows[0];

        return {
          content: [{
            type: "text",
            text: JSON.stringify({
              user_external_id: args.user_external_id,
              current_balance: parseFloat(data.current_balance),
              upcoming_liabilities: parseFloat(data.upcoming_liabilities),
              safe_balance: parseFloat(data.safe_balance),
              status: data.status,
              upcoming_count: data.upcoming_count,
              next_payment_date: data.next_payment_date,
              next_payment_amount: data.next_payment_amount ? parseFloat(data.next_payment_amount) : null,
              lookahead_days: lookaheadDays,
              timestamp: new Date().toISOString()
            }, null, 2)
          }]
        };
      } catch (error) {
        return {
          content: [{
            type: "text",
            text: JSON.stringify({
              error: "Failed to calculate safe balance",
              message: error instanceof Error ? error.message : "Unknown error"
            }, null, 2)
          }]
        };
      } finally {
        await pool.end();
      }
    }
  );
}

/**
 * Tool 2: Get Upcoming Bills
 * Lists all upcoming recurring liabilities for the next N days
 */
function setupGetUpcomingBillsTool(server: McpServer): void {
  const inputSchema = z.object({
    user_external_id: z.string().describe("External user ID (e.g., 'john_doe_001')"),
    lookahead_days: z.number().optional().default(30).describe("Number of days to look ahead (default: 30)")
  });

  server.registerTool(
    "get-upcoming-bills",
    {
      title: "Get Upcoming Bills",
      description: "List all upcoming recurring liabilities and bills for a user",
      inputSchema: inputSchema
    },
    // @ts-ignore
    async (args: { user_external_id: string; lookahead_days?: number }) => {
      const pool = createDbConnection();

      try {
        const lookaheadDays = args.lookahead_days || 30;

        // Query the v_upcoming_payments_30days view
        const result = await pool.query(
          `SELECT
            liability_name,
            liability_type,
            amount,
            payment_date,
            payment_status
          FROM v_upcoming_payments_30days
          WHERE external_user_id = $1
            AND payment_date BETWEEN CURRENT_DATE AND CURRENT_DATE + $2 * INTERVAL '1 day'
          ORDER BY payment_date ASC`,
          [args.user_external_id, lookaheadDays]
        );

        const bills = result.rows.map(row => ({
          liability_name: row.liability_name,
          liability_type: row.liability_type,
          amount: parseFloat(row.amount),
          payment_date: row.payment_date,
          payment_status: row.payment_status
        }));

        return {
          content: [{
            type: "text",
            text: JSON.stringify({
              user_external_id: args.user_external_id,
              lookahead_days: lookaheadDays,
              bills_count: bills.length,
              total_amount: bills.reduce((sum, bill) => sum + bill.amount, 0),
              bills: bills,
              timestamp: new Date().toISOString()
            }, null, 2)
          }]
        };
      } catch (error) {
        return {
          content: [{
            type: "text",
            text: JSON.stringify({
              error: "Failed to fetch upcoming bills",
              message: error instanceof Error ? error.message : "Unknown error"
            }, null, 2)
          }]
        };
      } finally {
        await pool.end();
      }
    }
  );
}

/**
 * Tool 3: Check Affordability
 * Checks if user can afford a purchase based on safe balance
 */
function setupCheckAffordabilityTool(server: McpServer): void {
  const inputSchema = z.object({
    user_external_id: z.string().describe("External user ID (e.g., 'john_doe_001')"),
    purchase_amount: z.number().describe("Amount of the purchase in RM"),
    purchase_description: z.string().optional().describe("Description of what user wants to buy")
  });

  server.registerTool(
    "check-affordability",
    {
      title: "Check Affordability",
      description: "Check if user can afford a purchase based on their safe balance",
      inputSchema: inputSchema
    },
    // @ts-ignore
    async (args: { user_external_id: string; purchase_amount: number; purchase_description?: string }) => {
      const pool = createDbConnection();

      try {
        // Get user_id
        const userResult = await pool.query(
          'SELECT user_id FROM users WHERE external_user_id = $1',
          [args.user_external_id]
        );

        if (userResult.rows.length === 0) {
          return {
            content: [{
              type: "text",
              text: JSON.stringify({
                error: "User not found",
                user_external_id: args.user_external_id
              }, null, 2)
            }]
          };
        }

        const userId = userResult.rows[0].user_id;

        // Get safe balance
        const balanceResult = await pool.query(
          'SELECT * FROM calculate_safe_balance($1, 30)',
          [userId]
        );

        const safeBalance = parseFloat(balanceResult.rows[0].safe_balance);
        const currentBalance = parseFloat(balanceResult.rows[0].current_balance);
        const upcomingLiabilities = parseFloat(balanceResult.rows[0].upcoming_liabilities);
        const status = balanceResult.rows[0].status;

        // Get upcoming bills for context
        const billsResult = await pool.query(
          `SELECT liability_name, amount, payment_date
           FROM v_upcoming_payments_30days
           WHERE external_user_id = $1
           ORDER BY payment_date ASC
           LIMIT 5`,
          [args.user_external_id]
        );

        const upcomingBills = billsResult.rows.map(row => ({
          name: row.liability_name,
          amount: parseFloat(row.amount),
          date: row.payment_date
        }));

        // Determine affordability
        const canAfford = safeBalance >= args.purchase_amount;
        const remainingAfterPurchase = safeBalance - args.purchase_amount;

        // Generate recommendation
        let recommendation = "";
        if (canAfford && remainingAfterPurchase > safeBalance * 0.3) {
          recommendation = "This purchase is well within your safe range. Go ahead!";
        } else if (canAfford && remainingAfterPurchase > 0) {
          recommendation = "You can afford this, but it will significantly reduce your safe balance. Consider if it's essential.";
        } else {
          recommendation = "This purchase would exceed your safe balance. I recommend waiting until after your upcoming bills are paid.";
        }

        return {
          content: [{
            type: "text",
            text: JSON.stringify({
              user_external_id: args.user_external_id,
              purchase_description: args.purchase_description || "item",
              purchase_amount: args.purchase_amount,
              financial_overview: {
                current_balance: currentBalance,
                upcoming_liabilities: upcomingLiabilities,
                safe_balance: safeBalance,
                status: status
              },
              affordability_check: {
                can_afford: canAfford,
                remaining_after_purchase: remainingAfterPurchase,
                percentage_of_safe_balance: ((args.purchase_amount / safeBalance) * 100).toFixed(1) + "%"
              },
              recommendation: recommendation,
              upcoming_bills_preview: upcomingBills,
              timestamp: new Date().toISOString()
            }, null, 2)
          }]
        };
      } catch (error) {
        return {
          content: [{
            type: "text",
            text: JSON.stringify({
              error: "Failed to check affordability",
              message: error instanceof Error ? error.message : "Unknown error"
            }, null, 2)
          }]
        };
      } finally {
        await pool.end();
      }
    }
  );
}

/**
 * Tool 4: Get Spending Summary
 * Analyzes spending patterns by category
 */
function setupGetSpendingSummaryTool(server: McpServer): void {
  const inputSchema = z.object({
    user_external_id: z.string().describe("External user ID (e.g., 'john_doe_001')"),
    days_back: z.number().optional().default(30).describe("Number of days to analyze (default: 30)")
  });

  server.registerTool(
    "get-spending-summary",
    {
      title: "Get Spending Summary",
      description: "Analyze user's spending patterns by category over time",
      inputSchema: inputSchema
    },
    // @ts-ignore
    async (args: { user_external_id: string; days_back?: number }) => {
      const pool = createDbConnection();

      try {
        const daysBack = args.days_back || 30;

        // Get user_id
        const userResult = await pool.query(
          'SELECT user_id FROM users WHERE external_user_id = $1',
          [args.user_external_id]
        );

        if (userResult.rows.length === 0) {
          return {
            content: [{
              type: "text",
              text: JSON.stringify({
                error: "User not found",
                user_external_id: args.user_external_id
              }, null, 2)
            }]
          };
        }

        const userId = userResult.rows[0].user_id;

        // Get spending by category
        const result = await pool.query(
          `SELECT
            COALESCE(category, 'Uncategorized') as category,
            COUNT(*) as transaction_count,
            SUM(ABS(amount)) as total_spent,
            AVG(ABS(amount)) as average_transaction
          FROM transactions
          WHERE user_id = $1
            AND transaction_type = 'DEBIT'
            AND transaction_date >= CURRENT_DATE - $2 * INTERVAL '1 day'
          GROUP BY category
          ORDER BY total_spent DESC`,
          [userId, daysBack]
        );

        const categories = result.rows.map(row => ({
          category: row.category,
          transaction_count: parseInt(row.transaction_count),
          total_spent: parseFloat(row.total_spent),
          average_transaction: parseFloat(row.average_transaction)
        }));

        const totalSpent = categories.reduce((sum, cat) => sum + cat.total_spent, 0);

        return {
          content: [{
            type: "text",
            text: JSON.stringify({
              user_external_id: args.user_external_id,
              period_days: daysBack,
              summary: {
                total_spent: totalSpent,
                total_transactions: categories.reduce((sum, cat) => sum + cat.transaction_count, 0),
                categories_count: categories.length
              },
              categories: categories,
              timestamp: new Date().toISOString()
            }, null, 2)
          }]
        };
      } catch (error) {
        return {
          content: [{
            type: "text",
            text: JSON.stringify({
              error: "Failed to get spending summary",
              message: error instanceof Error ? error.message : "Unknown error"
            }, null, 2)
          }]
        };
      } finally {
        await pool.end();
      }
    }
  );
}

/**
 * Tool 5: Save Conversation
 * Stores conversation history in the database
 */
function setupSaveConversationTool(server: McpServer): void {
  const inputSchema = z.object({
    user_external_id: z.string().describe("External user ID (e.g., 'john_doe_001')"),
    role: z.enum(['user', 'assistant', 'system']).describe("Role of the message sender"),
    message: z.string().describe("The message content"),
    metadata: z.record(z.any()).optional().describe("Optional metadata (JSON object)")
  });

  server.registerTool(
    "save-conversation",
    {
      title: "Save Conversation",
      description: "Store conversation history in the database for context and analysis",
      inputSchema: inputSchema
    },
    // @ts-ignore
    async (args: { user_external_id: string; role: string; message: string; metadata?: any }) => {
      const pool = createDbConnection();

      try {
        // Get user_id and safe_balance
        const userResult = await pool.query(
          `SELECT
            u.user_id,
            COALESCE(
              (SELECT safe_balance FROM calculate_safe_balance(u.user_id, 30)),
              u.current_balance
            ) as safe_balance
           FROM users u
           WHERE u.external_user_id = $1`,
          [args.user_external_id]
        );

        if (userResult.rows.length === 0) {
          return {
            content: [{
              type: "text",
              text: JSON.stringify({
                error: "User not found",
                user_external_id: args.user_external_id
              }, null, 2)
            }]
          };
        }

        const userId = userResult.rows[0].user_id;
        const safeBalance = userResult.rows[0].safe_balance;

        // Insert conversation message
        const result = await pool.query(
          `INSERT INTO conversation_history
           (user_id, role, message_text, safe_balance_at_time, metadata)
           VALUES ($1, $2, $3, $4, $5)
           RETURNING message_id, created_at`,
          [userId, args.role, args.message, safeBalance, args.metadata ? JSON.stringify(args.metadata) : null]
        );

        return {
          content: [{
            type: "text",
            text: JSON.stringify({
              saved: true,
              message_id: result.rows[0].message_id,
              user_external_id: args.user_external_id,
              role: args.role,
              safe_balance_at_time: parseFloat(safeBalance),
              created_at: result.rows[0].created_at,
              timestamp: new Date().toISOString()
            }, null, 2)
          }]
        };
      } catch (error) {
        return {
          content: [{
            type: "text",
            text: JSON.stringify({
              error: "Failed to save conversation",
              message: error instanceof Error ? error.message : "Unknown error"
            }, null, 2)
          }]
        };
      } finally {
        await pool.end();
      }
    }
  );
}
