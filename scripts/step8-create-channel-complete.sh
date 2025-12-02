#!/bin/bash
set -e

echo "=========================================="
echo "Step 8: Create Channel (Complete Process)"
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

# Step 1: Create configtx.yaml
echo ""
echo "Step 1: Creating configtx.yaml..."
cat > configtx.yaml << EOF
Organizations:
  - &Org1
    Name: ${MEMBER_ID}
    ID: ${MEMBER_ID}
    MSPDir: /data/admin-msp
    AnchorPeers:
      - Host: ${PEER_ENDPOINT}
        Port: 30003

Application: &ApplicationDefaults
  Organizations:

Profiles:
  OneOrgChannel:
    Consortium: AWSSystemConsortium
    Application:
      <<: *ApplicationDefaults
      Organizations:
        - *Org1
EOF

echo "✓ configtx.yaml created"

# Step 2: Generate channel configuration
echo ""
echo "Step 2: Generating channel configuration..."
sudo docker run --rm \
  -v $(pwd):/data \
  -e FABRIC_CFG_PATH=/data \
  hyperledger/fabric-tools:2.2 \
  configtxgen -profile OneOrgChannel \
    -outputCreateChannelTx /data/${CHANNEL_NAME}.pb \
    -channelID ${CHANNEL_NAME}

sudo chown ec2-user:ec2-user ${CHANNEL_NAME}.pb
echo "✓ Channel config generated: ${CHANNEL_NAME}.pb"

# Step 3: Create channel
echo ""
echo "Step 3: Creating channel on orderer..."
sudo docker run --rm \
  -v $(pwd):/data \
  -e CORE_PEER_TLS_ENABLED=true \
  -e CORE_PEER_LOCALMSPID=${MEMBER_ID} \
  -e CORE_PEER_MSPCONFIGPATH=/data/admin-msp \
  -e CORE_PEER_ADDRESS=${PEER_ENDPOINT} \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/data/peer-tls-cert.pem \
  hyperledger/fabric-tools:2.2 \
  peer channel create \
    -c ${CHANNEL_NAME} \
    -f /data/${CHANNEL_NAME}.pb \
    -o ${ORDERER_ENDPOINT} \
    --tls \
    --cafile /data/ca-cert-chain.pem \
    --outputBlock /data/${CHANNEL_NAME}.block

sudo chown ec2-user:ec2-user ${CHANNEL_NAME}.block
echo "✓ Channel created: ${CHANNEL_NAME}.block"

# Step 4: Join peer to channel
echo ""
echo "Step 4: Joining peer to channel..."
sudo docker run --rm \
  -v $(pwd):/data \
  -e CORE_PEER_TLS_ENABLED=true \
  -e CORE_PEER_LOCALMSPID=${MEMBER_ID} \
  -e CORE_PEER_MSPCONFIGPATH=/data/admin-msp \
  -e CORE_PEER_ADDRESS=${PEER_ENDPOINT} \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/data/peer-tls-cert.pem \
  hyperledger/fabric-tools:2.2 \
  peer channel join \
    -b /data/${CHANNEL_NAME}.block

echo "✓ Peer joined channel"

# Step 5: List channels
echo ""
echo "Step 5: Verifying channel membership..."
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
echo "✅ Channel Created & Peer Joined!"
echo "=========================================="
echo ""
echo "Next: Approve and commit chaincode"
