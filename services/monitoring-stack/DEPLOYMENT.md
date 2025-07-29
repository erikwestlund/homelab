# Monitoring Stack Deployment Guide

## Prerequisites

- Docker and Docker Compose installed on docker-services-host.lan (192.168.1.103)
- ZFS volumes mounted at:
  - `/mnt/storage/influxdb` - InfluxDB data storage
  - `/mnt/storage/grafana` - Grafana data storage
- Access to Nginx Proxy Manager for domain configuration

## Quick Deployment

### 1. Initial Setup

```bash
# SSH to docker-services-host
ssh ansible@docker-services-host.lan

# Clone or copy the monitoring stack
cd /opt/docker
git clone <repo> monitoring-stack
cd monitoring-stack

# Run the setup script
./setup.sh
```

### 2. Start the Stack

```bash
# Start all services
docker compose up -d

# Check status
docker compose ps

# View logs
docker compose logs -f
```

### 3. Create InfluxDB Buckets

```bash
# Wait for InfluxDB to be fully started (about 30 seconds)
sleep 30

# Run bucket setup
cd scripts
./setup-buckets.sh
cd ..
```

### 4. Configure Nginx Proxy Manager

Add these services to NPM (already in the configuration):

1. **Grafana**:
   - Domain: `grafana.pequod.sh`
   - Forward to: `grafana` (container name)
   - Port: `3000`
   - Scheme: `http`

2. **InfluxDB** (optional, for admin access):
   - Domain: `influxdb.pequod.sh`
   - Forward to: `influxdb`
   - Port: `8086`
   - Scheme: `http`

### 5. Access Services

- Grafana: https://grafana.pequod.sh
- InfluxDB: https://influxdb.pequod.sh (or http://docker-services-host.lan:8086)

Login with credentials from `.env` file.

## Home Assistant Integration

1. Copy the token from `.env`:
   ```bash
   grep INFLUXDB_ADMIN_TOKEN .env
   ```

2. On your Home Assistant:
   - Add configuration from `home-assistant-config.yaml`
   - Update the token value
   - Restart Home Assistant

3. Verify data flow:
   - Check InfluxDB Data Explorer
   - Look for measurements from `homeassistant` bucket

## Import Grafana Dashboards

### Recommended Dashboards

1. **System Overview** (ID: 15141)
   - Docker container metrics
   - System resources
   - Network statistics

2. **UPS Monitoring** (ID: 12617)
   - Battery status
   - Power metrics
   - Runtime trends

3. **Home Energy** (ID: 16449)
   - Energy consumption
   - Cost analysis
   - Device tracking

### Import Process

1. Login to Grafana
2. Navigate to Dashboards → Import
3. Enter dashboard ID
4. Select data source:
   - For system/Docker: Select `InfluxDB` → `infrastructure` bucket
   - For UPS: Select `InfluxDB` → `ups` bucket
   - For Home Assistant: Select `InfluxDB` → `homeassistant` bucket
5. Click Import

## Verify Everything is Working

### Check Data Collection

```bash
# Check Telegraf is collecting metrics
docker compose exec telegraf telegraf --test

# Check InfluxDB has data
docker compose exec influxdb influx query 'from(bucket:"infrastructure") |> range(start: -5m) |> limit(n:10)'

# Check NUT metrics (if UPS connected)
docker compose exec telegraf python3 /etc/telegraf/scripts/nut_influx.py
```

### Check Service Health

```bash
# All containers should be healthy
docker compose ps

# Check Grafana API
curl -s http://localhost:3000/api/health

# Check InfluxDB API
curl -s http://localhost:8086/health
```

## Troubleshooting

### Container Won't Start

```bash
# Check logs
docker compose logs <service_name>

# Common issues:
# - Port conflicts: Check ports 3000, 8086 are free
# - Volume permissions: Ensure /mnt/storage/* directories exist and are writable
```

### No Data in Grafana

1. Check InfluxDB has data:
   ```bash
   docker compose exec influxdb influx
   > show buckets
   > from(bucket: "infrastructure") |> range(start: -1h) |> limit(n: 10)
   ```

2. Check Telegraf is running:
   ```bash
   docker compose logs telegraf | tail -50
   ```

3. Verify datasource in Grafana:
   - Settings → Data Sources → InfluxDB
   - Test connection

### UPS Metrics Missing

```bash
# Check if NUT is accessible
docker compose exec telegraf /bin/sh
$ upsc -l
$ exit

# If no UPS listed, NUT server might not be running on host
```

## Maintenance

### Regular Backups

```bash
# Stop services
docker compose stop

# Backup InfluxDB
tar -czf influxdb-backup-$(date +%Y%m%d).tar.gz /mnt/storage/influxdb

# Backup Grafana  
tar -czf grafana-backup-$(date +%Y%m%d).tar.gz /mnt/storage/grafana

# Start services
docker compose start
```

### Updates

```bash
# Update images
docker compose pull

# Recreate containers
docker compose up -d

# Check logs after update
docker compose logs -f
```

## Advanced Configuration

### Add Custom Telegraf Inputs

Edit `telegraf/telegraf.conf` and add new inputs:

```toml
# Example: Monitor specific URLs
[[inputs.http_response]]
  urls = ["https://ha.pequod.sh", "https://plex.pequod.sh"]
  response_timeout = "5s"
  method = "GET"
  follow_redirects = false
```

Then restart Telegraf:
```bash
docker compose restart telegraf
```

### Create Custom Dashboards

1. In Grafana, create new dashboard
2. Add panel with Flux query:
   ```flux
   from(bucket: "infrastructure")
     |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
     |> filter(fn: (r) => r["_measurement"] == "cpu")
     |> filter(fn: (r) => r["_field"] == "usage_idle")
     |> aggregateWindow(every: v.windowPeriod, fn: mean)
   ```

### Long-term Data Management

With infinite retention and 1TB storage, you can store approximately:
- 15-20 years of metrics at current collection rates
- Monitor storage usage: `df -h /mnt/storage/influxdb`
- Consider downsampling old data if needed (see `influxdb/downsampling.flux`)