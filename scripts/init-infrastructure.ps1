# init-infrastructure.ps1 - Initialize all development infrastructure services
# Usage: .\init-infrastructure.ps1

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Stop"

Write-Host "`n+===============================================================+" -ForegroundColor Cyan
Write-Host "|                                                               |" -ForegroundColor Cyan
Write-Host "|        >>> Development Infrastructure Startup <<<            |" -ForegroundColor Cyan
Write-Host "|                                                               |" -ForegroundColor Cyan
Write-Host "+===============================================================+" -ForegroundColor Cyan
Write-Host ""

# Navigate to project root
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

# Check if Docker is installed and running
Write-Host "[*] Checking Docker..." -ForegroundColor Yellow
try {
    $null = docker --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Docker not found"
    }
} catch {
    Write-Host "[X] Error: Docker is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

# Check if Docker daemon is running
try {
    $ErrorActionPreference = "Continue"
    $null = docker info 2>&1
    $dockerExitCode = $LASTEXITCODE
    $ErrorActionPreference = "Stop"

    if ($dockerExitCode -ne 0) {
        throw "Docker daemon not running"
    }
    Write-Host "[OK] Docker is ready" -ForegroundColor Green
} catch {
    Write-Host "[X] Error: Docker daemon is not running" -ForegroundColor Red
    Write-Host "   Please start Docker Desktop and try again." -ForegroundColor Yellow
    exit 1
}

# Check if docker-compose is available
try {
    $null = docker-compose --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        $null = docker compose version 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Docker Compose not available"
        }
    }
} catch {
    Write-Host "[X] Error: Docker Compose is not installed" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[i] Discovering services from docker-compose.yml..." -ForegroundColor Cyan

# Parse docker-compose.yml to get service names
$composeContent = Get-Content "docker-compose.yml" -Raw
$lines = $composeContent -split "`n"
$services = @()
$inServices = $false

foreach ($line in $lines) {
    # Check if we're entering the services section
    if ($line -match '^\s*services:\s*$') {
        $inServices = $true
        continue
    }

    # Check if we're leaving the services section (volumes or networks)
    if ($line -match '^\s*(volumes|networks):\s*$') {
        $inServices = $false
        continue
    }

    # If we're in services section, match service names (2 spaces indentation, name followed by colon)
    if ($inServices -and $line -match '^\s{2}(\w+):\s*$') {
        $serviceName = $matches[1]
        # Skip comments
        if (-not $line.TrimStart().StartsWith('#')) {
            $services += $serviceName
        }
    }
}

if ($services.Count -eq 0) {
    Write-Host "[!] No services found in docker-compose.yml" -ForegroundColor Yellow
    exit 1
}

Write-Host "   Found $($services.Count) service(s): $($services -join ', ')" -ForegroundColor Gray
Write-Host ""

# Start all services
Write-Host "[>] Starting all services..." -ForegroundColor Cyan
$ErrorActionPreference = "Continue"
docker-compose up -d 2>&1 | Out-Null
$composeExitCode = $LASTEXITCODE
$ErrorActionPreference = "Stop"

if ($composeExitCode -ne 0) {
    Write-Host "[X] Error: Failed to start services" -ForegroundColor Red
    Write-Host "   Run 'docker-compose up -d' manually to see detailed error" -ForegroundColor Yellow
    exit 1
}

Write-Host "[OK] Services started" -ForegroundColor Green
Write-Host ""

# Wait a moment for containers to initialize
Start-Sleep -Seconds 2

# Check health of each service
Write-Host "[+] Checking service health..." -ForegroundColor Cyan
Write-Host ""

$healthyServices = @()
$unhealthyServices = @()

foreach ($service in $services) {
    Write-Host "  Checking $service..." -ForegroundColor Gray -NoNewline

    # Check if a health check script exists
    $healthCheckScript = ".\scripts\health-checks\check-$service.ps1"

    if (Test-Path $healthCheckScript) {
        # Run the service-specific health check
        try {
            $result = & $healthCheckScript
            if ($LASTEXITCODE -eq 0) {
                Write-Host " [OK]" -ForegroundColor Green
                $healthyServices += $service
            } else {
                Write-Host " [X]" -ForegroundColor Red
                $unhealthyServices += $service
            }
        } catch {
            Write-Host " [X] (health check failed)" -ForegroundColor Red
            $unhealthyServices += $service
        }
    } else {
        # Fallback: just check if container is running
        $containerName = "dev-$service"
        $containerStatus = docker ps --filter "name=$containerName" --format "{{.Status}}" 2>&1

        if ($containerStatus -match "Up") {
            Write-Host " [OK] (running)" -ForegroundColor Green
            $healthyServices += $service
        } else {
            Write-Host " [!] (no health check available)" -ForegroundColor Yellow
            $healthyServices += $service
        }
    }
}

Write-Host ""
Write-Host "================================================================" -ForegroundColor DarkGray

# Summary
if ($unhealthyServices.Count -eq 0) {
    Write-Host "[OK] All services are running successfully!" -ForegroundColor Green
} else {
    Write-Host "[!] Some services may not be healthy:" -ForegroundColor Yellow
    foreach ($service in $unhealthyServices) {
        Write-Host "   - $service" -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "Check logs with: docker-compose logs SERVICE_NAME" -ForegroundColor Gray
}

Write-Host ""
Write-Host "[i] Service Status:" -ForegroundColor Cyan
Write-Host "   Running: $($healthyServices.Count)/$($services.Count)" -ForegroundColor White
Write-Host ""

# Display service-specific connection information
Write-Host "[i] Connection Information:" -ForegroundColor Cyan
Write-Host ""

foreach ($service in $healthyServices) {
    $infoScript = ".\scripts\service-info\info-$service.ps1"
    if (Test-Path $infoScript) {
        & $infoScript
    }
}

Write-Host "[i] Quick Commands:" -ForegroundColor Cyan
Write-Host "   View logs:        docker-compose logs -f" -ForegroundColor Gray
Write-Host "   Stop services:    docker-compose down" -ForegroundColor Gray
Write-Host "   Restart service:  docker-compose restart SERVICE_NAME" -ForegroundColor Gray
Write-Host "   Service status:   docker-compose ps" -ForegroundColor Gray
Write-Host ""
Write-Host "[OK] Infrastructure initialization complete!" -ForegroundColor Green
Write-Host ""
