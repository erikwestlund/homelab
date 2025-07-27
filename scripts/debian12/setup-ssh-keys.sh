#!/bin/bash
# Setup SSH keys and initial configuration on new Debian 12 machines
# This script should be run on the target machine

set -e

echo "=== SSH Key Setup for Homelab Servers ==="

# Create .ssh directory with proper permissions
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Add your public key to authorized_keys
# You'll need to paste your ~/.ssh/scv.pub key content here
echo "Paste your scv.pub key content (from ~/.ssh/scv.pub on your local machine):"
echo "Press Ctrl+D when done:"
cat > ~/.ssh/authorized_keys.tmp

# Ensure proper permissions
chmod 600 ~/.ssh/authorized_keys.tmp

# Append to existing authorized_keys if it exists
if [ -f ~/.ssh/authorized_keys ]; then
    cat ~/.ssh/authorized_keys.tmp >> ~/.ssh/authorized_keys
else
    mv ~/.ssh/authorized_keys.tmp ~/.ssh/authorized_keys
fi
rm -f ~/.ssh/authorized_keys.tmp

chmod 600 ~/.ssh/authorized_keys

# Configure SSH daemon for better security
echo ""
echo "Configuring SSH daemon..."
sudo tee /etc/ssh/sshd_config.d/90-homelab.conf > /dev/null <<EOF
# Homelab SSH configuration
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication no
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding no
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
EOF

# Restart SSH service
sudo systemctl restart sshd

echo ""
echo "SSH setup complete!"
echo "You should now be able to SSH using: ssh -i ~/.ssh/scv debian@$(hostname -I | awk '{print $1}')"
echo ""
echo "Test the connection from your local machine before logging out!"