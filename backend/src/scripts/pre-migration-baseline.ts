import { PrismaClient } from '@prisma/client';

async function main() {
  const prisma = new PrismaClient();
  try {
    const tables = [
      'businesses', 'business_settings', 'users', 'roles', 'user_sessions',
      'devices', 'audit_logs', 'categories', 'products', 'product_images',
      'invoices', 'invoice_items', 'payments', 'payment_methods', 'bill_notes',
      'kot_records', 'dining_tables', 'customers', 'business_sync_cursors',
      'device_sync_state', 'sync_change_log', 'sync_conflicts', 'sync_logs'
    ];

    console.log('=== PRE-PHASE-5 PRODUCTION BASELINE AUDIT ===');
    for (const t of tables) {
      const res = await prisma.$queryRawUnsafe<Array<{ count: string }>>(`SELECT count(*)::text as count FROM "${t}"`);
      console.log(`${t.padEnd(25)} : ${res[0].count}`);
    }
  } finally {
    await prisma.$disconnect();
  }
}

main().catch(e => { console.error(e); process.exit(1); });
