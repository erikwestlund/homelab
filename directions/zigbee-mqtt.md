# Zigbee2MQTT Setup

This service was set up manually. Proxmox provides automatic backups. The Ansible playbook below will get you into a workable state if you need to recreate it.

## Create VM in Proxmox

1. Create new VM
2. Name: `zigbee-mqtt`
3. Debian 12 template
4. 1 CPU core, 2GB RAM, 16GB disk
5. Network: Static IP or DHCP reservation
6. Hardware: Add USB Device (Zigbee coordinator)

## Test SSH Connection

```bash
ssh -i ~/.ssh/scv root@zigbee-mqtt.lan
```

## Find Zigbee Device

```bash
ssh root@zigbee-mqtt.lan "ls -la /dev/serial/by-id/"
```

Note the device path and add to `ansible/host_vars/zigbee-mqtt.yml`

## Deploy Everything

```bash
cd ~/code/homelab/ansible
ansible-playbook playbooks/zigbee-mqtt.yml
```

## Verify Deployment

```bash
ansible zigbee-mqtt -a "docker ps"
```

Should see:
- mosquitto
- zigbee2mqtt

## Access Zigbee2MQTT

1. Open http://zigbee-mqtt.lan:8080
2. Default login uses generated credentials

## Get MQTT Credentials

```bash
ansible zigbee-mqtt -a "cat /opt/docker/.env"
```

Note MQTT_USER and MQTT_PASS for Home Assistant integration.

## Pair Devices

1. In Zigbee2MQTT web UI
2. Click "Permit join (All)"
3. Put device in pairing mode
4. Device should appear in list

## Configure Devices

### Rename Device
1. Click device
2. Settings → Friendly name
3. Enter descriptive name

### Set Device Options
1. Click device
2. Settings tab
3. Configure options (e.g., LED behavior)

## Home Assistant Integration

In Home Assistant:
1. Settings → Integrations → Add
2. MQTT
3. Broker: `zigbee-mqtt.lan`
4. Port: 1883
5. Username/Password from above

## Common Device Types

### Smart Plugs
```yaml
# In device settings
power_on_behavior: on
state_action: true
```

### Motion Sensors
```yaml
# In device settings
occupancy_timeout: 90
sensitivity: high
```

### Temperature Sensors
```yaml
# In device settings
temperature_calibration: 0
humidity_calibration: 0
```

## Set Up Groups

1. Groups → Create group
2. Name: "Living Room Lights"
3. Select devices
4. Save

## Set Up Scenes

1. Dashboard → Scene
2. Create scene
3. Set device states
4. Save

## Backup Configuration

```bash
ansible zigbee-mqtt -m cron -a "name='backup zigbee2mqtt' special_time=daily job='cd /opt/docker && tar czf /backups/zigbee2mqtt-$(date +\%Y\%m\%d).tar.gz zigbee2mqtt/data'"
```

## Update Firmware

1. Click device
2. OTA tab
3. Check for updates
4. Update if available

## Monitor

```bash
# Check logs
ansible zigbee-mqtt -a "docker logs --tail 50 zigbee2mqtt"

# Check MQTT
ansible zigbee-mqtt -a "docker exec mosquitto mosquitto_sub -h localhost -t zigbee2mqtt/# -v -C 5"

# Device status
ansible zigbee-mqtt -a "curl -s http://localhost:8080/api/devices | jq '.[] | {friendly_name, available}'"
```

## Troubleshooting

### Device Not Responding
```bash
# Restart service
ansible zigbee-mqtt -a "docker restart zigbee2mqtt"
```

### Coordinator Issues
```bash
# Check USB device
ansible zigbee-mqtt -a "ls -la /dev/serial/by-id/"

# Check permissions
ansible zigbee-mqtt -a "ls -la /dev/ttyUSB*"
```