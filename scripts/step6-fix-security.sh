#!/bin/bash
set -e

# Fix npm security vulnerabilities

echo "🔒 Fixing security vulnerabilities..."

cd ../src/ui

echo "📦 Running npm audit fix..."
npm audit fix

echo ""
echo "📊 Security report:"
npm audit

echo ""
echo "✅ Security fixes applied"
