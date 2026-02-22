#!/bin/bash
# iOS App Quick Start Script

set -e

# Add Ruby gems to PATH
export PATH="/opt/homebrew/opt/ruby/bin:/opt/homebrew/lib/ruby/gems/4.0.0/bin:$PATH"

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   RUPAYA iOS App - Quick Start${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check Prerequisites
echo -e "${YELLOW}Step 1: Checking Prerequisites${NC}"

if command -v xcodebuild &> /dev/null; then
  XCODE_VERSION=$(xcodebuild -version | head -1)
  echo -e "${GREEN}✓${NC} Xcode installed: $XCODE_VERSION"
else
  echo -e "${RED}✗${NC} Xcode not found. Please install from App Store."
  exit 1
fi

if command -v pod &> /dev/null; then
  POD_VERSION=$(pod --version)
  echo -e "${GREEN}✓${NC} CocoaPods installed: $POD_VERSION"
else
  echo -e "${YELLOW}⚠${NC} CocoaPods not installed. Installing..."
  sudo gem install cocoapods
fi

echo ""

# Check Backend
echo -e "${YELLOW}Step 2: Checking Backend${NC}"

if curl -s http://localhost:3000/health > /dev/null 2>&1; then
  echo -e "${GREEN}✓${NC} Backend is running at http://localhost:3000"
else
  echo -e "${RED}✗${NC} Backend not running!"
  echo -e "${YELLOW}Starting backend...${NC}"
  
  cd ../backend
  docker-compose -f docker-compose.dev.yml up -d
  
  echo "Waiting for backend to start..."
  sleep 10
  
  if curl -s http://localhost:3000/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Backend started successfully"
  else
    echo -e "${RED}✗${NC} Failed to start backend"
    exit 1
  fi
  
  cd ../ios
fi

echo ""

# Get Mac IP for physical device testing
echo -e "${YELLOW}Step 3: Network Configuration${NC}"
MAC_IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | head -1 | awk '{print $2}')
echo -e "${GREEN}ℹ${NC} Your Mac's IP address: ${YELLOW}$MAC_IP${NC}"
echo -e "${GREEN}ℹ${NC} For physical device, update APIConfig.swift with this IP"
echo ""

# Install Dependencies
echo -e "${YELLOW}Step 4: Installing iOS Dependencies${NC}"

if [ -f "Podfile" ]; then
  echo "Running pod install..."
  pod install
  echo -e "${GREEN}✓${NC} Dependencies installed"
else
  echo -e "${YELLOW}⚠${NC} No Podfile found, skipping..."
fi

echo ""

# List Available Simulators
echo -e "${YELLOW}Step 5: Available Simulators${NC}"
xcrun simctl list devices available | grep "iPhone" | head -5

echo ""

# Open Xcode
echo -e "${YELLOW}Step 6: Opening Xcode${NC}"

if [ -f "RUPAYA.xcworkspace" ]; then
  echo "Opening RUPAYA.xcworkspace..."
  open RUPAYA.xcworkspace
  echo -e "${GREEN}✓${NC} Xcode opened"
elif [ -f "RUPAYA.xcodeproj" ]; then
  echo "Opening RUPAYA.xcodeproj..."
  open RUPAYA.xcodeproj
  echo -e "${GREEN}✓${NC} Xcode opened"
else
  echo -e "${RED}✗${NC} No Xcode project found"
  exit 1
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✓ Setup Complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "  1. In Xcode, select a simulator (iPhone 15 Pro recommended)"
echo "  2. Press ${YELLOW}⌘ + R${NC} to build and run"
echo "  3. Test signup/login with backend at http://localhost:3000"
echo ""
echo -e "${BLUE}Useful Commands:${NC}"
echo "  • Backend logs: ${YELLOW}cd ../backend && docker-compose -f docker-compose.dev.yml logs -f backend${NC}"
echo "  • Stop backend:  ${YELLOW}cd ../backend && docker-compose -f docker-compose.dev.yml down${NC}"
echo "  • Reset pods:    ${YELLOW}pod deintegrate && pod install${NC}"
echo ""
echo -e "${BLUE}Testing Credentials:${NC}"
echo "  Email: test-ios@example.com"
echo "  Password: TestPass123"
echo ""
