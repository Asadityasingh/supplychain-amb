#!/bin/bash
set -e

echo "=========================================="
echo "Step 3: Enroll Admin & Setup Channel"
echo "=========================================="

# Network details
NETWORK_ID="n-FQYK2HY5WRCQBFUDCKAKQDLU3A"
MEMBER_ID="m-7WUFYVVHYZEATNPNU4PHTW7KCM"
PEER_NODE_ID="nd-MNQIEPJFW5EKBPZSDE73VCWA6M"
ADMIN_PASSWORD="Admin12345678"

CA_ENDPOINT="ca.${MEMBER_ID,,}.${NETWORK_ID,,}.managedblockchain.us-east-1.amazonaws.com:30002"
ORDERER_ENDPOINT="orderer.${NETWORK_ID,,}.managedblockchain.us-east-1.amazonaws.com:30001"
PEER_ENDPOINT="${PEER_NODE_ID,,}.${MEMBER_ID,,}.${NETWORK_ID,,}.managedblockchain.us-east-1.amazonaws.com:30003"

WORK_DIR="/home/ec2-user/fabric-certs-v2"
cd $WORK_DIR

echo "Working directory: $WORK_DIR"

# Step 1: Clean up old certificates
echo ""
echo "Step 1: Cleaning up old certificates..."
sudo rm -rf admin-msp

# Step 2: Enroll admin (standard enrollment, NOT TLS profile)
echo ""
echo "Step 2: Enrolling admin user (standard enrollment)..."
sudo docker run --rm -v $(pwd):/data hyperledger/fabric-ca:1.5 \
  fabric-ca-client enroll \
  -u https://admin:${ADMIN_PASSWORD}@${CA_ENDPOINT} \
  --tls.certfiles /data/ca-cert-chain.pem \
  -M /data/admin-msp

# Step 3: Fix permissions
echo ""
echo "Step 3: Fixing permissions..."
sudo chown -R ec2-user:ec2-user admin-msp/

# Step 4: Create MSP config.yaml
echo ""
echo "Step 4: Creating MSP config.yaml..."
cat > admin-msp/config.yaml << EOF
NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/ca-${MEMBER_ID,,}-${NETWORK_ID,,}-managedblockchain-us-east-1-amazonaws-com-30002.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/ca-${MEMBER_ID,,}-${NETWORK_ID,,}-managedblockchain-us-east-1-amazonaws-com-30002.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/ca-${MEMBER_ID,,}-${NETWORK_ID,,}-managedblockchain-us-east-1-amazonaws-com-30002.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/ca-${MEMBER_ID,,}-${NETWORK_ID,,}-managedblockchain-us-east-1-amazonaws-com-30002.pem
    OrganizationalUnitIdentifier: orderer
EOF

# Step 5: Verify MSP structure
echo ""
echo "Step 5: Verifying MSP structure..."
ls -la admin-msp/
echo ""
echo "MSP contents:"
find admin-msp/ -type f

# Step 6: Upload to S3
echo ""
echo "Step 6: Uploading certificates to S3..."
aws s3 cp admin-msp/ s3://supplychain-certs-1764607411/certificates-v2/admin-msp/ --recursive --region us-east-1
aws s3 cp ca-cert-chain.pem s3://supplychain-certs-1764607411/certificates-v2/ca-cert.pem --region us-east-1
aws s3 cp peer-tls-cert.pem s3://supplychain-certs-1764607411/certificates-v2/peer-tls-cert.pem --region us-east-1

echo ""
echo "S3 contents:"
aws s3 ls s3://supplychain-certs-1764607411/certificates-v2/ --recursive --region us-east-1

# Step 7: Create channel configuration
echo ""
echo "Step 7: Creating channel..."
sudo docker run --rm \
  -v $(pwd):/data \
  -e CORE_PEER_TLS_ENABLED=true \
  -e CORE_PEER_LOCALMSPID=m-7WUFYVVHYZEATNPNU4PHTW7KCM \
  -e CORE_PEER_MSPCONFIGPATH=/data/admin-msp \
  -e CORE_PEER_ADDRESS=${PEER_ENDPOINT} \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/data/peer-tls-cert.pem \
  hyperledger/fabric-tools:2.2 \
  peer channel create \
    -c mychannel \
    -f /data/mychannel.pb \
    -o ${ORDERER_ENDPOINT} \
    --tls \
    --cafile /data/ca-cert-chain.pem \
    --outputBlock /data/mychannel.block || echo "Channel may already exist or needs genesis block"

# Step 8: Join channel
echo ""
echo "Step 8: Joining peer to channel..."
sudo docker run --rm \
  -v $(pwd):/data \
  -e CORE_PEER_TLS_ENABLED=true \
  -e CORE_PEER_LOCALMSPID=m-7WUFYVVHYZEATNPNU4PHTW7KCM \
  -e CORE_PEER_MSPCONFIGPATH=/data/admin-msp \
  -e CORE_PEER_ADDRESS=${PEER_ENDPOINT} \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/data/peer-tls-cert.pem \
  hyperledger/fabric-tools:2.2 \
  peer channel join \
    -b /data/mychannel.block || echo "Peer may already be joined"

echo ""
echo "=========================================="
echo "✅ Setup Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Package and install chaincode"
echo "2. Update Lambda with certificates from S3"
echo "3. Test end-to-end flow"
