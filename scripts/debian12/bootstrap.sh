#!/bin/bash
# Bootstrap script for fresh Debian 12 servers without git
# Run with: curl -fsSL https://raw.githubusercontent.com/erikwestlund/homelab/main/scripts/debian12/bootstrap.sh | bash

set -e

echo "=== Homelab Bootstrap Script ==="
echo "Installing git and cloning repository..."

# Update package list
sudo apt-get update

# Install git
sudo apt-get install -y git

# Clone the repository
read -p "Enter the directory to clone the repo (default: ~/homelab): " CLONE_DIR
CLONE_DIR=${CLONE_DIR:-~/homelab}

# Expand tilde to home directory
CLONE_DIR="${CLONE_DIR/#\~/$HOME}"

echo "Cloning repository to $CLONE_DIR..."
git clone https://github.com/erikwestlund/homelab.git "$CLONE_DIR"

echo "Repository cloned successfully!"
echo ""
echo "Next steps:"
echo "1. cd $CLONE_DIR"
echo "2. Review the README and CLAUDE.md files"
echo "3. Run the appropriate setup scripts for your server (nexus or hatchery)"