-- ============================================================================
-- FoodBill Pro - Stage D Verification Test Suite
-- Database: foodbill_test_stage_d
-- ============================================================================

\set ON_ERROR_STOP on
\pset pager off

SELECT '=== STARTING STAGE D TEST SUITE ===' AS test_banner;

DO $$
DECLARE
    v_b1_id UUID;
    v_b2_id UUID;
    v_u1_id UUID;
    v_u2_id UUID;
    v_cat1_id UUID := gen_random_uuid();
    v_cat2_id UUID := gen_random_uuid();
    v_prod1_id UUID := gen_random_uuid();
    v_prod2_id UUID := gen_random_uuid();
    v_cust1_id UUID := gen_random_uuid();
    v_inv1_id UUID := gen_random_uuid();
    v_inv2_id UUID := gen_random_uuid();
    v_item1_id UUID := gen_random_uuid();
    v_pay1_id UUID := gen_random_uuid();
    v_sync_count INT;
    v_last_cursor BIGINT;
    v_caught BOOLEAN;
BEGIN
    RAISE NOTICE '>>> SETUP: Initializing test businesses and seed records...';

    -- Business 1
    INSERT INTO businesses (name, tagline, phone)
    VALUES ('Stage D Test Cafe 1', 'Best Cafe', '9999999991')
    RETURNING id INTO v_b1_id;

    -- Business 2 (for multi-tenant isolation tests)
    INSERT INTO businesses (name, tagline, phone)
    VALUES ('Stage D Test Cafe 2', 'Bakery Shop', '9999999992')
    RETURNING id INTO v_b2_id;

    -- Roles & Users
    INSERT INTO users (business_id, username, full_name, role_id, password_hash, salt)
    VALUES (v_b1_id, 'admin_b1', 'Admin B1', 'admin', 'dummyhash1', 'salt1')
    RETURNING id INTO v_u1_id;

    INSERT INTO users (business_id, username, full_name, role_id, password_hash, salt)
    VALUES (v_b2_id, 'admin_b2', 'Admin B2', 'admin', 'dummyhash2', 'salt2')
    RETURNING id INTO v_u2_id;

    -- Categories
    INSERT INTO categories (id, business_id, name, is_active, display_order)
    VALUES (v_cat1_id, v_b1_id, 'Beverages B1', true, 1);

    INSERT INTO categories (id, business_id, name, is_active, display_order)
    VALUES (v_cat2_id, v_b2_id, 'Bakery B2', true, 1);

    -- Products
    INSERT INTO products (id, business_id, category_id, name, unit, cost_price_paise, selling_price_paise, gst_rate_percent, is_tax_inclusive, is_available)
    VALUES (v_prod1_id, v_b1_id, v_cat1_id, 'Masala Chai', 'cup', 1000, 2500, 5.00, true, true);

    INSERT INTO products (id, business_id, category_id, name, unit, cost_price_paise, selling_price_paise, gst_rate_percent, is_tax_inclusive, is_available)
    VALUES (v_prod2_id, v_b2_id, v_cat2_id, 'Croissant', 'pc', 3000, 6000, 5.00, true, true);

    -- Customer for B1
    INSERT INTO customers (id, business_id, name, phone)
    VALUES (v_cust1_id, v_b1_id, 'John Doe', '9876543210');

    RAISE NOTICE '>>> SETUP COMPLETED. B1: %, B2: %', v_b1_id, v_b2_id;

    -- ========================================================================
    -- TEST D2: Outbox & Cursor Progression
    -- ========================================================================
    RAISE NOTICE '>>> RUNNING TEST D2: Outbox & Cursor Progression...';

    SELECT COUNT(*) INTO v_sync_count FROM sync_change_log WHERE business_id = v_b1_id;
    IF v_sync_count < 3 THEN
        RAISE EXCEPTION 'TEST D2 FAILED: Expected at least 3 sync entries for B1, got %', v_sync_count;
    END IF;

    SELECT last_cursor INTO v_last_cursor FROM business_sync_cursors WHERE business_id = v_b1_id;
    IF v_last_cursor != v_sync_count THEN
        RAISE EXCEPTION 'TEST D2 FAILED: Cursor mismatch. last_cursor=%, sync_count=%', v_last_cursor, v_sync_count;
    END IF;

    RAISE NOTICE 'TEST D2 PASSED: B1 generated % sync entries with strict cursor matching %', v_sync_count, v_last_cursor;

    -- ========================================================================
    -- TEST D3: Invoice Lifecycle & Item Protection
    -- ========================================================================
    RAISE NOTICE '>>> RUNNING TEST D3: Invoice Lifecycle & Item Protection...';

    -- D3.1: Create Open Invoice A (Pending)
    INSERT INTO invoices (id, business_id, invoice_number, subtotal_paise, taxable_amount_paise, grand_total_paise, payment_method, payment_status, order_status, order_type, idempotency_key, created_at)
    VALUES (v_inv1_id, v_b1_id, 'INV-TEST-001', 5000, 5000, 5000, 'Cash', 'Pending', 'Pending', 'Dine In', 'idemp-inv-1', CURRENT_TIMESTAMP);

    -- D3.2: Add item to Open Invoice A
    INSERT INTO invoice_items (id, invoice_id, product_id, product_name, unit, unit_price_paise, quantity, taxable_amount_paise, tax_amount_paise, total_amount_paise)
    VALUES (v_item1_id, v_inv1_id, v_prod1_id, 'Masala Chai', 'cup', 2500, 2.000, 5000, 0, 5000);

    -- D3.3: Update item quantity on Open Invoice A
    UPDATE invoice_items
    SET quantity = 3.000, taxable_amount_paise = 7500, total_amount_paise = 7500
    WHERE id = v_item1_id;

    UPDATE invoices
    SET subtotal_paise = 7500, taxable_amount_paise = 7500, grand_total_paise = 7500
    WHERE id = v_inv1_id;

    -- D3.4: Create Open Invoice B (Pending)
    INSERT INTO invoices (id, business_id, invoice_number, subtotal_paise, taxable_amount_paise, grand_total_paise, payment_method, payment_status, order_status, order_type, idempotency_key, created_at)
    VALUES (v_inv2_id, v_b1_id, 'INV-TEST-002', 0, 0, 0, 'Cash', 'Pending', 'Pending', 'Dine In', 'idemp-inv-2', CURRENT_TIMESTAMP);

    -- D3.5: Move item from Open Invoice A to Open Invoice B (Supported for Table Merges / Course Splits)
    UPDATE invoice_items
    SET invoice_id = v_inv2_id
    WHERE id = v_item1_id;

    RAISE NOTICE 'D3.5 Item moving between open invoices succeeded.';

    -- Move it back to Invoice A
    UPDATE invoice_items
    SET invoice_id = v_inv1_id
    WHERE id = v_item1_id;

    -- D3.6: Finalize Invoice A (Paid & Completed)
    UPDATE invoices
    SET payment_status = 'Paid', order_status = 'Completed'
    WHERE id = v_inv1_id;

    -- D3.7: Attempt to add item to finalized invoice -> MUST FAIL
    v_caught := false;
    BEGIN
        INSERT INTO invoice_items (id, invoice_id, product_id, product_name, unit, unit_price_paise, quantity, taxable_amount_paise, tax_amount_paise, total_amount_paise)
        VALUES (gen_random_uuid(), v_inv1_id, v_prod1_id, 'Masala Chai', 'cup', 2500, 1.000, 2500, 0, 2500);
    EXCEPTION WHEN OTHERS THEN
        v_caught := true;
        RAISE NOTICE 'D3.7 Correctly rejected adding item to finalized invoice: %', SQLERRM;
    END;
    IF NOT v_caught THEN
        RAISE EXCEPTION 'TEST D3.7 FAILED: Allowed adding item to finalized invoice!';
    END IF;

    -- D3.8: Attempt to update item on finalized invoice -> MUST FAIL
    v_caught := false;
    BEGIN
        UPDATE invoice_items
        SET quantity = 10.000
        WHERE id = v_item1_id;
    EXCEPTION WHEN OTHERS THEN
        v_caught := true;
        RAISE NOTICE 'D3.8 Correctly rejected modifying item on finalized invoice: %', SQLERRM;
    END;
    IF NOT v_caught THEN
        RAISE EXCEPTION 'TEST D3.8 FAILED: Allowed updating item on finalized invoice!';
    END IF;

    -- D3.9: Attempt to move item out of finalized invoice to open invoice -> MUST FAIL
    v_caught := false;
    BEGIN
        UPDATE invoice_items
        SET invoice_id = v_inv2_id
        WHERE id = v_item1_id;
    EXCEPTION WHEN OTHERS THEN
        v_caught := true;
        RAISE NOTICE 'D3.9 Correctly rejected moving item out of finalized invoice: %', SQLERRM;
    END;
    IF NOT v_caught THEN
        RAISE EXCEPTION 'TEST D3.9 FAILED: Allowed moving item out of finalized invoice!';
    END IF;

    -- D3.10: Attempt to delete item from finalized invoice -> MUST FAIL
    v_caught := false;
    BEGIN
        DELETE FROM invoice_items WHERE id = v_item1_id;
    EXCEPTION WHEN OTHERS THEN
        v_caught := true;
        RAISE NOTICE 'D3.10 Correctly rejected deleting item from finalized invoice: %', SQLERRM;
    END;
    IF NOT v_caught THEN
        RAISE EXCEPTION 'TEST D3.10 FAILED: Allowed deleting item from finalized invoice!';
    END IF;

    RAISE NOTICE 'TEST D3 PASSED: All invoice item protections verified.';

    -- ========================================================================
    -- TEST D4: Payment Immutability & Ripple Sync
    -- ========================================================================
    RAISE NOTICE '>>> RUNNING TEST D4: Payment Immutability & Ripple Sync...';

    -- Record sync cursor before payment
    SELECT last_cursor INTO v_last_cursor FROM business_sync_cursors WHERE business_id = v_b1_id;

    INSERT INTO payments (id, invoice_id, amount_paise, payment_method, idempotency_key)
    VALUES (v_pay1_id, v_inv1_id, 7500, 'Cash', 'idemp-pay-1');

    -- Verify parent invoice sync change was rippled
    IF NOT EXISTS (
        SELECT 1 FROM sync_change_log
        WHERE business_id = v_b1_id
          AND entity_name = 'invoices'
          AND record_id = v_inv1_id
          AND cursor > v_last_cursor
    ) THEN
        RAISE EXCEPTION 'TEST D4 FAILED: Parent invoice sync ripple not recorded!';
    END IF;

    -- Attempt to UPDATE payment -> MUST FAIL
    v_caught := false;
    BEGIN
        UPDATE payments SET amount_paise = 10000 WHERE id = v_pay1_id;
    EXCEPTION WHEN OTHERS THEN
        v_caught := true;
        RAISE NOTICE 'D4.2 Correctly rejected payment update: %', SQLERRM;
    END;
    IF NOT v_caught THEN
        RAISE EXCEPTION 'TEST D4 FAILED: Allowed payment update!';
    END IF;

    -- Attempt to DELETE payment -> MUST FAIL
    v_caught := false;
    BEGIN
        DELETE FROM payments WHERE id = v_pay1_id;
    EXCEPTION WHEN OTHERS THEN
        v_caught := true;
        RAISE NOTICE 'D4.3 Correctly rejected payment delete: %', SQLERRM;
    END;
    IF NOT v_caught THEN
        RAISE EXCEPTION 'TEST D4 FAILED: Allowed payment delete!';
    END IF;

    RAISE NOTICE 'TEST D4 PASSED: Payment immutability and ripple sync verified.';

    -- ========================================================================
    -- TEST D5: Foreign Keys, Multi-Tenant Isolation & Composite SET NULL
    -- ========================================================================
    RAISE NOTICE '>>> RUNNING TEST D5: Multi-Tenant & Composite FK SET NULL...';

    -- D5.1: Composite FK ON DELETE SET NULL on category
    -- When Category 1 is deleted, Product 1 category_id should become NULL, but business_id must remain B1
    DELETE FROM categories WHERE id = v_cat1_id;

    IF NOT EXISTS (
        SELECT 1 FROM products
        WHERE id = v_prod1_id
          AND category_id IS NULL
          AND business_id = v_b1_id
    ) THEN
        RAISE EXCEPTION 'TEST D5.1 FAILED: Product category_id was not set to NULL or business_id was corrupted!';
    END IF;
    RAISE NOTICE 'D5.1 Composite FK ON DELETE SET NULL (category_id) preserved business_id successfully.';

    -- ========================================================================
    -- TEST D6: Financial Integrity Protection on Finalized Invoices
    -- ========================================================================
    RAISE NOTICE '>>> RUNNING TEST D6: Financial Integrity on Finalized Invoices...';

    -- Attempt to alter grand_total_paise on finalized Invoice A -> MUST FAIL
    v_caught := false;
    BEGIN
        UPDATE invoices SET grand_total_paise = 100 WHERE id = v_inv1_id;
    EXCEPTION WHEN OTHERS THEN
        v_caught := true;
        RAISE NOTICE 'D6.1 Correctly rejected grand_total modification on finalized invoice: %', SQLERRM;
    END;
    IF NOT v_caught THEN
        RAISE EXCEPTION 'TEST D6.1 FAILED: Allowed modifying grand_total on finalized invoice!';
    END IF;

    -- Attempt to hard-delete finalized invoice -> MUST FAIL
    v_caught := false;
    BEGIN
        DELETE FROM invoices WHERE id = v_inv1_id;
    EXCEPTION WHEN OTHERS THEN
        v_caught := true;
        RAISE NOTICE 'D6.2 Correctly rejected hard-delete on finalized invoice: %', SQLERRM;
    END;
    IF NOT v_caught THEN
        RAISE EXCEPTION 'TEST D6.2 FAILED: Allowed hard-deleting finalized invoice!';
    END IF;

    RAISE NOTICE 'TEST D6 PASSED: Financial integrity constraints verified.';

    RAISE NOTICE '=== ALL STAGE D IN-DATABASE TESTS COMPLETED SUCCESSFULLY! ===';
END $$;
