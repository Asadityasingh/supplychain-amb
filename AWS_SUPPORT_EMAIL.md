# AWS Support Request - Managed Blockchain Chaincode Instantiation Issue

---

**Subject**: Chaincode Instantiation Failure - Orderer TLS Certificate Error on AWS Managed Blockchain

---

**To**: AWS Support Team

**Priority**: High

**Service**: AWS Managed Blockchain (Hyperledger Fabric)

**Region**: us-east-1

---

## Issue Summary

I am unable to instantiate chaincode on my AWS Managed Blockchain STANDARD network due to persistent TLS handshake failures when connecting to the orderer endpoint. The chaincode has been successfully packaged with vendored dependencies and installed on the peer, but instantiation fails with certificate validation errors.

---

## Environment Details

**Network Information**:
- Network ID: `n-CFCACD47IZA7DALLDSYZ32FUZY`
- Member ID: `m-KTGJMTI7HFGTZKU7ECMPS4FQUU`
- Edition: STANDARD
- Framework: Hyperledger Fabric 2.2
- Region: us-east-1

**Peer Nodes**:
- Peer 1: `nd-ZQX2IJVXHBCWZOTRY5KXM2KDVA` (us-east-1a)
- Peer 2: `nd-SGEPHKNBOZDQFPXUFJEJW4OVCI` (us-east-1b)
- Instance Type: bc.t3.small

**Channel**:
- Name: `mychannel`
- Status: Created and operational
- Peer joined successfully

**Chaincode**:
- Name: `supplychain`
- Version: `1.0`
- Language: Go
- Package ID: `supplychain_1:000532f5a94f0b2611112213a706c6c2e55b0a0d6b276b8edfd2ca132fe67f55`
- Status: Installed on peer (verified with `peer lifecycle chaincode queryinstalled`)
- Dependencies: Fully vendored (2.5MB package)

**Client Environment**:
- EC2 Instance: Amazon Linux 2023
- Fabric Tools: v2.2.3
- Peer CLI: Configured and operational for peer operations

---

## Error Description

When attempting to instantiate chaincode using either Fabric 1.4 or 2.2 lifecycle commands, I receive TLS handshake failures when connecting to the orderer endpoint.

### Error Messages

**Fabric 2.2 Lifecycle (approveformyorg)**:
```
Error: proposal failed with status: 500 - cannot use new lifecycle for channel 'mychannel' 
as it does not have the required capabilities enabled
```

**Fabric 1.4 Lifecycle (instantiate)**:
```
2025-12-02 10:32:30.956 UTC [comm.tls] ClientHandshake -> ERRO 001 
Client TLS handshake failed after 3.097967ms with error: 
x509: certificate signed by unknown authority remoteaddress=172.31.13.187:30001

Error: error getting broadcast client: orderer client failed to connect to 
orderer.n-cfcacd47iza7dalldsyz32fuzy.managedblockchain.us-east-1.amazonaws.com:30001: 
failed to create new connection: context deadline exceeded
```

---

## Steps Taken

### Successful Steps:
1. ✅ Created STANDARD network and member
2. ✅ Created two peer nodes
3. ✅ Enrolled admin certificates via fabric-ca-client
4. ✅ Created channel 'mychannel' successfully
5. ✅ Joined peer to channel
6. ✅ Developed chaincode with vendored Fabric dependencies
7. ✅ Packaged chaincode using `peer lifecycle chaincode package`
8. ✅ Installed chaincode on peer using `peer lifecycle chaincode install`
9. ✅ Verified installation with `peer lifecycle chaincode queryinstalled`

### Failed Steps:
1. ❌ Approve chaincode for organization (Fabric 2.2 lifecycle)
2. ❌ Instantiate chaincode (Fabric 1.4 lifecycle)

### Certificates Tried:
1. `/home/ec2-user/fabric-certs-standard/orderer-tls-cert.pem` - Downloaded from AWS
2. `/home/ec2-user/fabric-certs-standard/peer-tls-cert.pem` - Works for peer operations
3. Amazon Root CA1 from https://www.amazontrust.com/repository/AmazonRootCA1.pem

### Commands Attempted:

**Fabric 2.2 Lifecycle**:
```bash
peer lifecycle chaincode approveformyorg \
  -o orderer.n-cfcacd47iza7dalldsyz32fuzy.managedblockchain.us-east-1.amazonaws.com:30001 \
  --tls \
  --cafile /home/ec2-user/fabric-certs-standard/orderer-tls-cert.pem \
  --channelID mychannel \
  --name supplychain \
  --version 1 \
  --package-id supplychain_1:000532f5a94f0b2611112213a706c6c2e55b0a0d6b276b8edfd2ca132fe67f55 \
  --sequence 1
```
Result: "cannot use new lifecycle for channel 'mychannel' as it does not have the required capabilities enabled"

**Fabric 1.4 Lifecycle**:
```bash
peer chaincode instantiate \
  -o orderer.n-cfcacd47iza7dalldsyz32fuzy.managedblockchain.us-east-1.amazonaws.com:30001 \
  --tls \
  --cafile /home/ec2-user/fabric-certs-standard/orderer-tls-cert.pem \
  -C mychannel \
  -n supplychain \
  -v 1.0 \
  -c '{"Args":[]}' \
  -P "OR('m-KTGJMTI7HFGTZKU7ECMPS4FQUU.member')"
```
Result: TLS handshake failure with orderer

---

## Questions for AWS Support

1. **Orderer TLS Certificate**: What is the correct method to obtain and configure the orderer TLS certificate for chaincode instantiation on AWS Managed Blockchain?

2. **Channel Capabilities**: How can I enable Fabric 2.2 lifecycle capabilities on an existing channel, or should I recreate the channel with V2_0 capabilities?

3. **Lifecycle Version**: Which chaincode lifecycle should I use with AWS Managed Blockchain Fabric 2.2 - the new lifecycle (approve/commit) or old lifecycle (instantiate)?

4. **Alternative Deployment**: Can chaincode be deployed via the AWS Console or AWS CLI instead of using peer CLI commands?

5. **Certificate Chain**: Is there a complete certificate chain file I should be using for the orderer endpoint?

---

## Expected Outcome

I need to successfully instantiate/deploy the chaincode on channel 'mychannel' so that:
1. The chaincode is running and accessible
2. I can invoke chaincode functions via peer CLI
3. My Lambda function can interact with the chaincode via fabric-network SDK

---

## Additional Context

- This is a supply chain tracking application with CRUD operations for assets
- The chaincode has been tested locally and works correctly
- All dependencies are vendored to avoid internet access issues in the build environment
- Peer-to-peer communication works fine (channel creation, peer join)
- Only orderer communication fails during instantiation

---

## Urgency

The network has been running for ~10 hours at $0.30/hour. I would like to resolve this issue within 24 hours to minimize costs while completing the deployment.

---

## Attachments

If needed, I can provide:
1. Complete chaincode package (supplychain.tar.gz)
2. Channel configuration file
3. Full error logs
4. Certificate files (redacted if necessary)
5. Environment configuration details

---

## Contact Information

Please respond via email or AWS Support Console. I am available for any clarifying questions or additional troubleshooting steps.

Thank you for your assistance.

---

**Case Type**: Technical Support
**Severity**: High (Production deployment blocked)
**Category**: AWS Managed Blockchain - Hyperledger Fabric
