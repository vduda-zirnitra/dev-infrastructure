#!/bin/bash

# init-infrastructure.sh - Initialize all development infrastructure services
# Usage: ./init-infrastructure.sh

set -e

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║        🚀 Development Infrastructure Startup 🚀          ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Navigate to project root
cd "$(dirname "$0")/.."

# Check if Docker is installed and running
echo "🔍 Checking Docker..."
if ! command -v docker &> /dev/null; then
    echo "❌ Error: Docker is not installed or not in PATH"
    exit 1
fi

if ! docker info &> /dev/null; then
    echo "❌ Error: Docker daemon is not running"
    echo "   Please start Docker and try again."
    exit 1
fi

echo "✅ Docker is ready"

# Check if docker-compose is installed
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "❌ Error: Docker Compose is not installed"
    exit 1
fi

echo ""
echo "📋 Discovering services from docker-compose.yml..."

# Parse docker-compose.yml to get service names
services=()
in_services=false

while IFS= read -r line; do
    # Check if we're in the services section
    if [[ "$line" =~ ^services: ]]; then
        in_services=true
        continue
    fi

    # Check if we left the services section (volumes or networks)
    if [[ "$line" =~ ^(volumes|networks): ]]; then
        in_services=false
        continue
    fi

    # Extract service names (indented names followed by colon)
    if [[ $in_services == true ]] && [[ "$line" =~ ^[[:space:]]+([a-zA-Z0-9_-]+):[[:space:]]*$ ]]; then
        service_name="${BASH_REMATCH[1]}"
        # Skip comments
        if [[ ! "$line" =~ ^[[:space:]]*# ]]; then
            services+=("$service_name")
        fi
    fi
done < docker-compose.yml

if [ ${#services[@]} -eq 0 ]; then
    echo "⚠️  No services found in docker-compose.yml"
    exit 1
fi

echo "   Found ${#services[@]} service(s): ${services[*]}"
echo ""

# Start all services
echo "🚀 Starting all services..."
if docker-compose up -d &> /dev/null; then
    echo "✅ Services started"
else
    echo "❌ Error: Failed to start services"
    echo "   Run 'docker-compose up -d' manually to see detailed error"
    exit 1
fi

echo ""

# Wait a moment for containers to initialize
sleep 2

# Check health of each service
echo "🏥 Checking service health..."
echo ""

healthy_services=()
unhealthy_services=()

for service in "${services[@]}"; do
    echo -n "  Checking $service..."

    # Check if a health check script exists
    health_check_script="./scripts/health-checks/check-$service.sh"

    if [ -f "$health_check_script" ] && [ -x "$health_check_script" ]; then
        # Run the service-specific health check
        if "$health_check_script" &> /dev/null; then
            echo " ✅"
            healthy_services+=("$service")
        else
            echo " ❌"
            unhealthy_services+=("$service")
        fi
    else
        # Fallback: just check if container is running
        container_name="dev-$service"
        if docker ps --filter "name=$container_name" --format "{{.Status}}" | grep -q "Up"; then
            echo " ✅ (running)"
            healthy_services+=("$service")
        else
            echo " ⚠️  (no health check available)"
            healthy_services+=("$service")
        fi
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Summary
if [ ${#unhealthy_services[@]} -eq 0 ]; then
    echo "✨ All services are running successfully!"
else
    echo "⚠️  Some services may not be healthy:"
    for service in "${unhealthy_services[@]}"; do
        echo "   - $service"
    done
    echo ""
    echo "Check logs with: docker-compose logs <service-name>"
fi

echo ""
echo "📊 Service Status:"
echo "   Running: ${#healthy_services[@]}/${#services[@]}"
echo ""

# Display service-specific connection information
echo "🔗 Connection Information:"
echo ""

for service in "${healthy_services[@]}"; do
    info_script="./scripts/service-info/info-$service.sh"
    if [ -f "$info_script" ] && [ -x "$info_script" ]; then
        "$info_script"
    fi
done

echo "📝 Quick Commands:"
echo "   View logs:        docker-compose logs -f"
echo "   Stop services:    docker-compose down"
echo "   Restart service:  docker-compose restart <service-name>"
echo "   Service status:   docker-compose ps"
echo ""
echo "✅ Infrastructure initialization complete!"
echo ""
