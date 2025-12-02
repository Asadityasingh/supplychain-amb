#!/bin/bash
set -e

echo "=========================================="
echo "Step 13: Create Channel (AWS Official Method)"
echo "=========================================="

NETWORK_ID="n-FQYK2HY5WRCQBFUDCKAKQDLU3A"
MEMBER_ID="m-7WUFYVVHYZEATNPNU4PHTW7KCM"
PEER_NODE_ID="nd-MNQIEPJFW5EKBPZSDE73VCWA6M"

ORDERER_ENDPOINT="orderer.${NETWORK_ID,,}.managedblockchain.us-east-1.amazonaws.com:30001"
PEER_ENDPOINT="${PEER_NODE_ID,,}.${MEMBER_ID,,}.${NETWORK_ID,,}.managedblockchain.us-east-1.amazonaws.com:30003"

WORK_DIR="/home/ec2-user/fabric-certs-v2"
cd $WORK_DIR

CHANNEL_NAME="mychannel"

# Step 1: Get orderer TLS cert
echo ""
echo "Step 1: Getting orderer TLS certificate..."
openssl s_client -connect ${ORDERER_ENDPOINT} -showcerts < /dev/null 2>/dev/null | \
  sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > orderer-tls-cert.pem
echo "✓ Orderer TLS cert saved"

# Step 2: Create configtx for AWS (simplified)
echo ""
echo "Step 2: Creating configtx.yaml..."
cat > configtx.yaml << EOF
Organizations:
  - &Org1
    Name: ${MEMBER_ID}
    ID: ${MEMBER_ID}
    MSPDir: /opt/home/admin-msp
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

# Step 3: Run configtxgen in Docker
echo ""
echo "Step 3: Generating channel configuration..."
docker run --rm \
  -e "FABRIC_CFG_PATH=/opt/home/" \
  -v "$PWD:/opt/home" \
  hyperledger/fabric-tools:2.2 \
  configtxgen -profile OneOrgChannel \
    -outputCreateChannelTx /opt/home/${CHANNEL_NAME}.pb \
    -channelID ${CHANNEL_NAME}

echo "✓ Channel config generated"

# Step 4: Create channel
echo ""
echo "Step 4: Creating channel..."
docker run --rm \
  -e "CORE_PEER_TLS_ENABLED=true" \
  -e "CORE_PEER_LOCALMSPID=${MEMBER_ID}" \
  -e "CORE_PEER_TLS_ROOTCERT_FILE=/opt/home/peer-tls-cert.pem" \
  -e "CORE_PEER_MSPCONFIGPATH=/opt/home/admin-msp" \
  -e "CORE_PEER_ADDRESS=${PEER_ENDPOINT}" \
  -v "$PWD:/opt/home" \
  hyperledger/fabric-tools:2.2 \
  peer channel create \
    -c ${CHANNEL_NAME} \
    -f /opt/home/${CHANNEL_NAME}.pb \
    -o ${ORDERER_ENDPOINT} \
    --cafile /opt/home/orderer-tls-cert.pem \
    --tls

echo "✓ Channel created"

# Step 5: Copy genesis block
cp ${CHANNEL_NAME}.block /opt/home/ 2>/dev/null || \
  docker run --rm -v "$PWD:/opt/home" hyperledger/fabric-tools:2.2 \
    cp /opt/home/${CHANNEL_NAME}.block /opt/home/

# Step 6: Join peer to channel
echo ""
echo "Step 5: Joining peer to channel..."
docker run --rm \
  -e "CORE_PEER_TLS_ENABLED=true" \
  -e "CORE_PEER_LOCALMSPID=${MEMBER_ID}" \
  -e "CORE_PEER_TLS_ROOTCERT_FILE=/opt/home/peer-tls-cert.pem" \
  -e "CORE_PEER_MSPCONFIGPATH=/opt/home/admin-msp" \
  -e "CORE_PEER_ADDRESS=${PEER_ENDPOINT}" \
  -v "$PWD:/opt/home" \
  hyperledger/fabric-tools:2.2 \
  peer channel join -b /opt/home/${CHANNEL_NAME}.block

echo ""
echo "Step 6: Verifying channel membership..."
docker run --rm \
  -e "CORE_PEER_TLS_ENABLED=true" \
  -e "CORE_PEER_LOCALMSPID=${MEMBER_ID}" \
  -e "CORE_PEER_TLS_ROOTCERT_FILE=/opt/home/peer-tls-cert.pem" \
  -e "CORE_PEER_MSPCONFIGPATH=/opt/home/admin-msp" \
  -e "CORE_PEER_ADDRESS=${PEER_ENDPOINT}" \
  -v "$PWD:/opt/home" \
  hyperledger/fabric-tools:2.2 \
  peer channel list

echo ""
echo "=========================================="
echo "✅ Channel Created & Peer Joined!"
echo "=========================================="
echo ""
echo "Next: Run step7 to approve and commit chaincode"
