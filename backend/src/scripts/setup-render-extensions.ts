import { PrismaClient } from '@prisma/client';

async function main() {
  const prisma = new PrismaClient();
  try {
    await prisma.$executeRawUnsafe('CREATE EXTENSION IF NOT EXISTS "uuid-ossp";');
    await prisma.$executeRawUnsafe('CREATE EXTENSION IF NOT EXISTS "pgcrypto";');
    const ext = await prisma.$queryRaw<Array<{ extname: string; extversion: string }>>`
      SELECT extname, extversion FROM pg_extension
    `;
    console.log('✔ Extensions on Render:', ext);
  } finally {
    await prisma.$disconnect();
  }
}

main().catch(err => {
  console.error('Extension error:', err);
  process.exit(1);
});
