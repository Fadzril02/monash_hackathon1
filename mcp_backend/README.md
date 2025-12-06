# Minimal MCP Server

This is the minimal MCP (Model Context Protocol) server implementation with Streamable HTTP transport.

# Deployment

You can deploy this server on Leanmcp.com.
If you are generating the code, on the the platform just go ahead and click test and deploy button and this should deploy the MCP server on leanmcp.com.

The endpoint will look like this:
`https://3001-...deployment id...-6532622b.e2b.dev/`
or 
`https://3001-...deployment id...-6532622b.serverlessmcps.link/`


## Features

- **Resources**: 
  - `server-info` - Provides JSON information about the server
  - `database-schema` - PostgreSQL database schema information
- **Tool**: `postgres-query` - Execute read-only SQL queries against PostgreSQL
- **Prompt**: `query-generator` - Generate SQL queries from natural language
- **Streamable HTTP Transport**: Modern MCP transport protocol
- **TypeScript**: Full type safety with ES modules
- **Read-Only**: Only SELECT and WITH queries allowed for safety

## Quick Start

```bash
# Install dependencies
npm install

# Configure database connection (see README-SETUP.md for details)
# Create .env file with your database credentials

# Test database connection first
npm run test:connection

# Start development server
npm run dev

# Or build and run production
npm run build
npm start
```

## Deployment

**To build and deploy this MCP server, click the "Test and Deploy" button in the UI.**

This button will:
1. Build your MCP server with all dependencies
2. Deploy it to a live endpoint

## API Endpoints

Once you've clicked "Test and Deploy" and your server is deployed, the following API endpoints will be available:

**An example server would look like this with the e2b.dev endpoint:**
`https://3001-i2ioj8ir4wgd6eh867twi-6532622b.e2b.dev/`

**Available endpoints:**
- **MCP Endpoint**: `POST /mcp`
- **Health Check**: `GET /health`
- **Server Info**: `GET /`
- **AI Playground**: `GET /ai`
- **MCP Playground**: `GET /mcp`

**Example full URLs:**
- MCP Endpoint: `https://3001-i2ioj8ir4wgd6eh867twi-6532622b.e2b.dev/mcp`
- Health Check: `https://3001-i2ioj8ir4wgd6eh867twi-6532622b.e2b.dev/health`
- AI Playground: `https://3001-i2ioj8ir4wgd6eh867twi-6532622b.e2b.dev/ai`


## Environment Variables

Copy `.env.example` to `.env` and configure your PostgreSQL connection:

```env
DB_HOST=127.0.0.1
DB_PORT=5433
DB_NAME=ryt_guard
DB_USER=postgres
DB_PASSWORD=your_password

# OR use connection string:
# DATABASE_URL=postgresql://user:password@host:port/database
```

See `README-SETUP.md` for detailed setup instructions.


## MCP Capabilities

### Resources

**server-info** (`info://server`)
- Returns server information, metadata, and database connection status

**database-schema** (`postgres://schema`)
- Returns complete database schema including all tables and columns

### Tools

**postgres-query**
- **Input**: `{ query: string, limit?: number }`
- **Description**: Execute read-only SQL queries (SELECT and WITH only)
- **Example**: 
  ```json
  {
    "query": "SELECT * FROM transactions LIMIT 10",
    "limit": 100
  }
  ```

### Prompts

**query-generator**
- **Arguments**: `{ description: string, tables?: string, style?: "simple" | "detailed" | "optimized" }`
- **Description**: Generate SQL queries from natural language descriptions
- **Example**: 
  ```json
  {
    "description": "Get all transactions from the last 30 days",
    "tables": "transactions",
    "style": "simple"
  }
  ```

## Usage with MCP Clients

Connect your MCP client to your deployed MCP endpoint using the Streamable HTTP transport.

**Example MCP client connection:**
```
https://3001-i2ioj8ir4wgd6eh867twi-6532622b.e2b.dev/mcp
```

Replace the example URL with your actual deployed server URL provided after clicking "Test and Deploy".

## Architecture

```
src/
├── server.ts          # Express server with Streamable HTTP transport
├── mcp-server.ts      # MCP server configuration
└── minimal/
    ├── resource.ts    # Single resource implementation
    ├── tool.ts        # Single tool implementation
    └── prompt.ts      # Single prompt implementation