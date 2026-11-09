-- Migration: 20261109_kot_procurement_linking
-- Allows KOT records to link to purchase invoices (procurement) in addition to customer sales invoices

-- 1. Allow invoice_id in kot_records to be NULL (for procurement KOTs)
ALTER TABLE "kot_records" ALTER COLUMN "invoice_id" DROP NOT NULL;

-- 2. Add purchase_invoice_id, supplier_invoice_number, business_id to kot_records
ALTER TABLE "kot_records" ADD COLUMN IF NOT EXISTS "purchase_invoice_id" UUID REFERENCES "purchase_invoices"("id") ON DELETE CASCADE;
ALTER TABLE "kot_records" ADD COLUMN IF NOT EXISTS "supplier_invoice_number" VARCHAR(80);
ALTER TABLE "kot_records" ADD COLUMN IF NOT EXISTS "business_id" UUID REFERENCES "businesses"("id") ON DELETE CASCADE;

-- 3. Backfill business_id for existing sales KOT records from invoices
UPDATE "kot_records" k
SET "business_id" = i."business_id"
FROM "invoices" i
WHERE k."invoice_id" = i."id"
  AND k."business_id" IS NULL;

-- 4. Add product_id and unit to kot_items
ALTER TABLE "kot_items" ADD COLUMN IF NOT EXISTS "product_id" UUID REFERENCES "products"("id") ON DELETE SET NULL;
ALTER TABLE "kot_items" ADD COLUMN IF NOT EXISTS "unit" VARCHAR(30) DEFAULT 'unit';

-- 5. Create indexes
CREATE INDEX IF NOT EXISTS "idx_kot_records_purchase_invoice" ON "kot_records"("purchase_invoice_id");
CREATE INDEX IF NOT EXISTS "idx_kot_records_business" ON "kot_records"("business_id");
CREATE INDEX IF NOT EXISTS "idx_kot_items_product" ON "kot_items"("product_id");
