#!/bin/bash

# add-database.sh - Create a new database and user in PostgreSQL
# Usage: ./add-database.sh <database_name> <username> [password]

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Check arguments
if [ $# -lt 2 ]; then
    echo -e "${RED}❌ Error: Insufficient arguments${NC}"
    echo ""
    echo "Usage: $0 <database_name> <username> [password]"
    echo ""
    echo "Arguments:"
    echo "  database_name  - Name of the database to create"
    echo "  username       - Username for the database owner"
    echo "  password       - Password for the user (default: 'password')"
    echo ""
    echo "Example:"
    echo "  $0 myapp myapp_user mySecurePassword123"
    echo "  $0 myapp myapp_user  # Uses default password 'password'"
    exit 1
fi

DB_NAME=$1
DB_USER=$2
DB_PASS=${3:-password}

echo -e "${CYAN}🔧 Creating database and user...${NC}"
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Error: Docker is not installed or not in PATH${NC}"
    exit 1
fi

# Check if container exists and is running
if ! docker ps --format '{{.Names}}' | grep -q "^dev-postgres$"; then
    echo -e "${RED}❌ Error: Container 'dev-postgres' is not running${NC}"
    echo ""
    echo "Please start the PostgreSQL container first:"
    echo "  ./scripts/init-postgres.sh"
    exit 1
fi

# Validate database name (alphanumeric, underscore, hyphen)
if ! [[ "$DB_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo -e "${RED}❌ Error: Invalid database name. Use only letters, numbers, underscores, and hyphens.${NC}"
    exit 1
fi

# Validate username (alphanumeric, underscore)
if ! [[ "$DB_USER" =~ ^[a-zA-Z0-9_]+$ ]]; then
    echo -e "${RED}❌ Error: Invalid username. Use only letters, numbers, and underscores.${NC}"
    exit 1
fi

# Convert hyphen to underscore for database name (PostgreSQL best practice)
DB_NAME_CLEAN=$(echo "$DB_NAME" | tr '-' '_')
if [ "$DB_NAME" != "$DB_NAME_CLEAN" ]; then
    echo -e "${YELLOW}ℹ️  Note: Database name converted from '$DB_NAME' to '$DB_NAME_CLEAN' (hyphens replaced with underscores)${NC}"
    DB_NAME=$DB_NAME_CLEAN
fi

echo "Creating database: $DB_NAME"
echo "Creating user: $DB_USER"
echo ""

# Create SQL commands
SQL_COMMANDS=$(cat <<EOF
-- Create user if not exists
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_user WHERE usename = '$DB_USER') THEN
        CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';
        RAISE NOTICE 'User $DB_USER created';
    ELSE
        ALTER USER $DB_USER WITH PASSWORD '$DB_PASS';
        RAISE NOTICE 'User $DB_USER already exists, password updated';
    END IF;
END
\$\$;

-- Create database if not exists
SELECT 'CREATE DATABASE $DB_NAME OWNER $DB_USER'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$DB_NAME')\gexec

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
EOF
)

# Execute SQL commands
echo -e "${YELLOW}⏳ Executing SQL commands...${NC}"
echo "$SQL_COMMANDS" | docker exec -i dev-postgres psql -U postgres

# Connect to the new database and set up schema privileges
SCHEMA_SQL=$(cat <<EOF
-- Grant all privileges on schema
GRANT ALL ON SCHEMA public TO $DB_USER;

-- Set default privileges for tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO $DB_USER;

-- Set default privileges for sequences
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO $DB_USER;

-- Set default privileges for functions
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO $DB_USER;
EOF
)

echo "$SCHEMA_SQL" | docker exec -i dev-postgres psql -U postgres -d $DB_NAME

# Verify database creation
DB_EXISTS=$(docker exec dev-postgres psql -U postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'")

if [ "$DB_EXISTS" = "1" ]; then
    echo ""
    echo -e "${GREEN}✅ Database and user created successfully!${NC}"
    echo ""
    echo -e "${CYAN}📋 Database Details:${NC}"
    echo "   Database: $DB_NAME"
    echo "   Username: $DB_USER"
    echo "   Password: $DB_PASS"
    echo "   Host: localhost"
    echo "   Port: 5432"
    echo ""
    echo -e "${CYAN}🔗 Connection String:${NC}"
    echo "   postgresql://$DB_USER:$DB_PASS@localhost:5432/$DB_NAME"
    echo ""
    echo -e "${CYAN}📝 JDBC URL:${NC}"
    echo "   jdbc:postgresql://localhost:5432/$DB_NAME"
    echo ""
    echo -e "${CYAN}💡 Test Connection:${NC}"
    echo "   docker exec -it dev-postgres psql -U $DB_USER -d $DB_NAME"
    echo ""
else
    echo -e "${RED}❌ Error: Database creation failed${NC}"
    exit 1
fi
