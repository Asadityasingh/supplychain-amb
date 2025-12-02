# 🚀 Complete Deployment Guide - From Scratch

## Starting Point: Raw Code Only

This guide assumes you have:
- ✅ Source code in local directory
- ❌ No AWS infrastructure deployed
- ❌ No blockchain network
- ❌ No Lambda function
- ❌ No S3 bucket
- ❌ No EC2 instance

---

## 📋 Prerequisites

### 1. Install Required Tools

```bash
# AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Node.js & npm (v18+)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Amplify CLI
npm install -g @aws-amplify/cli

# Verify installations
aws --version
node --version
npm --version
amplify --version
```

### 2. Configure AWS Credentials

```bash
aws configure
# Enter:
# - AWS Access Key ID
# - AWS Secret Access Key
# - Default region: us-east-1
# - Default output format: json
```

---

## 🎯 Complete Deployment Process

### PHASE 1: AWS Managed Blockchain Setup (2 hours)

#### Step 1: Create Blockchain Network (10 min)

```bash
# Create network
aws managedblockchain create-network \
  --name "SupplyChainNetwork" \
  --framework "HYPERLEDGER_FABRIC" \
  --framework-version "1.4" \
  --framework-configuration '{
    "Fabric": {
      "Edition": "STANDARD"
    }
  }' \
  --voting-policy '{
    "ApprovalThresholdPolicy": {
      "ThresholdPercentage": 50,
      "ProposalDurationInHours": 24,
      "ThresholdComparator": "GREATER_THAN"
    }
  }' \
  --member-configuration '{
    "Name": "Org1",
    "Description": "Supply Chain Organization",
    "FrameworkConfiguration": {
      "Fabric": {
        "AdminUsername": "admin",
        "AdminPassword": "Admin12345678"
      }
    }
  }' \
  --region us-east-1

# Save the output - you'll need NetworkId and MemberId
# Example output:
# NetworkId: n-XXXXXXXXXXXXXXXXXXXXXXXXXX
# MemberId: m-XXXXXXXXXXXXXXXXXXXXXXXXXX
```

**⏰ Wait 10 minutes for network to become AVAILABLE**

```bash
# Check status
aws managedblockchain get-network \
  --network-id <YOUR_NETWORK_ID> \
  --region us-east-1 \
  --query 'Network.Status'
```

#### Step 2: Create Peer Nodes (10 min)

```bash
# Get your network and member IDs from Step 1
NETWORK_ID="<YOUR_NETWORK_ID>"
MEMBER_ID="<YOUR_MEMBER_ID>"

# Create Peer Node 1
aws managedblockchain create-node \
  --network-id $NETWORK_ID \
  --member-id $MEMBER_ID \
  --node-configuration '{
    "InstanceType": "bc.t3.small",
    "AvailabilityZone": "us-east-1a"
  }' \
  --region us-east-1

# Create Peer Node 2
aws managedblockchain create-node \
  --network-id $NETWORK_ID \
  --member-id $MEMBER_ID \
  --node-configuration '{
    "InstanceType": "bc.t3.small",
    "AvailabilityZone": "us-east-1b"
  }' \
  --region us-east-1

# Save Peer Node IDs from output
# PEER_1_ID: nd-XXXXXXXXXXXXXXXXXXXXXXXXXX
# PEER_2_ID: nd-XXXXXXXXXXXXXXXXXXXXXXXXXX
```

**⏰ Wait 10 minutes for peer nodes to become AVAILABLE**

```bash
# Check peer status
aws managedblockchain list-nodes \
  --network-id $NETWORK_ID \
  --member-id $MEMBER_ID \
  --region us-east-1
```

#### Step 3: Create VPC Endpoint (5 min)

```bash
# Get VPC ID (use default VPC or create new one)
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query 'Vpcs[0].VpcId' --output text)

# Get subnet IDs
SUBNET_1=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=availability-zone,Values=us-east-1a" --query 'Subnets[0].SubnetId' --output text)
SUBNET_2=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=availability-zone,Values=us-east-1b" --query 'Subnets[0].SubnetId' --output text)

# Create security group
SG_ID=$(aws ec2 create-security-group \
  --group-name blockchain-sg \
  --description "Security group for blockchain" \
  --vpc-id $VPC_ID \
  --query 'GroupId' \
  --output text)

# Add inbound rules
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 30001-30004 \
  --cidr 0.0.0.0/0

# Create VPC endpoint
aws managedblockchain create-vpc-endpoint \
  --network-id $NETWORK_ID \
  --member-id $MEMBER_ID \
  --vpc-endpoint-configuration "SubnetIds=[$SUBNET_1,$SUBNET_2],SecurityGroupIds=[$SG_ID]" \
  --region us-east-1
```

#### Step 4: Launch EC2 for Certificate Enrollment (5 min)

```bash
# Create key pair
aws ec2 create-key-pair \
  --key-name blockchain-key \
  --query 'KeyMaterial' \
  --output text > blockchain-key.pem
chmod 400 blockchain-key.pem

# Launch EC2 instance
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id ami-0c55b159cbfafe1f0 \
  --instance-type t2.micro \
  --key-name blockchain-key \
  --security-group-ids $SG_ID \
  --subnet-id $SUBNET_1 \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "EC2 Instance ID: $INSTANCE_ID"

# Wait for instance to be running
aws ec2 wait instance-running --instance-ids $INSTANCE_ID

# Get public IP
PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

echo "EC2 Public IP: $PUBLIC_IP"
```

#### Step 5: Enroll Admin & Get Certificates (15 min)

```bash
# SSH into EC2
ssh -i blockchain-key.pem ec2-user@$PUBLIC_IP

# On EC2 instance:
# Download Fabric CA client
wget https://github.com/hyperledger/fabric-ca/releases/download/v1.5.2/hyperledger-fabric-ca-linux-amd64-1.5.2.tar.gz
tar -xzf hyperledger-fabric-ca-linux-amd64-1.5.2.tar.gz
sudo cp bin/fabric-ca-client /usr/local/bin/

# Set environment variables (replace with your values)
export NETWORK_ID="<YOUR_NETWORK_ID>"
export MEMBER_ID="<YOUR_MEMBER_ID>"
export CA_ENDPOINT="ca.$MEMBER_ID.$NETWORK_ID.managedblockchain.us-east-1.amazonaws.com:30002"

# Enroll admin
fabric-ca-client enroll \
  -u https://admin:Admin12345678@$CA_ENDPOINT \
  --tls.certfiles /home/ec2-user/managedblockchain-tls-chain.pem \
  -M /home/ec2-user/admin-msp

# Download certificates to local machine
# Exit EC2 and run on local:
exit

# Copy certificates from EC2
mkdir -p certs
scp -i blockchain-key.pem ec2-user@$PUBLIC_IP:/home/ec2-user/admin-msp/signcerts/*.pem certs/cert.pem
scp -i blockchain-key.pem ec2-user@$PUBLIC_IP:/home/ec2-user/admin-msp/keystore/*_sk certs/key.pem
scp -i blockchain-key.pem ec2-user@$PUBLIC_IP:/home/ec2-user/managedblockchain-tls-chain.pem certs/ca.pem

# Download orderer TLS cert
curl -o certs/orderer-tls.pem https://s3.amazonaws.com/managedblockchain-us-east-1-prod-ca-certificates/managedblockchain-tls-chain.pem
```

#### Step 6: Create Channel (10 min)

```bash
# SSH back to EC2
ssh -i blockchain-key.pem ec2-user@$PUBLIC_IP

# Set peer endpoint
export PEER_ENDPOINT="<PEER_1_ID>.$MEMBER_ID.$NETWORK_ID.managedblockchain.us-east-1.amazonaws.com:30003"
export ORDERER_ENDPOINT="orderer.$NETWORK_ID.managedblockchain.us-east-1.amazonaws.com:30001"

# Download peer binary
wget https://github.com/hyperledger/fabric/releases/download/v1.4.12/hyperledger-fabric-linux-amd64-1.4.12.tar.gz
tar -xzf hyperledger-fabric-linux-amd64-1.4.12.tar.gz
sudo cp bin/peer /usr/local/bin/

# Create channel
peer channel create \
  -c mychannel \
  -f /home/ec2-user/mychannel.tx \
  -o $ORDERER_ENDPOINT \
  --tls --cafile /home/ec2-user/managedblockchain-tls-chain.pem

# Join channel
peer channel join -b mychannel.block
```

#### Step 7: Package & Deploy Chaincode (20 min)

```bash
# On local machine, package chaincode
cd chaincode/supplychain-js
npm install

# Create package
cd ..
tar -czf supplychain.tar.gz supplychain-js/

# Copy to EC2
scp -i blockchain-key.pem supplychain.tar.gz ec2-user@$PUBLIC_IP:/home/ec2-user/

# SSH to EC2
ssh -i blockchain-key.pem ec2-user@$PUBLIC_IP

# Install chaincode
peer chaincode install -n supplychain -v 1.0 -p supplychain.tar.gz -l node

# Instantiate chaincode
peer chaincode instantiate \
  -o $ORDERER_ENDPOINT \
  -C mychannel \
  -n supplychain \
  -v 1.0 \
  -c '{"Args":[]}' \
  --tls --cafile /home/ec2-user/managedblockchain-tls-chain.pem

# Test chaincode
peer chaincode invoke \
  -o $ORDERER_ENDPOINT \
  -C mychannel \
  -n supplychain \
  -c '{"function":"CreateAsset","Args":["asset1","Product1","Mumbai","Owner1"]}' \
  --tls --cafile /home/ec2-user/managedblockchain-tls-chain.pem
```

---

### PHASE 2: Backend Deployment (30 min)

#### Step 8: Initialize Amplify (5 min)

```bash
# In project root
amplify init

# Answer prompts:
# - Enter a name for the project: supplychainamb
# - Enter a name for the environment: dev
# - Choose your default editor: Visual Studio Code
# - Choose the type of app: javascript
# - What javascript framework: react
# - Source Directory Path: src/ui/src
# - Distribution Directory Path: src/ui/build
# - Build Command: npm run build
# - Start Command: npm start
# - Do you want to use an AWS profile? Yes
# - Please choose the profile: default
```

#### Step 9: Add Lambda Function (10 min)

```bash
# Add function
amplify add function

# Answer prompts:
# - Select which capability: Lambda function
# - Provide a friendly name: supplyChainAPI
# - Provide the AWS Lambda function name: supplyChainAPI
# - Choose the runtime: NodeJS
# - Choose the function template: Hello World
# - Do you want to configure advanced settings? Yes
# - Do you want to access other resources? No
# - Do you want to invoke on a recurring schedule? No
# - Do you want to enable Lambda layers? No
# - Do you want to configure environment variables? Yes
# - Add environment variables...

# Copy Lambda code
cp lambda-function.js amplify/backend/function/supplyChainAPI/src/app.js
cp -r amplify/backend/function/supplyChainAPI/src/fabric-config amplify/backend/function/supplyChainAPI/src/

# Update package.json
cd amplify/backend/function/supplyChainAPI/src
npm install fabric-network aws-sdk
```

#### Step 10: Configure Lambda with Blockchain Details (5 min)

```bash
# Update team-provider-info.json with your IDs
# Edit: amplify/team-provider-info.json

{
  "dev": {
    "categories": {
      "function": {
        "supplyChainAPI": {
          "peerEndpoint": "nd-<PEER_ID>.<MEMBER_ID>.<NETWORK_ID>.managedblockchain.us-east-1.amazonaws.com:30003",
          "ordererEndpoint": "orderer.<NETWORK_ID>.managedblockchain.us-east-1.amazonaws.com:30001",
          "caEndpoint": "ca.<MEMBER_ID>.<NETWORK_ID>.managedblockchain.us-east-1.amazonaws.com:30002",
          "channelName": "mychannel",
          "chaincodeName": "supplychain",
          "mspId": "<MEMBER_ID>",
          "deploymentBucketName": "amplify-supplychainamb-dev-deployment"
        }
      }
    }
  }
}
```

#### Step 11: Store Certificates in SSM (5 min)

```bash
# Store certificates
aws ssm put-parameter \
  --name "/amplify/<APP_ID>/dev/AMPLIFY_function_supplyChainAPI_userCert" \
  --value "$(cat certs/cert.pem)" \
  --type "String" \
  --region us-east-1

aws ssm put-parameter \
  --name "/amplify/<APP_ID>/dev/AMPLIFY_function_supplyChainAPI_userPrivateKey" \
  --value "$(cat certs/key.pem)" \
  --type "String" \
  --region us-east-1

aws ssm put-parameter \
  --name "/amplify/<APP_ID>/dev/AMPLIFY_function_supplyChainAPI_tlsCert" \
  --value "$(cat certs/orderer-tls.pem)" \
  --type "String" \
  --region us-east-1

aws ssm put-parameter \
  --name "/amplify/<APP_ID>/dev/AMPLIFY_function_supplyChainAPI_caTlsCert" \
  --value "$(cat certs/ca.pem)" \
  --type "String" \
  --region us-east-1

aws ssm put-parameter \
  --name "/amplify/<APP_ID>/dev/AMPLIFY_function_supplyChainAPI_memberId" \
  --value "<MEMBER_ID>" \
  --type "String" \
  --region us-east-1

aws ssm put-parameter \
  --name "/amplify/<APP_ID>/dev/AMPLIFY_function_supplyChainAPI_networkId" \
  --value "<NETWORK_ID>" \
  --type "String" \
  --region us-east-1

aws ssm put-parameter \
  --name "/amplify/<APP_ID>/dev/AMPLIFY_function_supplyChainAPI_caEndpoint" \
  --value "ca.<MEMBER_ID>.<NETWORK_ID>.managedblockchain.us-east-1.amazonaws.com:30002" \
  --type "String" \
  --region us-east-1
```

#### Step 12: Deploy Lambda (5 min)

```bash
# Push to AWS
amplify push --yes

# Get Lambda URL
aws lambda get-function-url-config \
  --function-name supplyChainAPI-dev \
  --region us-east-1
```

---

### PHASE 3: Frontend Deployment (15 min)

#### Step 13: Build Frontend (5 min)

```bash
cd src/ui

# Install dependencies
npm install

# Create production environment file
cat > .env.production << EOF
REACT_APP_API_ENDPOINT=<YOUR_LAMBDA_URL>
EOF

# Build
npm run build
```

#### Step 14: Create S3 Bucket (5 min)

```bash
# Create unique bucket name
BUCKET_NAME="supplychain-frontend-$(date +%s)"

# Create bucket
aws s3 mb s3://$BUCKET_NAME --region us-east-1

# Enable static website hosting
aws s3 website s3://$BUCKET_NAME/ \
  --index-document index.html \
  --error-document index.html

# Create bucket policy
cat > bucket-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::$BUCKET_NAME/*"
    }
  ]
}
EOF

# Disable block public access
aws s3api put-public-access-block \
  --bucket $BUCKET_NAME \
  --public-access-block-configuration "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"

# Apply bucket policy
aws s3api put-bucket-policy \
  --bucket $BUCKET_NAME \
  --policy file://bucket-policy.json
```

#### Step 15: Deploy Frontend (5 min)

```bash
# Upload build files
aws s3 sync build/ s3://$BUCKET_NAME/ --region us-east-1

# Get website URL
echo "Frontend URL: http://$BUCKET_NAME.s3-website-us-east-1.amazonaws.com"
```

---

## ✅ Verification Steps

### 1. Test Blockchain
```bash
# Test health endpoint
curl <LAMBDA_URL>/health | jq

# Expected: {"blockchain": {"connected": true}}
```

### 2. Test API
```bash
# Create asset
curl -X POST <LAMBDA_URL>/assets \
  -H "Content-Type: application/json" \
  -d '{"assetId":"test1","name":"Test","location":"Mumbai","owner":"TestCo"}' | jq

# Get assets
curl <LAMBDA_URL>/assets | jq
```

### 3. Test Frontend
```bash
# Open in browser
open http://$BUCKET_NAME.s3-website-us-east-1.amazonaws.com

# Check for:
# - 🔗 Live Blockchain badge
# - Dashboard loads
# - Can create assets
# - Transaction IDs display
```

---

## 📝 Save Important IDs

Create a file `deployment-ids.txt`:

```bash
cat > deployment-ids.txt << EOF
NETWORK_ID=<YOUR_NETWORK_ID>
MEMBER_ID=<YOUR_MEMBER_ID>
PEER_1_ID=<YOUR_PEER_1_ID>
PEER_2_ID=<YOUR_PEER_2_ID>
VPC_ID=$VPC_ID
SUBNET_1=$SUBNET_1
SUBNET_2=$SUBNET_2
SG_ID=$SG_ID
INSTANCE_ID=$INSTANCE_ID
LAMBDA_URL=<YOUR_LAMBDA_URL>
BUCKET_NAME=$BUCKET_NAME
FRONTEND_URL=http://$BUCKET_NAME.s3-website-us-east-1.amazonaws.com
EOF
```

---

## 🧹 Cleanup (When Done)

```bash
# Delete in reverse order

# 1. Delete S3 bucket
aws s3 rm s3://$BUCKET_NAME --recursive
aws s3 rb s3://$BUCKET_NAME

# 2. Delete Lambda
amplify delete

# 3. Terminate EC2
aws ec2 terminate-instances --instance-ids $INSTANCE_ID

# 4. Delete peer nodes
aws managedblockchain delete-node --network-id $NETWORK_ID --member-id $MEMBER_ID --node-id $PEER_1_ID
aws managedblockchain delete-node --network-id $NETWORK_ID --member-id $MEMBER_ID --node-id $PEER_2_ID

# 5. Delete member
aws managedblockchain delete-member --network-id $NETWORK_ID --member-id $MEMBER_ID

# 6. Delete network (after member is deleted)
aws managedblockchain delete-network --network-id $NETWORK_ID

# 7. Delete VPC resources
aws ec2 delete-security-group --group-id $SG_ID
```

---

## ⏱️ Total Time Estimate

| Phase | Duration |
|-------|----------|
| Blockchain Setup | 2 hours |
| Backend Deployment | 30 minutes |
| Frontend Deployment | 15 minutes |
| **Total** | **2 hours 45 minutes** |

---

## 💰 Total Cost

| Component | Cost |
|-----------|------|
| Blockchain (2.75 hours) | ~$0.83 |
| Peer Nodes (2.75 hours) | ~$0.47 |
| EC2 (1 hour) | ~$0.01 |
| Lambda | ~$0.00 |
| S3 | ~$0.00 |
| **Total** | **~$1.31** |

---

## 🚨 Common Issues & Solutions

### Issue 1: Network creation fails
```bash
# Check quotas
aws service-quotas get-service-quota \
  --service-code managedblockchain \
  --quota-code L-6E9F2D5F

# Request quota increase if needed
```

### Issue 2: Certificate enrollment fails
```bash
# Verify CA endpoint is accessible
telnet <CA_ENDPOINT> 30002

# Check security group allows port 30002
```

### Issue 3: Lambda can't connect to blockchain
```bash
# Verify Lambda is in same VPC
# Check security group allows ports 30001-30004
# Verify certificates are in SSM
```

### Issue 4: Frontend shows Mock Data
```bash
# Check Lambda logs
aws logs tail /aws/lambda/supplyChainAPI-dev --follow

# Verify MSP ID matches Member ID
# Check certificates are valid
```

---

## ✅ Success Criteria

Your deployment is successful when:

- ✅ Blockchain network status: AVAILABLE
- ✅ Both peer nodes status: AVAILABLE
- ✅ Channel created: mychannel
- ✅ Chaincode instantiated: supplychain
- ✅ Lambda health check returns: connected=true
- ✅ Frontend loads with: 🔗 Live Blockchain
- ✅ Can create assets via UI
- ✅ Transaction IDs display
- ✅ Assets persist on blockchain

---

**🎉 Deployment Complete!**

Your blockchain supply chain application is now live and operational!
