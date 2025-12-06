import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";

/**
 * Sets up the PostgreSQL query generation prompt
 *
 * NOTE: Arguments removed to avoid Zod v3/v4 compatibility issues with MCP SDK
 * Query details should be provided in the conversation context
 */
export function setupMinimalPrompt(server: McpServer): void {
  server.registerPrompt(
    "query-generator",
    {
      title: "PostgreSQL Query Generator",
      description: "Generate SQL queries for the PostgreSQL database based on natural language descriptions. Describe what data you want in the conversation."
      // No arguments - query requirements provided in conversation
    },
    () => {
      const systemContext = `You are a PostgreSQL query expert. Generate read-only SELECT queries only. Consider:

Database Context:
- Database: ${process.env.DB_NAME || 'ryt_guard'}
- Connection: PostgreSQL on ${process.env.DB_HOST || '127.0.0.1'}:${process.env.DB_PORT || '5433'}
- Access: Read-only (SELECT queries only)

Guidelines:
- Use only SELECT and WITH statements
- Include proper table aliases
- Use appropriate WHERE clauses for filtering
- Consider LIMIT clauses for large datasets
- Use proper JOIN syntax when needed
- Include helpful comments for complex queries

Available resources:
- Use the database-schema resource to understand table structure
- Tables and columns should be referenced correctly
- Consider data types when filtering

When user asks for a query, generate a SQL query based on their natural language description.
Support different complexity levels:
- Simple queries: Basic SELECT with minimal JOINs
- Detailed queries: Comprehensive with proper JOINs and WHERE clauses
- Optimized queries: Performance-focused with indexing hints`;

      return {
        messages: [{
          role: "user" as const,
          content: {
            type: "text" as const,
            text: systemContext
          }
        }]
      };
    }
  );
}
