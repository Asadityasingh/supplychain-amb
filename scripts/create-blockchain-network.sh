#!/bin/bash
set -e

REGION="us-east-1"
NETWORK_NAME="supplychain-fabric-v2"
MEMBER_NAME="Org1"
ADMIN_PASSWORD="Blockchain@2025"  # Strong password we'll remember
VPC_ID="vpc-04f8c3e5590d02480"
SUBNET_ID="subnet-0d38c80717a1ade86"
SECURITY_GROUP="sg-035d562b317e7ccb2"

echo "🚀 Creating new AWS Managed Blockchain network..."

# Create network
NETWORK_ID=$(aws managedblockchain create-network \
  --name "$NETWORK_NAME" \
  --description "Supply Chain Blockchain Tracker v2" \
  --framework HYPERLEDGER_FABRIC \
  --framework-version 2.2 \
  --framework-configuration '{
    "Fabric": {
      "Edition": "STARTER"
    }
  }' \
  --voting-policy '{
    "ApprovalThresholdPolicy": {
      "ThresholdPercentage": 50,
      "ProposalDurationInHours": 24,
      "ThresholdComparator": "GREATER_THAN"
    }
  }' \
  --member-configuration '{
    "Name": "'"$MEMBER_NAME"'",
    "Description": "Supply Chain Manufacturer Org",
    "FrameworkConfiguration": {
      "Fabric": {
        "AdminUsername": "admin",
        "AdminPassword": "'"$ADMIN_PASSWORD"'"
      }
    },
    "LogPublishingConfiguration": {
      "Fabric": {
        "CaLogs": {
          "Cloudwatch": {
            "Enabled": false
          }
        }
      }
    }
  }' \
  --region $REGION \
  --query 'NetworkId' \
  --output text)

echo "✅ Network created: $NETWORK_ID"
echo "⏳ Waiting for network to be available..."

# Wait for network
for i in {1..60}; do
  STATUS=$(aws managedblockchain get-network --network-id $NETWORK_ID --region $REGION --query 'Network.Status' --output text)
  echo "Status: $STATUS"
  if [ "$STATUS" = "AVAILABLE" ]; then
    echo "✅ Network is available!"
    break
  fi
  sleep 10
done

# Get member ID
MEMBER_ID=$(aws managedblockchain list-members --network-id $NETWORK_ID --region $REGION --query 'Members[0].Id' --output text)

echo "✅ Member created: $MEMBER_ID"
echo "⏳ Waiting for member to be available..."

# Wait for member
for i in {1..60}; do
  STATUS=$(aws managedblockchain get-member --network-id $NETWORK_ID --member-id $MEMBER_ID --region $REGION --query 'Member.Status' --output text)
  echo "Status: $STATUS"
  if [ "$STATUS" = "AVAILABLE" ]; then
    echo "✅ Member is available!"
    break
  fi
  sleep 10
done

# Create peer nodes
echo "🚀 Creating peer node 1..."
PEER1_ID=$(aws managedblockchain create-node \
  --network-id $NETWORK_ID \
  --member-id $MEMBER_ID \
  --node-configuration '{
    "InstanceType": "bc.t3.small",
    "AvailabilityZone": "us-east-1a",
    "LogPublishingConfiguration": {
      "Fabric": {
        "ChaincodeLogs": {"Cloudwatch": {"Enabled": false}},
        "PeerLogs": {"Cloudwatch": {"Enabled": false}}
      }
    }
  }' \
  --region $REGION \
  --query 'NodeId' \
  --output text)

echo "✅ Peer node 1 created: $PEER1_ID"

echo "🚀 Creating peer node 2..."
PEER2_ID=$(aws managedblockchain create-node \
  --network-id $NETWORK_ID \
  --member-id $MEMBER_ID \
  --node-configuration '{
    "InstanceType": "bc.t3.small",
    "AvailabilityZone": "us-east-1b",
    "LogPublishingConfiguration": {
      "Fabric": {
        "ChaincodeLogs": {"Cloudwatch": {"Enabled": false}},
        "PeerLogs": {"Cloudwatch": {"Enabled": false}}
      }
    }
  }' \
  --region $REGION \
  --query 'NodeId' \
  --output text)

echo "✅ Peer node 2 created: $PEER2_ID"

# Get endpoints
CA_ENDPOINT=$(aws managedblockchain get-member --network-id $NETWORK_ID --member-id $MEMBER_ID --region $REGION --query 'Member.FrameworkAttributes.Fabric.CaEndpoint' --output text)
PEER1_ENDPOINT=$(aws managedblockchain get-node --network-id $NETWORK_ID --member-id $MEMBER_ID --node-id $PEER1_ID --region $REGION --query 'Node.FrameworkAttributes.Fabric.PeerEndpoint' --output text)
ORDERER_ENDPOINT=$(aws managedblockchain get-network --network-id $NETWORK_ID --region $REGION --query 'Network.FrameworkAttributes.Fabric.OrderingServiceEndpoint' --output text)

echo ""
echo "🎉 Blockchain network created successfully!"
echo ""
echo "📋 Network Details:"
echo "  Network ID: $NETWORK_ID"
echo "  Member ID: $MEMBER_ID"
echo "  Peer 1 ID: $PEER1_ID"
echo "  Peer 2 ID: $PEER2_ID"
echo ""
echo "📋 Endpoints:"
echo "  CA: $CA_ENDPOINT"
echo "  Peer: $PEER1_ENDPOINT"
echo "  Orderer: $ORDERER_ENDPOINT"
echo ""
echo "🔐 Admin Credentials:"
echo "  Username: admin"
echo "  Password: $ADMIN_PASSWORD"
echo ""
echo "Save these details!"

# Save to file
cat > blockchain-config.txt << EOF
NETWORK_ID=$NETWORK_ID
MEMBER_ID=$MEMBER_ID
PEER1_ID=$PEER1_ID
PEER2_ID=$PEER2_ID
CA_ENDPOINT=$CA_ENDPOINT
PEER_ENDPOINT=$PEER1_ENDPOINT
ORDERER_ENDPOINT=$ORDERER_ENDPOINT
ADMIN_USERNAME=admin
ADMIN_PASSWORD=$ADMIN_PASSWORD
MSP_ID=Org1MSP
EOF

echo "✅ Configuration saved to blockchain-config.txt"
