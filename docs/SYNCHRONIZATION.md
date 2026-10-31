# FoodBill Pro — Two-Way Synchronization & Multi-Phone Protocol

## 1. Overview & Core Philosophy

FoodBill Pro implements an offline-first, asynchronous two-way synchronization engine. Cashiers and Admins can create orders, register payments, and add products even when network connectivity is intermittent or unavailable.

The synchronization system guarantees:
1. **At-Least-Once Delivery with Idempotency:** Changes are pushed with UUIDv4 idempotency keys. Duplicate submissions are detected and acknowledged without duplicate side-effects.
2. **Commit-Safe Cursor Monotonicity:** Downstream synchronization uses a persistent integer commit cursor (`last_server_cursor`). The local cursor advances **only after** an entire batch of changes is successfully written into local SQLite inside an atomic transaction.
3. **Financial Immutability:** Historical invoices, invoice items, and payment transactions are never silently overwritten or mutated during conflict resolution.
4. **Soft-Deletion Propagation:** Products or categories deleted on one device are marked with `deleted_at` timestamps, preserving foreign-key referential integrity on devices with historical billing records.

---

## 2. Shared Entities

The synchronization engine handles the following business entities:
- `categories`: Menu category groups, display orders, active status.
- `products`: Food items, SKU, unit, tax rate, pricing in paise, availability.
- `product_images`: Up to 10 photos per product, primary flags, base64 data payloads.
- `dining_tables`: Restaurant floor layout, table names, capacity, occupancy status.
- `customers`: Customer names, phone numbers, delivery addresses.
- `invoices`: Master invoice records, order types (Dine In / Takeaway / Delivery), table assignments, subtotal, taxes, grand total, payment status.
- `invoice_items`: Snapshot item lines with historical rates and quantities.
- `payments`: Split and full payment records (Cash, UPI, Card, Due).
- `kot_records`: Kitchen tickets, print counts, status.

---

## 3. Upload Flow (`POST /api/v1/sync/push`)

```
Local SQLite (SyncQueue)
       │
       │ Select pending items (limit 50)
       ▼
HTTP POST /api/v1/sync/push
  - Headers: Authorization (JWT), X-Device-Id (UUID), X-Idempotency-Key
  - Body: { deviceId, items: [ { entityName, operation, recordId, clientVersion, payload } ] }
       │
       ▼
Backend PostgreSQL Transaction:
  1. Verify Device authorization & business isolation.
  2. For each item:
     - Check conflict (compare clientVersion vs server version).
     - Apply INSERT / UPDATE / DELETE to authoritative domain table.
     - Append change event to `sync_outbox` in the SAME transaction.
  3. Return results array: [ { recordId, status: "synced" | "conflict" | "error" } ]
       │
       ▼
Local SQLite Transaction:
  - If "synced": Delete item from SyncQueue.
  - If "conflict": Insert into SyncConflicts table (SERVER_WINS resolution logged) & remove from queue.
  - If "failed": Increment retryCount, record lastError.
```

---

## 4. Download Flow (`GET /api/v1/sync/pull`)

```
Local SQLite (SyncCursors)
       │
       │ Query current cursor: `SELECT last_server_cursor FROM sync_cursors WHERE sync_entity = 'global'`
       ▼
HTTP GET /api/v1/sync/pull?cursor={currentCursor}&limit=50
       │
       ▼
Backend Database:
  - Query `sync_outbox` where `business_id = user.businessId` AND `id > cursor` ORDER BY `id` ASC LIMIT 50.
  - Return: { changes: [...], nextCursor: 142, hasMore: true }
       │
       ▼
Local SQLite Transaction:
  - Begin Drift Database Transaction:
    - For each change: Apply change to local table (INSERT / UPDATE / SOFT-DELETE).
    - Advance cursor in `sync_cursors`: `INSERT OR REPLACE INTO sync_cursors VALUES ('global', bizId, 142)`.
  - Commit Transaction.
  (If any local error occurs, transaction rolls back and cursor remains at previous safe checkpoint).
```

---

## 5. Multi-Phone Migration & Setup

When onboarding Phone A (Admin) and Phone B (Cashier) to the same restaurant business:
1. **Device Registration:** Each phone generates a hardware/UUID-backed `deviceId` on initial launch and requests registration via `POST /api/v1/devices/register`.
2. **Admin Approval:** Admin approves the cashier's device in Store Settings / Authorized Devices.
3. **Initial Upload:** Unsynced offline records created prior to pairing are queued into `SyncQueue` and uploaded idempotently.
4. **Historical Reconciliation:** If the same product name was created on both devices, the server reconciles records using unique SKU/Name constraints and returns the authoritative record ID.
5. **Full Seed Synchronization:** Once approved, Phone B pulls from `cursor = 0`, populating all categories created by the Admin and existing menu items.
