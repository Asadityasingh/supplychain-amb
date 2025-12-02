#!/bin/bash
set -e

REGION="us-east-1"
NETWORK_NAME="supplychain-fabric-v2"
MEMBER_NAME="Org1"
ADMIN_PASSWORD="Blockchain@2025"

echo "🚀 Creating new AWS Managed Blockchain network..."

# Create network with member
NETWORK_ID=$(aws managedblockchain create-network \
  --cli-input-json '{
    "Name": "'"$NETWORK_NAME"'",
    "Description": "Supply Chain Blockchain Tracker v2",
    "Framework": "HYPERLEDGER_FABRIC",
    "FrameworkVersion": "2.2",
    "FrameworkConfiguration": {
      "Fabric": {
        "Edition": "STARTER"
      }
    },
    "VotingPolicy": {
      "ApprovalThresholdPolicy": {
        "ThresholdPercentage": 50,
        "ProposalDurationInHours": 24,
        "ThresholdComparator": "GREATER_THAN"
      }
    },
    "MemberConfiguration": {
      "Name": "'"$MEMBER_NAME"'",
      "Description": "Supply Chain Manufacturer Org",
      "FrameworkConfiguration": {
        "Fabric": {
          "AdminUsername": "admin",
          "AdminPassword": "'"$ADMIN_PASSWORD"'"
        }
      }
    }
  }' \
  --region $REGION \
  --query 'NetworkId' \
  --output text)

echo "✅ Network ID: $NETWORK_ID"
echo "⏳ Waiting for network (this takes 10-15 minutes)..."

sleep 60

echo "Network creation in progress. Check status with:"
echo "aws managedblockchain get-network --network-id $NETWORK_ID --region us-east-1"
echo ""
echo "Password: $ADMIN_PASSWORD"
