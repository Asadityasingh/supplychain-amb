#!/bin/bash
set -e

echo "=========================================="
echo "Step 11: Create Channel (AWS Method)"
echo "=========================================="

NETWORK_ID="n-FQYK2HY5WRCQBFUDCKAKQDLU3A"
MEMBER_ID="m-7WUFYVVHYZEATNPNU4PHTW7KCM"
PEER_NODE_ID="nd-MNQIEPJFW5EKBPZSDE73VCWA6M"

ORDERER_ENDPOINT="orderer.${NETWORK_ID,,}.managedblockchain.us-east-1.amazonaws.com:30001"
PEER_ENDPOINT="${PEER_NODE_ID,,}.${MEMBER_ID,,}.${NETWORK_ID,,}.managedblockchain.us-east-1.amazonaws.com:30003"

WORK_DIR="/home/ec2-user/fabric-certs-v2"
cd $WORK_DIR

CHANNEL_NAME="mychannel"

echo "Network: $NETWORK_ID"
echo "Member: $MEMBER_ID"
echo "Peer: $PEER_NODE_ID"
echo "Channel: $CHANNEL_NAME"

# AWS Managed Blockchain uses system channel, just fetch and join
echo ""
echo "Step 1: Fetching channel genesis block from orderer..."
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
    --cafile /data/ca-cert-chain.pem

sudo chown ec2-user:ec2-user ${CHANNEL_NAME}.block 2>/dev/null || true

echo ""
echo "Step 2: Joining peer to channel..."
sudo docker run --rm \
  -v $(pwd):/data \
  -e CORE_PEER_TLS_ENABLED=true \
  -e CORE_PEER_LOCALMSPID=${MEMBER_ID} \
  -e CORE_PEER_MSPCONFIGPATH=/data/admin-msp \
  -e CORE_PEER_ADDRESS=${PEER_ENDPOINT} \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/data/peer-tls-cert.pem \
  hyperledger/fabric-tools:2.2 \
  peer channel join -b /data/${CHANNEL_NAME}.block

echo ""
echo "Step 3: Listing channels..."
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
echo "If channel doesn't exist, create via AWS:"
echo "aws managedblockchain create-proposal \\"
echo "  --network-id ${NETWORK_ID} \\"
echo "  --member-id ${MEMBER_ID} \\"
echo "  --actions '{\"Invitations\":[]}' \\"
echo "  --region us-east-1"
echo "=========================================="
