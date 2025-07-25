#!/bin/bash

# Install monitoring script for Zigbee2MQTT and Mosquitto

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "Installing Zigbee2MQTT Monitoring Script"
echo "========================================"
echo

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ] && ! command -v sudo &> /dev/null; then
    echo -e "${RED}This script requires root privileges or sudo${NC}"
    exit 1
fi

# Default installation directory
DOCKER_DIR="${DOCKER_DIR:-/opt/docker}"

# Check if Docker directory exists
if [ ! -d "$DOCKER_DIR" ]; then
    echo -e "${RED}Error: Docker directory not found at $DOCKER_DIR${NC}"
    echo "Set DOCKER_DIR environment variable if using a different path"
    exit 1
fi

# Check if monitor script exists in current directory
if [ ! -f "monitor-zigbee.sh" ]; then
    echo -e "${RED}Error: monitor-zigbee.sh not found in current directory${NC}"
    echo "Please run this script from the homelab repository directory"
    exit 1
fi

# Copy monitoring script
echo "Copying monitoring script to $DOCKER_DIR..."
cp monitor-zigbee.sh "$DOCKER_DIR/"
chmod +x "$DOCKER_DIR/monitor-zigbee.sh"

# Create log directory if it doesn't exist
if [ "$EUID" -eq 0 ]; then
    touch /var/log/zigbee-monitor.log
    chmod 644 /var/log/zigbee-monitor.log
else
    sudo touch /var/log/zigbee-monitor.log
    sudo chmod 644 /var/log/zigbee-monitor.log
fi

# Test the script
echo "Testing monitoring script..."
echo "Skipping test run to avoid restarting services during installation"
echo -e "${GREEN}✓ Monitoring script copied successfully${NC}"

# Show what would happen
echo
echo "The monitoring script will check services every 5 minutes and:"
echo "  - Log status to /var/log/zigbee-monitor.log"
echo "  - Restart services only if they're not responding"

# Check if cron is installed
if ! command -v crontab &> /dev/null; then
    echo -e "${RED}Error: cron is not installed${NC}"
    echo "Install cron first:"
    echo "  Debian/Ubuntu: apt install cron"
    echo "  RHEL/CentOS: yum install cronie"
    exit 1
fi

# Add to crontab
echo
echo "Adding to crontab..."
CRON_CMD="*/5 * * * * $DOCKER_DIR/monitor-zigbee.sh"

# Check if already in crontab
if crontab -l 2>/dev/null | grep -q "monitor-zigbee.sh"; then
    echo -e "${YELLOW}Monitoring script already in crontab${NC}"
else
    # Add to crontab
    (crontab -l 2>/dev/null; echo "$CRON_CMD") | crontab -
    echo -e "${GREEN}✓ Added to crontab${NC}"
fi

echo
echo -e "${GREEN}Installation complete!${NC}"
echo
echo "Monitoring script installed at: $DOCKER_DIR/monitor-zigbee.sh"
echo "Log file: /var/log/zigbee-monitor.log"
echo "Cron schedule: Every 5 minutes"
echo
echo "To view logs:"
echo "  tail -f /var/log/zigbee-monitor.log"
echo
echo "To check cron status:"
echo "  crontab -l"
echo
echo "To remove from cron:"
echo "  crontab -e  # Then delete the monitor-zigbee.sh line"