# Nginx Proxy Manager Setup

Deploy Nginx Proxy Manager on Docker LXC container (192.168.1.103) to proxy all services with SSL.

## Prerequisites

1. Update secrets.yaml with strong NPM password
2. Ensure erikwestlund.ddns.net points to your public IP
3. Configure port forwarding on router:
   - 80 → 192.168.1.103:80
   - 443 → 192.168.1.103:443
   - DO NOT forward port 81 (admin interface)

## Security Configuration

NPM is configured with multiple security layers:

1. **Admin Interface (Port 81)**:
   - Only accessible from local network (192.168.1.0/24)
   - UFW firewall blocks external access
   - Access via Tailscale: First VPN in, then http://192.168.1.103:81

2. **Service Access**:
   - All services except Plex restricted to local network
   - External access requires Tailscale VPN
   - Access lists automatically configured

3. **SSL/HTTPS**:
   - All services force SSL
   - Certificates from Let's Encrypt
   - HSTS enabled for security

## Deploy NPM

```bash
cd ~/code/homelab/ansible
ansible-playbook playbooks/nginx-proxy-manager.yml
```

## Verify Deployment

```bash
ansible docker-services-host -a "docker ps | grep nginx-proxy-manager"
```

## Access Admin Interface

1. Open http://192.168.1.103:81
2. Login with credentials from secrets.yaml

## Configured Services

All services are automatically configured with SSL certificates:

- https://nexus.pequod.sh → Proxmox Nexus (192.168.1.100:8006)
- https://hatchery.pequod.sh → Proxmox Hatchery (192.168.1.2:8006)
- https://pihole.pequod.sh → Pi-hole Admin (192.168.1.101:80)
- https://ha.pequod.sh → Home Assistant (192.168.1.6:8123)
- https://plex.pequod.sh → Plex Media Server (192.168.1.7:32400)
- https://mqtt.pequod.sh → Zigbee2MQTT (192.168.1.103:8080)
- https://kvm.pequod.sh → GLKVM (WebSockets enabled for remote KVM access)

## Access Control

- All services except Plex restricted to local network (192.168.1.0/24)
- Add additional allowed IPs in secrets.yaml if needed

## Accessing Services via Tailscale

When connected via Tailscale VPN:
1. Connect to Tailscale network
2. Access services directly via their local URLs:
   - https://nexus.pequod.sh → Proxmox Nexus
   - https://ha.pequod.sh → Home Assistant
   - http://192.168.1.103:81 → NPM Admin

The DDNS (erikwestlund.ddns.net) points to your home IP, but services are protected by access lists that only allow local network + Tailscale access.

## SSL Certificates

- Automatically requested from Let's Encrypt
- Auto-renewed before expiration
- May take 2-3 minutes after deployment

## Manual Configuration

If needed, access NPM admin interface to:
- View/modify proxy hosts
- Check SSL certificate status
- View access logs
- Add custom configurations

## Monitoring

```bash
# Check NPM status
ansible docker-services-host -a "curl -s http://localhost:81/api/ | jq .status"

# View logs
ansible docker-services-host -a "docker logs --tail 50 nginx-proxy-manager"

# Check SSL certificate status
ansible docker-services-host -a "docker exec nginx-proxy-manager certbot certificates"
```

## Backup

Automatic daily backups at 3 AM to `/opt/backups/nginx-proxy-manager/`

Manual backup:
```bash
ansible docker-services-host -a "/opt/nginx-proxy-manager/backup-npm.sh"
```

## Update

```bash
ansible docker-services-host -a "/opt/nginx-proxy-manager/update-npm.sh"
```

## Troubleshooting

### Service Not Accessible (Timeout)
If a proxy host times out, check:
1. **Firewall rules**: Ensure the service port is allowed
   ```bash
   # Check UFW status
   ansible docker-services-host -a "ufw status numbered"
   
   # Allow port from local network only (example for port 8080)
   ansible docker-services-host -a "ufw allow from 192.168.1.0/24 to any port 8080"
   ```
2. **Docker networking**: Services on same host may need special handling
   - Use container names instead of IPs when possible
   - Or connect containers to same Docker network

### SSL Certificate Issues
```bash
# Force renew certificate
ansible docker-services-host -a "docker exec nginx-proxy-manager certbot renew --force-renewal"
```

### Can't Access Service
1. Check DNS: `nslookup nexus.pequod.sh`
2. Check port forwarding on router
3. Verify service is running
4. Check NPM logs

### Reset Admin Password
```bash
# Connect to NPM database
ansible docker-services-host -a "docker exec -it nginx-proxy-manager sqlite3 /data/database.sqlite"
# Then run: UPDATE user SET password = '$2b$10$WbYZZsFu03biHpHCZwP5vOXHgMfIFPDtZrKvj4KqCkzqBCSHAKj.a' WHERE email = 'admin@pequod.sh';
# This sets password to 'changeme'
```