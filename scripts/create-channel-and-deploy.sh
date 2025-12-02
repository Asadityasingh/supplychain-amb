#!/bin/bash
set -e

PEER_ENDPOINT="nd-xaiao3kjsvd7hjur5a6rpfhl6i.m-i5mmo373lffuthpslbocegjrkm.n-ozfgrzjblfgavhtmceacicx35u.managedblockchain.us-east-1.amazonaws.com:30003"
ORDERER_ENDPOINT="orderer.n-ozfgrzjblfgavhtmceacicx35u.managedblockchain.us-east-1.amazonaws.com:30001"
CHANNEL_NAME="mychannel"
CHAINCODE_NAME="supplychain"
MSP_ID="Org1MSP"
WORK_DIR="/home/ec2-user/fabric-certs"
S3_BUCKET="supplychain-certs-1764607411"

cd $WORK_DIR

echo "📦 Step 1: Creating channel..."

# Create channel
docker run --rm -v $(pwd):/data \
  -e CORE_PEER_TLS_ENABLED=true \
  -e CORE_PEER_LOCALMSPID=$MSP_ID \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/data/peer-tls-cert.pem \
  -e CORE_PEER_ADDRESS=$PEER_ENDPOINT \
  -e CORE_PEER_MSPCONFIGPATH=/data/admin-msp \
  hyperledger/fabric-tools:2.2 \
  peer channel create \
  -o $ORDERER_ENDPOINT \
  -c $CHANNEL_NAME \
  -f /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/channel.tx \
  --outputBlock /data/mychannel.block \
  --tls \
  --cafile /data/ca-cert-full.pem 2>&1 || echo "Channel might already exist"

echo "✅ Channel created"

echo "📦 Step 2: Joining peer to channel..."

# Join channel
docker run --rm -v $(pwd):/data \
  -e CORE_PEER_TLS_ENABLED=true \
  -e CORE_PEER_LOCALMSPID=$MSP_ID \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/data/peer-tls-cert.pem \
  -e CORE_PEER_ADDRESS=$PEER_ENDPOINT \
  -e CORE_PEER_MSPCONFIGPATH=/data/admin-msp \
  hyperledger/fabric-tools:2.2 \
  peer channel join \
  -b /data/mychannel.block

echo "✅ Peer joined channel"

echo "📦 Step 3: Downloading chaincode..."
aws s3 cp s3://$S3_BUCKET/chaincode/ ./chaincode/ --recursive --region us-east-1

echo "📦 Step 4: Packaging chaincode..."
cd chaincode/supplychain-js && npm install && cd ../..

docker run --rm -v $(pwd):/data hyperledger/fabric-tools:2.2 \
  peer lifecycle chaincode package /data/supplychain.tar.gz \
  --path /data/chaincode/supplychain-js \
  --lang node \
  --label supplychain_1.0

echo "✅ Chaincode packaged"

echo "📦 Step 5: Installing chaincode..."
docker run --rm -v $(pwd):/data \
  -e CORE_PEER_TLS_ENABLED=true \
  -e CORE_PEER_LOCALMSPID=$MSP_ID \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/data/peer-tls-cert.pem \
  -e CORE_PEER_ADDRESS=$PEER_ENDPOINT \
  -e CORE_PEER_MSPCONFIGPATH=/data/admin-msp \
  hyperledger/fabric-tools:2.2 \
  peer lifecycle chaincode install /data/supplychain.tar.gz

echo "✅ Chaincode installed"

echo "📦 Step 6: Getting package ID..."
PACKAGE_ID=$(docker run --rm -v $(pwd):/data \
  -e CORE_PEER_TLS_ENABLED=true \
  -e CORE_PEER_LOCALMSPID=$MSP_ID \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/data/peer-tls-cert.pem \
  -e CORE_PEER_ADDRESS=$PEER_ENDPOINT \
  -e CORE_PEER_MSPCONFIGPATH=/data/admin-msp \
  hyperledger/fabric-tools:2.2 \
  peer lifecycle chaincode queryinstalled | grep supplychain_1.0 | sed 's/.*Package ID: \(.*\), Label.*/\1/')

echo "Package ID: $PACKAGE_ID"

echo "📦 Step 7: Approving chaincode..."
docker run --rm -v $(pwd):/data \
  -e CORE_PEER_TLS_ENABLED=true \
  -e CORE_PEER_LOCALMSPID=$MSP_ID \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/data/peer-tls-cert.pem \
  -e CORE_PEER_ADDRESS=$PEER_ENDPOINT \
  -e CORE_PEER_MSPCONFIGPATH=/data/admin-msp \
  hyperledger/fabric-tools:2.2 \
  peer lifecycle chaincode approveformyorg \
  --channelID $CHANNEL_NAME \
  --name $CHAINCODE_NAME \
  --version 1.0 \
  --package-id $PACKAGE_ID \
  --sequence 1 \
  --tls \
  --cafile /data/ca-cert-full.pem \
  --orderer $ORDERER_ENDPOINT

echo "✅ Chaincode approved"

echo "📦 Step 8: Committing chaincode..."
docker run --rm -v $(pwd):/data \
  -e CORE_PEER_TLS_ENABLED=true \
  -e CORE_PEER_LOCALMSPID=$MSP_ID \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/data/peer-tls-cert.pem \
  -e CORE_PEER_ADDRESS=$PEER_ENDPOINT \
  -e CORE_PEER_MSPCONFIGPATH=/data/admin-msp \
  hyperledger/fabric-tools:2.2 \
  peer lifecycle chaincode commit \
  --channelID $CHANNEL_NAME \
  --name $CHAINCODE_NAME \
  --version 1.0 \
  --sequence 1 \
  --tls \
  --cafile /data/ca-cert-full.pem \
  --orderer $ORDERER_ENDPOINT \
  --peerAddresses $PEER_ENDPOINT \
  --tlsRootCertFiles /data/peer-tls-cert.pem

echo "✅ Chaincode committed!"
echo ""
echo "🎉 Channel created and chaincode deployed successfully!"
