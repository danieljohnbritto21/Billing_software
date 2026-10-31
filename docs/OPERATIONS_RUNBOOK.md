# FoodBill Pro — Operations & Disaster Recovery Runbook

## 1. PostgreSQL Database Operations & Security

### Port & Network Security
- **Port 5433:** PostgreSQL is configured to listen strictly on `127.0.0.1` (loopback).
- Never expose port 5433 or 5432 to external or public interfaces.
- The backend application connects locally via Unix domain socket or `localhost:5433`.

### Verifying PostgreSQL Service
```bash
# In WSL / Linux host:
sudo systemctl status postgresql
# Verify port binding is local:
sudo ss -tulpn | grep 5433
```

---

## 2. Automated & Manual Database Backups

### Generating an Instant Full Backup
To create a verified, compressed binary backup of the authoritative PostgreSQL database:
```bash
# Execute within WSL:
sudo -u postgres pg_dump -p 5433 -Fc -f /var/backups/foodbill_$(date +%Y%m%d_%H%M%S).dump foodbill
```

### Automated Nightly Backup Cron
Add the following line to `/etc/cron.d/foodbill_backup`:
```cron
0 2 * * * postgres pg_dump -p 5433 -Fc -f /var/backups/foodbill_$(date +\%Y\%m\%d).dump foodbill
```

### Restoring from Backup (Disaster Recovery)
```bash
# 1. Stop backend services to avoid concurrent writes:
pm2 stop foodbill-backend

# 2. Terminate existing database connections:
sudo -u postgres psql -p 5433 -d postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'foodbill';"

# 3. Drop and recreate clean database:
sudo -u postgres dropdb -p 5433 foodbill
sudo -u postgres createdb -p 5433 foodbill -O foodbill_app

# 4. Restore dump:
sudo -u postgres pg_restore -p 5433 -d foodbill --no-owner --role=foodbill_app /var/backups/foodbill_YYYYMMDD_HHMMSS.dump

# 5. Restart backend:
pm2 restart foodbill-backend
```

---

## 3. Backend Service Management

The backend application is located at `D:\billing_software\backend`.

### Building & Running Production Backend
```bash
cd D:\billing_software\backend
npm run build
npm run start
```

### Environment Configuration
The `.env` file must be stored securely and excluded from version control:
```env
PORT=3000
NODE_ENV=production
DATABASE_URL="postgresql://foodbill_app:<SECURE_PASSWORD>@127.0.0.1:5433/foodbill?schema=public"
JWT_SECRET="<SECURE_JWT_SECRET>"
JWT_EXPIRATION="7d"
CORS_ORIGIN="*"
```

---

## 4. SQLite Client Recovery

In the event a mobile device experiences file corruption or loss:
1. Re-install the FoodBill Pro APK.
2. Sign in with the registered Cashier or Admin credentials.
3. The app automatically initializes Drift SQLite schema version 6.
4. The two-way sync engine initiates an initial pull from `cursor = 0`.
5. All categories, products, customer records, dining tables, and invoices are automatically restored from the server within seconds.
