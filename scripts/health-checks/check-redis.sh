#!/usr/bin/env bash

# check-redis.sh - Health check for Redis
# Returns exit code 0 if healthy, 1 if not

max_attempts=30
attempt=0

while [ $attempt -lt $max_attempts ]; do
    result=$(docker exec dev-redis redis-cli ping 2>&1)
    if [ $? -eq 0 ] && echo "$result" | grep -q "PONG"; then
        exit 0  # Healthy
    fi

    attempt=$((attempt + 1))
    sleep 0.5
done

exit 1  # Unhealthy
