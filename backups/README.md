# Backups Directory

This directory is for storing backup files and is excluded from git.

## Structure

```
backups/
├── by-date/         # Backups organized by date
│   └── 2024-01-15/
├── by-service/      # Backups organized by service
│   ├── plex/
│   ├── pihole/
│   └── zigbee2mqtt/
└── by-server/       # Backups organized by server (if needed)
    ├── server1/
    └── server2/
```

## Usage

Store any sensitive backups, configuration exports, or temporary files here. This directory will not be tracked by git.

## Backup Scripts

Example backup commands:

```bash
# Backup Plex
docker exec plex tar czf - /config > backups/by-service/plex/plex-$(date +%Y%m%d).tar.gz

# Backup Pi-hole
cd /opt/docker/pihole
tar czf ~/homelab/backups/by-service/pihole/pihole-$(date +%Y%m%d).tar.gz .

# Backup all Docker volumes
docker run --rm -v /var/lib/docker/volumes:/volumes -v $(pwd)/backups:/backup alpine tar czf /backup/volumes-$(date +%Y%m%d).tar.gz /volumes
```

## Restore

```bash
# Restore Plex
docker exec -i plex tar xzf - < backups/by-service/plex/plex-20240115.tar.gz

# Restore Pi-hole
cd /opt/docker/pihole
tar xzf ~/homelab/backups/by-service/pihole/pihole-20240115.tar.gz
```