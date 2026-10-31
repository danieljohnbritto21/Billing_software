-- ============================================================================
-- FOODBILL PRO ENTERPRISE POSTGRESQL SCHEMA MIGRATION 003
-- Database: foodbill | Cluster Port: 5433 | Target User: foodbill_app
-- Focus: Column-Specific Composite FKs, Commit-Safe Synchronization Engine,
--        Open-Order vs Finalized Invoice Immutability, and Complete Table Triggers.
-- Idempotent & Fully Transactional
-- ============================================================================

BEGIN;

-- 1. COLUMN-SPECIFIC COMPOSITE FOREIGN KEYS (PREVENT BUSINESS_ID WIPEOUT)
-- PostgreSQL 15+ allows ON DELETE SET NULL (column_name) so business_id is NEVER nulled out

ALTER TABLE products DROP CONSTRAINT IF EXISTS fk_products_category_business;
ALTER TABLE products ADD CONSTRAINT fk_products_category_business
    FOREIGN KEY (business_id, category_id)
    REFERENCES categories(business_id, id)
    ON DELETE SET NULL (category_id);

ALTER TABLE invoices DROP CONSTRAINT IF EXISTS fk_invoices_customer_business;
ALTER TABLE invoices ADD CONSTRAINT fk_invoices_customer_business
    FOREIGN KEY (business_id, customer_id)
    REFERENCES customers(business_id, id)
    ON DELETE SET NULL (customer_id);

ALTER TABLE invoices DROP CONSTRAINT IF EXISTS fk_invoices_device_business;
ALTER TABLE invoices ADD CONSTRAINT fk_invoices_device_business
    FOREIGN KEY (business_id, device_id)
    REFERENCES devices(business_id, id)
    ON DELETE SET NULL (device_id);

ALTER TABLE dining_tables DROP CONSTRAINT IF EXISTS fk_dining_tables_invoice_business;
ALTER TABLE dining_tables ADD CONSTRAINT fk_dining_tables_invoice_business
    FOREIGN KEY (business_id, current_invoice_id)
    REFERENCES invoices(business_id, id)
    ON DELETE SET NULL (current_invoice_id);

-- 2. ENFORCE NOT NULL ON USER_SESSIONS.BUSINESS_ID
ALTER TABLE user_sessions ALTER COLUMN business_id SET NOT NULL;

-- 3. FINANCIAL IMMUTABILITY: OPEN ORDER VS FINALIZED INVOICE GUARDS

-- 3a. Protect Invoice Items: Allow additions/deletions on open pending orders,
--     but FROZEN completely once invoice is Completed, Paid, or Cancelled.
CREATE OR REPLACE FUNCTION fn_protect_invoice_items()
RETURNS TRIGGER AS $$
DECLARE
    target_invoice_id UUID;
    inv_order_status VARCHAR(40);
    inv_payment_status VARCHAR(40);
    inv_cancelled BOOLEAN;
BEGIN
    target_invoice_id := COALESCE(NEW.invoice_id, OLD.invoice_id);

    SELECT order_status, payment_status, is_cancelled
    INTO inv_order_status, inv_payment_status, inv_cancelled
    FROM invoices WHERE id = target_invoice_id;

    IF inv_order_status = 'Completed' OR inv_payment_status IN ('Paid', 'Cancelled', 'Refunded') OR inv_cancelled = TRUE THEN
        IF TG_OP = 'INSERT' THEN
            RAISE EXCEPTION 'Cannot add items to a finalized or paid invoice (ID: %).', target_invoice_id;
        ELSIF TG_OP = 'UPDATE' THEN
            RAISE EXCEPTION 'Cannot modify items of a finalized or paid invoice (ID: %).', target_invoice_id;
        ELSIF TG_OP = 'DELETE' THEN
            RAISE EXCEPTION 'Cannot delete items from a finalized or paid invoice (ID: %).', target_invoice_id;
        END IF;
    END IF;

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_protect_invoice_items ON invoice_items;
CREATE TRIGGER trg_protect_invoice_items
    BEFORE INSERT OR UPDATE OR DELETE ON invoice_items
    FOR EACH ROW
    EXECUTE FUNCTION fn_protect_invoice_items();

-- 3b. Protect Invoices: Prevent tampering with financial totals on finalized bills
CREATE OR REPLACE FUNCTION fn_protect_finalized_invoices()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.order_status = 'Completed' OR OLD.payment_status IN ('Paid', 'Cancelled', 'Refunded') OR OLD.is_cancelled = TRUE THEN
        -- Allow formal cancellation transition
        IF NEW.is_cancelled = TRUE AND OLD.is_cancelled = FALSE THEN
            IF NEW.grand_total_paise <> OLD.grand_total_paise OR
               NEW.subtotal_paise <> OLD.subtotal_paise OR
               NEW.taxable_amount_paise <> OLD.taxable_amount_paise OR
               NEW.invoice_number <> OLD.invoice_number THEN
                RAISE EXCEPTION 'Financial totals cannot be modified during invoice cancellation.';
            END IF;
            RETURN NEW;
        END IF;

        -- Allow partial payment updates (e.g. paid_amount_paise and payment_status transitions)
        IF OLD.payment_status = 'Partially Paid' AND NEW.grand_total_paise = OLD.grand_total_paise THEN
            RETURN NEW;
        END IF;

        -- Block financial tampering
        IF NEW.grand_total_paise <> OLD.grand_total_paise OR
           NEW.subtotal_paise <> OLD.subtotal_paise OR
           NEW.taxable_amount_paise <> OLD.taxable_amount_paise OR
           NEW.invoice_number <> OLD.invoice_number OR
           NEW.business_id <> OLD.business_id THEN
            RAISE EXCEPTION 'Invoice % is finalized. Financial amounts cannot be modified.', OLD.invoice_number;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_protect_finalized_invoices ON invoices;
CREATE TRIGGER trg_protect_finalized_invoices
    BEFORE UPDATE ON invoices
    FOR EACH ROW
    EXECUTE FUNCTION fn_protect_finalized_invoices();

-- 3c. Protect Payments: Ledger entries are immutable once written
CREATE OR REPLACE FUNCTION fn_protect_payments()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        IF NEW.amount_paise <> OLD.amount_paise OR NEW.invoice_id <> OLD.invoice_id OR NEW.payment_method <> OLD.payment_method THEN
            RAISE EXCEPTION 'Payment ledger entries are strictly immutable. To adjust a balance, record a separate adjustment transaction.';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_protect_payments ON payments;
CREATE TRIGGER trg_protect_payments
    BEFORE UPDATE ON payments
    FOR EACH ROW
    EXECUTE FUNCTION fn_protect_payments();

-- 3d. Protect KOT Records: Original order items are immutable; only reprint count can advance
CREATE OR REPLACE FUNCTION fn_protect_kot_records()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        IF NEW.items_json <> OLD.items_json OR NEW.kot_number <> OLD.kot_number OR NEW.invoice_id <> OLD.invoice_id THEN
            RAISE EXCEPTION 'Original KOT item snapshots are immutable. Only reprint count may be updated.';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_protect_kot_records ON kot_records;
CREATE TRIGGER trg_protect_kot_records
    BEFORE UPDATE ON kot_records
    FOR EACH ROW
    EXECUTE FUNCTION fn_protect_kot_records();

-- 4. COMPLETE SYNCHRONIZATION TRIGGERS ON ALL SYNCHRONIZABLE ENTITIES

-- 4a. Product Images: Add updated_at, deleted_at, and sync trigger
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'product_images' AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE product_images ADD COLUMN updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'product_images' AND column_name = 'deleted_at'
    ) THEN
        ALTER TABLE product_images ADD COLUMN deleted_at TIMESTAMPTZ;
    END IF;
END $$;

DROP TRIGGER IF EXISTS trg_product_images_sync_version ON product_images;
CREATE TRIGGER trg_product_images_sync_version
    BEFORE UPDATE ON product_images
    FOR EACH ROW
    EXECUTE FUNCTION fn_bump_sync_version();

-- 4b. Payments: Attach sync version trigger
DROP TRIGGER IF EXISTS trg_payments_sync_version ON payments;
CREATE TRIGGER trg_payments_sync_version
    BEFORE UPDATE ON payments
    FOR EACH ROW
    EXECUTE FUNCTION fn_bump_sync_version();

-- 4c. KOT Records: Add updated_at and sync version trigger
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'kot_records' AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE kot_records ADD COLUMN updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP;
    END IF;
END $$;

DROP TRIGGER IF EXISTS trg_kot_records_sync_version ON kot_records;
CREATE TRIGGER trg_kot_records_sync_version
    BEFORE UPDATE ON kot_records
    FOR EACH ROW
    EXECUTE FUNCTION fn_bump_sync_version();

-- 4d. Ripple Triggers: When items or payments change, bump parent invoice server_version
-- Ensures phones pulling invoices immediately see updated totals, items, and balance due
CREATE OR REPLACE FUNCTION fn_ripple_invoice_sync()
RETURNS TRIGGER AS $$
DECLARE
    target_invoice_id UUID;
BEGIN
    target_invoice_id := COALESCE(NEW.invoice_id, OLD.invoice_id);
    UPDATE invoices
    SET server_version = nextval('global_sync_sequence'),
        updated_at = CURRENT_TIMESTAMP
    WHERE id = target_invoice_id;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_items_ripple_invoice ON invoice_items;
CREATE TRIGGER trg_items_ripple_invoice
    AFTER INSERT OR UPDATE OR DELETE ON invoice_items
    FOR EACH ROW
    EXECUTE FUNCTION fn_ripple_invoice_sync();

DROP TRIGGER IF EXISTS trg_payments_ripple_invoice ON payments;
CREATE TRIGGER trg_payments_ripple_invoice
    AFTER INSERT OR UPDATE ON payments
    FOR EACH ROW
    EXECUTE FUNCTION fn_ripple_invoice_sync();

-- 5. COMMIT-SAFE SYNCHRONIZATION WATERMARK FUNCTION
-- Calculates safe high-water mark preventing phones from skipping in-flight uncommitted transactions
CREATE OR REPLACE FUNCTION fn_get_safe_sync_watermark(p_business_id UUID)
RETURNS BIGINT AS $$
DECLARE
    active_txids xid8[];
    min_uncommitted_version BIGINT;
    latest_committed_version BIGINT;
BEGIN
    -- 1. Gather all currently active (uncommitted) transaction IDs
    active_txids := ARRAY(SELECT pg_snapshot_xip(pg_current_snapshot()));

    -- 2. If concurrent write transactions exist, find minimum sequence assigned to them
    IF array_length(active_txids, 1) > 0 THEN
        -- Safely look across primary sync tables
        SELECT MIN(min_v) INTO min_uncommitted_version FROM (
            SELECT MIN(server_version) AS min_v FROM invoices WHERE business_id = p_business_id AND pg_current_xact_id()::text != xmin::text AND xmin::text = ANY(active_txids::text[])
            UNION ALL
            SELECT MIN(server_version) AS min_v FROM products WHERE business_id = p_business_id AND pg_current_xact_id()::text != xmin::text AND xmin::text = ANY(active_txids::text[])
            UNION ALL
            SELECT MIN(server_version) AS min_v FROM categories WHERE business_id = p_business_id AND pg_current_xact_id()::text != xmin::text AND xmin::text = ANY(active_txids::text[])
        ) sub;
    END IF;

    -- 3. If an uncommitted transaction exists, barrier is (min_uncommitted_version - 1)
    IF min_uncommitted_version IS NOT NULL AND min_uncommitted_version > 0 THEN
        RETURN min_uncommitted_version - 1;
    END IF;

    -- 4. Otherwise, safe barrier is the latest sequence value
    SELECT last_value INTO latest_committed_version FROM global_sync_sequence;
    RETURN COALESCE(latest_committed_version, 0);
END;
$$ LANGUAGE plpgsql;

COMMIT;
