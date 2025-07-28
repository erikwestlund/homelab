# Common Tasks

## Table of Contents

- [Proxmox Tasks](#proxmox-tasks)
  - [Fix Enterprise Repository Error](#fix-enterprise-repository-error)
  - [Update Proxmox](#update-proxmox)
  - [Backup VMs](#backup-vms)
- [VM Management](#vm-management)
  - [Create New VM](#create-new-vm)
  - [Update All VMs](#update-all-vms)
  - [Check VM Health](#check-vm-health)
- [Service Management](#service-management)
  - [Restart Services](#restart-services)
  - [Update Docker Images](#update-docker-images)
  - [Check Service Logs](#check-service-logs)
- [Monitoring](#monitoring)
  - [Check All Services](#check-all-services)
  - [View Resource Usage](#view-resource-usage)
  - [Check Mount Points](#check-mount-points)
- [Backup and Recovery](#backup-and-recovery)
  - [Manual Backup](#manual-backup)
  - [Restore from Backup](#restore-from-backup)
  - [Verify Backups](#verify-backups)
- [Security](#security)
  - [Update SSH Keys](#update-ssh-keys)
  - [Rotate Secrets](#rotate-secrets)
  - [Security Audit](#security-audit)

## Proxmox Tasks

### Fix Enterprise Repository Error

Fix the "apt-get update failed: exit code 100" error on all Proxmox hosts:

```bash
cd ~/code/homelab/ansible
ansible-playbook playbooks/fix-proxmox-repos.yml
```

This playbook will:
- Remove enterprise repository files
- Add no-subscription repositories for PVE and Ceph
- Update package cache
- Upgrade all packages

Run on a single host:
```bash
ansible-playbook playbooks/fix-proxmox-repos.yml --limit nexus
```

### Update Proxmox

```bash
# Update all Proxmox hosts
ansible -i hosts proxmox-hosts -m apt -a "upgrade=dist" -b

# Reboot if kernel was updated
ansible -i hosts proxmox-hosts -m reboot -b
```

### Backup VMs

```bash
# List all VMs
pvesh get /nodes/nexus/qemu
pvesh get /nodes/hatchery/qemu

# Backup specific VM
vzdump <vmid> --storage local --mode snapshot --compress zstd

# Backup all VMs on a node
vzdump --all --storage local --mode snapshot --compress zstd
```

## VM Management

### Create New VM

```bash
# Clone from template
qm clone <template-id> <new-vmid> --name <vm-name>

# Set resources
qm set <vmid> --cores 2 --memory 4096 --net0 virtio,bridge=vmbr0

# Start VM
qm start <vmid>
```

### Update All VMs

```bash
# Update all Debian-based VMs
cd ~/code/homelab/ansible
ansible all -m apt -a "update_cache=yes upgrade=dist" -b

# Reboot all VMs
ansible all -m reboot -b
```

### Check VM Health

```bash
# Check all VMs status
ansible all -m ping

# Check disk usage
ansible all -a "df -h"

# Check memory usage
ansible all -a "free -h"

# Check running services
ansible all -a "systemctl status docker"
```

## Service Management

### Restart Services

```bash
# Restart Plex
ansible plex-server -a "docker restart plex"

# Restart Zigbee2MQTT
ansible zigbee-mqtt -a "docker restart zigbee2mqtt mosquitto"

# Restart all Docker containers on a host
ansible <host> -a "docker restart \$(docker ps -q)"
```

### Update Docker Images

```bash
# Update specific service
ansible plex-server -a "docker pull lscr.io/linuxserver/plex:latest && docker restart plex"

# Update all images on a host
ansible <host> -m shell -a "docker images --format '{{.Repository}}:{{.Tag}}' | grep -v none | xargs -L1 docker pull"
```

### Check Service Logs

```bash
# View Plex logs
ansible plex-server -a "docker logs --tail 100 plex"

# View Zigbee2MQTT logs
ansible zigbee-mqtt -a "docker logs --tail 100 zigbee2mqtt"

# Follow logs in real-time
ssh root@<host> docker logs -f <container>
```

## Monitoring

### Check All Services

```bash
# Run comprehensive status check
cd ~/code/homelab/ansible
ansible all -m shell -a "docker ps --format 'table {{.Names}}\t{{.Status}}' && echo && df -h /media 2>/dev/null || true"

# Check specific service status
ansible plex-server -a "/opt/docker/plex/check-status.sh"
```

### View Resource Usage

```bash
# CPU and Memory usage
ansible all -a "top -bn1 | head -20"

# Docker resource usage
ansible all -a "docker stats --no-stream"

# Disk I/O
ansible all -a "iostat -x 1 3"
```

### Check Mount Points

```bash
# Verify NAS mounts
ansible all -a "mount | grep cifs"

# Check mount health
ansible plex-server -a "ls -la /media/"

# Force remount if needed
ansible plex-server -b -a "umount /media && mount -a"
```

## Backup and Recovery

### Manual Backup

```bash
# Backup Plex configuration
ssh root@plex-server
docker exec plex tar czf - /config > /tmp/plex-backup-$(date +%Y%m%d).tar.gz

# Backup Zigbee2MQTT
ssh root@zigbee-mqtt
cd /opt/docker && tar czf /tmp/zigbee2mqtt-backup-$(date +%Y%m%d).tar.gz zigbee2mqtt/data

# Copy backups locally
scp root@<host>:/tmp/*backup*.tar.gz ~/backups/
```

### Restore from Backup

```bash
# Restore Plex
docker stop plex
cd /opt/docker/plex/config
tar xzf /path/to/plex-backup.tar.gz
docker start plex

# Restore Zigbee2MQTT
docker stop zigbee2mqtt
cd /opt/docker/zigbee2mqtt/data
tar xzf /path/to/zigbee2mqtt-backup.tar.gz
docker start zigbee2mqtt
```

### Verify Backups

```bash
# List Proxmox backups
pvesm list local --content backup

# Verify backup integrity
tar tzf backup.tar.gz > /dev/null && echo "Backup is valid"
```

## Security

### Update SSH Keys

```bash
# Deploy new SSH key to all hosts
cd ~/code/homelab/ansible
ansible all -m authorized_key -a "user=root key='{{ lookup('file', '~/.ssh/scv.pub') }}' state=present"

# Remove old SSH key
ansible all -m authorized_key -a "user=root key='old-key-content' state=absent"
```

### Rotate Secrets

```bash
# Update secrets.yaml
vim ~/code/homelab/ansible/secrets.yaml

# Push to secure storage
put-secrets

# Redeploy services with new secrets
ansible-playbook playbooks/site.yml
```

### Security Audit

```bash
# Check for security updates
ansible all -m shell -a "apt list --upgradable 2>/dev/null | grep -i security"

# Check open ports
ansible all -a "ss -tlnp"

# Check failed login attempts
ansible all -a "journalctl -u ssh --since '1 week ago' | grep -i failed"

# Verify firewall rules (if using ufw)
ansible all -a "ufw status verbose"
```

## Quick Commands Reference

```bash
# SSH to any VM
ssh -i ~/.ssh/scv root@<hostname>.lan

# Quick health check
ansible all -m ping

# Emergency stop all Docker containers
ansible <host> -a "docker stop \$(docker ps -q)"

# View real-time logs
ssh root@<host> journalctl -f

# Check service uptime
ansible all -a uptime

# Find large files
ansible all -a "find / -type f -size +1G -exec ls -lh {} \; 2>/dev/null"
```