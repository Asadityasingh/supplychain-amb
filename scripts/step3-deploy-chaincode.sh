#!/bin/bash
set -e

# Deploy chaincode to AWS Managed Blockchain
# Run this script ON the EC2 instance after certificates are retrieved

PEER_ENDPOINT="nd-xaiao3kjsvd7hjur5a6rpfhl6i.m-i5mmo373lffuthpslbocegjrkm.n-ozfgrzjblfgavhtmceacicx35u.managedblockchain.us-east-1.amazonaws.com:30003"
ORDERER_ENDPOINT="orderer.n-ozfgrzjblfgavhtmceacicx35u.managedblockchain.us-east-1.amazonaws.com:30001"
CHANNEL_NAME="mychannel"
CHAINCODE_NAME="supplychain"
CHAINCODE_VERSION="1.0"
MSP_ID="Org1MSP"
WORK_DIR="/home/ec2-user/fabric-certs"

cd $WORK_DIR

echo "📦 Deploying chaincode to blockchain..."

# Set environment variables
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID=$MSP_ID
export CORE_PEER_TLS_ROOTCERT_FILE=$WORK_DIR/peer-tls-cert.pem
export CORE_PEER_ADDRESS=$PEER_ENDPOINT
export CORE_PEER_MSPCONFIGPATH=$WORK_DIR/admin-msp
export ORDERER_CA=$WORK_DIR/ca-cert.pem

# Download chaincode from S3
echo "📥 Downloading chaincode..."
aws s3 cp s3://supplychain-certs-1764607411/chaincode/ ./chaincode/ --recursive --region us-east-1 || echo "Upload chaincode to S3 first"

# Package chaincode
echo "📦 Packaging chaincode..."
docker run --rm -v $(pwd):/data hyperledger/fabric-tools:2.2 \
  peer lifecycle chaincode package /data/supplychain.tar.gz \
  --path /data/chaincode/supplychain-js \
  --lang node \
  --label supplychain_1.0

# Install chaincode
echo "⚙️  Installing chaincode on peer..."
docker run --rm -v $(pwd):/data \
  -e CORE_PEER_TLS_ENABLED=$CORE_PEER_TLS_ENABLED \
  -e CORE_PEER_LOCALMSPID=$CORE_PEER_LOCALMSPID \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/data/peer-tls-cert.pem \
  -e CORE_PEER_ADDRESS=$CORE_PEER_ADDRESS \
  -e CORE_PEER_MSPCONFIGPATH=/data/admin-msp \
  hyperledger/fabric-tools:2.2 \
  peer lifecycle chaincode install /data/supplychain.tar.gz

echo "✅ Chaincode installed"

# Get package ID
PACKAGE_ID=$(docker run --rm -v $(pwd):/data \
  -e CORE_PEER_TLS_ENABLED=$CORE_PEER_TLS_ENABLED \
  -e CORE_PEER_LOCALMSPID=$CORE_PEER_LOCALMSPID \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/data/peer-tls-cert.pem \
  -e CORE_PEER_ADDRESS=$CORE_PEER_ADDRESS \
  -e CORE_PEER_MSPCONFIGPATH=/data/admin-msp \
  hyperledger/fabric-tools:2.2 \
  peer lifecycle chaincode queryinstalled | grep supplychain_1.0 | awk '{print $3}' | sed 's/,$//')

echo "📋 Package ID: $PACKAGE_ID"

# Approve chaincode
echo "✅ Approving chaincode..."
docker run --rm -v $(pwd):/data \
  -e CORE_PEER_TLS_ENABLED=$CORE_PEER_TLS_ENABLED \
  -e CORE_PEER_LOCALMSPID=$CORE_PEER_LOCALMSPID \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/data/peer-tls-cert.pem \
  -e CORE_PEER_ADDRESS=$CORE_PEER_ADDRESS \
  -e CORE_PEER_MSPCONFIGPATH=/data/admin-msp \
  hyperledger/fabric-tools:2.2 \
  peer lifecycle chaincode approveformyorg \
  --channelID $CHANNEL_NAME \
  --name $CHAINCODE_NAME \
  --version $CHAINCODE_VERSION \
  --package-id $PACKAGE_ID \
  --sequence 1 \
  --tls \
  --cafile /data/ca-cert.pem \
  --orderer $ORDERER_ENDPOINT

echo "✅ Chaincode approved"

# Commit chaincode
echo "🚀 Committing chaincode..."
docker run --rm -v $(pwd):/data \
  -e CORE_PEER_TLS_ENABLED=$CORE_PEER_TLS_ENABLED \
  -e CORE_PEER_LOCALMSPID=$CORE_PEER_LOCALMSPID \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/data/peer-tls-cert.pem \
  -e CORE_PEER_ADDRESS=$CORE_PEER_ADDRESS \
  -e CORE_PEER_MSPCONFIGPATH=/data/admin-msp \
  hyperledger/fabric-tools:2.2 \
  peer lifecycle chaincode commit \
  --channelID $CHANNEL_NAME \
  --name $CHAINCODE_NAME \
  --version $CHAINCODE_VERSION \
  --sequence 1 \
  --tls \
  --cafile /data/ca-cert.pem \
  --orderer $ORDERER_ENDPOINT \
  --peerAddresses $PEER_ENDPOINT \
  --tlsRootCertFiles /data/peer-tls-cert.pem

echo "✅ Chaincode deployed successfully!"
