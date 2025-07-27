# Ansible Deployment Guide

Deploying services using Ansible.

## Prerequisites

- Ansible installed on your local machine
- SSH key access configured (see `01-ssh-setup.md`)
- Secrets configured (see `06-secrets-management.md`)

## Step 1: Install Ansible (Local Machine)

On your local machine:

```bash
# macOS
brew install ansible

# Or with pip
pip3 install ansible
```

## Step 2: Clone Repository

```bash
cd ~/code
git clone https://github.com/erikwestlund/homelab.git
cd homelab/ansible
```

## Step 3: Install Ansible Dependencies

```bash
ansible-galaxy install -r requirements.yml
```

## Step 4: Update Inventory

Edit the inventory with your actual IPs:

```bash
vim inventories/homelab.yml
```

Update the IP addresses:

```yaml
nexus.local:
  ansible_host: 192.168.1.10  # Your actual Nexus IP
hatchery.local:
  ansible_host: 192.168.1.11  # Your actual Hatchery IP
```

## Step 5: Test Connection

Test ansible can connect to your servers:

```bash
# Test all hosts
ansible all -i inventories/homelab.yml -m ping

# Test specific host
ansible nexus -i inventories/homelab.yml -m ping
```

## Step 6: Deploy Everything

Deploy all services to all servers:

```bash
ansible-playbook playbooks/site.yml
```

## Step 7: Deploy Specific Services

### Deploy only to Nexus servers:

```bash
ansible-playbook playbooks/nexus.yml
```

### Deploy only to Hatchery servers:

```bash
ansible-playbook playbooks/hatchery.yml
```

### Deploy only Plex:

```bash
ansible-playbook playbooks/site.yml --tags plex
```

### Deploy only common setup (Docker, etc):

```bash
ansible-playbook playbooks/site.yml --tags common
```

## Step 8: Check What Would Change

Use check mode to see what would be changed:

```bash
ansible-playbook playbooks/site.yml --check --diff
```

## Common Deployment Commands

### Full deployment with verbose output:

```bash
ansible-playbook playbooks/site.yml -v
```

### Deploy Plex with specific claim token:

```bash
ansible-playbook playbooks/plex.yml -e "plex_claim_token=claim-xxxxxxxxxxxx"
```

### Deploy to specific host only:

```bash
ansible-playbook playbooks/site.yml --limit hatchery
```

### Skip certain tags:

```bash
ansible-playbook playbooks/site.yml --skip-tags docker
```

## Troubleshooting

### SSH Connection Issues

```bash
# Test with verbose SSH
ansible nexus -i inventories/homelab.yml -m ping -vvv

# Specify SSH key explicitly
ansible-playbook playbooks/site.yml --private-key ~/.ssh/scv
```

### Python Interpreter Issues

Add to your inventory if needed:

```yaml
ansible_python_interpreter: /usr/bin/python3
```

### Become Password Required

If sudo requires password:

```bash
ansible-playbook playbooks/site.yml --ask-become-pass
```

## Useful Ad-Hoc Commands

### Check disk space:

```bash
ansible all -i inventories/homelab.yml -a "df -h"
```

### Check Docker status:

```bash
ansible all -i inventories/homelab.yml -a "docker ps"
```

### Restart a service:

```bash
ansible hatchery -i inventories/homelab.yml -m systemd -a "name=docker state=restarted" --become
```

### Update all packages:

```bash
ansible all -i inventories/homelab.yml -m apt -a "upgrade=dist update_cache=yes" --become
```

## Next Steps

- Deploy Plex (see `04-plex-setup.md`)
- Set up monitoring
- Configure backups