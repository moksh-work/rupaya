#!/bin/bash

# ====================================================================
# RUPAYA Database Setup Script
# ====================================================================

set -e

echo "🚀 RUPAYA Database Setup"
echo "========================"

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Database connection details
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-rupaya}"
DB_USER="${DB_USER:-postgres}"
DB_PASSWORD="${DB_PASSWORD:-postgres}"

echo "📋 Configuration:"
echo "   Host: $DB_HOST"
echo "   Port: $DB_PORT"
echo "   Database: $DB_NAME"
echo "   User: $DB_USER"
echo ""

# Check if PostgreSQL is accessible
echo "🔍 Checking PostgreSQL connection..."
export PGPASSWORD=$DB_PASSWORD

if ! psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -c '\q' 2>/dev/null; then
    echo "❌ Cannot connect to PostgreSQL server"
    echo "Please ensure PostgreSQL is running and credentials are correct"
    exit 1
fi

echo "✅ PostgreSQL connection successful"
echo ""

# Create database if it doesn't exist
echo "📦 Creating database if not exists..."
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -tc "SELECT 1 FROM pg_database WHERE datname = '$DB_NAME'" | grep -q 1 || \
    psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -c "CREATE DATABASE $DB_NAME"

echo "✅ Database ready"
echo ""

# Run migrations in order
echo "🔄 Running migrations..."
echo ""

# Migration 003: Complete API Schema
echo "📝 Running migration 003_complete_api_schema.sql..."
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f backend/migrations/003_complete_api_schema.sql

if [ $? -eq 0 ]; then
    echo "✅ Migration 003 completed successfully"
else
    echo "❌ Migration 003 failed"
    exit 1
fi

# Migration 004: Refresh Token Revocation
echo ""
echo "📝 Running migration 004_auth_token_revocation.sql..."
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f backend/migrations/004_auth_token_revocation.sql

if [ $? -eq 0 ]; then
    echo "✅ Migration 004 completed successfully"
else
    echo "❌ Migration 004 failed"
    exit 1
fi

echo ""
echo "🎉 Database setup completed successfully!"
echo ""

# Verify tables
echo "📊 Database Statistics:"
echo ""

TABLES=$(psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE'")
VIEWS=$(psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "SELECT COUNT(*) FROM information_schema.views WHERE table_schema = 'public'")
INDEXES=$(psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "SELECT COUNT(*) FROM pg_indexes WHERE schemaname = 'public'")

echo "   Tables: $TABLES"
echo "   Views: $VIEWS"
echo "   Indexes: $INDEXES"
echo ""

# List all tables
echo "📋 Created Tables:"
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "\dt" | grep public

echo ""
echo "✨ Setup complete! You can now start the backend server."
echo ""
