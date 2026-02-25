#!/bin/bash

# Feature Flags Quick Setup Script
# This script initializes the feature flags and deployment metrics infrastructure
# Usage: bash scripts/setup-deployment-features.sh [--skip-migrations] [--seed-only]

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DB_RETRIES=5
REDIS_RETRIES=5
TIMEOUT_SECONDS=30

# Parse arguments
SKIP_MIGRATIONS=false
SEED_ONLY=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --skip-migrations)
      SKIP_MIGRATIONS=true
      shift
      ;;
    --seed-only)
      SEED_ONLY=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Helper functions
log_info() {
  echo -e "${BLUE}ℹ ${1}${NC}"
}

log_success() {
  echo -e "${GREEN}✓ ${1}${NC}"
}

log_warning() {
  echo -e "${YELLOW}⚠ ${1}${NC}"
}

log_error() {
  echo -e "${RED}✗ ${1}${NC}"
}

check_prerequisites() {
  log_info "Checking prerequisites..."
  
  # Check Node.js
  if ! command -v node &> /dev/null; then
    log_error "Node.js is not installed"
    exit 1
  fi
  log_success "Node.js $(node --version)"
  
  # Check npm
  if ! command -v npm &> /dev/null; then
    log_error "npm is not installed"
    exit 1
  fi
  log_success "npm $(npm --version)"
  
  # Check .env file
  if [ ! -f .env ]; then
    log_error ".env file not found"
    echo "Please create .env file with required variables:"
    echo "  DATABASE_URL=postgresql://user:password@localhost/rupaya"
    echo "  REDIS_URL=redis://localhost:6379"
    echo "  ADMIN_API_TOKEN=your-secure-token"
    exit 1
  fi
  log_success ".env file exists"
  
  # Check database connectivity
  log_info "Checking database connectivity..."
  if ! node -e "
    require('dotenv').config();
    const Pool = require('pg').Pool;
    const pool = new Pool({ connectionString: process.env.DATABASE_URL });
    pool.query('SELECT Now()', (err, res) => {
      pool.end();
      if (err) {
        console.error('Database connection failed:', err.message);
        process.exit(1);
      } else {
        console.log('Database connection successful');
      }
    });
  " 2>/dev/null; then
    log_error "Cannot connect to database"
    exit 1
  fi
  log_success "Database connection verified"
  
  # Check Redis connectivity
  log_info "Checking Redis connectivity..."
  if ! node -e "
    require('dotenv').config();
    const redis = require('redis');
    const client = redis.createClient({ url: process.env.REDIS_URL });
    client.connect().then(() => {
      client.quit();
    }).catch(err => {
      console.error('Redis connection failed:', err.message);
      process.exit(1);
    });
  " 2>/dev/null; then
    log_error "Cannot connect to Redis"
    exit 1
  fi
  log_success "Redis connection verified"
}

run_migrations() {
  if [ "$SKIP_MIGRATIONS" = true ]; then
    log_warning "Skipping migrations (--skip-migrations)"
    return 0
  fi
  
  log_info "Running database migrations..."
  
  if npm run migrate --silent >/dev/null 2>&1; then
    log_success "Migrations completed"
  else
    log_error "Migration failed"
    npm run migrate
    exit 1
  fi
}

seed_feature_flags() {
  log_info "Seeding default feature flags..."
  
  node -e "
    require('dotenv').config();
    const knex = require('knex');
    const config = require('./knexfile');
    const db = knex(config[process.env.NODE_ENV || 'development']);
    
    (async () => {
      try {
        // Check if flags exist
        const count = await db('feature_flags').count('* as count').first();
        
        if (count.count > 0) {
          console.log('Feature flags already seeded (' + count.count + ' flags)');
          await db.destroy();
          return;
        }

        // Get default flags
        const flagConfig = require('./src/config/feature-flags');
        const flags = Object.entries(flagConfig.defaultFlags).map(([key, value]) => ({
          key,
          type: value.type,
          config: JSON.stringify(value),
          created_at: new Date(),
          updated_at: new Date()
        }));

        // Insert flags
        await db('feature_flags').insert(flags);
        console.log('Seeded ' + flags.length + ' feature flags');
        await db.destroy();
      } catch (error) {
        console.error('Seeding failed:', error.message);
        process.exit(1);
      }
    })();
  " || exit 1
  
  log_success "Feature flags seeded"
}

create_admin_token() {
  log_info "Checking ADMIN_API_TOKEN..."
  
  if grep -q "^ADMIN_API_TOKEN=.{20,}" .env; then
    log_success "ADMIN_API_TOKEN already configured"
  else
    log_warning "ADMIN_API_TOKEN not set or too short"
    
    # Generate random token
    TOKEN=$(node -e "console.log(require('crypto').randomBytes(32).toString('hex'))")
    
    # Update .env if no token exists
    if ! grep -q "^ADMIN_API_TOKEN=" .env; then
      echo "" >> .env
      echo "# Admin API Token for managing feature flags" >> .env
      echo "ADMIN_API_TOKEN=$TOKEN" >> .env
      log_success "Generated and saved ADMIN_API_TOKEN to .env"
      echo -e "${YELLOW}Token: $TOKEN${NC}"
    fi
  fi
}

verify_services() {
  log_info "Verifying services..."
  
  # Start server briefly to test
  timeout 5 npm start > /tmp/server-test.log 2>&1 || true
  
  if grep -q "Server running" /tmp/server-test.log; then
    log_success "Server starts successfully"
  else
    log_warning "Could not verify server startup (expected for quick test)"
  fi
  
  # Test health endpoint
  if curl -s http://localhost:3000/health > /dev/null 2>&1; then
    log_success "Health endpoint responding"
  else
    log_warning "Health endpoint not responding (server may not be running)"
  fi
}

main() {
  echo ""
  echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${BLUE}║  Feature Flags & Deployment Metrics Setup                    ║${NC}"
  echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  
  # Check prerequisites
  check_prerequisites
  echo ""
  
  # Run migrations
  run_migrations
  echo ""
  
  # Seed data
  seed_feature_flags
  echo ""
  
  # Setup admin token
  create_admin_token
  echo ""
  
  # Verify services
  log_info "Setup complete! ✨"
  echo ""
  echo -e "${BLUE}Next steps:${NC}"
  echo "  1. Start the server: npm start"
  echo "  2. Test health endpoint: curl http://localhost:3000/health"
  echo "  3. View feature flags: curl http://localhost:3000/api/admin/deployment/feature-flags"
  echo "  4. Read docs/FEATURE_FLAGS_AND_DEPLOYMENT.md for usage guide"
  echo ""
}

# Run main
main
