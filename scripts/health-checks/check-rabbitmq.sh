#!/usr/bin/env bash

# check-rabbitmq.sh - Health check for RabbitMQ
# Returns exit code 0 if healthy, 1 if not

max_attempts=30
attempt=0

while [ $attempt -lt $max_attempts ]; do
    if docker exec dev-rabbitmq rabbitmq-diagnostics ping &> /dev/null; then
        exit 0  # Healthy
    fi

    attempt=$((attempt + 1))
    sleep 0.5
done

exit 1  # Unhealthy
