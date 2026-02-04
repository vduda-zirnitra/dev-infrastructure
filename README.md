# Development Infrastructure

A centralized Docker Compose infrastructure for managing multiple development services across all your projects. This repository provides a single source of truth for your local development environment, including PostgreSQL, RabbitMQ, Redis, and other services.

## 🎯 Overview

This project allows you to:
- ✅ Start all development services with one command
- ✅ Access services from any project on your machine
- ✅ Manage PostgreSQL databases easily with provided scripts
- ✅ Add/remove services by editing a single `docker-compose.yml`
- ✅ Keep data persistent across restarts
- ✅ Check service health and connection info quickly

**Key Concept**: Once started, these services are available system-wide. You can start them from this repository and connect to them from any other project.

## 📂 Project Structure

```
dev-infrastructure/
├── docker-compose.yml              # All infrastructure services
├── scripts/
│   ├── init-infrastructure.ps1     # Start all services (Windows)
│   ├── init-infrastructure.sh      # Start all services (Linux/Mac)
│   ├── add-database.ps1            # Create PostgreSQL databases (Windows)
│   ├── add-database.sh             # Create PostgreSQL databases (Linux/Mac)
│   ├── health-checks/              # Service health check scripts
│   │   ├── check-postgres.ps1/.sh
│   │   ├── check-rabbitmq.ps1/.sh
│   │   └── check-redis.ps1/.sh
│   └── service-info/               # Service connection info scripts
│       ├── info-postgres.ps1/.sh
│       ├── info-rabbitmq.ps1/.sh
│       └── info-redis.ps1/.sh
└── database/
    └── postgre/                    # PostgreSQL-specific configurations
        └── README.md
```

## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Available Services](#available-services)
- [PostgreSQL Database Management](#postgresql-database-management)
- [Service Management](#service-management)
- [Connection Information](#connection-information)
- [Scripts Reference](#scripts-reference)
- [Adding New Services](#adding-new-services)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)

---

## 🔧 Prerequisites

### Required Software

1. **Docker Desktop** (includes Docker Engine and Docker Compose)
   - Windows: [Download Docker Desktop for Windows](https://docs.docker.com/desktop/install/windows-install/)
   - Mac: [Download Docker Desktop for Mac](https://docs.docker.com/desktop/install/mac-install/)
   - Linux: [Install Docker Engine](https://docs.docker.com/engine/install/) + [Docker Compose Plugin](https://docs.docker.com/compose/install/)

2. **PowerShell** (Windows users - already installed)
3. **Bash** (Linux/Mac users - already installed)

### Verify Installation

Open a terminal and run:

```bash
# Check Docker
docker --version

# Check Docker Compose
docker compose version

# Verify Docker is running
docker info
```

If Docker Desktop is installed but `docker info` fails, make sure Docker Desktop is running (check your system tray or applications).

---

## 🚀 Quick Start

### First Time Setup

#### Windows (PowerShell)

```powershell
# 1. Clone or download this repository
cd C:\Users\YourName\IdeaProjects\dev-infrastructure

# 2. Start the infrastructure
.\scripts\init-infrastructure.ps1

# 3. Create your first PostgreSQL database
.\scripts\add-database.ps1 myapp myapp_user mySecurePassword123
```

#### Linux / Mac

```bash
# 1. Clone or download this repository
cd ~/projects/dev-infrastructure

# 2. Make scripts executable (one-time only)
chmod +x scripts/*.sh
chmod +x scripts/health-checks/*.sh
chmod +x scripts/service-info/*.sh

# 3. Start the infrastructure
./scripts/init-infrastructure.sh

# 4. Create your first PostgreSQL database
./scripts/add-database.sh myapp myapp_user mySecurePassword123
```

### What Happens?

The initialization script will:
1. ✅ Verify Docker is running
2. ✅ Start all enabled services (currently PostgreSQL)
3. ✅ Wait for services to become healthy
4. ✅ Display connection information for each service

---

## 🛠️ Available Services

### Currently Active

| Service    | Container Name | Ports           | Admin Credentials        | Status  |
|------------|----------------|-----------------|--------------------------|---------|
| PostgreSQL | dev-postgres   | 5432            | postgres / postgres      | ✅ Active |

### Available to Enable

The following services are pre-configured but commented out in `docker-compose.yml`. Uncomment them to enable:

| Service    | Container Name | Ports           | Admin Credentials        | Management UI         |
|------------|----------------|-----------------|--------------------------|------------------------|
| RabbitMQ   | dev-rabbitmq   | 5672, 15672     | admin / admin            | http://localhost:15672 |
| Redis      | dev-redis      | 6379            | (none - no auth)         | N/A                   |

To enable a service, edit `docker-compose.yml` and uncomment the relevant section, then run:

```bash
# Windows
.\scripts\init-infrastructure.ps1

# Linux/Mac
./scripts/init-infrastructure.sh
```

---

## 🗄️ PostgreSQL Database Management

### Creating Databases

Use the `add-database` scripts to create new databases with dedicated users:

#### Windows

```powershell
.\scripts\add-database.ps1 <database_name> <username> [password]

# Examples:
.\scripts\add-database.ps1 myapp myapp_user                    # Password defaults to "password"
.\scripts\add-database.ps1 auth_service auth_user MySecret123  # Custom password
```

#### Linux/Mac

```bash
./scripts/add-database.sh <database_name> <username> [password]

# Examples:
./scripts/add-database.sh myapp myapp_user                    # Password defaults to "password"
./scripts/add-database.sh auth_service auth_user MySecret123  # Custom password
```

### What the Script Does

The `add-database` script:
1. Creates the database if it doesn't exist
2. Creates the user if it doesn't exist
3. Grants all privileges on the database to the user
4. Sets up default privileges for tables and sequences
5. Returns a ready-to-use connection string

### Example Output

```
✅ Database 'myapp' created successfully!
✅ User 'myapp_user' created successfully!
✅ Privileges granted to 'myapp_user' on database 'myapp'

📋 Connection String:
   postgresql://myapp_user:password@localhost:5432/myapp
```

### Using from Your Projects

Copy the `add-database` script to your project or run it from this repository:

```bash
# From any project directory (Windows)
C:\Users\YourName\IdeaProjects\dev-infrastructure\scripts\add-database.ps1 my_project_db my_user

# From any project directory (Linux/Mac)
~/projects/dev-infrastructure/scripts/add-database.sh my_project_db my_user
```

---

## 🎮 Service Management

### Starting Services

```bash
# Windows
.\scripts\init-infrastructure.ps1

# Linux/Mac
./scripts/init-infrastructure.sh
```

### Stopping Services (Keep Data)

```bash
# Stop all services but preserve data
docker compose down

# Stop a specific service
docker compose stop postgres
```

### Restarting Services

```bash
# Restart all services
docker compose restart

# Restart a specific service
docker compose restart postgres
```

### Viewing Logs

```bash
# View all logs
docker compose logs -f

# View logs for a specific service
docker compose logs -f postgres

# View last 100 lines
docker compose logs --tail=100 postgres
```

### Checking Service Status

```bash
# List all running containers
docker ps

# Check specific container
docker ps | grep dev-postgres

# Check service health
docker inspect dev-postgres --format='{{.State.Health.Status}}'
```

### Destroying Services (⚠️ Deletes All Data)

```bash
# Remove containers AND volumes (all data will be lost)
docker compose down -v
```

---

## 🔗 Connection Information

### PostgreSQL

**Default Admin Connection:**
```
Host:     localhost
Port:     5432
Database: postgres
Username: postgres
Password: postgres

Connection String:
postgresql://postgres:postgres@localhost:5432/postgres
```

**After Creating a Database:**
```
Connection String:
postgresql://<username>:<password>@localhost:5432/<database_name>
```

## 📜 Scripts Reference

### `init-infrastructure.ps1/.sh`

**Purpose**: Initialize and start all infrastructure services

**Usage**:
```bash
# Windows
.\scripts\init-infrastructure.ps1

# Linux/Mac
./scripts/init-infrastructure.sh
```

**What it does**:
- Checks Docker daemon status
- Discovers all services in docker-compose.yml
- Starts all services with `docker compose up -d`
- Runs health checks on each service
- Displays connection information


---

## ➕ Adding New Services

### Example: Adding a Custom Service

Add to `docker-compose.yml`:

```yaml
services:
  # ...existing services...
  
  mongodb:
    image: mongo:latest
    container_name: dev-mongodb
    restart: unless-stopped
    ports:
      - "27017:27017"
    environment:
      MONGO_INITDB_ROOT_USERNAME: admin
      MONGO_INITDB_ROOT_PASSWORD: admin
    volumes:
      - mongo_data:/data/db
    networks:
      - dev-network

volumes:
  # ...existing volumes...
  mongo_data:
    driver: local
```

Then run `init-infrastructure` to start it.

---

## 🔧 Troubleshooting

### Docker Daemon Not Running

**Error**: `Error: Docker daemon is not running`

**Solution**:
1. Start Docker Desktop (Windows/Mac)
2. On Linux: `sudo systemctl start docker`
3. Wait 10-20 seconds for Docker to fully start
4. Run the script again

### Port Already in Use

**Error**: `Bind for 0.0.0.0:5432 failed: port is already allocated`

**Solution**:
```bash
# Find what's using the port (Windows)
netstat -ano | findstr :5432

# Find what's using the port (Linux/Mac)
lsof -i :5432

# Stop the conflicting service or change the port in docker-compose.yml
```

### Full Reset

If nothing works, perform a complete reset:

```bash
# Stop and remove everything
docker compose down -v

# Remove the containers
docker rm -f dev-postgres dev-rabbitmq dev-redis

# Remove the network
docker network rm dev-infrastructure_dev-network

# Start fresh
# Windows
.\scripts\init-infrastructure.ps1

# Linux/Mac
./scripts/init-infrastructure.sh
```

---

## 📄 License

This infrastructure setup is provided as-is for development purposes.

---

## 🔗 Useful Links

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [RabbitMQ Documentation](https://www.rabbitmq.com/documentation.html)
- [Redis Documentation](https://redis.io/documentation)
