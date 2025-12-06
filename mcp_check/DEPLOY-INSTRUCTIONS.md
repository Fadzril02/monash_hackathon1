# 🐳 Docker Deployment Instructions

## Prerequisites

1. **Docker Desktop must be running**
   - Make sure Docker Desktop is started on Windows
   - Wait for it to fully start (whale icon in system tray)

2. **Your `.env` file is in the root folder** ✅ (already done)

## Quick Deploy (PowerShell)

Run from the `mcp_check` directory:

```powershell
# Option 1: Use the helper script
.\docker-deploy.ps1

# Option 2: Manual commands
docker-compose up --build -d
```

## Step-by-Step Manual Deployment

### 1. Start Docker Desktop
- Open Docker Desktop application
- Wait until it shows "Docker Desktop is running"

### 2. Navigate to mcp_check directory
```powershell
cd mcp_check
```

### 3. Build and start the container
```powershell
docker-compose up --build -d
```

This will:
- Build the Docker image
- Start the container in background
- Map port 3001 to your host

### 4. Check if it's running
```powershell
docker ps
```

You should see `rytguard-mcp-server` in the list.

### 5. Test the server
```powershell
# Health check
curl http://localhost:3001/health

# Or open in browser
# http://localhost:3001/health
```

## Important: Database Connection

The docker-compose.yml is configured to:
- ✅ Load `.env` from root folder
- ✅ Use `host.docker.internal` to connect to your host PostgreSQL
- ✅ Automatically set up host gateway access

**If connection fails**, check:
1. PostgreSQL is running on your host
2. Port 5433 is accessible
3. Check container logs: `docker logs rytguard-mcp-server`

## Useful Commands

```powershell
# View logs
docker-compose logs -f

# Stop server
docker-compose down

# Restart server
docker-compose restart

# Rebuild (after code changes)
docker-compose up --build -d

# Check container status
docker ps

# Execute command in container
docker exec -it rytguard-mcp-server sh

# View container logs
docker logs rytguard-mcp-server
```

## Testing the MCP Server

Once deployed, test with:

```powershell
# Health check
Invoke-WebRequest -Uri http://localhost:3001/health

# Test MCP query (using curl or Postman)
curl -X POST http://localhost:3001/mcp `
  -H "Content-Type: application/json" `
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

## Troubleshooting

### Docker Desktop not running
**Error:** `open //./pipe/dockerDesktopLinuxEngine: The system cannot find the file specified`

**Solution:** Start Docker Desktop and wait for it to fully initialize.

### Port already in use
**Error:** `port 3001 is already allocated`

**Solution:** 
- Stop local dev server: `Ctrl+C` in terminal running `npm run dev`
- Or change port in docker-compose.yml: `"3002:3001"`

### Container can't connect to database
**Error:** Connection timeout or refused

**Solution:**
- Verify PostgreSQL is running: Check Docker containers or Windows services
- Check DB_HOST in .env is correct
- View logs: `docker logs rytguard-mcp-server`
- Test connection from container: `docker exec -it rytguard-mcp-server node test-connection.js`

### Build fails
**Error:** TypeScript compilation errors

**Solution:**
- Fix TypeScript errors first: `npm run build` locally
- Check all dependencies are in package.json
- Rebuild: `docker-compose build --no-cache`

## Next Steps

After successful deployment:
1. ✅ Test health endpoint
2. ✅ Test MCP queries
3. ✅ Deploy to LeanMCP platform (optional)
4. ✅ Integrate with your MCP client









