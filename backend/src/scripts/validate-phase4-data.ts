import { PrismaClient } from '@prisma/client';

async function main() {
  const prisma = new PrismaClient();
  try {
    const users = await prisma.users.findMany({
      select: { id: true, business_id: true, username: true, role_id: true, is_active: true }
    });
    console.log('TOTAL USERS:', users.length);
    const roleCounts: Record<string, number> = {};
    users.forEach(u => roleCounts[u.role_id] = (roleCounts[u.role_id] || 0) + 1);
    console.log('USERS BY ROLE:', roleCounts);
    console.log('SAMPLE USERS (first 6):', users.slice(0, 6));

    const products = await prisma.products.findMany({
      select: { id: true, business_id: true, name: true, category_id: true, selling_price_paise: true }
    });
    console.log('\nTOTAL PRODUCTS:', products.length);
    console.log('SAMPLE PRODUCTS (first 5):', products.slice(0, 5));

    const invoices = await prisma.invoices.findMany({
      select: { id: true, business_id: true, invoice_number: true, grand_total_paise: true, customer_name: true, cashier_name: true }
    });
    console.log('\nTOTAL INVOICES:', invoices.length);
    console.log('SAMPLE INVOICES (first 5):', invoices.slice(0, 5));
  } finally {
    await prisma.$disconnect();
  }
}

main().catch(err => {
  console.error('Error:', err);
  process.exit(1);
});
