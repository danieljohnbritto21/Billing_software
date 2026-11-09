const { PrismaClient } = require('@prisma/client');
require('dotenv').config();

const prisma = new PrismaClient();

async function main() {
  console.log('=== APPLYING PRODUCT PRICES RUPEE MIGRATION ===');

  // 1. Pre-migration check
  const countBefore = await prisma.products.count();
  console.log(`Verified ${countBefore} total products before migration.`);

  console.log('Executing step-by-step DDL/DML on PostgreSQL...');

  // Step 1: Add columns
  await prisma.$executeRawUnsafe(`
    ALTER TABLE "products"
    ADD COLUMN IF NOT EXISTS "cost_price_rupees" NUMERIC(12,2) DEFAULT 0.00;
  `);
  console.log('✔ Added cost_price_rupees column.');

  await prisma.$executeRawUnsafe(`
    ALTER TABLE "products"
    ADD COLUMN IF NOT EXISTS "selling_price_rupees" NUMERIC(12,2) DEFAULT 0.00;
  `);
  console.log('✔ Added selling_price_rupees column.');

  // Step 2: Backfill existing records
  await prisma.$executeRawUnsafe(`
    UPDATE "products"
    SET
      "cost_price_rupees" = ROUND(COALESCE("cost_price_paise", 0)::numeric / 100.0, 2),
      "selling_price_rupees" = ROUND(COALESCE("selling_price_paise", 0)::numeric / 100.0, 2);
  `);
  console.log('✔ Backfilled cost_price_rupees and selling_price_rupees for all products.');

  // Step 3: Set NOT NULL
  await prisma.$executeRawUnsafe(`
    ALTER TABLE "products"
    ALTER COLUMN "cost_price_rupees" SET NOT NULL;
  `);
  await prisma.$executeRawUnsafe(`
    ALTER TABLE "products"
    ALTER COLUMN "selling_price_rupees" SET NOT NULL;
  `);
  console.log('✔ Enforced NOT NULL on rupee columns.');

  // Step 4: Index
  await prisma.$executeRawUnsafe(`
    CREATE INDEX IF NOT EXISTS "idx_products_selling_price_rupees"
    ON "products" ("business_id", "selling_price_rupees");
  `);
  console.log('✔ Created index idx_products_selling_price_rupees.');

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
