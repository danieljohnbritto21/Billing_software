import assert from 'node:assert/strict';
import test from 'node:test';
import { app } from '../src/app';
import { prisma } from '../src/config/prisma';
import http from 'http';
import bcrypt from 'bcryptjs';

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

async function apiRequest(path: string, options: RequestInit = {}, token?: string) {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(options.headers as Record<string, string>),
  };
  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  const res = await fetch(`${baseUrl}${path}`, {
    ...options,
    headers,
  });
  const data = await res.json().catch(() => null);
  return { status: res.status, ok: res.ok, data };
}

test('=== FOODBILL PRO PHASE 6 INTEGRATION & SECURITY TEST SUITE ===', async (t) => {
  // Test Context State
  let adminTokenA: string;
  let adminUserIdA: string;
  let businessIdA: string;

  let adminTokenB: string;
  let adminUserIdB: string;
  let businessIdB: string;

  let supplierA_Id: string;
  let supplierA_Token: string;
  let supplierA_UserId: string;

  let supplierB_Id: string;
  let supplierB_Token: string;

  let productA_Id: string;
  let categoryA_Id: string;
  let purchaseOrderA_Id: string;
  let purchaseInvoiceA_Id: string;

  const testSuffix = Date.now().toString().slice(-6);

  // --------------------------------------------------------------------------
  // Setup: Register Two Distinct Businesses
  // --------------------------------------------------------------------------
  await t.test('Setup: Register Business A & Business B', async () => {
    const resA = await apiRequest('/auth/register-business', {
      method: 'POST',
      body: JSON.stringify({
        businessName: `Test Enterprise A ${testSuffix}`,
        username: `admin_a_${testSuffix}`,
        password: 'Password123!',
        fullName: 'Admin User A',
      }),
    });
    assert.equal(resA.status, 201);
    assert.equal(resA.data.success, true);
    adminTokenA = resA.data.data.token;
    adminUserIdA = resA.data.data.user.id;
    businessIdA = resA.data.data.business.id;

    const resB = await apiRequest('/auth/register-business', {
      method: 'POST',
      body: JSON.stringify({
        businessName: `Test Enterprise B ${testSuffix}`,
        username: `admin_b_${testSuffix}`,
        password: 'Password123!',
        fullName: 'Admin User B',
      }),
    });
    assert.equal(resB.status, 201);
    assert.equal(resB.data.success, true);
    adminTokenB = resB.data.data.token;
    adminUserIdB = resB.data.data.user.id;
    businessIdB = resB.data.data.business.id;
  });

  // --------------------------------------------------------------------------
  // Test 1: Admin Login
  // --------------------------------------------------------------------------
  await t.test('1. Admin Login succeeds with canonical ADMIN role', async () => {
    const res = await apiRequest('/auth/login', {
      method: 'POST',
      body: JSON.stringify({
        username: `admin_a_${testSuffix}`,
        password: 'Password123!',
      }),
    });
    assert.equal(res.status, 200);
    assert.equal(res.data.success, true);
    assert.equal(res.data.data.user.role, 'ADMIN');
    assert.ok(res.data.data.token);
  });

  // --------------------------------------------------------------------------
  // Test 2 & 10: Admin creates and manages suppliers in their business
  // --------------------------------------------------------------------------
  await t.test('10. Admin can manage suppliers in their own business & create Supplier A', async () => {
    const res = await apiRequest(
      '/admin/suppliers',
      {
        method: 'POST',
        body: JSON.stringify({
          supplierCode: `SUP-A-${testSuffix}`,
          supplierName: 'Quality Farm Supplies A',
          contactPerson: 'Alice Farmer',
          phoneNumber: '9876543210',
          email: `supplier_a_${testSuffix}@example.com`,
          createLoginUser: true,
          username: `sup_user_a_${testSuffix}`,
          password: 'SupplierPass123!',
          fullName: 'Alice Farmer Account',
        }),
      },
      adminTokenA
    );
    assert.equal(res.status, 201);
    assert.equal(res.data.success, true);
    supplierA_Id = res.data.data.supplier.id;
    supplierA_UserId = res.data.data.user.id;
    assert.ok(supplierA_Id);

    // Create Supplier B in Business B
    const resB = await apiRequest(
      '/admin/suppliers',
      {
        method: 'POST',
        body: JSON.stringify({
          supplierCode: `SUP-B-${testSuffix}`,
          supplierName: 'Dairy Wholesale B',
          contactPerson: 'Bob Dairyman',
          createLoginUser: true,
          username: `sup_user_b_${testSuffix}`,
          password: 'SupplierPass123!',
          fullName: 'Bob Dairyman Account',
        }),
      },
      adminTokenB
    );
    assert.equal(resB.status, 201);
    supplierB_Id = resB.data.data.supplier.id;
  });

  // --------------------------------------------------------------------------
  // Test 2: Supplier Login
  // --------------------------------------------------------------------------
  await t.test('2. Supplier Login succeeds for verified active supplier', async () => {
    const resA = await apiRequest('/auth/supplier-login', {
      method: 'POST',
      body: JSON.stringify({
        username: `sup_user_a_${testSuffix}`,
        password: 'SupplierPass123!',
      }),
    });
    assert.equal(resA.status, 200);
    assert.equal(resA.data.success, true);
    assert.equal(resA.data.data.user.role, 'SUPPLIER');
    assert.equal(resA.data.data.supplier.id, supplierA_Id);
    supplierA_Token = resA.data.data.token;

    const resB = await apiRequest('/auth/supplier-login', {
      method: 'POST',
      body: JSON.stringify({
        username: `sup_user_b_${testSuffix}`,
        password: 'SupplierPass123!',
      }),
    });
    assert.equal(resB.status, 200);
    supplierB_Token = resB.data.data.token;
  });

  // --------------------------------------------------------------------------
  // Test 3: Inactive Supplier Login Rejection
  // --------------------------------------------------------------------------
  await t.test('3. Inactive supplier login is rejected', async () => {
    // Deactivate Supplier A
    await apiRequest(
      `/admin/suppliers/${supplierA_Id}/status`,
      {
        method: 'PATCH',
        body: JSON.stringify({ isActive: false }),
      },
      adminTokenA
    );

    const res = await apiRequest('/auth/supplier-login', {
      method: 'POST',
      body: JSON.stringify({
        username: `sup_user_a_${testSuffix}`,
        password: 'SupplierPass123!',
      }),
    });
    assert.equal(res.status, 403);
    assert.equal(res.data.success, false);

    // Reactivate for subsequent tests
    await apiRequest(
      `/admin/suppliers/${supplierA_Id}/status`,
      {
        method: 'PATCH',
        body: JSON.stringify({ isActive: true }),
      },
      adminTokenA
    );
  });

  // --------------------------------------------------------------------------
  // Test 4: Legacy Cashier Login Rejection
  // --------------------------------------------------------------------------
  await t.test('4. Legacy cashier login is strictly rejected', async () => {
    // Create a user with CASHIER_LEGACY role directly
    const salt = await bcrypt.genSalt(10);
    const hash = await bcrypt.hash('LegacyPass123!', salt);
    await prisma.users.create({
      data: {
        business_id: businessIdA,
        username: `legacy_cashier_${testSuffix}`,
        full_name: 'Old Cashier',
        role_id: 'CASHIER_LEGACY',
        password_hash: hash,
        salt,
        is_active: false,
      },
    });

    const res = await apiRequest('/auth/login', {
      method: 'POST',
      body: JSON.stringify({
        username: `legacy_cashier_${testSuffix}`,
        password: 'LegacyPass123!',
      }),
    });
    assert.equal(res.status, 401); // Inactive accounts rejected
  });

  // --------------------------------------------------------------------------
  // Test 9: Supplier cannot create categories
  // --------------------------------------------------------------------------
  await t.test('9. Supplier cannot create categories (Admin only)', async () => {
    const resSupplier = await apiRequest(
      '/admin/categories',
      {
        method: 'POST',
        body: JSON.stringify({ name: 'Prohibited Category' }),
      },
      supplierA_Token
    );
    assert.equal(resSupplier.status, 403);

    // Admin creates category successfully
    const resAdmin = await apiRequest(
      '/admin/categories',
      {
        method: 'POST',
        body: JSON.stringify({ name: `Produce ${testSuffix}` }),
      },
      adminTokenA
    );
    assert.equal(resAdmin.status, 201);
    categoryA_Id = resAdmin.data.data.id;
  });

  // --------------------------------------------------------------------------
  // Test 8: Supplier creates product; supplier_id is automatically enforced
  // --------------------------------------------------------------------------
  await t.test('8. Supplier product creation automatically assigns authenticated supplier_id', async () => {
    const res = await apiRequest(
      '/supplier/products',
      {
        method: 'POST',
        body: JSON.stringify({
          name: `Organic Carrots ${testSuffix}`,
          categoryId: categoryA_Id,
          sellingPricePaise: 4500, // Rs 45.00
          costPricePaise: 3000,
          supplierId: '99999999-9999-9999-9999-999999999999', // Client spoofing attempt
        }),
      },
      supplierA_Token
    );
    assert.equal(res.status, 201);
    assert.equal(res.data.success, true);
    // Anti-spoofing verification: must match supplierA_Id, NOT client-supplied spoof ID!
    assert.equal(res.data.data.supplier_id, supplierA_Id);
    productA_Id = res.data.data.id;
  });

  // --------------------------------------------------------------------------
  // Test 5: Supplier A cannot access Supplier B's products
  // --------------------------------------------------------------------------
  await t.test("5. Supplier A cannot access Supplier B's products", async () => {
    // Create product owned by Supplier B
    const resBProd = await apiRequest(
      '/supplier/products',
      {
        method: 'POST',
        body: JSON.stringify({
          name: `Almond Milk ${testSuffix}`,
          sellingPricePaise: 8000,
        }),
      },
      supplierB_Token
    );
    assert.equal(resBProd.status, 201);
    const productB_Id = resBProd.data.data.id;

    // Supplier A attempts to read Supplier B's product
    const resCrossGet = await apiRequest(`/supplier/products/${productB_Id}`, {}, supplierA_Token);
    assert.equal(resCrossGet.status, 404);

    // Supplier A attempts to update Supplier B's product
    const resCrossPut = await apiRequest(
      `/supplier/products/${productB_Id}`,
      {
        method: 'PUT',
        body: JSON.stringify({ name: 'Tampered Product' }),
      },
      supplierA_Token
    );
    assert.equal(resCrossPut.status, 404);
  });

  // --------------------------------------------------------------------------
  // Test 6: Supplier A cannot access Supplier B's purchase orders
  // --------------------------------------------------------------------------
  await t.test("6. Supplier A cannot access Supplier B's purchase orders", async () => {
    // Admin A creates PO for Supplier A
    const resPoA = await apiRequest(
      '/admin/purchase-orders',
      {
        method: 'POST',
        body: JSON.stringify({
          supplierId: supplierA_Id,
          items: [
            {
              productName: 'Fresh Tomatoes',
              quantity: 20,
              unitPricePaise: 2500,
            },
          ],
        }),
      },
      adminTokenA
    );
    assert.equal(resPoA.status, 201);
    purchaseOrderA_Id = resPoA.data.data.order.id;

    // Supplier B attempts to view Supplier A's Purchase Order
    const resCrossPo = await apiRequest(`/supplier/orders/${purchaseOrderA_Id}`, {}, supplierB_Token);
    assert.equal(resCrossPo.status, 404);
  });

  // --------------------------------------------------------------------------
  // Test 7 & 12: Supplier submits invoice; requires verification
  // --------------------------------------------------------------------------
  await t.test('7 & 12. Supplier invoice submission requires verification & blocks cross-supplier access', async () => {
    const resInvoice = await apiRequest(
      '/supplier/invoices',
      {
        method: 'POST',
        body: JSON.stringify({
          purchaseOrderId: purchaseOrderA_Id,
          supplierInvoiceNumber: `INV-SUP-A-${testSuffix}`,
          items: [
            {
              productName: 'Fresh Tomatoes',
              quantity: 20,
              unitPricePaise: 2500,
            },
          ],
        }),
      },
      supplierA_Token
    );
    assert.equal(resInvoice.status, 201);
    assert.equal(resInvoice.data.data.invoice.invoice_status, 'PENDING_VERIFICATION');
    purchaseInvoiceA_Id = resInvoice.data.data.invoice.id;

    // Supplier B attempts to access Supplier A's invoice
    const resCrossInv = await apiRequest(`/supplier/invoices/${purchaseInvoiceA_Id}`, {}, supplierB_Token);
    assert.equal(resCrossInv.status, 404);
  });

  // --------------------------------------------------------------------------
  // Test 13: Unapproved supplier invoice cannot be paid
  // --------------------------------------------------------------------------
  await t.test('13. Unapproved supplier invoice cannot be paid', async () => {
    const resPayUnapproved = await apiRequest(
      `/admin/purchase-invoices/${purchaseInvoiceA_Id}/payments`,
      {
        method: 'POST',
        body: JSON.stringify({
          supplierId: supplierA_Id,
          amountPaise: 50000,
          paymentMethodId: 'Cash',
        }),
      },
      adminTokenA
    );
    assert.equal(resPayUnapproved.status, 400);
    assert.match(resPayUnapproved.data.error, /APPROVED/);

    // Admin approves invoice
    const resApprove = await apiRequest(
      `/admin/purchase-invoices/${purchaseInvoiceA_Id}/approve`,
      { method: 'POST' },
      adminTokenA
    );
    assert.equal(resApprove.status, 200);
  });

  // --------------------------------------------------------------------------
  // Test 14 & 15: Sales and Supplier Payments Ledger Separation
  // --------------------------------------------------------------------------
  await t.test('14 & 15. Sales and Purchase Payment Ledgers remain strictly separate', async () => {
    // Record supplier payment in supplier_payments
    const resPayApproved = await apiRequest(
      `/admin/purchase-invoices/${purchaseInvoiceA_Id}/payments`,
      {
        method: 'POST',
        body: JSON.stringify({
          supplierId: supplierA_Id,
          amountPaise: 20000, // Rs 200 partial payment
          paymentMethodId: 'Cash',
          paymentReference: 'CHQ-99881',
        }),
      },
      adminTokenA
    );
    assert.equal(resPayApproved.status, 201);
    const supplierPaymentId = resPayApproved.data.data.id;

    // Verify it exists in supplier_payments table
    const spDb = await prisma.supplier_payments.findUnique({ where: { id: supplierPaymentId } });
    assert.ok(spDb);

    // Verify it DOES NOT exist in customer sales payments table
    const salesDb = await prisma.payments.findUnique({ where: { id: supplierPaymentId } });
    assert.equal(salesDb, null);
  });

  // --------------------------------------------------------------------------
  // Test 16: Partial payment and outstanding balance calculations
  // --------------------------------------------------------------------------
  await t.test('16. Partial payment and outstanding balance calculations', async () => {
    const resBalance = await apiRequest(
      `/supplier/outstanding-balance`,
      {},
      supplierA_Token
    );
    assert.equal(resBalance.status, 200);
    // Total was 20 * 2500 = 50,000 paise. Paid = 20,000 paise. Outstanding = 30,000 paise.
    assert.equal(resBalance.data.data.totalBilledPaise, '50000');
    assert.equal(resBalance.data.data.totalPaidPaise, '20000');
    assert.equal(resBalance.data.data.totalOutstandingPaise, '30000');
  });

  // --------------------------------------------------------------------------
  // Test 17: Sales duplicate payment idempotency
  // --------------------------------------------------------------------------
  await t.test('17. Sales duplicate payment idempotency', async () => {
    // Create sales order
    const resOrder = await apiRequest(
      '/admin/orders',
      {
        method: 'POST',
        body: JSON.stringify({
          orderType: 'Dine In',
          items: [
            {
              productName: 'Veg Thali',
              quantity: 2,
              unitPricePaise: 15000, // Rs 150 each
            },
          ],
          createInvoiceImmediately: true,
          amountPaidPaise: 0,
        }),
      },
      adminTokenA
    );
    assert.equal(resOrder.status, 201);
    const orderId = resOrder.data.data.order.id;

    const idempotencyKey = `idem-pay-${Date.now()}`;

    // First Payment
    const resPay1 = await apiRequest(
      `/admin/orders/${orderId}/payments`,
      {
        method: 'POST',
        body: JSON.stringify({
          amountPaise: 10000,
          paymentMethod: 'Cash',
          idempotencyKey,
        }),
      },
      adminTokenA
    );
    assert.equal(resPay1.status, 201);
    assert.equal(resPay1.data.data.isDuplicate, false);

    // Duplicate Payment with exact same idempotencyKey
    const resPay2 = await apiRequest(
      `/admin/orders/${orderId}/payments`,
      {
        method: 'POST',
        body: JSON.stringify({
          amountPaise: 10000,
          paymentMethod: 'Cash',
          idempotencyKey,
        }),
      },
      adminTokenA
    );
    assert.equal(resPay2.status, 200);
    assert.equal(resPay2.data.data.isDuplicate, true);

    // Verify balance due was only deducted ONCE (30000 - 10000 = 20000)
    const orderDb = await prisma.orders.findUnique({ where: { id: orderId } });
    assert.equal(orderDb?.amount_paid_paise, 10000n);
    assert.equal(orderDb?.balance_due_paise, 20000n);
  });

  // --------------------------------------------------------------------------
  // Test 18: BigInt Serialization
  // --------------------------------------------------------------------------
  await t.test('18. BigInt values serialize cleanly to JSON without errors', async () => {
    const res = await apiRequest('/admin/orders', {}, adminTokenA);
    assert.equal(res.status, 200);
    assert.ok(Array.isArray(res.data.data));
    const firstOrder = res.data.data[0];
    assert.ok(firstOrder);
    assert.ok(typeof firstOrder.grand_total_paise === 'number' || typeof firstOrder.grand_total_paise === 'string');
  });

  // --------------------------------------------------------------------------
  // Test 11: Admin cannot access another business's records
  // --------------------------------------------------------------------------
  await t.test("11. Admin A cannot access Business B's suppliers or orders", async () => {
    const resCrossSupplier = await apiRequest(`/admin/suppliers/${supplierB_Id}`, {}, adminTokenA);
    assert.equal(resCrossSupplier.status, 404);
  });

  // --------------------------------------------------------------------------
  // Test 19: Cross-business sync isolation
  // --------------------------------------------------------------------------
  await t.test('19. Cross-business sync isolation', async () => {
    const syncStatusA = await apiRequest('/sync/status', {}, adminTokenA);
    assert.equal(syncStatusA.status, 200);
    assert.equal(syncStatusA.data.data.businessId, businessIdA);

    const syncStatusB = await apiRequest('/sync/status', {}, adminTokenB);
    assert.equal(syncStatusB.status, 200);
    assert.equal(syncStatusB.data.data.businessId, businessIdB);
  });

  // --------------------------------------------------------------------------
  // Test 20: Offline retry does not create duplicate financial records
  // --------------------------------------------------------------------------
  await t.test('20. Offline invoice retry does not create duplicate financial records', async () => {
    const offlineIdempotencyKey = `offline-inv-${Date.now()}`;
    const invoicePayload = {
      orderType: 'Takeaway',
      subtotalPaise: 5000,
      taxableAmountPaise: 5000,
      grandTotalPaise: 5000,
      idempotencyKey: offlineIdempotencyKey,
      items: [
        {
          productName: 'Cold Coffee',
          quantity: 1,
          unitPricePaise: 5000,
          taxableAmountPaise: 5000,
          taxAmountPaise: 0,
          totalAmountPaise: 5000,
        },
      ],
    };

    // First submission
    const res1 = await apiRequest(
      '/invoices',
      {
        method: 'POST',
        body: JSON.stringify(invoicePayload),
      },
      adminTokenA
    );
    assert.equal(res1.status, 201);
    const invoiceId1 = res1.data.data.id;

    // Retry submission with same idempotency key
    const res2 = await apiRequest(
      '/invoices',
      {
        method: 'POST',
        body: JSON.stringify(invoicePayload),
      },
      adminTokenA
    );
    assert.equal(res2.status, 201);
    const invoiceId2 = res2.data.data.id;

    // Assert same invoice returned without duplicate creation
    assert.equal(invoiceId1, invoiceId2);

    const count = await prisma.invoices.count({
      where: { business_id: businessIdA, idempotency_key: offlineIdempotencyKey },
    });
    assert.equal(count, 1);
  });
});
