#!/bin/bash
# Deploy all Grafana dashboards to running instance

GRAFANA_URL="http://docker-services-host.lan:3001"
GRAFANA_USER="admin"
GRAFANA_PASS="BIgvqJh4wWAuCQ61YIp4ONVWM"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DASHBOARDS_DIR="${SCRIPT_DIR}/../grafana/dashboards"

echo "Deploying Grafana dashboards..."
echo "=============================="

# Function to deploy a dashboard
deploy_dashboard() {
    local dashboard_file=$1
    local dashboard_name=$(basename "$dashboard_file" .json)
    
    echo -n "Deploying ${dashboard_name}... "
    
    # Wrap the dashboard JSON in the required API format
    PAYLOAD=$(jq '{dashboard: ., folderId: 0, overwrite: true}' "$dashboard_file")
    
    RESPONSE=$(curl -s -X POST "${GRAFANA_URL}/api/dashboards/db" \
        -H "Content-Type: application/json" \
        -u "${GRAFANA_USER}:${GRAFANA_PASS}" \
        -d "${PAYLOAD}")
    
    if echo "$RESPONSE" | jq -e '.status == "success"' > /dev/null 2>&1; then
        echo "✓ Success"
        echo "  URL: ${GRAFANA_URL}$(echo "$RESPONSE" | jq -r '.url')"
    else
        echo "✗ Failed"
        echo "  Error: $(echo "$RESPONSE" | jq -r '.message // "Unknown error"')"
    fi
}

# Check if Grafana is accessible
if ! curl -s -f "${GRAFANA_URL}/api/health" > /dev/null; then
    echo "Error: Cannot reach Grafana at ${GRAFANA_URL}"
    echo "Make sure Grafana is running and accessible"
    exit 1
fi

# Deploy all dashboards
for dashboard in "${DASHBOARDS_DIR}"/*.json; do
    if [ -f "$dashboard" ]; then
        deploy_dashboard "$dashboard"
    fi
done

echo ""
echo "Dashboard deployment complete!"
echo "Access Grafana at: ${GRAFANA_URL}"