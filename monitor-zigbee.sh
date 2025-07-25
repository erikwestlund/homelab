#!/bin/bash

# Zigbee2MQTT monitoring script
# Add to crontab: */5 * * * * /opt/docker/monitor-zigbee.sh

INSTALL_DIR="/opt/docker"
LOG_FILE="/var/log/zigbee-monitor.log"

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Check if Zigbee2MQTT is responding
check_zigbee2mqtt() {
    if ! curl -sf http://localhost:8080/api > /dev/null; then
        log_message "ERROR: Zigbee2MQTT not responding"
        return 1
    fi
    return 0
}

# Check if MQTT is responding
check_mqtt() {
    if ! docker exec mosquitto mosquitto_sub -t '$SYS/#' -C 1 -W 2 > /dev/null 2>&1; then
        log_message "ERROR: MQTT not responding"
        return 1
    fi
    return 0
}

# Main monitoring logic
cd "$INSTALL_DIR"

# Check Zigbee2MQTT
if ! check_zigbee2mqtt; then
    log_message "Restarting Zigbee2MQTT..."
    docker compose restart zigbee2mqtt
    sleep 30
    if check_zigbee2mqtt; then
        log_message "Zigbee2MQTT restarted successfully"
    else
        log_message "CRITICAL: Zigbee2MQTT restart failed"
    fi
fi

# Check MQTT
if ! check_mqtt; then
    log_message "Restarting Mosquitto..."
    docker compose restart mosquitto
    sleep 10
    docker compose restart zigbee2mqtt  # Restart Z2M after MQTT
    sleep 30
    if check_mqtt && check_zigbee2mqtt; then
        log_message "Services restarted successfully"
    else
        log_message "CRITICAL: Service restart failed"
    fi
fi