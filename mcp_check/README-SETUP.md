# PostgreSQL MCP Server Setup for RytGuard

This MCP server provides read-only access to the `ryt_guard` PostgreSQL database, specifically for querying the `transactions` table.

## Quick Setup

### 1. Configure Database Connection

Create a `.env` file in the `mcp_check` directory:

```bash
# Copy the example file
cp .env.example .env
```

Then edit `.env` with your database credentials:

```env
DB_HOST=127.0.0.1
DB_PORT=5433
DB_NAME=ryt_guard
DB_USER=postgres
DB_PASSWORD=your_actual_password
```

**OR** use a connection string:

```env
DATABASE_URL=postgresql://postgres:password@127.0.0.1:5433/ryt_guard
```

### 2. Test Database Connection

Before starting the MCP server, test the connection:

```bash
cd mcp_check
node test-connection.js
```

This will:
- ✅ Verify database connection
- ✅ Check if `transactions` table exists
- ✅ Show table schema
- ✅ Test a sample query

### 3. Start the MCP Server

**Development mode (with auto-reload):**
```bash
npm run dev
```

**Production mode:**
```bash
npm run build
npm start
```

The server will start on `http://localhost:3001`

### 4. Test the MCP Server

**Health Check:**
```bash
curl http://localhost:3001/health
```

**MCP Endpoint:**
- POST `http://localhost:3001/mcp`
- POST `http://localhost:3001/`

## MCP Capabilities

### Tools

1. **postgres-query**
   - Execute read-only SELECT queries
   - Input: `{ query: string, limit?: number }`
   - Example: `SELECT * FROM transactions LIMIT 10`

### Resources

1. **server-info** (`info://server`)
   - Server metadata and status

2. **database-schema** (`postgres://schema`)
   - Database schema information including tables and columns

### Prompts

1. **query-generator**
   - Generate SQL queries from natural language
   - Input: `{ description: string, tables?: string, style?: "simple" | "detailed" | "optimized" }`

## Deployment to LeanMCP

1. Go to https://ship.leanmcp.com
2. Connect your GitHub repository (or upload the code)
3. Click "Test and Deploy"
4. Your MCP server will be deployed and you'll get a URL like:
   - `https://3001-...deployment-id...-6532622b.e2b.dev/`

## Example Queries

Once connected, you can query the transactions table:

```sql
-- Get all transactions
SELECT * FROM transactions;

-- Count transactions
SELECT COUNT(*) FROM transactions;

-- Get recent transactions
SELECT * FROM transactions ORDER BY created_at DESC LIMIT 10;
```

## Troubleshooting

**Connection fails:**
- Check database is running: `docker ps`
- Verify credentials in `.env`
- Test connection: `node test-connection.js`

**Table not found:**
- Ensure database `ryt_guard` exists
- Ensure table `transactions` exists
- Check table name spelling (case-sensitive)

