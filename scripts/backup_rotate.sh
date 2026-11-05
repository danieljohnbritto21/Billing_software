#!/usr/bin/env bash
# ==============================================================================
# FoodBill Pro — Automated Database & Image Backup with Multi-Tier Rotation
# Target: PostgreSQL 16 on port 5433 (WSL2 FoodBill-Ubuntu) + Product Images
# Retention: 7 Daily, 4 Weekly, 4 Monthly
# Safety: Strict verification with pg_restore -l before rotation
# ==============================================================================

set -euo pipefail

DB_NAME="foodbill"
DB_PORT="5433"
BACKUP_BASE="/mnt/d/foodbill_backups/database"
LOG_DIR="/mnt/d/foodbill_backups/logs"
LOG_FILE="${LOG_DIR}/backup.log"
IMAGE_DIR="/mnt/d/foodbill_storage/images"

DAILY_DIR="${BACKUP_BASE}/daily"
WEEKLY_DIR="${BACKUP_BASE}/weekly"
MONTHLY_DIR="${BACKUP_BASE}/monthly"

DAILY_RETENTION=7
WEEKLY_RETENTION=4
MONTHLY_RETENTION=4

mkdir -p "${DAILY_DIR}" "${WEEKLY_DIR}" "${MONTHLY_DIR}" "${LOG_DIR}"

log() {
  local level="$1"
  local msg="$2"
  local timestamp
  timestamp=$(date +"%Y-%m-%dT%H:%M:%S%z")
  echo "[${timestamp}] [${level}] ${msg}" | tee -a "${LOG_FILE}"
}

log "INFO" "Starting FoodBill Pro automated database & image backup..."

# Verify PostgreSQL is online and accepting connections
if ! pg_isready -p "${DB_PORT}" -h 127.0.0.1 >/dev/null 2>&1; then
  log "ERROR" "PostgreSQL is not reachable on port ${DB_PORT}. Backup aborted."
  exit 1
fi

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
TEMP_DUMP="${DAILY_DIR}/.tmp_foodbill_${TIMESTAMP}.dump"
FINAL_DAILY="${DAILY_DIR}/foodbill_daily_${TIMESTAMP}.dump"

# 1. Execute pg_dump into temporary file
log "INFO" "Dumping database '${DB_NAME}' to temporary file..."
if ! pg_dump -p "${DB_PORT}" -Fc -d "${DB_NAME}" -f "${TEMP_DUMP}"; then
  log "ERROR" "pg_dump command failed for database '${DB_NAME}'."
  rm -f "${TEMP_DUMP}"
  exit 1
fi

# 2. Verify the temporary archive with pg_restore -l
log "INFO" "Verifying archive integrity with pg_restore -l..."
if ! pg_restore -l "${TEMP_DUMP}" >/dev/null 2>&1; then
  log "ERROR" "Archive verification failed! File is corrupted or unreadable. Aborting rotation."
  rm -f "${TEMP_DUMP}"
  exit 1
fi

# 3. Commit temporary file to daily backup
mv "${TEMP_DUMP}" "${FINAL_DAILY}"
FILE_SIZE=$(stat -c '%s' "${FINAL_DAILY}" 2>/dev/null || stat -f '%z' "${FINAL_DAILY}" 2>/dev/null || echo "unknown")
log "INFO" "Daily database backup created successfully: ${FINAL_DAILY} (${FILE_SIZE} bytes)."

# 3b. Backup persistent product images
if [ -d "${IMAGE_DIR}" ] && [ "$(ls -A "${IMAGE_DIR}" 2>/dev/null)" ]; then
  FINAL_IMAGES="${DAILY_DIR}/foodbill_images_${TIMESTAMP}.tar.gz"
  tar -czf "${FINAL_IMAGES}" -C "${IMAGE_DIR}" .
  log "INFO" "Product images archived to: ${FINAL_IMAGES}."
else
  log "INFO" "No product images found in ${IMAGE_DIR} to archive."
fi

# 4. Weekly Backup (copy on Sundays: day of week = 7)
DAY_OF_WEEK=$(date +%u)
if [ "${DAY_OF_WEEK}" -eq 7 ]; then
  FINAL_WEEKLY="${WEEKLY_DIR}/foodbill_weekly_${TIMESTAMP}.dump"
  cp "${FINAL_DAILY}" "${FINAL_WEEKLY}"
  log "INFO" "Sunday snapshot copied to weekly archive: ${FINAL_WEEKLY}."
  if [ -f "${DAILY_DIR}/foodbill_images_${TIMESTAMP}.tar.gz" ]; then
    cp "${DAILY_DIR}/foodbill_images_${TIMESTAMP}.tar.gz" "${WEEKLY_DIR}/foodbill_images_${TIMESTAMP}.tar.gz"
  fi
fi

# 5. Monthly Backup (copy on the 1st day of the month)
DAY_OF_MONTH=$(date +%d)
if [ "${DAY_OF_MONTH}" = "01" ]; then
  FINAL_MONTHLY="${MONTHLY_DIR}/foodbill_monthly_${TIMESTAMP}.dump"
  cp "${FINAL_DAILY}" "${FINAL_MONTHLY}"
  log "INFO" "First-of-month snapshot copied to monthly archive: ${FINAL_MONTHLY}."
  if [ -f "${DAILY_DIR}/foodbill_images_${TIMESTAMP}.tar.gz" ]; then
    cp "${DAILY_DIR}/foodbill_images_${TIMESTAMP}.tar.gz" "${MONTHLY_DIR}/foodbill_images_${TIMESTAMP}.tar.gz"
  fi
fi

# 6. Safe Rotation Helper (operates strictly within target directory)
rotate_backups() {
  local target_dir="$1"
  local pattern="$2"
  local keep_count="$3"
  local tier_name="$4"

  # Count existing backups matching pattern
  local total_files
  total_files=$(find "${target_dir}" -maxdepth 1 -name "${pattern}" -type f | wc -l)

  if [ "${total_files}" -gt "${keep_count}" ]; then
    local delete_count=$((total_files - keep_count))
    log "INFO" "Pruning ${delete_count} old ${tier_name} backup(s) exceeding retention limit of ${keep_count}..."

    # Find oldest files exceeding retention limit, sorted oldest first
    find "${target_dir}" -maxdepth 1 -name "${pattern}" -type f -printf "%T@ %p\n" \
      | sort -n \
      | head -n "${delete_count}" \
      | cut -d' ' -f2- \
      | while IFS= read -r old_file; do
          if [ -f "${old_file}" ]; then
            rm -f "${old_file}"
            log "INFO" "Removed old ${tier_name} backup: ${old_file}"
          fi
        done
  else
    log "INFO" "${tier_name} (${pattern}) retention within threshold (${total_files}/${keep_count})."
  fi
}

rotate_backups "${DAILY_DIR}" "foodbill_daily_*.dump" "${DAILY_RETENTION}" "Daily DB"
rotate_backups "${DAILY_DIR}" "foodbill_images_*.tar.gz" "${DAILY_RETENTION}" "Daily Images"
rotate_backups "${WEEKLY_DIR}" "foodbill_weekly_*.dump" "${WEEKLY_RETENTION}" "Weekly DB"
rotate_backups "${WEEKLY_DIR}" "foodbill_images_*.tar.gz" "${WEEKLY_RETENTION}" "Weekly Images"
rotate_backups "${MONTHLY_DIR}" "foodbill_monthly_*.dump" "${MONTHLY_RETENTION}" "Monthly DB"
rotate_backups "${MONTHLY_DIR}" "foodbill_images_*.tar.gz" "${MONTHLY_RETENTION}" "Monthly Images"

log "INFO" "FoodBill Pro database & image backup completed successfully."
exit 0
