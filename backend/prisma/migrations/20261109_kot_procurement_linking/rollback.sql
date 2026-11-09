DROP INDEX IF EXISTS "idx_kot_items_product";
DROP INDEX IF EXISTS "idx_kot_records_business";
DROP INDEX IF EXISTS "idx_kot_records_purchase_invoice";

ALTER TABLE "kot_items" DROP COLUMN IF EXISTS "unit";
ALTER TABLE "kot_items" DROP COLUMN IF EXISTS "product_id";

ALTER TABLE "kot_records" DROP COLUMN IF EXISTS "business_id";
ALTER TABLE "kot_records" DROP COLUMN IF EXISTS "supplier_invoice_number";
ALTER TABLE "kot_records" DROP COLUMN IF EXISTS "purchase_invoice_id";
