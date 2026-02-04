# check-postgres.ps1 - Health check for PostgreSQL
# Returns exit code 0 if healthy, 1 if not

$maxAttempts = 30
$attempt = 0

while ($attempt -lt $maxAttempts) {
    $ErrorActionPreference = "Continue"
    $null = docker exec dev-postgres pg_isready -U postgres 2>&1
    $exitCode = $LASTEXITCODE
    $ErrorActionPreference = "Stop"

    if ($exitCode -eq 0) {
        exit 0  # Healthy
    }

    $attempt++
    Start-Sleep -Milliseconds 500
}

exit 1  # Unhealthy
