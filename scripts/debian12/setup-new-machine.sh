#!/bin/bash
# Complete setup script for new Debian 12 homelab machines
# Run this after initial SSH access is established

set -e

echo "=== Complete Homelab Machine Setup ==="
echo ""

# Update system
echo "Updating system packages..."
sudo apt-get update
sudo apt-get upgrade -y

# Install essential packages
echo "Installing essential packages..."
sudo apt-get install -y \
    curl \
    wget \
    git \
    vim \
    htop \
    net-tools \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    python3-pip \
    sudo \
    ufw

# Set up firewall
echo "Configuring firewall..."
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow from 192.168.0.0/16 to any # Allow local network
echo "y" | sudo ufw enable

# Create homelab user if needed
if ! id -u homelab >/dev/null 2>&1; then
    echo "Creating homelab user..."
    sudo useradd -m -s /bin/bash -G sudo,docker homelab
    echo "Set password for homelab user:"
    sudo passwd homelab
fi

# Set up Docker
echo "Installing Docker..."
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add current user to docker group
sudo usermod -aG docker $USER

# Create standard directories
echo "Creating standard directories..."
sudo mkdir -p /opt/docker
sudo mkdir -p /media/{movies,tv,music,photos}
sudo mkdir -p /backups
sudo chown -R $USER:$USER /opt/docker
sudo chown -R $USER:$USER /media

# Set up automatic updates
echo "Configuring automatic security updates..."
sudo apt-get install -y unattended-upgrades
echo 'Unattended-Upgrade::Automatic-Reboot "false";' | sudo tee -a /etc/apt/apt.conf.d/50unattended-upgrades

# Configure system limits
echo "Configuring system limits..."
echo "* soft nofile 65536" | sudo tee -a /etc/security/limits.conf
echo "* hard nofile 65536" | sudo tee -a /etc/security/limits.conf

# Set timezone
echo "Setting timezone..."
sudo timedatectl set-timezone America/New_York

# Enable systemd-resolved for better DNS handling
sudo systemctl enable systemd-resolved
sudo systemctl start systemd-resolved

echo ""
echo "=== Setup Complete! ==="
echo ""
echo "Next steps:"
echo "1. Log out and back in for group changes to take effect"
echo "2. Clone the homelab repository:"
echo "   git clone https://github.com/erikwestlund/homelab.git"
echo "3. Run Ansible playbooks to deploy services"
echo ""
echo "SSH access: ssh -i ~/.ssh/scv $USER@$(hostname -I | awk '{print $1}')"