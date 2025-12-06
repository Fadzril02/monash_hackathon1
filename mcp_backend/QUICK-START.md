# Quick Start Guide - PostgreSQL MCP Server

## Step 1: Configure Database Connection

Create a `.env` file in the `mcp_check` directory:

```bash
cd mcp_check
```

Create `.env` file with your database credentials:

```env
DB_HOST=127.0.0.1
DB_PORT=5433
DB_NAME=ryt_guard
DB_USER=postgres
DB_PASSWORD=YOUR_ACTUAL_PASSWORD_HERE
```

**⚠️ IMPORTANT:** Replace `YOUR_ACTUAL_PASSWORD_HERE` with your actual PostgreSQL password!

## Step 2: Test Database Connection

Before starting the server, verify the connection works:

```bash
npm run test:connection
```

This will:
- ✅ Test database connectivity
- ✅ Verify `transactions` table exists
- ✅ Show table schema
- ✅ Run a sample query

**If this fails**, check:
- Database is running
- Credentials are correct
- Database `ryt_guard` exists
- Table `transactions` exists

## Step 3: Start the MCP Server

**Development mode (recommended for testing):**
```bash
npm run dev
```

The server will start on `http://localhost:3001`

You should see:
```
🐘 PostgreSQL MCP Server running on port 3001
```

## Step 4: Test the Server

**Health Check:**
```bash
curl http://localhost:3001/health
```

Or open in browser: http://localhost:3001/health

**Expected response:**
```json
{
  "status": "ok",
  "server": "postgresql-mcp",
  "version": "1.0.0",
  "database": {
    "configured": true
  }
}
```

## Step 5: Test MCP Query Tool

You can test the MCP endpoint using curl or an MCP client:

```bash
curl -X POST http://localhost:3001/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/call",
    "params": {
      "name": "postgres-query",
      "arguments": {
        "query": "SELECT COUNT(*) as total FROM transactions",
        "limit": 10
      }
    }
  }'
```

## Next Steps

1. **Local Testing**: Test queries locally first
2. **Deploy to LeanMCP**: 
   - Go to https://ship.leanmcp.com
   - Connect your repository or upload code
   - Click "Test and Deploy"
   - Get your deployment URL

## Troubleshooting

**"Connection refused" or "password authentication failed"**
- Check `.env` file exists and has correct credentials
- Verify database is running: `docker ps`
- Test connection: `npm run test:connection`

**"Table transactions does not exist"**
- Verify table name is exactly `transactions` (case-sensitive)
- Check database name is `ryt_guard`
- Run: `npm run test:connection` to see available tables

**Port 3001 already in use**
- Change PORT in `.env` file
- Or stop other services using port 3001

