# check-redis.ps1 - Health check for Redis
# Returns exit code 0 if healthy, 1 if not

$maxAttempts = 30
$attempt = 0

while ($attempt -lt $maxAttempts) {
    $ErrorActionPreference = "Continue"
    $result = docker exec dev-redis redis-cli ping 2>&1
    $exitCode = $LASTEXITCODE
    $ErrorActionPreference = "Stop"

    if ($exitCode -eq 0 -and $result -match "PONG") {
        exit 0  # Healthy
    }

    $attempt++
    Start-Sleep -Milliseconds 500
}

exit 1  # Unhealthy
