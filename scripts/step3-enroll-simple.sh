#!/bin/bash
set -e

echo "=========================================="
echo "Step 3: Enroll Admin (Simple)"
echo "=========================================="

NETWORK_ID="n-CFCACD47IZA7DALLDSYZ32FUZY"
MEMBER_ID="m-KTGJMTI7HFGTZKU7ECMPS4FQUU"
PEER_NODE_ID="nd-ZQX2IJVXHBCWZOTRY5KXM2KDVA"
ADMIN_PASSWORD="Admin12345678"

CA_ENDPOINT="ca.${MEMBER_ID,,}.${NETWORK_ID,,}.managedblockchain.us-east-1.amazonaws.com:30002"
PEER_ENDPOINT="${PEER_NODE_ID,,}.${MEMBER_ID,,}.${NETWORK_ID,,}.managedblockchain.us-east-1.amazonaws.com:30003"

WORK_DIR="/home/ec2-user/fabric-certs-standard"
cd $WORK_DIR

# Step 1: Get fresh CA certificate
echo ""
echo "Step 1: Getting CA certificate..."
openssl s_client -connect ${CA_ENDPOINT} -showcerts < /dev/null 2>/dev/null | \
  awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/' > ca-cert-chain.pem
echo "✓ CA certificate saved"

# Step 2: Clean and enroll
echo ""
echo "Step 2: Enrolling admin..."
sudo rm -rf admin-msp
sudo docker run --rm -v $(pwd):/data hyperledger/fabric-ca:1.5 \
  fabric-ca-client enroll \
  -u https://admin:${ADMIN_PASSWORD}@${CA_ENDPOINT} \
  --tls.certfiles /data/ca-cert-chain.pem \
  -M /data/admin-msp

sudo chown -R ec2-user:ec2-user admin-msp/

# Step 3: Create config.yaml
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

# Step 4: Get peer TLS cert
echo ""
echo "Step 4: Getting peer TLS certificate..."
openssl s_client -connect ${PEER_ENDPOINT} -showcerts < /dev/null 2>/dev/null | \
  awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/' > peer-tls-cert.pem
echo "✓ Peer TLS certificate saved"

# Step 5: Verify structure
echo ""
echo "Step 5: MSP structure:"
find admin-msp/ -type f

# Step 6: Upload to S3
echo ""
echo "Step 6: Uploading to S3..."
aws s3 cp admin-msp/ s3://supplychain-certs-1764607411/certificates-v2/admin-msp/ --recursive --region us-east-1
aws s3 cp ca-cert-chain.pem s3://supplychain-certs-1764607411/certificates-v2/ca-cert.pem --region us-east-1
aws s3 cp peer-tls-cert.pem s3://supplychain-certs-1764607411/certificates-v2/peer-tls-cert.pem --region us-east-1

echo ""
echo "✅ Enrollment complete! Certificates uploaded to S3."
echo ""
echo "Next: Create channel and deploy chaincode"
