import { PrismaClient } from '@prisma/client';

async function main() {
  const prisma = new PrismaClient();
  try {
    const tables = [
      'businesses',
      'users',
      'roles',
      'categories',
      'products',
      'invoices',
      'invoice_items',
      'payments',
      'payment_methods',
      'devices',
      'sync_change_log',
      'business_settings',
      'business_sync_cursors',
      'customers',
      'dining_tables',
    ];

    console.log('==============================================');
    console.log('       RENDER DATABASE TABLE AUDIT            ');
    console.log('==============================================');
    for (const t of tables) {
      try {
        const res = await prisma.$queryRawUnsafe<Array<{ cnt: string }>>(
          `SELECT count(*)::text as cnt FROM "${t}"`
        );
        console.log(`  ${t.padEnd(25)} : ${res[0].cnt}`);
      } catch (err: any) {
        console.log(`  ${t.padEnd(25)} : [ERROR / NOT FOUND] ${err.message}`);
      }
    }

    console.log('----------------------------------------------');
    const triggers = await prisma.$queryRawUnsafe<Array<{ tgname: string; relname: string }>>(`
      SELECT tgname, relname FROM pg_trigger
      JOIN pg_class ON pg_trigger.tgrelid = pg_class.oid
      WHERE NOT tgisinternal
      ORDER BY relname, tgname
    `);
    console.log(`✔ Active custom triggers: ${triggers.length}`);
    for (const trg of triggers) {
      console.log(`    ${trg.relname} -> ${trg.tgname}`);
    }

    console.log('----------------------------------------------');
    const seqs = await prisma.$queryRawUnsafe<Array<{ sequencename: string; last_value: string }>>(`
      SELECT sequencename, last_value::text FROM pg_sequences
    `);
    console.log('✔ Sequences:');
    for (const s of seqs) {
      console.log(`    ${s.sequencename}: last_value = ${s.last_value}`);
    }

    console.log('----------------------------------------------');
    // Test sample query to verify relationships
    const bizSample = await prisma.$queryRawUnsafe<Array<{ id: string; name: string }>>(`
      SELECT id, name FROM businesses LIMIT 3
    `);
    console.log('✔ Sample Businesses in Render:', bizSample);

    const prodSample = await prisma.$queryRawUnsafe<Array<{ id: string; name: string; selling_price_paise: string }>>(`
      SELECT id, name, selling_price_paise::text FROM products LIMIT 5
    `);
    console.log('✔ Sample Products in Render:', prodSample);

    console.log('==============================================');
  } finally {
    await prisma.$disconnect();
  }
}

main().catch(err => {
  console.error('Audit failed:', err);
  process.exit(1);
});
