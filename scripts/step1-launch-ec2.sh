#!/bin/bash
set -e

# Launch EC2 instance in VPC for blockchain certificate retrieval
# Based on AWS Managed Blockchain documentation

REGION="us-east-1"
VPC_ID="vpc-04f8c3e5590d02480"
SUBNET_ID="subnet-0d38c80717a1ade86"
SECURITY_GROUP="sg-035d562b317e7ccb2"
S3_BUCKET="supplychain-certs-1764607411"

echo "🚀 Launching EC2 instance for blockchain certificate retrieval..."

# Get latest Amazon Linux 2023 AMI
AMI_ID=$(aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=al2023-ami-2023*-x86_64" "Name=state,Values=available" \
  --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
  --output text \
  --region $REGION)

echo "✅ Using AMI: $AMI_ID"

# Create user data script
cat > /tmp/ec2-userdata.sh << 'USERDATA'
#!/bin/bash
yum update -y
yum install -y docker jq openssl aws-cli

systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

docker pull hyperledger/fabric-ca:1.5

mkdir -p /home/ec2-user/fabric-certs
chown -R ec2-user:ec2-user /home/ec2-user/fabric-certs

echo "✅ EC2 ready for certificate retrieval" > /home/ec2-user/setup-complete.txt
USERDATA

# Launch instance
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type t2.micro \
  --subnet-id $SUBNET_ID \
  --security-group-ids $SECURITY_GROUP \
  --user-data file:///tmp/ec2-userdata.sh \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=SupplyChainCertRetrieval}]" \
  --region $REGION \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "✅ Instance launched: $INSTANCE_ID"
echo "⏳ Waiting for instance to be running..."

aws ec2 wait instance-running --instance-ids $INSTANCE_ID --region $REGION

echo "✅ Instance is running"
echo ""
echo "📋 Instance ID: $INSTANCE_ID"
echo "📋 Next: Run step2-retrieve-certificates.sh with this instance ID"
echo ""
echo $INSTANCE_ID > instance-id.txt
