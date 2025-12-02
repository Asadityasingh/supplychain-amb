#!/bin/bash
set -e

REGION="us-east-1"
INSTANCE_ID="i-0df0b95e48cc0602a"
S3_BUCKET="supplychain-certs-1764607411"

echo "🧹 Cleaning up EC2 and S3..."

# Terminate EC2 instance
echo "🔴 Terminating EC2 instance..."
aws ec2 terminate-instances --instance-ids $INSTANCE_ID --region $REGION
echo "✅ EC2 instance terminating"

# Clean S3 scripts folder
echo "🗑️  Cleaning S3 scripts..."
aws s3 rm s3://$S3_BUCKET/scripts/ --recursive --region $REGION 2>/dev/null || echo "Scripts folder empty"

# Clean S3 certificates folder
echo "🗑️  Cleaning S3 certificates..."
aws s3 rm s3://$S3_BUCKET/certificates/ --recursive --region $REGION 2>/dev/null || echo "Certificates folder empty"
aws s3 rm s3://$S3_BUCKET/admin-msp/ --recursive --region $REGION 2>/dev/null || echo "Admin-msp folder empty"
aws s3 rm s3://$S3_BUCKET/ca-cert.pem --region $REGION 2>/dev/null || echo "CA cert not found"
aws s3 rm s3://$S3_BUCKET/peer-tls-cert.pem --region $REGION 2>/dev/null || echo "Peer cert not found"

# Remove local instance ID file
rm -f instance-id.txt

# Remove local fabric-certs folder
rm -rf fabric-certs

echo "✅ Cleanup complete"
