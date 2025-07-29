# Portainer Remote Docker Management

This guide explains how to set up Portainer to manage Docker containers on remote servers.

## Overview

Portainer can manage multiple Docker environments:
- **Local**: Already configured - uses the Docker socket on docker-services-host
- **Remote**: Using Edge Agents for secure remote management

## Setting Up Remote Docker Management

### Method 1: Edge Agent (Recommended)

Edge Agents are perfect for:
- Servers behind NAT/firewall
- Dynamic IP addresses
- Secure polling-based connection

#### Step 1: Get Edge Key from Portainer

1. Go to https://portainer.pequod.sh
2. Navigate to **Environments** → **Add environment**
3. Select **Docker Standalone** → **Edge Agent**
4. Select **Linux** as the OS
5. **Important**: Copy the generated Edge Key (looks like a long random string)
6. Optionally set a name for the environment

#### Step 2: Install Edge Agent on Remote Host

On each remote Docker host you want to manage:

```bash
# Create directory
sudo mkdir -p /opt/docker/portainer-agent

# Create docker-compose.yml
sudo nano /opt/docker/portainer-agent/docker-compose.yml
```

Add this content (replace YOUR_EDGE_KEY with the key from Step 1):
```yaml
version: '3.8'

services:
  edge-agent:
    image: portainer/agent:latest
    container_name: portainer_edge_agent
    restart: unless-stopped
    environment:
      - EDGE=1
      - EDGE_ID=my-remote-server  # Optional custom ID
      - EDGE_KEY=YOUR_EDGE_KEY_HERE
      - EDGE_INSECURE_POLL=1  # Since we use self-signed cert
      - PORTAINER_URL=https://portainer.pequod.sh
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /var/lib/docker/volumes:/var/lib/docker/volumes
      - /opt/docker/portainer-agent:/data
    networks:
      - agent_net

networks:
  agent_net:
    driver: bridge
```

Start the agent:
```bash
cd /opt/docker/portainer-agent
sudo docker compose up -d
```

#### Step 3: Verify Connection

1. Return to Portainer UI
2. The remote environment should appear in the Environments list within 30 seconds
3. Click on it to manage remote containers

### Method 2: Direct Connection (For Same Network)

For Docker hosts on the same network that can be reached directly:

1. On remote host, expose Docker API:
   ```bash
   # Edit Docker service
   sudo systemctl edit docker.service
   ```
   
   Add:
   ```ini
   [Service]
   ExecStart=
   ExecStart=/usr/bin/dockerd -H fd:// -H tcp://0.0.0.0:2375
   ```
   
   **WARNING**: This is insecure! Only use on trusted networks.

2. In Portainer:
   - Environments → Add environment
   - Docker Standalone → API
   - Name: Remote Server Name
   - Endpoint URL: `tcp://remote-server-ip:2375`

## Using Ansible to Deploy Edge Agents

To deploy to multiple hosts:

```bash
# First, get the Edge Key from Portainer UI
# Then update the playbook with the key

# Run on specific host
ansible-playbook -i inventories/homelab.yml \
  playbooks/setup-portainer-edge-agent.yml \
  -e "edge_key=YOUR_EDGE_KEY_HERE" \
  --limit nexus.lan

# Run on all Docker hosts
ansible-playbook -i inventories/homelab.yml \
  playbooks/setup-portainer-edge-agent.yml \
  -e "edge_key=YOUR_EDGE_KEY_HERE" \
  -e "ansible_become_pass=YOUR_SUDO_PASS"
```

## Managing Multiple Environments

Once configured, you can:
- Switch between environments using the dropdown in Portainer
- See all environments on the Home page
- Manage containers, images, networks, volumes on each host
- Deploy stacks across multiple hosts
- Monitor resource usage

## Troubleshooting

### Edge Agent Not Connecting
- Check the Edge Key is correct
- Verify Portainer URL is accessible from remote host
- Check Docker logs: `docker logs portainer_edge_agent`
- Ensure port 8000 is open on Portainer server for Edge communication

### Can't See Containers
- Verify Docker socket is mounted correctly
- Check agent has proper permissions
- Restart the Edge Agent

### Connection Timeout
- Edge Agents poll every 5 seconds by default
- May take up to 30 seconds to appear initially
- Check firewall rules on both ends