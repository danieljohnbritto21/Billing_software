-- ============================================================================
-- FOODBILL PRO ENTERPRISE POSTGRESQL SCHEMA MIGRATION 002
-- Database: foodbill | Cluster Port: 5433 | Target User: foodbill_app
-- Focus: Schema Hardening, Financial Immutability, Multi-Tenant Isolation,
--        and Synchronization Reliability.
-- Idempotent & Fully Transactional
-- ============================================================================

BEGIN;

-- 1. SYNCHRONIZATION VERSIONING TRIGGER FUNCTION
-- Automatically advances server_version and updated_at on INSERT and UPDATE
CREATE OR REPLACE FUNCTION fn_bump_sync_version()
RETURNS TRIGGER AS $$
BEGIN
    NEW.server_version = nextval('global_sync_sequence');
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Attach sync version trigger to all synchronizable tables
DROP TRIGGER IF EXISTS trg_categories_sync_version ON categories;
CREATE TRIGGER trg_categories_sync_version
    BEFORE UPDATE ON categories
    FOR EACH ROW
    EXECUTE FUNCTION fn_bump_sync_version();

DROP TRIGGER IF EXISTS trg_products_sync_version ON products;
CREATE TRIGGER trg_products_sync_version
    BEFORE UPDATE ON products
    FOR EACH ROW
    EXECUTE FUNCTION fn_bump_sync_version();

DROP TRIGGER IF EXISTS trg_customers_sync_version ON customers;
CREATE TRIGGER trg_customers_sync_version
    BEFORE UPDATE ON customers
    FOR EACH ROW
    EXECUTE FUNCTION fn_bump_sync_version();

DROP TRIGGER IF EXISTS trg_invoices_sync_version ON invoices;
CREATE TRIGGER trg_invoices_sync_version
    BEFORE UPDATE ON invoices
    FOR EACH ROW
    EXECUTE FUNCTION fn_bump_sync_version();

DROP TRIGGER IF EXISTS trg_business_settings_sync_version ON business_settings;
CREATE TRIGGER trg_business_settings_sync_version
    BEFORE UPDATE ON business_settings
    FOR EACH ROW
    EXECUTE FUNCTION fn_bump_sync_version();

DROP TRIGGER IF EXISTS trg_bill_notes_sync_version ON bill_notes;
CREATE TRIGGER trg_bill_notes_sync_version
    BEFORE UPDATE ON bill_notes
    FOR EACH ROW
    EXECUTE FUNCTION fn_bump_sync_version();

-- 2. FINANCIAL IMMUTABILITY & HARD-DELETE PREVENTION TRIGGERS
-- Strictly blocks DELETE operations on invoices, invoice items, and payments
CREATE OR REPLACE FUNCTION fn_prevent_hard_delete()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'Hard deletion of % records is strictly prohibited for financial audit compliance. Use soft deletion or cancellation instead.', TG_TABLE_NAME;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_no_delete_invoices ON invoices;
CREATE TRIGGER trg_no_delete_invoices
    BEFORE DELETE ON invoices
    FOR EACH ROW
    EXECUTE FUNCTION fn_prevent_hard_delete();

DROP TRIGGER IF EXISTS trg_no_delete_invoice_items ON invoice_items;
CREATE TRIGGER trg_no_delete_invoice_items
    BEFORE DELETE ON invoice_items
    FOR EACH ROW
    EXECUTE FUNCTION fn_prevent_hard_delete();

DROP TRIGGER IF EXISTS trg_no_delete_payments ON payments;
CREATE TRIGGER trg_no_delete_payments
    BEFORE DELETE ON payments
    FOR EACH ROW
    EXECUTE FUNCTION fn_prevent_hard_delete();

DROP TRIGGER IF EXISTS trg_no_delete_kot_records ON kot_records;
CREATE TRIGGER trg_no_delete_kot_records
    BEFORE DELETE ON kot_records
    FOR EACH ROW
    EXECUTE FUNCTION fn_prevent_hard_delete();

-- 3. MULTI-TENANT BUSINESS ISOLATION ENFORCEMENT
-- 3a. Categories: Ensure unique (business_id, id)
ALTER TABLE categories DROP CONSTRAINT IF EXISTS uq_categories_business_id;
ALTER TABLE categories ADD CONSTRAINT uq_categories_business_id UNIQUE (business_id, id);

-- 3b. Products: Composite FK to Categories ensuring product & category share same business_id
ALTER TABLE products DROP CONSTRAINT IF EXISTS products_category_id_fkey;
ALTER TABLE products DROP CONSTRAINT IF EXISTS fk_products_category_business;
ALTER TABLE products DROP CONSTRAINT IF EXISTS uq_products_business_id;
ALTER TABLE products ADD CONSTRAINT uq_products_business_id UNIQUE (business_id, id);
ALTER TABLE products ADD CONSTRAINT fk_products_category_business
    FOREIGN KEY (business_id, category_id)
    REFERENCES categories(business_id, id)
    ON DELETE SET NULL;

-- 3c. Customers: Ensure unique (business_id, id)
ALTER TABLE customers DROP CONSTRAINT IF EXISTS uq_customers_business_id;
ALTER TABLE customers ADD CONSTRAINT uq_customers_business_id UNIQUE (business_id, id);

-- 3d. Devices: Ensure unique (business_id, id)
ALTER TABLE devices DROP CONSTRAINT IF EXISTS uq_devices_business_id;
ALTER TABLE devices ADD CONSTRAINT uq_devices_business_id UNIQUE (business_id, id);

-- 3e. Invoices: Ensure unique (business_id, id), Composite FK to Customers and Devices
ALTER TABLE invoices DROP CONSTRAINT IF EXISTS invoices_customer_id_fkey;
ALTER TABLE invoices DROP CONSTRAINT IF EXISTS invoices_device_id_fkey;
ALTER TABLE invoices DROP CONSTRAINT IF EXISTS fk_invoices_customer_business;
ALTER TABLE invoices DROP CONSTRAINT IF EXISTS fk_invoices_device_business;
ALTER TABLE invoices DROP CONSTRAINT IF EXISTS uq_invoices_business_id;

ALTER TABLE invoices ADD CONSTRAINT uq_invoices_business_id UNIQUE (business_id, id);
ALTER TABLE invoices ADD CONSTRAINT fk_invoices_customer_business
    FOREIGN KEY (business_id, customer_id)
    REFERENCES customers(business_id, id)
    ON DELETE SET NULL;
ALTER TABLE invoices ADD CONSTRAINT fk_invoices_device_business
    FOREIGN KEY (business_id, device_id)
    REFERENCES devices(business_id, id)
    ON DELETE SET NULL;

-- 3f. Dining Tables: Composite FK to Invoices
ALTER TABLE dining_tables DROP CONSTRAINT IF EXISTS fk_dining_tables_invoice_business;
ALTER TABLE dining_tables ADD CONSTRAINT fk_dining_tables_invoice_business
    FOREIGN KEY (business_id, current_invoice_id)
    REFERENCES invoices(business_id, id)
    ON DELETE SET NULL;

-- 3g. User Sessions: Add business_id with composite constraints
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'user_sessions' AND column_name = 'business_id'
    ) THEN
        ALTER TABLE user_sessions ADD COLUMN business_id UUID REFERENCES businesses(id) ON DELETE CASCADE;
    END IF;
END $$;

ALTER TABLE users DROP CONSTRAINT IF EXISTS uq_users_business_id;
ALTER TABLE users ADD CONSTRAINT uq_users_business_id UNIQUE (business_id, id);

ALTER TABLE user_sessions DROP CONSTRAINT IF EXISTS fk_user_sessions_user_business;
ALTER TABLE user_sessions DROP CONSTRAINT IF EXISTS fk_user_sessions_device_business;
ALTER TABLE user_sessions ADD CONSTRAINT fk_user_sessions_user_business
    FOREIGN KEY (business_id, user_id)
    REFERENCES users(business_id, id)
    ON DELETE CASCADE;
ALTER TABLE user_sessions ADD CONSTRAINT fk_user_sessions_device_business
    FOREIGN KEY (business_id, device_id)
    REFERENCES devices(business_id, id)
    ON DELETE CASCADE;

-- 4. DATA INTEGRITY CHECK CONSTRAINTS
-- 4a. Products
ALTER TABLE products DROP CONSTRAINT IF EXISTS chk_product_selling_price;
ALTER TABLE products ADD CONSTRAINT chk_product_selling_price CHECK (selling_price_paise >= 0);

ALTER TABLE products DROP CONSTRAINT IF EXISTS chk_product_cost_price;
ALTER TABLE products ADD CONSTRAINT chk_product_cost_price CHECK (cost_price_paise >= 0);

ALTER TABLE products DROP CONSTRAINT IF EXISTS chk_product_gst_rate;
ALTER TABLE products ADD CONSTRAINT chk_product_gst_rate CHECK (gst_rate_percent >= 0.00 AND gst_rate_percent <= 100.00);

-- 4b. Payments
ALTER TABLE payments DROP CONSTRAINT IF EXISTS chk_payment_amount_positive;
ALTER TABLE payments ADD CONSTRAINT chk_payment_amount_positive CHECK (amount_paise > 0);

-- 4c. Invoices
ALTER TABLE invoices DROP CONSTRAINT IF EXISTS chk_invoice_grand_total;
ALTER TABLE invoices ADD CONSTRAINT chk_invoice_grand_total CHECK (grand_total_paise >= 0);

ALTER TABLE invoices DROP CONSTRAINT IF EXISTS chk_invoice_paid_amount;
ALTER TABLE invoices ADD CONSTRAINT chk_invoice_paid_amount CHECK (paid_amount_paise >= 0);

ALTER TABLE invoices DROP CONSTRAINT IF EXISTS chk_invoice_taxable_amount;
ALTER TABLE invoices ADD CONSTRAINT chk_invoice_taxable_amount CHECK (taxable_amount_paise >= 0);

ALTER TABLE invoices DROP CONSTRAINT IF EXISTS chk_invoice_payment_status;
ALTER TABLE invoices ADD CONSTRAINT chk_invoice_payment_status CHECK (
    payment_status IN ('Paid', 'Partially Paid', 'Pending', 'Cancelled', 'Refunded')
);

ALTER TABLE invoices DROP CONSTRAINT IF EXISTS chk_invoice_order_status;
ALTER TABLE invoices ADD CONSTRAINT chk_invoice_order_status CHECK (
    order_status IN ('Pending', 'In Progress', 'Completed', 'Cancelled')
);

ALTER TABLE invoices DROP CONSTRAINT IF EXISTS chk_invoice_order_type;
ALTER TABLE invoices ADD CONSTRAINT chk_invoice_order_type CHECK (
    order_type IN ('Dine In', 'Takeaway', 'Delivery')
);

ALTER TABLE invoices DROP CONSTRAINT IF EXISTS chk_invoice_cancellation_integrity;
ALTER TABLE invoices ADD CONSTRAINT chk_invoice_cancellation_integrity CHECK (
    (is_cancelled = FALSE AND cancelled_at IS NULL) OR
    (is_cancelled = TRUE AND cancelled_at IS NOT NULL AND cancel_reason IS NOT NULL AND length(trim(cancel_reason)) > 0)
);

-- 4d. Invoice Items
ALTER TABLE invoice_items DROP CONSTRAINT IF EXISTS chk_invoice_item_quantity;
ALTER TABLE invoice_items ADD CONSTRAINT chk_invoice_item_quantity CHECK (quantity > 0);

ALTER TABLE invoice_items DROP CONSTRAINT IF EXISTS chk_invoice_item_unit_price;
ALTER TABLE invoice_items ADD CONSTRAINT chk_invoice_item_unit_price CHECK (unit_price_paise >= 0);

ALTER TABLE invoice_items DROP CONSTRAINT IF EXISTS chk_invoice_item_total_amount;
ALTER TABLE invoice_items ADD CONSTRAINT chk_invoice_item_total_amount CHECK (total_amount_paise >= 0);

ALTER TABLE invoice_items DROP CONSTRAINT IF EXISTS chk_invoice_item_gst_rate;
ALTER TABLE invoice_items ADD CONSTRAINT chk_invoice_item_gst_rate CHECK (gst_rate_percent >= 0.00 AND gst_rate_percent <= 100.00);

COMMIT;
