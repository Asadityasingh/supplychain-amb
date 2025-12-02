#!/bin/bash
set -e

REGION="us-east-1"
INSTANCE_ID="i-0df0b95e48cc0602a"
ROLE_NAME="EC2-Blockchain-CertRetrieval-Role"
INSTANCE_PROFILE_NAME="EC2-Blockchain-CertRetrieval-Profile"

echo "🔧 Fixing EC2 permissions..."

# Create IAM role
aws iam create-role \
  --role-name $ROLE_NAME \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "ec2.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }' 2>/dev/null || echo "Role already exists"

# Attach S3 policy
aws iam attach-role-policy \
  --role-name $ROLE_NAME \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess 2>/dev/null || echo "Policy already attached"

# Create instance profile
aws iam create-instance-profile \
  --instance-profile-name $INSTANCE_PROFILE_NAME 2>/dev/null || echo "Profile already exists"

# Add role to instance profile
aws iam add-role-to-instance-profile \
  --instance-profile-name $INSTANCE_PROFILE_NAME \
  --role-name $ROLE_NAME 2>/dev/null || echo "Role already in profile"

# Wait for IAM propagation
sleep 5

# Attach instance profile to EC2
aws ec2 associate-iam-instance-profile \
  --instance-id $INSTANCE_ID \
  --iam-instance-profile Name=$INSTANCE_PROFILE_NAME \
  --region $REGION

echo "✅ IAM role attached to EC2 instance"
echo "⏳ Wait 30 seconds for credentials to propagate, then retry the script on EC2"
