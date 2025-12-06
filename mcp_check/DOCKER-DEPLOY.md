# Docker Deployment Guide for RytGuard MCP Server

## Quick Start

### Option 1: Using Docker Compose (Recommended)

1. **Make sure your `.env` file is in the root folder** (already done ✅)

2. **Build and run:**
   ```bash
   cd mcp_check
   docker-compose up --build
   ```

3. **Run in background:**
   ```bash
   docker-compose up -d --build
   ```

4. **View logs:**
   ```bash
   docker-compose logs -f
   ```

5. **Stop:**
   ```bash
   docker-compose down
   ```

### Option 2: Using Docker directly

1. **Build the image:**
   ```bash
   cd mcp_check
   docker build -t rytguard-mcp:latest .
   ```

2. **Run the container:**
   ```bash
   docker run -d \
     --name rytguard-mcp-server \
     -p 3001:3001 \
     -e DB_HOST=host.docker.internal \
     -e DB_PORT=5433 \
     -e DB_NAME=ryt_guard \
     -e DB_USER=postgres \
     -e DB_PASSWORD=your_password \
     rytguard-mcp:latest
   ```

## Important: Database Connection from Docker

Since your PostgreSQL database is running on your host machine (not in Docker), you need to use `host.docker.internal` to connect from inside the container.

### Update your connection:

**Option A: Use environment variables in docker-compose.yml**
```yaml
environment:
  - DB_HOST=host.docker.internal  # This allows Docker to access host machine
  - DB_PORT=5433
  - DB_NAME=ryt_guard
  - DB_USER=postgres
  - DB_PASSWORD=your_password
```

**Option B: Create a `.env` file in mcp_check folder for Docker**
```env
DB_HOST=host.docker.internal
DB_PORT=5433
DB_NAME=ryt_guard
DB_USER=postgres
DB_PASSWORD=your_password
```

Then docker-compose will automatically load it.

## Testing the Docker Deployment

1. **Check if container is running:**
   ```bash
   docker ps
   ```

2. **Check health endpoint:**
   ```bash
   curl http://localhost:3001/health
   ```
   Or open: http://localhost:3001/health

3. **View container logs:**
   ```bash
   docker logs rytguard-mcp-server
   ```

4. **Test MCP query (from host):**
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

## Troubleshooting

### Container can't connect to database

**Problem:** `ECONNREFUSED` or connection timeout

**Solution:** 
- Use `host.docker.internal` instead of `127.0.0.1` for DB_HOST
- On Linux, you may need to add `--add-host=host.docker.internal:host-gateway` to docker run
- Or use your host machine's IP address instead

### Port already in use

**Problem:** `port 3001 is already allocated`

**Solution:**
- Stop the local dev server: `Ctrl+C` in the terminal running `npm run dev`
- Or change the port in docker-compose.yml: `"3002:3001"` (host:container)

### Build fails

**Problem:** TypeScript compilation errors

**Solution:**
- Make sure all dependencies are installed: `npm install` in mcp_check
- Check TypeScript errors: `npm run build`
- Fix any type errors before building Docker image

### Container exits immediately

**Problem:** Container starts then stops

**Solution:**
- Check logs: `docker logs rytguard-mcp-server`
- Verify environment variables are set correctly
- Check database connection is accessible from container

## Docker Commands Cheat Sheet

```bash
# Build and start
docker-compose up --build

# Start in background
docker-compose up -d

# View logs
docker-compose logs -f

# Stop
docker-compose down

# Rebuild without cache
docker-compose build --no-cache

# Execute command in running container
docker exec -it rytguard-mcp-server sh

# Remove everything (including volumes)
docker-compose down -v
```

## Production Considerations

For production deployment:

1. **Use secrets management** instead of environment variables in docker-compose.yml
2. **Add proper logging** and monitoring
3. **Set up reverse proxy** (nginx/traefik) if needed
4. **Configure resource limits** in docker-compose.yml
5. **Use health checks** (already included ✅)









