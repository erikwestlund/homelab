# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains infrastructure-as-code for managing homelab services across Proxmox servers. Services can be deployed to any server based on resource requirements and availability.

The repository provides scripts, Docker configurations, Ansible playbooks, and deployment templates for quick service configuration.

## Repository Structure

```
homelab/
├── services/           # All service configurations
│   ├── zigbee-mqtt/    # Mosquitto + Zigbee2MQTT setup
│   ├── home-assistant/ # Home Assistant configuration
│   ├── pihole/         # Pi-hole DNS configuration
│   ├── tailscale/      # Tailscale exit node setup
│   ├── plex/           # Plex media server
│   ├── windows-vms/    # Windows VM configurations
│   ├── peanut/         # PeaNUT web interface for UPS monitoring
│   └── monitoring-stack/ # InfluxDB + Telegraf + Grafana stack
├── ansible/            # Ansible playbooks and roles
│   ├── inventories/    # Server definitions
│   ├── roles/          # Service roles
│   │   ├── common/     # Base system setup
│   │   ├── nut-server/ # Network UPS Tools configuration
│   │   └── peanut/     # PeaNUT deployment
│   ├── playbooks/      # Deployment playbooks
│   └── secrets.yaml    # Service credentials (not in git)
├── scripts/            # Utility scripts
│   └── debian12/       # Debian 12 specific scripts
├── directions/         # Step-by-step guides
├── deployments/        # Production-ready configurations
└── backups/            # Backup storage (gitignored)
```

## Common Commands

### Service Deployment
```bash
# Deploy all services using Ansible
cd ansible
ansible-galaxy install -r requirements.yml
ansible-playbook -i inventories/homelab.yml playbooks/site.yml

# Deploy specific service
ansible-playbook -i inventories/homelab.yml playbooks/deploy-monitoring-stack.yml

# Manual service setup (from services/[service-name]/)
./setup.sh                          # Default installation
./setup.sh --install-dir ~/homelab  # Custom directory
```

### Docker Operations
```bash
# From installation directory (e.g., /opt/docker/[service])
docker-compose up -d          # Start all services
docker-compose down           # Stop all services
docker-compose logs -f        # View logs for all services
docker-compose logs [service] # View specific service logs
docker-compose restart [service] # Restart specific service
docker-compose pull          # Update Docker images
docker-compose ps            # Check container status
```

### Monitoring Commands
```bash
# UPS status check
upsc homelab@ups-monitor.lan:3493
upsc network@ups-monitor.lan:3493

# Service health checks
curl http://localhost:8086/health  # InfluxDB
curl http://localhost:8080         # Zigbee2MQTT
curl http://localhost:3000          # Grafana

# Install monitoring scripts
sudo ./install-monitor.sh  # Creates cron job for health checks
```

## Service Architecture

### Monitoring Stack
- **InfluxDB 2.7**: Time-series database with infinite retention on 1TB SSD
- **Telegraf 1.31**: Metrics collector (Docker, system, UPS, Home Assistant)
- **Grafana 11.1.0**: Visualization dashboards
- **Access**: Grafana at http://docker-services-host.lan:3000
- **Network**: External integration with nginx-proxy-manager_default

### Zigbee-MQTT Stack
- **Mosquitto**: MQTT broker (ports 1883/9001)
- **Zigbee2MQTT**: Zigbee gateway with web UI (port 8080)
- **Installation**: `/opt/docker/zigbee-mqtt/`
- **Configuration**: Auto-generated credentials in `.env`

### Infrastructure Services
- **Nginx Proxy Manager**: SSL termination and reverse proxy
- **Portainer**: Container management interface
- **Pi-hole**: DNS filtering
- **Home Assistant**: Home automation with InfluxDB integration

### Host Infrastructure
- **nexus.lan**: Primary Proxmox host
- **hatchery.lan**: Secondary Proxmox host
- **docker-services-host.lan**: Intel N100 running core services
- **ups-monitor.lan**: Dedicated VM for UPS monitoring
- **ha.lan**: Home Assistant VM

## Credentials Management

ALWAYS use credentials from `/Users/erikwestlund/code/homelab/ansible/secrets.yaml` when deploying services. Never generate new passwords if they already exist in secrets.yaml.

### Credential Structure in secrets.yaml
- **npm**: admin_email (username!), admin_password, ssl_email, cloudflare_api_token
- **monitoring.influxdb**: username, password, token
- **monitoring.grafana**: username, password
- **portainer**: admin_password
- **peanut**: password
- **nas.media_server**: host, username, password

## Docker Networking Best Practices

- **Always use container names** for inter-container communication
- **Ensure containers share a Docker network** (e.g., nginx-proxy-manager_default)
- **Use internal container ports** when proxying between containers (not host-mapped ports)
- **Example**: For Grafana mapped as `3001:3000`, use port `3000` when proxying from another container

## Development Workflow

1. **Development**: Work in `services/*/` directories
2. **Testing**: Test configurations locally or in development environment
3. **Production**: Deploy using Ansible playbooks or copy configs to `deployments/`
4. **Backup**: Store sensitive data in `backups/` (gitignored)

### Adding New Services
1. Create directory under `services/`
2. Create Ansible role in `ansible/roles/`
3. Add setup scripts and documentation
4. Test thoroughly
5. Deploy with Ansible playbooks

### Configuration Generation Pattern
- `.env.example` → `.env` with generated credentials
- `docker-compose.yml.template` → `docker-compose.yml` with device mappings
- Templates in Ansible roles for service configurations

## Home Assistant Integration

Add to HA configuration.yaml for InfluxDB:
```yaml
influxdb:
  api_version: 2
  ssl: false
  host: docker-services-host.lan
  port: 8086
  token: "YOUR_TOKEN_FROM_ENV"  # Get from monitoring-stack/.env
  organization: homelab
  bucket: metrics
```

## Storage and Backup Strategy

- **Monitoring data**: `/mnt/storage/influxdb` on 1TB dedicated SSD (15-20+ years capacity)
- **Service configs**: Bind mounts to preserve data across container recreations
- **Sensitive data**: Store in `backups/` directory (gitignored)
- **Generated files**: Excluded from git via `.gitignore`