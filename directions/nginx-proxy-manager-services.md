# Nginx Proxy Manager Service Configuration

This guide shows how to add services to Nginx Proxy Manager for easy access via domain names.

## Access NPM Admin Panel

1. Go to http://docker-services-host.lan:81
2. Login with your NPM admin credentials

## Adding Proxy Hosts

### Portainer (Container Management)

1. Click **"Add Proxy Host"**
2. **Details tab:**
   - Domain Names: `portainer.pequod.sh`
   - Scheme: `http`
   - Forward Hostname/IP: `192.168.1.103`
   - Forward Port: `9000`
   - ✓ Block Common Exploits
   - ✓ Websockets Support

3. **SSL tab:**
   - SSL Certificate: Request new Let's Encrypt certificate
   - ✓ Force SSL
   - Email: your-email@example.com
   - ✓ Agree to terms

4. **Advanced tab** - Add this custom config:
   ```nginx
   # Portainer specific settings
   proxy_set_header Upgrade $http_upgrade;
   proxy_set_header Connection "upgrade";
   ```

5. Click **Save**

### Grafana (Monitoring Dashboard)

1. Click **"Add Proxy Host"**
2. **Details tab:**
   - Domain Names: `grafana.pequod.sh`
   - Scheme: `http`
   - Forward Hostname/IP: `192.168.1.103`
   - Forward Port: `3000`
   - ✓ Block Common Exploits
   - ✓ Websockets Support

3. **SSL tab:**
   - SSL Certificate: Request new Let's Encrypt certificate
   - ✓ Force SSL

4. **Advanced tab** - Add this custom config:
   ```nginx
   # Grafana specific settings
   proxy_set_header Host $http_host;
   ```

5. Click **Save**

### InfluxDB (Time Series Database)

1. Click **"Add Proxy Host"**
2. **Details tab:**
   - Domain Names: `influxdb.pequod.sh`
   - Scheme: `http`
   - Forward Hostname/IP: `192.168.1.103`
   - Forward Port: `8086`
   - ✓ Block Common Exploits

3. **SSL tab:**
   - SSL Certificate: Request new Let's Encrypt certificate
   - ✓ Force SSL

4. Click **Save**

### PeaNUT (UPS Monitor)

1. Click **"Add Proxy Host"**
2. **Details tab:**
   - Domain Names: `ups.pequod.sh`
   - Scheme: `http`
   - Forward Hostname/IP: `192.168.1.15`
   - Forward Port: `8086`
   - ✓ Block Common Exploits
   - ✓ Websockets Support

3. **SSL tab:**
   - SSL Certificate: Request new Let's Encrypt certificate
   - ✓ Force SSL

4. Click **Save**

### Zigbee2MQTT

1. Click **"Add Proxy Host"**
2. **Details tab:**
   - Domain Names: `mqtt.pequod.sh` or `zigbee.pequod.sh`
   - Scheme: `http`
   - Forward Hostname/IP: `192.168.1.103`
   - Forward Port: `8080`
   - ✓ Block Common Exploits
   - ✓ Websockets Support

3. **SSL tab:**
   - SSL Certificate: Request new Let's Encrypt certificate
   - ✓ Force SSL

4. Click **Save**

## Setting Up Access Lists (Optional)

To restrict access to local network only:

1. Go to **Access Lists** in NPM
2. Click **"Add Access List"**
3. Name: `Local Network Only`
4. Add Authorization:
   - Type: `Allow`
   - IP Address: `192.168.1.0/24`
5. Click **Save**

Then edit each proxy host and in the **Details** tab, set:
- Access List: `Local Network Only`

## DNS Configuration

Make sure your DNS (Pi-hole or router) has entries for these domains:
- `portainer.pequod.sh` → docker-services-host IP
- `grafana.pequod.sh` → docker-services-host IP
- `influxdb.pequod.sh` → docker-services-host IP
- `ups.pequod.sh` → docker-services-host IP
- `mqtt.pequod.sh` → docker-services-host IP

Or use wildcard: `*.pequod.sh` → docker-services-host IP (where NPM is running)

## Testing

After adding each service, test by visiting:
- https://portainer.pequod.sh
- https://grafana.pequod.sh
- https://influxdb.pequod.sh
- https://ups.pequod.sh
- https://mqtt.pequod.sh

## Troubleshooting

### SSL Certificate Issues
- Make sure ports 80 and 443 are forwarded to docker-services-host
- Check that DNS resolves correctly
- Let's Encrypt needs to reach your domain from the internet

### Service Not Accessible
- Verify the service is running: `docker ps`
- Check the correct internal IP and port
- Test direct access first: `http://192.168.1.103:9443`
- Check NPM logs: `docker logs nginx-proxy-manager`

### Websocket Issues
- Make sure "Websockets Support" is enabled
- Add the proxy headers in Advanced configuration