#!/bin/bash
set -e

echo "=========================================="
echo "Step 9: Create Channel (Fixed Config)"
echo "=========================================="

NETWORK_ID="n-FQYK2HY5WRCQBFUDCKAKQDLU3A"
MEMBER_ID="m-7WUFYVVHYZEATNPNU4PHTW7KCM"
PEER_NODE_ID="nd-MNQIEPJFW5EKBPZSDE73VCWA6M"

ORDERER_ENDPOINT="orderer.${NETWORK_ID,,}.managedblockchain.us-east-1.amazonaws.com:30001"
PEER_ENDPOINT="${PEER_NODE_ID,,}.${MEMBER_ID,,}.${NETWORK_ID,,}.managedblockchain.us-east-1.amazonaws.com:30003"

WORK_DIR="/home/ec2-user/fabric-certs-v2"
cd $WORK_DIR

CHANNEL_NAME="mychannel"

# Step 1: Create complete configtx.yaml with policies
echo ""
echo "Step 1: Creating configtx.yaml with policies..."
cat > configtx.yaml << EOF
Organizations:
  - &Org1
    Name: ${MEMBER_ID}
    ID: ${MEMBER_ID}
    MSPDir: /data/admin-msp
    Policies:
      Readers:
        Type: Signature
        Rule: "OR('${MEMBER_ID}.member')"
      Writers:
        Type: Signature
        Rule: "OR('${MEMBER_ID}.member')"
      Admins:
        Type: Signature
        Rule: "OR('${MEMBER_ID}.admin')"
      Endorsement:
        Type: Signature
        Rule: "OR('${MEMBER_ID}.member')"
    AnchorPeers:
      - Host: ${PEER_ENDPOINT}
        Port: 30003

Application: &ApplicationDefaults
  Organizations:
  Policies:
    Readers:
      Type: ImplicitMeta
      Rule: "ANY Readers"
    Writers:
      Type: ImplicitMeta
      Rule: "ANY Writers"
    Admins:
      Type: ImplicitMeta
      Rule: "MAJORITY Admins"
    LifecycleEndorsement:
      Type: ImplicitMeta
      Rule: "MAJORITY Endorsement"
    Endorsement:
      Type: ImplicitMeta
      Rule: "MAJORITY Endorsement"
  Capabilities:
    V2_0: true

Profiles:
  OneOrgChannel:
    Consortium: AWSSystemConsortium
    Application:
      <<: *ApplicationDefaults
      Organizations:
        - *Org1
      Capabilities:
        <<: *ApplicationCapabilities
    Capabilities:
      V2_0: true

Capabilities:
  ApplicationCapabilities: &ApplicationCapabilities
    V2_0: true
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
echo "✓ Channel config: ${CHANNEL_NAME}.pb"

# Step 3: Create channel
echo ""
echo "Step 3: Creating channel..."
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
echo "✓ Channel created"

# Step 4: Join peer
echo ""
echo "Step 4: Joining peer..."
sudo docker run --rm \
  -v $(pwd):/data \
  -e CORE_PEER_TLS_ENABLED=true \
  -e CORE_PEER_LOCALMSPID=${MEMBER_ID} \
  -e CORE_PEER_MSPCONFIGPATH=/data/admin-msp \
  -e CORE_PEER_ADDRESS=${PEER_ENDPOINT} \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/data/peer-tls-cert.pem \
  hyperledger/fabric-tools:2.2 \
  peer channel join -b /data/${CHANNEL_NAME}.block

# Step 5: Verify
echo ""
echo "Step 5: Verifying..."
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
echo "✅ Channel ready! Now approve/commit chaincode."
