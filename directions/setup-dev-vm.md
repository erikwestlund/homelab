# Ubuntu 24.04 Development VM Setup

Complete Ansible automation for setting up a powerful Ubuntu 24.04 development VM optimized for offloading resource-intensive tasks from your Mac.

## Quick Start

```bash
# 1. Copy SSH key to VM
ssh-copy-id -f -i ~/.ssh/scv.pub erik@dev.lan
ssh-copy-id -f -i ~/.ssh/scv.pub root@dev.lan

# 2. Deploy the VM configuration
cd /Users/erikwestlund/code/homelab/ansible
ansible-playbook -i inventories/homelab.yml playbooks/setup-dev-vm.yml
```

## Features

### Container Platforms
- **Docker CE**: Latest stable with docker-compose and BuildKit
- **Podman**: Rootless containers with podman-compose
- Both configured to coexist peacefully

### Development Tools
- **Languages**: Python 3, Node.js 20, Go 1.21.5, optionally Rust
- **Package Managers**: pip, pipx, npm, yarn, pnpm, cargo, uv/uvx
- **Build Tools**: gcc, g++, make, cmake, build-essential
- **CLI Tools**: git, gh (GitHub CLI), jq, ripgrep, fzf, bat, fd-find

### Shell Environment
- **Zsh with Oh-My-Zsh**: For both erik and root users
- **Custom Aliases**: Docker/Podman shortcuts, git aliases, navigation helpers
- **Environment Variables**: Pre-configured for development

### Cloud Integration
- **rclone**: For syncing secrets and configs
- **sync-secrets**: Pull secrets from cloud storage
- **put-secrets**: Push secrets to cloud storage
- **GitHub repos**: Automatically cloned and kept up-to-date

### Claude AI Tools
- **Claude Code CLI**: Command-line interface for Claude
- **zen MCP server**: Advanced AI capabilities via OpenRouter
- **addzen script**: Easy MCP server configuration

### System Tools
- **Monitoring**: btop, htop, glances, neofetch
- **Network**: nmap, traceroute, mtr, iperf3, netcat
- **Performance**: 8GB swap, Docker optimizations
- **Security**: UFW firewall, unattended-upgrades

## Prerequisites

### On Your Mac

1. **Secrets Configuration**
   Add to `/Users/erikwestlund/code/homelab/ansible/secrets.yaml`:
   ```yaml
   dev_vm:
     github_user: "your-github-username"
     github_email: "your-email@example.com"
     github_token: "ghp_your_personal_access_token"
     openrouter_api_key: "sk-or-v1-your_api_key"  # For zen MCP
   ```

2. **VM Requirements**
   - Ubuntu 24.04 LTS
   - SSH access configured
   - Network accessible at `dev.lan`

## Deployment Options

### Full Deployment
```bash
ansible-playbook -i inventories/homelab.yml playbooks/setup-dev-vm.yml
```

### Specific Components
```bash
# Just packages
ansible-playbook -i inventories/homelab.yml playbooks/setup-dev-vm.yml --tags packages

# Just Docker
ansible-playbook -i inventories/homelab.yml playbooks/setup-dev-vm.yml --tags docker

# Just repos
ansible-playbook -i inventories/homelab.yml playbooks/setup-dev-vm.yml --tags repos

# Claude tools
ansible-playbook -i inventories/homelab.yml playbooks/setup-dev-vm.yml --tags claude,zen,mcp
```

### Update Options
```bash
# Update everything including pulling latest from GitHub repos
ansible-playbook -i inventories/homelab.yml playbooks/setup-dev-vm.yml

# Skip repo updates (preserve local changes)
ansible-playbook -i inventories/homelab.yml playbooks/setup-dev-vm.yml -e update_repos=false
```

## Post-Installation Setup

### 1. Copy rclone Configuration
```bash
# From your Mac
scp ~/.config/rclone/rclone.conf root@dev.lan:/home/erik/.config/rclone/
ssh root@dev.lan chown erik:erik /home/erik/.config/rclone/rclone.conf
```

### 2. Sync Secrets
```bash
# SSH into the VM
ssh erik@dev.lan

# Pull all secrets from cloud
sync-secrets

# Later, push any changes back
put-secrets
```

### 3. Test Services
```bash
# Docker
docker run hello-world

# Podman
podman run hello-world

# GitHub authentication
gh auth status

# Check repos
ls ~/code/
```

## Repository Management

The playbook automatically clones and maintains these repositories in `~/code/`:
- `erikwestlund/homelab`
- `erikwestlund/dotfiles`
- `jhbiostatcenter/naaccord-data-depot`
- `jhbiostatcenter/naaccord-r-tools`
- `letsrun/better-shoes`

**Auto-update behavior:**
- Fetches latest changes on each playbook run
- Resets to origin/main (removes local changes)
- Cleans untracked files

To add more repos, edit `ansible/roles/dev-vm/defaults/main.yml`:
```yaml
github_repos:
  - { repo: "username/repository" }
  - { repo: "org/repo", dest: "custom-name", branch: "develop" }
```

## Shell Aliases

Key aliases configured automatically:

### Navigation
- `code` - cd ~/code
- `homelab` - cd ~/code/homelab
- `dotfiles` - cd ~/code/dotfiles
- `ws` - cd ~/workspace

### Docker/Podman
- `d` - docker
- `dc` - docker-compose
- `dps` - docker ps
- `dex` - docker exec -it
- `p` - podman
- `pc` - podman-compose

### Git
- `gs` - git status
- `gc` - git commit
- `gp` - git push
- `glog` - git log with graph

### Secrets
- `sync-secrets` - Pull from cloud
- `put-secrets` - Push to cloud
- `addzen` - Configure zen MCP

### System
- `update` - Full system update
- `myip` - Show public IP
- `btop` - System monitor

## zen MCP Configuration

### Setup
1. Ensure `OPENROUTER_API_KEY` is in secrets.yaml
2. Projects are auto-configured in ~/.claude.json
3. Use `addzen [project]` to add zen to any project

### Available Projects
- homelab
- dotfiles
- naaccord-data-depot
- naaccord-r-tools
- better-shoes
- workspace

### Usage
```bash
# Add zen to a project
addzen homelab

# Check configuration
cat ~/.claude.json | jq .projects.homelab.mcpServers
```

## Troubleshooting

### Permission Issues
```bash
# Fix Docker permissions
sudo usermod -aG docker $USER
# Log out and back in
```

### GitHub Authentication
```bash
# Check token auth
gh auth status

# Test with private repo
git clone https://github.com/your-private/repo.git
```

### Oh-My-Zsh Issues
```bash
# Reinstall for both users
ansible-playbook -i inventories/homelab.yml \
  playbooks/setup-dev-vm.yml --tags omz_reinstall,user,shell
```

### Node.js Installation
If Node.js fails to install, the playbook uses the official NodeSource setup script for Ubuntu 24.04.

### Python Package Issues
Ubuntu 24.04 enforces "externally-managed-environment". The playbook uses pipx for Python tools to avoid conflicts.

## File Structure

```
ansible/roles/dev-vm/
├── tasks/
│   ├── main.yml              # Main orchestration
│   ├── packages.yml          # System packages
│   ├── docker.yml            # Docker setup
│   ├── podman.yml            # Podman setup
│   ├── development.yml       # Dev tools & git
│   ├── user.yml              # Shell & user config
│   ├── sync-scripts.yml     # rclone & sync setup
│   ├── repos.yml             # GitHub repos
│   └── claude-tools.yml     # Claude & zen MCP
├── templates/
│   ├── aliases.j2            # Shell aliases
│   ├── gitconfig.j2          # Git configuration
│   ├── docker-daemon.json.j2 # Docker settings
│   ├── sync-secrets.sh.j2    # Secrets sync script
│   └── addzen.sh.j2          # zen MCP helper
├── defaults/
│   └── main.yml              # Default variables
└── handlers/
    └── main.yml              # Service handlers
```

## Customization

### Change Default Settings
Edit `ansible/roles/dev-vm/defaults/main.yml`:

```yaml
# Shell type
shell_type: "zsh"  # or "bash"
install_ohmyzsh: true

# Languages to install
install_nodejs: true
install_golang: true
install_rust: false  # Set to true if needed

# Performance
swap_size_gb: 8  # Adjust as needed

# Security
configure_firewall: true
ssh_hardening: false  # Set to true for production
```

### Add Custom Aliases
Add to `ansible/roles/dev-vm/templates/aliases.j2`

### Modify Packages
Edit the `system_packages` list in `defaults/main.yml`

## Maintenance

### Update Everything
```bash
# On Mac
cd /Users/erikwestlund/code/homelab/ansible
ansible-playbook -i inventories/homelab.yml playbooks/setup-dev-vm.yml
```

### System Updates on VM
```bash
# SSH to VM
ssh erik@dev.lan

# Run update alias
update
```

### Backup Secrets
```bash
# On VM
put-secrets

# Backs up to cloud storage via rclone
```

## Security Notes

1. **Secrets Management**
   - secrets.yaml is gitignored
   - Synced via encrypted rclone to cloud storage
   - Never commit tokens to git

2. **SSH Access**
   - Key-based authentication only
   - Both erik and root have your SSH key

3. **Firewall**
   - UFW enabled with SSH allowed
   - Additional ports opened as needed

4. **Updates**
   - unattended-upgrades configured
   - Security updates auto-installed

## Support

- **Homelab Issues**: Check ansible/roles/dev-vm/README.md
- **Claude Code**: https://claude.ai/docs
- **zen MCP**: https://github.com/BeehiveInnovations/zen-mcp-server

---
*Last Updated: September 2025*
*Ansible Role Version: 1.0.0*