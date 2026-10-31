-- ============================================================================
-- FOODBILL PRO ENTERPRISE POSTGRESQL SCHEMA MIGRATION 001
-- Database: foodbill | Cluster Port: 5433 | Target User: foodbill_app
-- Generated from: Flutter Drift Schema Version 5 (D:\billing_software)
-- Idempotent & Safe to Re-run
-- ============================================================================

-- 0. CORE EXTENSIONS & GLOBAL SEQUENCES
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE SEQUENCE IF NOT EXISTS global_sync_sequence START WITH 1 INCREMENT BY 1;

-- 1. BUSINESS PROFILE & SETTINGS
CREATE TABLE IF NOT EXISTS businesses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(150) NOT NULL,
    tagline VARCHAR(255),
    address TEXT,
    phone VARCHAR(30),
    gstin VARCHAR(20),
    invoice_prefix VARCHAR(15) DEFAULT 'INV-',
    printer_width VARCHAR(10) DEFAULT '80mm',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS business_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    setting_key VARCHAR(100) NOT NULL,
    setting_value TEXT NOT NULL,
    server_version BIGINT DEFAULT nextval('global_sync_sequence'),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_business_setting UNIQUE (business_id, setting_key)
);

-- 2. ROLES & USERS
CREATE TABLE IF NOT EXISTS roles (
    id VARCHAR(30) PRIMARY KEY,
    description VARCHAR(255) NOT NULL
);

INSERT INTO roles (id, description) VALUES
('admin', 'Full administrative store access'),
('cashier', 'Point-of-Sale, product creation, and order management')
ON CONFLICT (id) DO NOTHING;

CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    username VARCHAR(60) NOT NULL,
    full_name VARCHAR(120) NOT NULL,
    role_id VARCHAR(30) NOT NULL REFERENCES roles(id),
    password_hash VARCHAR(255) NOT NULL,
    salt VARCHAR(64) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    server_version BIGINT DEFAULT nextval('global_sync_sequence'),
    CONSTRAINT uq_business_username UNIQUE (business_id, username)
);

-- 3. DEVICE AUTHORIZATION & SESSIONS
CREATE TABLE IF NOT EXISTS devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    device_uid VARCHAR(128) NOT NULL,
    device_name VARCHAR(100) NOT NULL,
    tailscale_ip VARCHAR(45),
    is_authorized BOOLEAN NOT NULL DEFAULT FALSE,
    authorized_at TIMESTAMPTZ,
    last_seen_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_business_device UNIQUE (business_id, device_uid)
);

CREATE TABLE IF NOT EXISTS user_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id UUID NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    refresh_token_hash VARCHAR(255) NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    is_revoked BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 4. CATEGORIES & PRODUCTS (MAPPED FROM DRIFT TABLES)
CREATE TABLE IF NOT EXISTS categories (
    id UUID PRIMARY KEY,
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    icon VARCHAR(60),
    color_value INTEGER,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    display_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ,
    server_version BIGINT DEFAULT nextval('global_sync_sequence')
);

CREATE TABLE IF NOT EXISTS products (
    id UUID PRIMARY KEY,
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    name VARCHAR(150) NOT NULL,
    code VARCHAR(60),
    description TEXT,
    cost_price_paise BIGINT NOT NULL DEFAULT 0,
    selling_price_paise BIGINT NOT NULL,
    gst_rate_percent NUMERIC(5, 2) NOT NULL DEFAULT 0.00,
    is_tax_inclusive BOOLEAN NOT NULL DEFAULT TRUE,
    unit VARCHAR(30) NOT NULL DEFAULT 'plate',
    is_available BOOLEAN NOT NULL DEFAULT TRUE,
    image_path TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ,
    server_version BIGINT DEFAULT nextval('global_sync_sequence')
);

CREATE TABLE IF NOT EXISTS product_images (
    id UUID PRIMARY KEY,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    file_path VARCHAR(255) NOT NULL,
    file_name VARCHAR(150) NOT NULL,
    file_size_bytes BIGINT NOT NULL,
    mime_type VARCHAR(50) NOT NULL,
    file_hash_sha256 VARCHAR(64) NOT NULL,
    is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    display_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    server_version BIGINT DEFAULT nextval('global_sync_sequence')
);

-- 5. CUSTOMERS & DINING TABLES
CREATE TABLE IF NOT EXISTS customers (
    id UUID PRIMARY KEY,
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    name VARCHAR(120) NOT NULL,
    phone VARCHAR(30),
    address TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ,
    server_version BIGINT DEFAULT nextval('global_sync_sequence')
);

CREATE TABLE IF NOT EXISTS dining_tables (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    table_name VARCHAR(50) NOT NULL,
    seating_capacity INTEGER DEFAULT 4,
    current_invoice_id UUID,
    is_occupied BOOLEAN NOT NULL DEFAULT FALSE,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 6. INVOICES, ITEMS, BILL NOTES & KOT RECORDS
CREATE TABLE IF NOT EXISTS invoices (
    id UUID PRIMARY KEY,
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    device_id UUID REFERENCES devices(id),
    invoice_number VARCHAR(60) NOT NULL,
    customer_id UUID REFERENCES customers(id),
    customer_name VARCHAR(120),
    customer_phone VARCHAR(30),
    subtotal_paise BIGINT NOT NULL,
    item_discount_total_paise BIGINT NOT NULL DEFAULT 0,
    bill_discount_paise BIGINT NOT NULL DEFAULT 0,
    taxable_amount_paise BIGINT NOT NULL,
    cgst_paise BIGINT NOT NULL DEFAULT 0,
    sgst_paise BIGINT NOT NULL DEFAULT 0,
    igst_paise BIGINT NOT NULL DEFAULT 0,
    round_off_paise BIGINT NOT NULL DEFAULT 0,
    grand_total_paise BIGINT NOT NULL,
    paid_amount_paise BIGINT NOT NULL DEFAULT 0,
    payment_method VARCHAR(40) NOT NULL DEFAULT 'Cash',
    payment_status VARCHAR(40) NOT NULL DEFAULT 'Paid',
    order_status VARCHAR(40) NOT NULL DEFAULT 'Completed',
    order_type VARCHAR(40) NOT NULL DEFAULT 'Dine In',
    table_number VARCHAR(40),
    delivery_address TEXT,
    kot_number VARCHAR(60),
    cashier_id VARCHAR(60),
    cashier_name VARCHAR(120),
    is_cancelled BOOLEAN NOT NULL DEFAULT FALSE,
    cancelled_at TIMESTAMPTZ,
    cancel_reason TEXT,
    idempotency_key VARCHAR(128) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    server_version BIGINT DEFAULT nextval('global_sync_sequence'),
    CONSTRAINT uq_invoice_idempotency UNIQUE (business_id, idempotency_key),
    CONSTRAINT uq_invoice_number UNIQUE (business_id, invoice_number)
);

CREATE TABLE IF NOT EXISTS invoice_items (
    id UUID PRIMARY KEY,
    invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id) ON DELETE SET NULL,
    product_name VARCHAR(150) NOT NULL,
    product_code VARCHAR(60),
    unit VARCHAR(30) NOT NULL,
    unit_price_paise BIGINT NOT NULL,
    quantity NUMERIC(10, 3) NOT NULL,
    discount_paise BIGINT NOT NULL DEFAULT 0,
    gst_rate_percent NUMERIC(5, 2) NOT NULL DEFAULT 0.00,
    is_tax_inclusive BOOLEAN NOT NULL DEFAULT TRUE,
    taxable_amount_paise BIGINT NOT NULL,
    tax_amount_paise BIGINT NOT NULL,
    total_amount_paise BIGINT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS bill_notes (
    id UUID PRIMARY KEY,
    invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    note TEXT NOT NULL,
    is_customer_facing BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    server_version BIGINT DEFAULT nextval('global_sync_sequence'),
    CONSTRAINT uq_invoice_bill_note UNIQUE (invoice_id)
);

CREATE TABLE IF NOT EXISTS kot_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    kot_number VARCHAR(60) NOT NULL,
    table_number VARCHAR(40),
    order_type VARCHAR(40) NOT NULL,
    items_json JSONB NOT NULL,
    printed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    reprinted_count INTEGER NOT NULL DEFAULT 0,
    server_version BIGINT DEFAULT nextval('global_sync_sequence')
);

-- 7. PAYMENT METHODS & PAYMENTS (ADDITIVE LEDGER)
CREATE TABLE IF NOT EXISTS payment_methods (
    id VARCHAR(40) PRIMARY KEY,
    description VARCHAR(100) NOT NULL
);

INSERT INTO payment_methods (id, description) VALUES
('Cash', 'Cash Currency Settlement'),
('UPI', 'Unified Payments Interface QR / App'),
('Card', 'Debit or Credit Card POS Swipe'),
('Split', 'Multi-mode partial cash & digital split'),
('Credit/Due', 'Customer Pending Balance Ledger')
ON CONFLICT (id) DO NOTHING;

CREATE TABLE IF NOT EXISTS payments (
    id UUID PRIMARY KEY,
    invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE RESTRICT,
    amount_paise BIGINT NOT NULL,
    payment_method VARCHAR(40) NOT NULL REFERENCES payment_methods(id),
    reference_number VARCHAR(100),
    notes TEXT,
    idempotency_key VARCHAR(128) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    server_version BIGINT DEFAULT nextval('global_sync_sequence'),
    CONSTRAINT uq_payment_idempotency UNIQUE (invoice_id, idempotency_key)
);

-- 8. SYNCHRONIZATION ENGINE & CONFLICT AUDITING
CREATE TABLE IF NOT EXISTS device_sync_state (
    device_id UUID NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    entity_name VARCHAR(60) NOT NULL,
    last_pulled_version BIGINT NOT NULL DEFAULT 0,
    last_pushed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (device_id, entity_name)
);

CREATE TABLE IF NOT EXISTS sync_logs (
    id BIGSERIAL PRIMARY KEY,
    device_id UUID NOT NULL REFERENCES devices(id),
    operation_type VARCHAR(20) NOT NULL,
    entity_name VARCHAR(60) NOT NULL,
    records_processed INTEGER NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL,
    error_message TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS sync_conflicts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id UUID NOT NULL REFERENCES devices(id),
    entity_name VARCHAR(60) NOT NULL,
    record_id UUID NOT NULL,
    client_payload JSONB NOT NULL,
    server_payload JSONB NOT NULL,
    resolution VARCHAR(30) NOT NULL,
    resolved_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 9. AUDIT LOGGING
CREATE TABLE IF NOT EXISTS audit_logs (
    id BIGSERIAL PRIMARY KEY,
    business_id UUID NOT NULL REFERENCES businesses(id),
    user_id UUID REFERENCES users(id),
    device_id UUID REFERENCES devices(id),
    action VARCHAR(60) NOT NULL,
    entity_type VARCHAR(60) NOT NULL,
    entity_id VARCHAR(100) NOT NULL,
    details JSONB,
    ip_address VARCHAR(45),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 10. INDEXES FOR PERFORMANCE & SYNC QUERY OPTIMIZATION
CREATE INDEX IF NOT EXISTS idx_products_sync ON products(business_id, server_version);
CREATE INDEX IF NOT EXISTS idx_categories_sync ON categories(business_id, server_version);
CREATE INDEX IF NOT EXISTS idx_customers_sync ON customers(business_id, server_version);
CREATE INDEX IF NOT EXISTS idx_invoices_sync ON invoices(business_id, server_version);
CREATE INDEX IF NOT EXISTS idx_invoices_created ON invoices(business_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_invoices_status ON invoices(business_id, payment_status, order_status);
CREATE INDEX IF NOT EXISTS idx_payments_sync ON payments(invoice_id, server_version);
CREATE INDEX IF NOT EXISTS idx_invoice_items_inv ON invoice_items(invoice_id);
CREATE INDEX IF NOT EXISTS idx_product_images_prod ON product_images(product_id);
