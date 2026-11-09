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

test('=== FOODBILL PRO: SUPPLIER CASH PAYMENT, COMPLETION & KOT ATOMIC LINKING ===', async (t) => {
  let adminToken: string;
  let supplierToken: string;
  let businessId: string;
  let deviceId: string;
  let supplierId: string;
  let testInvoiceId: string;
  const testInvoiceNumber = `INV-${Date.now().toString().slice(-6)}`;

  await t.test('1. Setup Business, Admin, Device & Supplier Partner', async () => {
    const adminUsername = `adm_kot_${Date.now()}`;
    const regRes = await apiRequest('/auth/register-business', {
      method: 'POST',
      body: JSON.stringify({
        businessName: 'Gourmet Bistro KOT Test',
        phone: '9876543210',
        username: adminUsername,
        password: 'Password@123',
        fullName: 'Admin KOT Manager',
      }),
    });
    assert.equal(regRes.status, 201, 'Admin registered');
    businessId = regRes.data.data.business.id;

    const loginAdminRes = await apiRequest('/auth/login', {
      method: 'POST',
      body: JSON.stringify({
        username: adminUsername,
        password: 'Password@123',
        deviceUid: `device_kot_${Date.now()}`,
        deviceName: 'Admin POS Terminal',
      }),
    });
    assert.equal(loginAdminRes.status, 200, 'Admin login success');
    adminToken = loginAdminRes.data.data.token;
    deviceId = loginAdminRes.data.data.user.deviceId || loginAdminRes.data.data.sessionId;

    // Create Supplier
    const supRes = await apiRequest(
      '/admin/suppliers',
      {
        method: 'POST',
        body: JSON.stringify({
          supplierCode: `SUP-${Date.now().toString().slice(-4)}`,
          supplierName: 'Fresh Farms & Dairy Supply',
          contactPerson: 'Ramesh Patel',
          phoneNumber: '9840012345',
          email: `supplier_${Date.now()}@example.com`,
          address: '42 Market Street, Bangalore',
          gstin: '29ABCDE1234F1Z5',
        }),
      },
      adminToken,
      deviceId
    );
    assert.equal(supRes.status, 201, 'Supplier created');
    supplierId = supRes.data.data.supplier ? supRes.data.data.supplier.id : supRes.data.data.id;
    assert.ok(supplierId, 'supplierId must be defined');

  });

  await t.test('2. Submit Supplier Invoice via Purchase Invoices Endpoint', async () => {
    testInvoiceId = randomUUID();
    const invRes = await apiRequest(
      '/admin/purchase-invoices',
      {
        method: 'POST',
        body: JSON.stringify({
          id: testInvoiceId,
          supplierId: supplierId,
          supplierInvoiceNumber: testInvoiceNumber,
          invoiceNumber: testInvoiceNumber,
          invoiceDate: new Date().toISOString(),
          items: [
            {
              id: randomUUID(),
              productName: 'Paneer Butter Masala Pack',
              quantity: 2,
              unit: 'kg',
              unitPricePaise: 40000, // ₹400.00
              gstPercentage: 5.0,
              gstRatePercent: 5.0,
            },
            {
              id: randomUUID(),
              productName: 'Fresh Butter Cubes',
              quantity: 1,
              unit: 'packet',
              unitPricePaise: 15000, // ₹150.00
              gstPercentage: 0.0,
              gstRatePercent: 0.0,
            },
          ],
        }),
      },
      adminToken,
      deviceId
    );
    if (invRes.status !== 201) {
      console.error('Invoice creation failed:', invRes.status, JSON.stringify(invRes.data));
    }
    assert.equal(invRes.status, 201, 'Invoice submitted');

    // Verify stored in procurement table (purchase_invoices)
    const dbInvoice = await prisma.purchase_invoices.findUnique({
      where: { id: testInvoiceId },
      include: { purchase_invoice_items: true },
    });
    assert.ok(dbInvoice, 'Invoice exists in purchase_invoices');
    assert.equal(dbInvoice.supplier_invoice_number, testInvoiceNumber);
    assert.equal(dbInvoice.purchase_invoice_items.length, 2);
    assert.equal(dbInvoice.balance_due_paise.toString(), dbInvoice.grand_total_paise.toString());
    assert.equal(dbInvoice.payment_status, 'UNPAID');
  });

  await t.test('3. Atomic KOT Generation & Persistence for Purchase Invoice', async () => {
    const kotPayload = {
      purchaseInvoiceId: testInvoiceId,
      supplierInvoiceNumber: testInvoiceNumber,
      orderType: 'Procurement',
      items: [
        {
          productName: 'Paneer Butter Masala Pack',
          quantity: 2,
          unit: 'kg',
          specialInstructions: 'Check expiry date and cold storage seal',
        },
        {
          productName: 'Fresh Butter Cubes',
          quantity: 1,
          unit: 'packet',
          specialInstructions: 'Store immediately in chiller',
        },
      ],
    };

    const kotRes = await apiRequest('/kot', {
      method: 'POST',
      body: JSON.stringify(kotPayload),
    }, adminToken, deviceId);

    assert.equal(kotRes.status, 201, 'KOT created successfully');
    const createdKot = kotRes.data.data;
    assert.ok(createdKot.id, 'KOT has an ID');
    assert.equal(createdKot.purchase_invoice_id, testInvoiceId);
    assert.equal(createdKot.supplier_invoice_number, testInvoiceNumber);
    assert.equal(createdKot.kot_items.length, 2, 'Line items persisted in kot_items table');

    // Verify in PostgreSQL kot_records & kot_items
    const dbKot = await prisma.kot_records.findUnique({
      where: { id: createdKot.id },
      include: { kot_items: true, purchase_invoices: true },
    });
    assert.ok(dbKot, 'KOT record found in PostgreSQL');
    assert.equal(dbKot.kot_items.length, 2, '2 line items found in kot_items');
    assert.equal(dbKot.purchase_invoices?.supplier_invoice_number, testInvoiceNumber);

    // Test Associated KOT retrieval endpoint
    const getKotsRes = await apiRequest(
      `/admin/purchase-invoices/${testInvoiceId}/kots`,
      { method: 'GET' },
      adminToken,
      deviceId
    );
    assert.equal(getKotsRes.status, 200);
    assert.equal(getKotsRes.data.data.length, 1);
    assert.equal(getKotsRes.data.data[0].id, createdKot.id);

    // Test reprint counter
    const reprintRes = await apiRequest(
      `/kot/${createdKot.id}/reprint`,
      { method: 'POST' },
      adminToken,
      deviceId
    );
    assert.equal(reprintRes.status, 200);
    assert.equal(reprintRes.data.data.reprinted_count, 1, 'Reprint count incremented');
  });

  await t.test('4. Invoice Completion Prevention When Balance Due > 0', async () => {
    // Attempting to complete while balance due is greater than 0 must fail
    const completeFailRes = await apiRequest(
      `/admin/purchase-invoices/${testInvoiceId}/complete`,
      { method: 'POST' },
      adminToken,
      deviceId
    );
    assert.equal(completeFailRes.status, 400, 'Cannot complete invoice with outstanding balance');
  });

  await t.test('5. Record Cash Payment & Full Settlement', async () => {
    const inv = await prisma.purchase_invoices.findUnique({
      where: { id: testInvoiceId },
    });
    const totalDue = Number(inv!.balance_due_paise);

    // Record partial cash payment
    const partialAmount = Math.floor(totalDue / 2);
    const pay1Res = await apiRequest(
      `/admin/purchase-invoices/${testInvoiceId}/payments`,
      {
        method: 'POST',
        body: JSON.stringify({
          supplierId,
          amountPaise: partialAmount,
          paymentMethod: 'Cash',
          referenceNumber: 'CASH-REC-001',
          notes: 'Cash advance given at loading',
        }),
      },
      adminToken,
      deviceId
    );
    assert.equal(pay1Res.status, 201, 'Partial cash payment recorded');

    // Verify invoice status updated to PARTIALLY_PAID
    let updatedInv = await prisma.purchase_invoices.findUnique({
      where: { id: testInvoiceId },
    });
    assert.equal(updatedInv!.payment_status, 'PARTIALLY_PAID');
    assert.equal(Number(updatedInv!.amount_paid_paise), partialAmount);

    // Settle remaining balance
    const remainingDue = Number(updatedInv!.balance_due_paise);
    const pay2Res = await apiRequest(
      `/admin/purchase-invoices/${testInvoiceId}/payments`,
      {
        method: 'POST',
        body: JSON.stringify({
          supplierId,
          amountPaise: remainingDue,
          paymentMethod: 'Cash',
          referenceNumber: 'CASH-REC-002',
          notes: 'Final cash settlement at delivery counter',
        }),
      },
      adminToken,
      deviceId
    );
    assert.equal(pay2Res.status, 201, 'Remaining cash settlement recorded');

    // Verify invoice status updated to PAID and balance due is 0
    updatedInv = await prisma.purchase_invoices.findUnique({
      where: { id: testInvoiceId },
    });
    assert.equal(updatedInv!.payment_status, 'PAID');
    assert.equal(Number(updatedInv!.balance_due_paise), 0);
  });

  await t.test('6. Complete Invoice Execution & Idempotency', async () => {
    // Complete invoice
    const completeRes = await apiRequest(
      `/admin/purchase-invoices/${testInvoiceId}/complete`,
      { method: 'POST' },
      adminToken,
      deviceId
    );
    assert.equal(completeRes.status, 200, 'Invoice completed successfully');
    assert.equal(completeRes.data.data.invoice_status, 'COMPLETED');

    // Verify database record
    const finalInv = await prisma.purchase_invoices.findUnique({
      where: { id: testInvoiceId },
    });
    assert.equal(finalInv!.invoice_status, 'COMPLETED');
    assert.equal(finalInv!.payment_status, 'PAID');

    // Second completion attempt must reject (prevent duplicate completion)
    const secondCompleteRes = await apiRequest(
      `/admin/purchase-invoices/${testInvoiceId}/complete`,
      { method: 'POST' },
      adminToken,
      deviceId
    );
    assert.equal(secondCompleteRes.status, 400, 'Already completed');
  });
});
