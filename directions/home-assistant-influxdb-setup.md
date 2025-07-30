# Setting Up Home Assistant with InfluxDB

This guide walks through configuring Home Assistant to send sensor data to InfluxDB for long-term storage and visualization in Grafana.

## Prerequisites

- Home Assistant running and accessible
- InfluxDB 2.x running on `docker-services-host.lan:8087`
- Grafana running on `docker-services-host.lan:3001`

## Step 1: Add InfluxDB Configuration to Home Assistant

### 1.1 Access Your Home Assistant Configuration

The configuration needs to be added to your Home Assistant's `configuration.yaml` file.

**Option A: Through Home Assistant UI (Recommended)**
1. In Home Assistant, go to **Settings** → **Add-ons**
2. Install "File editor" add-on if not already installed
3. Start the File editor and click "Open Web UI"
4. Open `configuration.yaml`

**Option B: Through SSH**
```bash
# SSH into your Home Assistant instance
ssh user@your-ha-instance
nano /config/configuration.yaml
```

### 1.2 Add InfluxDB Configuration

Add this configuration to the end of your `configuration.yaml`:

```yaml
# InfluxDB 2.x Configuration
influxdb:
  api_version: 2
  ssl: false
  host: docker-services-host.lan
  port: 8087
  token: "***REMOVED***"
  organization: "homelab"
  bucket: "home_assistant"
  tags:
    source: home_assistant
  tags_attributes:
    - friendly_name
  default_measurement: state
  # Only include specific entities
  include:
    entities:
      - sensor.current_nws_outdoor_temperature
  # Exclude all domains by default since we're being selective
  exclude:
    domains:
      - automation
      - binary_sensor
      - button
      - camera
      - climate
      - cover
      - device_tracker
      - fan
      - group
      - humidifier
      - input_boolean
      - input_button
      - input_datetime
      - input_number
      - input_select
      - input_text
      - light
      - lock
      - media_player
      - number
      - person
      - remote
      - scene
      - script
      - select
      - siren
      - sun
      - switch
      - timer
      - update
      - vacuum
      - water_heater
      - weather
      - zone
```

### 1.3 Validate Configuration

Before restarting, validate your configuration:

**Through UI:**
1. Go to **Developer Tools** → **YAML**
2. Click "CHECK CONFIGURATION"
3. Ensure it says "Configuration valid!"

**Through CLI:**
```bash
ha core check
```

### 1.4 Restart Home Assistant

**Through UI:**
1. Go to **Developer Tools** → **YAML**
2. Click "RESTART" → "Restart Home Assistant"

**Through CLI:**
```bash
ha core restart
```

## Step 2: Verify Data Flow

### 2.1 Check Home Assistant Logs

After restart, check for any InfluxDB errors:

**Through UI:** Settings → System → Logs

**Through CLI:**
```bash
ha logs | grep -i influx
```

### 2.2 Test Data Flow

Run this test script on docker-services-host:

```bash
/tmp/test-ha-temperature.sh
```

### 2.3 Debug Connection

If data isn't flowing, run the debug script:

```bash
/tmp/debug-ha-influxdb.sh
```

## Step 3: Add More Sensors

To track additional sensors, add them to the `include.entities` list:

```yaml
include:
  entities:
    - sensor.current_nws_outdoor_temperature
    - sensor.living_room_temperature
    - sensor.bedroom_humidity
    - sensor.total_energy_consumption
```

## Step 4: View Data in Grafana

1. Access Grafana at http://grafana.pequod.sh
2. Go to the "HVAC Monitoring" dashboard
3. Temperature data should appear within a few minutes

### Create Custom Queries

Example Flux query for temperature data:

```flux
from(bucket: "home_assistant")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r["entity_id"] == "sensor.current_nws_outdoor_temperature")
  |> filter(fn: (r) => r["_field"] == "value")
  |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)
```

## Troubleshooting

### No Data Showing Up

1. **Verify sensor name**: In HA, go to Developer Tools → States and search for your sensor
2. **Check network**: Ensure HA can reach `docker-services-host.lan:8087`
3. **Verify token**: Make sure the InfluxDB token matches exactly
4. **Check bucket**: Confirm `home_assistant` bucket exists in InfluxDB

### Connection Errors

1. Check InfluxDB is running: `docker ps | grep influxdb`
2. Test connectivity: `curl http://docker-services-host.lan:8087/health`
3. Check firewall rules between HA and InfluxDB

### Common Issues

- **Wrong sensor name**: Entity IDs must match exactly
- **YAML formatting**: Use spaces, not tabs. Indentation matters!
- **Network issues**: Ensure DNS resolution for docker-services-host.lan
- **Port conflicts**: Verify InfluxDB is on port 8087

## Performance Tips

1. Only include sensors you need for long-term storage
2. Use the exclude domains list to prevent unwanted data
3. Consider data retention needs per sensor type
4. Monitor InfluxDB disk usage at `/mnt/storage/influxdb`

## Next Steps

- Add indoor temperature sensors
- Set up energy monitoring
- Create automation based on temperature trends
- Build comprehensive HVAC dashboards