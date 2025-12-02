#!/bin/bash
set -e

echo "=========================================="
echo "STANDARD Edition - Complete Setup"
echo "=========================================="

# STANDARD Network Details
NETWORK_ID="n-CFCACD47IZA7DALLDSYZ32FUZY"
MEMBER_ID="m-KTGJMTI7HFGTZKU7ECMPS4FQUU"
PEER_NODE_ID="nd-ZQX2UVXHBCWZOTRY5KXM2KDVA"  # Using first peer

CA_ENDPOINT="ca.${MEMBER_ID,,}.${NETWORK_ID,,}.managedblockchain.us-east-1.amazonaws.com:30002"
ORDERER_ENDPOINT="orderer.${NETWORK_ID,,}.managedblockchain.us-east-1.amazonaws.com:30001"
PEER_ENDPOINT="${PEER_NODE_ID,,}.${MEMBER_ID,,}.${NETWORK_ID,,}.managedblockchain.us-east-1.amazonaws.com:30003"

WORK_DIR="/home/ec2-user/fabric-certs-standard"
CHANNEL_NAME="mychannel"
ADMIN_PASSWORD="Admin12345678"

echo "Network ID: $NETWORK_ID"
echo "Member ID: $MEMBER_ID"
echo "Peer ID: $PEER_NODE_ID"
echo ""

# Create working directory
mkdir -p $WORK_DIR
cd $WORK_DIR

echo "Step 1: Getting CA certificate..."
openssl s_client -connect ${CA_ENDPOINT} -showcerts < /dev/null 2>/dev/null | \
  sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > ca-cert-chain.pem
echo "✓ CA cert saved"

echo ""
echo "Step 2: Enrolling admin..."
sudo docker run --rm -v $(pwd):/data hyperledger/fabric-ca:1.5 \
  fabric-ca-client enroll \
  -u https://admin:${ADMIN_PASSWORD}@${CA_ENDPOINT} \
  --tls.certfiles /data/ca-cert-chain.pem \
  -M /data/admin-msp

sudo chown -R ec2-user:ec2-user admin-msp/

echo ""
echo "Step 3: Creating MSP config..."
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

echo ""
echo "Step 4: Getting peer TLS cert..."
openssl s_client -connect ${PEER_ENDPOINT} -showcerts < /dev/null 2>/dev/null | \
  sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > peer-tls-cert.pem

echo ""
echo "Step 5: Getting orderer TLS cert..."
openssl s_client -connect ${ORDERER_ENDPOINT} -showcerts < /dev/null 2>/dev/null | \
  sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > orderer-tls-cert.pem

echo ""
echo "Step 6: Uploading certificates to S3..."
aws s3 cp admin-msp/ s3://supplychain-certs-1764607411/certificates-standard/admin-msp/ --recursive --region us-east-1
aws s3 cp ca-cert-chain.pem s3://supplychain-certs-1764607411/certificates-standard/ca-cert.pem --region us-east-1
aws s3 cp peer-tls-cert.pem s3://supplychain-certs-1764607411/certificates-standard/peer-tls-cert.pem --region us-east-1
aws s3 cp orderer-tls-cert.pem s3://supplychain-certs-1764607411/certificates-standard/orderer-tls-cert.pem --region us-east-1

echo ""
echo "Step 7: Downloading chaincode..."
aws s3 cp s3://supplychain-certs-1764607411/chaincode/supplychain-js/ chaincode/supplychain-js/ --recursive --region us-east-1

echo ""
echo "Step 8: Packaging chaincode..."
rm -rf chaincode-package
mkdir -p chaincode-package/src
cp -r chaincode/supplychain-js/* chaincode-package/src/

cat > chaincode-package/metadata.json << 'EOFMETA'
{
  "type": "node",
  "label": "supplychain_1.0"
}
EOFMETA

docker run --rm \
  -v $(pwd)/chaincode-package:/chaincode \
  -v $(pwd):/output \
  hyperledger/fabric-tools:2.2 \
  peer lifecycle chaincode package /output/supplychain.tar.gz \
    --path /chaincode/src \
    --lang node \
    --label supplychain_1.0

echo ""
echo "Step 9: Installing chaincode..."
docker run --rm \
  -v $(pwd):/data \
  -e CORE_PEER_TLS_ENABLED=true \
  -e CORE_PEER_LOCALMSPID=${MEMBER_ID} \
  -e CORE_PEER_MSPCONFIGPATH=/data/admin-msp \
  -e CORE_PEER_ADDRESS=${PEER_ENDPOINT} \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/data/peer-tls-cert.pem \
  hyperledger/fabric-tools:2.2 \
  peer lifecycle chaincode install /data/supplychain.tar.gz

docker run --rm \
  -v $(pwd):/data \
  -e CORE_PEER_TLS_ENABLED=true \
  -e CORE_PEER_LOCALMSPID=${MEMBER_ID} \
  -e CORE_PEER_MSPCONFIGPATH=/data/admin-msp \
  -e CORE_PEER_ADDRESS=${PEER_ENDPOINT} \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/data/peer-tls-cert.pem \
  hyperledger/fabric-tools:2.2 \
  peer lifecycle chaincode queryinstalled > installed.txt

PACKAGE_ID=$(grep "supplychain_1.0" installed.txt | awk '{print $3}' | sed 's/,$//')
echo "Package ID: $PACKAGE_ID"
echo "$PACKAGE_ID" > package_id.txt

echo ""
echo "=========================================="
echo "✅ Phase 1 Complete!"
echo "=========================================="
echo ""
echo "Certificates enrolled and uploaded"
echo "Chaincode packaged and installed"
echo ""
echo "Next: Create channel (will work on STANDARD!)"
echo ""
echo "Run: ./STANDARD-create-channel.sh"
