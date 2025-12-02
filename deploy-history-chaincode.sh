#!/bin/bash

# Deploy chaincode with History support to AWS Managed Blockchain
# Run this script on EC2 instance

set -e

echo "🚀 Deploying chaincode with History support..."

cd ~/fabric-samples/asset-transfer-basic/chaincode-go

# Vendor dependencies
echo "📦 Vendoring dependencies..."
go mod vendor

# Package chaincode as supplychain-v2
echo "📦 Packaging chaincode..."
peer lifecycle chaincode package supplychain-v2.tar.gz \
  --path . \
  --lang golang \
  --label supplychain-v2_1.0

# Install on peer
echo "📥 Installing chaincode on peer..."
peer lifecycle chaincode install supplychain-v2.tar.gz

# Get package ID
echo "🔍 Getting package ID..."
peer lifecycle chaincode queryinstalled

# Instantiate new chaincode
echo "🎯 Instantiating chaincode on channel..."
peer chaincode instantiate \
  -o orderer.n-cfcacd47iza7dalldsyz32fuzy.managedblockchain.us-east-1.amazonaws.com:30001 \
  --tls --cafile ~/managedblockchain-tls-chain.pem \
  -C mychannel \
  -n supplychain-v2 \
  -v 1.0 \
  -c '{"Args":[]}' \
  -P "OR('m-KTGJMTI7HFGTZKU7ECMPS4FQUU.member')"

echo "⏳ Waiting 30 seconds for chaincode to be ready..."
sleep 30

# Test: Create asset
echo "✅ Testing: Creating asset..."
peer chaincode invoke \
  -o orderer.n-cfcacd47iza7dalldsyz32fuzy.managedblockchain.us-east-1.amazonaws.com:30001 \
  --tls --cafile ~/managedblockchain-tls-chain.pem \
  -C mychannel \
  -n supplychain-v2 \
  -c '{"Args":["CreateAsset","HISTORY-TEST-FINAL","Laptop Shipment","Mumbai","Sarthak"]}'

sleep 5

# Test: Query asset
echo "🔍 Testing: Querying asset..."
peer chaincode query -C mychannel -n supplychain-v2 -c '{"Args":["ReadAsset","HISTORY-TEST-FINAL"]}'

echo ""
echo "✅ Testing: Transferring asset..."
peer chaincode invoke \
  -o orderer.n-cfcacd47iza7dalldsyz32fuzy.managedblockchain.us-east-1.amazonaws.com:30001 \
  --tls --cafile ~/managedblockchain-tls-chain.pem \
  -C mychannel \
  -n supplychain-v2 \
  -c '{"Args":["TransferAsset","HISTORY-TEST-FINAL","Suven","Delhi"]}'

sleep 5

echo "🔍 Testing: Querying asset after transfer..."
peer chaincode query -C mychannel -n supplychain-v2 -c '{"Args":["ReadAsset","HISTORY-TEST-FINAL"]}'

echo ""
echo "✅ Testing: Second transfer..."
peer chaincode invoke \
  -o orderer.n-cfcacd47iza7dalldsyz32fuzy.managedblockchain.us-east-1.amazonaws.com:30001 \
  --tls --cafile ~/managedblockchain-tls-chain.pem \
  -C mychannel \
  -n supplychain-v2 \
  -c '{"Args":["TransferAsset","HISTORY-TEST-FINAL","Aditya","Bangalore"]}'

sleep 5

echo "🔍 Testing: Final query with full history..."
peer chaincode query -C mychannel -n supplychain-v2 -c '{"Args":["ReadAsset","HISTORY-TEST-FINAL"]}'

echo ""
echo "🎉 Deployment complete!"
echo "📝 Next step: Update Lambda CHAINCODE_NAME environment variable to 'supplychain-v2'"
