#!/bin/bash
set -e

echo "=========================================="
echo "Step 4: Create Channel & Deploy Chaincode"
echo "=========================================="

NETWORK_ID="n-FQYK2HY5WRCQBFUDCKAKQDLU3A"
MEMBER_ID="m-7WUFYVVHYZEATNPNU4PHTW7KCM"
PEER_NODE_ID="nd-MNQIEPJFW5EKBPZSDE73VCWA6M"

CA_ENDPOINT="ca.${MEMBER_ID,,}.${NETWORK_ID,,}.managedblockchain.us-east-1.amazonaws.com:30002"
ORDERER_ENDPOINT="orderer.${NETWORK_ID,,}.managedblockchain.us-east-1.amazonaws.com:30001"
PEER_ENDPOINT="${PEER_NODE_ID,,}.${MEMBER_ID,,}.${NETWORK_ID,,}.managedblockchain.us-east-1.amazonaws.com:30003"

WORK_DIR="/home/ec2-user/fabric-certs-v2"
cd $WORK_DIR

echo "Working in: $WORK_DIR"

# Step 1: Download chaincode from S3
echo ""
echo "Step 1: Downloading chaincode..."
mkdir -p chaincode
aws s3 cp s3://supplychain-certs-1764607411/chaincode/supplychain-js/ chaincode/supplychain-js/ --recursive --region us-east-1

# Step 2: Package chaincode
echo ""
echo "Step 2: Packaging chaincode..."
cd chaincode/supplychain-js
tar czf ../../supplychain.tar.gz .
cd $WORK_DIR

# Step 3: Create channel (AWS Managed Blockchain handles this differently)
echo ""
echo "Step 3: Attempting to list channels..."
sudo docker run --rm \
  -v $(pwd):/data \
  -e CORE_PEER_TLS_ENABLED=true \
  -e CORE_PEER_LOCALMSPID=${MEMBER_ID} \
  -e CORE_PEER_MSPCONFIGPATH=/data/admin-msp \
  -e CORE_PEER_ADDRESS=${PEER_ENDPOINT} \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/data/peer-tls-cert.pem \
  hyperledger/fabric-tools:2.2 \
  peer channel list || echo "Channel list failed - may need to create channel first"

# Step 4: Install chaincode
echo ""
echo "Step 4: Installing chaincode on peer..."
sudo docker run --rm \
  -v $(pwd):/data \
  -e CORE_PEER_TLS_ENABLED=true \
  -e CORE_PEER_LOCALMSPID=${MEMBER_ID} \
  -e CORE_PEER_MSPCONFIGPATH=/data/admin-msp \
  -e CORE_PEER_ADDRESS=${PEER_ENDPOINT} \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/data/peer-tls-cert.pem \
  hyperledger/fabric-tools:2.2 \
  peer lifecycle chaincode install /data/supplychain.tar.gz || echo "Install may have failed"

# Step 5: Query installed chaincode
echo ""
echo "Step 5: Querying installed chaincode..."
sudo docker run --rm \
  -v $(pwd):/data \
  -e CORE_PEER_TLS_ENABLED=true \
  -e CORE_PEER_LOCALMSPID=${MEMBER_ID} \
  -e CORE_PEER_MSPCONFIGPATH=/data/admin-msp \
  -e CORE_PEER_ADDRESS=${PEER_ENDPOINT} \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/data/peer-tls-cert.pem \
  hyperledger/fabric-tools:2.2 \
  peer lifecycle chaincode queryinstalled

echo ""
echo "=========================================="
echo "✅ Setup Progress"
echo "=========================================="
echo ""
echo "Completed:"
echo "  ✓ Admin enrolled"
echo "  ✓ Certificates in S3"
echo "  ✓ Chaincode downloaded"
echo "  ✓ Chaincode packaged"
echo ""
echo "Note: AWS Managed Blockchain STARTER edition"
echo "uses a pre-configured channel. You may need to:"
echo "1. Use AWS Console to create channel 'mychannel'"
echo "2. Join peer to channel via console"
echo "3. Then approve and commit chaincode"
