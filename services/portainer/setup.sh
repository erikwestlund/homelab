#!/bin/bash

# Portainer Setup Script
set -e

echo "================================="
echo "Portainer CE Setup"
echo "================================="

# Default installation directory
INSTALL_DIR="${1:-/opt/docker/portainer}"

echo "Setting up Portainer in $INSTALL_DIR..."

# Create directory
mkdir -p "$INSTALL_DIR"

# Copy docker-compose.yml
cp docker-compose.yml "$INSTALL_DIR/"

# Check if .env exists
if [ -f "$INSTALL_DIR/.env" ]; then
    echo "⚠️  .env file already exists. Using existing configuration."
else
    # Generate secure admin password
    ADMIN_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    
    # Create .env from template
    cp .env.example "$INSTALL_DIR/.env"
    
    # Update password
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s/changeme-super-secure-password/$ADMIN_PASSWORD/g" "$INSTALL_DIR/.env"
    else
        # Linux
        sed -i "s/changeme-super-secure-password/$ADMIN_PASSWORD/g" "$INSTALL_DIR/.env"
    fi
    
    echo "✅ Generated secure admin password"
    echo ""
    echo "IMPORTANT: Save this password!"
    echo "Admin Password: $ADMIN_PASSWORD"
    echo ""
fi

echo "================================="
echo "Portainer setup complete!"
echo "================================="
echo ""
echo "To start Portainer:"
echo "  cd $INSTALL_DIR"
echo "  docker-compose up -d"
echo ""
echo "Initial setup:"
echo "1. Navigate to https://$(hostname -I | awk '{print $1}'):9443"
echo "2. Create admin user with the generated password"
echo "3. Choose 'Local' environment"
echo ""
echo "Features:"
echo "- Manage all Docker containers"
echo "- View logs and stats"
echo "- Deploy stacks"
echo "- Manage volumes and networks"
echo ""