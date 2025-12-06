# PowerShell script to deploy MCP server to Docker
# Run this from the mcp_check directory

Write-Host "🐳 Deploying RytGuard MCP Server to Docker..." -ForegroundColor Cyan
Write-Host ""

# Check if Docker is running
Write-Host "1️⃣ Checking Docker..." -ForegroundColor Yellow
try {
    docker ps | Out-Null
    Write-Host "   ✅ Docker is running" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Docker is not running. Please start Docker Desktop." -ForegroundColor Red
    exit 1
}

# Check if .env exists in root
Write-Host ""
Write-Host "2️⃣ Checking for .env file..." -ForegroundColor Yellow
if (Test-Path "../.env") {
    Write-Host "   ✅ Found .env in root folder" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  No .env file found. Make sure it exists in the root folder." -ForegroundColor Yellow
}

# Stop existing container if running
Write-Host ""
Write-Host "3️⃣ Stopping existing containers..." -ForegroundColor Yellow
docker-compose down 2>$null
Write-Host "   ✅ Cleaned up" -ForegroundColor Green

# Build and start
Write-Host ""
Write-Host "4️⃣ Building Docker image..." -ForegroundColor Yellow
docker-compose build

if ($LASTEXITCODE -ne 0) {
    Write-Host "   ❌ Build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "   ✅ Build successful" -ForegroundColor Green

Write-Host ""
Write-Host "5️⃣ Starting MCP server..." -ForegroundColor Yellow
docker-compose up -d

if ($LASTEXITCODE -ne 0) {
    Write-Host "   ❌ Failed to start container!" -ForegroundColor Red
    exit 1
}

Write-Host "   ✅ Container started" -ForegroundColor Green

# Wait a bit for server to start
Write-Host ""
Write-Host "6️⃣ Waiting for server to initialize..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Check health
Write-Host ""
Write-Host "7️⃣ Checking server health..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3001/health" -UseBasicParsing -TimeoutSec 5
    if ($response.StatusCode -eq 200) {
        Write-Host "   ✅ Server is healthy!" -ForegroundColor Green
        Write-Host ""
        Write-Host "🎉 Deployment successful!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Server is running at:" -ForegroundColor Cyan
        Write-Host "   http://localhost:3001" -ForegroundColor White
        Write-Host "   http://localhost:3001/health" -ForegroundColor White
        Write-Host ""
        Write-Host "View logs: docker-compose logs -f" -ForegroundColor Yellow
        Write-Host "Stop server: docker-compose down" -ForegroundColor Yellow
    } else {
        Write-Host "   ⚠️  Server responded but status is not OK" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   ⚠️  Health check failed. Server may still be starting..." -ForegroundColor Yellow
    Write-Host "   Check logs: docker-compose logs" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "View logs: docker-compose logs -f" -ForegroundColor Cyan









