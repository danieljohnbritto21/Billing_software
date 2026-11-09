-- ====================================================================
-- FOODBILL PRO: UNIFIED TRANSACTION LINKING MIGRATION (FORWARD)
-- Adds transaction_id to orders, invoices, kot_records, purchase_orders, purchase_invoices
-- Backfills existing data safely without data loss or dropping columns
-- ====================================================================

BEGIN;

-- 1. ADD transaction_id COLUMNS SAFELY
ALTER TABLE "orders"
  ADD COLUMN IF NOT EXISTS "transaction_id" UUID;

ALTER TABLE "invoices"
  ADD COLUMN IF NOT EXISTS "transaction_id" UUID;

ALTER TABLE "kot_records"
  ADD COLUMN IF NOT EXISTS "transaction_id" UUID;

ALTER TABLE "purchase_orders"
  ADD COLUMN IF NOT EXISTS "transaction_id" UUID;

ALTER TABLE "purchase_invoices"
  ADD COLUMN IF NOT EXISTS "transaction_id" UUID;

-- 2. BACKFILL SALES DOMAIN (orders, invoices, kot_records)
-- For orders: transaction_id defaults to order id
UPDATE "orders"
SET "transaction_id" = "id"
WHERE "transaction_id" IS NULL;

-- For invoices: use order_id if present, otherwise invoice id
UPDATE "invoices"
SET "transaction_id" = COALESCE("order_id", "id")
WHERE "transaction_id" IS NULL;

-- For kot_records: resolve from order_id or linked invoice
UPDATE "kot_records" k
SET "transaction_id" = COALESCE(k."order_id", i."order_id", i."id", k."invoice_id", k."id")
FROM "invoices" i
WHERE k."invoice_id" = i."id" AND k."transaction_id" IS NULL;

UPDATE "kot_records"
SET "transaction_id" = COALESCE("order_id", "invoice_id", "id")
WHERE "transaction_id" IS NULL;

-- 3. BACKFILL PROCUREMENT DOMAIN (purchase_orders, purchase_invoices)
-- Purchase orders: transaction_id defaults to po id
UPDATE "purchase_orders"
SET "transaction_id" = "id"
WHERE "transaction_id" IS NULL;

-- Purchase invoices: use purchase_order_id if present, otherwise purchase invoice id
UPDATE "purchase_invoices"
SET "transaction_id" = COALESCE("purchase_order_id", "id")
WHERE "transaction_id" IS NULL;

-- 4. CREATE HIGH-PERFORMANCE INDEXES
CREATE INDEX IF NOT EXISTS "idx_orders_transaction_id"
  ON "orders"("business_id", "transaction_id");

CREATE INDEX IF NOT EXISTS "idx_invoices_transaction_id"
  ON "invoices"("business_id", "transaction_id");

CREATE INDEX IF NOT EXISTS "idx_kot_records_transaction_id"
  ON "kot_records"("transaction_id");

CREATE INDEX IF NOT EXISTS "idx_purchase_orders_transaction_id"
  ON "purchase_orders"("business_id", "transaction_id");

CREATE INDEX IF NOT EXISTS "idx_purchase_invoices_transaction_id"
  ON "purchase_invoices"("business_id", "transaction_id");

COMMIT;
