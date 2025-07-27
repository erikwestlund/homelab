# New Machine Setup

Fresh Debian 12 setup using Ansible.

## Prerequisites

- SSH key access configured (see `01-ssh-setup.md`)
- Ansible installed on local machine
- Target server added to inventory

## Step 1: Update Inventory

Add new server to `ansible/inventories/homelab.yml`:

```yaml
newserver:
  ansible_host: newserver.lan
  ansible_user: root
  ansible_ssh_private_key_file: ~/.ssh/scv
```

## Step 2: Test Connection

```bash
cd ~/code/homelab/ansible
ansible newserver -i inventories/homelab.yml -m ping
```

## Step 3: Run Initial Setup

Deploy common role to new machine:

```bash
ansible-playbook playbooks/site.yml --limit newserver --tags common
```

This will:
- Update system packages
- Install essential tools
- Configure firewall
- Install Docker
- Create directory structure
- Set system limits
- Configure timezone
- Set up automatic updates

## Step 4: Verify Setup

```bash
# Check installed packages
ansible newserver -a "docker --version"

# Check directories
ansible newserver -a "ls -la /opt/docker"

# Check firewall
ansible newserver -b -a "ufw status"

# Check timezone
ansible newserver -a "timedatectl"
```

## Manual Bootstrap (if needed)

If Ansible can't connect initially:

```bash
# Minimal setup on target server
apt update && apt install -y python3 python3-apt
```

Then run Ansible playbook.

## Next Steps

1. Deploy specific services with Ansible (see `03-ansible-deployment.md`)
2. Configure service-specific secrets (see `05-secrets-management.md`)