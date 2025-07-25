#!/bin/bash

set -e

echo "Homelab Setup Script"
echo "===================="
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default installation directory
DEFAULT_INSTALL_DIR="/opt/docker"
INSTALL_DIR=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --install-dir)
            INSTALL_DIR="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --install-dir <path>  Specify custom installation directory (default: $DEFAULT_INSTALL_DIR)"
            echo "  --help                Show this help message"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Check if running from repo root
if [ ! -d "docker" ]; then
    echo -e "${RED}Error: Please run this script from the repository root directory${NC}"
    exit 1
fi

# Determine installation directory
if [ -z "$INSTALL_DIR" ]; then
    # Check if /opt/docker exists
    if [ -d "$DEFAULT_INSTALL_DIR" ]; then
        # Check if it's empty (only . and .. entries)
        if [ "$(ls -A $DEFAULT_INSTALL_DIR 2>/dev/null | wc -l)" -eq 0 ]; then
            echo -e "${GREEN}Found empty $DEFAULT_INSTALL_DIR directory, will use it for installation${NC}"
            INSTALL_DIR="$DEFAULT_INSTALL_DIR"
        else
            echo -e "${RED}Error: $DEFAULT_INSTALL_DIR exists and is not empty${NC}"
            echo
            echo "Options:"
            echo "1. Remove the existing directory manually: sudo rm -rf $DEFAULT_INSTALL_DIR"
            echo "2. Use a different installation directory: $0 --install-dir /path/to/directory"
            echo
            echo "Example: $0 --install-dir ~/homelab-docker"
            exit 1
        fi
    else
        echo -e "${BLUE}Will create and use $DEFAULT_INSTALL_DIR for installation${NC}"
        INSTALL_DIR="$DEFAULT_INSTALL_DIR"
    fi
else
    echo -e "${BLUE}Using custom installation directory: $INSTALL_DIR${NC}"
fi

# Create installation directory if it doesn't exist
if [ ! -d "$INSTALL_DIR" ]; then
    echo "Creating installation directory..."
    if [[ "$INSTALL_DIR" == /opt/* ]]; then
        if [ "$EUID" -eq 0 ]; then
            # Running as root, no sudo needed
            mkdir -p "$INSTALL_DIR"
        else
            # Running as regular user, need sudo
            if command -v sudo &> /dev/null; then
                sudo mkdir -p "$INSTALL_DIR"
                sudo chown $USER:$USER "$INSTALL_DIR"
            else
                echo -e "${RED}Error: Need root privileges to create $INSTALL_DIR${NC}"
                echo "Please run as root or install sudo"
                exit 1
            fi
        fi
    else
        mkdir -p "$INSTALL_DIR"
    fi
fi

# Function to generate random password
generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
}

# Copy docker directory structure to installation directory
echo "Copying Docker configuration to $INSTALL_DIR..."
cp -r docker/* "$INSTALL_DIR/"

# Create necessary directories
echo "Creating directories..."
mkdir -p "$INSTALL_DIR/mosquitto/config"
mkdir -p "$INSTALL_DIR/mosquitto/data"
mkdir -p "$INSTALL_DIR/mosquitto/log"
mkdir -p "$INSTALL_DIR/zigbee2mqtt/data"

# Generate passwords
MQTT_USER="homelab"
MQTT_PASS=$(generate_password)

echo -e "${GREEN}Generated MQTT credentials:${NC}"
echo "Username: $MQTT_USER"
echo "Password: $MQTT_PASS"
echo

# Create .env file from template
if [ -f "$INSTALL_DIR/.env" ]; then
    echo -e "${YELLOW}Warning: .env file already exists. Backing up to .env.backup${NC}"
    cp "$INSTALL_DIR/.env" "$INSTALL_DIR/.env.backup"
fi

echo "Creating .env file..."
cat > "$INSTALL_DIR/.env" << EOF
# Timezone
TZ=America/New_York

# Zigbee adapter configuration
# For USB adapters use: /dev/ttyUSB0 or /dev/ttyACM0
# For network adapters use: tcp://ip:port
ZIGBEE_SERIAL_PORT=tcp://zigbee.lan:6638

# MQTT credentials (auto-generated, do not commit!)
MQTT_USER=$MQTT_USER
MQTT_PASS=$MQTT_PASS
EOF

# Create Mosquitto configuration with authentication
echo "Creating Mosquitto configuration..."
cat > "$INSTALL_DIR/mosquitto/config/mosquitto.conf" << EOF
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
cat > "$INSTALL_DIR/zigbee2mqtt/data/configuration.yaml" << EOF
# Zigbee2MQTT Configuration
# Documentation: https://www.zigbee2mqtt.io/guide/configuration/

# MQTT settings
mqtt:
  base_topic: zigbee2mqtt
  server: mqtt://mosquitto:1883
  # user and password come from environment variables

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
if [ -f "$INSTALL_DIR/docker-compose.yml" ]; then
    echo -e "${YELLOW}Info: docker-compose.yml already exists, keeping current version${NC}"
else
    echo "Creating docker-compose.yml from template..."
    if [ -f "$INSTALL_DIR/docker-compose.yml.template" ]; then
        cp "$INSTALL_DIR/docker-compose.yml.template" "$INSTALL_DIR/docker-compose.yml"
    else
        echo -e "${RED}Warning: docker-compose.yml.template not found${NC}"
    fi
fi

# Read the serial port from .env and check if using network adapter
SERIAL_PORT=$(grep "^ZIGBEE_SERIAL_PORT=" "$INSTALL_DIR/.env" | cut -d'=' -f2)
if [[ "$SERIAL_PORT" == tcp://* ]]; then
    echo
    echo -e "${YELLOW}Note: You're using a network Zigbee adapter.${NC}"
    echo "You may need to comment out the 'devices:' section in docker-compose.yml"
    echo "as it's only needed for USB adapters."
fi

# Generate Mosquitto password file
echo "Generating Mosquitto password file..."
docker run --rm -v "$INSTALL_DIR/mosquitto/config:/mosquitto/config" eclipse-mosquitto:latest mosquitto_passwd -b -c /mosquitto/config/passwd $MQTT_USER $MQTT_PASS

# Set proper permissions
echo "Setting permissions..."
if [ "$EUID" -eq 0 ]; then
    # Running as root, no sudo needed
    chown -R 1883:1883 "$INSTALL_DIR/mosquitto/" 2>/dev/null || true
else
    # Running as regular user, try sudo if available
    if command -v sudo &> /dev/null; then
        sudo chown -R 1883:1883 "$INSTALL_DIR/mosquitto/" 2>/dev/null || true
    else
        echo -e "${YELLOW}Warning: Cannot set mosquitto ownership without root privileges${NC}"
    fi
fi
chmod -R 755 "$INSTALL_DIR/mosquitto/config"
chmod 600 "$INSTALL_DIR/mosquitto/config/passwd" 2>/dev/null || true

echo
echo -e "${GREEN}Setup complete!${NC}"
echo -e "${GREEN}Installation directory: $INSTALL_DIR${NC}"
echo
echo "Next steps:"
echo "1. Review and edit the .env file with your specific settings:"
echo "   cd $INSTALL_DIR && nano .env"
echo "2. Ensure your Zigbee adapter is accessible (network or USB)"
echo "3. Start the services:"
echo "   cd $INSTALL_DIR && docker-compose up -d"
echo
echo -e "${YELLOW}Important: Keep your .env file and passwords secure!${NC}"
echo "The generated MQTT password has been saved to $INSTALL_DIR/.env"
echo
echo "Web interfaces will be available at:"
echo "- Zigbee2MQTT: http://localhost:8080"
echo "- MQTT: mqtt://localhost:1883"