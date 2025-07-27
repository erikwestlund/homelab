# Secrets Management

## Overview

Secrets management:
- Local `secrets.yaml` file (git-ignored)
- Synced via rclone to secure cloud storage
- Integrated with dotfiles sync scripts

## Step 1: Initial Setup

Create secrets file from template:

```bash
cd ~/code/homelab/ansible
cp secrets.yaml.example secrets.yaml
```

## Step 2: Edit Secrets


```bash
vim secrets.yaml
```

Key secrets to configure:

```yaml
# Plex
plex_claim_token: "claim-xxxxxxxxxxxx"  # From https://www.plex.tv/claim

# Home Assistant
home_assistant_api_token: "your-long-lived-token"

# MQTT/Zigbee
mqtt_username: "homelab"
mqtt_password: "generate-strong-password"

# Pi-hole
pihole_web_password: "your-admin-password"

# Backup credentials
s3_access_key: "your-access-key"
s3_secret_key: "your-secret-key"
```

## Step 3: Save Secrets to Cloud


```bash
put-secrets
```

This runs the script that includes:
```bash
rclone copy ~/code/homelab/ansible/secrets.yaml config:/erik-config/homelab/ansible/
```

## Step 4: Sync Secrets on New Machine

On any machine with dotfiles:

```bash
sync-secrets
```

This pulls all your secrets including:
- SSH keys (`~/.ssh/`)
- AWS credentials (`~/.aws/`)
- Homelab secrets (`~/code/homelab/ansible/secrets.yaml`)

## Step 5: Using Secrets in Ansible

Secrets are automatically loaded in playbooks:

```yaml
vars_files:
  - "{{ playbook_dir }}/../secrets.yaml"
```

Reference in roles:

```yaml
environment:
  PLEX_CLAIM: "{{ plex_claim_token }}"
```

## Generating Secure Passwords

### Using OpenSSL:

```bash
openssl rand -base64 32
```

### Using Python:

```bash
python3 -c 'import secrets; print(secrets.token_urlsafe(32))'
```

### Using pwgen:

```bash
pwgen -s 32 1
```

## Managing Different Environments

### Option 1: Environment-specific files

```bash
secrets.yaml          # Production
secrets.dev.yaml      # Development
secrets.staging.yaml  # Staging
```

### Option 2: Encrypted with Ansible Vault

```bash
# Encrypt secrets file
ansible-vault encrypt secrets.yaml

# Edit encrypted file
ansible-vault edit secrets.yaml

# Use in playbook
ansible-playbook playbooks/site.yml --ask-vault-pass
```

## Quick Reference

### Add new secret:

1. Edit `secrets.yaml`
2. Run `put-secrets`
3. Deploy with Ansible

### Rotate a secret:

1. Generate new value
2. Update `secrets.yaml`
3. Run `put-secrets`
4. Redeploy affected service

### Share with team member:

1. Use ansible-vault for encryption
2. Share vault password separately
3. Commit encrypted file to git

## Security Best Practices

1. **Never commit secrets to git**
   - Check `.gitignore` includes `secrets.yaml`
   - Use `git status` before committing

2. **Use strong passwords**
   - Minimum 32 characters for important services
   - Use password generators

3. **Rotate regularly**
   - Set calendar reminders
   - Document rotation in README

4. **Limit access**
   - Use separate secrets per environment
   - Don't share production secrets

5. **Backup securely**
   - Rclone remote should be encrypted
   - Keep offline backup of critical secrets

## Troubleshooting

### Secrets not loading:

```bash
# Check file exists
ls -la ~/code/homelab/ansible/secrets.yaml

# Test loading
ansible-playbook playbooks/site.yml --check -v
```

### Permission denied:

```bash
# Fix permissions
chmod 600 ~/code/homelab/ansible/secrets.yaml
```

### Sync issues:

```bash
# Check rclone config
rclone config show

# Test sync
rclone ls config:/erik-config/homelab/
```