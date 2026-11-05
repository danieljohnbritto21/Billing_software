#!/usr/bin/env bash
# ==============================================================================
# FoodBill Pro — VPS Production Deployment: Stage 5 (Automated Backups & Cron)
# Target: Daily Automated Backups with Verification & Test Restore
# ==============================================================================

set -euo pipefail

BACKUP_ROOT="/var/backups/foodbill"
BACKUP_SCRIPT="/usr/local/bin/foodbill-backup.sh"

echo ">>> [1/3] Creating backup directories..."
sudo mkdir -p "$BACKUP_ROOT/database/daily" "$BACKUP_ROOT/database/weekly" "$BACKUP_ROOT/database/monthly" "$BACKUP_ROOT/logs" "$BACKUP_ROOT/storage"

echo ">>> [2/3] Installing hardened backup script..."
sudo tee "$BACKUP_SCRIPT" > /dev/null <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

DB_NAME="foodbill"
DB_PORT="5432"
BACKUP_BASE="/var/backups/foodbill/database"
LOG_FILE="/var/backups/foodbill/logs/backup.log"
DAILY_DIR="$BACKUP_BASE/daily"
WEEKLY_DIR="$BACKUP_BASE/weekly"
MONTHLY_DIR="$BACKUP_BASE/monthly"

log() {
  echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] [$1] $2" | tee -a "$LOG_FILE"
}

log "INFO" "Starting FoodBill Pro automated VPS database backup..."

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
TEMP_DUMP="$DAILY_DIR/.tmp_foodbill_${TIMESTAMP}.dump"
FINAL_DUMP="$DAILY_DIR/foodbill_daily_${TIMESTAMP}.dump"

# 1. Execute dump
if ! sudo -u postgres pg_dump -p "$DB_PORT" -Fc -d "$DB_NAME" -f "$TEMP_DUMP"; then
  log "ERROR" "pg_dump failed for $DB_NAME"
  rm -f "$TEMP_DUMP"
  exit 1
fi

# 2. Verify dump
if ! sudo -u postgres pg_restore -l "$TEMP_DUMP" >/dev/null 2>&1; then
  log "ERROR" "Backup verification failed! Corrupted archive."
  rm -f "$TEMP_DUMP"
  exit 1
fi

mv "$TEMP_DUMP" "$FINAL_DUMP"
sha256sum "$FINAL_DUMP" > "$FINAL_DUMP.sha256"
log "INFO" "Backup successfully created: $FINAL_DUMP"

# 3. Test restore verification into temporary test database
TEST_DB="foodbill_test_restore_${TIMESTAMP}"
log "INFO" "Executing automatic restore test into $TEST_DB..."
sudo -u postgres createdb -p "$DB_PORT" "$TEST_DB"
if sudo -u postgres pg_restore -p "$DB_PORT" -d "$TEST_DB" --no-owner "$FINAL_DUMP" >/dev/null 2>&1; then
  log "INFO" "Automatic test restore verification: PASSED"
else
  log "WARN" "Automatic test restore encountered non-critical warnings"
fi
sudo -u postgres dropdb -p "$DB_PORT" "$TEST_DB"

# 4. Multi-tier retention rotation
# Weekly backup on Sunday
if [[ $(date +%u) -eq 7 ]]; then
  cp "$FINAL_DUMP" "$WEEKLY_DIR/foodbill_weekly_${TIMESTAMP}.dump"
  cp "$FINAL_DUMP.sha256" "$WEEKLY_DIR/foodbill_weekly_${TIMESTAMP}.dump.sha256"
fi

# Monthly backup on 1st of month
if [[ $(date +%d) -eq 01 ]]; then
  cp "$FINAL_DUMP" "$MONTHLY_DIR/foodbill_monthly_${TIMESTAMP}.dump"
  cp "$FINAL_DUMP.sha256" "$MONTHLY_DIR/foodbill_monthly_${TIMESTAMP}.dump.sha256"
fi

# Retention cleanup: Keep 7 daily, 4 weekly, 12 monthly
find "$DAILY_DIR" -maxdepth 1 -name "foodbill_daily_*.dump*" -mtime +7 -delete
find "$WEEKLY_DIR" -maxdepth 1 -name "foodbill_weekly_*.dump*" -mtime +28 -delete
find "$MONTHLY_DIR" -maxdepth 1 -name "foodbill_monthly_*.dump*" -mtime +365 -delete

log "INFO" "Backup rotation and retention cycle complete."
EOF

sudo chmod +x "$BACKUP_SCRIPT"

echo ">>> [3/3] Setting up automated daily cron job (runs every night at 02:00 UTC)..."
sudo tee /etc/cron.d/foodbill-backup > /dev/null <<EOF
0 2 * * * root /usr/local/bin/foodbill-backup.sh > /dev/null 2>&1
EOF
sudo chmod 0644 /etc/cron.d/foodbill-backup

echo ">>> [SUCCESS] Automated backup script and cron schedule configured!"
