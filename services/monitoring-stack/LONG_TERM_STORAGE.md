# Long-Term Storage Configuration Guide

## Storage Requirements Over Time

With your monitoring setup collecting data from Docker, system metrics, UPS, and Home Assistant:

### Estimated Storage Growth

| Time Period | Raw Data Size | With Downsampling | Notes |
|------------|---------------|-------------------|-------|
| 1 Month | 1.5-2.5 GB | N/A | Full resolution |
| 6 Months | 9-15 GB | 8-12 GB | 5-min averages after 30 days |
| 1 Year | 18-30 GB | 15-25 GB | Hourly averages after 6 months |
| 5 Years | 90-150 GB | 75-125 GB | Daily averages after 1 year |
| 10 Years | 180-300 GB | 150-250 GB | With full downsampling |

**With 1TB available, you can easily store 15-20+ years of monitoring data!**

## Optimizing for Long-Term Storage

### 1. Data Retention Strategy

```
Full Resolution (10s): 0-30 days
5-min Averages: 30 days - 6 months  
1-hour Averages: 6 months - 1 year
Daily Averages: 1+ years
```

### 2. Configure Downsampling in InfluxDB

After initial setup, create downsampling tasks:

```bash
# Access InfluxDB CLI
docker exec -it influxdb influx

# Create downsampled buckets
influx bucket create -n metrics_5m -r 180d
influx bucket create -n metrics_1h -r 365d
influx bucket create -n metrics_1d -r 1825d

# Apply downsampling tasks from file
influx apply -f /etc/influxdb2/downsampling.flux
```

### 3. Optimize Data Collection

For multi-year storage, adjust collection intervals in `telegraf.conf`:

```toml
# System metrics - less frequent for long-term storage
[[inputs.cpu]]
  interval = "30s"  # Instead of 10s

[[inputs.disk]]
  interval = "60s"  # Disk metrics change slowly

# UPS metrics - already optimized at 30s
[[inputs.exec]]
  interval = "30s"

# High-frequency data only for important metrics
[[inputs.docker]]
  interval = "10s"  # Keep detailed for active monitoring
```

### 4. Selective Home Assistant Data

Update HA config to be more selective for long-term storage:

```yaml
influxdb:
  # ... existing config ...
  include:
    entities:
      # Only include specific long-term valuable data
      - sensor.total_energy_consumption
      - sensor.solar_production
      - sensor.grid_import
      - sensor.grid_export
  measurement_overrides:
    sensor.instant_power_*: 
      override_measurement: power_instant
      # Don't store instant power long-term
  tags_attributes:
    - device_class
    - state_class  # For energy dashboard
```

### 5. Storage Management

Create these directories on your 1TB SSD:

```bash
# As root
mkdir -p /mnt/monitoring/{influxdb,grafana,backups}
chown -R 1000:1000 /mnt/monitoring/influxdb
chown -R 472:472 /mnt/monitoring/grafana

# Set up automated cleanup
cat > /etc/cron.weekly/monitoring-cleanup << 'EOF'
#!/bin/bash
# Remove old high-frequency data that's been downsampled
docker exec influxdb influx delete \
  --bucket metrics \
  --start 1970-01-01T00:00:00Z \
  --stop $(date -d '31 days ago' -Iseconds) \
  --predicate '_measurement="docker_container_cpu"'
EOF
chmod +x /etc/cron.weekly/monitoring-cleanup
```

### 6. Backup Strategy for Long-Term Data

```bash
# Weekly incremental backups
0 2 * * 0 docker exec influxdb influx backup -t $TOKEN /backups/weekly/$(date +%Y%W)

# Monthly full backups (keep 12 months)
0 3 1 * * docker exec influxdb influx backup -t $TOKEN /backups/monthly/$(date +%Y%m)

# Yearly archives (compress old data)
0 4 1 1 * tar -czf /backups/yearly/monitoring-$(date +%Y).tar.gz /backups/monthly/
```

## Query Optimization for Historical Data

When querying multi-year data in Grafana:

### Use Appropriate Aggregations

```flux
// For 5+ year trends
from(bucket: "metrics_1d")
  |> range(start: -5y)
  |> filter(fn: (r) => r._measurement == "energy_consumption")
  |> aggregateWindow(every: 1mo, fn: sum)
```

### Create Materialized Views

```flux
// Monthly energy summary
task_monthly_energy = from(bucket: "metrics")
  |> range(start: -1mo)
  |> filter(fn: (r) => r._measurement == "kWh")
  |> aggregateWindow(every: 1mo, fn: sum)
  |> to(bucket: "metrics_monthly")
```

## Grafana Dashboard Best Practices

1. **Use variable time ranges** - Don't query 5 years of data for real-time dashboards
2. **Create separate dashboards** for:
   - Real-time monitoring (last 24h)
   - Weekly/Monthly trends
   - Yearly summaries
   - Historical analysis
3. **Cache long-term queries** - Enable query caching in Grafana
4. **Use dashboard links** - Link from summary to detailed views

## Space-Saving Tips

1. **Exclude chatty metrics**:
   ```toml
   # In telegraf.conf
   fielddrop = ["container_id", "engine_host", "server_version"]
   ```

2. **Compress old backups**:
   ```bash
   find /mnt/monitoring/backups -name "*.tar" -mtime +30 -exec gzip {} \;
   ```

3. **Monitor storage usage**:
   ```flux
   // Add to Grafana
   import "system"
   system.df()
     |> filter(fn: (r) => r.path == "/mnt/monitoring")
   ```

With this configuration, your 1TB SSD will easily handle 10+ years of comprehensive monitoring data!