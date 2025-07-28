# Plex Server Setup

## Create VM in Proxmox

1. Create new VM
2. Name: `plex-server`
3. Debian 12 template
4. 4 CPU cores, 8GB RAM, 32GB disk
5. Network: Static IP or DHCP reservation

## Test SSH Connection

```bash
ssh -i ~/.ssh/scv root@plex-server.lan
```

## Get Plex Claim Token

1. Go to https://www.plex.tv/claim
2. Sign in
3. Copy claim token
4. Add to `ansible/secrets.yaml`
5. Run `put-secrets`

## Deploy Everything

```bash
cd ~/code/homelab/ansible
ansible-playbook playbooks/plex-server.yml
```

## Verify Deployment

```bash
ansible plex-server -a "docker ps"
```

## Access Plex

Open http://plex-server.lan:32400/web

### If you provided a claim token:
Libraries are automatically configured:
- Movies → `/media/Movies`
- TV Shows → `/media/TV Shows`  
- Music → `/media/Music`
- Documentaries → `/media/Documentaries`
- Courses → `/media/Courses`

### If you didn't provide a claim token:
1. Sign in and claim server
2. Run library setup:
   ```bash
   ssh root@plex-server.lan
   /opt/docker/plex/setup-libraries.sh
   ```


## Enable Hardware Transcoding

1. In Plex settings → Transcoder
2. Check "Use hardware acceleration when available"

## Set Up Automatic Updates

```bash
ansible plex-server -m cron -a "name='update plex' special_time=daily job='docker pull lscr.io/linuxserver/plex:latest && docker restart plex'"
```

## Set Up Backups

```bash
ansible plex-server -m cron -a "name='backup plex' hour=3 minute=0 job='docker exec plex tar czf - /config > /backups/plex-$(date +\%Y\%m\%d).tar.gz'"
```

## Monitor

### Automated Monitoring

The following monitoring is automatically configured:

1. **NAS Mount Monitor** (every 5 minutes):
   - Verifies `/media` mount is active
   - Checks expected directories exist
   - Auto-remounts if connection lost
   - Restarts Plex after remount
   - Logs to `/var/log/nas-mount-monitor.log`

2. **Plex Health Check** (every 10 minutes):
   - Verifies Plex is responding
   - Auto-restarts if unresponsive
   - Logs to `/var/log/plex-health.log`

### Manual Monitoring

```bash
# Run comprehensive status check
ansible plex-server -a "/opt/docker/plex/check-status.sh"

# Check mount monitor logs
ansible plex-server -a "tail -20 /var/log/nas-mount-monitor.log"

# Check health check logs
ansible plex-server -a "tail -20 /var/log/plex-health.log"

# Check Docker logs
ansible plex-server -a "docker logs --tail 50 plex"

# Check resource usage
ansible plex-server -a "docker stats plex --no-stream"

# Verify NAS mount
ansible plex-server -a "df -h /media"
ansible plex-server -a "ls -la /media"
```

### Troubleshooting Mount Issues

If media disappears:

```bash
# Check mount status
ansible plex-server -a "mount | grep /media"

# Force remount
ansible plex-server -b -a "umount /media; mount -a"

# Restart Plex
ansible plex-server -a "docker restart plex"
```

The monitoring scripts will handle this automatically, but these commands are useful for immediate intervention.