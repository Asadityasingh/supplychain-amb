#!/bin/bash
set -e

echo "=========================================="
echo "Step 3: Enroll Admin & Setup Channel v2"
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

# Step 1: Get fresh CA certificate
echo ""
echo "Step 1: Retrieving fresh CA certificate..."
rm -f ca-cert-chain.pem
aws managedblockchain get-member \
  --network-id ${NETWORK_ID} \
  --member-id ${MEMBER_ID} \
  --region us-east-1 \
  --query 'Member.FrameworkAttributes.Fabric.CaEndpoint' \
  --output text

# Download CA cert using openssl
openssl s_client -connect ${CA_ENDPOINT} -showcerts < /dev/null 2>/dev/null | \
  awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/' > ca-cert-chain.pem

echo "CA certificate retrieved"
cat ca-cert-chain.pem

# Step 2: Clean up old certificates
echo ""
echo "Step 2: Cleaning up old admin certificates..."
sudo rm -rf admin-msp

# Step 3: Enroll admin (standard enrollment)
echo ""
echo "Step 3: Enrolling admin user..."
sudo docker run --rm -v $(pwd):/data hyperledger/fabric-ca:1.5 \
  fabric-ca-client enroll \
  -u https://admin:${ADMIN_PASSWORD}@${CA_ENDPOINT} \
  --tls.certfiles /data/ca-cert-chain.pem \
  -M /data/admin-msp

# Step 4: Fix permissions
echo ""
echo "Step 4: Fixing permissions..."
sudo chown -R ec2-user:ec2-user admin-msp/

# Step 5: Create MSP config.yaml
echo ""
echo "Step 5: Creating MSP config.yaml..."
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

# Step 6: Get peer TLS cert
echo ""
echo "Step 6: Getting peer TLS certificate..."
openssl s_client -connect ${PEER_ENDPOINT} -showcerts < /dev/null 2>/dev/null | \
  awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/' > peer-tls-cert.pem

# Step 7: Verify MSP structure
echo ""
echo "Step 7: Verifying MSP structure..."
echo "MSP directory structure:"
find admin-msp/ -type f

# Step 8: Upload to S3
echo ""
echo "Step 8: Uploading certificates to S3..."
aws s3 cp admin-msp/ s3://supplychain-certs-1764607411/certificates-v2/admin-msp/ --recursive --region us-east-1
aws s3 cp ca-cert-chain.pem s3://supplychain-certs-1764607411/certificates-v2/ca-cert.pem --region us-east-1
aws s3 cp peer-tls-cert.pem s3://supplychain-certs-1764607411/certificates-v2/peer-tls-cert.pem --region us-east-1

echo ""
echo "S3 contents:"
aws s3 ls s3://supplychain-certs-1764607411/certificates-v2/ --recursive --region us-east-1

echo ""
echo "=========================================="
echo "✅ Enrollment Complete!"
echo "=========================================="
echo ""
echo "Certificates are ready. Next: Create channel and deploy chaincode"
