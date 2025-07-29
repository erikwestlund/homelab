#!/bin/bash

# Storage Setup Script for Long-Term Monitoring Data
set -e

echo "======================================="
echo "Monitoring Stack Storage Setup"
echo "======================================="

# Default storage path - update this to your dedicated SSD mount point
STORAGE_PATH="${1:-/mnt/monitoring}"

# Check if running as root (needed for directory creation)
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root to create storage directories"
   exit 1
fi

echo "Setting up storage at: $STORAGE_PATH"

# Create directory structure
mkdir -p "$STORAGE_PATH"/{influxdb,grafana,backups}

# Set permissions (InfluxDB runs as UID 1000, Grafana as UID 472)
chown -R 1000:1000 "$STORAGE_PATH/influxdb"
chown -R 472:472 "$STORAGE_PATH/grafana"

# Create backup script
cat > "$STORAGE_PATH/backup.sh" << 'EOF'
#!/bin/bash
# Backup script for monitoring data
BACKUP_DATE=$(date +%Y%m%d)
BACKUP_DIR="/mnt/monitoring/backups/$BACKUP_DATE"

mkdir -p "$BACKUP_DIR"

# Backup InfluxDB
docker exec influxdb influx backup -t YOUR_TOKEN_HERE "$BACKUP_DIR/influxdb"

# Backup Grafana
docker run --rm -v monitoring-stack_grafana_data:/data -v "$BACKUP_DIR":/backup alpine tar czf /backup/grafana.tar.gz -C /data .

# Keep only last 30 days of backups
find /mnt/monitoring/backups -type d -mtime +30 -exec rm -rf {} +

echo "Backup completed: $BACKUP_DIR"
EOF

chmod +x "$STORAGE_PATH/backup.sh"

# Update docker-compose.yml with correct paths
if [ -f "./docker-compose.yml" ]; then
    sed -i "s|/mnt/monitoring/influxdb|$STORAGE_PATH/influxdb|g" docker-compose.yml
    sed -i "s|/mnt/monitoring/grafana|$STORAGE_PATH/grafana|g" docker-compose.yml
fi

echo ""
echo "Storage setup complete!"
echo ""
echo "Storage locations:"
echo "  InfluxDB data: $STORAGE_PATH/influxdb"
echo "  Grafana data: $STORAGE_PATH/grafana"
echo "  Backups: $STORAGE_PATH/backups"
echo ""
echo "Estimated storage usage:"
echo "  - First year: ~20-30GB"
echo "  - Per year after: ~15-25GB (with downsampling)"
echo "  - 5 years total: ~100-150GB"
echo ""
echo "With 1TB available, you can store 15-20+ years of data!"
echo ""
echo "Next steps:"
echo "  1. Update .env file with your settings"
echo "  2. Run: docker-compose up -d"
echo "  3. Set up weekly backups: crontab -e"
echo "     0 2 * * 0 $STORAGE_PATH/backup.sh"
echo ""