#!/bin/bash

# Read certificates as single line
USER_CERT=$(cat certs/cert.pem | awk '{printf "%s\\n", $0}')
USER_KEY=$(cat certs/key.pem | awk '{printf "%s\\n", $0}')
TLS_CERT=$(cat certs/ca.pem | awk '{printf "%s\\n", $0}')

# Update Lambda
aws lambda update-function-configuration \
  --function-name supplyChainAPI-dev \
  --region us-east-1 \
  --environment "Variables={PEER_ENDPOINT=nd-zqx2ijvxhbcwzotry5kxm2kdva.m-ktgjmti7hfgtzku7ecmps4fquu.n-cfcacd47iza7dalldsyz32fuzy.managedblockchain.us-east-1.amazonaws.com:30003,ORDERER_ENDPOINT=orderer.n-cfcacd47iza7dalldsyz32fuzy.managedblockchain.us-east-1.amazonaws.com:30001,CHANNEL_NAME=mychannel,CHAINCODE_NAME=supplychain,MSP_ID=m-KTGJMTI7HFGTZKU7ECMPS4FQUU,USE_MOCK_DATA=false,USER_CERT=$USER_CERT,USER_PRIVATE_KEY=$USER_KEY,TLS_CERT=$TLS_CERT}" \
  --query 'FunctionArn' --output text

echo "Lambda updated with certificates"
