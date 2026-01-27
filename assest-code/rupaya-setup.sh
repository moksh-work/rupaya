#!/bin/bash

# RUPAYA Money Manager - Complete Setup Script
# Run this to bootstrap the entire project locally

set -e

echo "🚀 RUPAYA Money Manager - Local Setup"
echo "======================================"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check prerequisites
echo -e "\n${YELLOW}Checking prerequisites...${NC}"
command -v docker &> /dev/null || { echo -e "${RED}Docker not installed${NC}"; exit 1; }
command -v node &> /dev/null || { echo -e "${RED}Node.js not installed${NC}"; exit 1; }
command -v git &> /dev/null || { echo -e "${RED}Git not installed${NC}"; exit 1; }

echo -e "${GREEN}✓ All prerequisites found${NC}"

# Backend setup
echo -e "\n${YELLOW}Setting up Backend...${NC}"
cd backend
cp .env.example .env
npm install
echo -e "${GREEN}✓ Backend dependencies installed${NC}"

# Database setup
echo -e "\n${YELLOW}Starting PostgreSQL & Redis...${NC}"
docker-compose up -d
sleep 5

# Run migrations
echo -e "${YELLOW}Running database migrations...${NC}"
npm run migrate
npm run seed
echo -e "${GREEN}✓ Database initialized${NC}"

# Start backend
echo -e "\n${YELLOW}Starting backend server...${NC}"
npm run dev &
BACKEND_PID=$!
sleep 3
echo -e "${GREEN}✓ Backend running on port 3000${NC}"

# iOS setup (if on macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo -e "\n${YELLOW}Setting up iOS...${NC}"
    cd ../ios
    pod install
    echo -e "${GREEN}✓ iOS pods installed. Open RUPAYA.xcworkspace in Xcode${NC}"
fi

# Android setup (if Android Studio available)
if command -v android &> /dev/null; then
    echo -e "\n${YELLOW}Setting up Android...${NC}"
    cd ../android
    ./gradlew build
    echo -e "${GREEN}✓ Android project built${NC}"
fi

cd ..

echo -e "\n${GREEN}======================================"
echo "✓ RUPAYA setup complete!"
echo -e "======================================${NC}"
echo ""
echo "📝 Next steps:"
echo "1. Backend: http://localhost:3000 (running)"
echo "2. iOS: Open ios/RUPAYA.xcworkspace in Xcode"
echo "3. Android: Open android/ in Android Studio"
echo ""
echo "📚 Documentation:"
echo "   • API: /docs/API_DOCUMENTATION.md"
echo "   • Deployment: /docs/DEPLOYMENT.md"
echo "   • Security: /docs/SECURITY.md"
echo ""
echo "🧪 Run tests:"
echo "   cd backend && npm test"
echo ""
