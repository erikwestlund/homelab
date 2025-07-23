#!/bin/bash

set -e

echo "Homelab Setup Script"
echo "===================="
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running from repo root
if [ ! -d "docker" ]; then
    echo -e "${RED}Error: Please run this script from the repository root directory${NC}"
    exit 1
fi

# Function to generate random password
generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
}

# Create necessary directories
echo "Creating directories..."
mkdir -p docker/mosquitto/config
mkdir -p docker/mosquitto/data
mkdir -p docker/mosquitto/log
mkdir -p docker/zigbee2mqtt/data

# Generate passwords
MQTT_USER="homelab"
MQTT_PASS=$(generate_password)

echo -e "${GREEN}Generated MQTT credentials:${NC}"
echo "Username: $MQTT_USER"
echo "Password: $MQTT_PASS"
echo

# Create .env file from template
if [ -f "docker/.env" ]; then
    echo -e "${YELLOW}Warning: .env file already exists. Backing up to .env.backup${NC}"
    cp docker/.env docker/.env.backup
fi

echo "Creating .env file..."
cat > docker/.env << EOF
# Timezone
TZ=America/New_York

# Zigbee adapter configuration
# For USB adapters use: /dev/ttyUSB0 or /dev/ttyACM0
# For network adapters use: tcp://ip:port
ZIGBEE_SERIAL_PORT=/dev/ttyUSB0

# MQTT credentials (auto-generated, do not commit!)
MQTT_USER=$MQTT_USER
MQTT_PASS=$MQTT_PASS
EOF

# Create Mosquitto configuration with authentication
echo "Creating Mosquitto configuration..."
cat > docker/mosquitto/config/mosquitto.conf << EOF
# Mosquitto Configuration File

# Listener configuration
listener 1883
listener 9001
protocol websockets

# Security
allow_anonymous false
password_file /mosquitto/config/passwd

# Persistence
persistence true
persistence_location /mosquitto/data/

# Logging
log_dest file /mosquitto/log/mosquitto.log
log_type all
log_timestamp true
log_timestamp_format %Y-%m-%dT%H:%M:%S

# General settings
max_keepalive 60
EOF

# Create Zigbee2MQTT configuration
echo "Creating Zigbee2MQTT configuration..."
cat > docker/zigbee2mqtt/data/configuration.yaml << EOF
# Zigbee2MQTT Configuration
# Documentation: https://www.zigbee2mqtt.io/guide/configuration/

# MQTT settings
mqtt:
  base_topic: zigbee2mqtt
  server: mqtt://mosquitto:1883
  user: $MQTT_USER
  password: $MQTT_PASS

# Serial port settings
serial:
  port: \${ZIGBEE_SERIAL_PORT}

# Web frontend
frontend:
  port: 8080

# Zigbee network settings
advanced:
  log_level: info
  log_output:
    - console
  network_key: GENERATE
  pan_id: GENERATE
  ext_pan_id: GENERATE
  channel: 11

# Device specific configuration
device_options:
  retain: true

# Permit devices to join
permit_join: false

# Home Assistant integration
homeassistant: true
EOF

# Check if docker-compose.yml already exists
if [ -f "docker/docker-compose.yml" ]; then
    echo -e "${YELLOW}Info: docker-compose.yml already exists, keeping current version${NC}"
else
    echo "Creating docker-compose.yml from template..."
    cp docker/docker-compose.yml.template docker/docker-compose.yml
fi

# Read the serial port from .env and check if using network adapter
SERIAL_PORT=$(grep "^ZIGBEE_SERIAL_PORT=" docker/.env | cut -d'=' -f2)
if [[ "$SERIAL_PORT" == tcp://* ]]; then
    echo
    echo -e "${YELLOW}Note: You're using a network Zigbee adapter.${NC}"
    echo "You may need to comment out the 'devices:' section in docker-compose.yml"
    echo "as it's only needed for USB adapters."
fi

# Generate Mosquitto password file
echo "Generating Mosquitto password file..."
docker run --rm -v "$(pwd)/docker/mosquitto/config:/mosquitto/config" eclipse-mosquitto:latest mosquitto_passwd -b -c /mosquitto/config/passwd $MQTT_USER $MQTT_PASS

# Set proper permissions
echo "Setting permissions..."
sudo chown -R 1883:1883 docker/mosquitto/ 2>/dev/null || true
chmod -R 755 docker/mosquitto/config
chmod 600 docker/mosquitto/config/passwd

echo
echo -e "${GREEN}Setup complete!${NC}"
echo
echo "Next steps:"
echo "1. Review and edit docker/.env file with your specific settings"
echo "2. Ensure your Zigbee adapter is connected"
echo "3. Run: cd docker && docker-compose up -d"
echo
echo -e "${YELLOW}Important: Keep your .env file and passwords secure!${NC}"
echo "The generated MQTT password has been saved to docker/.env"
echo
echo "Web interfaces will be available at:"
echo "- Zigbee2MQTT: http://localhost:8080"
echo "- MQTT: mqtt://localhost:1883"