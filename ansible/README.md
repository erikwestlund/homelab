# Homelab Ansible Configuration

This directory contains Ansible playbooks and roles for managing the homelab infrastructure.

## Prerequisites

1. **SSH Key Setup:**
   - Ensure `~/.ssh/scv` and `~/.ssh/scv.pub` exist on your local machine
   - These keys are automatically used by the Ansible inventory

2. **Secrets Management:**
   - Copy `secrets.yaml.example` to `secrets.yaml`
   - Fill in your actual secret values
   - Run `put-secrets` to sync to your secure storage
   - Run `sync-secrets` on new machines to pull secrets

## Quick Start

1. **Install Ansible requirements:**
   ```bash
   ansible-galaxy install -r requirements.yml
   ```

2. **Update inventory:**
   Edit `inventories/homelab.yml` with your actual server IPs.

3. **Set up secrets:**
   ```bash
   cp secrets.yaml.example secrets.yaml
   # Edit secrets.yaml with your values
   put-secrets  # Sync to secure storage
   ```

4. **Deploy everything:**
   ```bash
   ansible-playbook playbooks/site.yml
   ```

## Selective Deployment

Deploy only specific services using tags:

```bash
# Deploy only Plex
ansible-playbook playbooks/site.yml --tags plex

# Deploy all Nexus services
ansible-playbook playbooks/site.yml --tags nexus

# Deploy only common setup (Docker, etc.)
ansible-playbook playbooks/site.yml --tags common
```

Or use specific playbooks:

```bash
# Deploy to Hatchery only
ansible-playbook playbooks/hatchery.yml

# Deploy Plex only
ansible-playbook playbooks/plex.yml
```

## Testing Changes

Always test with `--check` first:

```bash
ansible-playbook playbooks/site.yml --check --diff
```

## Variables

- **Global vars**: `group_vars/all.yml`
- **Nexus-specific**: `group_vars/nexus.yml`
- **Hatchery-specific**: `group_vars/hatchery.yml`

Override any variable from the command line:

```bash
ansible-playbook playbooks/plex.yml -e "plex_claim_token=YOUR_TOKEN"
```

## Roles

- **common**: Base system setup, Docker installation
- **plex**: Plex Media Server with hardware transcoding
- **pihole**: Pi-hole DNS server (placeholder)
- **home-assistant**: Home Assistant (placeholder)
- **zigbee-mqtt**: Mosquitto + Zigbee2MQTT (placeholder)

## Adding New Services

1. Create a new role: `ansible-galaxy init roles/SERVICE_NAME`
2. Add to appropriate playbook
3. Configure variables in group_vars
4. Test thoroughly before deploying