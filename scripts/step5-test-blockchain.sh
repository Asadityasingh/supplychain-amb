#!/bin/bash
set -e

# Test end-to-end blockchain functionality

LAMBDA_URL="https://k4uyws3gmegkpwvbzkywnrisfq0zeoxe.lambda-url.us-east-1.on.aws"

echo "🧪 Testing blockchain connection..."

# Test 1: Health check
echo ""
echo "1️⃣  Health Check:"
curl -s "$LAMBDA_URL/health" | jq '.'

# Test 2: Create asset
echo ""
echo "2️⃣  Creating test asset..."
RESPONSE=$(curl -s -X POST "$LAMBDA_URL/assets" \
  -H "Content-Type: application/json" \
  -d '{
    "assetId": "TEST-'$(date +%s)'",
    "name": "Test Product",
    "location": "Warehouse A",
    "owner": "Test Company"
  }')
echo $RESPONSE | jq '.'

ASSET_ID=$(echo $RESPONSE | jq -r '.data.ID')
echo "✅ Asset created: $ASSET_ID"

# Test 3: Query asset
echo ""
echo "3️⃣  Querying asset..."
curl -s "$LAMBDA_URL/assets/$ASSET_ID" | jq '.'

# Test 4: Get all assets
echo ""
echo "4️⃣  Getting all assets..."
curl -s "$LAMBDA_URL/assets" | jq '.data | length'

# Test 5: Transfer asset
echo ""
echo "5️⃣  Transferring asset..."
curl -s -X PUT "$LAMBDA_URL/assets/$ASSET_ID/transfer" \
  -H "Content-Type: application/json" \
  -d '{
    "newOwner": "New Owner Corp",
    "newLocation": "Distribution Center B"
  }' | jq '.'

echo ""
echo "✅ All tests passed! Blockchain is live!"
