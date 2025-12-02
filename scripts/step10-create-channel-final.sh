#!/bin/bash
set -e

echo "=========================================="
echo "Step 10: Create Channel (Final)"
echo "=========================================="

NETWORK_ID="n-FQYK2HY5WRCQBFUDCKAKQDLU3A"
MEMBER_ID="m-7WUFYVVHYZEATNPNU4PHTW7KCM"
PEER_NODE_ID="nd-MNQIEPJFW5EKBPZSDE73VCWA6M"

ORDERER_ENDPOINT="orderer.${NETWORK_ID,,}.managedblockchain.us-east-1.amazonaws.com:30001"
PEER_ENDPOINT="${PEER_NODE_ID,,}.${MEMBER_ID,,}.${NETWORK_ID,,}.managedblockchain.us-east-1.amazonaws.com:30003"

WORK_DIR="/home/ec2-user/fabric-certs-v2"
cd $WORK_DIR

CHANNEL_NAME="mychannel"

# Create configtx.yaml
echo ""
echo "Creating configtx.yaml..."
cat > configtx.yaml << 'EOFCONFIG'
Capabilities:
  Channel: &ChannelCapabilities
    V2_0: true
  Orderer: &OrdererCapabilities
    V2_0: true
  Application: &ApplicationCapabilities
    V2_0: true

Organizations:
  - &Org1
    Name: m-7WUFYVVHYZEATNPNU4PHTW7KCM
    ID: m-7WUFYVVHYZEATNPNU4PHTW7KCM
    MSPDir: /data/admin-msp
    Policies:
      Readers:
        Type: Signature
        Rule: "OR('m-7WUFYVVHYZEATNPNU4PHTW7KCM.member')"
      Writers:
        Type: Signature
        Rule: "OR('m-7WUFYVVHYZEATNPNU4PHTW7KCM.member')"
      Admins:
        Type: Signature
        Rule: "OR('m-7WUFYVVHYZEATNPNU4PHTW7KCM.admin')"
      Endorsement:
        Type: Signature
        Rule: "OR('m-7WUFYVVHYZEATNPNU4PHTW7KCM.member')"

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
    <<: *ApplicationCapabilities

Profiles:
  OneOrgChannel:
    Consortium: AWSSystemConsortium
    Application:
      <<: *ApplicationDefaults
      Organizations:
        - *Org1
EOFCONFIG

echo "✓ configtx.yaml created"

# Generate channel config
echo ""
echo "Generating channel configuration..."
sudo docker run --rm \
  -v $(pwd):/data \
  -e FABRIC_CFG_PATH=/data \
  hyperledger/fabric-tools:2.2 \
  configtxgen -profile OneOrgChannel \
    -outputCreateChannelTx /data/${CHANNEL_NAME}.pb \
    -channelID ${CHANNEL_NAME}

sudo chown ec2-user:ec2-user ${CHANNEL_NAME}.pb
echo "✓ ${CHANNEL_NAME}.pb created"

# Create channel
echo ""
echo "Creating channel..."
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

# Join peer
echo ""
echo "Joining peer..."
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
echo "Channels joined:"
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
echo "✅ Channel ready! Run step7 to approve/commit chaincode."
