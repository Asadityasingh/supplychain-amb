#!/bin/bash
set -e

echo "=========================================="
echo "Step 12: Get Orderer Cert & Create Channel"
echo "=========================================="

NETWORK_ID="n-FQYK2HY5WRCQBFUDCKAKQDLU3A"
MEMBER_ID="m-7WUFYVVHYZEATNPNU4PHTW7KCM"
PEER_NODE_ID="nd-MNQIEPJFW5EKBPZSDE73VCWA6M"

ORDERER_ENDPOINT="orderer.${NETWORK_ID,,}.managedblockchain.us-east-1.amazonaws.com:30001"
PEER_ENDPOINT="${PEER_NODE_ID,,}.${MEMBER_ID,,}.${NETWORK_ID,,}.managedblockchain.us-east-1.amazonaws.com:30003"

WORK_DIR="/home/ec2-user/fabric-certs-v2"
cd $WORK_DIR

CHANNEL_NAME="mychannel"

# Step 1: Get orderer TLS certificate
echo ""
echo "Step 1: Getting orderer TLS certificate..."
openssl s_client -connect ${ORDERER_ENDPOINT} -showcerts < /dev/null 2>/dev/null | \
  awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/' > orderer-tls-cert.pem

if [ ! -s orderer-tls-cert.pem ]; then
  echo "ERROR: Could not retrieve orderer TLS certificate"
  exit 1
fi

echo "✓ Orderer TLS cert saved"

# Step 2: Try to fetch existing channel
echo ""
echo "Step 2: Attempting to fetch channel block..."
sudo docker run --rm \
  -v $(pwd):/data \
  -e CORE_PEER_TLS_ENABLED=true \
  -e CORE_PEER_LOCALMSPID=${MEMBER_ID} \
  -e CORE_PEER_MSPCONFIGPATH=/data/admin-msp \
  -e CORE_PEER_ADDRESS=${PEER_ENDPOINT} \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/data/peer-tls-cert.pem \
  hyperledger/fabric-tools:2.2 \
  peer channel fetch 0 ${CHANNEL_NAME}.block \
    -c ${CHANNEL_NAME} \
    -o ${ORDERER_ENDPOINT} \
    --tls \
    --cafile /data/orderer-tls-cert.pem 2>&1 | tee fetch.log

if grep -q "Received block: 0" fetch.log; then
  echo "✓ Channel exists, fetched genesis block"
  sudo chown ec2-user:ec2-user ${CHANNEL_NAME}.block
  
  # Join peer
  echo ""
  echo "Step 3: Joining peer to channel..."
  sudo docker run --rm \
    -v $(pwd):/data \
    -e CORE_PEER_TLS_ENABLED=true \
    -e CORE_PEER_LOCALMSPID=${MEMBER_ID} \
    -e CORE_PEER_MSPCONFIGPATH=/data/admin-msp \
    -e CORE_PEER_ADDRESS=${PEER_ENDPOINT} \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/data/peer-tls-cert.pem \
    hyperledger/fabric-tools:2.2 \
    peer channel join -b /data/${CHANNEL_NAME}.block
  
  echo "✓ Peer joined channel"
else
  echo ""
  echo "⚠️  Channel does not exist yet."
  echo ""
  echo "AWS Managed Blockchain STARTER edition requires creating"
  echo "channels through AWS Console or API."
  echo ""
  echo "To create channel via AWS Console:"
  echo "1. Go to: https://console.aws.amazon.com/managedblockchain"
  echo "2. Select network: ${NETWORK_ID}"
  echo "3. Click 'Create channel'"
  echo "4. Name: ${CHANNEL_NAME}"
  echo "5. Add member: ${MEMBER_ID}"
  echo ""
  echo "After creating channel in console, run this script again."
fi

# List channels
echo ""
echo "Current channels:"
sudo docker run --rm \
  -v $(pwd):/data \
  -e CORE_PEER_TLS_ENABLED=true \
  -e CORE_PEER_LOCALMSPID=${MEMBER_ID} \
  -e CORE_PEER_MSPCONFIGPATH=/data/admin-msp \
  -e CORE_PEER_ADDRESS=${PEER_ENDPOINT} \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/data/peer-tls-cert.pem \
  hyperledger/fabric-tools:2.2 \
  peer channel list

echo ""
echo "=========================================="
echo "Next: If channel exists, run step7 to approve/commit chaincode"
echo "=========================================="
