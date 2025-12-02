#!/bin/bash
set -e

echo "=========================================="
echo "Step 7: Approve & Commit Chaincode"
echo "=========================================="

NETWORK_ID="n-CFCACD47IZA7DALLDSYZ32FUZY"
MEMBER_ID="m-KTGJMTI7HFGTZKU7ECMPS4FQUU"
PEER_NODE_ID="nd-ZQX2IJVXHBCWZOTRY5KXM2KDVA"

ORDERER_ENDPOINT="orderer.${NETWORK_ID,,}.managedblockchain.us-east-1.amazonaws.com:30001"
PEER_ENDPOINT="${PEER_NODE_ID,,}.${MEMBER_ID,,}.${NETWORK_ID,,}.managedblockchain.us-east-1.amazonaws.com:30003"

WORK_DIR="/home/ec2-user/fabric-certs-standard"
cd $WORK_DIR

CHANNEL_NAME="mychannel"
CHAINCODE_NAME="supplychain"
PACKAGE_ID=$(cat package_id.txt)

echo "Channel: $CHANNEL_NAME"
echo "Chaincode: $CHAINCODE_NAME"
echo "Package ID: $PACKAGE_ID"

# Step 1: Approve chaincode for organization
echo ""
echo "Step 1: Approving chaincode for organization..."
sudo docker run --rm \
  -v $(pwd):/data \
  -e CORE_PEER_TLS_ENABLED=true \
  -e CORE_PEER_LOCALMSPID=${MEMBER_ID} \
  -e CORE_PEER_MSPCONFIGPATH=/data/admin-msp \
  -e CORE_PEER_ADDRESS=${PEER_ENDPOINT} \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/data/peer-tls-cert.pem \
  hyperledger/fabric-tools:2.2 \
  peer lifecycle chaincode approveformyorg \
    --channelID ${CHANNEL_NAME} \
    --name ${CHAINCODE_NAME} \
    --version 1.0 \
    --package-id ${PACKAGE_ID} \
    --sequence 1 \
    --tls \
    --cafile /data/ca-cert-chain.pem \
    --orderer ${ORDERER_ENDPOINT}

# Step 2: Check commit readiness
echo ""
echo "Step 2: Checking commit readiness..."
sudo docker run --rm \
  -v $(pwd):/data \
  -e CORE_PEER_TLS_ENABLED=true \
  -e CORE_PEER_LOCALMSPID=${MEMBER_ID} \
  -e CORE_PEER_MSPCONFIGPATH=/data/admin-msp \
  -e CORE_PEER_ADDRESS=${PEER_ENDPOINT} \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/data/peer-tls-cert.pem \
  hyperledger/fabric-tools:2.2 \
  peer lifecycle chaincode checkcommitreadiness \
    --channelID ${CHANNEL_NAME} \
    --name ${CHAINCODE_NAME} \
    --version 1.0 \
    --sequence 1 \
    --tls \
    --cafile /data/ca-cert-chain.pem \
    --output json

# Step 3: Commit chaincode
echo ""
echo "Step 3: Committing chaincode to channel..."
sudo docker run --rm \
  -v $(pwd):/data \
  -e CORE_PEER_TLS_ENABLED=true \
  -e CORE_PEER_LOCALMSPID=${MEMBER_ID} \
  -e CORE_PEER_MSPCONFIGPATH=/data/admin-msp \
  -e CORE_PEER_ADDRESS=${PEER_ENDPOINT} \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/data/peer-tls-cert.pem \
  hyperledger/fabric-tools:2.2 \
  peer lifecycle chaincode commit \
    --channelID ${CHANNEL_NAME} \
    --name ${CHAINCODE_NAME} \
    --version 1.0 \
    --sequence 1 \
    --tls \
    --cafile /data/ca-cert-chain.pem \
    --orderer ${ORDERER_ENDPOINT} \
    --peerAddresses ${PEER_ENDPOINT} \
    --tlsRootCertFiles /data/peer-tls-cert.pem

# Step 4: Query committed chaincode
echo ""
echo "Step 4: Querying committed chaincode..."
sudo docker run --rm \
  -v $(pwd):/data \
  -e CORE_PEER_TLS_ENABLED=true \
  -e CORE_PEER_LOCALMSPID=${MEMBER_ID} \
  -e CORE_PEER_MSPCONFIGPATH=/data/admin-msp \
  -e CORE_PEER_ADDRESS=${PEER_ENDPOINT} \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/data/peer-tls-cert.pem \
  hyperledger/fabric-tools:2.2 \
  peer lifecycle chaincode querycommitted \
    --channelID ${CHANNEL_NAME} \
    --name ${CHAINCODE_NAME}

echo ""
echo "=========================================="
echo "✅ Chaincode Deployed!"
echo "=========================================="
echo ""
echo "Next: Test chaincode and update Lambda"
