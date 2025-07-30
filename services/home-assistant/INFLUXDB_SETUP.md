# Home Assistant InfluxDB Integration

This guide explains how to configure Home Assistant to send sensor data to InfluxDB 2.x.

## Prerequisites

- Home Assistant running and accessible
- InfluxDB 2.x running on docker-services-host.lan:8087
- InfluxDB token and organization configured

## Configuration

### 1. Add InfluxDB Configuration to Home Assistant

Add the contents of `influxdb-config.yaml` to your Home Assistant `configuration.yaml`:

```yaml
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
  # Exclude all domains by default
  exclude:
    domains:
      - automation
      - binary_sensor
      # ... (see full list in influxdb-config.yaml)
```

### 2. Restart Home Assistant

After adding the configuration, restart Home Assistant:
- Through UI: Settings → System → Restart
- Or via CLI: `ha core restart`

### 3. Verify Data Flow

Check if data is flowing to InfluxDB:

```bash
# Query the bucket for temperature data
curl -X POST "http://docker-services-host.lan:8087/api/v2/query?org=homelab" \
  -H "Authorization: Token ***REMOVED***" \
  -H "Content-Type: application/vnd.flux" \
  -d 'from(bucket: "home_assistant")
  |> range(start: -1h)
  |> filter(fn: (r) => r["entity_id"] == "sensor.current_nws_outdoor_temperature")
  |> limit(n: 10)'
```

## Adding More Sensors

To add more sensors to track, simply add them to the `include.entities` list:

```yaml
include:
  entities:
    - sensor.current_nws_outdoor_temperature
    - sensor.living_room_temperature
    - sensor.humidity
    - sensor.energy_consumption
```

## Creating Grafana Dashboard

To visualize the temperature data in Grafana:

1. Go to Grafana (http://grafana.pequod.sh)
2. Create a new dashboard
3. Add a panel with this Flux query:

```flux
from(bucket: "home_assistant")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r["entity_id"] == "sensor.current_nws_outdoor_temperature")
  |> filter(fn: (r) => r["_field"] == "value")
  |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)
```

## Troubleshooting

### No Data Showing Up
1. Check Home Assistant logs for InfluxDB errors
2. Verify the sensor exists and has data in Home Assistant
3. Ensure InfluxDB is accessible from Home Assistant
4. Check the token has write permissions

### Connection Errors
1. Verify the host and port are correct
2. Check network connectivity between Home Assistant and InfluxDB
3. Ensure InfluxDB is running: `docker ps | grep influxdb`

## Performance Considerations

- Only include sensors you actually want to track
- The current configuration excludes all domains by default
- Add sensors explicitly to the include list
- Consider the data retention needs for each sensor type