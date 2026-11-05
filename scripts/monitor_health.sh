#!/usr/bin/env bash
# ==============================================================================
# FoodBill Pro — Service Health & Disk Space Monitor
# Checks: PostgreSQL 16 (5433), Node.js API (3000/health), Disk & RAM thresholds
# ==============================================================================

set -euo pipefail

LOG_DIR="/mnt/d/foodbill_storage/logs"
LOG_FILE="${LOG_DIR}/monitor.log"
mkdir -p "${LOG_DIR}"

log() {
  local level="$1"
  local msg="$2"
  local timestamp
  timestamp=$(date +"%Y-%m-%dT%H:%M:%S%z")
  echo "[${timestamp}] [${level}] ${msg}" | tee -a "${LOG_FILE}"
}

FAILURES=0

# 1. PostgreSQL 16 Check
if pg_isready -p 5433 -h 127.0.0.1 >/dev/null 2>&1; then
  log "INFO" "PostgreSQL 16 (port 5433): OK"
else
  log "ERROR" "PostgreSQL 16 (port 5433): DOWN or unresponsive!"
  FAILURES=$((FAILURES + 1))
fi

# 2. Node.js Backend Health Check
HEALTH_JSON=$(curl -s -m 5 http://127.0.0.1:3000/health || echo "")
if echo "${HEALTH_JSON}" | grep -q '"status":"UP"'; then
  log "INFO" "Backend API (port 3000): OK (${HEALTH_JSON})"
else
  log "WARN" "Backend API (port 3000): NOT RESPONDING or DOWN"
  # Backend might not be running if testing offline
fi

# 3. Disk Space Monitoring (Root / and Windows /mnt/d)
check_disk() {
  local mount_point="$1"
  local name="$2"
  local usage
  usage=$(df -h "${mount_point}" | awk 'NR==2 {print $5}' | tr -d '%')
  if [ "${usage}" -ge 85 ]; then
    log "WARN" "High disk usage on ${name} (${mount_point}): ${usage}% full!"
  else
    log "INFO" "Disk usage on ${name} (${mount_point}): ${usage}% (normal)"
  fi
}

check_disk "/" "WSL Root"
check_disk "/mnt/d" "Windows D: Drive"

# 4. Memory check
MEM_AVAIL=$(free -m | awk '/^Mem:/ {print $7}')
log "INFO" "Available system RAM: ${MEM_AVAIL} MiB"

if [ "${FAILURES}" -eq 0 ]; then
  log "INFO" "Overall System Health: HEALTHY"
  exit 0
else
  log "ERROR" "Overall System Health: ${FAILURES} failure(s) detected!"
  exit 1
fi
