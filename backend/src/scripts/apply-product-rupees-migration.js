const { PrismaClient } = require('@prisma/client');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

const prisma = new PrismaClient();

async function main() {
  console.log('=== APPLYING PRODUCT PRICES RUPEE MIGRATION ===');

  // 1. Pre-migration check
  const countBefore = await prisma.products.count();
  console.log(`Verified ${countBefore} total products before migration.`);

  // 2. Read migration SQL
  const migrationPath = path.join(__dirname, '../../prisma/migrations/20261109_product_prices_to_rupees/migration.sql');
  const sql = fs.readFileSync(migrationPath, 'utf8');

  // 3. Execute migration inside transaction
  console.log('Executing migration transaction on PostgreSQL...');
  await prisma.$executeRawUnsafe(sql);
  console.log('✔ Migration SQL executed successfully!');

  // 4. Verify post-migration columns and backfilled values
  const products = await prisma.$queryRaw`
    SELECT id, name, cost_price_paise, selling_price_paise, cost_price_rupees, selling_price_rupees
    FROM "products"
    ORDER BY name ASC
    LIMIT 10;
  `;
  console.log('\nSample Converted Products:');
  console.log(products);

  // 5. Verify no NULLs or mismatched calculations
  const mismatches = await prisma.$queryRaw`
    SELECT count(*)::int as mismatch_count
    FROM "products"
    WHERE
      cost_price_rupees != ROUND(COALESCE(cost_price_paise, 0)::numeric / 100.0, 2)
      OR selling_price_rupees != ROUND(COALESCE(selling_price_paise, 0)::numeric / 100.0, 2);
  `;
  console.log('\nIntegrity verification check (mismatches):', mismatches);

  await prisma.$disconnect();
}

if (process.argv.includes('--execute')) {
  main().catch((err) => {
    console.error('Migration execution failed:', err);
    process.exit(1);
  });
} else {
  console.log('DRY RUN / SAFEGUARD: Pass --execute to apply this migration to PostgreSQL.');
}
