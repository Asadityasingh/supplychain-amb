# AWS Amplify Setup for Supply Chain Project

## Prerequisites
```bash
npm install -g @aws-amplify/cli
amplify configure
```

## Step 1: Initialize Amplify Project
```bash
cd /home/aditya/Documents/programming/Projects/supplychain-amb
amplify init
```

**Configuration:**
- Project name: `supplychain`
- Environment: `dev`
- Default editor: `Visual Studio Code`
- App type: `javascript`
- Framework: `none`
- Source directory: `src`
- Distribution directory: `dist`
- Build command: `npm run build`
- Start command: `npm start`

## Step 2: Add API (REST)
```bash
amplify add api
```

**Configuration:**
- Service: `REST`
- API name: `supplyChainAPI`
- Path: `/assets`
- Lambda source: `Create a new Lambda function`
- Function name: `supplyChainAPI`
- Template: `Serverless ExpressJS function`
- Advanced settings: `Yes`
- Environment variables: `Yes`

**Environment Variables to add:**
- MSP_ID
- PEER_ENDPOINT
- ORDERER_ENDPOINT
- CHANNEL_NAME
- CHAINCODE_NAME
- TLS_CERT
- USER_CERT
- USER_PRIVATE_KEY

## Step 3: Add More API Paths
```bash
amplify update api
```

Add these paths:
- `/assets/{id}`
- `/assets/{id}/transfer`
- `/health`

## Step 4: Deploy
```bash
amplify push
```

## Step 5: Test API
```bash
amplify status
```

Your API endpoint will be displayed after deployment.