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

test('=== FOODBILL PRO SUPPLIER INVOICE CONTRACT & PRODUCT PRICE TESTS ===', async (t) => {
  let adminToken: string;
  let adminUsername: string;
  let businessId: string;
  let deviceId: string;
  let supplierId: string;
  let createdProductId: string;
  let testInvoiceUuid: string;
  let testInvoiceNum: string;

  await t.test('1. Setup Test Business, Admin, Device & Supplier', async () => {
    adminUsername = `adm_${Date.now()}`;
    // 1. Register business
    const res = await apiRequest('/auth/register-business', {
      method: 'POST',
      body: JSON.stringify({
        businessName: 'Integrity Test Kitchen',
        phone: '9988776655',
        username: adminUsername,
        password: 'Password@123',
        fullName: 'Admin Tester',
      }),
    });
    assert.equal(res.status, 201);
    businessId = res.data.data.business.id;

    // 2. Login with device to get authorized deviceId
    const loginRes = await apiRequest('/auth/login', {
      method: 'POST',
      body: JSON.stringify({
        username: adminUsername,
        password: 'Password@123',
        deviceUid: `device_${Date.now()}`,
        deviceName: 'Admin Main Terminal',
      }),
    });
    assert.equal(loginRes.status, 200);
    adminToken = loginRes.data.data.token;
    deviceId = loginRes.data.data.deviceId;
    assert.ok(deviceId, 'deviceId must be returned upon login');

    // 3. Create supplier
    const supRes = await apiRequest(
      '/admin/suppliers',
      {
        method: 'POST',
        body: JSON.stringify({
          supplierCode: `SUP-${Date.now().toString().slice(-4)}`,
          supplierName: 'Reliable Produce Ltd',
          contactPerson: 'Ramesh Patel',
          phoneNumber: '9876540000',
          email: `supplier_${Date.now()}@test.com`,
          gstin: '29ABCDE1234F1Z5',
        }),
      },
      adminToken,
      deviceId
    );
    assert.equal(supRes.status, 201);
    supplierId = supRes.data.data.supplier ? supRes.data.data.supplier.id : supRes.data.data.id;
    assert.ok(supplierId, 'supplierId must be defined');
  });

  await t.test('2. Product Rupee Support & Conversion Tests', async (t2) => {
    await t2.test('2.1 Should create product using rupees (sellingPriceRupees, costPriceRupees)', async () => {
      const pId = randomUUID();
      const res = await apiRequest(
        '/products',
        {
          method: 'POST',
          body: JSON.stringify({
            id: pId,
            name: 'Fresh Alphonso Mangoes',
            sellingPriceRupees: 80.00,
            costPriceRupees: 65.00,
            gstRatePercent: 5.0,
            unit: 'kg',
            supplierId: supplierId,
          }),
        },
        adminToken,
        deviceId
      );

      assert.equal(res.status, 201);
      assert.equal(res.data.data.id, pId);
      assert.equal(res.data.data.sellingPriceRupees, 80.00);
      assert.equal(res.data.data.costPriceRupees, 65.00);
      assert.equal(Number(res.data.data.selling_price_paise), 8000);
      assert.equal(Number(res.data.data.cost_price_paise), 6500);
      createdProductId = pId;
    });

    await t2.test('2.2 Should create product using paise backward compatibility (8000 paise -> ₹80.00)', async () => {
      const pId = randomUUID();
      const res = await apiRequest(
        '/products',
        {
          method: 'POST',
          body: JSON.stringify({
            id: pId,
            name: 'Masala Chai Premix',
            sellingPricePaise: 8000,
            costPricePaise: 5000,
            unit: 'packet',
            supplierId: supplierId,
          }),
        },
        adminToken,
        deviceId
      );

      assert.equal(res.status, 201);
      assert.equal(res.data.data.sellingPriceRupees, 80.00);
      assert.equal(res.data.data.costPriceRupees, 50.00);
    });

    await t2.test('2.3 Boundary Precision: ₹0.01, ₹25.50, ₹999.99, ₹8,000.00', async () => {
      const boundaries = [
        { name: 'Micro Item', sell: 0.01, cost: 0.01, paise: 1 },
        { name: 'Standard Item', sell: 25.50, cost: 20.00, paise: 2550 },
        { name: 'Premium Item', sell: 999.99, cost: 800.00, paise: 99999 },
        { name: 'Bulk Saffron', sell: 8000.00, cost: 6000.00, paise: 800000 },
      ];

      for (const b of boundaries) {
        const res = await apiRequest(
          '/products',
          {
            method: 'POST',
            body: JSON.stringify({
              name: b.name,
              sellingPriceRupees: b.sell,
              costPriceRupees: b.cost,
              unit: 'unit',
              supplierId: supplierId,
            }),
          },
          adminToken,
          deviceId
        );
        assert.equal(res.status, 201);
        assert.equal(res.data.data.sellingPriceRupees, b.sell);
        assert.equal(Number(res.data.data.selling_price_paise), b.paise);
      }
    });

    await t2.test('2.4 Should update product price in rupees', async () => {
      const res = await apiRequest(
        `/products/${createdProductId}`,
        {
          method: 'PUT',
          body: JSON.stringify({
            sellingPriceRupees: 88.50,
            costPriceRupees: 70.00,
          }),
        },
        adminToken,
        deviceId
      );

      assert.equal(res.status, 200);
      assert.equal(res.data.data.sellingPriceRupees, 88.50);
      assert.equal(res.data.data.costPriceRupees, 70.00);
      assert.equal(Number(res.data.data.selling_price_paise), 8850);
      assert.equal(Number(res.data.data.cost_price_paise), 7000);
    });
  });

  await t.test('3. Supplier Invoice Contract & Field Normalization Tests', async (t3) => {
    testInvoiceUuid = randomUUID();
    testInvoiceNum = `INV-${Date.now().toString().slice(-6)}`;

    await t3.test('3.1 Direct Submission accepts invoiceNumber and gstRatePercent seamlessly', async () => {
      const res = await apiRequest(
        '/admin/purchase-invoices',
        {
          method: 'POST',
          body: JSON.stringify({
            id: testInvoiceUuid,
            supplierId: supplierId,
            invoiceNumber: testInvoiceNum, // Sent by Flutter mobile
            invoiceDate: new Date().toISOString(),
            items: [
              {
                id: randomUUID(),
                productId: createdProductId,
                productName: 'Fresh Alphonso Mangoes',
                quantity: 10,
                unitPricePaise: 8000, // ₹80.00
                gstRatePercent: 5.0, // Sent by Flutter mobile
              },
            ],
          }),
        },
        adminToken,
        deviceId
      );

      assert.equal(res.status, 201);
      assert.equal(res.data.data.invoice.id, testInvoiceUuid, 'Original UUID must be preserved');
      assert.equal(res.data.data.invoice.supplier_invoice_number, testInvoiceNum);
      assert.equal(Number(res.data.data.invoice.subtotal_paise), 80000, 'Subtotal 10 x 8000 = 80000 paise (₹800)');
      assert.equal(Number(res.data.data.invoice.tax_amount_paise), 4000, 'Tax 5% of 80000 = 4000 paise (₹40)');
      assert.equal(Number(res.data.data.invoice.grand_total_paise), 84000, 'Grand total = 84000 paise (₹840)');
    });

    await t3.test('3.2 Idempotent retry does not create duplicate or throw 409', async () => {
      const retryRes = await apiRequest(
        '/admin/purchase-invoices',
        {
          method: 'POST',
          body: JSON.stringify({
            id: testInvoiceUuid,
            supplierId: supplierId,
            invoiceNumber: testInvoiceNum,
            items: [
              {
                productId: createdProductId,
                productName: 'Fresh Alphonso Mangoes',
                quantity: 10,
                unitPricePaise: 8000,
                gstRatePercent: 5.0,
              },
            ],
          }),
        },
        adminToken,
        deviceId
      );

      assert.equal(retryRes.status, 201);
      assert.equal(retryRes.data.data.invoice.id, testInvoiceUuid);
      assert.equal(retryRes.data.data.isDuplicate, true, 'Must acknowledge as duplicate idempotently');
    });

    await t3.test('3.3 Sync Push accepts supplier invoice with invoiceNumber and gstRatePercent', async () => {
      const syncInvoiceUuid = randomUUID();
      const syncInvoiceNum = `INV-SYNC-${Date.now().toString().slice(-4)}`;

      const res = await apiRequest(
        '/sync/push',
        {
          method: 'POST',
          body: JSON.stringify({
            deviceId: deviceId,
            items: [
              {
                entityName: 'purchase_invoices',
                recordId: syncInvoiceUuid,
                operation: 'INSERT',
                payload: {
                  id: syncInvoiceUuid,
                  supplierId: supplierId,
                  invoiceNumber: syncInvoiceNum,
                  items: [
                    {
                      id: randomUUID(),
                      productName: 'Sample Veg',
                      quantity: 5,
                      unitPricePaise: 5000,
                      gstRatePercent: 0,
                    },
                  ],
                },
              },
            ],
          }),
        },
        adminToken,
        deviceId
      );

      assert.equal(res.status, 200);
      assert.equal(res.data.data.results[0].status, 'synced');
      assert.equal(res.data.data.results[0].piId, syncInvoiceUuid);
    });

    await t3.test('3.4 Fetch purchase invoice returns invoice_number alias and child items', async () => {
      const res = await apiRequest(`/admin/purchase-invoices/${testInvoiceUuid}`, {}, adminToken, deviceId);
      assert.equal(res.status, 200);
      assert.equal(res.data.data.supplier_invoice_number, testInvoiceNum);
      assert.ok(Array.isArray(res.data.data.purchase_invoice_items));
      assert.equal(res.data.data.purchase_invoice_items.length, 1);
    });
  });

  await t.test('4. Historical Financial Integrity Verification', async () => {
    // When master product price changes, historical purchase invoice item snapshot did NOT change
    await apiRequest(
      `/products/${createdProductId}`,
      {
        method: 'PUT',
        body: JSON.stringify({
          sellingPriceRupees: 999.00,
          costPriceRupees: 888.00,
        }),
      },
      adminToken,
      deviceId
    );

    const inv = await prisma.purchase_invoices.findFirst({
      where: { id: testInvoiceUuid },
      include: { purchase_invoice_items: true },
    });

    assert.ok(inv);
    assert.equal(inv.grand_total_paise, 84000n, 'Historical grand total must remain 84000 paise');
    assert.equal(
      inv.purchase_invoice_items[0].unit_price_paise,
      8000n,
      'Historical unit price snapshot must remain 8000 paise'
    );
  });
});
