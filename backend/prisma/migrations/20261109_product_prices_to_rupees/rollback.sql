-- Rollback Migration: 20261109_rollback_product_prices_to_rupees
BEGIN;

DROP INDEX IF EXISTS "idx_products_selling_price_rupees";

ALTER TABLE "products"
DROP CONSTRAINT IF EXISTS "chk_products_cost_price_rupees_non_negative";

ALTER TABLE "products"
DROP CONSTRAINT IF EXISTS "chk_products_selling_price_rupees_non_negative";

ALTER TABLE "products"
DROP COLUMN IF EXISTS "cost_price_rupees";

ALTER TABLE "products"
DROP COLUMN IF EXISTS "selling_price_rupees";

COMMIT;
