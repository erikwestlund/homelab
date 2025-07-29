# NUT (Network UPS Tools) Setup Guide

This guide covers setting up Network UPS Tools for monitoring CyberPower UPS devices in the homelab.

## Current Setup

- **VM**: ups-monitor.lan (192.168.1.15)
- **Host**: hatchery.lan 
- **UPS Devices**:
  - `homelab` - CyberPower PR1500LCDRT2U (Serial: CXXPU7012005) - Powers servers & homelab equipment
  - `network` - CyberPower PR1500LCDRT2U (Serial: CXXNU7009695) - Powers network equipment

## Automated Deployment

### Using Ansible (Recommended)

```bash
# Deploy complete UPS monitoring stack
cd ~/code/homelab/ansible
ansible-playbook -i inventories/homelab.yml playbooks/ups-monitor.yml

# This will:
# 1. Install NUT server and client packages
# 2. Configure both UPS devices with proper serial numbers
# 3. Set up network access for remote monitoring
# 4. Deploy PeaNUT web interface
# 5. Configure monitoring users
```

### What Gets Configured

1. **NUT Server** (nut-server, nut-client packages)
   - Listens on all interfaces (0.0.0.0:3493)
   - Configures USB devices by serial number
   - Creates monitoring users

2. **PeaNUT Web Interface**
   - Web UI on port 8086
   - Auto-discovers UPS devices
   - Real-time status monitoring

## Manual Setup Steps

### 1. VM Requirements

- Debian 12 minimal install
- 2 vCPUs, 2GB RAM, 32GB disk
- USB devices passed through from host

### 2. USB Passthrough Configuration

On Proxmox host (hatchery):

```bash
# Identify UPS USB devices
lsusb | grep "Cyber Power"
# Example output:
# Bus 001 Device 002: ID 0764:0601 Cyber Power System, Inc. PR1500LCDRT2U UPS
# Bus 001 Device 003: ID 0764:0601 Cyber Power System, Inc. PR1500LCDRT2U UPS

# Pass through to VM (in Proxmox UI or CLI)
qm set VMID -usb0 host=0764:0601,usb3=1
qm set VMID -usb1 host=0764:0601,usb3=1
```

### 3. Install NUT Packages

```bash
# On ups-monitor VM
apt update
apt install -y nut nut-server nut-client
```

### 4. Configure UPS Devices

Edit `/etc/nut/ups.conf`:

```ini
[homelab]
    driver = usbhid-ups
    port = auto
    vendorid = 0764
    productid = 0601
    serial = "CXXPU7012005"
    desc = "Homelab Servers & Equipment"

[network]
    driver = usbhid-ups
    port = auto
    vendorid = 0764
    productid = 0601
    serial = "CXXNU7009695"
    desc = "Network Equipment"
```

### 5. Configure Network Access

Edit `/etc/nut/upsd.conf`:

```ini
LISTEN 0.0.0.0 3493
MAXCONN 64
```

### 6. Configure Users

Edit `/etc/nut/upsd.users`:

```ini
[admin]
    password = YOUR_SECURE_PASSWORD
    actions = SET
    instcmds = ALL

[monuser]
    password = YOUR_SECURE_PASSWORD
    upsmon master

[peanut]
    password = YOUR_SECURE_PASSWORD
    upsmon slave
```

### 7. Configure Monitoring

Edit `/etc/nut/upsmon.conf`:

```ini
MONITOR homelab@localhost 1 monuser YOUR_SECURE_PASSWORD master
MONITOR network@localhost 1 monuser YOUR_SECURE_PASSWORD master

MINSUPPLIES 1
SHUTDOWNCMD "/sbin/shutdown -h +0"
POLLFREQ 5
POLLFREQALERT 5
HOSTSYNC 15
DEADTIME 15
POWERDOWNFLAG /etc/killpower

# Notification configuration
NOTIFYMSG ONLINE    "UPS %s on line power"
NOTIFYMSG ONBATT    "UPS %s on battery"
NOTIFYMSG LOWBATT   "UPS %s battery is low"
NOTIFYMSG FSD       "UPS %s: forced shutdown in progress"
NOTIFYMSG COMMOK    "Communications with UPS %s established"
NOTIFYMSG COMMBAD   "Communications with UPS %s lost"
NOTIFYMSG SHUTDOWN  "Auto logout and shutdown proceeding"
NOTIFYMSG REPLBATT  "UPS %s battery needs to be replaced"

NOTIFYFLAG ONLINE   SYSLOG+WALL+EXEC
NOTIFYFLAG ONBATT   SYSLOG+WALL+EXEC
NOTIFYFLAG LOWBATT  SYSLOG+WALL
NOTIFYFLAG FSD      SYSLOG+WALL+EXEC
NOTIFYFLAG COMMOK   SYSLOG+WALL+EXEC
NOTIFYFLAG COMMBAD  SYSLOG+WALL+EXEC
NOTIFYFLAG SHUTDOWN SYSLOG+WALL+EXEC
NOTIFYFLAG REPLBATT SYSLOG+WALL

NOTIFYCMD /usr/sbin/upssched
RUN_AS_USER nut
```

### 8. Set NUT Mode

Edit `/etc/nut/nut.conf`:

```ini
MODE=netserver
```

### 9. Start Services

```bash
systemctl restart nut-server
systemctl restart nut-monitor
systemctl enable nut-server
systemctl enable nut-monitor
```

## Testing

### Local Testing

```bash
# List UPS devices
upsc -l

# Check UPS status
upsc homelab@localhost
upsc network@localhost

# Expected output includes:
# battery.charge: 100
# battery.runtime: 3825
# battery.voltage: 27.4
# device.model: PR1500LCDRT2U
# ups.status: OL  (On Line)
```

### Remote Testing

From another host:

```bash
# Test remote access
upsc homelab@ups-monitor.lan:3493
upsc network@ups-monitor.lan:3493
```

## PeaNUT Web Interface

### Deploy with Docker

```bash
# Already included in Ansible playbook, or manually:
docker run -d \
  --name peanut \
  --network host \
  -e NUT_HOST=localhost \
  -e NUT_PORT=3493 \
  -e NUT_USERNAME=monuser \
  -e NUT_PASSWORD=YOUR_PASSWORD \
  -e WEB_PORT=8086 \
  -v peanut_data:/app/data \
  brandawg93/peanut:latest
```

### Access PeaNUT

1. Navigate to http://ups-monitor.lan:8086
2. Add NUT server connection:
   - Host: localhost
   - Port: 3493
   - Username: monuser
   - Password: YOUR_PASSWORD
3. Add devices:
   - Device: homelab
   - Device: network

## Integration with Monitoring Stack

The monitoring stack automatically collects NUT metrics via Telegraf:

1. **Telegraf Configuration** (already configured):
   - Executes Python script every 30 seconds
   - Converts NUT data to InfluxDB format
   - Stores in metrics bucket

2. **Grafana Dashboards**:
   - Import dashboard ID 11207 for UPS monitoring
   - Shows battery status, runtime, load, voltage
   - Historical trends and alerts

## Troubleshooting

### USB Permission Issues

```bash
# Check USB devices
lsusb -v | grep -E "(Cyber|idVendor|idProduct|iSerial)"

# Fix permissions
usermod -a -G nut nut
udevadm control --reload-rules
udevadm trigger
```

### Driver Issues

```bash
# Test driver directly
/lib/nut/usbhid-ups -a homelab -DD

# Check logs
journalctl -u nut-server -f
tail -f /var/log/syslog | grep nut
```

### Connection Issues

```bash
# Check if NUT is listening
netstat -tlnp | grep 3493

# Test local connection
telnet localhost 3493

# Check firewall
ufw status
ufw allow 3493/tcp comment "NUT server"
```

## Maintenance

### Regular Tasks

- Monitor UPS battery age and runtime
- Test UPS switchover monthly
- Update NUT packages quarterly
- Review logs for communication errors

### Battery Replacement

When `ups.status` shows `RB` (Replace Battery):
1. Order replacement batteries
2. Schedule maintenance window
3. Follow UPS manual for hot-swap procedure
4. Reset battery date in UPS after replacement

## Security Notes

1. Always use strong passwords for NUT users
2. Limit network access via firewall rules
3. Use read-only users for monitoring
4. Avoid exposing NUT directly to internet
5. Regular security updates

## Additional Resources

- [NUT Documentation](https://networkupstools.org/docs/)
- [CyberPower Compatibility](https://networkupstools.org/stable-hcl.html)
- [PeaNUT GitHub](https://github.com/Brandawg93/PeaNut)