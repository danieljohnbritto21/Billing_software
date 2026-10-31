# FoodBill Pro — Architecture & Security Documentation

## 1. System Architecture Overview

FoodBill Pro is an offline-first restaurant point-of-sale (POS) and inventory management system designed for high reliability, concurrent multi-device operations, and zero data loss.

```
┌─────────────────────────────────┐       ┌─────────────────────────────────┐
│     Phone A (Admin Device)      │       │    Phone B (Cashier Device)     │
│  - Categories Management        │       │  - Menu & Ordering              │
│  - Cashiers / Staff             │       │  - Add / Manage Products        │
│  - Financial Reports & Bills    │       │  - Table Management & KOT       │
│  - Drift SQLite (Schema v6)     │       │  - Drift SQLite (Schema v6)     │
└────────────────┬────────────────┘       └────────────────┬────────────────┘
                 │                                         │
                 │ HTTP REST / JSON (JWT, Device UID, Idemp)│
                 ▼                                         ▼
┌───────────────────────────────────────────────────────────────────────────┐
│                       FoodBill Pro Backend API                            │
│  - Node.js, Express, TypeScript, Prisma ORM                               │
│  - Port 3000 (LAN / Tailscale / Cloud)                                    │
│  - Device Registration & Admin Approval Gatekeeper                        │
│  - Two-Way Synchronizer with Commit-Safe Cursor Outbox                    │
└─────────────────────────────────────┬─────────────────────────────────────┘
                                      │
                                      ▼
┌───────────────────────────────────────────────────────────────────────────┐
│                    Authoritative PostgreSQL Database                      │
│  - 23 hardened public tables                                              │
│  - Per-business sync outbox (`sync_outbox`) with committed cursors        │
│  - Pure integer paise currency representation                             │
│  - Multi-tenant business isolation with RLS and foreign keys              │
└───────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Security Model & Role Separation

### Role & Access Matrix

| Capability / Route | Admin | Cashier | Guarded Layer |
| :--- | :---: | :---: | :--- |
| **Login / Authentication** | Yes | Yes | JWT + BCrypt + Active check |
| **Dashboard & Sales Overview** | Yes | No | Flutter Route Guard (`checkRouteAccess`) |
| **Category Management** | Yes | No | Backend API + Flutter UI |
| **Product Creation & Editing** | **NO** | **YES** | Flutter Route Guard (`/products/add` blocked for Admin) |
| **Point of Sale (POS) Menu** | Read-Only | Yes | Separate interactive POS screens |
| **Cart, Checkout & Payments** | Yes | Yes | Riverpod State + SQLite |
| **KOT & Final Bill Printing** | Yes | Yes | ESC/POS (58mm/80mm) & PDF Thermal |
| **Staff & User Management** | Yes | No | Backend Admin Gate + Flutter Screen |
| **Device Approval / Revocation**| Yes | No | Backend Admin Middleware |

### Admin vs. Cashier Product Separation
- **Critical Policy:** Admin does **not** have "Add Product" or "Edit Product" capabilities.
- When an Admin attempts to access `/products/add` or `/products/edit`, the router automatically redirects to `/categories`.
- The Cashier is the primary product steward at the counter, equipped with full product creation, pricing, unit selection, tax settings, and up to 10 product images.

---

## 3. Financial Integrity & Zero Floating-Point Arithmetic
All monetary values (selling price, cost price, tax amounts, line item totals, discounts, grand totals, and payment amounts) are strictly stored and computed as **integer paise** (1 Rupee = 100 Paise).

- Storage: SQLite `INTEGER` / PostgreSQL `BIGINT`.
- Calculations: `CurrencyFormatter.calculateItemTax` and `InvoiceRepository` use integer arithmetic.
- Round-off: 50-paise rounding logic with difference explicitly captured in `round_off_paise`.

---

## 4. Hardware Printing Architecture
- **KOT (Kitchen Order Ticket):** Outputs item names, quantities, order type, table number, server name, and timestamp. Zero prices printed on KOT.
- **Customer Final Bill:** Outputs business name, GSTIN, invoice number, table number, order type, line item rates/amounts, tax breakdown (CGST/SGST), payment breakdown, and footer message.
- **ESC/POS Generator:** Direct byte generation for 58mm and 80mm thermal receipt printers via Bluetooth/USB/Network.
- **PDF Thermal Generator:** Generates rasterized PDF receipts with automatic Unicode fallback (`Rs.` for ASCII/Helvetica environments, `₹` for Unicode environments).
