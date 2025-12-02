# Execution Guide - Complete Blockchain Setup

Follow these steps in order to complete the blockchain integration.

## Prerequisites

- AWS CLI configured with appropriate credentials
- Access to AWS Console
- S3 bucket: `supplychain-certs-1764607411`
- Blockchain network running and available

---

## Step 1: Launch EC2 Instance

```bash
cd scripts
chmod +x step1-launch-ec2.sh
./step1-launch-ec2.sh
```

**What it does:**
- Launches EC2 instance in the VPC
- Installs Docker and Fabric CA client
- Saves instance ID to `instance-id.txt`

**Output:** Instance ID (e.g., `i-0109c5a082014bf90`)

---

## Step 2: Upload Chaincode to S3

Before retrieving certificates, upload your chaincode:

```bash
aws s3 cp ../chaincode/supplychain-js/ s3://supplychain-certs-1764607411/chaincode/supplychain-js/ --recursive --region us-east-1
```

---

## Step 3: Connect to EC2 and Retrieve Certificates

### Option A: Using EC2 Instance Connect (Console)

1. Go to AWS Console → EC2 → Instances
2. Select your instance
3. Click "Connect" → "EC2 Instance Connect"
4. Once connected, run:

```bash
# Download the script
aws s3 cp s3://supplychain-certs-1764607411/scripts/step2-retrieve-certificates.sh . --region us-east-1

# Make it executable
chmod +x step2-retrieve-certificates.sh

# Run it
./step2-retrieve-certificates.sh
```

### Option B: Using SSH (if you have key pair)

```bash
INSTANCE_ID=$(cat instance-id.txt)
INSTANCE_IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text --region us-east-1)

# Copy script to EC2
scp step2-retrieve-certificates.sh ec2-user@$INSTANCE_IP:~/

# SSH and run
ssh ec2-user@$INSTANCE_IP
chmod +x step2-retrieve-certificates.sh
./step2-retrieve-certificates.sh
```

**What it does:**
- Downloads CA TLS certificate
- Enrolls admin user with Fabric CA
- Downloads peer TLS certificate
- Uploads all certificates to S3

**Important:** The default admin password is `AdminPassword`. If this fails, check AWS Managed Blockchain console for the correct admin password.

---

## Step 4: Create Channel (On EC2)

While still on the EC2 instance:

```bash
# Set environment variables
export PEER_ENDPOINT="nd-xaiao3kjsvd7hjur5a6rpfhl6i.m-i5mmo373lffuthpslbocegjrkm.n-ozfgrzjblfgavhtmceacicx35u.managedblockchain.us-east-1.amazonaws.com:30003"
export ORDERER_ENDPOINT="orderer.n-ozfgrzjblfgavhtmceacicx35u.managedblockchain.us-east-1.amazonaws.com:30001"
export MSP_ID="Org1MSP"
export WORK_DIR="/home/ec2-user/fabric-certs"

cd $WORK_DIR

# Create channel configuration
docker run --rm -v $(pwd):/data hyperledger/fabric-tools:2.2 \
  configtxgen -profile OneOrgChannel \
  -outputCreateChannelTx /data/mychannel.tx \
  -channelID mychannel

# Create channel
docker run --rm -v $(pwd):/data \
  -e CORE_PEER_TLS_ENABLED=true \
  -e CORE_PEER_LOCALMSPID=$MSP_ID \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/data/peer-tls-cert.pem \
  -e CORE_PEER_ADDRESS=$PEER_ENDPOINT \
  -e CORE_PEER_MSPCONFIGPATH=/data/admin-msp \
  hyperledger/fabric-tools:2.2 \
  peer channel create \
  -o $ORDERER_ENDPOINT \
  -c mychannel \
  -f /data/mychannel.tx \
  --tls \
  --cafile /data/ca-cert.pem

# Join peer to channel
docker run --rm -v $(pwd):/data \
  -e CORE_PEER_TLS_ENABLED=true \
  -e CORE_PEER_LOCALMSPID=$MSP_ID \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/data/peer-tls-cert.pem \
  -e CORE_PEER_ADDRESS=$PEER_ENDPOINT \
  -e CORE_PEER_MSPCONFIGPATH=/data/admin-msp \
  hyperledger/fabric-tools:2.2 \
  peer channel join \
  -b mychannel.block
```

---

## Step 5: Deploy Chaincode (On EC2)

```bash
# Download and run deployment script
aws s3 cp s3://supplychain-certs-1764607411/scripts/step3-deploy-chaincode.sh . --region us-east-1
chmod +x step3-deploy-chaincode.sh
./step3-deploy-chaincode.sh
```

**What it does:**
- Packages chaincode
- Installs on peer node
- Approves chaincode definition
- Commits chaincode to channel

---

## Step 6: Upload Certificates to Lambda (Local Machine)

Exit EC2 and return to your local machine:

```bash
chmod +x step4-upload-certs-to-lambda.sh
./step4-upload-certs-to-lambda.sh
```

**What it does:**
- Downloads certificates from S3
- Updates Lambda environment variables
- Tests blockchain connection

---

## Step 7: Test End-to-End

```bash
chmod +x step5-test-blockchain.sh
./step5-test-blockchain.sh
```

**What it does:**
- Tests health endpoint
- Creates test asset on blockchain
- Queries asset
- Transfers asset
- Verifies all operations

---

## Step 8: Fix Security Vulnerabilities

```bash
chmod +x step6-fix-security.sh
./step6-fix-security.sh
```

---

## Step 9: Deploy Frontend

```bash
cd ../src/ui

# Build production bundle
npm run build

# Deploy to Amplify Hosting
cd ../..
amplify add hosting
amplify publish
```

---

## Troubleshooting

### Certificate Enrollment Fails

Check the admin password in AWS Console:
1. Go to Managed Blockchain → Networks → supplychain-fabric-demo
2. Click on Member → Org1
3. Check the admin username and password

### Channel Creation Fails

The channel might already exist. Check with:
```bash
docker run --rm -v $(pwd):/data \
  -e CORE_PEER_TLS_ENABLED=true \
  -e CORE_PEER_LOCALMSPID=$MSP_ID \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/data/peer-tls-cert.pem \
  -e CORE_PEER_ADDRESS=$PEER_ENDPOINT \
  -e CORE_PEER_MSPCONFIGPATH=/data/admin-msp \
  hyperledger/fabric-tools:2.2 \
  peer channel list
```

### Chaincode Deployment Fails

Verify chaincode is uploaded to S3:
```bash
aws s3 ls s3://supplychain-certs-1764607411/chaincode/supplychain-js/ --region us-east-1
```

### Lambda Connection Fails

Check Lambda logs:
```bash
aws logs tail /aws/lambda/supplyChainAPI-dev --follow --region us-east-1
```

---

## Verification Checklist

- [ ] EC2 instance launched successfully
- [ ] Certificates retrieved and uploaded to S3
- [ ] Channel created and peer joined
- [ ] Chaincode deployed and committed
- [ ] Lambda environment variables updated
- [ ] Health endpoint shows "connected": true
- [ ] Test asset created on blockchain
- [ ] Frontend can create/query/transfer assets
- [ ] Security vulnerabilities fixed
- [ ] Frontend deployed to production

---

## Clean Up (Optional)

To terminate the EC2 instance after setup:

```bash
INSTANCE_ID=$(cat instance-id.txt)
aws ec2 terminate-instances --instance-ids $INSTANCE_ID --region us-east-1
```

Note: Keep the instance running if you need to make chaincode updates or troubleshoot.
