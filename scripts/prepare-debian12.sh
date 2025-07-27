#!/bin/bash

# Debian 12 VM Preparation Script
# Essential tools and configuration for all VMs

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Debian 12 VM Preparation Script${NC}"
echo "================================="

# Update system
echo -e "\n${YELLOW}Updating system packages...${NC}"
sudo apt update && sudo apt upgrade -y

# Install essential packages
echo -e "\n${YELLOW}Installing essential packages...${NC}"
sudo apt install -y \
    curl \
    wget \
    git \
    vim \
    btop \
    tmux \
    build-essential \
    net-tools \
    dnsutils \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    apt-transport-https \
    openssh-server \
    unzip \
    jq \
    ncdu \
    iotop \
    sysstat \
    mtr-tiny

# Install Docker
echo -e "\n${YELLOW}Installing Docker...${NC}"
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add current user to docker group
echo -e "\n${YELLOW}Adding user to docker group...${NC}"
sudo usermod -aG docker $USER

# Skip firewall configuration - handled at Proxmox level

# Set timezone
echo -e "\n${YELLOW}Setting timezone...${NC}"
sudo timedatectl set-timezone America/New_York

# Enable automatic security updates
echo -e "\n${YELLOW}Enabling automatic security updates...${NC}"
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades

# Skip fail2ban - minimal security approach

# Clean up
echo -e "\n${YELLOW}Cleaning up...${NC}"
sudo apt autoremove -y
sudo apt autoclean

echo -e "\n${GREEN}VM preparation complete!${NC}"
echo "Please log out and back in for docker group changes to take effect."
echo ""
echo "Next steps:"
echo "- Configure SSH keys if needed"
echo "- Set up any service-specific requirements"