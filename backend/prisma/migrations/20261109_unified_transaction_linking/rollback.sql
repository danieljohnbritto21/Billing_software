-- ====================================================================
-- FOODBILL PRO: UNIFIED TRANSACTION LINKING ROLLBACK
-- Safely removes transaction_id indexes and columns
-- ====================================================================

BEGIN;

DROP INDEX IF EXISTS "idx_purchase_invoices_transaction_id";
DROP INDEX IF EXISTS "idx_purchase_orders_transaction_id";
DROP INDEX IF EXISTS "idx_kot_records_transaction_id";
DROP INDEX IF EXISTS "idx_invoices_transaction_id";
DROP INDEX IF EXISTS "idx_orders_transaction_id";

ALTER TABLE "purchase_invoices" DROP COLUMN IF EXISTS "transaction_id";
ALTER TABLE "purchase_orders" DROP COLUMN IF EXISTS "transaction_id";
ALTER TABLE "kot_records" DROP COLUMN IF EXISTS "transaction_id";
ALTER TABLE "invoices" DROP COLUMN IF EXISTS "transaction_id";
ALTER TABLE "orders" DROP COLUMN IF EXISTS "transaction_id";

COMMIT;
