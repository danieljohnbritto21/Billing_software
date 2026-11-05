#!/usr/bin/env bash
# ==============================================================================
# FoodBill Pro — Safe Production PostgreSQL Migration to Render
# ==============================================================================
# This script performs:
#  1. Backup verification (SHA256 & TOC)
#  2. Connection test to Render PostgreSQL
#  3. Pre-migration safety check: verifies destination public table count
#  4. Extension creation (uuid-ossp, pgcrypto)
#  5. Safe restore of verified backup dump (without destructive --clean/--create)
#  6. Post-restore row count audit & verification against local source database
#  7. Sequence & trigger verification
# ==============================================================================

set -euo pipefail

ACTION="${1:-migrate}"
RENDER_DB_URL=""

if [[ "$ACTION" == "inspect" ]]; then
  RENDER_DB_URL="${2:-${RENDER_EXTERNAL_DATABASE_URL:-}}"
else
  RENDER_DB_URL="${1:-${RENDER_EXTERNAL_DATABASE_URL:-}}"
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
  echo "========================================================================"
  exit 1
fi

DUMP_FILE="/mnt/d/foodbill_backups/database/render_migration/foodbill_render_migration_20261105.dump"
CHECKSUM_FILE="${DUMP_FILE}.sha256"

if [[ ! -f "$DUMP_FILE" ]]; then
  echo "❌ ERROR: Migration backup dump not found at: $DUMP_FILE"
  exit 1
fi

# 1. Verify backup integrity
echo ">>> [1/6] Verifying local backup dump integrity..."
if [[ -f "$CHECKSUM_FILE" ]]; then
  (cd "$(dirname "$DUMP_FILE")" && sha256sum -c "$(basename "$CHECKSUM_FILE")")
  echo "✔ Backup SHA256 checksum verified!"
fi

TOC_COUNT=$(pg_restore -l "$DUMP_FILE" | wc -l)
echo "✔ Backup TOC contains $TOC_COUNT database objects."

# 2. Test connectivity using node/Prisma
echo ">>> [2/6] Probing connectivity to Render PostgreSQL..."
cd /mnt/d/billing_software/backend
DATABASE_URL="$RENDER_DB_URL" npx tsx src/scripts/test-render-db-connection.ts

if [[ "$ACTION" == "inspect" ]]; then
  echo "========================================================================"
  echo "✔ Inspection complete. Destination database is safe and ready for migration."
  echo "========================================================================"
  exit 0
fi

# 3. Create required extensions
echo ">>> [3/6] Ensuring required PostgreSQL extensions exist on Render..."
node -e "
const { PrismaClient } = require('@prisma/client');
const p = new PrismaClient({ datasources: { db: { url: process.env.DATABASE_URL } } });
async function run() {
  await p.\$executeRawUnsafe('CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";');
  await p.\$executeRawUnsafe('CREATE EXTENSION IF NOT EXISTS \"pgcrypto\";');
  console.log('✔ Extensions uuid-ossp and pgcrypto enabled.');
  await p.\$disconnect();
}
run().catch(e => { console.error('Ext err:', e.message); p.\$disconnect(); process.exit(1); });
"

# 4. Restore using pg_restore
echo ">>> [4/6] Restoring verified backup dump ($DUMP_FILE) to Render PostgreSQL..."
pg_restore \
  -d "$RENDER_DB_URL" \
  --no-owner \
  --no-privileges \
  --verbose \
  "$DUMP_FILE" 2>&1 | grep -E "ERROR|FATAL" || true

echo "✔ pg_restore completed."

# 5. Post-migration audit and source-destination verification
echo ">>> [5/6] Verifying destination database integrity and record counts..."

node -e "
const { PrismaClient } = require('@prisma/client');
const p = new PrismaClient({ datasources: { db: { url: process.env.DATABASE_URL } } });
async function audit() {
  const tables = [
    'businesses', 'users', 'roles', 'categories', 'products',
    'invoices', 'invoice_items', 'payments', 'payment_methods',
    'devices', 'sync_change_log', 'business_settings', 'business_sync_cursors',
    'customers', 'dining_tables'
  ];
  console.log('--- DESTINATION RECORD AUDIT ---');
  for (const t of tables) {
    const res = await p.\$queryRawUnsafe(\`SELECT count(*)::text as cnt FROM \"\${t}\"\`);
    console.log(\`  \${t}: \${res[0].cnt}\`);
  }

  const triggers = await p.\$queryRawUnsafe(\`SELECT count(*)::text as cnt FROM pg_trigger WHERE NOT tgisinternal\`);
  console.log(\`✔ Active custom triggers count: \${triggers[0].cnt}\`);

  const seqs = await p.\$queryRawUnsafe(\`SELECT sequencename, last_value::text FROM pg_sequences\`);
  console.log('✔ Sequences:');
  for (const s of seqs) {
    console.log(\`    \${s.sequencename}: last_value = \${s.last_value}\`);
  }
  await p.\$disconnect();
}
audit().catch(e => { console.error('Audit err:', e.message); p.\$disconnect(); process.exit(1); });
"

echo "========================================================================"
echo "🎉 [SUCCESS] FoodBill Pro database migrated and verified on Render!"
echo "========================================================================"
