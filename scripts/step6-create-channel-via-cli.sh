#!/bin/bash
set -e

echo "=========================================="
echo "Step 6: Create Channel via AWS CLI"
echo "=========================================="

NETWORK_ID="n-FQYK2HY5WRCQBFUDCKAKQDLU3A"
MEMBER_ID="m-7WUFYVVHYZEATNPNU4PHTW7KCM"

echo ""
echo "Creating channel 'mychannel' via AWS Managed Blockchain..."

# Create channel proposal
aws managedblockchain create-proposal \
  --network-id ${NETWORK_ID} \
  --member-id ${MEMBER_ID} \
  --actions "Invitations=[{Principal=arn:aws:managedblockchain:us-east-1::members/${MEMBER_ID}}]" \
  --description "Create mychannel for supply chain" \
  --region us-east-1 || echo "Proposal creation may have failed"

echo ""
echo "Note: AWS Managed Blockchain STARTER edition uses a default channel."
echo "You may need to use the AWS Console to:"
echo "1. Navigate to Managed Blockchain > Networks > ${NETWORK_ID}"
echo "2. Create a channel named 'mychannel'"
echo "3. Add your peer node to the channel"
echo ""
echo "Alternatively, the network may already have a default channel."
echo "Let's check what channels exist..."

cd /home/ec2-user/fabric-certs-v2

PEER_NODE_ID="nd-MNQIEPJFW5EKBPZSDE73VCWA6M"
PEER_ENDPOINT="${PEER_NODE_ID,,}.${MEMBER_ID,,}.${NETWORK_ID,,}.managedblockchain.us-east-1.amazonaws.com:30003"

sudo docker run --rm \
  -v $(pwd):/data \
  -e CORE_PEER_TLS_ENABLED=true \
  -e CORE_PEER_LOCALMSPID=${MEMBER_ID} \
  -e CORE_PEER_MSPCONFIGPATH=/data/admin-msp \
  -e CORE_PEER_ADDRESS=${PEER_ENDPOINT} \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/data/peer-tls-cert.pem \
  hyperledger/fabric-tools:2.2 \
  peer channel list

echo ""
echo "If no channels are listed, you need to create one via AWS Console."
