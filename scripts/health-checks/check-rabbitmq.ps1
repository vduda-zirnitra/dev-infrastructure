# check-rabbitmq.ps1 - Health check for RabbitMQ
# Returns exit code 0 if healthy, 1 if not

$maxAttempts = 30
$attempt = 0

while ($attempt -lt $maxAttempts) {
    $ErrorActionPreference = "Continue"
    $null = docker exec dev-rabbitmq rabbitmq-diagnostics ping 2>&1
    $exitCode = $LASTEXITCODE
    $ErrorActionPreference = "Stop"

    if ($exitCode -eq 0) {
        exit 0  # Healthy
    }

    $attempt++
    Start-Sleep -Milliseconds 500
}

exit 1  # Unhealthy
