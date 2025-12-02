#!/bin/bash

CA_ENDPOINT="ca.m-i5mmo373lffuthpslbocegjrkm.n-ozfgrzjblfgavhtmceacicx35u.managedblockchain.us-east-1.amazonaws.com:30002"
ADMIN_USERNAME="admin"
ADMIN_PASSWORD="12345678"
OUTPUT_DIR="certificates"

mkdir -p "$OUTPUT_DIR"

echo "🔗 Retrieving CA TLS Certificate from AWS Managed Blockchain..."
echo "Note: This must be run from an EC2 instance in the same VPC or from AWS Systems Manager Session Manager"
echo ""

openssl s_client -connect "$CA_ENDPOINT" -showcerts < /dev/null 2>/dev/null | \
  sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > "$OUTPUT_DIR/ca-cert.pem"

if [ -s "$OUTPUT_DIR/ca-cert.pem" ]; then
    echo "✅ CA Certificate saved to $OUTPUT_DIR/ca-cert.pem"
    cat "$OUTPUT_DIR/ca-cert.pem" | head -3
else
    echo "❌ Failed to retrieve CA certificate"
    echo "Make sure you're running this from an EC2 instance in VPC: vpc-04f8c3e5590d02480"
    exit 1
fi

echo ""
echo "📋 Next Steps:"
echo "1. From an EC2 instance in the same VPC, run fabric-ca-client to enroll:"
echo "   fabric-ca-client enroll -u https://${ADMIN_USERNAME}:${ADMIN_PASSWORD}@${CA_ENDPOINT} \\"
echo "     --tls.certfiles $OUTPUT_DIR/ca-cert.pem -M ~/fabric-admin-msp"
echo ""
echo "2. This will create files in ~/fabric-admin-msp/signcerts/ and ~/fabric-admin-msp/keystore/"
echo ""
echo "3. Then upload certificates to Lambda:"
echo "   ./upload-certificates.sh"
