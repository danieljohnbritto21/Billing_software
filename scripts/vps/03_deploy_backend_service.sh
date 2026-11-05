#!/usr/bin/env bash
# ==============================================================================
# FoodBill Pro — VPS Production Deployment: Stage 3 (Backend & Systemd)
# Target: Node.js Express Backend on Ubuntu VPS
# ==============================================================================

set -euo pipefail

APP_DIR="/var/www/foodbill/backend"
STORAGE_DIR="/var/www/foodbill/storage/images"
LOG_DIR="/var/log/foodbill"
SERVICE_USER="foodbill"

echo ">>> [1/5] Creating dedicated service user and directories..."
if ! id -u "$SERVICE_USER" >/dev/null 2>&1; then
  sudo useradd --system --shell /bin/bash --home-dir /var/www/foodbill "$SERVICE_USER"
fi

sudo mkdir -p "$APP_DIR" "$STORAGE_DIR" "$LOG_DIR"
sudo chown -R "$SERVICE_USER:$SERVICE_USER" /var/www/foodbill "$LOG_DIR"

echo ">>> [2/5] Installing dependencies and building backend..."
cd "$APP_DIR"
sudo -u "$SERVICE_USER" npm install --production=false
sudo -u "$SERVICE_USER" npx prisma generate
sudo -u "$SERVICE_USER" npm run build

echo ">>> [3/5] Setting up production systemd service..."
sudo tee /etc/systemd/system/foodbill-backend.service > /dev/null <<EOF
[Unit]
Description=FoodBill Pro POS Backend API Service
After=network.target postgresql.service
Wants=postgresql.service

[Service]
Type=simple
User=$SERVICE_USER
WorkingDirectory=$APP_DIR
EnvironmentFile=$APP_DIR/.env
ExecStart=/usr/bin/node dist/server.js
Restart=always
RestartSec=5
StandardOutput=append:$LOG_DIR/backend.log
StandardError=append:$LOG_DIR/backend-error.log

# Production Resource Limits
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

echo ">>> [4/5] Enabling and starting foodbill-backend service..."
sudo systemctl daemon-reload
sudo systemctl enable foodbill-backend.service
sudo systemctl restart foodbill-backend.service

echo ">>> [5/5] Testing local backend health..."
sleep 3
curl -s http://127.0.0.1:3000/health | grep -q '"status":"UP"' && echo "Backend Health Check: PASSED" || (echo "Backend Health Check: FAILED" && sudo systemctl status foodbill-backend.service && exit 1)

echo ">>> [SUCCESS] FoodBill Pro backend is running under systemd!"
