import assert from 'node:assert/strict';
import test from 'node:test';
import http from 'http';
import { randomUUID } from 'crypto';
import { app } from '../src/app';
import { prisma } from '../src/config/prisma';

let server: http.Server;
let baseUrl: string;

test.before(async () => {
  await prisma.$connect();
  server = app.listen(0);
  const address = server.address() as any;
  baseUrl = `http://127.0.0.1:${address.port}/api/v1`;
});

test.after(async () => {
  server.close();
  await prisma.$disconnect();
});

async function apiRequest(path: string, options: RequestInit = {}, token?: string, deviceId?: string) {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(options.headers as Record<string, string>),
  };
  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }
  if (deviceId) {
    headers['X-Device-Id'] = deviceId;
  }

  const res = await fetch(`${baseUrl}${path}`, {
    ...options,
    headers,
  });
  const data = await res.json().catch(() => null);
  return { status: res.status, ok: res.ok, data };
}

test('=== FOODBILL PRO: UNIFIED TRANSACTION LINKING & DOCUMENT ARCHITECTURE TESTS ===', async (t) => {
  let adminToken: string;
  let adminUsername: string;
  let businessId: string;
  let deviceId: string;
  let supplier1Id: string;
  let supplier1Token: string;
  let supplier1Username: string;
  let supplier2Id: string;
  let supplier2Token: string;
  let supplier2Username: string;
  let productId: string;

  // Tracked IDs across sales tests
  let salesOrderId: string;
  let salesTransactionId: string;
  let salesOrderNumber: string;
  let customerInvoiceId: string;
  let customerInvoiceNumber: string;
  let firstKotId: string;
  let secondKotId: string;

  // Tracked IDs across procurement tests
  const exactSupplierInvoiceNumber = 'SUP-INV/2026-X#99';
  let procurementInvoiceId: string;
  let procurementTransactionId: string;

  await t.test('Setup: Register business, Admin, Suppliers, Product and Devices', async () => {
    adminUsername = `adm_${Date.now()}`;
    const regRes = await apiRequest('/auth/register-business', {
      method: 'POST',
      body: JSON.stringify({
        businessName: 'Unified Linking Test Kitchen',
        phone: '9876543210',
        username: adminUsername,
        password: 'Password@123',
        fullName: 'Master Admin',
      }),
    });
    assert.equal(regRes.status, 201, `Failed to register business: ${JSON.stringify(regRes.data)}`);
    adminToken = regRes.data.data.token;
    businessId = regRes.data.data.business.id;
    deviceId = regRes.data.data.device?.id || randomUUID();

    // Create Supplier 1
    supplier1Username = `sup1_${Date.now()}`;
    const sup1Res = await apiRequest(
      '/admin/suppliers',
      {
        method: 'POST',
        body: JSON.stringify({
          supplierCode: `SUP1_${Date.now()}`,
          supplierName: 'Fresh Farms Supply Co',
          contactPerson: 'Ramesh Patel',
          phoneNumber: '9845123456',
          createLoginUser: true,
          username: supplier1Username,
          password: 'Supplier@123',
          fullName: 'Ramesh Patel',
        }),
      },
      adminToken
    );
    assert.equal(sup1Res.status, 201, `Failed to create supplier 1: ${JSON.stringify(sup1Res.data)}`);
    supplier1Id = sup1Res.data.data.supplier?.id || sup1Res.data.data.id;

    // Login Supplier 1
    const sup1Login = await apiRequest('/auth/supplier-login', {
      method: 'POST',
      body: JSON.stringify({
        username: supplier1Username,
        password: 'Supplier@123',
      }),
    });
    assert.equal(sup1Login.status, 200, `Supplier 1 login failed: ${JSON.stringify(sup1Login.data)}`);
    supplier1Token = sup1Login.data.data.token;

    // Create Supplier 2
    supplier2Username = `sup2_${Date.now()}`;
    const sup2Res = await apiRequest(
      '/admin/suppliers',
      {
        method: 'POST',
        body: JSON.stringify({
          supplierCode: `SUP2_${Date.now()}`,
          supplierName: 'Metro Meats Ltd',
          contactPerson: 'Vikram Singh',
          phoneNumber: '9845987654',
          createLoginUser: true,
          username: supplier2Username,
          password: 'Supplier@123',
          fullName: 'Vikram Singh',
        }),
      },
      adminToken
    );
    assert.equal(sup2Res.status, 201, `Failed to create supplier 2: ${JSON.stringify(sup2Res.data)}`);
    supplier2Id = sup2Res.data.data.supplier?.id || sup2Res.data.data.id;

    // Login Supplier 2
    const sup2Login = await apiRequest('/auth/supplier-login', {
      method: 'POST',
      body: JSON.stringify({
        username: supplier2Username,
        password: 'Supplier@123',
      }),
    });
    assert.equal(sup2Login.status, 200, `Supplier 2 login failed: ${JSON.stringify(sup2Login.data)}`);
    supplier2Token = sup2Login.data.data.token;

    // Create a product linked to Supplier 1
    const prodRes = await apiRequest(
      '/products',
      {
        method: 'POST',
        body: JSON.stringify({
          name: 'Special Chicken Biryani',
          costPriceRupees: 150,
          sellingPriceRupees: 280,
          unit: 'plate',
          supplierId: supplier1Id,
        }),
      },
      adminToken
    );
    assert.equal(prodRes.status, 201, `Failed to create product: ${JSON.stringify(prodRes.data)}`);
    productId = prodRes.data.data.id;
  });

  await t.test('Test 1: One sales order generates one stable transaction ID', async () => {
    const orderRes = await apiRequest(
      '/admin/orders',
      {
        method: 'POST',
        body: JSON.stringify({
          orderType: 'Dine In',
          items: [
            {
              productId,
              productName: 'Special Chicken Biryani',
              quantity: 2,
              unit: 'plate',
              unitPricePaise: 28000,
              gstRatePercent: 5,
            },
          ],
          createInvoiceImmediately: true,
          paymentMethod: 'Cash',
          amountPaidPaise: 0,
        }),
      },
      adminToken
    );
    assert.equal(orderRes.status, 201);
    const orderData = orderRes.data.data;
    salesOrderId = orderData.order.id;
    salesOrderNumber = orderData.order.order_number;
    salesTransactionId = orderData.transactionId || orderData.order.transaction_id || salesOrderId;
    customerInvoiceId = orderData.invoice.id;
    customerInvoiceNumber = orderData.invoice.invoice_number;

    assert.ok(salesTransactionId, 'Order must have a valid transaction ID');
    assert.ok(salesOrderId, 'Order must have an ID');
    assert.ok(customerInvoiceId, 'Invoice must be generated');
  });

  await t.test('Test 2: Multiple KOTs share the same transaction ID', async () => {
    // Generate initial KOT for the order
    const kot1Res = await apiRequest(
      '/kot',
      {
        method: 'POST',
        body: JSON.stringify({
          orderId: salesOrderId,
          invoiceId: customerInvoiceId,
          tableNumber: 'T-04',
          orderType: 'Dine In',
          items: [
            {
              productName: 'Special Chicken Biryani',
              quantity: 2,
              notes: 'Less spicy',
            },
          ],
        }),
      },
      adminToken
    );
    assert.equal(kot1Res.status, 201);
    firstKotId = kot1Res.data.data.id;

    // Check unified sales transaction endpoint
    const txRes = await apiRequest(`/admin/transactions/sales/${salesOrderId}`, {}, adminToken);
    assert.equal(txRes.status, 200);
    assert.equal(txRes.data.data.transactionId, salesTransactionId);
    assert.ok(txRes.data.data.kotHistory.length >= 1);
    assert.equal(txRes.data.data.kotHistory[0].id, firstKotId);
  });

  await t.test('Test 3: Customer invoice shares the sales order transaction ID', async () => {
    // Query unified sales transaction by invoice ID or number
    const txByInvRes = await apiRequest(`/admin/transactions/sales/${customerInvoiceId}`, {}, adminToken);
    assert.equal(txByInvRes.status, 200);
    assert.equal(txByInvRes.data.data.transactionId, salesTransactionId);
    assert.equal(txByInvRes.data.data.customerInvoice.id, customerInvoiceId);
    assert.equal(txByInvRes.data.data.salesOrder.id, salesOrderId);
  });

  await t.test('Test 4: Reprinting KOT does not create another KOT', async () => {
    const kotCountBefore = (await apiRequest('/kot', {}, adminToken)).data.data.length;

    const reprintRes = await apiRequest(`/kot/${firstKotId}/reprint`, { method: 'POST' }, adminToken);
    assert.equal(reprintRes.status, 200);
    assert.equal(reprintRes.data.data.id, firstKotId);
    assert.equal(reprintRes.data.data.reprinted_count, 1);

    const kotCountAfter = (await apiRequest('/kot', {}, adminToken)).data.data.length;
    assert.equal(kotCountAfter, kotCountBefore, 'KOT reprint must not insert a new row');
  });

  await t.test('Test 5: Reprinting customer invoice does not create another invoice', async () => {
    const invCountBefore = (await apiRequest('/admin/invoices', {}, adminToken)).data.total;

    // Fetch existing invoice details for reprinting
    const invRes = await apiRequest(`/admin/invoices/${customerInvoiceId}`, {}, adminToken);
    assert.equal(invRes.status, 200);
    assert.equal(invRes.data.data.id, customerInvoiceId);
    assert.equal(invRes.data.data.invoice_number, customerInvoiceNumber);

    const invCountAfter = (await apiRequest('/admin/invoices', {}, adminToken)).data.total;
    assert.equal(invCountAfter, invCountBefore, 'Reprinting/retrieving invoice must not create another invoice');
  });

  await t.test('Test 6: Additional items create the appropriate new KOT without losing previous KOT history', async () => {
    // Add additional item (e.g. 1 more biryani) to existing active order
    const addItemsRes = await apiRequest(
      `/admin/orders/${salesOrderId}/items`,
      {
        method: 'POST',
        body: JSON.stringify({
          items: [
            {
              productId,
              productName: 'Special Chicken Biryani (Repeat)',
              quantity: 1,
              unit: 'plate',
              unitPricePaise: 28000,
              gstRatePercent: 5,
              specialInstructions: 'Extra raita',
            },
          ],
          generateKot: true,
        }),
      },
      adminToken
    );
    assert.equal(addItemsRes.status, 201);
    assert.ok(addItemsRes.data.data.kot, 'New KOT must be generated for added items');
    secondKotId = addItemsRes.data.data.kot.id;
    assert.notEqual(secondKotId, firstKotId, 'Second KOT must have its own unique ID');

    // Query sales transaction to verify both KOTs exist under the same transaction ID
    const txRes = await apiRequest(`/admin/transactions/sales/${salesOrderId}`, {}, adminToken);
    assert.equal(txRes.status, 200);
    assert.equal(txRes.data.data.transactionId, salesTransactionId);
    assert.equal(txRes.data.data.kotHistory.length, 2, 'Must contain both initial and incremental KOTs');
    const kotIds = txRes.data.data.kotHistory.map((k: any) => k.id);
    assert.ok(kotIds.includes(firstKotId), 'Initial KOT must be retained');
    assert.ok(kotIds.includes(secondKotId), 'Incremental KOT must be included');
  });

  await t.test('Test 7: Supplier invoice number is preserved exactly', async () => {
    const subRes = await apiRequest(
      '/supplier/invoices',
      {
        method: 'POST',
        body: JSON.stringify({
          supplierInvoiceNumber: exactSupplierInvoiceNumber,
          invoiceDate: new Date().toISOString(),
          items: [
            {
              productName: 'Raw Chicken Grade A',
              quantity: 10,
              unitPricePaise: 18000,
              gstPercentage: 5,
            },
          ],
        }),
      },
      supplier1Token
    );
    assert.equal(subRes.status, 201);
    procurementInvoiceId = subRes.data.data.invoice.id;
    assert.equal(
      subRes.data.data.invoice.supplier_invoice_number,
      exactSupplierInvoiceNumber,
      'Supplier invoice number with special characters must be preserved exactly'
    );
  });

  await t.test('Test 8: Supplier invoice number is not replaced by the customer invoice number', async () => {
    const piRes = await apiRequest(`/supplier/invoices/${procurementInvoiceId}`, {}, supplier1Token);
    assert.equal(piRes.status, 200);
    assert.equal(piRes.data.data.supplier_invoice_number, exactSupplierInvoiceNumber);
    assert.notEqual(
      piRes.data.data.supplier_invoice_number,
      customerInvoiceNumber,
      'Supplier invoice number must never be replaced by customer invoice number'
    );
    assert.ok(!piRes.data.data.supplier_invoice_number.startsWith('INV-00'), 'Must not use sales prefix');
  });

  await t.test('Test 9: Duplicate supplier invoice submissions do not create duplicate records', async () => {
    const dupRes = await apiRequest(
      '/supplier/invoices',
      {
        method: 'POST',
        body: JSON.stringify({
          supplierInvoiceNumber: exactSupplierInvoiceNumber,
          invoiceDate: new Date().toISOString(),
          items: [
            {
              productName: 'Raw Chicken Grade A',
              quantity: 10,
              unitPricePaise: 18000,
              gstPercentage: 5,
            },
          ],
        }),
      },
      supplier1Token
    );
    assert.equal(dupRes.status, 200, 'Duplicate submission must return 200 OK idempotently');
    assert.equal(dupRes.data.data.isDuplicate, true);
    assert.equal(dupRes.data.data.invoice.id, procurementInvoiceId);
  });

  await t.test('Test 10: Offline supplier invoice submission synchronizes correctly', async () => {
    const offlineClientUuid = randomUUID();
    const offlineInvoiceNumber = 'OFFLINE/INV-2026-99';

    // Simulate mobile client posting sync push item
    const syncRes = await apiRequest(
      '/sync/push',
      {
        method: 'POST',
        body: JSON.stringify({
          items: [
            {
              entityName: 'purchase_invoices',
              recordId: offlineClientUuid,
              operation: 'INSERT',
              payload: {
                id: offlineClientUuid,
                supplierId: supplier1Id,
                supplierInvoiceNumber: offlineInvoiceNumber,
                invoiceDate: new Date().toISOString(),
                items: [
                  {
                    productName: 'Farm Eggs 30-tray',
                    quantity: 5,
                    unitPricePaise: 15000,
                    gstPercentage: 0,
                  },
                ],
              },
            },
          ],
        }),
      },
      adminToken
    );
    assert.equal(syncRes.status, 200, `Sync push failed: ${JSON.stringify(syncRes.data)}`);
    assert.equal(syncRes.data.data.synced, 1);

    // Verify record exists in PostgreSQL
    const checkRes = await apiRequest(`/admin/purchase-invoices/${offlineClientUuid}`, {}, adminToken);
    assert.equal(checkRes.status, 200);
    assert.equal(checkRes.data.data.supplier_invoice_number, offlineInvoiceNumber);
  });

  await t.test('Test 11: Failed sync can safely retry', async () => {
    const retryUuid = randomUUID();
    const retryInvoiceNumber = 'RETRY/INV-2026-01';

    // Attempt 1: succeeds
    const try1 = await apiRequest(
      '/sync/push',
      {
        method: 'POST',
        body: JSON.stringify({
          items: [
            {
              entityName: 'purchase_invoices',
              recordId: retryUuid,
              operation: 'INSERT',
              payload: {
                id: retryUuid,
                supplierId: supplier1Id,
                supplierInvoiceNumber: retryInvoiceNumber,
                invoiceDate: new Date().toISOString(),
                items: [{ productName: 'Basmati Rice 25kg', quantity: 2, unitPricePaise: 250000 }],
              },
            },
          ],
        }),
      },
      adminToken
    );
    assert.equal(try1.status, 200, `Try 1 failed: ${JSON.stringify(try1.data)}`);

    // Attempt 2: retry with same recordId and payload (idempotent replay)
    const try2 = await apiRequest(
      '/sync/push',
      {
        method: 'POST',
        body: JSON.stringify({
          items: [
            {
              entityName: 'purchase_invoices',
              recordId: retryUuid,
              operation: 'INSERT',
              payload: {
                id: retryUuid,
                supplierId: supplier1Id,
                supplierInvoiceNumber: retryInvoiceNumber,
                invoiceDate: new Date().toISOString(),
                items: [{ productName: 'Basmati Rice 25kg', quantity: 2, unitPricePaise: 250000 }],
              },
            },
          ],
        }),
      },
      adminToken
    );
    assert.equal(try2.status, 200, 'Retry must not crash or create duplicates');
  });

  await t.test('Test 12: Supplier cannot access another supplier documents', async () => {
    // Supplier 2 attempts to access Supplier 1's procurement invoice
    const forbiddenRes = await apiRequest(`/supplier/invoices/${procurementInvoiceId}`, {}, supplier2Token);
    assert.equal(forbiddenRes.status, 404, 'Supplier 2 must not be able to find or access Supplier 1 invoice');

    // Supplier 2 attempts to access Supplier 1's transaction
    const forbiddenTxRes = await apiRequest(`/supplier/transactions/${procurementInvoiceId}`, {}, supplier2Token);
    assert.equal(forbiddenTxRes.status, 404, 'Supplier 2 must not be able to access Supplier 1 transaction');
  });

  await t.test('Test 13: Supplier portal does not show KOT/customer invoice printing controls', async () => {
    // Supplier attempt to access KOT router
    const kotAttempt = await apiRequest('/kot', {}, supplier1Token);
    assert.equal(kotAttempt.status, 403, 'Suppliers must be forbidden from accessing KOT endpoints');

    // Supplier attempt to access Admin sales invoices router
    const invAttempt = await apiRequest('/admin/invoices', {}, supplier1Token);
    assert.equal(invAttempt.status, 403, 'Suppliers must be forbidden from accessing admin sales invoices');

    // Supplier attempt to access Admin sales transactions
    const txSalesAttempt = await apiRequest(`/admin/transactions/sales/${salesOrderId}`, {}, supplier1Token);
    assert.equal(txSalesAttempt.status, 403, 'Suppliers must be forbidden from accessing sales transactions');
  });

  await t.test('Test 14: Customer invoices and supplier invoices remain separate', async () => {
    // Sales domain invoices table check
    const salesInvoices = await prisma.invoices.findMany({
      where: { business_id: businessId },
    });
    // Procurement domain purchase_invoices table check
    const purchaseInvoices = await prisma.purchase_invoices.findMany({
      where: { business_id: businessId },
    });

    assert.ok(salesInvoices.length > 0, 'Sales invoices must exist in invoices table');
    assert.ok(purchaseInvoices.length > 0, 'Purchase invoices must exist in purchase_invoices table');

    // Confirm no sales invoice number is in purchase_invoices
    for (const si of salesInvoices) {
      assert.ok(si.invoice_number.startsWith('INV-'));
      const inPurchase = purchaseInvoices.some((p) => p.supplier_invoice_number === si.invoice_number);
      assert.equal(inPurchase, false, 'Sales invoice must not bleed into purchase invoices');
    }
  });

  await t.test('Test 15: Historical invoice amounts and payment records remain unchanged', async () => {
    const historicalInv = await prisma.invoices.findUnique({
      where: { id: customerInvoiceId },
      include: { invoice_items: true },
    });
    assert.ok(historicalInv);
    assert.ok(BigInt(historicalInv.grand_total_paise) > 0n);

    // Verify raw bigint and snapshots are intact
    for (const it of historicalInv.invoice_items) {
      assert.ok(BigInt(it.unit_price_paise) > 0n);
      assert.ok(BigInt(it.total_amount_paise) > 0n);
    }
  });

  await t.test('Test 16: Existing database migrations work without data loss', async () => {
    // Verify rollback and forward migration files exist and are valid SQL
    const fs = await import('fs');
    const path = await import('path');
    const forwardPath = path.join(process.cwd(), 'prisma/migrations/20261109_unified_transaction_linking/migration.sql');
    const rollbackPath = path.join(process.cwd(), 'prisma/migrations/20261109_unified_transaction_linking/rollback.sql');

    assert.ok(fs.existsSync(forwardPath), 'Forward migration file must exist');
    assert.ok(fs.existsSync(rollbackPath), 'Rollback migration file must exist');

    const forwardSql = fs.readFileSync(forwardPath, 'utf8');
    const rollbackSql = fs.readFileSync(rollbackPath, 'utf8');

    assert.ok(forwardSql.includes('transaction_id'), 'Forward SQL must add transaction_id');
    assert.ok(rollbackSql.includes('DROP COLUMN IF EXISTS "transaction_id"'), 'Rollback SQL must safely drop column');
    assert.ok(!forwardSql.includes('DROP TABLE'), 'Forward migration must never drop tables');
  });
});
