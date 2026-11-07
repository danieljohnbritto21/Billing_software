-- ==============================================================================
-- FoodBill Pro: Rollback Script for Migration 005
-- Target: PostgreSQL 18
-- Safety: Reverts schema additions without dropping core historical tables
-- ==============================================================================

BEGIN;

-- Drop triggers on new tables
DROP TRIGGER IF EXISTS trg_supplier_payments_sync_version ON public.supplier_payments;
DROP TRIGGER IF EXISTS trg_purchase_invoices_sync_version ON public.purchase_invoices;
DROP TRIGGER IF EXISTS trg_purchase_orders_sync_version ON public.purchase_orders;
DROP TRIGGER IF EXISTS trg_orders_sync_version ON public.orders;
DROP TRIGGER IF EXISTS trg_suppliers_sync_version ON public.suppliers;

-- Drop purchase management tables
DROP TABLE IF EXISTS public.supplier_payments CASCADE;
DROP TABLE IF EXISTS public.purchase_invoice_items CASCADE;
DROP TABLE IF EXISTS public.purchase_invoices CASCADE;
DROP TABLE IF EXISTS public.purchase_order_items CASCADE;
DROP TABLE IF EXISTS public.purchase_orders CASCADE;

-- Drop KOT items
DROP TABLE IF EXISTS public.kot_items CASCADE;

-- Remove added foreign keys from invoices and payments
ALTER TABLE public.payments DROP COLUMN IF EXISTS order_id;
ALTER TABLE public.invoice_items DROP COLUMN IF EXISTS order_item_id;
ALTER TABLE public.invoices DROP COLUMN IF EXISTS order_id;
ALTER TABLE public.kot_records DROP COLUMN IF EXISTS order_id;

-- Drop central sales orders
DROP TABLE IF EXISTS public.order_items CASCADE;
DROP TABLE IF EXISTS public.orders CASCADE;

-- Remove supplier foreign keys from products and users
ALTER TABLE public.products DROP CONSTRAINT IF EXISTS fk_products_supplier_business;
ALTER TABLE public.products DROP COLUMN IF EXISTS supplier_id;

ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_supplier_id_fkey;
ALTER TABLE public.users DROP COLUMN IF EXISTS supplier_id;
ALTER TABLE public.users DROP COLUMN IF EXISTS deleted_at;

-- Revert user roles
UPDATE public.users SET role_id = 'admin' WHERE role_id = 'ADMIN';
UPDATE public.users SET role_id = 'cashier', is_active = TRUE WHERE role_id = 'CASHIER_LEGACY';

-- Drop suppliers table
DROP TABLE IF EXISTS public.suppliers CASCADE;

-- Clean up roles
DELETE FROM public.roles WHERE id IN ('SUPPLIER', 'CASHIER_LEGACY');

COMMIT;
