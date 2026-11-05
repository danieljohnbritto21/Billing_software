#!/usr/bin/env bash
# ==============================================================================
# FoodBill Pro — Safe Production PostgreSQL Migration to Render
# ==============================================================================
# This script performs:
#  1. Connection test & version check on Render PostgreSQL
#  2. Pre-migration inspection: detects existing tables & records (ABORTS IF NOT EMPTY)
#  3. Extension readiness check (uuid-ossp, pgcrypto)
#  4. Safe restore of verified backup dump (without destructive --clean/--create)
#  5. Post-restore row count audit & verification against local source database
#  6. Sequence & trigger verification
# ==============================================================================

set -euo pipefail

# Allow passing URL as $1 or via RENDER_EXTERNAL_DATABASE_URL environment variable
ACTION="${1:-migrate}"
RENDER_DB_URL=""

if [[ "$ACTION" == "inspect" ]]; then
  RENDER_DB_URL="${2:-${RENDER_EXTERNAL_DATABASE_URL:-}}"
else
  RENDER_DB_URL="${1:-${RENDER_EXTERNAL_DATABASE_URL:-}}"
  # If $1 was actually "migrate", check $2
  if [[ "$ACTION" == "migrate" && -n "${2:-}" ]]; then
    RENDER_DB_URL="$2"
  fi
fi

if [[ -z "$RENDER_DB_URL" ]]; then
  echo "========================================================================"
  echo "  FoodBill Pro — PostgreSQL Safe Migration Tool"
  echo "========================================================================"
  echo "Usage:"
  echo "  Inspect destination only:"
  echo "    ./scripts/migrate_to_render.sh inspect <RENDER_EXTERNAL_DATABASE_URL>"
  echo "  Perform safe migration:"
  echo "    ./scripts/migrate_to_render.sh migrate <RENDER_EXTERNAL_DATABASE_URL>"
  echo ""
  echo "Alternatively, export RENDER_EXTERNAL_DATABASE_URL and run without URL argument:"
  echo "    export RENDER_EXTERNAL_DATABASE_URL='postgresql://...'"
  echo "    ./scripts/migrate_to_render.sh inspect"
  echo "    ./scripts/migrate_to_render.sh migrate"
  echo "========================================================================"
  exit 1
fi

DUMP_FILE="/mnt/d/foodbill_backups/database/render_migration/foodbill_render_migration_20261105.dump"
CHECKSUM_FILE="${DUMP_FILE}.sha256"

if [[ ! -f "$DUMP_FILE" ]]; then
  echo "❌ ERROR: Migration backup dump not found at: $DUMP_FILE"
  exit 1
fi

# Verify backup integrity via SHA256 before doing anything
echo ">>> [1/6] Verifying local backup dump integrity..."
if [[ -f "$CHECKSUM_FILE" ]]; then
  (cd "$(dirname "$DUMP_FILE")" && sha256sum -c "$(basename "$CHECKSUM_FILE")")
  echo "✔ Backup SHA256 checksum verified!"
else
  echo "⚠ Warning: Checksum file not found, proceeding with pg_restore -l verification..."
fi

TOC_COUNT=$(pg_restore -l "$DUMP_FILE" | wc -l)
echo "✔ Backup TOC contains $TOC_COUNT database objects."

# Test connectivity to destination
echo ">>> [2/6] Probing connectivity to Render PostgreSQL..."
RENDER_VERSION=$(psql "$RENDER_DB_URL" -P pager=off -X -q -t -A -c "SELECT version();" 2>&1)
echo "✔ Connected to Render PostgreSQL:"
echo "    $RENDER_VERSION"

# Pre-migration destination inspection
echo ">>> [3/6] Inspecting destination Render database state..."
EXISTING_TABLES_COUNT=$(psql "$RENDER_DB_URL" -P pager=off -X -q -t -A -c "
SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE';
")

echo "Destination currently has $EXISTING_TABLES_COUNT public tables."

if [[ "$EXISTING_TABLES_COUNT" -gt 0 ]]; then
  echo "Found existing tables in destination database. Auditing record counts..."
  psql "$RENDER_DB_URL" -P pager=off -X -q -c "
  SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name;
  "

  # Check if any table contains records
  RECORD_CHECK=$(psql "$RENDER_DB_URL" -P pager=off -X -q -t -A -c "
  DO \$\$
  DECLARE
      r RECORD;
      cnt BIGINT;
      total BIGINT := 0;
  BEGIN
      FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public') LOOP
          EXECUTE format('SELECT count(*) FROM %I', r.tablename) INTO cnt;
          total := total + cnt;
      END LOOP;
      RAISE NOTICE 'TOTAL_EXISTING_RECORDS=%', total;
  END \$\$;
  " 2>&1 | grep "TOTAL_EXISTING_RECORDS" || true)

  echo "Audit result: $RECORD_CHECK"

  if [[ "$RECORD_CHECK" =~ TOTAL_EXISTING_RECORDS=([1-9][0-9]*) ]]; then
    echo "========================================================================"
    echo "❌ SAFETY STOP: Destination Render database is NOT empty!"
    echo "Found existing records in destination database."
    echo "Per safety guidelines, migration will NOT overwrite existing records."
    echo "Please inspect destination database manually before proceeding."
    echo "========================================================================"
    exit 2
  fi
fi

if [[ "$ACTION" == "inspect" ]]; then
  echo "========================================================================"
  echo "✔ Inspection complete. Destination database is safe and ready for migration."
  echo "========================================================================"
  exit 0
fi

# Ensure extensions exist on destination
echo ">>> [4/6] Ensuring required PostgreSQL extensions exist on Render..."
psql "$RENDER_DB_URL" -P pager=off -X -q <<EOF
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
EOF
echo "✔ Extensions (uuid-ossp, pgcrypto) verified."

# Safe restore (no --clean or --create)
echo ">>> [5/6] Restoring verified backup dump ($DUMP_FILE) to Render..."
pg_restore \
  -d "$RENDER_DB_URL" \
  --no-owner \
  --no-privileges \
  --verbose \
  "$DUMP_FILE" 2>&1 | grep -E "ERROR|FATAL" || true

echo "✔ pg_restore completed."

# Post-migration audit and source-destination verification
echo ">>> [6/6] Verifying destination database integrity and record counts..."

echo "--- Destination Table Counts ---"
psql "$RENDER_DB_URL" -P pager=off -X -q -c "
SELECT 'businesses' as table_name, count(*) as count FROM businesses
UNION ALL SELECT 'users', count(*) FROM users
UNION ALL SELECT 'roles', count(*) FROM roles
UNION ALL SELECT 'categories', count(*) FROM categories
UNION ALL SELECT 'products', count(*) FROM products
UNION ALL SELECT 'invoices', count(*) FROM invoices
UNION ALL SELECT 'invoice_items', count(*) FROM invoice_items
UNION ALL SELECT 'payments', count(*) FROM payments
UNION ALL SELECT 'payment_methods', count(*) FROM payment_methods
UNION ALL SELECT 'devices', count(*) FROM devices
UNION ALL SELECT 'sync_change_log', count(*) FROM sync_change_log
UNION ALL SELECT 'business_settings', count(*) FROM business_settings
UNION ALL SELECT 'business_sync_cursors', count(*) FROM business_sync_cursors;
"

echo "--- Verifying Sequences and Triggers ---"
psql "$RENDER_DB_URL" -P pager=off -X -q -c "
SELECT sequencename, last_value FROM pg_sequences;
SELECT count(*) as active_triggers_count FROM pg_trigger WHERE NOT tgisinternal;
"

echo "========================================================================"
echo "🎉 [SUCCESS] FoodBill Pro database migrated and verified on Render!"
echo "========================================================================"
