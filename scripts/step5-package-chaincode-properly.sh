#!/bin/bash
set -e

echo "=========================================="
echo "Step 5: Package Chaincode (Fabric 2.x)"
echo "=========================================="

NETWORK_ID="n-CFCACD47IZA7DALLDSYZ32FUZY"
MEMBER_ID="m-KTGJMTI7HFGTZKU7ECMPS4FQUU"
PEER_NODE_ID="nd-ZQX2IJVXHBCWZOTRY5KXM2KDVA"
PEER_ENDPOINT="${PEER_NODE_ID,,}.${MEMBER_ID,,}.${NETWORK_ID,,}.managedblockchain.us-east-1.amazonaws.com:30003"

WORK_DIR="/home/ec2-user/fabric-certs-standard"
cd $WORK_DIR

# Step 1: Create proper chaincode structure
echo ""
echo "Step 1: Creating chaincode package structure..."
rm -rf chaincode-package
mkdir -p chaincode-package/src

# Copy chaincode files
cp -r chaincode/supplychain-js/* chaincode-package/src/

# Step 2: Create metadata.json
echo ""
echo "Step 2: Creating metadata.json..."
cat > chaincode-package/metadata.json << 'EOF'
{
  "type": "node",
  "label": "supplychain_1.0"
}
EOF

# Step 3: Package using peer lifecycle
echo ""
echo "Step 3: Packaging chaincode with peer lifecycle..."
sudo docker run --rm \
  -v $(pwd)/chaincode-package:/chaincode \
  -v $(pwd):/output \
  hyperledger/fabric-tools:2.2 \
  peer lifecycle chaincode package /output/supplychain.tar.gz \
    --path /chaincode/src \
    --lang node \
    --label supplychain_1.0

sudo chown ec2-user:ec2-user supplychain.tar.gz

# Step 4: Verify package
echo ""
echo "Step 4: Package created:"
ls -lh supplychain.tar.gz

# Step 5: Install chaincode
echo ""
echo "Step 5: Installing chaincode..."
sudo docker run --rm \
  -v $(pwd):/data \
  -e CORE_PEER_TLS_ENABLED=true \
  -e CORE_PEER_LOCALMSPID=${MEMBER_ID} \
  -e CORE_PEER_MSPCONFIGPATH=/data/admin-msp \
  -e CORE_PEER_ADDRESS=${PEER_ENDPOINT} \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/data/peer-tls-cert.pem \
  hyperledger/fabric-tools:2.2 \
  peer lifecycle chaincode install /data/supplychain.tar.gz

# Step 6: Query installed
echo ""
echo "Step 6: Querying installed chaincode..."
sudo docker run --rm \
  -v $(pwd):/data \
  -e CORE_PEER_TLS_ENABLED=true \
  -e CORE_PEER_LOCALMSPID=${MEMBER_ID} \
  -e CORE_PEER_MSPCONFIGPATH=/data/admin-msp \
  -e CORE_PEER_ADDRESS=${PEER_ENDPOINT} \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/data/peer-tls-cert.pem \
  hyperledger/fabric-tools:2.2 \
  peer lifecycle chaincode queryinstalled > installed.txt

cat installed.txt

# Extract package ID
PACKAGE_ID=$(grep "supplychain_1.0" installed.txt | awk '{print $3}' | sed 's/,$//')
echo ""
echo "Package ID: $PACKAGE_ID"
echo "$PACKAGE_ID" > package_id.txt

echo ""
echo "=========================================="
echo "✅ Chaincode Packaged & Installed!"
echo "=========================================="
echo ""
echo "Next: Create channel and approve chaincode"
