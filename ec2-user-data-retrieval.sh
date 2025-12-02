#!/bin/bash
set -e

BUCKET="supplychain-certs-1764607411"
CA_ENDPOINT="ca.m-i5mmo373lffuthpslbocegjrkm.n-ozfgrzjblfgavhtmceacicx35u.managedblockchain.us-east-1.amazonaws.com:30002"
ADMIN_USERNAME="admin"
ADMIN_PASSWORD="12345678"
WORK_DIR="/home/ubuntu/blockchain"

exec > >(tee -a /var/log/blockchain-setup.log)
exec 2>&1

echo "==================================="
echo "Starting blockchain certificate retrieval..."
echo "Timestamp: $(date)"
echo "==================================="

# Update system
echo "Step 1: Updating system packages..."
apt-get update -qq
apt-get install -y curl wget git jq openssl awscli

# Install Node.js
echo "Step 2: Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# Download and install Fabric CA Client
echo "Step 3: Installing Fabric CA Client..."
cd /tmp
wget -q https://github.com/hyperledger/fabric-ca/releases/download/v1.5.2/fabric-ca_linux-amd64-1.5.2.tar.gz
tar xzf fabric-ca_linux-amd64-1.5.2.tar.gz
mv bin/fabric-ca-client /usr/local/bin/
chmod +x /usr/local/bin/fabric-ca-client
fabric-ca-client version > /tmp/fabric-version.txt
echo "✅ Fabric CA Client installed"

# Create working directory
mkdir -p $WORK_DIR
cd $WORK_DIR

# Step 4: Retrieve CA TLS Certificate
echo "Step 4: Retrieving CA TLS Certificate..."
openssl s_client -connect $CA_ENDPOINT -showcerts < /dev/null 2>/dev/null | \
  sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > $WORK_DIR/ca-cert.pem

if [ -s $WORK_DIR/ca-cert.pem ]; then
  echo "✅ CA Certificate retrieved"
else
  echo "❌ Failed to retrieve CA certificate"
  exit 1
fi

# Step 5: Enroll admin user with CA
echo "Step 5: Enrolling admin user with Fabric CA..."
fabric-ca-client enroll \
  -u https://${ADMIN_USERNAME}:${ADMIN_PASSWORD}@${CA_ENDPOINT} \
  --tls.certfiles $WORK_DIR/ca-cert.pem \
  -M $WORK_DIR/fabric-admin-msp 2>&1 | tail -10

if [ -f "$WORK_DIR/fabric-admin-msp/signcerts/cert.pem" ]; then
  echo "✅ Admin enrollment successful"
else
  echo "❌ Enrollment failed"
  exit 1
fi

# Step 6: Extract certificates
echo "Step 6: Preparing certificates for upload..."
USER_CERT=$(cat $WORK_DIR/fabric-admin-msp/signcerts/cert.pem | base64 -w 0)
USER_PRIVATE_KEY=$(cat $WORK_DIR/fabric-admin-msp/keystore/*_sk | base64 -w 0)
TLS_CERT=$(cat $WORK_DIR/ca-cert.pem | base64 -w 0)

# Create JSON file with certificates
cat > $WORK_DIR/certificates.json <<EOF
{
  "userCert": "$USER_CERT",
  "userPrivateKey": "$USER_PRIVATE_KEY",
  "tlsCert": "$TLS_CERT",
  "caTlsCert": "",
  "timestamp": "$(date -Iseconds)",
  "adminUsername": "$ADMIN_USERNAME"
}
EOF

# Step 7: Upload to S3
echo "Step 7: Uploading certificates to S3..."
aws s3 cp $WORK_DIR/certificates.json s3://$BUCKET/certificates.json --region us-east-1
aws s3 cp $WORK_DIR/fabric-admin-msp/signcerts/cert.pem s3://$BUCKET/cert.pem --region us-east-1
aws s3 cp $WORK_DIR/fabric-admin-msp/keystore/*_sk s3://$BUCKET/private.key --region us-east-1

echo "✅ Certificates uploaded to S3://$BUCKET/"

# Step 8: Create status file
echo "Step 8: Creating status report..."
cat > $WORK_DIR/status.txt <<EOF
BLOCKCHAIN CERTIFICATE RETRIEVAL - SUCCESS
===========================================
Timestamp: $(date)
S3 Bucket: $BUCKET
CA Endpoint: $CA_ENDPOINT
Admin Username: $ADMIN_USERNAME
MSP ID: Org1MSP
Network ID: n-OZFGRZJBLFGAVHTMCEACICX35U

Files Available in S3:
- s3://$BUCKET/certificates.json (full credentials bundle)
- s3://$BUCKET/cert.pem (user certificate)
- s3://$BUCKET/private.key (private key)

Status: ✅ READY
Next Step: Download from S3 and upload to Lambda /certificates endpoint
EOF

aws s3 cp $WORK_DIR/status.txt s3://$BUCKET/status.txt --region us-east-1

echo ""
echo "==================================="
echo "✅ CERTIFICATE RETRIEVAL COMPLETE"
echo "==================================="
cat $WORK_DIR/status.txt
