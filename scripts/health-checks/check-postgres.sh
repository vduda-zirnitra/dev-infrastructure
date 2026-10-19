#!/usr/bin/env bash

# check-postgres.sh - Health check for PostgreSQL
# Returns exit code 0 if healthy, 1 if not

max_attempts=30
attempt=0

while [ $attempt -lt $max_attempts ]; do
    if docker exec dev-postgres pg_isready -U postgres &> /dev/null; then
        exit 0  # Healthy
    fi

    attempt=$((attempt + 1))
    sleep 0.5
done

exit 1  # Unhealthy
