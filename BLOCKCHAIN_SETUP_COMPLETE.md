# 🎉 NEW BLOCKCHAIN NETWORK - COMPLETE SETUP GUIDE

## ✅ NETWORK CREATED

**Network Details:**
- **Network ID:** `n-FQYK2HY5WRCQBFUDCKAKQDLU3A`
- **Network Name:** `supplychain-fabric-v2`
- **Member ID:** `m-7WUFYVVHYZEATNPNU4PHTW7KCM`
- **Member Name:** `Org1`
- **MSP ID:** `Org1MSP`
- **Status:** AVAILABLE ✅

**Admin Credentials:**
- **Username:** `admin`
- **Password:** `Admin12345678` 🔐

**Peer Nodes:**
- **Peer 1:** `nd-MNQIEPJFW5EKBPZSDE73VCWA6M` (us-east-1a) - Creating
- **Peer 2:** `nd-ITJBOGZ7RFDY3H7M3MBZOCX2LE` (us-east-1b) - Creating

**Endpoints:**
- **CA:** `ca.m-7wufyvvhyzeatnpnu4phtw7kcm.n-fqyk2hy5wrcqbfudckakqdlu3a.managedblockchain.us-east-1.amazonaws.com:30002`
- **Orderer:** `orderer.n-fqyk2hy5wrcqbfudckakqdlu3a.managedblockchain.us-east-1.amazonaws.com:30001`
- **Peer:** (will be available after peer nodes are ready)

---

## 📋 NEXT STEPS

### Step 1: Wait for Peer Nodes (5-10 minutes)

Check status:
```bash
aws managedblockchain list-nodes \
  --network-id n-FQYK2HY5WRCQBFUDCKAKQDLU3A \
  --member-id m-7WUFYVVHYZEATNPNU4PHTW7KCM \
  --region us-east-1 \
  --query 'Nodes[*].{Id:Id,Status:Status}'
```

### Step 2: Get Certificates from CA

On EC2 instance (i-0ae980f8feb375fcf):

```bash
cd /home/ec2-user
mkdir -p fabric-certs-v2
cd fabric-certs-v2

# Download CA certificate
openssl s_client -connect ca.m-7wufyvvhyzeatnpnu4phtw7kcm.n-fqyk2hy5wrcqbfudckakqdlu3a.managedblockchain.us-east-1.amazonaws.com:30002 -showcerts < /dev/null 2>/dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > ca-cert.pem

# Enroll admin with KNOWN password
sudo docker run --rm -v $(pwd):/data hyperledger/fabric-ca:1.5 \
  fabric-ca-client enroll \
  -u https://admin:Admin12345678@ca.m-7wufyvvhyzeatnpnu4phtw7kcm.n-fqyk2hy5wrcqbfudckakqdlu3a.managedblockchain.us-east-1.amazonaws.com:30002 \
  --tls.certfiles /data/ca-cert.pem \
  -M /data/admin-msp

# Get peer TLS certificate (after peer is ready)
PEER_ENDPOINT="<peer-endpoint-from-step1>"
openssl s_client -connect $PEER_ENDPOINT -showcerts < /dev/null 2>/dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > peer-tls-cert.pem

# Upload to S3
aws s3 cp admin-msp/ s3://supplychain-certs-1764607411/certificates-v2/admin-msp/ --recursive --region us-east-1
aws s3 cp ca-cert.pem s3://supplychain-certs-1764607411/certificates-v2/ca-cert.pem --region us-east-1
aws s3 cp peer-tls-cert.pem s3://supplychain-certs-1764607411/certificates-v2/peer-tls-cert.pem --region us-east-1
```

### Step 3: Create Channel

```bash
# Set environment variables
export PEER_ENDPOINT="<peer-endpoint>"
export ORDERER_ENDPOINT="orderer.n-fqyk2hy5wrcqbfudckakqdlu3a.managedblockchain.us-east-1.amazonaws.com:30001"
export MSP_ID="Org1MSP"
export WORK_DIR="/home/ec2-user/fabric-certs-v2"

cd $WORK_DIR

# Create and join channel
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
  --outputBlock /data/mychannel.block \
  --tls \
  --cafile /data/ca-cert.pem

docker run --rm -v $(pwd):/data \
  -e CORE_PEER_TLS_ENABLED=true \
  -e CORE_PEER_LOCALMSPID=$MSP_ID \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/data/peer-tls-cert.pem \
  -e CORE_PEER_ADDRESS=$PEER_ENDPOINT \
  -e CORE_PEER_MSPCONFIGPATH=/data/admin-msp \
  hyperledger/fabric-tools:2.2 \
  peer channel join \
  -b /data/mychannel.block
```

### Step 4: Deploy Chaincode

```bash
# Download chaincode
aws s3 cp s3://supplychain-certs-1764607411/chaincode/ ./chaincode/ --recursive --region us-east-1

# Package
docker run --rm -v $(pwd):/data hyperledger/fabric-tools:2.2 \
  peer lifecycle chaincode package /data/supplychain.tar.gz \
  --path /data/chaincode/supplychain-js \
  --lang node \
  --label supplychain_1.0

# Install
docker run --rm -v $(pwd):/data \
  -e CORE_PEER_TLS_ENABLED=true \
  -e CORE_PEER_LOCALMSPID=$MSP_ID \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/data/peer-tls-cert.pem \
  -e CORE_PEER_ADDRESS=$PEER_ENDPOINT \
  -e CORE_PEER_MSPCONFIGPATH=/data/admin-msp \
  hyperledger/fabric-tools:2.2 \
  peer lifecycle chaincode install /data/supplychain.tar.gz

# Get package ID
PACKAGE_ID=$(docker run --rm -v $(pwd):/data \
  -e CORE_PEER_TLS_ENABLED=true \
  -e CORE_PEER_LOCALMSPID=$MSP_ID \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/data/peer-tls-cert.pem \
  -e CORE_PEER_ADDRESS=$PEER_ENDPOINT \
  -e CORE_PEER_MSPCONFIGPATH=/data/admin-msp \
  hyperledger/fabric-tools:2.2 \
  peer lifecycle chaincode queryinstalled | grep supplychain_1.0 | sed 's/.*Package ID: \(.*\), Label.*/\1/')

# Approve
docker run --rm -v $(pwd):/data \
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

# Commit
docker run --rm -v $(pwd):/data \
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
```

### Step 5: Update Lambda with New Endpoints

```bash
# Update Secrets Manager
aws secretsmanager update-secret \
  --secret-id blockchain/fabric-admin-credentials \
  --secret-string file://certs.json \
  --region us-east-1

# Update Lambda environment
aws lambda update-function-configuration \
  --function-name supplyChainAPI-dev \
  --environment "Variables={
    PEER_ENDPOINT=<new-peer-endpoint>,
    ORDERER_ENDPOINT=orderer.n-fqyk2hy5wrcqbfudckakqdlu3a.managedblockchain.us-east-1.amazonaws.com:30001,
    CA_ENDPOINT=ca.m-7wufyvvhyzeatnpnu4phtw7kcm.n-fqyk2hy5wrcqbfudckakqdlu3a.managedblockchain.us-east-1.amazonaws.com:30002,
    CHANNEL_NAME=mychannel,
    CHAINCODE_NAME=supplychain,
    MSP_ID=Org1MSP,
    MEMBER_ID=m-7WUFYVVHYZEATNPNU4PHTW7KCM,
    NETWORK_ID=n-FQYK2HY5WRCQBFUDCKAKQDLU3A,
    REGION=us-east-1
  }" \
  --region us-east-1
```

### Step 6: Test

```bash
curl https://k4uyws3gmegkpwvbzkywnrisfq0zeoxe.lambda-url.us-east-1.on.aws/health
```

---

## 🔑 IMPORTANT NOTES

1. **Save the admin password:** `Admin12345678`
2. **VPC Endpoint already created** for blockchain access
3. **Secrets Manager VPC endpoint** already exists
4. **EC2 instance** (i-0ae980f8feb375fcf) is ready to use
5. **S3 bucket** (supplychain-certs-1764607411) ready for certificates

---

## ✅ COMPLETED SO FAR

- [x] New blockchain network created
- [x] Member created with known password
- [x] Peer nodes creating
- [x] VPC endpoints configured
- [x] EC2 instance ready
- [x] S3 bucket ready
- [x] Lambda function deployed
- [x] Frontend UI built

## ⏳ PENDING

- [ ] Wait for peer nodes (5-10 min)
- [ ] Retrieve certificates with correct password
- [ ] Create channel
- [ ] Deploy chaincode
- [ ] Update Lambda with new endpoints
- [ ] Test end-to-end
