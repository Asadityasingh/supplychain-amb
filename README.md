# Supply Chain Tracker on AWS Managed Blockchain

A production-grade blockchain-based supply chain tracking system built with Hyperledger Fabric on AWS Managed Blockchain, providing immutable asset tracking and complete audit trails.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Features](#features)
- [Technology Stack](#technology-stack)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [API Documentation](#api-documentation)
- [Deployment](#deployment)
- [Security](#security)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## Overview

This application provides an enterprise-grade solution for tracking assets through supply chains using blockchain technology. Built on AWS Managed Blockchain with Hyperledger Fabric, it ensures data immutability, transparency, and complete audit trails for all asset movements.

### Key Benefits

- **Immutable Records**: All transactions are permanently recorded on the blockchain
- **Complete Audit Trail**: Track every asset movement from creation to current state
- **Transparency**: All authorized parties can view asset history
- **Fraud Prevention**: Cryptographic signatures prevent tampering
- **Real-time Tracking**: Monitor asset location and ownership changes instantly
- **Regulatory Compliance**: Maintain comprehensive records for auditing

## Architecture

### System Architecture

```
┌─────────────┐      ┌──────────────┐      ┌─────────────────┐
│   React UI  │─────▶│  API Gateway │─────▶│  Lambda (VPC)   │
└─────────────┘      └──────────────┘      └────────┬────────┘
                                                     │
                                                     ▼
                                          ┌──────────────────┐
                                          │  Fabric Network  │
                                          │   (AMB - VPC)    │
                                          └──────────────────┘
                                                     │
                                    ┌────────────────┼────────────────┐
                                    ▼                ▼                ▼
                              ┌─────────┐    ┌──────────┐    ┌──────────┐
                              │  Peer   │    │ Orderer  │    │    CA    │
                              │  Node   │    │  (RAFT)  │    │  Server  │
                              └─────────┘    └──────────┘    └──────────┘
```

### Components

#### Frontend Layer
- **React Application**: Modern SPA with Bootstrap UI
- **Real-time Updates**: Polling mechanism for blockchain status
- **Responsive Design**: Mobile-friendly interface

#### API Layer
- **AWS Lambda**: Serverless compute with Node.js 22.x
- **API Gateway**: RESTful API endpoints
- **VPC Integration**: Secure access to blockchain network

#### Blockchain Layer
- **Hyperledger Fabric**: Permissioned blockchain framework
- **AWS Managed Blockchain**: Fully managed blockchain service
- **RAFT Consensus**: Crash fault-tolerant ordering service
- **Smart Contracts**: JavaScript chaincode for business logic

#### Security Layer
- **X.509 Certificates**: Identity and authentication
- **AWS Secrets Manager**: Secure credential storage
- **VPC Security Groups**: Network isolation
- **TLS Encryption**: Secure communication channels

## Features

### Core Functionality

- **Asset Creation**: Register new assets with metadata
- **Asset Transfer**: Transfer ownership and update location
- **Asset Query**: Retrieve current asset state
- **Asset History**: View complete transaction history
- **Batch Operations**: Query all assets efficiently

### Advanced Features

- **Mock Mode Fallback**: Graceful degradation when blockchain unavailable
- **Transaction ID Tracking**: Unique identifier for every operation
- **Real-time Status**: Live blockchain connection monitoring
- **Search & Filter**: Advanced asset discovery
- **Audit Trail**: Complete history of all changes

## Technology Stack

### Frontend
- React 19.2.0
- Bootstrap 5.3.3
- Axios 1.13.2
- React Scripts 5.0.1

### Backend
- Node.js 22.x
- AWS Lambda
- Hyperledger Fabric Network SDK 2.2.x
- AWS SDK for JavaScript

### Blockchain
- Hyperledger Fabric 2.x
- AWS Managed Blockchain
- RAFT Consensus Algorithm

### Infrastructure
- AWS Amplify
- AWS Lambda
- AWS Secrets Manager
- Amazon VPC
- AWS CloudFormation

## Prerequisites

### Required Tools
- Node.js 18.x or higher
- npm 9.x or higher
- AWS CLI 2.x
- Amplify CLI 12.x or higher
- AWS Account with appropriate permissions

### AWS Services Access
- AWS Managed Blockchain
- AWS Lambda
- AWS Secrets Manager
- Amazon VPC
- AWS Amplify

### Blockchain Requirements
- Hyperledger Fabric network on AWS Managed Blockchain
- X.509 certificates (admin user)
- TLS certificates for secure communication
- VPC with private subnets

## Installation

### 1. Clone Repository

```bash
git clone https://github.com/Asadityasingh/supplychain-amb
cd supplychain-amb
```

### 2. Install Frontend Dependencies

```bash
cd src/ui
npm install
```

### 3. Install Backend Dependencies

```bash
cd amplify/backend/function/supplyChainAPI/src
npm install
```

### 4. Configure AWS Amplify

```bash
amplify init
amplify push
```

## Configuration

### Environment Variables

#### Lambda Function

Create or update environment variables in AWS Lambda console or CloudFormation template:

```bash
PEER_ENDPOINT=<your-peer-endpoint>:30003
ORDERER_ENDPOINT=<your-orderer-endpoint>:30001
CA_ENDPOINT=<your-ca-endpoint>:30002
MSP_ID=<your-msp-id>
MEMBER_ID=<your-member-id>
NETWORK_ID=<your-network-id>
CHANNEL_NAME=mychannel
CHAINCODE_NAME=supplychain
REGION=us-east-1
```

#### Frontend

Create `.env.production` in `src/ui/`:

```bash
REACT_APP_API_ENDPOINT=https://your-api-gateway-url
```

### AWS Secrets Manager

Store blockchain credentials in AWS Secrets Manager:

```bash
aws secretsmanager create-secret \
  --name blockchain/fabric-admin-credentials \
  --secret-string '{
    "userCert": "-----BEGIN CERTIFICATE-----\n...",
    "userPrivateKey": "-----BEGIN PRIVATE KEY-----\n...",
    "tlsCert": "-----BEGIN CERTIFICATE-----\n...",
    "caTlsCert": "-----BEGIN CERTIFICATE-----\n..."
  }'
```

### VPC Configuration

Ensure Lambda function has:
- VPC ID with access to AMB endpoints
- Private subnets in multiple AZs
- Security group allowing outbound HTTPS (443) and gRPC (30001-30003)
- NAT Gateway for internet access (if needed)

## API Documentation

### Base URL

```
https://your-api-gateway-url
```

### Endpoints

#### Health Check

```http
GET /health
```

**Response:**
```json
{
  "status": "running",
  "timestamp": "2024-01-15T10:30:00.000Z",
  "blockchain": {
    "connected": true,
    "network": "n-CFCACD47IZA7DALLDSYZ32FUZY",
    "member": "m-KTGJMTI7HFGTZKU7ECMPS4FQUU",
    "peer": "nd-zqx2ijvxhbcwzotry5kxm2kdva...",
    "orderer": "orderer.n-cfcacd47iza7dalldsyz32fuzy..."
  }
}
```

#### Upload Certificates

```http
POST /certificates
Content-Type: application/json

{
  "userCert": "-----BEGIN CERTIFICATE-----\n...",
  "userPrivateKey": "-----BEGIN PRIVATE KEY-----\n...",
  "tlsCert": "-----BEGIN CERTIFICATE-----\n...",
  "caTlsCert": "-----BEGIN CERTIFICATE-----\n..."
}
```

#### Get All Assets

```http
GET /assets
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "ID": "ASSET-001",
      "Name": "Product X",
      "Location": "Warehouse A",
      "Owner": "Manufacturer Ltd",
      "Timestamp": "2024-01-15T10:00:00.000Z",
      "TransactionId": "abc123..."
    }
  ],
  "source": "blockchain"
}
```

#### Create Asset

```http
POST /assets
Content-Type: application/json

{
  "assetId": "ASSET-001",
  "name": "Product X",
  "location": "Warehouse A",
  "owner": "Manufacturer Ltd"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "ID": "ASSET-001",
    "name": "Product X",
    "location": "Warehouse A",
    "owner": "Manufacturer Ltd",
    "timestamp": "2024-01-15T10:00:00.000Z",
    "transactionId": "abc123..."
  },
  "source": "blockchain",
  "transactionId": "abc123..."
}
```

#### Get Asset by ID

```http
GET /assets/{assetId}
```

#### Transfer Asset

```http
PUT /assets/{assetId}/transfer
Content-Type: application/json

{
  "newOwner": "Distributor Inc",
  "newLocation": "Distribution Center B"
}
```

#### Get Asset History

```http
GET /assets/{assetId}/history
```

## Deployment

### Deploy Chaincode

```bash
# Package chaincode
cd chaincode/supplychain-js
tar -czf supplychain.tar.gz *

# Install on peer (via AWS Console or CLI)
# Approve and commit chaincode definition
```

### Deploy Backend

```bash
# Deploy Lambda function
cd amplify
amplify push

# Or use CloudFormation
aws cloudformation deploy \
  --template-file backend/function/supplyChainAPI/supplyChainAPI-cloudformation-template.json \
  --stack-name supplychain-api \
  --capabilities CAPABILITY_NAMED_IAM
```

### Deploy Frontend

```bash
cd src/ui
npm run build

# Deploy to Amplify Hosting
amplify publish

# Or deploy to S3 + CloudFront
aws s3 sync build/ s3://your-bucket-name
```

## Security

### Best Practices

1. **Certificate Management**
   - Store certificates in AWS Secrets Manager
   - Rotate certificates regularly
   - Use separate certificates per environment

2. **Network Security**
   - Deploy Lambda in private VPC subnets
   - Use security groups to restrict access
   - Enable VPC Flow Logs for monitoring

3. **API Security**
   - Implement API Gateway authentication
   - Use AWS WAF for DDoS protection
   - Enable CloudWatch logging

4. **Access Control**
   - Follow principle of least privilege
   - Use IAM roles for service-to-service communication
   - Enable MFA for AWS console access

### Compliance

- GDPR: Personal data handling guidelines
- HIPAA: Healthcare data protection (if applicable)
- SOC 2: Security and availability controls

## Monitoring

### CloudWatch Metrics

Monitor key metrics:
- Lambda invocation count and duration
- API Gateway 4xx/5xx errors
- Blockchain connection success rate
- Transaction throughput

### Logging

```bash
# View Lambda logs
aws logs tail /aws/lambda/supplyChainAPI --follow

# View API Gateway logs
aws logs tail /aws/apigateway/your-api-id --follow
```

### Alerts

Set up CloudWatch alarms for:
- Lambda errors > threshold
- API latency > 3 seconds
- Blockchain connection failures
- Certificate expiration warnings

## Troubleshooting

### Common Issues

#### Blockchain Connection Failed

**Symptom**: "Fabric network module not available" or connection timeout

**Solutions**:
1. Verify VPC configuration and security groups
2. Check certificate validity
3. Confirm AMB network is active
4. Verify Lambda has VPC permissions

#### Certificate Errors

**Symptom**: "User certificate or private key not found"

**Solutions**:
1. Verify Secrets Manager secret exists
2. Check IAM permissions for Lambda
3. Validate certificate format (PEM)
4. Ensure certificates match the network

#### Lambda Timeout

**Symptom**: Task timed out after 60 seconds

**Solutions**:
1. Increase Lambda timeout
2. Optimize chaincode queries
3. Check network latency
4. Review VPC NAT Gateway configuration

### Debug Mode

Enable detailed logging:

```javascript
// In app.js
console.log('Debug:', JSON.stringify(event, null, 2));
```

## Performance Optimization

### Caching Strategy

- Credential caching in Lambda
- Connection profile caching
- API Gateway response caching

### Scaling Considerations

- Lambda concurrent execution limits
- API Gateway throttling limits
- Blockchain transaction throughput
- VPC ENI limits

## Contributing

### Development Workflow

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

### Code Standards

- ESLint configuration for JavaScript
- Prettier for code formatting
- Conventional Commits for commit messages
- Unit tests for new features

## Support

For issues and questions:
- GitHub Issues: https://github.com/Asadityasingh/supplychain-amb/issues
- Documentation: https://github.com/Asadityasingh/supplychain-amb/blob/main/FINAL_DOCUMENTATION.md
- DEPLOYMENT FROM SCRATCH Documentation: https://github.com/Asadityasingh/supplychain-amb/blob/main/DEPLOYMENT_FROM_SCRATCH.md
- Email: as25822@gmail.com

## Acknowledgments

- AWS Managed Blockchain team
- Hyperledger Fabric community
- AWS Amplify team

---

**Version**: 1.1.0  
**Last Updated**: 2025-11-03  
**Maintainer**: Aditya Singh as25822@gmail.ccom
