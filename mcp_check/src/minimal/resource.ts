import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { Pool } from "pg";

/**
 * Sets up PostgreSQL resources
 */
export function setupMinimalResource(server: McpServer): void {
  // Server info resource
  server.registerResource(
    "server-info",
    "info://server",
    {
      title: "Server Information",
      description: "Information about this PostgreSQL MCP server",
      mimeType: "application/json"
    },
    async (uri: URL) => {
      const serverInfo = {
        name: "postgresql-mcp",
        version: "1.0.0",
        description: "Read-only PostgreSQL query MCP server with Streamable HTTP transport",
        timestamp: new Date().toISOString(),
        features: ["resources", "tools", "prompts"],
        uri: uri.href,
        capabilities: {
          resources: 2,
          tools: 1,
          prompts: 1
        },
        transport: "Streamable HTTP",
        status: "active",
        environment: {
          node_version: process.version,
          platform: process.platform,
          uptime: process.uptime(),
          memory_usage: process.memoryUsage(),
          timezone: Intl.DateTimeFormat().resolvedOptions().timeZone
        },
        database: {
          type: "PostgreSQL",
          access: "read-only",
          host: process.env.DB_HOST || '127.0.0.1',
          connection: process.env.DATABASE_URL ? "configured" : "not configured"
        }
      };

      return {
        contents: [{
          uri: uri.href,
          text: JSON.stringify(serverInfo, null, 2),
          mimeType: "application/json"
        }]
      };
    }
  );

  // Database schema resource
  server.registerResource(
    "database-schema",
    "postgres://schema",
    {
      title: "Database Schema",
      description: "Information about the PostgreSQL database schema, tables, and columns",
      mimeType: "application/json"
    },
    async (uri: URL) => {
      // Build connection string - hostname is configurable via DB_HOST environment variable
      const connectionString = process.env.DATABASE_URL || 
        `postgresql://${process.env.DB_USER || 'postgres'}:${process.env.DB_PASSWORD || '420690'}@${process.env.DB_HOST || '127.0.0.1'}:${process.env.DB_PORT || '5433'}/${process.env.DB_NAME || 'ryt_guard'}`;
      
      const pool = new Pool({ connectionString });
      
      try {
        // Get tables and their columns
        const tablesQuery = `
          SELECT 
            t.table_name,
            t.table_type,
            c.column_name,
            c.data_type,
            c.is_nullable,
            c.column_default,
            c.ordinal_position
          FROM information_schema.tables t
          LEFT JOIN information_schema.columns c ON t.table_name = c.table_name
          WHERE t.table_schema = 'public'
          ORDER BY t.table_name, c.ordinal_position;
        `;
        
        const result = await pool.query(tablesQuery);
        
        // Group columns by table
        const schema: Record<string, any> = {};
        result.rows.forEach(row => {
          if (!schema[row.table_name]) {
            schema[row.table_name] = {
              table_name: row.table_name,
              table_type: row.table_type,
              columns: []
            };
          }
          if (row.column_name) {
            schema[row.table_name].columns.push({
              column_name: row.column_name,
              data_type: row.data_type,
              is_nullable: row.is_nullable,
              column_default: row.column_default,
              ordinal_position: row.ordinal_position
            });
          }
        });

        return {
          contents: [{
            uri: uri.href,
            text: JSON.stringify({
              database: process.env.DB_NAME || 'ryt_guard',
              schema: 'public',
              tables: Object.values(schema),
              generated_at: new Date().toISOString()
            }, null, 2),
            mimeType: "application/json"
          }]
        };
      } catch (error) {
        return {
          contents: [{
            uri: uri.href,
            text: JSON.stringify({
              error: "Failed to retrieve schema",
              message: error instanceof Error ? error.message : "Unknown error",
              timestamp: new Date().toISOString()
            }, null, 2),
            mimeType: "application/json"
          }]
        };
      } finally {
        await pool.end();
      }
    }
  );
}
