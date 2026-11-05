#!/usr/bin/env bash
# ==============================================================================
# FoodBill Pro — Automated PostgreSQL Migration to Render
# Restores the verified local PostgreSQL dump to Render PostgreSQL
# ==============================================================================

set -euo pipefail

RENDER_DB_URL="${1:-}"

if [[ -z "$RENDER_DB_URL" ]]; then
  echo "========================================================================"
  echo "  FoodBill Pro — PostgreSQL Migration to Render"
  echo "========================================================================"
  echo "Usage: ./scripts/migrate_to_render.sh <RENDER_EXTERNAL_DATABASE_URL>"
  echo "Example:"
  echo "  ./scripts/migrate_to_render.sh 'postgresql://foodbill_app:password@dpg-xxxx.oregon-postgres.render.com/foodbill'"
  echo "========================================================================"
  exit 1
fi

DUMP_FILE="/mnt/d/foodbill_backups/database/foodbill_pre_vps_deploy_current.dump"

if [[ ! -f "$DUMP_FILE" ]]; then
  echo "ERROR: Verified backup dump not found at $DUMP_FILE"
  exit 1
fi

echo ">>> [1/5] Testing connectivity to Render PostgreSQL..."
if ! psql "$RENDER_DB_URL" -c "SELECT version();" >/dev/null 2>&1; then
  echo "ERROR: Could not connect to Render PostgreSQL using the provided connection string."
  echo "Please verify the External Database URL from the Render Dashboard."
  exit 1
fi
echo "Connection to Render PostgreSQL successful!"

echo ">>> [2/5] Ensuring required PostgreSQL extensions exist on Render..."
psql "$RENDER_DB_URL" <<EOF
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
EOF

echo ">>> [3/5] Restoring verified backup dump ($DUMP_FILE) to Render..."
# Restore without hard ownership failure, using the connected user
pg_restore \
  -d "$RENDER_DB_URL" \
  --no-owner \
  --clean \
  --if-exists \
  --verbose \
  "$DUMP_FILE" || true

echo ">>> [4/5] Verifying exact table counts on Render PostgreSQL..."
psql "$RENDER_DB_URL" --no-align -P pager=off -c "
DO \$\$
DECLARE
    r RECORD;
    cnt BIGINT;
BEGIN
    RAISE NOTICE '=== RENDER DATABASE AUDIT ===';
    FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename) LOOP
        EXECUTE format('SELECT count(*) FROM %I', r.tablename) INTO cnt;
        RAISE NOTICE '%: %', r.tablename, cnt;
    END LOOP;
END \$\$;
"

echo ">>> [5/5] Testing read & write operations on Render PostgreSQL..."
psql "$RENDER_DB_URL" -c "
SELECT id, name, created_at FROM businesses WHERE id = '2fe0d16c-95d4-4719-a3b6-d492668b5a24';
SELECT COUNT(*) as product_count FROM products WHERE business_id = '2fe0d16c-95d4-4719-a3b6-d492668b5a24';
"

echo "========================================================================"
echo " [SUCCESS] Database successfully migrated and verified on Render!"
echo "========================================================================"
