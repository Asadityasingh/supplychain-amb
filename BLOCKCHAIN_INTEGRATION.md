# Amazon Managed Blockchain Integration Guide

## Status: ✅ CONFIGURED

Your supply chain application is now integrated with **Amazon Managed Blockchain - Hyperledger Fabric**.

---

## Blockchain Configuration

### Network Details
- **Network ID**: `n-OZFGRZJBLFGAVHTMCEACICX35U`
- **Network Name**: `supplychain-fabric-demo`
- **Framework**: Hyperledger Fabric 2.2
- **Edition**: STARTER
- **Status**: AVAILABLE ✅

### Member (Organization) Details
- **Member ID**: `m-I5MMO373LFFUTHPSLBOCEGJRKM`
- **Member Name**: `Org1`
- **Description**: Supply Chain Manufacturer Org
- **MSP ID**: `Org1MSP`
- **Status**: AVAILABLE ✅

### Blockchain Endpoints
- **Peer Endpoint**: `nd-xaiao3kjsvd7hjur5a6rpfhl6i.m-i5mmo373lffuthpslbocegjrkm.n-ozfgrzjblfgavhtmceacicx35u.managedblockchain.us-east-1.amazonaws.com:30003`
- **Orderer Endpoint**: `orderer.n-ozfgrzjblfgavhtmceacicx35u.managedblockchain.us-east-1.amazonaws.com:30001`
- **CA Endpoint**: `ca.m-i5mmo373lffuthpslbocegjrkm.n-ozfgrzjblfgavhtmceacicx35u.managedblockchain.us-east-1.amazonaws.com:30002`

### Peer Nodes
| Node ID | Status | Instance Type | Zone |
|---------|--------|---------------|------|
| `nd-XAIAO3KJSVD7HJUR5A6RPFHL6I` | AVAILABLE ✅ | bc.t3.small | us-east-1a |
| `nd-IZLSTIENJJFQ3E2Z6RE6TALQSQ` | AVAILABLE ✅ | bc.t3.small | us-east-1b |

---

## Lambda Configuration

### Environment Variables Set
```
PEER_ENDPOINT=nd-xaiao3kjsvd7hjur5a6rpfhl6i.m-i5mmo373lffuthpslbocegjrkm.n-ozfgrzjblfgavhtmceacicx35u.managedblockchain.us-east-1.amazonaws.com:30003
ORDERER_ENDPOINT=orderer.n-ozfgrzjblfgavhtmceacicx35u.managedblockchain.us-east-1.amazonaws.com:30001
CA_ENDPOINT=ca.m-i5mmo373lffuthpslbocegjrkm.n-ozfgrzjblfgavhtmceacicx35u.managedblockchain.us-east-1.amazonaws.com:30002
CHANNEL_NAME=mychannel
CHAINCODE_NAME=supplychain
MSP_ID=Org1MSP
MEMBER_ID=m-I5MMO373LFFUTHPSLBOCEGJRKM
NETWORK_ID=n-OZFGRZJBLFGAVHTMCEACICX35U
```

### Remaining Configuration Needed

To enable **LIVE BLOCKCHAIN** connection, you need to add:

```
USER_CERT=<X.509 certificate>
USER_PRIVATE_KEY=<Private key>
TLS_CERT=<TLS CA certificate>
CA_TLS_CERT=<CA TLS certificate>
```

---

## How to Get Certificates

### Option 1: Using AWS Managed Blockchain Dashboard
1. Go to AWS Console → Amazon Managed Blockchain → Networks → `supplychain-fabric-demo`
2. Click on Organization → `Org1`
3. Download member certificate and key files
4. Extract certificate PEM content and set as environment variables

### Option 2: Using Fabric CA Client
```bash
# Download CA certificate
openssl s_client -connect ca.m-i5mmo373lffuthpslbocegjrkm.n-ozfgrzjblfgavhtmceacicx35u.managedblockchain.us-east-1.amazonaws.com:30002 -showcerts 2>/dev/null | grep -A999 "BEGIN CERTIFICATE" | head -30

# Enroll user with CA
fabric-ca-client enroll -u https://admin:admin-password@ca.m-i5mmo373lffuthpslbocegjrkm.n-ozfgrzjblfgavhtmceacicx35u.managedblockchain.us-east-1.amazonaws.com:30002 --csr.hosts peer-host
```

---

## Current Status

### ✅ What Works
- ✅ Lambda Function URL accessible
- ✅ CORS headers properly configured
- ✅ Mock data fallback working
- ✅ Blockchain endpoints configured
- ✅ UI shows blockchain status
- ✅ Health endpoint returns blockchain info

### ⚠️ What's Pending
- ⏳ User certificates for blockchain authentication
- ⏳ TLS certificates for secure peer/orderer connection
- ⏳ Live blockchain asset creation and transfer

### 📊 UI Status Indicators
- **🔐 Needs Certificates** (Current): Blockchain configured but missing credentials
- **⚙️ Blockchain Ready**: All certificates provided, ready for transactions
- **🔗 Live Blockchain**: Connected and transacting with real blockchain
- **📦 Mock Data**: Using fallback mock data mode

---

## Testing the Connection

### Check Health Status
```bash
curl https://k4uyws3gmegkpwvbzkywnrisfq0zeoxe.lambda-url.us-east-1.on.aws/health
```

**Expected Response:**
```json
{
  "status": "running",
  "blockchain": {
    "connected": false,
    "error": "User certificate or private key not found in environment",
    "network": "n-OZFGRZJBLFGAVHTMCEACICX35U",
    "member": "m-I5MMO373LFFUTHPSLBOCEGJRKM"
  }
}
```

### Create Asset (Uses Mock Until Certificates Provided)
```bash
curl -X POST https://k4uyws3gmegkpwvbzkywnrisfq0zeoxe.lambda-url.us-east-1.on.aws/assets \
  -H "Content-Type: application/json" \
  -d '{
    "assetId": "ASSET-TEST-001",
    "name": "Test Product",
    "location": "Warehouse A",
    "owner": "Manufacturer Ltd"
  }'
```

---

## Next Steps

### To Enable Live Blockchain:

1. **Get Certificates from AWS AMB**
   - Download from AWS Console or use Fabric CA

2. **Update Lambda Environment Variables**
   ```bash
   aws lambda update-function-configuration \
     --function-name supplyChainAPI-dev \
     --environment "Variables={...,USER_CERT='<cert-content>',USER_PRIVATE_KEY='<key-content>',TLS_CERT='<tls-cert>',CA_TLS_CERT='<ca-tls-cert>'}"
   ```

3. **Test Live Connection**
   - Check health endpoint for "connected": true
   - Create asset through UI
   - Assets will be recorded on Hyperledger Fabric blockchain

4. **Monitor Transactions**
   - View all assets created on blockchain
   - Track asset transfers
   - Query historical data from immutable ledger

---

## Architecture

```
┌─────────────────────┐
│   React UI Browser  │
│  (localhost:3000)   │
└──────────┬──────────┘
           │ HTTP/CORS
           ▼
┌─────────────────────┐
│ AWS Lambda Function │
│  (supplyChainAPI)   │
└──────────┬──────────┘
           │ gRPC/TLS
           ▼
┌─────────────────────────────────────┐
│ Amazon Managed Blockchain (Fabric)  │
│ ┌─────────────────────────────────┐ │
│ │ Peer0 (bc.t3.small, us-east-1a)│ │
│ ├─────────────────────────────────┤ │
│ │ Peer1 (bc.t3.small, us-east-1b)│ │
│ ├─────────────────────────────────┤ │
│ │ Orderer (Consensus)             │ │
│ ├─────────────────────────────────┤ │
│ │ CA (Member Certificate Auth)    │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

---

## Troubleshooting

### "Fabric network module not available"
- fabric-network npm package is installed
- This appears during blockchain connection attempts before certificates are available

### "User certificate or private key not found"
- Add USER_CERT and USER_PRIVATE_KEY to Lambda environment variables

### Connection timeout
- Verify peer/orderer endpoints are accessible from Lambda
- Check security groups allow port 30001, 30002, 30003

### Channel not found
- Ensure CHANNEL_NAME matches the actual channel on blockchain
- Verify peer is part of the channel

---

## Support & Documentation

- **AWS Managed Blockchain Docs**: https://docs.aws.amazon.com/managed-blockchain/
- **Hyperledger Fabric Docs**: https://hyperledger-fabric.readthedocs.io/
- **fabric-network SDK**: https://github.com/hyperledger/fabric-sdk-node

