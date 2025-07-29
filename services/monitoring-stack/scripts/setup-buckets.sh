#!/bin/bash
# Setup InfluxDB buckets with no retention policy (keep data forever)

set -e

# Load environment variables
if [ -f ../.env ]; then
    source ../.env
else
    echo "Error: .env file not found. Run setup.sh first."
    exit 1
fi

echo "Setting up InfluxDB buckets..."

# Wait for InfluxDB to be ready
until curl -s http://localhost:8086/ping > /dev/null; do
    echo "Waiting for InfluxDB to be ready..."
    sleep 5
done

# Create buckets with no retention (0 = infinite)
echo "Creating buckets with infinite retention..."

# Infrastructure bucket (default, created during init)
influx bucket update \
    -n "${INFLUXDB_BUCKET}" \
    -o "${INFLUXDB_ORG}" \
    -r 0 \
    -t "${INFLUXDB_ADMIN_TOKEN}" \
    --host http://localhost:8086 || echo "Infrastructure bucket already configured"

# Home Assistant bucket
influx bucket create \
    -n homeassistant \
    -o "${INFLUXDB_ORG}" \
    -r 0 \
    -d "Home Assistant sensor data" \
    -t "${INFLUXDB_ADMIN_TOKEN}" \
    --host http://localhost:8086 || echo "Home Assistant bucket already exists"

# UPS bucket
influx bucket create \
    -n ups \
    -o "${INFLUXDB_ORG}" \
    -r 0 \
    -d "UPS power and battery metrics" \
    -t "${INFLUXDB_ADMIN_TOKEN}" \
    --host http://localhost:8086 || echo "UPS bucket already exists"

# MQTT bucket for future use
influx bucket create \
    -n mqtt \
    -o "${INFLUXDB_ORG}" \
    -r 0 \
    -d "MQTT sensor data" \
    -t "${INFLUXDB_ADMIN_TOKEN}" \
    --host http://localhost:8086 || echo "MQTT bucket already exists"

echo ""
echo "✅ Buckets created successfully:"
echo "  - ${INFLUXDB_BUCKET} (infrastructure metrics)"
echo "  - homeassistant (Home Assistant data)"
echo "  - ups (UPS power metrics)"
echo "  - mqtt (future MQTT data)"
echo ""
echo "All buckets configured with infinite retention (no data expiration)"