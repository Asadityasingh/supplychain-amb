#!/bin/bash
set -e

# Upload certificates to Lambda function
# Run this script from your LOCAL machine after certificates are in S3

LAMBDA_FUNCTION="supplyChainAPI-dev"
S3_BUCKET="supplychain-certs-1764607411"
REGION="us-east-1"
TEMP_DIR="/tmp/fabric-certs"

echo "☁️  Downloading certificates from S3..."
mkdir -p $TEMP_DIR
aws s3 cp s3://$S3_BUCKET/admin-msp/ $TEMP_DIR/admin-msp/ --recursive --region $REGION
aws s3 cp s3://$S3_BUCKET/ca-cert.pem $TEMP_DIR/ca-cert.pem --region $REGION
aws s3 cp s3://$S3_BUCKET/peer-tls-cert.pem $TEMP_DIR/peer-tls-cert.pem --region $REGION

echo "✅ Certificates downloaded"

# Read certificate files
USER_CERT=$(cat $TEMP_DIR/admin-msp/signcerts/cert.pem)
USER_KEY=$(cat $TEMP_DIR/admin-msp/keystore/*_sk)
CA_TLS_CERT=$(cat $TEMP_DIR/ca-cert.pem)
PEER_TLS_CERT=$(cat $TEMP_DIR/peer-tls-cert.pem)

echo "🔐 Updating Lambda environment variables..."

# Update Lambda environment variables
aws lambda update-function-configuration \
  --function-name $LAMBDA_FUNCTION \
  --environment "Variables={
    PEER_ENDPOINT=nd-xaiao3kjsvd7hjur5a6rpfhl6i.m-i5mmo373lffuthpslbocegjrkm.n-ozfgrzjblfgavhtmceacicx35u.managedblockchain.us-east-1.amazonaws.com:30003,
    ORDERER_ENDPOINT=orderer.n-ozfgrzjblfgavhtmceacicx35u.managedblockchain.us-east-1.amazonaws.com:30001,
    CA_ENDPOINT=ca.m-i5mmo373lffuthpslbocegjrkm.n-ozfgrzjblfgavhtmceacicx35u.managedblockchain.us-east-1.amazonaws.com:30002,
    CHANNEL_NAME=mychannel,
    CHAINCODE_NAME=supplychain,
    MSP_ID=Org1MSP,
    MEMBER_ID=m-I5MMO373LFFUTHPSLBOCEGJRKM,
    NETWORK_ID=n-OZFGRZJBLFGAVHTMCEACICX35U,
    USER_CERT=$USER_CERT,
    USER_PRIVATE_KEY=$USER_KEY,
    TLS_CERT=$PEER_TLS_CERT,
    CA_TLS_CERT=$CA_TLS_CERT
  }" \
  --region $REGION

echo "✅ Lambda environment variables updated"
echo ""
echo "🧪 Testing connection..."
sleep 5

# Test health endpoint
LAMBDA_URL="https://k4uyws3gmegkpwvbzkywnrisfq0zeoxe.lambda-url.us-east-1.on.aws"
curl -s "$LAMBDA_URL/health" | jq '.blockchain'

echo ""
echo "✅ Setup complete!"
