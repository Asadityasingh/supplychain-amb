# 🚀 Quick Reference Guide

## Live URLs
- **Frontend**: http://supplychain-amb-frontend-1764697282.s3-website-us-east-1.amazonaws.com
- **API**: https://k4uyws3gmegkpwvbzkywnrisfq0zeoxe.lambda-url.us-east-1.on.aws

## Quick Commands

### Test API
```bash
# Health check
curl https://k4uyws3gmegkpwvbzkywnrisfq0zeoxe.lambda-url.us-east-1.on.aws/health | jq

# Get all assets
curl https://k4uyws3gmegkpwvbzkywnrisfq0zeoxe.lambda-url.us-east-1.on.aws/assets | jq

# Create asset
curl -X POST https://k4uyws3gmegkpwvbzkywnrisfq0zeoxe.lambda-url.us-east-1.on.aws/assets \
  -H "Content-Type: application/json" \
  -d '{"assetId":"test001","name":"TestProduct","location":"Mumbai","owner":"TestCo"}' | jq
```

### Deploy Frontend
```bash
cd src/ui
npm run build
aws s3 sync build/ s3://supplychain-amb-frontend-1764697282/ --delete --region us-east-1
```

### Deploy Lambda
```bash
amplify push --yes
```

### Check Logs
```bash
aws logs tail /aws/lambda/supplyChainAPI-dev --follow
```

## Infrastructure IDs

```
Network: n-CFCACD47IZA7DALLDSYZ32FUZY
Member: m-KTGJMTI7HFGTZKU7ECMPS4FQUU
Peer 1: nd-ZQX2IJVXHBCWZOTRY5KXM2KDVA
Peer 2: nd-SGSP9ANBDZQFPXJEJHWAVQVCI
Channel: mychannel
Chaincode: supplychain v3.0
Lambda: supplyChainAPI-dev
S3 Bucket: supplychain-amb-frontend-1764697282
VPC: vpc-04f8c3e5590d02480
```

## Cost Summary

**Development**: $7.72  
**Monthly (if active)**: $353.26  
**Demo (2 hours)**: ~$1.00

## Key Features

✅ Create assets on blockchain  
✅ Transfer asset ownership  
✅ Real-time monitoring  
✅ Transaction ID tracking  
✅ Live blockchain connection  
✅ Responsive UI  

## Tech Stack

- **Frontend**: React 19.2.0 + Bootstrap 5
- **Backend**: AWS Lambda (Node.js 22.x)
- **Blockchain**: Hyperledger Fabric 1.4
- **Infrastructure**: AWS Managed Blockchain STANDARD

## Status

🟢 **LIVE & OPERATIONAL**

Last Updated: December 3, 2025
