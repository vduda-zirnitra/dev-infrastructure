# add-database.ps1 - Create a new database and user in PostgreSQL
# Usage: .\add-database.ps1 <database_name> <username> [password]

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$DatabaseName,

    [Parameter(Mandatory=$true, Position=1)]
    [string]$Username,

    [Parameter(Mandatory=$false, Position=2)]
    [string]$Password = "password"
)

$ErrorActionPreference = "Stop"

Write-Host "🔧 Creating database and user..." -ForegroundColor Cyan
Write-Host ""

# Check if Docker is installed
try {
    $null = docker --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Docker not available"
    }
} catch {
    Write-Host "❌ Error: Docker is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

# Check if container exists and is running
try {
    $containerRunning = docker ps --format "{{.Names}}" | Where-Object { $_ -eq "dev-postgres" }
    if (-not $containerRunning) {
        Write-Host "❌ Error: Container 'dev-postgres' is not running" -ForegroundColor Red
        Write-Host ""
        Write-Host "Please start the PostgreSQL container first:" -ForegroundColor Yellow
        Write-Host "  .\scripts\init-postgres.ps1"
        exit 1
    }
} catch {
    Write-Host "❌ Error: Failed to check container status" -ForegroundColor Red
    exit 1
}

# Validate database name (alphanumeric, underscore, hyphen)
if ($DatabaseName -notmatch '^[a-zA-Z0-9_-]+$') {
    Write-Host "❌ Error: Invalid database name. Use only letters, numbers, underscores, and hyphens." -ForegroundColor Red
    exit 1
}

# Validate username (alphanumeric, underscore)
if ($Username -notmatch '^[a-zA-Z0-9_]+$') {
    Write-Host "❌ Error: Invalid username. Use only letters, numbers, and underscores." -ForegroundColor Red
    exit 1
}

# Convert hyphen to underscore for database name (PostgreSQL best practice)
$DbNameClean = $DatabaseName -replace '-', '_'
if ($DatabaseName -ne $DbNameClean) {
    Write-Host "ℹ️  Note: Database name converted from '$DatabaseName' to '$DbNameClean' (hyphens replaced with underscores)" -ForegroundColor Yellow
    $DatabaseName = $DbNameClean
}

Write-Host "Creating database: $DatabaseName"
Write-Host "Creating user: $Username"
Write-Host ""

# Create SQL commands
$sqlCommands = @"
-- Create user if not exists
DO `$`$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_user WHERE usename = '$Username') THEN
        CREATE USER $Username WITH PASSWORD '$Password';
        RAISE NOTICE 'User $Username created';
    ELSE
        ALTER USER $Username WITH PASSWORD '$Password';
        RAISE NOTICE 'User $Username already exists, password updated';
    END IF;
END
`$`$;

-- Create database if not exists
SELECT 'CREATE DATABASE $DatabaseName OWNER $Username'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$DatabaseName')\gexec

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE $DatabaseName TO $Username;
"@

# Execute SQL commands
Write-Host "⏳ Executing SQL commands..." -ForegroundColor Yellow
try {
    $sqlCommands | docker exec -i dev-postgres psql -U postgres
    if ($LASTEXITCODE -ne 0) {
        throw "SQL execution failed"
    }
} catch {
    Write-Host "❌ Error: Failed to execute SQL commands" -ForegroundColor Red
    exit 1
}

# Connect to the new database and set up schema privileges
$schemaSql = @"
-- Grant all privileges on schema
GRANT ALL ON SCHEMA public TO $Username;

-- Set default privileges for tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO $Username;

-- Set default privileges for sequences
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO $Username;

-- Set default privileges for functions
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO $Username;
"@

try {
    $schemaSql | docker exec -i dev-postgres psql -U postgres -d $DatabaseName
    if ($LASTEXITCODE -ne 0) {
        throw "Schema privileges setup failed"
    }
} catch {
    Write-Host "⚠️  Warning: Some schema privileges may not have been set correctly" -ForegroundColor Yellow
}

# Verify database creation
try {
    $dbExists = docker exec dev-postgres psql -U postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$DatabaseName'" 2>&1

    if ($dbExists -match "1") {
        Write-Host ""
        Write-Host "✅ Database and user created successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "📋 Database Details:" -ForegroundColor Cyan
        Write-Host "   Database: $DatabaseName"
        Write-Host "   Username: $Username"
        Write-Host "   Password: $Password"
        Write-Host "   Host: localhost"
        Write-Host "   Port: 5432"
        Write-Host ""
        Write-Host "🔗 Connection String:" -ForegroundColor Cyan
        Write-Host "   postgresql://${Username}:${Password}@localhost:5432/$DatabaseName"
        Write-Host ""
        Write-Host "📝 JDBC URL:" -ForegroundColor Cyan
        Write-Host "   jdbc:postgresql://localhost:5432/$DatabaseName"
        Write-Host ""
        Write-Host "💡 Test Connection:" -ForegroundColor Cyan
        Write-Host "   docker exec -it dev-postgres psql -U $Username -d $DatabaseName"
        Write-Host ""
    } else {
        Write-Host "❌ Error: Database creation verification failed" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "⚠️  Warning: Could not verify database creation" -ForegroundColor Yellow
}
