import { prisma } from '../config/prisma';

async function main() {
  console.log('=== AUDITING CURRENT RENDER POSTGRESQL STATE ===');

  const [
    invoicesCount,
    invoiceItemsCount,
    purchaseInvoicesCount,
    purchaseInvoiceItemsCount,
    productsCount,
    suppliersCount,
    supplierPaymentsCount,
  ] = await Promise.all([
    prisma.invoices.count(),
    prisma.invoice_items.count(),
    prisma.purchase_invoices.count(),
    prisma.purchase_invoice_items.count(),
    prisma.products.count({ where: { deleted_at: null } }),
    prisma.suppliers.count({ where: { deleted_at: null } }),
    prisma.supplier_payments.count(),
  ]);

  console.log(`Table Counts:
  - invoices: ${invoicesCount}
  - invoice_items: ${invoiceItemsCount}
  - purchase_invoices: ${purchaseInvoicesCount}
  - purchase_invoice_items: ${purchaseInvoiceItemsCount}
  - products (active): ${productsCount}
  - suppliers (active): ${suppliersCount}
  - supplier_payments: ${supplierPaymentsCount}`);

  console.log('\n--- ALL PURCHASE INVOICES (Procurement Domain) ---');
  const pis = await prisma.purchase_invoices.findMany({
    select: {
      id: true,
      supplier_invoice_number: true,
      supplier_id: true,
      grand_total_paise: true,
      balance_due_paise: true,
      invoice_status: true,
      payment_status: true,
      created_at: true,
      purchase_invoice_items: {
        select: {
          id: true,
          product_name_snapshot: true,
          quantity: true,
          unit_price_paise: true,
          total_amount_paise: true,
        },
      },
    },
    orderBy: { created_at: 'desc' },
  });
  console.log(JSON.stringify(pis, (k, v) => typeof v === 'bigint' ? v.toString() : v, 2));

  console.log('\n--- ALL INVOICES (Customer Sales Domain) ---');
  const sales = await prisma.invoices.findMany({
    select: {
      id: true,
      invoice_number: true,
      grand_total_paise: true,
      payment_status: true,
      order_status: true,
      created_at: true,
      invoice_items: {
        select: {
          id: true,
          product_name: true,
          quantity: true,
          unit_price_paise: true,
          total_amount_paise: true,
        },
      },
    },
    orderBy: { created_at: 'desc' },
    take: 10,
  });
  console.log(JSON.stringify(sales, (k, v) => typeof v === 'bigint' ? v.toString() : v, 2));

  console.log('\n--- ALL 47 PRODUCTS BEFORE/AFTER PREVIEW ---');
  const products = await prisma.products.findMany({
    where: { deleted_at: null },
    select: {
      id: true,
      name: true,
      code: true,
      cost_price_paise: true,
      selling_price_paise: true,
      unit: true,
    },
    orderBy: { name: 'asc' },
  });

  console.log(`Found ${products.length} active products:`);
  products.forEach((p, idx) => {
    const costPaise = Number(p.cost_price_paise);
    const sellingPaise = Number(p.selling_price_paise);
    const costRupees = (costPaise / 100).toFixed(2);
    const sellingRupees = (sellingPaise / 100).toFixed(2);
    console.log(
      `#${idx + 1}: [${p.id}] ${p.name} (${p.code || 'NO_CODE'}) | Cost: ${costPaise}p -> ₹${costRupees} | Sell: ${sellingPaise}p -> ₹${sellingRupees} | Unit: ${p.unit}`
    );
  });

  await prisma.$disconnect();
}

main().catch((e) => {
  console.error('Audit failed:', e);
  process.exit(1);
});
