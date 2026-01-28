#!/bin/bash
# Docker Local Development Startup Script

set -e

echo "🚀 Starting RUPAYA Backend in Docker..."

# Create .env if it doesn't exist
if [ ! -f .env ]; then
  echo "📝 Creating .env from .env.docker..."
  cp .env.docker .env
fi

# Build and start containers
echo "🔨 Building Docker images..."
docker-compose -f docker-compose.dev.yml build

echo "📦 Starting services..."
docker-compose -f docker-compose.dev.yml up -d

echo "⏳ Waiting for PostgreSQL to be ready..."
sleep 5

# Run migrations
echo "🗄️  Running database migrations..."
docker-compose -f docker-compose.dev.yml exec -T backend npm run migrate

echo "✅ Backend setup complete!"
echo ""
echo "📍 Services running:"
echo "  • Backend: http://localhost:3000"
echo "  • PostgreSQL: localhost:5432"
echo "  • Redis: localhost:6379"
echo ""
echo "🔍 View logs: docker-compose -f docker-compose.dev.yml logs -f backend"
echo "🛑 Stop services: docker-compose -f docker-compose.dev.yml down"
