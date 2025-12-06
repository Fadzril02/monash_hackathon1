import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { Pool } from "pg";
import { z } from "zod";

/**
 * Sets up the PostgreSQL query tool
 */
export function setupMinimalTool(server: McpServer): void {
  const inputSchema = z.object({
    query: z.string().describe("The SQL query to execute (SELECT statements only)"),
    limit: z.number().optional().default(100).describe("Maximum number of rows to return (default: 100, max: 1000)")
  });

  server.registerTool(
    "postgres-query",
    {
      title: "PostgreSQL Query",
      description: "Execute read-only SQL queries against the PostgreSQL database",
      inputSchema: inputSchema
    },
    // @ts-ignore - Type inference issue with MCP SDK
    async (args: { query: string; limit?: number }) => {
      const query = args.query;
      const limit = args.limit ?? 100;
      // Validate that it's a read-only query
      const trimmedQuery = query.trim().toLowerCase();
      if (!trimmedQuery.startsWith('select') && !trimmedQuery.startsWith('with')) {
        return {
          content: [{
            type: "text",
            text: JSON.stringify({
              error: "Only SELECT and WITH queries are allowed",
              query: query,
              timestamp: new Date().toISOString()
            }, null, 2)
          }]
        };
      }

      // Validate limit
      const actualLimit = Math.min(Math.max(1, limit), 1000);

      // Build connection string - hostname is configurable via DB_HOST environment variable
      const connectionString = process.env.DATABASE_URL || 
        `postgresql://${process.env.DB_USER || 'postgres'}:${process.env.DB_PASSWORD || '420690'}@${process.env.DB_HOST || '127.0.0.1'}:${process.env.DB_PORT || '5433'}/${process.env.DB_NAME || 'ryt_guard'}`;
      
      const pool = new Pool({ connectionString });
      
      try {
        const startTime = Date.now();
        const result = await pool.query(`${query} LIMIT $1`, [actualLimit]);
        const endTime = Date.now();
        
        const response = {
          query: {
            sql: query,
            limit: actualLimit,
            execution_time_ms: endTime - startTime
          },
          result: {
            rows: result.rows,
            row_count: result.rowCount || 0,
            fields: result.fields.map(field => ({
              name: field.name,
              data_type_id: field.dataTypeID,
              table_id: field.tableID,
              column_id: field.columnID
            }))
          },
          metadata: {
            tool: "postgres-query",
            server: "postgresql-mcp",
            timestamp: new Date().toISOString(),
            truncated: (result.rowCount || 0) >= actualLimit
          }
        };

        return {
          content: [{
            type: "text",
            text: JSON.stringify(response, null, 2)
          }]
        };
      } catch (error) {
        return {
          content: [{
            type: "text",
            text: JSON.stringify({
              error: "Query execution failed",
              message: error instanceof Error ? error.message : "Unknown error",
              query: query,
              timestamp: new Date().toISOString()
            }, null, 2)
          }]
        };
      } finally {
        await pool.end();
      }
    }
  );
}
