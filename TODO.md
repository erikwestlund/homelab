# Homelab TODO List

## Monitoring Stack - Data Collection Setup

### Priority 1: Get Data Flowing into InfluxDB

#### 1. Configure Home Assistant to send data to InfluxDB
- [ ] Add InfluxDB integration to Home Assistant configuration.yaml
- [ ] Use the token from `/opt/docker/monitoring-stack/.env` on docker-services-host
- [ ] Configure which entities to include/exclude
- [ ] Test data is being received in InfluxDB

#### 2. Verify Telegraf is collecting metrics
- [ ] Check Docker metrics are being collected
- [ ] Verify system metrics (CPU, memory, disk) are working
- [ ] Confirm InfluxDB buckets are receiving data
- [ ] Fix NUT/UPS monitoring (currently disabled due to Python dependency)

#### 3. Create Grafana Dashboards
- [ ] Import recommended dashboards from Grafana.com
- [ ] Create custom dashboard for Home Assistant data
- [ ] Set up alerts for critical metrics
- [ ] Configure dashboard auto-refresh

### Priority 2: Complete Service Deployments

#### 1. Portainer Edge Agents
- [ ] Deploy edge agents on other Docker hosts
- [ ] Configure remote Docker management
- [ ] Document edge agent setup process

#### 2. Fix Remaining Issues
- [ ] Ensure all services work with Cloudflare proxy enabled
- [ ] Document NPM proxy configuration best practices
- [ ] Create backup scripts for monitoring data

### Priority 3: Documentation & Automation

#### 1. Update Documentation
- [ ] Document monitoring stack architecture
- [ ] Create runbook for common issues
- [ ] Add troubleshooting guide for Docker networking

#### 2. Ansible Improvements
- [ ] Fix rsync issue in monitoring-stack deployment
- [ ] Add health checks to all roles
- [ ] Create single playbook to deploy entire stack

## Completed Tasks ✓
- [x] Deploy Portainer for Docker management
- [x] Set up monitoring stack (InfluxDB + Telegraf + Grafana)
- [x] Configure credentials from secrets.yaml
- [x] Fix Docker networking between services
- [x] Update NPM to use container names instead of IPs
- [x] Document Docker networking best practices in CLAUDE.md

## Notes
- Monitoring stack ports: Grafana (3001), InfluxDB (8087)
- All services should use container names for inter-container communication
- Credentials are stored in ansible/secrets.yaml with hierarchical structure