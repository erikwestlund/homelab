# Homelab Docker Stack

This repository contains Docker Compose configurations for a homelab setup including Mosquitto (MQTT broker) and Zigbee2MQTT.

## Prerequisites

- Docker and Docker Compose installed
- Zigbee coordinator (USB stick or network-based)
- Basic understanding of MQTT and Zigbee protocols

## Quick Start

1. Clone this repository:
   ```bash
   git clone <repository-url>
   cd homelab
   ```

2. Run the setup script to generate configuration files:
   ```bash
   # Default installation to /opt/docker
   ./setup.sh
   
   # Or specify a custom directory
   ./setup.sh --install-dir ~/homelab-docker
   ```

3. Edit the generated `.env` file with your specific settings:
   ```bash
   # Navigate to your installation directory
   cd /opt/docker  # or your custom directory
   nano .env
   ```

4. Start the services:
   ```bash
   # From your installation directory
   docker-compose up -d
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