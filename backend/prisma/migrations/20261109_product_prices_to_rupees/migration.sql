-- Migration: 20261109_product_prices_to_rupees
-- Description: Transition products master price storage from paise to exact NUMERIC(12,2) rupees
-- Financial Data Integrity: Historical invoice item snapshots (invoice_items, purchase_invoice_items) remain unchanged.

BEGIN;

-- 1. Add cost_price_rupees and selling_price_rupees columns to products table if not present
ALTER TABLE "products"
ADD COLUMN IF NOT EXISTS "cost_price_rupees" NUMERIC(12,2) DEFAULT 0.00;

ALTER TABLE "products"
ADD COLUMN IF NOT EXISTS "selling_price_rupees" NUMERIC(12,2) DEFAULT 0.00;

-- 2. Backfill existing product records from authoritative paise (paise / 100.0)
UPDATE "products"
SET
  "cost_price_rupees" = ROUND(COALESCE("cost_price_paise", 0)::numeric / 100.0, 2),
  "selling_price_rupees" = ROUND(COALESCE("selling_price_paise", 0)::numeric / 100.0, 2)
WHERE "cost_price_rupees" = 0.00 AND "selling_price_rupees" = 0.00;

-- 3. Enforce NOT NULL constraints on rupee price columns
ALTER TABLE "products"
ALTER COLUMN "cost_price_rupees" SET NOT NULL;

ALTER TABLE "products"
ALTER COLUMN "selling_price_rupees" SET NOT NULL;

-- 4. Enforce non-negative price constraints
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'chk_products_cost_price_rupees_non_negative'
  ) THEN
    ALTER TABLE "products"
    ADD CONSTRAINT "chk_products_cost_price_rupees_non_negative"
    CHECK ("cost_price_rupees" >= 0);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'chk_products_selling_price_rupees_non_negative'
  ) THEN
    ALTER TABLE "products"
    ADD CONSTRAINT "chk_products_selling_price_rupees_non_negative"
    CHECK ("selling_price_rupees" >= 0);
  END IF;
END $$;

-- 5. Create index for price range queries in reports and catalog filtering
CREATE INDEX IF NOT EXISTS "idx_products_selling_price_rupees"
ON "products" ("business_id", "selling_price_rupees");

COMMIT;
