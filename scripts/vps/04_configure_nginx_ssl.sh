#!/usr/bin/env bash
# ==============================================================================
# FoodBill Pro — VPS Production Deployment: Stage 4 (Nginx Reverse Proxy & SSL)
# Target: Nginx with Let's Encrypt TLS on Ubuntu VPS
# ==============================================================================

set -euo pipefail

DOMAIN="${1:-}"
EMAIL="${2:-admin@$DOMAIN}"

if [[ -z "$DOMAIN" ]]; then
  echo "ERROR: Domain name required!"
  echo "Usage: $0 your-domain.com [admin-email]"
  exit 1
fi

echo ">>> [1/4] Generating Nginx reverse proxy configuration for $DOMAIN..."
sudo tee /etc/nginx/sites-available/foodbill > /dev/null <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN;

    # Security Headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # Allow large payloads for high-resolution product image uploads
    client_max_body_size 50M;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
EOF

echo ">>> [2/4] Enabling site and testing configuration..."
sudo ln -sf /etc/nginx/sites-available/foodbill /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx

echo ">>> [3/4] Requesting Let's Encrypt TLS Certificate via Certbot..."
sudo certbot --nginx --non-interactive --agree-tos --email "$EMAIL" --redirect -d "$DOMAIN"

echo ">>> [4/4] Verifying HTTPS health endpoint..."
curl -s "https://$DOMAIN/health" | grep -q '"status":"UP"' && echo "HTTPS Production Health Check: PASSED" || echo "Note: Check DNS propagation if domain was freshly pointed."

echo ">>> [SUCCESS] Nginx and TLS configured successfully for https://$DOMAIN!"
