# Chaincode Upgrade Instructions

## Smart Contract Updated ✅
The local `smartcontract.go` has been updated with new fields:
- `ID, Name, Location, Owner, Timestamp`

## Steps to Upgrade on EC2:

### 1. SSH to EC2
```bash
ssh -i <your-key.pem> ec2-user@54.198.191.176
```

### 2. Update the Smart Contract File
```bash
cd fabric-samples/asset-transfer-basic/chaincode-go/chaincode
cat > smartcontract.go << 'SMARTCONTRACT'
# Copy the entire content from local smartcontract.go file
SMARTCONTRACT
```

**OR** use SCP to copy:
```bash
scp -i <your-key.pem> fabric-samples/asset-transfer-basic/chaincode-go/chaincode/smartcontract.go ec2-user@54.198.191.176:~/fabric-samples/asset-transfer-basic/chaincode-go/chaincode/
```

### 3. Package and Upgrade
```bash
cd ~/fabric-samples/asset-transfer-basic/chaincode-go

# Vendor dependencies
go mod vendor

# Package v3.0
peer chaincode package -n supplychain -v 3.0 -p . supplychain-v3.tar.gz

# Install
peer chaincode install supplychain-v3.tar.gz

# Upgrade (this will reset ledger with new InitLedger data)
peer chaincode upgrade \
  -o orderer.n-cfcacd47iza7dalldsyz32fuzy.managedblockchain.us-east-1.amazonaws.com:30001 \
  --tls --cafile managedblockchain-tls-chain.pem \
  -C mychannel \
  -n supplychain \
  -v 3.0 \
  -c '{"Args":["InitLedger"]}'
```

### 4. Verify
```bash
peer chaincode query -C mychannel -n supplychain -c '{"Args":["GetAllAssets"]}'
```

## Lambda Already Updated ✅
Lambda code has been updated to use new parameters.

## After Upgrade
Test from UI - create an asset with proper Name, Location fields!
