#!/usr/bin/env bash
# ==============================================================================
# FoodBill Pro — Complete One-Step VPS Production Deployment Runner
# Target: Ubuntu Server 24.04 LTS
# ==============================================================================

set -euo pipefail

DOMAIN="${1:-}"
EMAIL="${2:-admin@$DOMAIN}"
DUMP_FILE="${3:-/tmp/foodbill_pre_vps_deploy_current.dump}"

if [[ -z "$DOMAIN" ]]; then
  echo "=========================================================="
  echo " FoodBill Pro — Ubuntu VPS Production Deployment Runner"
  echo "=========================================================="
  echo "Usage: sudo ./00_deploy_all.sh <YOUR_DOMAIN> <ADMIN_EMAIL> [DUMP_FILE_PATH]"
  echo "Example: sudo ./00_deploy_all.sh api.foodbillpro.com admin@foodbillpro.com"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================================="
echo " Starting Full Production Deployment for $DOMAIN"
echo "=========================================================="

echo ">>> Stage 1: Installing system prerequisites, Node 20, Postgres 16, UFW, Nginx..."
bash "$SCRIPT_DIR/01_install_vps_prerequisites.sh"

echo ">>> Stage 2: Setting up PostgreSQL 16 and Restoring Verified Database..."
bash "$SCRIPT_DIR/02_setup_database_and_restore.sh" "$DUMP_FILE"

echo ">>> Stage 3: Deploying Backend and Starting Systemd Service..."
bash "$SCRIPT_DIR/03_deploy_backend_service.sh"

echo ">>> Stage 4: Configuring Nginx Reverse Proxy and Let's Encrypt TLS..."
bash "$SCRIPT_DIR/04_configure_nginx_ssl.sh" "$DOMAIN" "$EMAIL"

echo ">>> Stage 5: Configuring Automated Daily Backups and Verification..."
bash "$SCRIPT_DIR/05_configure_automated_backups.sh"

echo "=========================================================="
echo " [DEPLOYMENT COMPLETE] Production API is LIVE at https://$DOMAIN"
echo " Health check: https://$DOMAIN/health"
echo "=========================================================="
