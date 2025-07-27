# Docker Homelab Quick Start Guide

This guide helps you get started with the Mosquitto/Zigbee2MQTT Docker setup after initial installation.

## Current Setup Overview

You have successfully deployed:
- **Mosquitto MQTT Broker** - Running on port 1883
- **Zigbee2MQTT** - Running on port 8080 with web UI
- **Health monitoring** - Docker health checks + cron monitoring every minute
- **Auto-restart** - Services automatically recover from failures

## Getting Started

### 1. Access Your Services

**Zigbee2MQTT Web Interface:**
```
http://your-docker-host-ip:8080
```

**MQTT Broker:**
```
mqtt://your-docker-host-ip:1883
Username: mqtt
Password: (check your .env file)
```

### 2. Directory Structure

Your installation is located at `/opt/docker/` with:
```
/opt/docker/
├── docker-compose.yml      # Service definitions
├── .env                    # Environment variables & secrets
├── monitor-zigbee.sh       # Health monitoring script
├── mosquitto/
│   ├── config/            # Mosquitto configuration
│   ├── data/              # Persistent data
│   └── log/               # Mosquitto logs
└── zigbee2mqtt/
    └── data/              # Zigbee2MQTT config & device data
```

### 3. Common Operations

#### View Service Status
```bash
cd /opt/docker
docker ps
```

#### View Logs
```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f zigbee2mqtt
docker compose logs -f mosquitto

# Monitoring script logs
tail -f /var/log/zigbee-monitor.log
```

#### Restart Services
```bash
cd /opt/docker

# Restart both
docker compose restart

# Restart individual service
docker compose restart zigbee2mqtt
docker compose restart mosquitto
```

#### Stop/Start Services
```bash
# Stop
docker compose down

# Start
docker compose up -d
```

### 4. Adding New Devices

1. Open Zigbee2MQTT web UI: `http://your-docker-host-ip:8080`
2. Click "Permit join" button (or Settings → Permit join)
3. Put your Zigbee device in pairing mode
4. Device should appear in the UI within 30 seconds
5. Click "Disable join" when done (security best practice)

### 5. Configuration Changes

#### Update Zigbee2MQTT Settings
```bash
nano /opt/docker/zigbee2mqtt/data/configuration.yaml
docker compose restart zigbee2mqtt
```

#### Update MQTT Credentials
```bash
# Edit credentials
nano /opt/docker/.env

# Regenerate Mosquitto password file
cd /opt/docker
docker run --rm -v "$(pwd)/mosquitto/config:/mosquitto/config" eclipse-mosquitto:latest mosquitto_passwd -b -c /mosquitto/config/passwd $MQTT_USER $MQTT_PASS

# Restart services
docker compose restart
```

### 6. Backup Your Configuration

#### Quick Backup
```bash
cd /opt/docker
tar -czf zigbee-backup-$(date +%Y%m%d).tar.gz zigbee2mqtt/data mosquitto/config .env
```

#### What to Backup
- `/opt/docker/.env` - Your secrets
- `/opt/docker/zigbee2mqtt/data/` - All Zigbee config & devices
- `/opt/docker/mosquitto/config/` - MQTT configuration

### 7. Monitoring & Troubleshooting

#### Check Health Status
```bash
docker inspect zigbee2mqtt --format='{{.State.Health.Status}}'
```

#### Monitor Resource Usage
```bash
docker stats
```

#### Common Issues

**Devices Not Responding:**
1. Check device battery levels in web UI
2. Power cycle router devices (smart plugs)
3. Check logs for errors: `docker compose logs zigbee2mqtt`

**MQTT Connection Issues:**
1. Verify credentials in `.env` match configuration
2. Check Mosquitto logs: `docker compose logs mosquitto`
3. Test connection: `nc -zv localhost 1883`

**Web UI Not Loading:**
1. Check if port 8080 is open: `netstat -tlnp | grep 8080`
2. Verify container is running: `docker ps`
3. Check firewall rules

### 8. Updates

#### Update Services
```bash
cd /opt/docker

# Pull latest images
docker compose pull

# Recreate containers with new images
docker compose up -d
```

#### Update This Repository
```bash
cd /path/to/homelab
git pull

# If setup.sh or templates changed, review changes before applying
```

### 9. Integration with Home Assistant

Your MQTT integration should be configured with:
- **Broker**: Your Docker host IP
- **Port**: 1883
- **Username**: mqtt
- **Password**: From your .env file

All Zigbee devices will automatically appear in Home Assistant through MQTT discovery.

### 10. Useful Commands Reference

```bash
# Service Management
docker compose up -d              # Start services
docker compose down               # Stop services
docker compose restart            # Restart all
docker compose logs -f            # View logs
docker ps                         # List running containers

# Monitoring
tail -f /var/log/zigbee-monitor.log     # Monitor script logs
docker stats                             # Resource usage
docker compose logs --tail 50            # Last 50 log lines

# Backup
tar -czf backup.tar.gz zigbee2mqtt/data mosquitto/config .env

# Network Testing
curl http://localhost:8080              # Test Zigbee2MQTT
nc -zv localhost 1883                   # Test MQTT port
```

## Next Steps

1. **Explore Zigbee2MQTT Web UI** - Familiarize yourself with device management
2. **Set up automations** - Use MQTT topics in Home Assistant
3. **Plan backups** - Schedule regular backups of your configuration
4. **Monitor logs** - Watch for any recurring issues
5. **Join the community** - Zigbee2MQTT has excellent documentation and forums

## Getting Help

- **Zigbee2MQTT Documentation**: https://www.zigbee2mqtt.io/
- **Mosquitto Documentation**: https://mosquitto.org/documentation/
- **Docker Compose Reference**: https://docs.docker.com/compose/
- **Your monitoring log**: `/var/log/zigbee-monitor.log`