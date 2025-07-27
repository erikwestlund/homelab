# Scripts Directory

Common scripts used across both Nexus and Hatchery servers.

## Available Scripts

### prepare-debian12.sh
Prepares a fresh Debian 12 VM with essential tools and configurations.

**What it installs:**
- System utilities: curl, wget, git, vim, btop, tmux
- Network tools: net-tools, dnsutils, mtr-tiny
- Monitoring: iotop, sysstat, ncdu
- Security: automatic security updates only (minimal approach)
- Docker and Docker Compose
- Build essentials

**Usage:**
```bash
# Copy to new VM and run
curl -O https://raw.githubusercontent.com/yourusername/homelab/main/scripts/prepare-debian12.sh
chmod +x prepare-debian12.sh
./prepare-debian12.sh
```

**Post-installation:**
- Log out and back in for docker group changes
- Configure SSH keys if needed
- Set up any service-specific requirements