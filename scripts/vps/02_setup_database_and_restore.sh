#!/usr/bin/env bash
# ==============================================================================
# FoodBill Pro — VPS Production Deployment: Stage 2 (Database Setup & Restore)
# Target: PostgreSQL 16 on Ubuntu VPS (Private 127.0.0.1:5432)
# ==============================================================================

set -euo pipefail

DB_NAME="foodbill"
DB_USER="foodbill_app"
DB_PORT="5432"
DUMP_FILE="${1:-/tmp/foodbill_pre_vps_deploy_current.dump}"

if [[ ! -f "$DUMP_FILE" ]]; then
  echo "ERROR: Dump file not found at $DUMP_FILE"
  echo "Usage: $0 /path/to/foodbill_pre_vps_deploy_current.dump [DB_PASSWORD]"
  exit 1
fi

DB_PASS="${2:-6daf278e1677e434dace085bf55f60efc915f47f94e09379e93719fc916da6c9}"

echo ">>> [1/4] Configuring PostgreSQL Role and Database..."
sudo -u postgres psql -p "$DB_PORT" <<EOF
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '$DB_USER') THEN
    CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASS' NOSUPERUSER NOCREATEDB NOCREATEROLE;
  ELSE
    ALTER ROLE $DB_USER WITH PASSWORD '$DB_PASS';
  END IF;
END \$\$;

SELECT 'Database already exists' WHERE EXISTS (SELECT FROM pg_database WHERE datname = '$DB_NAME')\gexec
CREATE DATABASE $DB_NAME OWNER $DB_USER ENCODING 'UTF8';
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
EOF

echo ">>> [2/4] Restoring full verified database from $DUMP_FILE..."
# Restore schema and data using pg_restore
sudo -u postgres pg_restore \
  -p "$DB_PORT" \
  -d "$DB_NAME" \
  --no-owner \
  --role="$DB_USER" \
  --verbose \
  "$DUMP_FILE" || true

echo ">>> [3/4] Ensuring schema permissions and extensions..."
sudo -u postgres psql -p "$DB_PORT" -d "$DB_NAME" <<EOF
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
GRANT ALL ON SCHEMA public TO $DB_USER;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $DB_USER;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $DB_USER;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO $DB_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO $DB_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO $DB_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO $DB_USER;
EOF

echo ">>> [4/4] Verifying table counts in restored database..."
sudo -u postgres psql -p "$DB_PORT" -d "$DB_NAME" --no-align -P pager=off -c "
DO \$\$
DECLARE
    r RECORD;
    cnt BIGINT;
BEGIN
    RAISE NOTICE '=== RESTORED TABLE COUNTS ===';
    FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename) LOOP
        EXECUTE format('SELECT count(*) FROM %I', r.tablename) INTO cnt;
        RAISE NOTICE '%: %', r.tablename, cnt;
    END LOOP;
END \$\$;
"

echo ">>> [SUCCESS] PostgreSQL database restored and verified successfully!"
