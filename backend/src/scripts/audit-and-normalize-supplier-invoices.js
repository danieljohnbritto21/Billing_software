const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log('=== AUDITING AND NORMALIZING SUPPLIER INVOICE STATUSES ===');

  const counts = await prisma.purchase_invoices.groupBy({
    by: ['invoice_status'],
    _count: { id: true },
  });
  console.log('Current invoice_status breakdown:', counts);

  const pendingCount = await prisma.purchase_invoices.count({
    where: { invoice_status: 'PENDING_VERIFICATION' },
  });
  console.log(`Found ${pendingCount} invoices with PENDING_VERIFICATION.`);

  if (pendingCount > 0) {
    const res = await prisma.purchase_invoices.updateMany({
      where: { invoice_status: 'PENDING_VERIFICATION' },
      data: { invoice_status: 'SUBMITTED' },
    });
    console.log(`✔ Normalized ${res.count} invoices from PENDING_VERIFICATION to SUBMITTED.`);
  }

  const updatedCounts = await prisma.purchase_invoices.groupBy({
    by: ['invoice_status'],
    _count: { id: true },
  });
  console.log('Updated invoice_status breakdown:', updatedCounts);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
