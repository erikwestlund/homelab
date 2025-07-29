#!/bin/bash

# PeaNUT setup script
set -e

INSTALL_DIR="${1:-/opt/docker/peanut}"

echo "Setting up PeaNUT in $INSTALL_DIR..."

# Create directory structure
mkdir -p "$INSTALL_DIR"

# Copy docker-compose.yml
cp docker-compose.yml "$INSTALL_DIR/"

# Create .env file with NUT credentials
cat > "$INSTALL_DIR/.env" << EOF
# PeaNUT Configuration
NUT_HOST=localhost
NUT_PORT=3493
NUT_USERNAME=monuser
NUT_PASSWORD=${NUT_PASSWORD:-$(openssl rand -base64 32)}
TZ=America/New_York
EOF

echo "PeaNUT setup complete!"
echo "To start PeaNUT:"
echo "  cd $INSTALL_DIR"
echo "  docker-compose up -d"
echo ""
echo "Access PeaNUT at: http://$(hostname -I | awk '{print $1}'):8086"