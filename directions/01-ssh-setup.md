# SSH Key Setup

SSH access using the `scv` key pair.

## Prerequisites

- A fresh Debian 12 installation
- Initial console or password-based SSH access
- Your `~/.ssh/scv.pub` key from your local machine

## Step 1: Initial SSH Access

First, SSH into your server using password authentication:

```bash
ssh root@nexus.lan
```

## Step 2: Create SSH Directory

On the target server, create the SSH directory:

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
```

## Step 3: Add Your Public Key

### Option A: Add During Proxmox VM Creation (Easiest!)

When creating the VM in Proxmox:
1. Go to the "Cloud-Init" tab
2. Paste your public key in the "SSH public key" field
3. The key will be automatically added to the default user

### Option B: Use ssh-copy-id (Recommended)

From your local machine:

```bash
ssh-copy-id -f -i ~/.ssh/scv root@nexus.lan
```

`-f` is oftne required 

### Option C: Copy with scp

From your local machine:

```bash
# First copy the key
scp ~/.ssh/scv.pub root@nexus.lan:~/

# Then SSH in and add it
ssh root@nexus.lan
cat ~/scv.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
rm ~/scv.pub
```

### Option D: One-liner with SSH

From your local machine:

```bash
cat ~/.ssh/scv.pub | ssh root@nexus.lan "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
```

### Option E: Manual copy-paste

On your local machine, display your public key:

```bash
cat ~/.ssh/scv.pub
```

Copy the output, then on the server:

```bash
cat >> ~/.ssh/authorized_keys << 'EOF'
# Paste your scv.pub content here
EOF

chmod 600 ~/.ssh/authorized_keys
```

## Step 4: Test SSH Key Access

From your local machine, test the key-based login:

```bash
ssh -i ~/.ssh/scv root@nexus.lan
```

## Step 5: Disable Password Authentication

Once key access is confirmed, secure the server:

```bash
sudo tee /etc/ssh/sshd_config.d/90-homelab.conf > /dev/null << 'EOF'
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

sudo systemctl restart sshd
```

## Step 6: Configure Local SSH Config (Optional)

Add to your local `~/.ssh/config` for easier access:

```bash
cat >> ~/.ssh/config << 'EOF'
Host nexus
    HostName nexus.lan
    User root
    IdentityFile ~/.ssh/scv

Host hatchery
    HostName hatchery.lan
    User root
    IdentityFile ~/.ssh/scv
EOF
```

Now you can simply use:

```bash
ssh nexus
ssh hatchery
```

## Troubleshooting

### Permission Denied

Check permissions:

```bash
ls -la ~/.ssh/
# Should show: drwx------ for the directory
# Should show: -rw------- for authorized_keys
```

### Still Asking for Password

Ensure the SSH service has reloaded:

```bash
sudo systemctl status sshd
sudo journalctl -u sshd -n 50
```

### Test with Verbose Output

```bash
ssh -vvv -i ~/.ssh/scv root@nexus.lan
```