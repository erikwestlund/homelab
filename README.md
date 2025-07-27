# Homelab Infrastructure

This repository contains infrastructure-as-code for managing two Proxmox servers:
- **Nexus**: Critical infrastructure (Home Assistant, Pi-hole, Tailscale, Zigbee2MQTT)
- **Hatchery**: Resource-intensive services (Plex, Windows VMs)

## Getting Started on Fresh Debian 12 Servers

### Option 1: Manual Bootstrap (for servers without git)
If your Debian 12 server doesn't have git installed, copy the bootstrap script manually:

```bash
# Copy the contents of scripts/debian12/bootstrap.sh and paste into a file on your server
nano bootstrap.sh
chmod +x bootstrap.sh
./bootstrap.sh
```

### Option 2: Direct curl (if you have curl)
```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/homelab/main/scripts/debian12/bootstrap.sh | bash
```

### Option 3: Standard git clone (if git is installed)
```bash
git clone https://github.com/YOUR_USERNAME/homelab.git
cd homelab
```

## Repository Structure

```
homelab/
├── nexus/              # Critical infrastructure services
│   ├── zigbee-mqtt/    # Mosquitto + Zigbee2MQTT setup
│   ├── home-assistant/ # Home Assistant configuration
│   ├── pihole/         # Pi-hole DNS configuration
│   └── tailscale/      # Tailscale exit node setup
├── hatchery/           # Resource-intensive services
│   ├── plex/           # Plex media server
│   └── windows-vms/    # Windows VM configurations
├── deployments/        # Production-ready configurations
├── scripts/            # Utility scripts
│   └── debian12/       # Debian 12 specific scripts
└── backups/            # Backup storage (gitignored)
```

## Zigbee-MQTT Setup Example

For detailed setup of specific services, see their respective directories. For example:

```bash
# Setup Zigbee-MQTT on Nexus
cd nexus/zigbee-mqtt
./setup.sh                          # Install to default /opt/docker
./setup.sh --install-dir ~/homelab  # Install to custom directory
```

## Services

### Mosquitto MQTT Broker
- **Port**: 1883 (MQTT), 9001 (WebSocket)
- **Web UI**: None (command-line only)
- **Default credentials**: Set during setup

### Zigbee2MQTT
- **Port**: 8080 (Web UI)
- **Web UI**: http://localhost:8080
- **MQTT Integration**: Automatically configured

## Configuration

### Environment Variables (.env)

The setup script will create a `.env` file from the template. Key variables:

- `TZ`: Your timezone (e.g., 'America/New_York')
- `ZIGBEE_SERIAL_PORT`: Path to your Zigbee adapter
  - USB: `/dev/ttyUSB0` or `/dev/ttyACM0`
  - Network: `tcp://zigbee.lan:6638`
- `MQTT_USER`: MQTT username (generated during setup)
- `MQTT_PASS`: MQTT password (generated during setup)

### Mosquitto Configuration

The setup script generates:
- `docker/mosquitto/config/mosquitto.conf` - Main configuration
- `docker/mosquitto/config/passwd` - User credentials (hashed)

### Zigbee2MQTT Configuration

The setup script generates:
- `docker/zigbee2mqtt/data/configuration.yaml` - Main configuration with MQTT credentials

## Security

This setup includes:
- MQTT authentication (no anonymous access)
- Randomly generated passwords during setup
- All secrets stored locally (not in git)

## Troubleshooting

### Zigbee adapter not found
1. Check adapter connection: `ls -la /dev/tty*`
2. Ensure Docker has device access
3. Check permissions: `sudo chmod 666 /dev/ttyUSB0`

### Cannot connect to MQTT
1. Check Mosquitto logs: `docker-compose logs mosquitto`
2. Verify credentials in `.env` match those in Zigbee2MQTT config
3. Ensure services are on same network

### Zigbee2MQTT won't start
1. Check logs: `docker-compose logs zigbee2mqtt`
2. Verify serial port configuration
3. Ensure Mosquitto is running first

## Backup

Important files to backup:
- `docker/.env`
- `docker/mosquitto/config/passwd`
- `docker/mosquitto/data/`
- `docker/zigbee2mqtt/data/`

## Updates

To update services:
```bash
cd docker
docker-compose pull
docker-compose up -d
```

## Additional Resources

- [Mosquitto Documentation](https://mosquitto.org/documentation/)
- [Zigbee2MQTT Documentation](https://www.zigbee2mqtt.io/)
- [Supported Devices](https://www.zigbee2mqtt.io/supported-devices/)