# Pi-hole Setup

## LXC Container

Pi-hole is installed in an LXC container on Proxmox using the official Pi-hole installer, not Docker.

1. Created as LXC container in Proxmox
2. Name: `pihole`
3. 1 CPU core, 1GB RAM, 8GB disk
4. Network: Static IP (important for DNS)
5. Backed up by Proxmox

## Access Pi-hole

1. Open http://pihole.lan/admin
2. Log in with password from secrets

## Configure DNS

### On Router
1. Set primary DNS to Pi-hole IP
2. Set secondary DNS to 1.1.1.1 or 8.8.8.8

### On Individual Devices
1. Set DNS to Pi-hole IP

## Add Block Lists

1. Go to Adlists
2. Add:
   - https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts
   - https://someonewhocares.org/hosts/zero/hosts
   - https://raw.githubusercontent.com/PolishFiltersTeam/KADhosts/master/KADhosts.txt

## Update Gravity

```bash
ssh root@pihole.lan
pihole -g
```

## Whitelist Common Services

```bash
# Microsoft
pihole -w clientconfig.passport.net

# Apple
pihole -w appleid.apple.com
```

## Monitor

```bash
# Check logs
pihole -t

# Check stats
pihole -c

# Check status
pihole status
```