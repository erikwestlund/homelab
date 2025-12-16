# Immich Photo Management

Self-hosted photo and video backup solution running on `immich.lan`.

## Access

- **Local**: http://immich.lan:2283
- **External**: https://immich.pequod.sh

## Architecture

| Container | Purpose |
|-----------|---------|
| immich_server | Main API and web server |
| immich_machine_learning | Face recognition, smart search |
| immich_postgres | PostgreSQL with pgvecto.rs |
| immich_redis | Caching and job queue |

## Storage

Photos are stored on the NAS:
- **NAS Share**: `//192.168.1.10/Media/immich`
- **Mount Point**: `/mnt/nas/photos/immich`
- **Capacity**: ~44TB

### fstab Entry
```
//192.168.1.10/Media /mnt/nas/photos cifs credentials=/root/.nascreds,uid=0,gid=0,file_mode=0755,dir_mode=0755,_netdev,nofail 0 0
```

Credentials stored in `/root/.nascreds` (mode 600).

## Deployment

```bash
cd ~/Projects/homelab/ansible
ansible-playbook -i inventories/homelab.yml playbooks/deploy-immich.yml
```

## Configuration Files

On server (`immich.lan`):
- `/opt/docker/immich/docker-compose.yml`
- `/opt/docker/immich/.env`
- `/opt/docker/immich/.db_password`

## Nginx Proxy Manager Setup

When proxying through NPM with Cloudflare, use this custom Nginx configuration to fix websocket issues:

**Advanced → Custom Nginx Configuration:**
```nginx
location / {
    proxy_pass http://immich.lan:2283;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_read_timeout 86400;
}
```

## Common Operations

```bash
# SSH to server
ssh root@immich.lan

# View logs
cd /opt/docker/immich
docker compose logs -f

# Restart services
docker compose restart

# Update Immich
docker compose pull
docker compose up -d
```

## Mobile App

1. Install Immich app (iOS/Android)
2. Server URL: `https://immich.pequod.sh` (external) or `http://immich.lan:2283` (local)
3. Login with your account credentials
