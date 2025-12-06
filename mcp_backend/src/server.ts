import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import path from "path";
import { fileURLToPath } from "url";
import { dirname, join } from "path";
import { existsSync } from "fs";
import { randomUUID } from "node:crypto";
import { StreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/streamableHttp.js";
import { isInitializeRequest } from "@modelcontextprotocol/sdk/types.js";
import { createMCPServer } from "./mcp-server.js";
import Anthropic from "@anthropic-ai/sdk";

import type { Request, Response } from "express";

// Load environment variables - try root folder first, then local
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const rootEnvPath = join(__dirname, '..', '..', '.env');
const localEnvPath = join(__dirname, '..', '.env');

if (existsSync(rootEnvPath)) {
  dotenv.config({ path: rootEnvPath });
  console.log('📁 Loaded .env from root folder');
} else if (existsSync(localEnvPath)) {
  dotenv.config({ path: localEnvPath });
  console.log('📁 Loaded .env from mcp_check folder');
} else {
  dotenv.config(); // Default behavior
}

const app = express();
const PORT = 3001;

// Debug: Check if API key is loaded
console.log('🔑 Anthropic API Key loaded:', process.env.ANTHROPIC_API_KEY ? 'YES ✅' : 'NO ❌');
if (process.env.ANTHROPIC_API_KEY) {
  console.log('🔑 Key starts with:', process.env.ANTHROPIC_API_KEY.substring(0, 15) + '...');
}

// Middleware - CORS configuration for MCP browser clients
app.use(cors({
  origin: function(origin, callback) {
    // Allow requests with no origin (like mobile apps or curl)
    if (!origin) return callback(null, true);
    // Allow all localhost origins
    if (origin.includes('localhost') || origin.includes('127.0.0.1')) {
      return callback(null, true);
    }
    callback(null, true);
  },
  methods: ['GET', 'POST', 'DELETE', 'OPTIONS'],
  allowedHeaders: [
    'Content-Type',
    'mcp-session-id',
    'mcp-protocol-version',
    'Authorization'
  ],
  exposedHeaders: ['mcp-session-id'],
  credentials: true
}));
app.use(express.json());
app.use(express.static('public'));

// Transport storage for session management
const transports: Record<string, StreamableHTTPServerTransport> = {};

console.log("🐘 Starting PostgreSQL MCP Server...");

// MCP endpoint handler function
const handleMCPRequest = async (req: Request, res: Response) => {
  const sessionId = req.headers['mcp-session-id'] as string | undefined;
  let transport: StreamableHTTPServerTransport;

  try {
    if (sessionId && transports[sessionId]) {
      // Reuse existing transport for the session
      transport = transports[sessionId];
      console.log(`🔄 Reusing session: ${sessionId}`);
    } else if (!sessionId && isInitializeRequest(req.body)) {
      // Create new transport for initialization request
      console.log("🆕 Creating new MCP session...");

      transport = new StreamableHTTPServerTransport({
        sessionIdGenerator: () => randomUUID(),
        onsessioninitialized: (newSessionId) => {
          // Store the transport by session ID
          transports[newSessionId] = transport;
          console.log(`✅ Session initialized: ${newSessionId}`);
        }
      });

      // Cleanup on transport close
      transport.onclose = () => {
        if (transport.sessionId) {
          delete transports[transport.sessionId];
          console.log(`🧹 Session cleaned up: ${transport.sessionId}`);
        }
      };

      // Create and connect MCP server
      const server = createMCPServer();
      await server.connect(transport);
    } else if (!sessionId && req.body.method === 'tools/call') {
      // HACKATHON MVP: Allow direct tool calls without session for postgres-query
      console.log("⚡ Direct tool call (no session) - creating temporary session...");

      transport = new StreamableHTTPServerTransport({
        sessionIdGenerator: () => randomUUID(),
        onsessioninitialized: (newSessionId) => {
          // Store the transport by session ID
          transports[newSessionId] = transport;
          console.log(`✅ Temporary session initialized: ${newSessionId}`);
        }
      });

      // Cleanup on transport close
      transport.onclose = () => {
        if (transport.sessionId) {
          delete transports[transport.sessionId];
          console.log(`🧹 Temporary session cleaned up: ${transport.sessionId}`);
        }
      };

      // Create and connect MCP server
      const server = createMCPServer();
      await server.connect(transport);
    } else {
      // Invalid request
      res.status(400).json({
        jsonrpc: '2.0',
        error: {
          code: -32000,
          message: 'Bad Request: No valid session ID provided or not an initialization request',
        },
        id: null,
      });
      return;
    }

    // Handle the request
    await transport.handleRequest(req, res, req.body);
  } catch (error) {
    console.error('❌ Error handling MCP request:', error);
    if (!res.headersSent) {
      res.status(500).json({
        jsonrpc: '2.0',
        error: {
          code: -32603,
          message: 'Internal server error',
        },
        id: null,
      });
    }
  }
};

// MCP endpoint handlers - both root and /mcp serve the same functionality
app.post('/', handleMCPRequest);
app.post('/mcp', handleMCPRequest);

// Health check endpoint
app.get('/health', (req: Request, res: Response) => {
  res.json({
    status: 'ok',
    server: 'postgresql-mcp',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
    database: {
      configured: !!process.env.DATABASE_URL ||
                 !!(process.env.DB_HOST && process.env.DB_NAME && process.env.DB_USER)
    }
  });
});

// HACKATHON MVP: Direct REST API endpoint for quick queries
import { Pool } from 'pg';

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5433'),
  database: process.env.DB_NAME || 'ryt_guard',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || '420690',
});

app.post('/api/query', async (req: Request, res: Response) => {
  try {
    const { query } = req.body;
    if (!query) {
      return res.status(400).json({ error: 'Query is required' });
    }

    console.log(`📊 Executing query: ${query.substring(0, 100)}...`);
    const result = await pool.query(query);

    res.json({
      success: true,
      data: result.rows,
      rowCount: result.rowCount
    });
  } catch (error: any) {
    console.error('❌ Query error:', error.message);
    res.status(500).json({
      error: error.message,
      success: false
    });
  }
});

// Initialize Anthropic client
const anthropic = new Anthropic({
  apiKey: process.env.ANTHROPIC_API_KEY || '',
});

// Define banking tools for Claude
const BANKING_TOOLS: Anthropic.Tool[] = [
  {
    name: 'get-safe-balance',
    description: 'Calculate user\'s safe balance by subtracting upcoming bills from current balance',
    input_schema: {
      type: 'object',
      properties: {
        user_external_id: {
          type: 'string',
          description: 'External user ID (e.g., john_doe_001)'
        },
        lookahead_days: {
          type: 'number',
          description: 'Number of days to look ahead for bills (default: 30)'
        }
      },
      required: ['user_external_id']
    }
  },
  {
    name: 'get-upcoming-bills',
    description: 'List all upcoming recurring liabilities and bills for a user',
    input_schema: {
      type: 'object',
      properties: {
        user_external_id: {
          type: 'string',
          description: 'External user ID (e.g., john_doe_001)'
        },
        lookahead_days: {
          type: 'number',
          description: 'Number of days to look ahead (default: 30)'
        }
      },
      required: ['user_external_id']
    }
  },
  {
    name: 'check-affordability',
    description: 'Check if user can afford a purchase based on their safe balance',
    input_schema: {
      type: 'object',
      properties: {
        user_external_id: {
          type: 'string',
          description: 'External user ID (e.g., john_doe_001)'
        },
        purchase_amount: {
          type: 'number',
          description: 'Amount of the purchase in RM'
        },
        purchase_description: {
          type: 'string',
          description: 'Description of what user wants to buy'
        }
      },
      required: ['user_external_id', 'purchase_amount']
    }
  },
  {
    name: 'get-financial-analysis',
    description: 'Get comprehensive financial analysis including current DSR, average income/expenses, and debt obligations. Use this to understand the user\'s overall financial health and make predictions.',
    input_schema: {
      type: 'object',
      properties: {
        user_external_id: {
          type: 'string',
          description: 'External user ID (e.g., john_doe_001)'
        }
      },
      required: ['user_external_id']
    }
  }
];

// Helper function to execute MCP tools
async function executeMCPTool(toolName: string, toolInput: any): Promise<any> {
  // Dynamically get user UUID from external_user_id
  const userQuery = await pool.query(
    'SELECT user_id FROM users WHERE external_user_id = $1',
    [toolInput.user_external_id]
  );

  if (userQuery.rows.length === 0) {
    throw new Error(`User not found: ${toolInput.user_external_id}`);
  }

  const userUuid = userQuery.rows[0].user_id;
  const lookaheadDays = toolInput.lookahead_days || 30;

  try {
    if (toolName === 'get-safe-balance') {
      const query = `SELECT * FROM calculate_safe_balance('${userUuid}', ${lookaheadDays});`;
      console.log(`🔧 Executing tool: ${toolName}`);
      const result = await pool.query(query);
      return result.rows[0];
    } else if (toolName === 'get-upcoming-bills') {
      const query = `
        SELECT * FROM v_upcoming_payments_30days
        WHERE external_user_id = '${toolInput.user_external_id}'
        AND payment_date <= CURRENT_DATE + INTERVAL '${lookaheadDays} days'
        ORDER BY payment_date ASC;
      `;
      console.log(`🔧 Executing tool: ${toolName}`);
      const result = await pool.query(query);
      return {
        user_external_id: toolInput.user_external_id,
        lookahead_days: lookaheadDays,
        bills_count: result.rows.length,
        total_amount: result.rows.reduce((sum, bill) => sum + parseFloat(bill.amount || 0), 0),
        bills: result.rows
      };
    } else if (toolName === 'check-affordability') {
      // First get safe balance
      const balanceQuery = `SELECT * FROM calculate_safe_balance('${userUuid}', ${lookaheadDays});`;
      const balanceResult = await pool.query(balanceQuery);
      const balance = balanceResult.rows[0];
      const safeBalance = parseFloat(balance.safe_balance);
      const purchaseAmount = toolInput.purchase_amount;

      return {
        user_external_id: toolInput.user_external_id,
        purchase_amount: purchaseAmount,
        purchase_description: toolInput.purchase_description,
        safe_balance: safeBalance,
        can_afford: purchaseAmount <= safeBalance,
        remaining_balance: safeBalance - purchaseAmount,
        recommendation: purchaseAmount <= safeBalance
          ? 'Go ahead - this is within your safe balance!'
          : 'Wait until bills are paid - this exceeds your safe balance.'
      };
    } else if (toolName === 'get-financial-analysis') {
      // Get financial analysis using existing tables only
      console.log(`🔧 Executing tool: ${toolName}`);

      // Get average monthly income (last 3 months)
      const incomeQuery = await pool.query(
        `SELECT AVG(monthly_income) as avg_income FROM (
          SELECT DATE_TRUNC('month', transaction_date) as month,
                 SUM(amount) as monthly_income
          FROM transactions
          WHERE user_id = $1
            AND transaction_type = 'CREDIT'
            AND transaction_date >= NOW() - INTERVAL '3 months'
            AND category NOT IN ('Loan Disbursement', 'Refund')
          GROUP BY DATE_TRUNC('month', transaction_date)
        ) monthly_totals`,
        [userUuid]
      );

      const avgIncome = incomeQuery.rows[0]?.avg_income ? parseFloat(incomeQuery.rows[0].avg_income) : 0;

      // Get average monthly expenses (last 3 months, excluding debt payments)
      const expenseQuery = await pool.query(
        `SELECT AVG(monthly_expense) as avg_expense FROM (
          SELECT DATE_TRUNC('month', transaction_date) as month,
                 SUM(ABS(amount)) as monthly_expense
          FROM transactions
          WHERE user_id = $1
            AND transaction_type = 'DEBIT'
            AND transaction_date >= NOW() - INTERVAL '3 months'
            AND category != 'LOAN'
          GROUP BY DATE_TRUNC('month', transaction_date)
        ) monthly_totals`,
        [userUuid]
      );

      const avgExpenses = expenseQuery.rows[0]?.avg_expense ? parseFloat(expenseQuery.rows[0].avg_expense) : 0;

      // Get total debt obligations (monthly debt payments for DSR calculation)
      const debtQuery = await pool.query(
        `SELECT SUM(amount) as total_debt
         FROM recurring_liabilities
         WHERE user_id = $1
           AND is_active = true
           AND liability_type IN ('LOAN', 'BNPL')`,
        [userUuid]
      );

      const totalDebt = debtQuery.rows[0]?.total_debt ? parseFloat(debtQuery.rows[0].total_debt) : 0;

      // Calculate DSR (Debt Service Ratio)
      const dsr = avgIncome > 0 ? (totalDebt / avgIncome) * 100 : 0;

      // DSR Status based on rytguard_mvp_schema.sql thresholds
      // < 30%: HEALTHY, 30-40%: WARNING, >= 40%: CRITICAL
      return {
        user_external_id: toolInput.user_external_id,
        avg_monthly_income: avgIncome,
        avg_monthly_expenses: avgExpenses,
        total_debt_payments: totalDebt,
        current_dsr: dsr,
        dsr_status: dsr < 30 ? 'HEALTHY' : dsr < 40 ? 'WARNING' : 'CRITICAL',
        financial_health_score: dsr < 30 ? 'Good' : dsr < 40 ? 'Fair' : 'Poor'
      };
    }
    throw new Error(`Unknown tool: ${toolName}`);
  } catch (error: any) {
    console.error(`❌ Tool execution error (${toolName}):`, error.message);
    throw error;
  }
}

// Chat endpoint with Claude AI and tool calling
app.post('/api/chat', async (req: Request, res: Response) => {
  try {
    const { messages, userExternalId } = req.body;

    if (!messages || !Array.isArray(messages)) {
      return res.status(400).json({ error: 'Messages array is required' });
    }

    if (!process.env.ANTHROPIC_API_KEY || process.env.ANTHROPIC_API_KEY === 'your_api_key_here') {
      return res.status(500).json({
        error: 'Anthropic API key not configured. Please add ANTHROPIC_API_KEY to .env file.'
      });
    }

    console.log(`💬 Chat request for user: ${userExternalId}`);

    // System prompt with RytGuard personality
    const systemPrompt = `You are RytGuard, a friendly and empathetic financial AI assistant for Ryt Bank, Malaysia's smartest digital bank. Your mission is to help Malaysians avoid financial stress and prevent bankruptcy by understanding their TRUE available funds through the Safe Balance concept.

# Core Concept: Safe Balance
Safe Balance = Current Balance - Upcoming Bills (next 30 days)

The Safe Balance is MORE IMPORTANT than the raw current balance. It shows the user what they can SAFELY spend without running into trouble when bills are due.

# Your Personality
- Friendly & Empathetic: Like a caring financial advisor friend
- Malaysian Context-Aware: Understand RM currency, local services (SpayLater, PTPTN, Grab, Netflix, etc.)
- Firm but Kind: When advising against purchases, explain WHY with empathy
- Celebratory: Praise good financial behavior and healthy safe balances
- Proactive: Warn users BEFORE they overspend, not after

# Guidelines
- Always use the tools to get real data before advising
- Refer to Safe Balance, not just current balance
- Explain the "why" behind your advice
- Show empathy for the user's financial situation
- Use RM (Malaysian Ringgit) for all amounts

Current user: ${userExternalId}`;

    // Convert messages to Anthropic format
    const anthropicMessages = messages.map((msg: any) => ({
      role: msg.role === 'assistant' ? 'assistant' : 'user',
      content: msg.content
    }));

    let response = await anthropic.messages.create({
      model: 'claude-haiku-4-5-20251001',
      max_tokens: 1024,
      system: systemPrompt,
      messages: anthropicMessages,
      tools: BANKING_TOOLS
    });

    console.log(`🤖 Claude response - stop_reason: ${response.stop_reason}`);

    // Tool calling loop
    while (response.stop_reason === 'tool_use') {
      // Extract tool calls from response
      const toolUseBlocks = response.content.filter(
        (block): block is Anthropic.ToolUseBlock => block.type === 'tool_use'
      );

      console.log(`🔧 Claude wants to use ${toolUseBlocks.length} tool(s)`);

      // Execute all tool calls
      const toolResults: Anthropic.MessageParam['content'] = [];

      for (const toolUse of toolUseBlocks) {
        try {
          console.log(`📞 Calling tool: ${toolUse.name} with input:`, toolUse.input);
          const result = await executeMCPTool(toolUse.name, toolUse.input);

          toolResults.push({
            type: 'tool_result',
            tool_use_id: toolUse.id,
            content: JSON.stringify(result)
          });
        } catch (error: any) {
          toolResults.push({
            type: 'tool_result',
            tool_use_id: toolUse.id,
            content: JSON.stringify({ error: error.message }),
            is_error: true
          });
        }
      }

      // Continue conversation with tool results
      anthropicMessages.push({
        role: 'assistant',
        content: response.content
      });
      anthropicMessages.push({
        role: 'user',
        content: toolResults
      });

      response = await anthropic.messages.create({
        model: 'claude-haiku-4-5-20251001',
        max_tokens: 1024,
        system: systemPrompt,
        messages: anthropicMessages,
        tools: BANKING_TOOLS
      });

      console.log(`🤖 Claude response after tools - stop_reason: ${response.stop_reason}`);
    }

    // Extract final text response
    const textBlocks = response.content.filter(
      (block): block is Anthropic.TextBlock => block.type === 'text'
    );
    const finalResponse = textBlocks.map(block => block.text).join('\n');

    console.log(`✅ Chat completed successfully`);

    res.json({
      success: true,
      response: finalResponse,
      usage: response.usage
    });

  } catch (error: any) {
    console.error('❌ Chat error:', error.message);
    res.status(500).json({
      error: error.message,
      success: false
    });
  }
});

// Reload Money endpoint - Deposit funds
app.post('/api/reload', async (req: Request, res: Response) => {
  try {
    const { userExternalId, amount, description } = req.body;

    // Validation
    if (!userExternalId) {
      return res.status(400).json({ error: 'User ID is required', success: false });
    }
    if (!amount || amount <= 0) {
      return res.status(400).json({ error: 'Amount must be greater than 0', success: false });
    }
    if (amount > 10000) {
      return res.status(400).json({ error: 'Maximum deposit amount is RM 10,000', success: false });
    }

    console.log(`💰 Reload request - User: ${userExternalId}, Amount: RM ${amount}`);

    // Get user
    const userQuery = await pool.query(
      'SELECT user_id, current_balance FROM users WHERE external_user_id = $1',
      [userExternalId]
    );

    if (userQuery.rows.length === 0) {
      return res.status(404).json({ error: 'User not found', success: false });
    }

    const user = userQuery.rows[0];
    const currentBalance = parseFloat(user.current_balance);
    const newBalance = currentBalance + amount;

    // Create transaction record
    const transactionId = `reload_${Date.now()}_${Math.random().toString(36).substring(7)}`;
    const transactionResult = await pool.query(
      `INSERT INTO transactions
       (user_id, external_transaction_id, amount, transaction_type, description, merchant_name,
        category, balance_after, transaction_date, status)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW(), $9)
       RETURNING *`,
      [
        user.user_id,
        transactionId,
        amount,
        'CREDIT',
        description || 'Reload via Bank Transfer',
        'Bank Transfer',
        'Deposit',
        newBalance,
        'PROCESSED'
      ]
    );

    // Update user balance
    await pool.query(
      'UPDATE users SET current_balance = $1, updated_at = NOW() WHERE user_id = $2',
      [newBalance, user.user_id]
    );

    console.log(`✅ Reload successful - New balance: RM ${newBalance}`);

    res.json({
      success: true,
      transaction: {
        id: transactionResult.rows[0].external_transaction_id,
        amount: amount,
        type: 'CREDIT',
        description: description || 'Reload via Bank Transfer',
        date: transactionResult.rows[0].transaction_date,
        previousBalance: currentBalance,
        newBalance: newBalance
      }
    });

  } catch (error: any) {
    console.error('❌ Reload error:', error.message);
    res.status(500).json({
      error: error.message,
      success: false
    });
  }
});

// Withdraw Money endpoint
app.post('/api/withdraw', async (req: Request, res: Response) => {
  try {
    const { userExternalId, amount, recipientName, description } = req.body;

    // Validation
    if (!userExternalId) {
      return res.status(400).json({ error: 'User ID is required', success: false });
    }
    if (!amount || amount <= 0) {
      return res.status(400).json({ error: 'Amount must be greater than 0', success: false });
    }
    if (!recipientName || recipientName.trim() === '') {
      return res.status(400).json({ error: 'Recipient name is required', success: false });
    }

    console.log(`💸 Withdraw request - User: ${userExternalId}, Amount: RM ${amount}, To: ${recipientName}`);

    // Get user and calculate safe balance
    const userQuery = await pool.query(
      'SELECT user_id, current_balance FROM users WHERE external_user_id = $1',
      [userExternalId]
    );

    if (userQuery.rows.length === 0) {
      return res.status(404).json({ error: 'User not found', success: false });
    }

    const user = userQuery.rows[0];
    const userId = user.user_id;

    // Calculate safe balance
    const safeBalanceQuery = await pool.query(
      'SELECT * FROM calculate_safe_balance($1, 30)',
      [userId]
    );
    const safeBalanceData = safeBalanceQuery.rows[0];
    const safeBalance = parseFloat(safeBalanceData.safe_balance);
    const currentBalance = parseFloat(safeBalanceData.current_balance);

    // Check if withdrawal exceeds safe balance
    if (amount > safeBalance) {
      console.log(`❌ Withdrawal blocked - Amount (${amount}) exceeds safe balance (${safeBalance})`);
      return res.status(400).json({
        error: `Insufficient safe balance. Your safe balance is RM ${safeBalance.toFixed(2)}. This withdrawal would leave you unable to pay your upcoming bills.`,
        success: false,
        safeBalance: safeBalance,
        requestedAmount: amount
      });
    }

    const newBalance = currentBalance - amount;

    // Create transaction record
    const transactionId = `withdraw_${Date.now()}_${Math.random().toString(36).substring(7)}`;
    const transactionResult = await pool.query(
      `INSERT INTO transactions
       (user_id, external_transaction_id, amount, transaction_type, description, merchant_name,
        category, balance_after, transaction_date, status)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW(), $9)
       RETURNING *`,
      [
        userId,
        transactionId,
        -amount, // Negative for withdrawal
        'DEBIT',
        description || `Withdrawal to ${recipientName}`,
        recipientName,
        'Withdrawal',
        newBalance,
        'PROCESSED'
      ]
    );

    // Update user balance
    await pool.query(
      'UPDATE users SET current_balance = $1, updated_at = NOW() WHERE user_id = $2',
      [newBalance, userId]
    );

    console.log(`✅ Withdrawal successful - New balance: RM ${newBalance}`);

    res.json({
      success: true,
      transaction: {
        id: transactionResult.rows[0].external_transaction_id,
        amount: amount,
        type: 'DEBIT',
        recipientName: recipientName,
        description: description || `Withdrawal to ${recipientName}`,
        date: transactionResult.rows[0].transaction_date,
        previousBalance: currentBalance,
        newBalance: newBalance
      }
    });

  } catch (error: any) {
    console.error('❌ Withdrawal error:', error.message);
    res.status(500).json({
      error: error.message,
      success: false
    });
  }
});

// Get active subscriptions for a user
app.get('/api/subscriptions', async (req: Request, res: Response) => {
  try {
    const userExternalId = req.query.userExternalId as string;

    if (!userExternalId) {
      return res.status(400).json({ error: 'User ID is required', success: false });
    }

    console.log(`📋 Fetching subscriptions for user: ${userExternalId}`);

    // Get user
    const userQuery = await pool.query(
      'SELECT user_id FROM users WHERE external_user_id = $1',
      [userExternalId]
    );

    if (userQuery.rows.length === 0) {
      return res.status(404).json({ error: 'User not found', success: false });
    }

    const userId = userQuery.rows[0].user_id;

    // Get active subscriptions/liabilities
    const subscriptionsQuery = await pool.query(
      `SELECT liability_id, liability_type, liability_name, amount, recurrence_pattern,
              next_due_date, last_paid_date, is_verified, created_at
       FROM recurring_liabilities
       WHERE user_id = $1 AND is_active = true
       ORDER BY next_due_date ASC`,
      [userId]
    );

    console.log(`✅ Found ${subscriptionsQuery.rows.length} active subscriptions`);

    res.json({
      success: true,
      subscriptions: subscriptionsQuery.rows
    });

  } catch (error: any) {
    console.error('❌ Error fetching subscriptions:', error.message);
    res.status(500).json({
      error: error.message,
      success: false
    });
  }
});

// Add new subscription
app.post('/api/add-subscription', async (req: Request, res: Response) => {
  try {
    const { userExternalId, subscriptionName, amount, type, nextDueDate } = req.body;

    // Validation
    if (!userExternalId) {
      return res.status(400).json({ error: 'User ID is required', success: false });
    }
    if (!subscriptionName || subscriptionName.trim() === '') {
      return res.status(400).json({ error: 'Subscription name is required', success: false });
    }
    if (!amount || amount <= 0) {
      return res.status(400).json({ error: 'Amount must be greater than 0', success: false });
    }
    if (!type) {
      return res.status(400).json({ error: 'Subscription type is required', success: false });
    }
    if (!nextDueDate) {
      return res.status(400).json({ error: 'Next due date is required', success: false });
    }

    console.log(`➕ Adding subscription - User: ${userExternalId}, Name: ${subscriptionName}, Amount: RM ${amount}`);

    // Get user
    const userQuery = await pool.query(
      'SELECT user_id FROM users WHERE external_user_id = $1',
      [userExternalId]
    );

    if (userQuery.rows.length === 0) {
      return res.status(404).json({ error: 'User not found', success: false });
    }

    const userId = userQuery.rows[0].user_id;

    // Insert new subscription (using MONTHLY as default recurrence for example)
    const subscriptionResult = await pool.query(
      `INSERT INTO recurring_liabilities
       (user_id, liability_type, liability_name, amount, recurrence_pattern, next_due_date, is_verified, is_active)
       VALUES ($1, $2, $3, $4, 'MONTHLY', $5, true, true)
       RETURNING *`,
      [userId, type, subscriptionName, amount, nextDueDate]
    );

    const newSubscription = subscriptionResult.rows[0];

    // Create projected payment for this subscription
    await pool.query(
      `INSERT INTO projected_payments (user_id, liability_id, payment_date, amount, payment_status)
       VALUES ($1, $2, $3, $4, 'UNPAID')
       ON CONFLICT (liability_id, payment_date) DO NOTHING`,
      [userId, newSubscription.liability_id, nextDueDate, amount]
    );

    console.log(`✅ Subscription added successfully`);

    res.json({
      success: true,
      subscription: {
        id: newSubscription.liability_id,
        name: subscriptionName,
        amount: amount,
        type: type,
        nextDueDate: nextDueDate,
        message: `${subscriptionName} subscription added successfully!`
      }
    });

  } catch (error: any) {
    console.error('❌ Add subscription error:', error.message);
    res.status(500).json({
      error: error.message,
      success: false
    });
  }
});

// Cancel subscription
app.post('/api/cancel-subscription', async (req: Request, res: Response) => {
  try {
    const { userExternalId, liabilityId } = req.body;

    // Validation
    if (!userExternalId) {
      return res.status(400).json({ error: 'User ID is required', success: false });
    }
    if (!liabilityId) {
      return res.status(400).json({ error: 'Subscription ID is required', success: false });
    }

    console.log(`❌ Cancelling subscription - User: ${userExternalId}, Liability ID: ${liabilityId}`);

    // Get subscription details before cancelling
    const subscriptionQuery = await pool.query(
      `SELECT rl.liability_name, rl.amount, rl.liability_type
       FROM recurring_liabilities rl
       JOIN users u ON rl.user_id = u.user_id
       WHERE u.external_user_id = $1 AND rl.liability_id = $2 AND rl.is_active = true`,
      [userExternalId, liabilityId]
    );

    if (subscriptionQuery.rows.length === 0) {
      return res.status(404).json({ error: 'Subscription not found or already cancelled', success: false });
    }

    const subscription = subscriptionQuery.rows[0];

    // Mark subscription as inactive (cancelled)
    await pool.query(
      'UPDATE recurring_liabilities SET is_active = false, updated_at = NOW() WHERE liability_id = $1',
      [liabilityId]
    );

    // Mark all future projected payments as skipped
    await pool.query(
      `UPDATE projected_payments
       SET payment_status = 'SKIPPED'
       WHERE liability_id = $1 AND payment_status = 'UNPAID' AND payment_date >= CURRENT_DATE`,
      [liabilityId]
    );

    console.log(`✅ Subscription cancelled successfully`);

    res.json({
      success: true,
      subscription: {
        id: liabilityId,
        name: subscription.liability_name,
        amount: subscription.amount,
        type: subscription.liability_type,
        message: `${subscription.liability_name} subscription cancelled successfully!`
      }
    });

  } catch (error: any) {
    console.error('❌ Cancel subscription error:', error.message);
    res.status(500).json({
      error: error.message,
      success: false
    });
  }
});

// ============================================
// PHASE 2: PREDICTIVE FINANCIAL MODELING (Simplified - No Schema Changes)
// Uses existing tables only: users, transactions, recurring_liabilities
// ============================================

// Get historical financial data for projection (uses existing tables only)
app.get('/api/v2/financial/history', async (req: Request, res: Response) => {
  try {
    const userExternalId = req.query.userExternalId as string;
    const months = parseInt(req.query.months as string) || 3;

    if (!userExternalId) {
      return res.status(400).json({ error: 'User ID is required', success: false });
    }

    console.log(`📊 Fetching financial history for user: ${userExternalId}`);

    // Get user
    const userQuery = await pool.query(
      'SELECT user_id, current_balance FROM users WHERE external_user_id = $1',
      [userExternalId]
    );

    if (userQuery.rows.length === 0) {
      return res.status(404).json({ error: 'User not found', success: false });
    }

    const user = userQuery.rows[0];

    // Get average monthly income (last N months)
    const incomeQuery = await pool.query(
      `SELECT
        DATE_TRUNC('month', transaction_date) as month,
        SUM(amount) as total_income
      FROM transactions
      WHERE user_id = $1
        AND transaction_type = 'CREDIT'
        AND transaction_date >= NOW() - INTERVAL '${months} months'
        AND category NOT IN ('Loan Disbursement', 'Refund')
      GROUP BY DATE_TRUNC('month', transaction_date)
      ORDER BY month DESC`,
      [user.user_id]
    );

    const avgIncome = incomeQuery.rows.length > 0
      ? incomeQuery.rows.reduce((sum, row) => sum + parseFloat(row.total_income), 0) / incomeQuery.rows.length
      : 0;

    // Get average monthly expenses (last N months, excluding debt payments)
    const expenseQuery = await pool.query(
      `SELECT
        DATE_TRUNC('month', transaction_date) as month,
        SUM(ABS(amount)) as total_expense
      FROM transactions
      WHERE user_id = $1
        AND transaction_type = 'DEBIT'
        AND transaction_date >= NOW() - INTERVAL '${months} months'
        AND category != 'LOAN'
      GROUP BY DATE_TRUNC('month', transaction_date)
      ORDER BY month DESC`,
      [user.user_id]
    );

    const avgExpenses = expenseQuery.rows.length > 0
      ? expenseQuery.rows.reduce((sum, row) => sum + parseFloat(row.total_expense), 0) / expenseQuery.rows.length
      : 0;

    // Get active recurring liabilities (debt obligations)
    const liabilitiesQuery = await pool.query(
      `SELECT liability_id, liability_type, liability_name, amount, recurrence_pattern, next_due_date
       FROM recurring_liabilities
       WHERE user_id = $1 AND is_active = true
       ORDER BY next_due_date ASC`,
      [user.user_id]
    );

    // Calculate total monthly debt obligations (DSR calculation)
    const totalDebtPayments = liabilitiesQuery.rows
      .filter(l => ['LOAN', 'BNPL'].includes(l.liability_type))
      .reduce((sum, l) => sum + parseFloat(l.amount), 0);

    // Calculate DSR (Debt Service Ratio)
    const currentDsr = avgIncome > 0 ? (totalDebtPayments / avgIncome) * 100 : 0;

    // Determine DSR status based on rytguard_mvp_schema.sql thresholds
    // < 30%: HEALTHY, 30-40%: WARNING, >= 40%: CRITICAL
    let dsrStatus = 'HEALTHY';
    if (currentDsr >= 40) {
      dsrStatus = 'CRITICAL';
    } else if (currentDsr >= 30) {
      dsrStatus = 'WARNING';
    }

    res.json({
      success: true,
      data: {
        user_external_id: userExternalId,
        current_balance: parseFloat(user.current_balance),
        avg_monthly_income: avgIncome,
        avg_monthly_expenses: avgExpenses,
        total_debt_payments: totalDebtPayments,
        current_dsr: currentDsr,
        dsr_status: dsrStatus,
        calculated_at: new Date().toISOString()
      }
    });

  } catch (error: any) {
    console.error('❌ Financial history error:', error.message);
    res.status(500).json({
      error: error.message,
      success: false
    });
  }
});

// S3 Dashboard URL
const DASHBOARD_URL = process.env.DASHBOARD_URL || 'https://s3-dashboard-build.s3.us-west-2.amazonaws.com/out/index.html';

// Cache for the dashboard HTML (optional optimization)
let cachedDashboard: string | null = null;
let cacheTimestamp: number = 0;
const CACHE_DURATION = 5 * 60 * 1000; // 5 minutes

// Helper function to fetch dashboard from S3
async function fetchDashboard(): Promise<string> {
  const now = Date.now();
  
  // Return cached version if still valid
  if (cachedDashboard && (now - cacheTimestamp) < CACHE_DURATION) {
    return cachedDashboard;
  }
  
  try {
    const response = await fetch(DASHBOARD_URL);
    if (!response.ok) {
      throw new Error(`Failed to fetch dashboard: ${response.status}`);
    }
    
    const html = await response.text();
    
    // Update cache
    cachedDashboard = html;
    cacheTimestamp = now;
    
    return html;
  } catch (error) {
    console.error('❌ Error fetching dashboard from S3:', error);
    throw error;
  }
}

// Root endpoint - Dynamic MCP Dashboard from S3
app.get('/', async (req: Request, res: Response) => {
  try {
    const html = await fetchDashboard();
    res.setHeader('Content-Type', 'text/html');
    res.send(html);
  } catch (error) {
    res.status(500).send('<h1>Dashboard temporarily unavailable</h1><p>Please try again later.</p>');
  }
});

app.get('/mcp', async (req: Request, res: Response) => {
  try {
    const html = await fetchDashboard();
    res.setHeader('Content-Type', 'text/html');
    res.send(html);
  } catch (error) {
    res.status(500).send('<h1>Dashboard temporarily unavailable</h1><p>Please try again later.</p>');
  }
});

// Start the server
app.listen(PORT, () => {
      console.log(`🐘 PostgreSQL MCP Server running on port ${PORT}`);
});
