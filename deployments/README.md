# Deployments - Production-Ready Configurations

This directory contains finalized, tested configuration files ready for deployment.

## Structure

- `nexus/` - Production configurations for Nexus services
- `hatchery/` - Production configurations for Hatchery services

## Usage

When a configuration is tested and ready for production use, copy it here with a descriptive filename. These files serve as:

1. Quick deployment references
2. Known-good configurations for recovery
3. Templates for similar services

## Naming Convention

Use descriptive names that include the service and purpose:
- `zigbee-mqtt-docker-compose.yml`
- `home-assistant-docker-compose.yml`
- `plex-docker-compose-gpu.yml`