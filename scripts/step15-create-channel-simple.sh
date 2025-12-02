#!/bin/bash
set -e

echo "=========================================="
echo "Step 15: Create Channel (Simplified)"
echo "=========================================="

NETWORK_ID="n-CFCACD47IZA7DALLDSYZ32FUZY"
MEMBER_ID="m-KTGJMTI7HFGTZKU7ECMPS4FQUU"
PEER_NODE_ID="nd-ZQX2IJVXHBCWZOTRY5KXM2KDVA"

ORDERER_ENDPOINT="orderer.${NETWORK_ID,,}.managedblockchain.us-east-1.amazonaws.com:30001"
PEER_ENDPOINT="${PEER_NODE_ID,,}.${MEMBER_ID,,}.${NETWORK_ID,,}.managedblockchain.us-east-1.amazonaws.com:30003"

WORK_DIR="/home/ec2-user/fabric-certs-standard"
cd $WORK_DIR

CHANNEL_NAME="mychannel"

# Get orderer TLS cert
echo ""
echo "Getting orderer TLS certificate..."
openssl s_client -connect ${ORDERER_ENDPOINT} -showcerts < /dev/null 2>/dev/null | \
  sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > orderer-tls-cert.pem
echo "✓ Orderer TLS cert saved"

# Create simplified configtx.yaml
echo ""
echo "Creating configtx.yaml..."
cat > configtx.yaml << EOF
Organizations:
  - &Org1
    Name: ${MEMBER_ID}
    ID: ${MEMBER_ID}
    MSPDir: /opt/home/admin-msp
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

Channel: &ChannelDefaults
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

Profiles:
  OneOrgChannel:
    Consortium: AWSSystemConsortium
    <<: *ChannelDefaults
    Application:
      <<: *ApplicationDefaults
      Organizations:
        - *Org1
EOF

echo "✓ configtx.yaml created"

# Generate channel config
echo ""
echo "Generating channel configuration..."
docker run --rm \
  -e "FABRIC_CFG_PATH=/opt/home/" \
  -v "$PWD:/opt/home" \
  hyperledger/fabric-tools:2.2 \
  configtxgen -profile OneOrgChannel \
    -outputCreateChannelTx /opt/home/${CHANNEL_NAME}.pb \
    -channelID ${CHANNEL_NAME}

echo "✓ Channel config generated"

# Create channel
echo ""
echo "Creating channel..."
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

# Join peer
echo ""
echo "Joining peer to channel..."
docker run --rm \
  -e "CORE_PEER_TLS_ENABLED=true" \
  -e "CORE_PEER_LOCALMSPID=${MEMBER_ID}" \
  -e "CORE_PEER_TLS_ROOTCERT_FILE=/opt/home/peer-tls-cert.pem" \
  -e "CORE_PEER_MSPCONFIGPATH=/opt/home/admin-msp" \
  -e "CORE_PEER_ADDRESS=${PEER_ENDPOINT}" \
  -v "$PWD:/opt/home" \
  hyperledger/fabric-tools:2.2 \
  peer channel join -b /opt/home/${CHANNEL_NAME}.block

# Verify
echo ""
echo "Verifying channel membership..."
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
echo "✅ Channel created and peer joined!"
echo ""
echo "Next: Run step7 to approve/commit chaincode"
