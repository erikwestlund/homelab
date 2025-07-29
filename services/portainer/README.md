# Portainer CE - Docker Container Management

Portainer provides a web-based UI for managing Docker containers, images, volumes, networks, and more across your homelab.

## Overview

- **Web UI**: Comprehensive Docker management interface
- **Multi-host**: Can manage multiple Docker endpoints
- **Security**: HTTPS-only configuration with strong authentication
- **Features**: Container management, logs, stats, exec, and stack deployment

## Quick Start

### Automated Deployment (Ansible)

```bash
# Deploy Portainer to docker-services-host
cd ~/code/homelab/ansible
ansible-playbook -i inventories/homelab.yml playbooks/portainer.yml

# Or as part of all docker services
ansible-playbook -i inventories/homelab.yml playbooks/docker-services.yml --tags portainer
```

### Manual Setup

```bash
# Clone and setup
cd /opt/docker
cp -r /path/to/homelab/services/portainer .
cd portainer
./setup.sh

# Start Portainer
docker-compose up -d
```

## Access

- **URL**: https://docker-services-host.lan:9443
- **Default Port**: 9443 (HTTPS only)
- **Edge Agent Port**: 8000 (optional, for remote endpoints)

## Initial Configuration

1. **First Login**:
   - Navigate to https://docker-services-host.lan:9443
   - Create admin user with the generated password
   - Password location: `/opt/docker/portainer/.portainer_password`

2. **Environment Setup**:
   - Choose "Get Started" for local Docker environment
   - Or add remote endpoints for other Docker hosts

3. **Security**:
   - HTTP is disabled by default (HTTPS only)
   - Strong password auto-generated during setup
   - Consider adding behind Nginx Proxy Manager for custom domain

## Features

### Container Management
- Start/Stop/Restart containers
- View logs in real-time
- Access container console
- Monitor resource usage
- Update container images

### Stack Deployment
- Deploy docker-compose stacks through UI
- Edit existing stack configurations
- Manage stack environments and variables

### System Overview
- Dashboard showing all containers across hosts
- Resource utilization graphs
- Image management and cleanup
- Volume and network management

## Integration with Existing Services

Portainer automatically discovers and can manage all existing containers:

- **Monitoring Stack**: InfluxDB, Telegraf, Grafana
- **PeaNUT**: UPS monitoring interface
- **Nginx Proxy Manager**: Reverse proxy
- **Zigbee2MQTT**: If running on same host
- Any other Docker containers

## Configuration Files

### docker-compose.yml
```yaml
version: '3.8'

services:
  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    restart: unless-stopped
    ports:
      - "9443:9443"
      - "8000:8000"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data
    command: --http-disabled
```

### Environment Variables
- `PORTAINER_ADMIN_PASSWORD`: Initial admin password
- `TZ`: Timezone setting
- `PORTAINER_HTTPS_PORT`: HTTPS port (default: 9443)

## Maintenance

### Backup
```bash
# Backup Portainer data
docker run --rm -v portainer_data:/data -v $(pwd):/backup alpine \
  tar czf /backup/portainer-backup-$(date +%Y%m%d).tar.gz -C /data .
```

### Update
```bash
cd /opt/docker/portainer
docker-compose pull
docker-compose up -d
```

### View Logs
```bash
docker-compose logs -f portainer
```

## Security Considerations

1. **Access Control**:
   - Always use strong admin password
   - Enable RBAC for team environments
   - Regularly review user access

2. **Network Security**:
   - HTTPS-only configuration
   - Consider firewall rules
   - Use reverse proxy for internet access

3. **Docker Socket**:
   - Portainer has full Docker control
   - Understand the security implications
   - Consider using endpoints with limited scope

## Troubleshooting

### Cannot Access Web UI
```bash
# Check if container is running
docker ps | grep portainer

# Check logs
docker logs portainer

# Verify port is listening
netstat -tlnp | grep 9443
```

### Reset Admin Password
```bash
# Stop Portainer
docker-compose down

# Reset password
docker run --rm -v portainer_data:/data portainer/helper-reset-password

# Restart with new password
docker-compose up -d
```

### Certificate Issues
- Portainer uses self-signed certificates by default
- Accept the certificate warning in your browser
- Or add custom certificates in /data/certs/

## Advanced Features

### Adding Remote Endpoints
1. Go to Settings → Endpoints
2. Add endpoint with Docker API URL
3. Configure TLS if required

### GitOps Integration
- Can deploy from Git repositories
- Supports webhooks for auto-deployment
- Integrated with GitHub, GitLab, etc.

### Templates
- Create custom application templates
- Share templates across team
- One-click deployments

## Resource Requirements
- **CPU**: Minimal (< 1% idle)
- **Memory**: ~50-100MB
- **Storage**: < 100MB + container data

## Related Documentation
- [Official Portainer Docs](https://docs.portainer.io/)
- [Docker Management Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Homelab Services Overview](../README.md)