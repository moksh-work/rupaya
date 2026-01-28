#!/bin/bash
# Docker Production Startup Script

set -e

echo "🚀 Starting RUPAYA Backend in Production Mode..."

# Verify required environment variables
required_vars=(
  "DB_PASSWORD"
  "JWT_SECRET"
  "REFRESH_TOKEN_SECRET"
  "ENCRYPTION_KEY"
)

for var in "${required_vars[@]}"; do
  if [ -z "${!var}" ]; then
    echo "❌ Error: Required environment variable $var is not set"
    exit 1
  fi
done

echo "✅ Environment variables verified"

# Build production images
echo "🔨 Building production Docker images..."
docker-compose -f docker-compose.prod.yml build

echo "📦 Starting services..."
docker-compose -f docker-compose.prod.yml up -d

echo "⏳ Waiting for services to be healthy..."
sleep 10

# Run migrations
echo "🗄️  Running database migrations..."
docker-compose -f docker-compose.prod.yml exec -T backend npm run migrate

echo "✅ Production setup complete!"
echo ""
echo "📍 Services running:"
echo "  • Backend: http://localhost:${PORT:-3000}"
echo "  • PostgreSQL: ${DB_HOST}:${DB_PORT}"
echo "  • Redis: redis://redis:6379"
echo ""
echo "🔍 View logs: docker-compose -f docker-compose.prod.yml logs -f backend"
