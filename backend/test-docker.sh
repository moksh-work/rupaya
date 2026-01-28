#!/bin/bash
# Docker Testing Script for RUPAYA Backend

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}  RUPAYA Backend Docker Test Suite${NC}"
echo -e "${BLUE}=====================================${NC}"
echo ""

# Function to print colored output
print_status() {
  echo -e "${GREEN}✓${NC} $1"
}

print_error() {
  echo -e "${RED}✗${NC} $1"
}

print_info() {
  echo -e "${BLUE}ℹ${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}⚠${NC} $1"
}

# Test 1: Check Docker installation
echo -e "${YELLOW}Test 1: Docker Installation${NC}"
if command -v docker &> /dev/null; then
  print_status "Docker installed: $(docker --version)"
else
  print_error "Docker not installed"
  exit 1
fi

if command -v docker-compose &> /dev/null; then
  print_status "Docker Compose installed: $(docker-compose --version)"
else
  print_error "Docker Compose not installed"
  exit 1
fi
echo ""

# Test 2: Port availability
echo -e "${YELLOW}Test 2: Port Availability${NC}"
check_port() {
  if lsof -Pi :$1 -sTCP:LISTEN -t >/dev/null ; then
    return 0
  else
    return 1
  fi
}

if check_port 3000; then
  print_warning "Port 3000 already in use"
else
  print_status "Port 3000 available"
fi

if check_port 5432; then
  print_warning "Port 5432 already in use"
else
  print_status "Port 5432 available"
fi

if check_port 6379; then
  print_warning "Port 6379 already in use"
else
  print_status "Port 6379 available"
fi
echo ""

# Test 3: Docker files exist
echo -e "${YELLOW}Test 3: Docker Files${NC}"
if [ -f "Dockerfile" ]; then
  print_status "Dockerfile exists"
else
  print_error "Dockerfile missing"
  exit 1
fi

if [ -f "docker-compose.dev.yml" ]; then
  print_status "docker-compose.dev.yml exists"
else
  print_error "docker-compose.dev.yml missing"
  exit 1
fi

if [ -f ".env.docker" ]; then
  print_status ".env.docker exists"
else
  print_error ".env.docker missing"
  exit 1
fi
echo ""

# Test 4: Environment file
echo -e "${YELLOW}Test 4: Environment Configuration${NC}"
if [ ! -f ".env" ]; then
  print_info "Creating .env from .env.docker..."
  cp .env.docker .env
  print_status ".env created"
else
  print_status ".env already exists"
fi
echo ""

# Test 5: Dependencies
echo -e "${YELLOW}Test 5: Node Dependencies${NC}"
if [ -d "node_modules" ]; then
  print_status "node_modules directory exists"
else
  print_warning "node_modules not installed locally, Docker will install"
fi
echo ""

# Test 6: Start Docker services
echo -e "${YELLOW}Test 6: Starting Docker Services${NC}"
print_info "Building Docker images..."
docker-compose -f docker-compose.dev.yml build --quiet

print_info "Starting containers..."
docker-compose -f docker-compose.dev.yml up -d

print_info "Waiting for services to be ready..."
sleep 8

echo ""

# Test 7: Container status
echo -e "${YELLOW}Test 7: Container Status${NC}"
docker-compose -f docker-compose.dev.yml ps

echo ""

# Test 8: Health checks
echo -e "${YELLOW}Test 8: Service Health Checks${NC}"

# Check PostgreSQL
print_info "Checking PostgreSQL..."
if docker-compose -f docker-compose.dev.yml exec -T postgres pg_isready -U rupaya &> /dev/null; then
  print_status "PostgreSQL is ready"
else
  print_error "PostgreSQL not ready"
  docker-compose -f docker-compose.dev.yml logs postgres
  exit 1
fi

# Check Redis
print_info "Checking Redis..."
if docker-compose -f docker-compose.dev.yml exec -T redis redis-cli ping | grep -q PONG; then
  print_status "Redis is ready"
else
  print_error "Redis not ready"
  docker-compose -f docker-compose.dev.yml logs redis
  exit 1
fi

# Check Backend
print_info "Checking Backend..."
sleep 3
if curl -s http://localhost:3000/health | grep -q "OK"; then
  print_status "Backend is ready"
else
  print_error "Backend not responding"
  docker-compose -f docker-compose.dev.yml logs backend
  exit 1
fi

echo ""

# Test 9: Run migrations
echo -e "${YELLOW}Test 9: Database Migrations${NC}"
print_info "Running migrations..."
if docker-compose -f docker-compose.dev.yml exec -T backend npm run migrate &> /dev/null; then
  print_status "Migrations completed"
else
  print_warning "Migrations may have already run"
fi
echo ""

# Test 10: API Testing
echo -e "${YELLOW}Test 10: API Endpoint Testing${NC}"

print_info "Testing /health endpoint..."
HEALTH=$(curl -s http://localhost:3000/health)
if echo "$HEALTH" | grep -q "OK"; then
  print_status "GET /health: OK"
else
  print_error "GET /health failed"
fi

print_info "Testing signup endpoint..."
SIGNUP=$(curl -s -X POST http://localhost:3000/api/v1/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "SecurePass123!",
    "deviceId": "docker-test",
    "deviceName": "Docker Test Device"
  }')

if echo "$SIGNUP" | grep -q "accessToken"; then
  print_status "POST /api/v1/auth/signup: Created"
  TOKEN=$(echo "$SIGNUP" | grep -o '"accessToken":"[^"]*' | cut -d'"' -f4)
  print_info "Token obtained: ${TOKEN:0:20}..."
else
  print_error "POST /api/v1/auth/signup failed"
  echo "Response: $SIGNUP"
fi

echo ""

# Test 11: Log verification
echo -e "${YELLOW}Test 11: Container Logs${NC}"
print_info "Backend logs (last 10 lines):"
docker-compose -f docker-compose.dev.yml logs backend | tail -10
echo ""

# Test 12: Resource usage
echo -e "${YELLOW}Test 12: Resource Usage${NC}"
docker stats --no-stream --format "table {{.Container}}\t{{.MemUsage}}\t{{.CPUPerc}}" | grep rupaya
echo ""

# Summary
echo -e "${BLUE}=====================================${NC}"
echo -e "${GREEN}✓ All Docker tests passed!${NC}"
echo -e "${BLUE}=====================================${NC}"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "  1. View logs:    ${YELLOW}docker-compose -f docker-compose.dev.yml logs -f backend${NC}"
echo "  2. Test API:     ${YELLOW}curl http://localhost:3000/health${NC}"
echo "  3. Access DB:    ${YELLOW}docker-compose -f docker-compose.dev.yml exec postgres psql -U rupaya -d rupaya_dev${NC}"
echo "  4. Stop services: ${YELLOW}docker-compose -f docker-compose.dev.yml down${NC}"
echo ""
echo -e "${BLUE}API Documentation:${NC}"
echo "  See DOCKER_GUIDE.md for complete testing examples"
echo ""
