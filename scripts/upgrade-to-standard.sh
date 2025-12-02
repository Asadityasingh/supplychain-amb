#!/bin/bash
set -e

echo "=========================================="
echo "Upgrade to STANDARD Edition"
echo "=========================================="
echo ""
echo "STARTER edition does NOT support channels."
echo "You must create a new STANDARD edition network."
echo ""
echo "Cost Estimate:"
echo "  - Network: ~$0.30/hour (~$216/month)"
echo "  - Per peer node: ~$0.07/hour (~$50/month per peer)"
echo "  - Total for 2 peers: ~$316/month"
echo ""
echo "Steps to upgrade:"
echo ""
echo "1. Delete current STARTER network (optional - keep for reference)"
echo ""
echo "2. Create STANDARD network via AWS Console:"
echo "   - Go to: https://console.aws.amazon.com/managedblockchain"
echo "   - Click 'Create network'"
echo "   - Choose: Hyperledger Fabric 2.2"
echo "   - Edition: STANDARD"
echo "   - Network name: supplychain-fabric-standard"
echo "   - Member name: Org1"
echo "   - Admin password: Admin12345678"
echo ""
echo "3. Or create via AWS CLI:"
echo ""
cat << 'EOFCLI'
aws managedblockchain create-network \
  --network-configuration '{
    "Name": "supplychain-fabric-standard",
    "Description": "Supply Chain Blockchain - STANDARD Edition",
    "Framework": "HYPERLEDGER_FABRIC",
    "FrameworkVersion": "2.2",
    "FrameworkConfiguration": {
      "Fabric": {
        "Edition": "STANDARD"
      }
    },
    "VotingPolicy": {
      "ApprovalThresholdPolicy": {
        "ThresholdPercentage": 50,
        "ProposalDurationInHours": 24,
        "ThresholdComparator": "GREATER_THAN"
      }
    }
  }' \
  --member-configuration '{
    "Name": "Org1",
    "Description": "Supply Chain Manufacturer Org",
    "FrameworkConfiguration": {
      "Fabric": {
        "AdminUsername": "admin",
        "AdminPassword": "Admin12345678"
      }
    }
  }' \
  --region us-east-1
EOFCLI

echo ""
echo "4. After network is created, update scripts with new IDs"
echo ""
echo "5. Re-run all setup scripts - they will work immediately!"
echo ""
echo "=========================================="
