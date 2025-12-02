# Supply Chain Tracker - Frontend & Backend Guide

## Overview

This project consists of a Hyperledger Fabric-based supply chain tracking system with a modern React frontend and AWS Lambda backend.

## Project Structure

```
├── amplify/
│   └── backend/
│       └── function/
│           └── supplyChainAPI/    # AWS Lambda function
└── src/ui/                         # React frontend
```

## Backend - AWS Lambda Function

### Location
`amplify/backend/function/supplyChainAPI/src/app.js`

### Deployed Lambda
- **Function Name**: `supplyChainAPI-dev`
- **Function URL**: `https://k4uyws3gmegkpwvbzkywnrisfq0zeoxe.lambda-url.us-east-1.on.aws/`
- **Region**: us-east-1

### Environment Variables
The Lambda function uses the following environment variables:
- `CHANNEL_NAME` - Fabric channel name (default: mychannel)
- `CHAINCODE_NAME` - Chaincode name (default: supplychain)
- `MSP_ID` - Member Service Provider ID (default: Org1MSP)
- `PEER_ENDPOINT` - Peer node endpoint
- `ORDERER_ENDPOINT` - Orderer endpoint
- `USER_CERT` - User certificate for authentication
- `USER_PRIVATE_KEY` - Private key for authentication
- `TLS_CERT` - TLS certificate

### API Endpoints

#### 1. Health Check
```bash
GET /{proxy+}/health
Response: { "status": "running", "timestamp": "2025-12-01T..." }
```

#### 2. Create Asset
```bash
POST /{proxy+}/assets
Body: {
  "assetId": "ASSET-001",
  "name": "Product Name",
  "location": "Warehouse A",
  "owner": "Company Name"
}
Response: { "success": true, "data": {...} }
```

#### 3. Get All Assets
```bash
GET /{proxy+}/assets
Response: { "success": true, "data": [...] }
```

#### 4. Get Asset by ID
```bash
GET /{proxy+}/assets/{assetId}
Response: { "success": true, "data": {...} }
```

#### 5. Transfer Asset
```bash
PUT /{proxy+}/assets/{assetId}/transfer
Body: {
  "newOwner": "New Owner Name",
  "newLocation": "New Location"
}
Response: { "success": true, "data": {...} }
```

### Amplify Deployment

#### Fix Applied
The original API Gateway configuration had conflicting path parameters:
- ❌ `/assets/{id}` and `/assets/{id}/transfer` caused conflicts
- ✅ Fixed by using `/{proxy+}` to catch all paths and route in Lambda

#### Redeploy Backend
```bash
cd /path/to/project
amplify push --yes
```

## Frontend - React Application

### Location
`src/ui/`

### Setup

1. **Install Dependencies**
   ```bash
   cd src/ui
   npm install
   ```

2. **Configure API Endpoint**
   Create `.env.local`:
   ```env
   REACT_APP_API_ENDPOINT=https://k4uyws3gmegkpwvbzkywnrisfq0zeoxe.lambda-url.us-east-1.on.aws
   ```

3. **Run Development Server**
   ```bash
   npm start
   ```
   Open http://localhost:3000 in browser

4. **Build for Production**
   ```bash
   npm run build
   ```
   Output: `build/` directory ready for deployment

### Features

#### 1. Dashboard (📊)
- View all assets in a searchable table
- Filter by owner
- Search by ID, name, or location
- Real-time statistics

#### 2. Create Asset (➕)
- Add new assets to the blockchain
- Track asset creation with form validation
- Automatic refresh after creation

#### 3. Transfer Asset (🔄)
- Transfer ownership and location
- Select from existing assets
- View current asset details before transfer
- Blockchain transaction confirmation

#### 4. Monitor (📡)
- Real-time metrics dashboard
- Top locations and owners charts
- System status indicators
- Asset distribution visualization

### Technologies Used

- **React 19.2.0** - UI Framework
- **Tailwind CSS** - Styling
- **Fetch API** - HTTP Requests
- **React Hooks** - State Management

### Components

- `Dashboard.js` - Asset listing and search
- `CreateAssetForm.js` - Asset creation form
- `TransferAssetForm.js` - Asset transfer form
- `MonitoringPanel.js` - Real-time monitoring dashboard

### Auto-Refresh

- Assets auto-refresh every 10 seconds
- Monitoring metrics update every 5 seconds
- Background refresh keeps data current

## Development Workflow

### Make Backend Changes
```bash
cd amplify/backend/function/supplyChainAPI/src
# Edit app.js
amplify push
```

### Make Frontend Changes
```bash
cd src/ui/src
# Edit components
npm run build  # Test build
npm start      # Dev server
```

### Testing

Frontend builds without warnings (zero ESLint violations):
```bash
cd src/ui
npm run build
npm test      # Run tests (if configured)
```

## Troubleshooting

### Lambda Function Issues
- Check CloudWatch logs: `aws logs tail /aws/lambda/supplyChainAPI-dev --follow`
- Verify environment variables are set
- Check Fabric network connectivity

### Frontend API Connection Failed
- Verify Lambda function URL is correct in `.env.local`
- Check Lambda CORS settings: `aws lambda get-function-url-config --function-name supplyChainAPI-dev`
- Browser console should show detailed fetch errors

### Assets Not Loading
- Check network tab in browser DevTools
- Verify Lambda function is running
- Check Fabric chaincode is deployed

## Deployment

### Frontend Deployment
Serve the `build/` directory using:
- AWS Amplify Hosting
- Vercel/Netlify
- Static S3 bucket with CloudFront
- Any static web host

### Backend Deployment
Backend is already deployed on AWS Lambda. To redeploy:
```bash
amplify push --force
```

## Additional Resources

- Amplify Documentation: https://docs.amplify.aws/
- Hyperledger Fabric: https://hyperledger-fabric.readthedocs.io/
- React Documentation: https://react.dev/
- Tailwind CSS: https://tailwindcss.com/

## Support

For issues or questions:
1. Check CloudWatch logs for backend errors
2. Check browser console for frontend errors
3. Review Lambda function code in `app.js`
4. Verify Fabric network connectivity
