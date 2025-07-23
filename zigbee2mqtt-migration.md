# Migrating from Home Assistant Add-ons to Docker Stack

This guide helps you migrate from Home Assistant's Mosquitto and Zigbee2MQTT add-ons to a standalone Docker deployment.

## Overview

Home Assistant runs Mosquitto and Zigbee2MQTT as managed add-ons through its Supervisor. This Docker stack provides the same functionality but with more control and flexibility.

**Note**: HACS (Home Assistant Community Store) is for custom integrations. The official Mosquitto and Zigbee2MQTT are installed through Home Assistant's Add-on Store, not HACS.

## Potential Conflicts

Running both systems simultaneously will cause conflicts:

### 1. Port Conflicts
- **Mosquitto**: Port 1883 (MQTT) and 9001 (WebSocket)
- **Zigbee2MQTT**: Port 8080 (Web UI)
- Both systems use these same ports by default

### 2. Serial Device Access
- Only one process can access the Zigbee coordinator
- Both systems trying to use `/dev/ttyUSB0` will fail

### 3. MQTT Topic Collisions
- Duplicate device names in `zigbee2mqtt/` topic namespace
- Devices may appear/disappear or behave erratically

## Pre-Migration Checklist

### 1. Backup Zigbee2MQTT Data
In Home Assistant:
1. Open Zigbee2MQTT web interface (typically port 8099 in your case)
2. Go to Settings → Tools → Download backup
3. This saves:
   - `configuration.yaml` - Main configuration
   - `coordinator_backup.json` - Zigbee network backup (critical!)
   - `database.db` - Device database
   - `state.json` - Current state
   - `devices.yaml` - Device-specific settings
   - `groups.yaml` - Group configurations

### 2. Document Current Setup
Based on your backup, here's your current configuration:
- [x] MQTT broker: `mqtt://core-mosquitto` with user `mqtt`
- [x] Zigbee coordinator: `tcp://zigbee.lan:6638` (network-based)
- [x] 21 devices total (1 coordinator, 2 routers, 18 end devices)
- [x] Network uses channel 25
- [x] Web UI on port 8099

### 3. Critical Network Parameters to Preserve
Your Zigbee network security (from coordinator_backup.json):
```yaml
# These MUST be preserved for devices to reconnect:
network_key: [131, 239, 145, 218, 133, 95, 179, 251, 56, 133, 159, 145, 234, 208, 152, 208]
pan_id: 56456  # 0xdc88
ext_pan_id: [142, 154, 91, 219, 63, 24, 76, 220]
channel: 25
```

## Migration Process

### Step 1: Prepare the Docker Environment

1. Clone and set up this repository:
   ```bash
   git clone <repository-url>
   cd homelab
   ./setup.sh
   ```

2. Edit `docker/.env` with your settings:
   ```bash
   cd docker
   nano .env
   ```

### Step 2: Copy Data from Add-ons

1. **Find add-on data location**:
   - SSH into Home Assistant
   - Add-on data typically in: `/addon_configs/45df7312_zigbee2mqtt/`
   - Or check through Portainer if installed

2. **Copy Zigbee2MQTT data**:
   ```bash
   # Copy your backup to the Docker volume
   cp -r z2mbackup/* docker/zigbee2mqtt/data/
   
   # Ensure proper file structure
   cd docker/zigbee2mqtt/data/
   ls -la  # Should show configuration.yaml, database.db, etc.
   ```

3. **Adjust configuration.yaml for your network setup**:
   ```yaml
   # Your current setup uses a network coordinator
   serial:
     port: tcp://zigbee.lan:6638
     adapter: zstack
   
   # Update MQTT to use new Docker service name
   mqtt:
     server: mqtt://mosquitto:1883
     user: ${MQTT_USER}      # From your .env file
     password: ${MQTT_PASS}  # From your .env file
   
   # IMPORTANT: Keep your existing network parameters!
   advanced:
     network_key: [131, 239, 145, 218, 133, 95, 179, 251, 56, 133, 159, 145, 234, 208, 152, 208]
     pan_id: 56456
     ext_pan_id: [142, 154, 91, 219, 63, 24, 76, 220]
     channel: 25
   ```

### Step 3: Stop Home Assistant Add-ons

**Critical**: Stop add-ons before starting Docker containers!

1. In Home Assistant UI:
   - Settings → Add-ons → Mosquitto broker → STOP
   - Settings → Add-ons → Zigbee2MQTT → STOP

2. Optionally disable auto-start:
   - Toggle "Start on boot" to OFF

### Step 4: Start Docker Stack

```bash
cd docker
docker-compose up -d

# Check logs
docker-compose logs -f
```

### Step 5: Update Home Assistant Integration

1. In Home Assistant:
   - Settings → Integrations → MQTT
   - Reconfigure with new broker details:
     - Broker: `<docker_host_ip>`
     - Port: `1883`
     - Username/Password: From your `.env` file

2. Restart Home Assistant

### Step 6: Verify Migration

- [ ] All Zigbee devices appear in Zigbee2MQTT web UI
- [ ] Devices respond to commands
- [ ] Home Assistant sees all devices through MQTT
- [ ] Automations still work

## Testing Both Systems (Temporary)

If you need to test before fully migrating:

1. **Use different ports** in `docker-compose.yml`:
   ```yaml
   mosquitto:
     ports:
       - "1884:1883"  # Different host port
       - "9002:9001"
   
   zigbee2mqtt:
     ports:
       - "8081:8080"  # Different host port
   ```

2. **Use different MQTT topics**:
   ```yaml
   # In zigbee2mqtt configuration.yaml
   mqtt:
     base_topic: zigbee2mqtt_docker  # Different from add-on
   ```

## Troubleshooting

### Devices Not Appearing
1. Check Zigbee2MQTT logs: `docker-compose logs zigbee2mqtt`
2. For network coordinators, verify connectivity: `ping zigbee.lan`
3. Power cycle your 2 router devices (smart plugs) to help rebuild mesh
4. Check that all 21 devices are listed in the web UI

### Network Coordinator Issues
Since you use `tcp://zigbee.lan:6638`:
```bash
# Test connectivity
nc -zv zigbee.lan 6638

# If using mDNS, might need to use IP instead
# Find IP: ping zigbee.lan
# Then update configuration.yaml with IP
```

### MQTT Connection Failed
1. Check credentials match between services
2. Verify network connectivity: `docker exec zigbee2mqtt ping mosquitto`
3. Check Mosquitto logs: `docker-compose logs mosquitto`

### Coordinator Backup Fails
- Stop the service, copy `coordinator_backup.json` manually
- Ensure the backup is recent (check timestamp)

## Rollback Plan

If migration fails:

1. **Stop Docker containers**:
   ```bash
   docker-compose down
   ```

2. **Re-enable Home Assistant add-ons**:
   - Start Mosquitto add-on
   - Start Zigbee2MQTT add-on

3. **Restore configuration** if needed:
   - Upload backup through Zigbee2MQTT web UI
   - Or restore from Home Assistant backup

## Your Specific Device Inventory

For reference, your 21 devices include:
- **Door/Window Sensors** (17): Family Room doors, Master Bedroom, Office, etc.
- **Smart Plugs** (3): Master Bedroom Floor Heater, Fish Tank Light, Office Under Desk Heater
- **Water Sensor** (1): Hot Water Heater

All devices should automatically reconnect if network parameters are preserved correctly.

## Benefits of Docker Deployment

- **Version control**: Pin specific versions
- **Portability**: Easy to move between systems
- **Flexibility**: More configuration options
- **Independence**: Not tied to Home Assistant updates
- **Resource control**: Set memory/CPU limits

## Next Steps

After successful migration:
1. Remove/uninstall Home Assistant add-ons
2. Set up automated backups for Docker volumes
3. Update `.env` with `ZIGBEE_SERIAL_PORT=tcp://zigbee.lan:6638`
4. Consider documenting your network coordinator setup