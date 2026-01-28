#!/bin/bash
# API Testing Script

echo "🧪 Testing RUPAYA API Endpoints..."
echo ""

# Test 1: Health Check
echo "1️⃣  Testing health endpoint..."
HEALTH=$(curl -s http://localhost:3000/health)
echo "Response: $HEALTH"
echo ""

# Test 2: Signup
echo "2️⃣  Testing signup..."
SIGNUP=$(curl -s -X POST http://localhost:3000/api/v1/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "SecurePass123!@#",
    "deviceId": "test-device-1",
    "deviceName": "Test Device"
  }')
echo "Response: $SIGNUP"

# Extract token
TOKEN=$(echo "$SIGNUP" | grep -o '"accessToken":"[^"]*' | cut -d'"' -f4)
if [ -z "$TOKEN" ]; then
  echo "❌ Failed to get token"
  exit 1
fi
echo "✅ Token obtained: ${TOKEN:0:30}..."
echo ""

# Test 3: Create Account
echo "3️⃣  Testing account creation..."
ACCOUNT=$(curl -s -X POST http://localhost:3000/api/v1/accounts \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "My Checking Account",
    "account_type": "bank",
    "current_balance": 5000.00,
    "currency": "INR"
  }')
echo "Response: $ACCOUNT"
echo ""

# Test 4: List Accounts
echo "4️⃣  Testing account listing..."
ACCOUNTS=$(curl -s http://localhost:3000/api/v1/accounts \
  -H "Authorization: Bearer $TOKEN")
echo "Response: $ACCOUNTS"
echo ""

# Test 5: List Categories
echo "5️⃣  Testing category listing..."
CATEGORIES=$(curl -s "http://localhost:3000/api/v1/categories?type=expense" \
  -H "Authorization: Bearer $TOKEN")
echo "Response: $CATEGORIES"
echo ""

echo "✅ All tests completed!"
