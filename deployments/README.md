# Deployments - Production-Ready Configurations

This directory contains finalized, tested configuration files ready for deployment.

## Structure

```
deployments/
└── services/           # Production configs organized by service
    ├── zigbee-mqtt/
    ├── home-assistant/
    ├── pihole/
    ├── plex/
    └── ...
```

## Usage

When a configuration is tested and ready for production use, copy it here. These files serve as:

1. Quick deployment references
2. Known-good configurations for recovery
3. Templates for similar services
4. Ansible deployment sources

## Workflow

1. Develop and test in `services/SERVICE_NAME/`
2. Deploy with Ansible from `ansible/`
3. Copy final, working configs here for reference
4. Use these as templates for similar deployments

## Note

These configurations are server-agnostic. Server-specific values (IPs, paths, etc.) should use environment variables or be documented clearly.