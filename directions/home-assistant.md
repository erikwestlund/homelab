# Home Assistant Setup

## VM Creation

Home Assistant is installed using the official Home Assistant OS image, not as a Docker container.

1. Download Home Assistant OS image for Proxmox
2. Create VM in Proxmox using the image
3. Name: `home-assistant`
4. 2 CPU cores, 4GB RAM, 32GB disk
5. Network: Static IP or DHCP reservation

## Access Home Assistant

Since Home Assistant OS is used, SSH access is limited. Use the web interface instead.

## Initial Setup

1. Open http://192.168.1.6:8123
2. Create account
3. Name your home
4. Set location
5. Choose unit system

## Install HACS (Home Assistant Community Store)

1. Open Terminal in Home Assistant (Settings → Add-ons → Terminal & SSH)
2. Run: `wget -O - https://get.hacs.xyz | bash -`
3. Restart Home Assistant
4. Go to Settings → Integrations
5. Add Integration → HACS
6. Follow GitHub authorization

## Add Integrations

### Zigbee2MQTT
1. Settings → Integrations → Add
2. Search "MQTT"
3. Broker: `192.168.1.103`
4. Port: 1883
5. Username/Password from secrets

### Pi-hole
1. HACS → Integrations → Search "Pi-hole"
2. Install
3. Settings → Integrations → Add → Pi-hole
4. Host: `192.168.1.101`
5. API Key from Pi-hole settings

### Plex
1. Settings → Integrations → Add
2. Search "Plex"
3. Follow Plex auth flow

## Create Automations

### Example: Turn on lights at sunset
1. Settings → Automations
2. Create Automation
3. Trigger: Sun → Sunset
4. Action: Light → Turn on

## Set Up Backups

### Google Drive Backup

1. Settings → Add-ons → Add-on Store
2. Search for "Google Drive Backup"
3. Install and configure with Google account

### Manual Backups

1. Settings → System → Backups
2. Create backup
3. Download locally or configure automatic backups

## Generate Long-Lived Access Token

1. Profile → Security
2. Long-Lived Access Tokens → Create Token
3. Name: `ansible`
4. Copy token

Add to secrets:
```bash
vim ~/code/homelab/ansible/secrets.yaml
```

Add:
```yaml
home_assistant_api_token: "your-token"
```

```bash
put-secrets
```

## SSL Access

With Nginx Proxy Manager configured, access Home Assistant at:
- https://ha.pequod.sh (from outside network)
- http://192.168.1.6:8123 (local network)

## Monitor

Since Home Assistant OS is used (not Docker), monitoring is done through the web interface:

1. Settings → System → Logs
2. Settings → System → Hardware
3. Developer Tools → Check Configuration

For SSH access (if enabled):
```bash
ssh root@192.168.1.6
ha core logs
ha core check
ha info
```