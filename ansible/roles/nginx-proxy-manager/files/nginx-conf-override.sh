#!/bin/bash
# Script to configure NPM for Cloudflare real IP detection
# This script is run when the NPM container starts

# Wait for nginx.conf to be generated
sleep 5

# Check if already configured
if grep -q "CF-Connecting-IP" /etc/nginx/nginx.conf; then
    echo "Cloudflare real IP already configured"
    exit 0
fi

# Backup original
cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.original

# Replace X-Real-IP with CF-Connecting-IP
sed -i 's/real_ip_header X-Real-IP;/real_ip_header CF-Connecting-IP;/' /etc/nginx/nginx.conf

# Test configuration
nginx -t

if [ $? -eq 0 ]; then
    echo "Cloudflare real IP configuration applied successfully"
    # Reload nginx
    nginx -s reload
else
    echo "Error in nginx configuration, reverting"
    cp /etc/nginx/nginx.conf.original /etc/nginx/nginx.conf
    exit 1
fi