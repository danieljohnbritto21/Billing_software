const { PrismaClient } = require('@prisma/client');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

const prisma = new PrismaClient();

async function main() {
  console.log('=== FOODBILL PRO: APPLYING KOT PROCUREMENT LINKING MIGRATION ===');

  const migrationPath = path.join(
    __dirname,
    '../../prisma/migrations/20261109_kot_procurement_linking/migration.sql'
  );
  let sql = fs.readFileSync(migrationPath, 'utf8');

  // Strip single-line comments
  sql = sql.replace(/--.*$/gm, '');

  // Split into distinct statements
  const statements = sql
    .split(';')
    .map((s) => s.trim())
    .filter((s) => s.length > 0);

  console.log(`Executing ${statements.length} statements transactionally...`);
  await prisma.$transaction(async (tx) => {
    for (const stmt of statements) {
      console.log('Executing:', stmt.substring(0, 70).replace(/\s+/g, ' ') + '...');
      await tx.$executeRawUnsafe(stmt);
    }
  });

  console.log('✔ KOT procurement linking migration executed successfully!');

  const kotCols = await prisma.$queryRawUnsafe(`
    SELECT column_name, data_type, is_nullable
    FROM information_schema.columns
    WHERE table_name = 'kot_records'
    ORDER BY ordinal_position;
  `);
  console.log('\nUpdated kot_records columns:');
  console.table(kotCols);

  const kotItemCols = await prisma.$queryRawUnsafe(`
    SELECT column_name, data_type, is_nullable
    FROM information_schema.columns
    WHERE table_name = 'kot_items'
    ORDER BY ordinal_position;
  `);
  console.log('\nUpdated kot_items columns:');
  console.table(kotItemCols);
}

main()
  .catch((e) => {
    console.error('Migration failed:', e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
