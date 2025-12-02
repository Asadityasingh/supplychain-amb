#!/bin/bash

LAMBDA_URL="https://k4uyws3gmegkpwvbzkywnrisfq0zeoxe.lambda-url.us-east-1.on.aws"
CERTS_DIR="${1:-.}"

if [ ! -f "$CERTS_DIR/fabric-admin-msp/signcerts/cert.pem" ]; then
    echo "❌ Error: Admin certificate not found at $CERTS_DIR/fabric-admin-msp/signcerts/cert.pem"
    echo "Run fabric-ca-client enroll first to generate certificates"
    exit 1
fi

if [ ! -f "$CERTS_DIR/fabric-admin-msp/keystore"/*_sk ]; then
    echo "❌ Error: Admin private key not found in $CERTS_DIR/fabric-admin-msp/keystore/"
    exit 1
fi

echo "📝 Reading certificates..."
USER_CERT=$(cat "$CERTS_DIR/fabric-admin-msp/signcerts/cert.pem")
USER_PRIVATE_KEY=$(cat "$CERTS_DIR/fabric-admin-msp/keystore"/*_sk)
TLS_CERT=$(cat "$CERTS_DIR/ca-cert.pem" 2>/dev/null || echo "")

echo "🚀 Uploading certificates to Lambda..."

RESPONSE=$(curl -s -X POST "$LAMBDA_URL/certificates" \
  -H "Content-Type: application/json" \
  -d @- <<EOF
{
  "userCert": $(echo "$USER_CERT" | jq -R -s .),
  "userPrivateKey": $(echo "$USER_PRIVATE_KEY" | jq -R -s .),
  "tlsCert": $(echo "$TLS_CERT" | jq -R -s .),
  "caTlsCert": ""
}
EOF
)

if echo "$RESPONSE" | grep -q "success"; then
    echo "✅ Certificates uploaded successfully!"
    echo ""
    echo "🔗 Your blockchain connection is now configured"
    echo "Status will update from '🔐 Needs Certificates' to '🔗 Live Blockchain'"
else
    echo "❌ Failed to upload certificates:"
    echo "$RESPONSE" | jq '.'
fi
