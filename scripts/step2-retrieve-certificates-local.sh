#!/bin/bash
set -e

CA_ENDPOINT="ca.m-i5mmo373lffuthpslbocegjrkm.n-ozfgrzjblfgavhtmceacicx35u.managedblockchain.us-east-1.amazonaws.com:30002"
PEER_ENDPOINT="nd-xaiao3kjsvd7hjur5a6rpfhl6i.m-i5mmo373lffuthpslbocegjrkm.n-ozfgrzjblfgavhtmceacicx35u.managedblockchain.us-east-1.amazonaws.com:30003"
S3_BUCKET="supplychain-certs-1764607411"
WORK_DIR="./fabric-certs"

echo "🔐 Retrieving blockchain certificates locally..."

mkdir -p $WORK_DIR
cd $WORK_DIR

echo "📥 Downloading CA TLS certificate..."
openssl s_client -connect $CA_ENDPOINT -showcerts < /dev/null 2>/dev/null | \
  sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > ca-cert.pem

if [ ! -s ca-cert.pem ]; then
    echo "❌ Failed to retrieve CA certificate"
    exit 1
fi
echo "✅ CA certificate saved"

echo "📝 Enrolling admin user..."
docker run --rm -v $(pwd):/data hyperledger/fabric-ca:1.5 \
  fabric-ca-client enroll \
  -u https://admin:AdminPassword@$CA_ENDPOINT \
  --tls.certfiles /data/ca-cert.pem \
  -M /data/admin-msp

if [ ! -d admin-msp ]; then
    echo "❌ Enrollment failed"
    exit 1
fi
echo "✅ Admin enrolled successfully"

echo "📥 Downloading peer TLS certificate..."
openssl s_client -connect $PEER_ENDPOINT -showcerts < /dev/null 2>/dev/null | \
  sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > peer-tls-cert.pem

echo "✅ Peer TLS certificate saved"

echo "☁️  Uploading certificates to S3..."
aws s3 cp admin-msp/ s3://$S3_BUCKET/certificates/admin-msp/ --recursive --region us-east-1
aws s3 cp ca-cert.pem s3://$S3_BUCKET/certificates/ca-cert.pem --region us-east-1
aws s3 cp peer-tls-cert.pem s3://$S3_BUCKET/certificates/peer-tls-cert.pem --region us-east-1

echo "✅ Certificates uploaded to S3"
echo ""
echo "📋 Certificate files saved in: $WORK_DIR"
