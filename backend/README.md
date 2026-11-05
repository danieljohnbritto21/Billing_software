# FoodBill Pro — Multi-Device Synchronized POS Backend API

Enterprise Node.js & TypeScript REST API and synchronization service for FoodBill Pro, powered by PostgreSQL 16 and Prisma ORM.

---

## 1. System Architecture Overview

- **Runtime & Language:** Node.js (v20+ LTS), TypeScript 5.6
- **Web Framework:** Express 4 with Helmet, CORS, and Zod validation
- **Database & ORM:** PostgreSQL 16 with Prisma ORM 5.22
- **Synchronization Engine:** Per-business transactional change log outbox (`sync_change_log`) with atomic row-locked contiguous commit-safe cursors (`business_sync_cursors`)
- **Cloud Hosting & Security:** Render Web Service with managed PostgreSQL over TLS/HTTPS (port 5433 is never exposed publicly)

---

## 2. Prerequisites & Environment Setup

1. **PostgreSQL 16 Cluster:** Local development runs inside WSL distribution `FoodBill-Ubuntu` on port `5433`; production runs on Render Managed PostgreSQL.
2. **Environment File (`.env`):**
   ```env
   PORT=3000
   HOST=0.0.0.0
   NODE_ENV=development
   DATABASE_URL="postgresql://foodbill_app:<PASSWORD>@127.0.0.1:5433/foodbill?schema=public"
   JWT_SECRET="<SECURE_JWT_SECRET>"
   JWT_EXPIRES_IN="7d"
   IMAGE_STORAGE_PATH="/mnt/d/foodbill_storage/images"
   ```

---

## 3. Build & Run Commands

### Development Mode (with Live Reload via `tsx`):
```bash
# In WSL:
wsl -d FoodBill-Ubuntu bash -c "cd /mnt/d/billing_software/backend && npm run dev"

# Or on Windows Host:
npm run dev
```

### Production Build & Run:
```bash
# 1. Compile TypeScript:
node node_modules/typescript/bin/tsc

# 2. Start the Server:
node dist/server.js
```

### Render Deployment Configuration:
- **Build Command:** `npm install && npm run build && npx prisma generate`
- **Start Command:** `node dist/server.js`
- **Health Check Path:** `/health`
- **Environment Variables:** `DATABASE_URL`, `JWT_SECRET`, `JWT_EXPIRES_IN`, `NODE_ENV=production`

### Run Automated Integration Test Suite:
```bash
# Runs full integration tests (32 passing tests) against isolated test database:
wsl -d FoodBill-Ubuntu bash -c "cd /mnt/d/billing_software/backend && DATABASE_URL='postgresql://foodbill_app:<PASSWORD>@127.0.0.1:5433/foodbill_api_test?schema=public' node node_modules/tsx/dist/cli.mjs --test tests/api.integration.test.ts"
```

---

## 4. API Endpoints Reference

### Health & Monitoring
- `GET /health` — Verifies database connection and server uptime

### Authentication (`/api/v1/auth`)
- `POST /api/v1/auth/register-business` — Registers new business and primary Admin user
- `POST /api/v1/auth/login` — Authenticates user (Admin or Cashier) and returns JWT token
- `GET /api/v1/auth/me` — Fetches authenticated user profile and business details

### Categories (`/api/v1/categories`)
- `GET /api/v1/categories` — Lists categories (Cashier & Admin)
- `GET /api/v1/categories/:id` — Gets category by ID
- `POST /api/v1/categories` — Admin only: Creates category
- `PUT /api/v1/categories/:id` — Admin only: Updates category
- `DELETE /api/v1/categories/:id` — Admin only: Soft deletes category

### Products (`/api/v1/products`)
- `GET /api/v1/products` — Lists products with optional filtering (Cashier & Admin)
- `GET /api/v1/products/:id` — Gets product by ID
- `POST /api/v1/products` — Cashier only: Creates product
- `PUT /api/v1/products/:id` — Cashier only: Updates product
- `DELETE /api/v1/products/:id` — Cashier only: Soft deletes product

### Invoices (`/api/v1/invoices`)
- `GET /api/v1/invoices` — Lists invoices with pagination and status filters
- `GET /api/v1/invoices/:id` — Gets invoice with items, notes, and payments
- `POST /api/v1/invoices` — Cashier only: Creates invoice with items (Idempotent)
- `POST /api/v1/invoices/:id/items` — Cashier only: Adds item to open/pending invoice
- `DELETE /api/v1/invoices/:id/items/:itemId` — Cashier only: Removes item from open invoice
- `POST /api/v1/invoices/:id/finalize` — Cashier only: Finalizes invoice (locks financial fields)
- `POST /api/v1/invoices/:id/cancel` — Cancels invoice with reason

### Payments (`/api/v1/payments`)
- `GET /api/v1/payments` — Lists payments
- `POST /api/v1/payments` — Cashier only: Records payment with idempotency key, updating invoice balance

### Kitchen Order Tickets (KOT) (`/api/v1/kot`)\n- `GET /api/v1/kot` — Lists KOT records
- `POST /api/v1/kot` — Cashier only: Generates immutable KOT snapshot
- `POST /api/v1/kot/:id/reprint` — Cashier only: Increments reprint counter

### Synchronization Engine (`/api/v1/sync`)
- `GET /api/v1/sync/pull?cursor=0&limit=50` — Commit-safe pull of change log entries strictly ordered by cursor
- `POST /api/v1/sync/push` — Batch push offline mobile changes with conflict detection
- `GET /api/v1/sync/status` — Returns latest authoritative cursor for the business

### Devices & Staff Users
- `GET /api/v1/devices` — Admin only: Lists registered devices
- `POST /api/v1/devices/register` — Registers device UID and name
- `PUT /api/v1/devices/:id/authorization` — Admin only: Authorizes or revokes device
- `GET /api/v1/users` — Admin only: Lists staff
- `POST /api/v1/users` — Admin only: Creates Cashier staff
- `PUT /api/v1/users/:id/status` — Admin only: Activates or deactivates user

### Store Settings & Stats (`/api/v1/business`)
- `GET /api/v1/business/profile` — Gets store settings and profile
- `PUT /api/v1/business/profile` — Admin only: Updates store settings and prefix
- `GET /api/v1/business/stats` — Admin only: Summarizes sales, bills, and pending dues

---

## 5. Database Backup and Restore Procedures

### Create a Custom-Format Backup:
```bash
wsl -d FoodBill-Ubuntu -u postgres bash -c "pg_dump -p 5433 -Fc -d foodbill > /mnt/d/foodbill_backups/database/foodbill_\$(date +%Y%m%d_%H%M%S).dump"
```

### Verify Backup Archive:
```bash
wsl -d FoodBill-Ubuntu -u postgres bash -c "pg_restore -l <BACKUP_PATH>"
```

### Restore to Temporary Test Database:
```bash
wsl -d FoodBill-Ubuntu -u postgres bash -c "createdb -p 5433 -O foodbill_app foodbill_temp && pg_restore -p 5433 -d foodbill_temp <BACKUP_PATH>"
```
