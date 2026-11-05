import { PrismaClient } from '@prisma/client';

async function main() {
  const dbUrl = process.env.DATABASE_URL;
  if (!dbUrl) {
    console.error('DATABASE_URL is not set');
    process.exit(1);
  }

  const maskedUrl = dbUrl.replace(/:([^:@]+)@/, ':***@');
  console.log(`Connecting to database at ${maskedUrl}...`);

  const prisma = new PrismaClient({
    datasources: {
      db: {
        url: dbUrl,
      },
    },
  });

  try {
    const result = await prisma.$queryRaw<Array<{ db: string; user: string; ver: string }>>`
      SELECT current_database() as db, current_user as user, version() as ver
    `;
    console.log('✔ Successfully connected to Render PostgreSQL!');
    console.log('  Database:', result[0]?.db);
    console.log('  User:', result[0]?.user);
    console.log('  Version:', result[0]?.ver);

    const tables = await prisma.$queryRaw<Array<{ tablename: string }>>`
      SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename
    `;
    console.log(`✔ Public tables found in destination: ${tables.length}`);
    for (const t of tables) {
      console.log(`    - ${t.tablename}`);
    }

    await prisma.$disconnect();
  } catch (err: any) {
    console.error('❌ Connection failed:', err.message);
    await prisma.$disconnect();
    process.exit(1);
  }
}

main();
