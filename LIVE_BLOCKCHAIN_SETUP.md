# 🚀 Live Blockchain Integration Guide

Your Lambda is now **VPC-enabled** and ready to receive certificates for **live blockchain connection**.

---

## Current Status

- ✅ **Lambda**: Deployed in VPC `vpc-04f8c3e5590d02480` with subnet and security group access
- ✅ **Blockchain**: Hyperledger Fabric 2.2 on AWS Managed Blockchain (STARTER Edition)
- ⏳ **Certificates**: Awaiting X.509 credentials for authentication
- ✅ **Mock Mode**: Working with fallback data

---

## Getting Certificates

### Option 1: Using AWS Systems Manager Session Manager (Recommended)

**Step 1**: Launch an EC2 instance in the VPC
```bash
aws ec2 run-instances \
  --image-id ami-0c55b159cbfafe1f0 \
  --instance-type t2.micro \
  --subnet-id subnet-0d38c80717a1ade86 \
  --region us-east-1
```

**Step 2**: Connect via Session Manager (no SSH key needed)
```bash
aws ssm start-session --target <INSTANCE_ID> --region us-east-1
```

**Step 3**: Inside the EC2 instance, install fabric-ca-client
```bash
curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh
docker pull hyperledger/fabric-ca:1.5
```

**Step 4**: Retrieve CA certificate
```bash
openssl s_client -connect ca.m-i5mmo373lffuthpslbocegjrkm.n-ozfgrzjblfgavhtmceacicx35u.managedblockchain.us-east-1.amazonaws.com:30002 \
  -showcerts < /dev/null 2>/dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > ca-cert.pem
```

**Step 5**: Enroll admin user
```bash
docker run -it -v $(pwd):/data hyperledger/fabric-ca:1.5 fabric-ca-client enroll \
  -u https://admin:12345678@ca.m-i5mmo373lffuthpslbocegjrkm.n-ozfgrzjblfgavhtmceacicx35u.managedblockchain.us-east-1.amazonaws.com:30002 \
  --tls.certfiles /data/ca-cert.pem \
  -M /data/fabric-admin-msp
```

**Step 6**: Download certificates to your local machine
```bash
# From your local machine
aws s3 cp s3://<your-bucket>/fabric-admin-msp . --recursive
```

---

### Option 2: Using AWS Managed Blockchain Dashboard

1. Go to AWS Console → Amazon Managed Blockchain
2. Select Network: **supplychain-fabric-demo**
3. Select Organization: **Org1**
4. Download member certificate package
5. Extract certificate PEM file

---

## Uploading Certificates to Lambda

### Step 1: Prepare certificate files

You need:
- `fabric-admin-msp/signcerts/cert.pem` (user certificate)
- `fabric-admin-msp/keystore/*_sk` (private key)

### Step 2: Make certificates executable

```bash
chmod +x upload-certificates.sh
```

### Step 3: Upload certificates

```bash
./upload-certificates.sh ~/fabric-admin-msp
```

Or manually using curl:

```bash
LAMBDA_URL="https://k4uyws3gmegkpwvbzkywnrisfq0zeoxe.lambda-url.us-east-1.on.aws"

curl -X POST "$LAMBDA_URL/certificates" \
  -H "Content-Type: application/json" \
  -d '{
    "userCert": "'"$(cat fabric-admin-msp/signcerts/cert.pem)"'",
    "userPrivateKey": "'"$(cat fabric-admin-msp/keystore/*_sk)"'",
    "tlsCert": ""
  }'
```

---

## Verifying Live Blockchain Connection

### Check Status

```bash
curl https://k4uyws3gmegkpwvbzkywnrisfq0zeoxe.lambda-url.us-east-1.on.aws/health | jq '.blockchain'
```

Expected output:
```json
{
  "connected": true,
  "network": "n-OZFGRZJBLFGAVHTMCEACICX35U",
  "member": "m-I5MMO373LFFUTHPSLBOCEGJRKM",
  "peer": "nd-xaiao3kjsvd7hjur5a6rpfhl6i.m-i5mmo373lffuthpslbocegjrkm.n-ozfgrzjblfgavhtmceacicx35u.managedblockchain.us-east-1.amazonaws.com:30003",
  "orderer": "orderer.n-ozfgrzjblfgavhtmceacicx35u.managedblockchain.us-east-1.amazonaws.com:30001"
}
```

### Check UI Status

Open your React app and look at the navbar - you should see:
- **Before**: 🔐 Needs Certificates
- **After**: 🔗 Live Blockchain

---

## Troubleshooting

### "Cannot connect from local machine"
**Solution**: AWS Managed Blockchain is VPC-isolated. You must use an EC2 instance in the same VPC or use AWS Systems Manager Session Manager.

### "DNS lookup failed"
**Solution**: Make sure you're running the command from an EC2 instance in the same VPC (`vpc-04f8c3e5590d02480`).

### "Enrollment failed"
**Solution**: Verify username is `admin` and password is `12345678` (or update as needed).

---

## Network Configuration

- **VPC**: `vpc-04f8c3e5590d02480`
- **Subnets**: 
  - `subnet-0d38c80717a1ade86`
  - `subnet-04424a3e27545e05f`
- **Security Group**: `sg-035d562b317e7ccb2`

---

## API Endpoints

### POST /health
Get blockchain connection status
```bash
curl https://k4uyws3gmegkpwvbzkywnrisfq0zeoxe.lambda-url.us-east-1.on.aws/health
```

### POST /certificates
Upload certificates for authentication
```bash
curl -X POST https://k4uyws3gmegkpwvbzkywnrisfq0zeoxe.lambda-url.us-east-1.on.aws/certificates \
  -H "Content-Type: application/json" \
  -d '{
    "userCert": "...",
    "userPrivateKey": "..."
  }'
```

### GET /assets
Get all assets (blockchain or mock)
```bash
curl https://k4uyws3gmegkpwvbzkywnrisfq0zeoxe.lambda-url.us-east-1.on.aws/assets
```

### POST /assets
Create new asset (blockchain or mock)
```bash
curl -X POST https://k4uyws3gmegkpwvbzkywnrisfq0zeoxe.lambda-url.us-east-1.on.aws/assets \
  -H "Content-Type: application/json" \
  -d '{
    "assetId": "ASSET-001",
    "name": "Product Name",
    "location": "Warehouse",
    "owner": "Company"
  }'
```

---

## Next Steps

1. ✅ **Create EC2 instance** in your VPC
2. ✅ **Retrieve certificates** using fabric-ca-client
3. ✅ **Upload certificates** to Lambda  
4. ✅ **Verify connection** status via health endpoint
5. ✅ **Start using live blockchain** for asset tracking

---

**Questions?** Check Lambda logs:
```bash
aws logs tail /aws/lambda/supplyChainAPI-dev --follow
```
