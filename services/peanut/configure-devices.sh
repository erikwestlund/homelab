#!/bin/bash

# Configure PeaNUT devices
PEANUT_URL="http://localhost:8086"
NUT_HOST="localhost"
NUT_PORT="3493"
NUT_USER="monuser"
NUT_PASS="Y*evtBv!JWEg-_2W"

echo "Configuring PeaNUT devices..."

# Add cyberpower1
echo "Adding cyberpower1..."
curl -X POST "$PEANUT_URL/api/v1/devices" \
  -H "Content-Type: application/json" \
  -d "{
    \"host\": \"$NUT_HOST\",
    \"port\": $NUT_PORT,
    \"username\": \"$NUT_USER\",
    \"password\": \"$NUT_PASS\",
    \"device\": \"cyberpower1\",
    \"alias\": \"CyberPower UPS 1\"
  }"

echo ""

# Add cyberpower2
echo "Adding cyberpower2..."
curl -X POST "$PEANUT_URL/api/v1/devices" \
  -H "Content-Type: application/json" \
  -d "{
    \"host\": \"$NUT_HOST\",
    \"port\": $NUT_PORT,
    \"username\": \"$NUT_USER\",
    \"password\": \"$NUT_PASS\",
    \"device\": \"cyberpower2\",
    \"alias\": \"CyberPower UPS 2\"
  }"

echo ""
echo "Configuration complete!"