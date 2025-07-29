# Homelab Monitoring Stack

A comprehensive monitoring solution for your homelab using InfluxDB, Telegraf, and Grafana. This stack collects metrics from multiple sources including Docker containers, system resources, UPS devices (via NUT), and Home Assistant.

## Architecture

```
┌─────────────────┐     ┌──────────────┐     ┌─────────────┐
│                 │     │              │     │             │
│  Data Sources   │────▶│   InfluxDB   │────▶│   Grafana   │
│                 │     │              │     │             │
└─────────────────┘     └──────────────┘     └─────────────┘
        │                                              │
        ├─ NUT Server (UPS)                           │
        ├─ Docker Stats                               │
        ├─ System Metrics                     Web Dashboard
        ├─ Home Assistant                      (Port 3000)
        └─ Network Ping
```

## Quick Start

1. **Clone this directory to your docker host:**
   ```bash
   cd /opt/docker
   git clone <repo> monitoring-stack
   cd monitoring-stack
   ```

2. **Configure environment variables:**
   ```bash
   cp .env.example .env
   # Edit .env and set secure passwords and tokens
   nano .env
   ```

3. **Start the stack:**
   ```bash
   docker-compose up -d
   ```

4. **Access services:**
   - Grafana: http://docker-services-host.lan:3000
   - InfluxDB: http://docker-services-host.lan:8086

## Default Credentials

⚠️ **Change these immediately after first login!**

- **Grafana:**
  - Username: `admin`
  - Password: `changeme456!`

- **InfluxDB:**
  - Username: `admin`
  - Password: `changeme123!`
  - Organization: `homelab`
  - Bucket: `metrics`

## Service Ports

- `3000`: Grafana web interface
- `8086`: InfluxDB API and web interface
- `8087`: Telegraf HTTP listener (for Home Assistant webhook)

## Data Collection

### 1. UPS Metrics (via NUT)
Telegraf automatically collects UPS metrics every 30 seconds:
- Battery charge percentage
- Runtime remaining
- Input/Output voltage
- Load percentage
- Temperature

### 2. Docker Container Metrics
- CPU usage per container
- Memory usage
- Network I/O
- Disk I/O
- Container status

### 3. System Metrics
- CPU usage (per core and total)
- Memory and swap usage
- Disk usage and I/O
- Network interface statistics
- System load and uptime
- Process counts

### 4. Home Assistant Integration
Configure Home Assistant to send metrics by adding the provided configuration to your `configuration.yaml`.

## Home Assistant Setup

1. Copy the configuration from `home-assistant-config.yaml` to your HA `configuration.yaml`
2. Update the token to match your InfluxDB token
3. Restart Home Assistant
4. Verify data is flowing: Check InfluxDB Data Explorer

## Grafana Dashboards

### Pre-built Dashboards

Import these dashboard IDs from Grafana.com:

1. **Docker and System Monitoring**: `15141`
   - Comprehensive Docker container metrics
   - System resource utilization

2. **UPS Monitoring**: `11207`
   - Battery status and runtime
   - Power load and efficiency
   - Voltage and frequency

3. **Home Energy Monitoring**: `16449`
   - Energy consumption trends
   - Cost calculations
   - Device-level monitoring

### Importing Dashboards

1. Navigate to Grafana (http://docker-services-host.lan:3000)
2. Go to Dashboards → Import
3. Enter the dashboard ID
4. Select "InfluxDB" as the data source
5. Click Import

### Creating Custom Dashboards

Example Flux queries for Grafana:

**UPS Battery Status:**
```flux
from(bucket: "metrics")
  |> range(start: -1h)
  |> filter(fn: (r) => r._measurement == "nut_ups")
  |> filter(fn: (r) => r._field == "battery_charge")
  |> aggregateWindow(every: 1m, fn: mean)
```

**Docker Container CPU:**
```flux
from(bucket: "metrics")
  |> range(start: -1h)
  |> filter(fn: (r) => r._measurement == "docker_container_cpu")
  |> filter(fn: (r) => r._field == "usage_percent")
  |> group(columns: ["container_name"])
```

**Home Assistant Energy:**
```flux
from(bucket: "metrics")
  |> range(start: -24h)
  |> filter(fn: (r) => r.domain == "sensor")
  |> filter(fn: (r) => r._field =~ /.*energy.*/)
  |> aggregateWindow(every: 1h, fn: sum)
```

## Maintenance

### Backup

Backup these directories regularly:
```bash
# Backup script
#!/bin/bash
BACKUP_DIR="/path/to/backups/monitoring-$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"

# Stop containers
docker-compose stop

# Backup volumes
docker run --rm -v monitoring-stack_influxdb_data:/data -v "$BACKUP_DIR":/backup alpine tar czf /backup/influxdb_data.tar.gz -C /data .
docker run --rm -v monitoring-stack_grafana_data:/data -v "$BACKUP_DIR":/backup alpine tar czf /backup/grafana_data.tar.gz -C /data .

# Start containers
docker-compose start
```

### Update Services

```bash
# Update all services
docker-compose pull
docker-compose up -d

# Update specific service
docker-compose pull grafana
docker-compose up -d grafana
```

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f telegraf
```

## Troubleshooting

### InfluxDB Connection Issues
```bash
# Test InfluxDB health
curl http://localhost:8086/health

# Check InfluxDB logs
docker-compose logs influxdb
```

### Telegraf Not Collecting Data
```bash
# Check Telegraf configuration
docker-compose exec telegraf telegraf --test

# View Telegraf logs
docker-compose logs telegraf
```

### NUT Metrics Missing
```bash
# Test NUT connection from Telegraf container
docker-compose exec telegraf upsc -l

# Test the NUT script
docker-compose exec telegraf python3 /etc/telegraf/scripts/nut_influx.py
```

### Home Assistant Data Not Appearing
1. Check HA logs for InfluxDB errors
2. Verify the token matches between HA and InfluxDB
3. Test connection: `curl -i http://docker-services-host.lan:8086/api/v2/ping`

## Performance Tuning

### InfluxDB Retention Policy
Default retention is 5 years (1825 days). To change:
```bash
# Access InfluxDB CLI
docker-compose exec influxdb influx

# Update retention
influx bucket update -n metrics -r 3650d  # 10 years
```

### Long-Term Storage (Multi-Year)
With a dedicated 1TB SSD, you can store 15-20+ years of data! See `LONG_TERM_STORAGE.md` for:
- Optimized retention strategies
- Downsampling configuration  
- Storage calculations
- Backup strategies

Quick setup for dedicated storage:
```bash
sudo ./setup-storage.sh /mnt/your-ssd-mount
```

### Telegraf Collection Intervals
Edit `telegraf/telegraf.conf`:
- System metrics: 10s (default)
- UPS metrics: 30s (less frequent due to slow changes)
- Docker metrics: 10s

### Grafana Performance
- Enable caching in dashboard settings
- Use appropriate time ranges
- Aggregate data for longer time periods

## Security Considerations

1. **Change all default passwords immediately**
2. **Use strong, unique tokens for InfluxDB**
3. **Consider putting services behind a reverse proxy with SSL**
4. **Restrict network access to monitoring ports**
5. **Regularly update all containers**

## Adding New Data Sources

### Example: Adding Temperature Sensors
1. Edit `telegraf/telegraf.conf`
2. Add new input plugin configuration
3. Restart Telegraf: `docker-compose restart telegraf`
4. Verify data in InfluxDB Data Explorer
5. Create Grafana dashboard

## Directory Structure
```
monitoring-stack/
├── docker-compose.yml       # Main stack definition
├── .env                    # Environment variables (create from .env.example)
├── .env.example           # Example environment file
├── telegraf/
│   ├── telegraf.conf      # Telegraf configuration
│   └── scripts/
│       └── nut_influx.py  # NUT to InfluxDB converter
├── grafana/
│   └── provisioning/
│       ├── dashboards/
│       │   └── dashboard.yml
│       └── datasources/
│           └── influxdb.yml
├── home-assistant-config.yaml  # HA configuration snippet
└── README.md
```

## Support

For issues or questions:
1. Check container logs first
2. Verify network connectivity between services
3. Ensure all passwords/tokens match across services
4. Check that all required ports are available

## License

This configuration is provided as-is for personal homelab use.