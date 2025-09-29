# Homelab Ansible Configuration

This directory contains Ansible playbooks and roles for managing the homelab infrastructure.

## Prerequisites

1. **SSH Key Setup:**
   - Ensure `~/.ssh/scv` and `~/.ssh/scv.pub` exist on your local machine
   - These keys are automatically used by the Ansible inventory

2. **Python & Ansible:**
   ```bash
   # Install Ansible (macOS)
   brew install ansible
   
   # Or via pip
   pip install ansible ansible-lint
   ```

3. **Secrets Management:**
   - Copy `secrets.yaml.example` to `secrets.yaml`
   - Fill in your actual secret values
   - Never commit secrets.yaml to git

## Infrastructure Overview

### Proxmox Hosts
- **nexus.lan**: Primary Proxmox server
- **hatchery.lan**: Secondary Proxmox server

### Virtual Machines & Containers
- **docker-services-host.lan**: Intel N100 running core Docker services
- **ups-monitor.lan**: Dedicated VM for UPS monitoring (on hatchery)
- **ha.lan**: Home Assistant VM
- **pihole.lan**: Pi-hole DNS server
- **plex-server.lan**: Plex Media Server

## Quick Start

1. **Clone the repository:**
   ```bash
   git clone <repo-url> ~/code/homelab
   cd ~/code/homelab/ansible
   ```

2. **Set up secrets:**
   ```bash
   cp secrets.yaml.example secrets.yaml
   # Edit secrets.yaml with your values
   ```

3. **Test connectivity:**
   ```bash
   ansible all -i inventories/homelab.yml -m ping
   ```

4. **Deploy everything:**
   ```bash
   ansible-playbook -i inventories/homelab.yml playbooks/site.yml
   ```

## Common Playbooks

### Infrastructure Setup
```bash
# Remove Proxmox subscription notices
ansible-playbook -i inventories/homelab.yml playbooks/remove-subscription-notice.yml

# Deploy common packages and Docker
ansible-playbook -i inventories/homelab.yml playbooks/common-setup.yml
```

### Service Deployment
```bash
# Development VM Setup
ansible-playbook -i inventories/homelab.yml playbooks/setup-dev-vm.yml

# UPS Monitoring (NUT + PeaNUT)
ansible-playbook -i inventories/homelab.yml playbooks/ups-monitor.yml

# Monitoring Stack (InfluxDB + Telegraf + Grafana)
ansible-playbook -i inventories/homelab.yml playbooks/deploy-monitoring-stack.yml

# Plex Media Server
ansible-playbook -i inventories/homelab.yml playbooks/plex.yml

# Home Assistant
ansible-playbook -i inventories/homelab.yml playbooks/home-assistant.yml
```

## Selective Deployment

### Deploy to Specific Hosts
```bash
# Deploy only to docker-services-host
ansible-playbook -i inventories/homelab.yml playbooks/site.yml --limit docker-services-host

# Deploy only to Proxmox hosts
ansible-playbook -i inventories/homelab.yml playbooks/site.yml --limit proxmox_hosts
```

### Deploy Specific Services (Tags)
```bash
# Deploy only monitoring services
ansible-playbook -i inventories/homelab.yml playbooks/site.yml --tags monitoring

# Deploy only UPS monitoring
ansible-playbook -i inventories/homelab.yml playbooks/site.yml --tags nut,peanut

# Skip certain tags
ansible-playbook -i inventories/homelab.yml playbooks/site.yml --skip-tags slow
```

## Testing Changes

Always test with `--check` first:
```bash
# Dry run to see what would change
ansible-playbook -i inventories/homelab.yml playbooks/site.yml --check --diff

# Test specific playbook
ansible-playbook -i inventories/homelab.yml playbooks/ups-monitor.yml --check
```

## Available Roles

### System & Infrastructure
- **common**: Base system setup, Docker installation, essential packages
- **remove-proxmox-subscription**: Removes Proxmox subscription notices

### Monitoring & UPS
- **nut-server**: Network UPS Tools server configuration
- **peanut**: PeaNUT web interface for UPS monitoring
- **monitoring-stack**: InfluxDB + Telegraf + Grafana deployment

### Services
- **plex**: Plex Media Server with hardware transcoding
- **pihole**: Pi-hole DNS server
- **home-assistant**: Home Assistant with Emporia Vue integration
- **zigbee-mqtt**: Mosquitto + Zigbee2MQTT
- **nginx-proxy-manager**: Reverse proxy with SSL

## Variables & Configuration

### Variable Hierarchy
1. **Global vars**: `group_vars/all.yml`
2. **Host group vars**: 
   - `group_vars/proxmox_hosts.yml`
   - `group_vars/nexus_services.yml`
   - `group_vars/hatchery_services.yml`
3. **Host-specific vars**: `host_vars/hostname.yml`
4. **Role defaults**: `roles/*/defaults/main.yml`

### Override Variables
```bash
# Override any variable from command line
ansible-playbook -i inventories/homelab.yml playbooks/plex.yml -e "plex_claim_token=YOUR_TOKEN"

# Use extra vars file
ansible-playbook -i inventories/homelab.yml playbooks/site.yml -e @extra_vars.yml
```

## Creating New Services

1. **Create the role:**
   ```bash
   ansible-galaxy init roles/SERVICE_NAME
   ```

2. **Add to inventory:**
   Edit `inventories/homelab.yml` to add the new host/service

3. **Create playbook:**
   ```bash
   cp playbooks/template.yml playbooks/SERVICE_NAME.yml
   # Edit the playbook
   ```

4. **Configure variables:**
   - Add defaults in `roles/SERVICE_NAME/defaults/main.yml`
   - Add secrets to `secrets.yaml` if needed

5. **Test thoroughly:**
   ```bash
   ansible-playbook -i inventories/homelab.yml playbooks/SERVICE_NAME.yml --check
   ```

## Troubleshooting

### SSH Connection Issues
```bash
# Test SSH manually
ssh -i ~/.ssh/scv root@hostname.lan

# Use verbose mode
ansible -i inventories/homelab.yml all -m ping -vvv
```

### Sudo/Privilege Issues
Some hosts don't have sudo installed. The inventory sets `ansible_become: no` for these hosts.

### Python Interpreter
The inventory specifies `ansible_python_interpreter: /usr/bin/python3` for all hosts.

## Maintenance

### Update All Services
```bash
# Pull latest Docker images and restart
ansible-playbook -i inventories/homelab.yml playbooks/update-all-services.yml
```

### Backup Configurations
```bash
# Backup all service configurations
ansible-playbook -i inventories/homelab.yml playbooks/backup-configs.yml
```

## Security Notes

1. **Never commit secrets.yaml** - It's in .gitignore
2. **Use strong passwords** - Generated in roles when possible
3. **Limit SSH access** - Use SSH keys only
4. **Regular updates** - Keep services and OS updated
5. **Firewall rules** - Implemented per service as needed

## Directory Structure
```
ansible/
├── inventories/
│   └── homelab.yml         # Main inventory file
├── playbooks/
│   ├── site.yml           # Master playbook
│   ├── ups-monitor.yml    # UPS monitoring setup
│   ├── deploy-monitoring-stack.yml  # Monitoring deployment
│   └── ...
├── roles/
│   ├── common/            # Base setup role
│   ├── nut-server/        # NUT UPS monitoring
│   ├── peanut/            # PeaNUT web UI
│   ├── monitoring-stack/  # InfluxDB+Telegraf+Grafana
│   └── ...
├── group_vars/
│   └── all.yml           # Global variables
├── requirements.yml      # Ansible Galaxy requirements
├── secrets.yaml.example  # Template for secrets
└── README.md            # This file
```

## Additional Resources

- [Ansible Documentation](https://docs.ansible.com/)
- [Homelab Services Documentation](../services/README.md)
- [Infrastructure Diagrams](../docs/architecture.md)