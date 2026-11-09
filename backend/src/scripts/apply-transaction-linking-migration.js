const { PrismaClient } = require('@prisma/client');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

const prisma = new PrismaClient();

async function main() {
  console.log('=== FOODBILL PRO: APPLYING TRANSACTION LINKING MIGRATION ===');

  // 1. Audit current counts
  const [ordersCount, invoicesCount, kotCount, poCount, piCount] = await Promise.all([
    prisma.orders.count(),
    prisma.invoices.count(),
    prisma.kot_records.count(),
    prisma.purchase_orders.count(),
    prisma.purchase_invoices.count(),
  ]);

  console.log(`Current Document Counts:
  - orders: ${ordersCount}
  - invoices: ${invoicesCount}
  - kot_records: ${kotCount}
  - purchase_orders: ${poCount}
  - purchase_invoices: ${piCount}`);

  // 2. Read forward migration
  const migrationPath = path.join(
    __dirname,
    '../../prisma/migrations/20261109_unified_transaction_linking/migration.sql'
  );
  const sql = fs.readFileSync(migrationPath, 'utf8');

  // 3. Execute migration transaction safely
  console.log('\nExecuting transactional migration on PostgreSQL...');
  await prisma.$executeRawUnsafe(sql);
  console.log('✔ Transaction linking migration executed successfully!');

  // 4. Verify backfill
  const [sampleSales, sampleProcurement] = await Promise.all([
    prisma.$queryRaw`
      SELECT o.id as order_id, o.order_number, o.transaction_id, i.id as invoice_id, i.invoice_number, i.transaction_id as inv_transaction_id
      FROM "orders" o
      LEFT JOIN "invoices" i ON i.order_id = o.id
      LIMIT 5;
    `,
    prisma.$queryRaw`
      SELECT pi.id as pi_id, pi.supplier_invoice_number, pi.transaction_id, po.id as po_id, po.order_number as po_number
      FROM "purchase_invoices" pi
      LEFT JOIN "purchase_orders" po ON po.id = pi.purchase_order_id
      LIMIT 5;
    `,
  ]);

  console.log('\nSample Linked Sales Transactions:');
  console.log(sampleSales);

  console.log('\nSample Linked Procurement Transactions:');
  console.log(sampleProcurement);

  await prisma.$disconnect();
}

if (process.argv.includes('--execute')) {
  main().catch((err) => {
    console.error('Migration failed:', err);
    process.exit(1);
  });
} else {
  console.log('DRY RUN / SAFEGUARD: Pass --execute to apply this migration to PostgreSQL.');
}
