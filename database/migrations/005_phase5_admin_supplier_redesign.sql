-- ==============================================================================
-- FoodBill Pro: Phase 5 Incremental Migration
-- Target: PostgreSQL 18
-- Author: Principal Architect
-- Safety: Non-destructive, backfill-aware, multi-business isolation
-- ==============================================================================

BEGIN;

-- ------------------------------------------------------------------------------
-- 1. Create suppliers table
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.suppliers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    supplier_code VARCHAR(60) NOT NULL,
    supplier_name VARCHAR(150) NOT NULL,
    contact_person VARCHAR(120),
    phone_number VARCHAR(30),
    email VARCHAR(120),
    address TEXT,
    gstin VARCHAR(20),
    notes TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ(6),
    server_version BIGINT,
    CONSTRAINT uq_supplier_code_business UNIQUE (business_id, supplier_code),
    CONSTRAINT uq_suppliers_business_id UNIQUE (business_id, id)
);

CREATE INDEX IF NOT EXISTS idx_suppliers_sync ON public.suppliers(business_id, server_version);

-- ------------------------------------------------------------------------------
-- 2. Backfill default in-house / direct supplier for each existing business
-- ------------------------------------------------------------------------------
INSERT INTO public.suppliers (id, business_id, supplier_code, supplier_name, contact_person, notes, is_active)
SELECT
    gen_random_uuid(),
    b.id,
    'SUP-DEFAULT',
    'In-House / Direct Supply',
    'Store Admin',
    'System-generated default supplier for legacy catalogue and in-house items',
    TRUE
FROM public.businesses b
ON CONFLICT (business_id, supplier_code) DO NOTHING;

-- ------------------------------------------------------------------------------
-- 3. Update roles table to enforce ADMIN and SUPPLIER
-- ------------------------------------------------------------------------------
INSERT INTO public.roles (id, description)
VALUES
    ('ADMIN', 'Full Business Administrator with complete operational authority'),
    ('SUPPLIER', 'Supplier account with self-managed catalogue and purchase orders'),
    ('CASHIER_LEGACY', 'Legacy cashier role preserved for historical audit')
ON CONFLICT (id) DO UPDATE SET description = EXCLUDED.description;

-- ------------------------------------------------------------------------------
-- 4. Alter users table: add supplier_id & audit columns
-- ------------------------------------------------------------------------------
ALTER TABLE public.users
    ADD COLUMN IF NOT EXISTS supplier_id UUID REFERENCES public.suppliers(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ(6);

-- Standardize existing roles: admin -> ADMIN, cashier -> CASHIER_LEGACY
UPDATE public.users SET role_id = 'ADMIN' WHERE role_id = 'admin';
UPDATE public.users SET role_id = 'CASHIER_LEGACY', is_active = FALSE WHERE role_id = 'cashier';

-- ------------------------------------------------------------------------------
-- 5. Alter products table: add supplier_id & bind existing products to default supplier
-- ------------------------------------------------------------------------------
ALTER TABLE public.products
    ADD COLUMN IF NOT EXISTS supplier_id UUID;

-- Backfill supplier_id from default in-house supplier
UPDATE public.products p
SET supplier_id = s.id
FROM public.suppliers s
WHERE p.business_id = s.business_id
  AND s.supplier_code = 'SUP-DEFAULT'
  AND p.supplier_id IS NULL;

-- Add foreign key constraint
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_products_supplier_business'
    ) THEN
        ALTER TABLE public.products
            ADD CONSTRAINT fk_products_supplier_business
            FOREIGN KEY (business_id, supplier_id)
            REFERENCES public.suppliers(business_id, id)
            ON DELETE SET NULL;
    END IF;
END $$;

-- ------------------------------------------------------------------------------
-- 6. Create central orders table
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    order_number VARCHAR(60) NOT NULL,
    created_by_user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    device_id UUID REFERENCES public.devices(id) ON DELETE SET NULL,
    dining_table_id UUID,
    order_type VARCHAR(40) NOT NULL DEFAULT 'Dine In',
    order_status VARCHAR(40) NOT NULL DEFAULT 'Completed',
    subtotal_paise BIGINT NOT NULL,
    item_discount_paise BIGINT NOT NULL DEFAULT 0,
    bill_discount_paise BIGINT NOT NULL DEFAULT 0,
    taxable_amount_paise BIGINT NOT NULL,
    total_tax_paise BIGINT NOT NULL DEFAULT 0,
    cgst_paise BIGINT NOT NULL DEFAULT 0,
    sgst_paise BIGINT NOT NULL DEFAULT 0,
    igst_paise BIGINT NOT NULL DEFAULT 0,
    round_off_paise BIGINT NOT NULL DEFAULT 0,
    grand_total_paise BIGINT NOT NULL,
    amount_paid_paise BIGINT NOT NULL DEFAULT 0,
    balance_due_paise BIGINT NOT NULL DEFAULT 0,
    payment_status VARCHAR(40) NOT NULL DEFAULT 'Paid',
    notes TEXT,
    ordered_at TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ(6),
    server_version BIGINT,
    CONSTRAINT uq_order_number_business UNIQUE (business_id, order_number),
    CONSTRAINT uq_orders_business_id UNIQUE (business_id, id)
);

CREATE INDEX IF NOT EXISTS idx_orders_sync ON public.orders(business_id, server_version);

-- ------------------------------------------------------------------------------
-- 7. Create order_items table
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL,
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
    supplier_id UUID,
    product_name_snapshot VARCHAR(150) NOT NULL,
    product_code_snapshot VARCHAR(60),
    quantity DECIMAL(10, 3) NOT NULL,
    unit VARCHAR(30) NOT NULL,
    unit_price_paise BIGINT NOT NULL,
    discount_paise BIGINT NOT NULL DEFAULT 0,
    gst_percentage_snapshot DECIMAL(5, 2) NOT NULL DEFAULT 0.00,
    taxable_amount_paise BIGINT NOT NULL,
    tax_amount_paise BIGINT NOT NULL,
    total_amount_paise BIGINT NOT NULL,
    special_instructions TEXT,
    created_at TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_order_items_order ON public.order_items(order_id);

-- ------------------------------------------------------------------------------
-- 8. Alter invoices & payments table to link with orders
-- ------------------------------------------------------------------------------
ALTER TABLE public.invoices
    ADD COLUMN IF NOT EXISTS order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL;

ALTER TABLE public.invoice_items
    ADD COLUMN IF NOT EXISTS order_item_id UUID REFERENCES public.order_items(id) ON DELETE SET NULL;

ALTER TABLE public.payments
    ADD COLUMN IF NOT EXISTS order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL;

ALTER TABLE public.kot_records
    ADD COLUMN IF NOT EXISTS order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE;

-- ------------------------------------------------------------------------------
-- 9. Backfill historical orders from existing 15 invoices
-- ------------------------------------------------------------------------------
-- Create order records corresponding to existing invoices
INSERT INTO public.orders (
    id,
    business_id,
    order_number,
    created_by_user_id,
    device_id,
    order_type,
    order_status,
    subtotal_paise,
    item_discount_paise,
    bill_discount_paise,
    taxable_amount_paise,
    total_tax_paise,
    cgst_paise,
    sgst_paise,
    igst_paise,
    round_off_paise,
    grand_total_paise,
    amount_paid_paise,
    balance_due_paise,
    payment_status,
    notes,
    ordered_at,
    created_at,
    updated_at
)
SELECT
    inv.id, -- reuse invoice UUID as order UUID for deterministic 1:1 mapping
    inv.business_id,
    inv.invoice_number,
    NULL,
    inv.device_id,
    COALESCE(inv.order_type, 'Dine In'),
    COALESCE(inv.order_status, 'Completed'),
    inv.subtotal_paise,
    inv.item_discount_total_paise,
    inv.bill_discount_paise,
    inv.taxable_amount_paise,
    (inv.cgst_paise + inv.sgst_paise + inv.igst_paise),
    inv.cgst_paise,
    inv.sgst_paise,
    inv.igst_paise,
    inv.round_off_paise,
    inv.grand_total_paise,
    inv.paid_amount_paise,
    (inv.grand_total_paise - inv.paid_amount_paise),
    inv.payment_status,
    inv.cancel_reason,
    inv.created_at,
    inv.created_at,
    inv.updated_at
FROM public.invoices inv
ON CONFLICT (business_id, order_number) DO NOTHING;

-- Link invoices.order_id to orders.id
UPDATE public.invoices
SET order_id = id
WHERE order_id IS NULL;

-- Backfill order_items from existing 30 invoice_items
INSERT INTO public.order_items (
    id,
    business_id,
    order_id,
    product_id,
    supplier_id,
    product_name_snapshot,
    product_code_snapshot,
    quantity,
    unit,
    unit_price_paise,
    discount_paise,
    gst_percentage_snapshot,
    taxable_amount_paise,
    tax_amount_paise,
    total_amount_paise,
    created_at,
    updated_at
)
SELECT
    ii.id, -- reuse invoice_item UUID
    inv.business_id,
    inv.id, -- order_id matches invoice.id
    ii.product_id,
    p.supplier_id,
    ii.product_name,
    ii.product_code,
    ii.quantity,
    ii.unit,
    ii.unit_price_paise,
    ii.discount_paise,
    ii.gst_rate_percent,
    ii.taxable_amount_paise,
    ii.tax_amount_paise,
    ii.total_amount_paise,
    ii.created_at,
    ii.created_at
FROM public.invoice_items ii
JOIN public.invoices inv ON ii.invoice_id = inv.id
LEFT JOIN public.products p ON ii.product_id = p.id
ON CONFLICT (id) DO NOTHING;

-- Link invoice_items.order_item_id with trigger bypass during structural migration
ALTER TABLE public.invoice_items DISABLE TRIGGER trg_protect_invoice_items;

UPDATE public.invoice_items
SET order_item_id = id
WHERE order_item_id IS NULL;

ALTER TABLE public.invoice_items ENABLE TRIGGER trg_protect_invoice_items;

-- Drop erroneous trigger on payments (payments has no updated_at column and syncs via parent invoice aggregate root)
DROP TRIGGER IF EXISTS trg_payments_sync_version ON public.payments;

-- Link payments.order_id to invoices.order_id
UPDATE public.payments p
SET order_id = inv.order_id
FROM public.invoices inv
WHERE p.invoice_id = inv.id
  AND p.order_id IS NULL;

-- ------------------------------------------------------------------------------
-- 10. Create kot_items table
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.kot_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kot_id UUID NOT NULL REFERENCES public.kot_records(id) ON DELETE CASCADE,
    order_item_id UUID REFERENCES public.order_items(id) ON DELETE SET NULL,
    product_name_snapshot VARCHAR(150) NOT NULL,
    quantity DECIMAL(10, 3) NOT NULL,
    special_instructions TEXT,
    item_status VARCHAR(30) NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_kot_items_kot ON public.kot_items(kot_id);

-- ------------------------------------------------------------------------------
-- 11. Create purchase management tables (Strict Separation of Purchases)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.purchase_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    supplier_id UUID NOT NULL,
    purchase_order_number VARCHAR(60) NOT NULL,
    created_by_user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    order_status VARCHAR(40) NOT NULL DEFAULT 'DRAFT',
    subtotal_paise BIGINT NOT NULL DEFAULT 0,
    discount_paise BIGINT NOT NULL DEFAULT 0,
    total_tax_paise BIGINT NOT NULL DEFAULT 0,
    grand_total_paise BIGINT NOT NULL DEFAULT 0,
    notes TEXT,
    ordered_at TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ(6),
    server_version BIGINT,
    CONSTRAINT uq_purchase_order_number_business UNIQUE (business_id, purchase_order_number),
    CONSTRAINT uq_purchase_orders_business_id UNIQUE (business_id, id),
    CONSTRAINT fk_po_supplier_business FOREIGN KEY (business_id, supplier_id) REFERENCES public.suppliers(business_id, id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_purchase_orders_sync ON public.purchase_orders(business_id, server_version);

CREATE TABLE IF NOT EXISTS public.purchase_order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    purchase_order_id UUID NOT NULL REFERENCES public.purchase_orders(id) ON DELETE CASCADE,
    product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
    product_name_snapshot VARCHAR(150) NOT NULL,
    quantity DECIMAL(10, 3) NOT NULL,
    unit_price_paise BIGINT NOT NULL,
    gst_percentage_snapshot DECIMAL(5, 2) NOT NULL DEFAULT 0.00,
    tax_amount_paise BIGINT NOT NULL DEFAULT 0,
    total_amount_paise BIGINT NOT NULL,
    created_at TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_purchase_order_items_po ON public.purchase_order_items(purchase_order_id);

CREATE TABLE IF NOT EXISTS public.purchase_invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    supplier_id UUID NOT NULL,
    purchase_order_id UUID REFERENCES public.purchase_orders(id) ON DELETE SET NULL,
    supplier_invoice_number VARCHAR(80) NOT NULL,
    internal_reference_number VARCHAR(80),
    invoice_date TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    subtotal_paise BIGINT NOT NULL DEFAULT 0,
    discount_paise BIGINT NOT NULL DEFAULT 0,
    tax_amount_paise BIGINT NOT NULL DEFAULT 0,
    grand_total_paise BIGINT NOT NULL,
    amount_paid_paise BIGINT NOT NULL DEFAULT 0,
    balance_due_paise BIGINT NOT NULL DEFAULT 0,
    invoice_status VARCHAR(40) NOT NULL DEFAULT 'RECEIVED',
    payment_status VARCHAR(40) NOT NULL DEFAULT 'UNPAID',
    created_at TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ(6),
    server_version BIGINT,
    CONSTRAINT uq_supplier_invoice_unique UNIQUE (business_id, supplier_id, supplier_invoice_number),
    CONSTRAINT uq_purchase_invoices_business_id UNIQUE (business_id, id),
    CONSTRAINT fk_pi_supplier_business FOREIGN KEY (business_id, supplier_id) REFERENCES public.suppliers(business_id, id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_purchase_invoices_sync ON public.purchase_invoices(business_id, server_version);

CREATE TABLE IF NOT EXISTS public.purchase_invoice_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    purchase_invoice_id UUID NOT NULL REFERENCES public.purchase_invoices(id) ON DELETE CASCADE,
    product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
    product_name_snapshot VARCHAR(150) NOT NULL,
    quantity DECIMAL(10, 3) NOT NULL,
    unit_price_paise BIGINT NOT NULL,
    gst_percentage_snapshot DECIMAL(5, 2) NOT NULL DEFAULT 0.00,
    tax_amount_paise BIGINT NOT NULL DEFAULT 0,
    total_amount_paise BIGINT NOT NULL,
    created_at TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_purchase_invoice_items_pi ON public.purchase_invoice_items(purchase_invoice_id);

CREATE TABLE IF NOT EXISTS public.supplier_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    supplier_id UUID NOT NULL,
    purchase_invoice_id UUID REFERENCES public.purchase_invoices(id) ON DELETE SET NULL,
    amount_paise BIGINT NOT NULL,
    payment_method_id VARCHAR(40) NOT NULL REFERENCES public.payment_methods(id),
    payment_reference VARCHAR(100),
    payment_status VARCHAR(30) NOT NULL DEFAULT 'COMPLETED',
    paid_by_user_id UUID,
    paid_at TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    notes TEXT,
    created_at TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    server_version BIGINT,
    CONSTRAINT fk_sp_supplier_business FOREIGN KEY (business_id, supplier_id) REFERENCES public.suppliers(business_id, id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_supplier_payments_sync ON public.supplier_payments(business_id, server_version);

-- ------------------------------------------------------------------------------
-- 12. Add triggers for synchronization version bumping on new entities
-- ------------------------------------------------------------------------------
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'fn_bump_sync_version') THEN
        DROP TRIGGER IF EXISTS trg_suppliers_sync_version ON public.suppliers;
        CREATE TRIGGER trg_suppliers_sync_version
        BEFORE INSERT OR UPDATE ON public.suppliers
        FOR EACH ROW EXECUTE FUNCTION public.fn_bump_sync_version();

        DROP TRIGGER IF EXISTS trg_orders_sync_version ON public.orders;
        CREATE TRIGGER trg_orders_sync_version
        BEFORE INSERT OR UPDATE ON public.orders
        FOR EACH ROW EXECUTE FUNCTION public.fn_bump_sync_version();

        DROP TRIGGER IF EXISTS trg_purchase_orders_sync_version ON public.purchase_orders;
        CREATE TRIGGER trg_purchase_orders_sync_version
        BEFORE INSERT OR UPDATE ON public.purchase_orders
        FOR EACH ROW EXECUTE FUNCTION public.fn_bump_sync_version();

        DROP TRIGGER IF EXISTS trg_purchase_invoices_sync_version ON public.purchase_invoices;
        CREATE TRIGGER trg_purchase_invoices_sync_version
        BEFORE INSERT OR UPDATE ON public.purchase_invoices
        FOR EACH ROW EXECUTE FUNCTION public.fn_bump_sync_version();

        DROP TRIGGER IF EXISTS trg_supplier_payments_sync_version ON public.supplier_payments;
        CREATE TRIGGER trg_supplier_payments_sync_version
        BEFORE INSERT OR UPDATE ON public.supplier_payments
        FOR EACH ROW EXECUTE FUNCTION public.fn_bump_sync_version();
    END IF;
END $$;

COMMIT;
