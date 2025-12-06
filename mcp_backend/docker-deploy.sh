#!/bin/bash
# Bash script to deploy MCP server to Docker
# Run this from the mcp_check directory

echo "🐳 Deploying RytGuard MCP Server to Docker..."
echo ""

# Check if Docker is running
echo "1️⃣ Checking Docker..."
if docker ps > /dev/null 2>&1; then
    echo "   ✅ Docker is running"
else
    echo "   ❌ Docker is not running. Please start Docker."
    exit 1
fi

# Check if .env exists in root
echo ""
echo "2️⃣ Checking for .env file..."
if [ -f "../.env" ]; then
    echo "   ✅ Found .env in root folder"
else
    echo "   ⚠️  No .env file found. Make sure it exists in the root folder."
fi

# Stop existing container if running
echo ""
echo "3️⃣ Stopping existing containers..."
docker-compose down 2>/dev/null
echo "   ✅ Cleaned up"

# Build and start
echo ""
echo "4️⃣ Building Docker image..."
docker-compose build

if [ $? -ne 0 ]; then
    echo "   ❌ Build failed!"
    exit 1
fi

echo "   ✅ Build successful"

echo ""
echo "5️⃣ Starting MCP server..."
docker-compose up -d

if [ $? -ne 0 ]; then
    echo "   ❌ Failed to start container!"
    exit 1
fi

echo "   ✅ Container started"

# Wait a bit for server to start
echo ""
echo "6️⃣ Waiting for server to initialize..."
sleep 5

# Check health
echo ""
echo "7️⃣ Checking server health..."
if curl -f http://localhost:3001/health > /dev/null 2>&1; then
    echo "   ✅ Server is healthy!"
    echo ""
    echo "🎉 Deployment successful!"
    echo ""
    echo "Server is running at:"
    echo "   http://localhost:3001"
    echo "   http://localhost:3001/health"
    echo ""
    echo "View logs: docker-compose logs -f"
    echo "Stop server: docker-compose down"
else
    echo "   ⚠️  Health check failed. Server may still be starting..."
    echo "   Check logs: docker-compose logs"
fi

echo ""
echo "View logs: docker-compose logs -f"









