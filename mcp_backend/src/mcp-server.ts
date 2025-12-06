import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { setupMinimalResource } from "./minimal/resource.js";
import { setupMinimalTool } from "./minimal/tool.js";
import { setupMinimalPrompt } from "./minimal/prompt.js";
import { setupBankingTools } from "./tools/banking-tools.js";
import { setupPromotionTools } from "./tools/promotions-tools.js";
import { setupFinancialAdvisorPrompt } from "./prompts/financial-advisor-prompt.js";
import { setupPromotionAdvisorPrompt } from "./prompts/promotion-advisor-prompt.js";

/**
 * Creates and configures the PostgreSQL MCP server instance
 */
export function createMCPServer(): McpServer {
  const serverName = "postgresql-mcp";
  const serverVersion = "1.0.0";

  console.log(`🔧 Creating PostgreSQL MCP server: ${serverName} v${serverVersion}`);

  // Create the MCP server instance
  const server = new McpServer({
    name: serverName,
    version: serverVersion
  });

  console.log("📦 Registering PostgreSQL MCP capabilities...");

  // Register resources (server-info and database-schema)
  setupMinimalResource(server);
  console.log("✅ Resources registered: server-info, database-schema");

  // Register the PostgreSQL query tool
  setupMinimalTool(server);
  console.log("✅ Tool registered: postgres-query");

  // Register the query generation prompt
  setupMinimalPrompt(server);
  console.log("✅ Prompt registered: query-generator");

  // Register RytGuard banking tools
  setupBankingTools(server);
  console.log("✅ Banking tools registered: get-safe-balance, get-upcoming-bills, check-affordability, get-spending-summary, save-conversation");

  // Register RytGuard promotion tools
  setupPromotionTools(server);
  console.log("✅ Promotion tools registered: rank-promotions");

  // Register RytGuard financial advisor prompt
  setupFinancialAdvisorPrompt(server);
  console.log("✅ Prompt registered: financial-advisor");

  // Register RytGuard promotion advisor prompt
  setupPromotionAdvisorPrompt(server);
  console.log("✅ Prompt registered: promotion-advisor");

  console.log("🎉 PostgreSQL MCP server configuration completed");

  return server;
}
