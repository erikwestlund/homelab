# Development VM Setup Role

This Ansible role sets up a comprehensive Ubuntu 24.04 development environment with Docker, Podman, build tools, and development essentials.

## Features

- **Container Platforms**: Docker CE and Podman with compose tools
- **Build Tools**: gcc, g++, make, cmake, build-essential
- **Languages**: Python 3, Node.js, Go, Rust (optional)
- **Development Tools**: git, GitHub CLI, ripgrep, fzf, bat, jq, yq
- **System Utilities**: htop, tmux, vim, curl, wget, network tools
- **Shell Enhancements**: Aliases, custom prompts, oh-my-zsh (optional)
- **Security**: UFW firewall, unattended-upgrades, SSH hardening (optional)
- **Performance**: Swap configuration, Docker optimizations

## Requirements

- Ubuntu 24.04 LTS
- SSH access with sudo privileges
- Ansible 2.9 or later

## Role Variables

Key variables (see `defaults/main.yml` for full list):

```yaml
# User configuration
dev_user: "{{ ansible_user | default('erik') }}"

# Enable/disable features
enable_podman: true
install_nodejs: true
install_golang: true
install_rust: false
configure_shell: true
configure_git: true
configure_firewall: true
configure_swap: true
swap_size_gb: 8

# Shell type
shell_type: "bash"  # or "zsh"
install_ohmyzsh: false
```

## Secrets Configuration

Add to your `ansible/secrets.yaml`:

```yaml
dev_vm:
  github_user: "your-github-username"
  github_email: "your-email@example.com"
  github_token: "ghp_your_personal_access_token"
  docker_hub_user: ""  # Optional
  docker_hub_token: ""  # Optional
```

## Usage

### 1. Update Inventory

Add the dev VM to `ansible/inventories/homelab.yml`:

```yaml
development:
  hosts:
    dev-vm:
      ansible_host: dev.lan
      ansible_user: erik
```

### 2. Run Playbook

```bash
cd ansible
ansible-playbook -i inventories/homelab.yml playbooks/setup-dev-vm.yml
```

### 3. Run with specific tags

```bash
# Only install packages
ansible-playbook -i inventories/homelab.yml playbooks/setup-dev-vm.yml --tags packages

# Only configure Docker
ansible-playbook -i inventories/homelab.yml playbooks/setup-dev-vm.yml --tags docker

# Only configure development environment
ansible-playbook -i inventories/homelab.yml playbooks/setup-dev-vm.yml --tags development
```

## Post-Installation

After the playbook completes:

1. **Log out and back in** for Docker group membership to take effect
2. **Test Docker**: `docker run hello-world`
3. **Test Podman**: `podman run hello-world`
4. **Check Git auth**: `gh auth status`

## Installed Tools

### System Packages
- curl, wget, htop, vim, tmux, tree
- build-essential, gcc, g++, make, cmake
- git, git-lfs
- jq, yq, ripgrep, fzf, bat, exa
- net-tools, nmap, traceroute, mtr

### Python Tools (via pipx)
- virtualenv
- poetry
- black, flake8, mypy
- ansible, ansible-lint

### Node.js Global Packages
- yarn, pnpm
- npm-check-updates
- nodemon, pm2

### Container Tools
- Docker CE with BuildKit
- docker-compose (standalone and plugin)
- Podman with buildah and skopeo
- podman-compose

## Customization

### Shell Aliases

Custom aliases are configured in `~/.bash_aliases`:
- Docker shortcuts: `d`, `dc`, `dps`, `di`, `dex`, `dl`
- Podman shortcuts: `p`, `pc`, `pps`, `pi`, `pex`, `pl`
- Git shortcuts: `gs`, `ga`, `gc`, `gp`, `gpl`
- System monitoring: `htop`, `df`, `du`, `free`

### Git Configuration

Git is configured with:
- Personal access token for HTTPS authentication
- Useful aliases (st, co, br, ci, lg)
- Core settings for cross-platform development

### Environment Variables

Set in `~/.env`:
- `GITHUB_TOKEN` - For authenticated GitHub operations
- `WORKSPACE` - Default workspace directory
- `DOCKER_BUILDKIT=1` - Enable BuildKit by default
- Go, Rust, Node.js paths as needed

## Troubleshooting

### Docker Permission Denied

If you get permission errors with Docker:
```bash
# Ensure user is in docker group
sudo usermod -aG docker $USER
# Log out and back in
```

### GitHub Authentication

To verify GitHub token authentication:
```bash
gh auth status
git clone https://github.com/your-private/repo.git
```

### Podman vs Docker Conflicts

Both can coexist. Use aliases:
- `docker` commands use Docker
- `podman` commands use Podman

## License

MIT