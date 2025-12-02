#!/bin/bash
set -e

# Complete blockchain setup script
# Run this on EC2 instance

NETWORK_ID="n-FQYK2HY5WRCQBFUDCKAKQDLU3A"
MEMBER_ID="m-7WUFYVVHYZEATNPNU4PHTW7KCM"
CA_ENDPOINT="ca.m-7wufyvvhyzeatnpnu4phtw7kcm.n-fqyk2hy5wrcqbfudckakqdlu3a.managedblockchain.us-east-1.amazonaws.com:30002"
PEER_ENDPOINT="nd-mnqiepjfw5ekbpzsde73vcwa6m.m-7wufyvvhyzeatnpnu4phtw7kcm.n-fqyk2hy5wrcqbfudckakqdlu3a.managedblockchain.us-east-1.amazonaws.com:30003"
ORDERER_ENDPOINT="orderer.n-fqyk2hy5wrcqbfudckakqdlu3a.managedblockchain.us-east-1.amazonaws.com:30001"
ADMIN_PASSWORD="Admin12345678"
MSP_ID="Org1MSP"
WORK_DIR="/home/ec2-user/fabric-certs-v2"
S3_BUCKET="supplychain-certs-1764607411"

echo "🚀 Starting complete blockchain setup..."

mkdir -p $WORK_DIR
cd $WORK_DIR

echo "📥 Step 1: Getting CA certificate..."
openssl s_client -connect $CA_ENDPOINT -showcerts < /dev/null 2>/dev/null | \
  sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > ca-cert.pem

echo "✅ CA certificate saved"

echo "📝 Step 2: Enrolling admin with password: $ADMIN_PASSWORD"
sudo docker run --rm -v $(pwd):/data hyperledger/fabric-ca:1.5 \
  fabric-ca-client enroll \
  -u https://admin:$ADMIN_PASSWORD@$CA_ENDPOINT \
  --tls.certfiles /data/ca-cert.pem \
  -M /data/admin-msp

if [ ! -f admin-msp/signcerts/cert.pem ]; then
    echo "❌ Enrollment failed!"
    exit 1
fi

echo "✅ Admin enrolled successfully"

echo "📥 Step 3: Getting peer TLS certificate..."
openssl s_client -connect $PEER_ENDPOINT -showcerts < /dev/null 2>/dev/null | \
  sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > peer-tls-cert.pem

echo "✅ Peer TLS certificate saved"

echo "☁️  Step 4: Uploading certificates to S3..."
aws s3 cp admin-msp/ s3://$S3_BUCKET/certificates-v2/admin-msp/ --recursive --region us-east-1
aws s3 cp ca-cert.pem s3://$S3_BUCKET/certificates-v2/ca-cert.pem --region us-east-1
aws s3 cp peer-tls-cert.pem s3://$S3_BUCKET/certificates-v2/peer-tls-cert.pem --region us-east-1

echo "✅ Certificates uploaded"

echo "📦 Step 5: Creating channel..."
sudo docker run --rm -v $(pwd):/data \
  -e CORE_PEER_TLS_ENABLED=true \
  -e CORE_PEER_LOCALMSPID=$MSP_ID \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/data/peer-tls-cert.pem \
  -e CORE_PEER_ADDRESS=$PEER_ENDPOINT \
  -e CORE_PEER_MSPCONFIGPATH=/data/admin-msp \
  hyperledger/fabric-tools:2.2 \
  peer channel create \
  -o $ORDERER_ENDPOINT \
  -c mychannel \
  --outputBlock /data/mychannel.block \
  --tls \
  --cafile /data/ca-cert.pem

echo "✅ Channel created"

echo "📦 Step 6: Joining peer to channel..."
sudo docker run --rm -v $(pwd):/data \
  -e CORE_PEER_TLS_ENABLED=true \
  -e CORE_PEER_LOCALMSPID=$MSP_ID \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/data/peer-tls-cert.pem \
  -e CORE_PEER_ADDRESS=$PEER_ENDPOINT \
  -e CORE_PEER_MSPCONFIGPATH=/data/admin-msp \
  hyperledger/fabric-tools:2.2 \
  peer channel join \
  -b /data/mychannel.block

echo "✅ Peer joined channel"

echo "📥 Step 7: Downloading chaincode..."
aws s3 cp s3://$S3_BUCKET/chaincode/ ./chaincode/ --recursive --region us-east-1

echo "📦 Step 8: Packaging chaincode..."
sudo docker run --rm -v $(pwd):/data hyperledger/fabric-tools:2.2 \
  peer lifecycle chaincode package /data/supplychain.tar.gz \
  --path /data/chaincode/supplychain-js \
  --lang node \
  --label supplychain_1.0

echo "✅ Chaincode packaged"

echo "📦 Step 9: Installing chaincode..."
sudo docker run --rm -v $(pwd):/data \
  -e CORE_PEER_TLS_ENABLED=true \
  -e CORE_PEER_LOCALMSPID=$MSP_ID \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/data/peer-tls-cert.pem \
  -e CORE_PEER_ADDRESS=$PEER_ENDPOINT \
  -e CORE_PEER_MSPCONFIGPATH=/data/admin-msp \
  hyperledger/fabric-tools:2.2 \
  peer lifecycle chaincode install /data/supplychain.tar.gz

echo "✅ Chaincode installed"

echo "📋 Step 10: Getting package ID..."
PACKAGE_ID=$(sudo docker run --rm -v $(pwd):/data \
  -e CORE_PEER_TLS_ENABLED=true \
  -e CORE_PEER_LOCALMSPID=$MSP_ID \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/data/peer-tls-cert.pem \
  -e CORE_PEER_ADDRESS=$PEER_ENDPOINT \
  -e CORE_PEER_MSPCONFIGPATH=/data/admin-msp \
  hyperledger/fabric-tools:2.2 \
  peer lifecycle chaincode queryinstalled | grep supplychain_1.0 | sed 's/.*Package ID: \(.*\), Label.*/\1/')

echo "Package ID: $PACKAGE_ID"

echo "📦 Step 11: Approving chaincode..."
sudo docker run --rm -v $(pwd):/data \
  -e CORE_PEER_TLS_ENABLED=true \
  -e CORE_PEER_LOCALMSPID=$MSP_ID \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/data/peer-tls-cert.pem \
  -e CORE_PEER_ADDRESS=$PEER_ENDPOINT \
  -e CORE_PEER_MSPCONFIGPATH=/data/admin-msp \
  hyperledger/fabric-tools:2.2 \
  peer lifecycle chaincode approveformyorg \
  --channelID mychannel \
  --name supplychain \
  --version 1.0 \
  --package-id $PACKAGE_ID \
  --sequence 1 \
  --tls \
  --cafile /data/ca-cert.pem \
  --orderer $ORDERER_ENDPOINT

echo "✅ Chaincode approved"

echo "📦 Step 12: Committing chaincode..."
sudo docker run --rm -v $(pwd):/data \
  -e CORE_PEER_TLS_ENABLED=true \
  -e CORE_PEER_LOCALMSPID=$MSP_ID \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/data/peer-tls-cert.pem \
  -e CORE_PEER_ADDRESS=$PEER_ENDPOINT \
  -e CORE_PEER_MSPCONFIGPATH=/data/admin-msp \
  hyperledger/fabric-tools:2.2 \
  peer lifecycle chaincode commit \
  --channelID mychannel \
  --name supplychain \
  --version 1.0 \
  --sequence 1 \
  --tls \
  --cafile /data/ca-cert.pem \
  --orderer $ORDERER_ENDPOINT \
  --peerAddresses $PEER_ENDPOINT \
  --tlsRootCertFiles /data/peer-tls-cert.pem

echo "✅ Chaincode committed"

echo ""
echo "🎉 BLOCKCHAIN SETUP COMPLETE!"
echo ""
echo "Next: Update Lambda with new endpoints from your local machine"
