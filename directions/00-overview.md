# Homelab Setup Overview

## Quick Links

1. [SSH Setup](01-ssh-setup.md) - Configure SSH key access
2. [New Machine Setup](02-new-machine-setup.md) - Prepare fresh Debian 12 servers
3. [Ansible Deployment](03-ansible-deployment.md) - Automated service deployment
4. [Plex Setup](04-plex-setup.md) - Media server configuration
5. [Secrets Management](05-secrets-management.md) - Managing sensitive data

## Deployment Criteria

Services can be deployed to any server based on:
- Available resources (CPU, RAM, storage)
- Network requirements
- Hardware dependencies (e.g., Zigbee USB stick)

## Typical Workflow

### 1. Initial Server Setup

For a brand new Proxmox VM:

```bash
# During VM creation in Proxmox:
# - Add your SSH public key in Cloud-Init tab
# - Set hostname and network configuration

# After VM starts, SSH in:
ssh -i ~/.ssh/scv debian@192.168.1.10

# Run initial setup
curl -fsSL https://raw.githubusercontent.com/erikwestlund/homelab/main/scripts/debian12/bootstrap.sh | bash
```

### 2. Configure Secrets

On your local machine:

```bash
cd ~/code/homelab/ansible
cp secrets.yaml.example secrets.yaml
vim secrets.yaml  # Add your secrets
put-secrets      # Sync to cloud storage
```

### 3. Deploy Services

Using Ansible from your local machine:

```bash
cd ~/code/homelab/ansible

# Update inventory with your server IPs
vim inventories/homelab.yml

# Deploy everything
ansible-playbook playbooks/site.yml

# Or deploy specific service
ansible-playbook playbooks/site.yml --tags plex
```

## Service Deployment Strategies

### Resource-Light Services
- Pi-hole
- Tailscale
- Mosquitto/Zigbee2MQTT

Can run on smaller VMs (1-2 CPU, 2-4GB RAM)

### Resource-Heavy Services
- Plex (especially with transcoding)
- Home Assistant (with many integrations)
- Windows VMs

Need larger VMs (4+ CPU, 8+ GB RAM)

### Hardware-Dependent Services
- Zigbee2MQTT - Needs Zigbee USB coordinator
- Plex with hardware transcoding - Needs GPU/Intel Quick Sync

## Common Commands Reference

### Check Service Status

```bash
# Via Ansible
ansible all -i inventories/homelab.yml -a "docker ps"

# On specific server
ssh nexus
docker ps
```

### Update Services

```bash
# Update all services
ansible-playbook playbooks/site.yml

# Update specific service
ansible-playbook playbooks/site.yml --tags plex
```

### View Logs

```bash
# On server
docker logs -f plex
docker logs --tail 50 zigbee2mqtt
```

### Backup Services

```bash
# Manual backup example
ssh nexus
tar -czf /backups/pihole-$(date +%Y%m%d).tar.gz /opt/docker/pihole
```

## Troubleshooting Tips

### Can't Connect via SSH

1. Check VM has started: Proxmox console
2. Verify IP address: `ip addr` in console
3. Test with verbose: `ssh -vvv -i ~/.ssh/scv debian@IP`

### Ansible Fails

1. Test connection: `ansible all -m ping`
2. Check Python: `ansible all -a "which python3"`
3. Verify sudo: `ansible all -b -a "whoami"`

### Service Won't Start

1. Check logs: `docker logs SERVICE_NAME`
2. Verify resources: `df -h` and `free -h`
3. Check permissions: `ls -la /opt/docker/SERVICE`

## Best Practices

1. **Always test in check mode first**
   ```bash
   ansible-playbook playbooks/site.yml --check --diff
   ```

2. **Use tags for selective deployment**
   ```bash
   ansible-playbook playbooks/site.yml --tags "common,plex"
   ```

3. **Keep secrets secure**
   - Never commit `secrets.yaml`
   - Use `put-secrets` after changes
   - Rotate credentials regularly

4. **Monitor resources**
   ```bash
   # Set up monitoring
   ansible all -m cron -a "name='docker stats' minute='*/5' job='docker stats --no-stream >> /var/log/docker-stats.log'"
   ```

## Next Steps

1. Start with [SSH Setup](01-ssh-setup.md)
2. Then follow [New Machine Setup](02-new-machine-setup.md)
3. Configure secrets as per [Secrets Management](05-secrets-management.md)
4. Deploy services using [Ansible Deployment](03-ansible-deployment.md)

## Getting Help

- Check service logs first
- Review the specific service README in `services/SERVICE_NAME/`
- Check Ansible role in `ansible/roles/SERVICE_NAME/`
- Consult the official documentation for each service