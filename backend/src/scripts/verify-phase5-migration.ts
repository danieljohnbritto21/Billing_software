import { PrismaClient } from '@prisma/client';

async function main() {
  const prisma = new PrismaClient();
  try {
    console.log('===============================================================');
    console.log('       FOODBILL PRO: PHASE 5 DATABASE VERIFICATION REPORT      ');
    console.log('===============================================================');

    // 1. Table Counts Audit
    const tables = [
      'businesses',
      'business_settings',
      'roles',
      'users',
      'user_sessions',
      'devices',
      'categories',
      'suppliers',
      'products',
      'product_images',
      'orders',
      'order_items',
      'invoices',
      'invoice_items',
      'payments',
      'payment_methods',
      'bill_notes',
      'kot_records',
      'kot_items',
      'purchase_orders',
      'purchase_order_items',
      'purchase_invoices',
      'purchase_invoice_items',
      'supplier_payments',
      'dining_tables',
      'business_sync_cursors',
      'device_sync_state',
      'sync_change_log',
      'sync_conflicts',
      'sync_logs'
    ];

    console.log('1. TABLE ROW COUNTS:');
    for (const t of tables) {
      try {
        const res = await prisma.$queryRawUnsafe<Array<{ cnt: string }>>(`SELECT count(*)::text as cnt FROM "${t}"`);
        console.log(`   ${t.padEnd(26)} : ${res[0].cnt}`);
      } catch (err: any) {
        console.log(`   ${t.padEnd(26)} : [ERROR] ${err.message}`);
      }
    }

    // 2. Data Integrity Checks
    console.log('\n2. DATA INTEGRITY & RELATIONSHIP AUDITS:');

    // Check products supplier_id
    const productsWithoutSupplier = await prisma.$queryRawUnsafe<Array<{ cnt: string }>>(`
      SELECT count(*)::text as cnt FROM products WHERE supplier_id IS NULL;
    `);
    console.log(`   Products without supplier_id                : ${productsWithoutSupplier[0].cnt} (Expected: 0)`);

    // Check invoices order_id
    const invoicesWithoutOrder = await prisma.$queryRawUnsafe<Array<{ cnt: string }>>(`
      SELECT count(*)::text as cnt FROM invoices WHERE order_id IS NULL;
    `);
    console.log(`   Invoices without order_id                   : ${invoicesWithoutOrder[0].cnt} (Expected: 0)`);

    // Check order_items count vs invoice_items
    const orderItemsCount = await prisma.$queryRawUnsafe<Array<{ cnt: string }>>(`
      SELECT count(*)::text as cnt FROM order_items;
    `);
    const invoiceItemsCount = await prisma.$queryRawUnsafe<Array<{ cnt: string }>>(`
      SELECT count(*)::text as cnt FROM invoice_items;
    `);
    console.log(`   Order items (${orderItemsCount[0].cnt}) vs Invoice items (${invoiceItemsCount[0].cnt}) : Match = ${orderItemsCount[0].cnt === invoiceItemsCount[0].cnt}`);

    // Check payments order_id
    const paymentsWithoutOrder = await prisma.$queryRawUnsafe<Array<{ cnt: string }>>(`
      SELECT count(*)::text as cnt FROM payments WHERE order_id IS NULL;
    `);
    console.log(`   Payments without order_id                   : ${paymentsWithoutOrder[0].cnt} (Expected: 0)`);

    // Check financial sum consistency between orders and invoices
    const financialMismatch = await prisma.$queryRawUnsafe<Array<{ diff_count: string }>>(`
      SELECT count(*)::text as diff_count
      FROM orders o
      JOIN invoices i ON i.order_id = o.id
      WHERE o.grand_total_paise <> i.grand_total_paise
         OR o.taxable_amount_paise <> i.taxable_amount_paise;
    `);
    console.log(`   Financial discrepancies between order & inv : ${financialMismatch[0].diff_count} (Expected: 0)`);

    // Check user roles distribution
    const roleDist = await prisma.$queryRawUnsafe<Array<{ role_id: string; cnt: string }>>(`
      SELECT role_id, count(*)::text as cnt FROM users GROUP BY role_id ORDER BY role_id;
    `);
    console.log('   User roles distribution                     :', roleDist);

    // Check active triggers count
    const triggerCount = await prisma.$queryRawUnsafe<Array<{ cnt: string }>>(`
      SELECT count(*)::text as cnt FROM pg_trigger WHERE NOT tgisinternal;
    `);
    console.log(`   Active custom triggers in PostgreSQL       : ${triggerCount[0].cnt} (Expected: 32)`);

    console.log('===============================================================');
  } finally {
    await prisma.$disconnect();
  }
}

main().catch(e => { console.error(e); process.exit(1); });
