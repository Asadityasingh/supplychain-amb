# 🔐 Certificate Retrieval Instructions

## EC2 Instance Ready!

**Instance ID:** `i-0ae980f8feb375fcf`  
**Public IP:** `54.198.191.176`  
**Status:** Running ✅

---

## Step 1: Connect to EC2 Instance

### Option A: AWS Console (Recommended)

1. Open AWS Console: https://console.aws.amazon.com/ec2/
2. Go to **EC2 → Instances**
3. Select instance: `i-0ae980f8feb375fcf`
4. Click **"Connect"** button
5. Choose **"EC2 Instance Connect"** tab
6. Click **"Connect"** button

### Option B: AWS CLI (if you have Session Manager)

```bash
aws ssm start-session --target i-0ae980f8feb375fcf --region us-east-1
```

---

## Step 2: Run Certificate Retrieval Script

Once connected to the EC2 instance, run these commands:

```bash
# Wait for setup to complete (Docker installation)
sleep 30

# Download the certificate retrieval script
aws s3 cp s3://supplychain-certs-1764607411/scripts/step2-retrieve-certificates.sh . --region us-east-1

# Make it executable
chmod +x step2-retrieve-certificates.sh

# Run the script
./step2-retrieve-certificates.sh
```

---

## What the Script Does

1. **Downloads CA TLS Certificate** - Gets the Certificate Authority's TLS cert
2. **Enrolls Admin User** - Registers admin with Fabric CA using password "AdminPassword"
3. **Downloads Peer TLS Certificate** - Gets the peer node's TLS cert
4. **Uploads to S3** - Saves all certificates to S3 bucket

---

## Expected Output

```
🔐 Retrieving blockchain certificates...
📥 Downloading CA TLS certificate...
✅ CA certificate saved
📝 Enrolling admin user...
✅ Admin enrolled successfully
📥 Downloading peer TLS certificate...
✅ Peer TLS certificate saved
☁️  Uploading certificates to S3...
✅ Certificates uploaded to S3

📋 Certificate files:
  - User cert: admin-msp/signcerts/cert.pem
  - Private key: admin-msp/keystore/*_sk
  - CA TLS cert: ca-cert.pem
  - Peer TLS cert: peer-tls-cert.pem
```

---

## Troubleshooting

### If "Unable to locate credentials" error:
The IAM role should already be attached. Wait 30 seconds and retry.

### If "Failed to retrieve CA certificate" error:
The CA endpoint might not be accessible. Check VPC configuration.

### If enrollment fails with wrong password:
Check AWS Managed Blockchain console for the correct admin password.

---

## After Certificates Are Retrieved

Exit the EC2 instance and return to your local terminal, then run:

```bash
cd /home/my/path/of/Projects/supplychain-amb/scripts
bash step4-upload-certs-to-lambda.sh
```

This will:
1. Download certificates from S3
2. Update Lambda environment variables
3. Test blockchain connection
4. Verify everything works

---

## Quick Commands Summary

**On EC2:**
```bash
aws s3 cp s3://supplychain-certs-1764607411/scripts/step2-retrieve-certificates.sh .
chmod +x step2-retrieve-certificates.sh
./step2-retrieve-certificates.sh
```

**On Local Machine (after EC2 completes):**
```bash
cd scripts
bash step4-upload-certs-to-lambda.sh
```

---
