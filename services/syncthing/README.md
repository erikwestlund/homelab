# Syncthing File Synchronization

Central file synchronization hub running in an LXC container on Proxmox.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                    FULL BIDIRECTIONAL SYNC                          │
│                                                                     │
│    NAS                              Proxmox SSD                     │
│    /volume1/Files  ◄══════════════► /srv/files                      │
│                                                                     │
│    Drop files here                  Or drop files here              │
│    They sync to SSD                 They sync to NAS                │
│                                                                     │
│    Both have complete copy of everything                            │
└─────────────────────────────────────────────────────────────────────┘
                                │
                    ┌───────────┼───────────┐
                    ▼           ▼           ▼
              SELECTIVE    SELECTIVE    SELECTIVE
              ┌──────────┐ ┌──────────┐ ┌──────────┐
              │Work      │ │Home      │ │Phone     │
              │Laptop    │ │Desktop   │ │          │
              │          │ │          │ │          │
              │~/Work    │ │~/Work    │ │Photos    │
              │~/CV      │ │~/Personal│ │          │
              │          │ │~/Photos  │ │          │
              └──────────┘ └──────────┘ └──────────┘

              Clients pick which folders to sync
              and where to put them locally
```

### Sync Model

- **NAS + SSD**: Full mirror, bidirectional. Drop files on either and they appear on both.
- **Workstations**: Subscribe to specific folders only. Map them to any local path.
- **OneDrive**: Syncs to a folder on SSD, then Syncthing distributes it.
- **B2**: Nightly backup of entire SSD contents.

### Services (LXC Container)

```
┌─────────────────────────────────────────────────────────┐
│              Syncthing LXC Container                    │
│                                                         │
│  /srv/files (bind mount from Proxmox SSD)              │
│  /mnt/nas   (NFS mount to NAS)                          │
│                                                         │
│  - Syncthing (port 8384 web UI, 22000 sync)            │
│  - OneDrive sync (rclone or abraunegg/onedrive)        │
│  - B2 backup (rclone)                                   │
└─────────────────────────────────────────────────────────┘
```

## Directory Structure

```
Files/
├── Erik/
│   ├── Work/           # Work-related files
│   ├── Personal/       # Personal documents
│   ├── Home/           # Home management
│   └── Photos/         # Photo library
├── Family/             # Shared family files
└── Work/
    └── OneDrive/       # Synced from corporate OneDrive
        ├── CV/
        └── ...
```

## Client Mapping Examples

Each client can map Syncthing folders to custom local paths:

| Syncthing Folder    | Work Laptop      | Home Desktop     | NAS              |
|---------------------|------------------|------------------|------------------|
| Files/Erik/Work     | ~/Work           | ~/Work           | /volume1/Files/Erik/Work |
| Files/Erik/Personal | -                | ~/Personal       | /volume1/Files/Erik/Personal |
| Files/Erik/Photos   | -                | ~/Photos         | /volume1/Files/Erik/Photos |
| Files/Family        | -                | ~/Family         | /volume1/Files/Family |
| Files/Work/OneDrive | ~/OneDrive       | -                | /volume1/Files/Work/OneDrive |

## Ports

| Port  | Protocol | Purpose                    |
|-------|----------|----------------------------|
| 8384  | TCP      | Web UI                     |
| 22000 | TCP      | Sync protocol              |
| 21027 | UDP      | Local discovery            |

## Setup

### Prerequisites

1. LXC container running Debian 12
2. Proxmox SSD mounted and passed through to container
3. NAS accessible via NFS

### Deploy with Ansible

```bash
cd ansible
ansible-playbook -i inventories/homelab.yml playbooks/deploy-syncthing.yml
```

### Post-Deployment

1. Access web UI at http://syncthing.lan:8384
2. Add devices (laptops, NAS, etc.)
3. Configure folders with appropriate sharing and paths
4. Set up OneDrive sync (see below)
5. Configure B2 backup schedule

## OneDrive Integration

Two options for syncing OneDrive:

### Option 1: abraunegg/onedrive (Recommended)

Purpose-built OneDrive client with selective sync:

```bash
# Install
apt install onedrive

# Configure selective sync
cat > ~/.config/onedrive/sync_list << EOF
/Documents/Work
/Documents/CV
EOF

# Run as service
systemctl --user enable onedrive
systemctl --user start onedrive
```

### Option 2: rclone bisync

More flexible, handles multiple cloud providers:

```bash
# Configure remote
rclone config  # Follow prompts for OneDrive

# Bidirectional sync specific folders
rclone bisync onedrive:/Documents/Work /srv/files/Work/OneDrive/Documents --resync
```

## B2 Backup

Using rclone for offsite backup to Backblaze B2:

```bash
# Configure B2 remote
rclone config  # Add B2 remote

# Sync to B2 (add to cron)
rclone sync /srv/files b2:homelab-files-backup --transfers 8
```

Recommended cron schedule:
```
0 2 * * * rclone sync /srv/files b2:homelab-files-backup --transfers 8 --log-file /var/log/rclone-b2.log
```

## Backup Strategy

1. **Primary**: Proxmox SSD (`/mnt/files`)
2. **Local Mirror**: NAS (real-time via Syncthing)
3. **Offsite**: B2 (nightly via rclone)

## Credentials

Store in `ansible/secrets.yaml`:

```yaml
syncthing:
  api_key: "<generated>"
  gui_password: "<your-password>"

onedrive:
  # OAuth handled interactively on first run

b2:
  account_id: "<your-account-id>"
  application_key: "<your-app-key>"
  bucket: "homelab-files-backup"
```
