#!/bin/bash

# Monitoring Stack Setup Script
set -e

echo "==================================="
echo "Homelab Monitoring Stack Setup"
echo "==================================="

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo "This script should not be run as root for security reasons."
   exit 1
fi

# Check for docker and docker-compose
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed"
    exit 1
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "Error: Docker Compose is not installed"
    exit 1
fi

# Check if .env exists
if [ -f .env ]; then
    echo "⚠️  .env file already exists. Using existing configuration."
    echo "   To reset, delete .env and run this script again."
else
    # Copy .env.example to .env
    cp .env.example .env
    
    # Generate secure passwords and token
    INFLUXDB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    GRAFANA_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    INFLUXDB_TOKEN=$(openssl rand -base64 48)
    
    # Update .env with generated values
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s/changeme123!/$INFLUXDB_PASSWORD/g" .env
        sed -i '' "s/changeme456!/$GRAFANA_PASSWORD/g" .env
        sed -i '' "s/changeme-super-secret-auth-token/$INFLUXDB_TOKEN/g" .env
    else
        # Linux
        sed -i "s/changeme123!/$INFLUXDB_PASSWORD/g" .env
        sed -i "s/changeme456!/$GRAFANA_PASSWORD/g" .env
        sed -i "s/changeme-super-secret-auth-token/$INFLUXDB_TOKEN/g" .env
    fi
    
    echo "✅ Generated secure passwords and token"
fi

# Create required directories
mkdir -p grafana/provisioning/{dashboards,datasources}
mkdir -p telegraf/scripts

# Check if NUT is available on the host
if command -v upsc &> /dev/null; then
    echo "✅ NUT (Network UPS Tools) detected on host"
    
    # Update Telegraf config to use host network for NUT access
    echo "   Configuring Telegraf for host NUT access..."
    
    # Add network_mode: host to telegraf service in docker-compose.yml
    # This is already handled in the docker-compose file
else
    echo "⚠️  NUT (Network UPS Tools) not detected on host"
    echo "   UPS monitoring will not be available"
fi

# Set proper permissions
chmod +x telegraf/scripts/nut_influx.py 2>/dev/null || true

echo ""
echo "==================================="
echo "Ready to start the monitoring stack!"
echo "==================================="
echo ""
echo "Generated credentials (saved in .env):"
echo "  InfluxDB Admin Password: ********"
echo "  Grafana Admin Password: ********"
echo ""
echo "To start the stack, run:"
echo "  docker-compose up -d"
echo ""
echo "Services will be available at:"
echo "  - Grafana: http://$(hostname -I | awk '{print $1}'):3000"
echo "  - InfluxDB: http://$(hostname -I | awk '{print $1}'):8086"
echo ""
echo "For Home Assistant integration:"
echo "  1. Copy configuration from home-assistant-config.yaml"
echo "  2. Update the token to: Check the .env file"
echo "  3. Restart Home Assistant"
echo ""