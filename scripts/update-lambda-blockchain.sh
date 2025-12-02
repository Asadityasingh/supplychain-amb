#!/bin/bash

# Update Lambda Environment Variables for Blockchain Integration
# Run this script to connect Lambda to the live blockchain

LAMBDA_FUNCTION="supplyChainAPI-dev"
REGION="us-east-1"

echo "Updating Lambda function: $LAMBDA_FUNCTION"
echo "Connecting to AWS Managed Blockchain..."

# Update environment variables
aws lambda update-function-configuration \
  --function-name $LAMBDA_FUNCTION \
  --region $REGION \
  --environment "Variables={
    PEER_ENDPOINT=nd-zqx2ijvxhbcwzotry5kxm2kdva.m-ktgjmti7hfgtzku7ecmps4fquu.n-cfcacd47iza7dalldsyz32fuzy.managedblockchain.us-east-1.amazonaws.com:30003,
    ORDERER_ENDPOINT=orderer.n-cfcacd47iza7dalldsyz32fuzy.managedblockchain.us-east-1.amazonaws.com:30001,
    CHANNEL_NAME=mychannel,
    CHAINCODE_NAME=supplychain,
    MSP_ID=m-KTGJMTI7HFGTZKU7ECMPS4FQUU,
    NETWORK_ID=n-CFCACD47IZA7DALLDSYZ32FUZY,
    MEMBER_ID=m-KTGJMTI7HFGTZKU7ECMPS4FQUU,
    USE_MOCK_DATA=false
  }"

echo ""
echo "✅ Lambda environment variables updated!"
echo ""
echo "Next steps:"
echo "1. Upload certificates to Lambda layer or S3"
echo "2. Update Lambda code to remove mock data fallback"
echo "3. Test Lambda function"
echo ""
echo "Test command:"
echo "aws lambda invoke --function-name $LAMBDA_FUNCTION --region $REGION response.json"
