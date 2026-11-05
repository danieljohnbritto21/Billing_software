#!/usr/bin/env bash
# ==============================================================================
# FoodBill Pro — VPS Production Deployment: Stage 1 (System & Packages)
# Target OS: Ubuntu Server 24.04 LTS
# ==============================================================================

set -euo pipefail

echo ">>> [1/5] Updating system packages..."
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update && sudo apt-get upgrade -y

echo ">>> [2/5] Installing core dependencies, UFW, and Fail2ban..."
sudo apt-get install -y \
  curl \
  wget \
  gnupg \
  lsb-release \
  ca-certificates \
  ufw \
  fail2ban \
  nginx \
  certbot \
  python3-certbot-nginx \
  git \
  build-essential

echo ">>> [3/5] Setting up Node.js 20.x LTS..."
if ! command -v node >/dev/null 2>&1 || [[ "$(node -v)" != v20* ]]; then
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
  sudo apt-get install -y nodejs
fi
echo "Node version: $(node -v)"
echo "NPM version: $(npm -v)"

echo ">>> [4/5] Installing PostgreSQL 16..."
if ! command -v psql >/dev/null 2>&1; then
  sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
  wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
  sudo apt-get update
  sudo apt-get install -y postgresql-16 postgresql-contrib-16
fi

# Ensure PostgreSQL 16 is bound only to localhost (127.0.0.1)
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '127.0.0.1'/g" /etc/postgresql/16/main/postgresql.conf
sudo systemctl enable postgresql
sudo systemctl restart postgresql

echo ">>> [5/5] Configuring UFW Firewall..."
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp comment 'SSH'
sudo ufw allow 80/tcp comment 'HTTP (Certbot & Redirection)'
sudo ufw allow 443/tcp comment 'HTTPS (FoodBill Pro API)'
sudo ufw --force enable
sudo ufw status verbose

echo ">>> [SUCCESS] VPS Prerequisites installed and secured successfully!"
