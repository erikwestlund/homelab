# Plex Media Server Setup

Deploying Plex Media Server.

## Prerequisites

- Server with Docker installed
- Media files available (or planned locations)
- Plex claim token (optional but recommended)

## Step 1: Get Plex Claim Token

1. Go to https://www.plex.tv/claim
2. Sign in to your Plex account
3. Copy the claim token (valid for 4 minutes)

## Step 2: Update Secrets

Add your claim token to `ansible/secrets.yaml`:

```yaml
plex_claim_token: "claim-xxxxxxxxxxxxxxxxx"
```

Save secrets:

```bash
put-secrets
```

## Step 3: Prepare Media Directories

On the target server:

```bash
# SSH into server
ssh SERVER_NAME

# Create media directories
sudo mkdir -p /media/{movies,tv,music,photos}
sudo chown -R $USER:$USER /media
```

## Step 4: Deploy with Ansible

From your local machine:

```bash
cd ~/code/homelab/ansible

# Deploy only Plex
ansible-playbook playbooks/site.yml --tags plex

# Or deploy to all Hatchery services
ansible-playbook playbooks/hatchery.yml
```

## Step 5: Access Plex Web UI

1. Open browser to: http://192.168.1.11:32400/web
2. Sign in with your Plex account
3. Follow initial setup wizard

## Manual Docker Deployment (Alternative)

Manual deployment:

```bash
# SSH into server
ssh SERVER_NAME

# Create Plex directories
mkdir -p /opt/docker/plex/config

# Run Plex container
docker run -d \
  --name=plex \
  --net=host \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=America/New_York \
  -e VERSION=docker \
  -e PLEX_CLAIM="claim-xxxxxxxxxxxxxxxxx" \
  -v /opt/docker/plex/config:/config \
  -v /media/movies:/movies \
  -v /media/tv:/tv \
  -v /media/music:/music \
  -v /media/photos:/photos \
  --restart unless-stopped \
  lscr.io/linuxserver/plex:latest
```

## Step 6: Configure Libraries

In Plex Web UI:

1. Go to Settings → Libraries
2. Add Movie library → Browse → /movies
3. Add TV Shows library → Browse → /tv
4. Add Music library → Browse → /music
5. Add Photos library → Browse → /photos

## Hardware Transcoding Setup

### For Intel Quick Sync:

1. Check if `/dev/dri` exists:
   ```bash
   ls -la /dev/dri
   ```

2. If it exists, the Ansible playbook automatically enables it

3. In Plex: Settings → Transcoder → Enable "Use hardware acceleration"

### For GPU passthrough in Proxmox:

1. Enable IOMMU in Proxmox host
2. Pass GPU to VM
3. Install drivers in VM
4. Restart Plex container

## Adding Media

### Option 1: Direct copy to server

```bash
# From local machine
scp movie.mkv hatchery:/media/movies/
```

### Option 2: Set up SMB/NFS share

```bash
# Install Samba on hatchery
sudo apt install samba

# Configure share in /etc/samba/smb.conf
[media]
   path = /media
   browseable = yes
   read only = no
   valid users = debian
```

### Option 3: Mount network storage

```bash
# Mount NAS share
sudo mkdir -p /mnt/nas
sudo mount -t nfs nas.local:/volume1/media /mnt/nas
```

## Updating Plex

### With Ansible:

```bash
ansible-playbook playbooks/site.yml --tags plex
```

### Manually:

```bash
# SSH into server
ssh SERVER_NAME

# Pull latest image
docker pull lscr.io/linuxserver/plex:latest

# Restart container
docker restart plex
```

### Using the update script:

```bash
# SSH into server
ssh SERVER_NAME

# Run update script (created by Ansible)
/opt/docker/plex/update-plex.sh
```

## Monitoring

Check Plex status:

```bash
# Container status
docker ps | grep plex

# Logs
docker logs -f plex

# Resource usage
docker stats plex
```

## Backup

Important directories to backup:

```bash
/opt/docker/plex/config/Library/Application Support/Plex Media Server/
```

Key files:
- `Preferences.xml` - Server settings
- `Metadata/` - Library metadata
- `Plug-in Support/Databases/` - Library databases

## Troubleshooting

### Can't access web UI:

```bash
# Check if container is running
docker ps | grep plex

# Check logs
docker logs plex

# Check port
sudo netstat -tlnp | grep 32400
```

### Libraries not showing:

1. Check permissions:
   ```bash
   ls -la /media/
   ```

2. Check container can see files:
   ```bash
   docker exec plex ls -la /movies
   ```

### Transcoding issues:

1. Check CPU usage during playback
2. Enable verbose logging in Plex
3. Check `/dev/dri` permissions for hardware transcoding

## Next Steps

1. Configure remote access in Plex settings
2. Set up Plex apps on your devices
3. Consider Plex Pass for additional features
4. Set up automated media management (Sonarr/Radarr)