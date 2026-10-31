-- ============================================================================
-- FOODBILL PRO ENTERPRISE POSTGRESQL SCHEMA MIGRATION 004
-- Database: foodbill | Cluster Port: 5433 | Target User: foodbill_app
-- Focus: Per-Business Transactional Change Log Outbox with Commit-Safe Cursor,
--        Soft-Deletion Propagation, Advanced Item-Movement Protection,
--        and Finalized Financial Immutability.
-- Idempotent & Fully Transactional
-- ============================================================================

BEGIN;

-- 1. PER-BUSINESS TRANSACTIONAL CHANGE LOG & CURSOR LOCK TABLES
CREATE TABLE IF NOT EXISTS business_sync_cursors (
    business_id UUID PRIMARY KEY REFERENCES businesses(id) ON DELETE CASCADE,
    last_cursor BIGINT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS sync_change_log (
    id BIGSERIAL PRIMARY KEY,
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    cursor BIGINT NOT NULL,
    entity_name VARCHAR(60) NOT NULL,
    record_id UUID NOT NULL,
    operation VARCHAR(20) NOT NULL, -- 'INSERT', 'UPDATE', 'DELETE'
    record_version BIGINT NOT NULL,
    payload JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_business_sync_cursor UNIQUE (business_id, cursor)
);

CREATE INDEX IF NOT EXISTS idx_sync_change_log_cursor
ON sync_change_log(business_id, cursor ASC);

-- 2. ENSURE SOFT-DELETION COLUMNS EXIST ON ALL RELEVANT ENTITIES
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'dining_tables' AND column_name = 'deleted_at'
    ) THEN
        ALTER TABLE dining_tables ADD COLUMN deleted_at TIMESTAMPTZ;
    END IF;
END $$;

-- 3. COMMIT-SAFE PER-BUSINESS OUTBOX SYNCHRONIZATION TRIGGER FUNCTION
-- Locks the business cursor row, allocates the next contiguous cursor,
-- and inserts a change-log record in the EXACT same transaction.
CREATE OR REPLACE FUNCTION fn_record_sync_change()
RETURNS TRIGGER AS $$
DECLARE
    v_business_id UUID;
    v_record_id UUID;
    v_entity_name VARCHAR(60);
    v_op VARCHAR(20);
    v_cursor BIGINT;
    v_payload JSONB := NULL;
BEGIN
    v_entity_name := TG_TABLE_NAME;

    -- Determine business_id and record_id safely using JSON representation
    IF TG_OP = 'DELETE' THEN
        v_op := 'DELETE';
        v_record_id := OLD.id;
        v_business_id := (to_jsonb(OLD) ->> 'business_id')::UUID;
    ELSIF TG_OP = 'UPDATE' THEN
        -- Detect soft deletion
        IF ((to_jsonb(NEW) ->> 'deleted_at') IS NOT NULL AND
            ((to_jsonb(OLD) ->> 'deleted_at') IS NULL OR (to_jsonb(OLD) ->> 'deleted_at') <> (to_jsonb(NEW) ->> 'deleted_at'))) THEN
            v_op := 'DELETE';
        ELSE
            v_op := 'UPDATE';
        END IF;
        v_record_id := NEW.id;
        v_business_id := (to_jsonb(NEW) ->> 'business_id')::UUID;
    ELSE
        v_op := 'INSERT';
        v_record_id := NEW.id;
        v_business_id := (to_jsonb(NEW) ->> 'business_id')::UUID;
    END IF;

    -- If business_id is null (e.g. child tables without direct business_id), retrieve from parent
    IF v_business_id IS NULL THEN
        IF v_entity_name = 'product_images' THEN
            SELECT business_id INTO v_business_id FROM products WHERE id = COALESCE(NEW.product_id, OLD.product_id);
        ELSIF v_entity_name = 'bill_notes' OR v_entity_name = 'kot_records' OR v_entity_name = 'payments' THEN
            SELECT business_id INTO v_business_id FROM invoices WHERE id = COALESCE(NEW.invoice_id, OLD.invoice_id);
        END IF;
    END IF;

    -- If business_id is still null, do not record outbox entry
    IF v_business_id IS NULL THEN
        IF TG_OP = 'DELETE' THEN RETURN OLD; END IF;
        RETURN NEW;
    END IF;

    -- Ensure a cursor record exists for this business
    INSERT INTO business_sync_cursors (business_id, last_cursor, updated_at)
    VALUES (v_business_id, 0, CURRENT_TIMESTAMP)
    ON CONFLICT (business_id) DO NOTHING;

    -- ATOMIC TRANSACTIONAL ROW LOCK:
    -- Updating this specific business's cursor row acquires an exclusive row lock
    -- for the remainder of this transaction. Any concurrent transaction for the
    -- SAME business MUST wait until this transaction commits.
    -- This guarantees 100% contiguous, commit-ordered cursor progression!
    UPDATE business_sync_cursors
    SET last_cursor = last_cursor + 1,
        updated_at = CURRENT_TIMESTAMP
    WHERE business_id = v_business_id
    RETURNING last_cursor INTO v_cursor;

    -- Assign cursor to entity server_version and update timestamp where supported
    IF TG_OP <> 'DELETE' THEN
        IF (to_jsonb(NEW) ? 'server_version') THEN
            NEW.server_version := v_cursor;
        END IF;
        IF (to_jsonb(NEW) ? 'updated_at') THEN
            NEW.updated_at := CURRENT_TIMESTAMP;
        END IF;
    END IF;

    -- Record in transactional outbox / change log
    INSERT INTO sync_change_log (
        business_id,
        cursor,
        entity_name,
        record_id,
        operation,
        record_version,
        payload,
        created_at
    ) VALUES (
        v_business_id,
        v_cursor,
        v_entity_name,
        v_record_id,
        v_op,
        v_cursor,
        v_payload,
        CURRENT_TIMESTAMP
    );

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. ATTACH OUTBOX SYNC TRIGGERS TO ALL SYNCHRONIZABLE TABLES
DROP TRIGGER IF EXISTS trg_sync_categories ON categories;
CREATE TRIGGER trg_sync_categories
    BEFORE INSERT OR UPDATE ON categories
    FOR EACH ROW
    EXECUTE FUNCTION fn_record_sync_change();

DROP TRIGGER IF EXISTS trg_sync_products ON products;
CREATE TRIGGER trg_sync_products
    BEFORE INSERT OR UPDATE ON products
    FOR EACH ROW
    EXECUTE FUNCTION fn_record_sync_change();

DROP TRIGGER IF EXISTS trg_sync_customers ON customers;
CREATE TRIGGER trg_sync_customers
    BEFORE INSERT OR UPDATE ON customers
    FOR EACH ROW
    EXECUTE FUNCTION fn_record_sync_change();

DROP TRIGGER IF EXISTS trg_sync_invoices ON invoices;
CREATE TRIGGER trg_sync_invoices
    BEFORE INSERT OR UPDATE ON invoices
    FOR EACH ROW
    EXECUTE FUNCTION fn_record_sync_change();

DROP TRIGGER IF EXISTS trg_sync_dining_tables ON dining_tables;
CREATE TRIGGER trg_sync_dining_tables
    BEFORE INSERT OR UPDATE ON dining_tables
    FOR EACH ROW
    EXECUTE FUNCTION fn_record_sync_change();

DROP TRIGGER IF EXISTS trg_sync_business_settings ON business_settings;
CREATE TRIGGER trg_sync_business_settings
    BEFORE INSERT OR UPDATE ON business_settings
    FOR EACH ROW
    EXECUTE FUNCTION fn_record_sync_change();

DROP TRIGGER IF EXISTS trg_sync_product_images ON product_images;
CREATE TRIGGER trg_sync_product_images
    BEFORE INSERT OR UPDATE ON product_images
    FOR EACH ROW
    EXECUTE FUNCTION fn_record_sync_change();

-- Note: payments, kot_records, and invoice_items synchronize via fn_ripple_invoice_sync
-- which touches parent invoice updated_at, generating outbox entries under 'invoices' aggregate root.
DROP TRIGGER IF EXISTS trg_sync_kot_records ON kot_records;
DROP TRIGGER IF EXISTS trg_sync_payments ON payments;
CREATE TRIGGER trg_sync_payments
    BEFORE INSERT OR UPDATE ON payments
    FOR EACH ROW
    EXECUTE FUNCTION fn_record_sync_change();

-- 5. REFINED INVOICE ITEM IMMUTABILITY & INTER-INVOICE MOVEMENT PROTECTION
CREATE OR REPLACE FUNCTION fn_protect_invoice_items()
RETURNS TRIGGER AS $$
DECLARE
    v_old_status VARCHAR(40);
    v_new_status VARCHAR(40);
    v_old_payment VARCHAR(40);
    v_new_payment VARCHAR(40);
    v_old_cancelled BOOLEAN;
    v_new_cancelled BOOLEAN;
BEGIN
    IF TG_OP = 'UPDATE' THEN
        -- If an item is moved between invoices, check BOTH old and new parent invoices!
        IF OLD.invoice_id <> NEW.invoice_id THEN
            SELECT order_status, payment_status, is_cancelled
            INTO v_old_status, v_old_payment, v_old_cancelled
            FROM invoices WHERE id = OLD.invoice_id;

            IF v_old_status = 'Completed' OR v_old_payment IN ('Paid', 'Cancelled', 'Refunded') OR v_old_cancelled = TRUE THEN
                RAISE EXCEPTION 'Cannot move item % out of finalized/paid invoice %.', OLD.id, OLD.invoice_id;
            END IF;

            SELECT order_status, payment_status, is_cancelled
            INTO v_new_status, v_new_payment, v_new_cancelled
            FROM invoices WHERE id = NEW.invoice_id;

            IF v_new_status = 'Completed' OR v_new_payment IN ('Paid', 'Cancelled', 'Refunded') OR v_new_cancelled = TRUE THEN
                RAISE EXCEPTION 'Cannot move item % into finalized/paid invoice %.', NEW.id, NEW.invoice_id;
            END IF;
        ELSE
            SELECT order_status, payment_status, is_cancelled
            INTO v_old_status, v_old_payment, v_old_cancelled
            FROM invoices WHERE id = OLD.invoice_id;

            IF v_old_status = 'Completed' OR v_old_payment IN ('Paid', 'Cancelled', 'Refunded') OR v_old_cancelled = TRUE THEN
                RAISE EXCEPTION 'Cannot modify items on finalized/paid invoice %.', OLD.invoice_id;
            END IF;
        END IF;

    ELSIF TG_OP = 'INSERT' THEN
        SELECT order_status, payment_status, is_cancelled
        INTO v_new_status, v_new_payment, v_new_cancelled
        FROM invoices WHERE id = NEW.invoice_id;

        IF v_new_status = 'Completed' OR v_new_payment IN ('Paid', 'Cancelled', 'Refunded') OR v_new_cancelled = TRUE THEN
            RAISE EXCEPTION 'Cannot add items to finalized/paid invoice %.', NEW.invoice_id;
        END IF;

    ELSIF TG_OP = 'DELETE' THEN
        SELECT order_status, payment_status, is_cancelled
        INTO v_old_status, v_old_payment, v_old_cancelled
        FROM invoices WHERE id = OLD.invoice_id;

        IF v_old_status = 'Completed' OR v_old_payment IN ('Paid', 'Cancelled', 'Refunded') OR v_old_cancelled = TRUE THEN
            RAISE EXCEPTION 'Cannot delete items from finalized/paid invoice %.', OLD.invoice_id;
        END IF;
        RETURN OLD;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 6. REFINED RIPPLE INVOICE SYNC TRIGGER
-- Advances updated_at on the parent invoice(s), triggering outbox sync
CREATE OR REPLACE FUNCTION fn_ripple_invoice_sync()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' AND OLD.invoice_id <> NEW.invoice_id THEN
        UPDATE invoices SET updated_at = CURRENT_TIMESTAMP WHERE id = OLD.invoice_id;
        UPDATE invoices SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.invoice_id;
    ELSE
        UPDATE invoices SET updated_at = CURRENT_TIMESTAMP WHERE id = COALESCE(NEW.invoice_id, OLD.invoice_id);
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 7. REFINED FINALIZED INVOICE TRANSITION & FINANCIAL PROTECTION
CREATE OR REPLACE FUNCTION fn_protect_finalized_invoices()
RETURNS TRIGGER AS $$
BEGIN
    -- If invoice was already completed, paid, or cancelled:
    IF OLD.order_status = 'Completed' OR OLD.payment_status IN ('Paid', 'Cancelled', 'Refunded') OR OLD.is_cancelled = TRUE THEN
        -- 1. Allow formal cancellation transition (must provide reason and timestamp)
        IF NEW.is_cancelled = TRUE AND OLD.is_cancelled = FALSE THEN
            IF NEW.grand_total_paise <> OLD.grand_total_paise OR
               NEW.subtotal_paise <> OLD.subtotal_paise OR
               NEW.taxable_amount_paise <> OLD.taxable_amount_paise OR
               NEW.invoice_number <> OLD.invoice_number OR
               NEW.business_id <> OLD.business_id THEN
                RAISE EXCEPTION 'Financial totals cannot be altered during invoice cancellation.';
            END IF;
            RETURN NEW;
        END IF;

        -- 2. Allow partial-to-paid payment updates while preserving bill totals
        IF OLD.payment_status = 'Partially Paid' AND NEW.grand_total_paise = OLD.grand_total_paise AND NEW.business_id = OLD.business_id THEN
            RETURN NEW;
        END IF;

        -- 3. Strict financial and identity freeze on completed bills
        IF NEW.grand_total_paise <> OLD.grand_total_paise OR
           NEW.subtotal_paise <> OLD.subtotal_paise OR
           NEW.taxable_amount_paise <> OLD.taxable_amount_paise OR
           NEW.cgst_paise <> OLD.cgst_paise OR
           NEW.sgst_paise <> OLD.sgst_paise OR
           NEW.igst_paise <> OLD.igst_paise OR
           NEW.round_off_paise <> OLD.round_off_paise OR
           NEW.invoice_number <> OLD.invoice_number OR
           NEW.business_id <> OLD.business_id OR
           NEW.created_at <> OLD.created_at THEN
            RAISE EXCEPTION 'Invoice % is finalized. Financial amounts, tax, and invoice numbers cannot be modified.', OLD.invoice_number;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMIT;
