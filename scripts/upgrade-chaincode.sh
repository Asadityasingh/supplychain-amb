#!/bin/bash
set -e

EC2_IP=$(aws ec2 describe-instances --instance-ids i-0ae980f8feb375fcf --query 'Reservations[0].Instances[0].PublicIpAddress' --output text --region us-east-1)

echo "Upgrading chaincode on EC2: $EC2_IP"

ssh -o StrictHostKeyChecking=no -i scripts/blockchain-key.pem ec2-user@$EC2_IP << 'EOF'
cd fabric-samples/asset-transfer-basic/chaincode-go

# Vendor dependencies
go mod vendor

# Package new version
peer chaincode package -n supplychain -v 3.0 -p . supplychain-v3.tar.gz

# Install
peer chaincode install supplychain-v3.tar.gz

# Upgrade with InitLedger
peer chaincode upgrade \
  -o orderer.n-cfcacd47iza7dalldsyz32fuzy.managedblockchain.us-east-1.amazonaws.com:30001 \
  --tls --cafile managedblockchain-tls-chain.pem \
  -C mychannel \
  -n supplychain \
  -v 3.0 \
  -c '{"Args":["InitLedger"]}'

echo "✅ Chaincode upgraded to v3.0"
EOF
