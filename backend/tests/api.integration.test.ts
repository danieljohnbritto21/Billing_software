import assert from 'node:assert/strict';
import test from 'node:test';
import { app } from '../src/app';
import { prisma } from '../src/config/prisma';
import http from 'http';

let server: http.Server;
let baseUrl: string;

test.before(async () => {
  // Use test database connection
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

test('=== FOODBILL PRO PHASE 4 API INTEGRATION TEST SUITE ===', async (t) => {
  let adminToken1: string;
  let admin1BusinessId: string;
  let cashierToken1: string;
  let cashier1UserId: string;
  let cashier1Username: string;

  let adminToken2: string;
  let admin2BusinessId: string;

  let category1Id: string;
  let product1Id: string;
  let device1Id: string;
  let invoice1Id: string;

  await t.test('1. Authentication & Role-Based Login', async (t2) => {
    await t2.test('1.1 Should register Business 1 with Admin user', async () => {
      const res = await apiRequest('/auth/register-business', {
        method: 'POST',
        body: JSON.stringify({
          businessName: 'FoodBill Test Cafe',
          tagline: 'Best South Indian Snacks',
          phone: '9876543210',
          address: '123 Test St, Bangalore',
          gstin: '29ABCDE1234F1Z5',
          username: `admin_${Date.now()}`,
          password: 'Password@123',
          fullName: 'Test Admin',
        }),
      });

      assert.equal(res.status, 201, `Expected 201, got ${res.status}`);
      assert.ok(res.data.data.token);
      assert.equal(res.data.data.user.role, 'admin');

      adminToken1 = res.data.data.token;
      admin1BusinessId = res.data.data.business.id;
    });

    await t2.test('1.2 Should reject login with invalid password', async () => {
      const profile = await apiRequest('/auth/me', {}, adminToken1);
      const res = await apiRequest('/auth/login', {
        method: 'POST',
        body: JSON.stringify({
          username: profile.data.data.username,
          password: 'WrongPassword!',
        }),
      });
      assert.equal(res.status, 401);
      assert.equal(res.data.success, false);
    });

    await t2.test('1.3 Admin creates a Cashier user', async () => {
      const cashierUsername = `cashier_${Date.now()}`;
      const res = await apiRequest(
        '/users',
        {
          method: 'POST',
          body: JSON.stringify({
            username: cashierUsername,
            password: 'CashierPassword@123',
            fullName: 'Ramesh Cashier',
            role: 'cashier',
          }),
        },
        adminToken1
      );

      assert.equal(res.status, 201);
      assert.equal(res.data.data.role, 'cashier');
      cashier1UserId = res.data.data.id;
      cashier1Username = cashierUsername;

      // Cashier logs in
      const loginRes = await apiRequest('/auth/login', {
        method: 'POST',
        body: JSON.stringify({
          username: cashierUsername,
          password: 'CashierPassword@123',
          deviceUid: 'test-device-terminal-01',
          deviceName: 'POS Terminal Counter 1',
        }),
      });

      assert.equal(loginRes.status, 200);
      assert.ok(loginRes.data.data.token);
      assert.equal(loginRes.data.data.user.role, 'cashier');
      cashierToken1 = loginRes.data.data.token;
      device1Id = loginRes.data.data.deviceId;
    });

    await t2.test('1.4 Register Business 2 (for multi-tenant isolation verification)', async () => {
      const res = await apiRequest('/auth/register-business', {
        method: 'POST',
        body: JSON.stringify({
          businessName: 'Bakery Shop Two',
          username: `admin2_${Date.now()}`,
          password: 'Password@123',
          fullName: 'Admin Two',
        }),
      });

      assert.equal(res.status, 201);
      adminToken2 = res.data.data.token;
      admin2BusinessId = res.data.data.business.id;
    });
  });

  await t.test('2. Role-Based Permissions & Guardrails', async (t2) => {
    await t2.test('2.1 Admin CAN manage categories; Cashier CANNOT', async () => {
      // Admin creates category -> Success 201
      const adminCatRes = await apiRequest(
        '/categories',
        {
          method: 'POST',
          body: JSON.stringify({
            name: 'Beverages',
            icon: 'coffee',
            displayOrder: 1,
          }),
        },
        adminToken1
      );
      assert.equal(adminCatRes.status, 201);
      category1Id = adminCatRes.data.data.id;

      // Cashier attempts to create category -> Forbidden 403
      const cashierCatRes = await apiRequest(
        '/categories',
        {
          method: 'POST',
          body: JSON.stringify({
            name: 'Snacks',
          }),
        },
        cashierToken1
      );
      assert.equal(cashierCatRes.status, 403);
    });

    await t2.test('2.2 Cashier CAN create products; Admin CANNOT', async () => {
      // Cashier creates product -> Success 201
      const cashierProdRes = await apiRequest(
        '/products',
        {
          method: 'POST',
          body: JSON.stringify({
            categoryId: category1Id,
            name: 'Filter Coffee',
            code: 'COF01',
            costPricePaise: 1000,
            sellingPricePaise: 2500,
            gstRatePercent: 5.0,
            unit: 'cup',
            isAvailable: true,
          }),
        },
        cashierToken1
      );
      assert.equal(cashierProdRes.status, 201);
      product1Id = cashierProdRes.data.data.id;

      // Admin attempts to create product -> Forbidden 403
      const adminProdRes = await apiRequest(
        '/products',
        {
          method: 'POST',
          body: JSON.stringify({
            categoryId: category1Id,
            name: 'Unauthorized Tea',
            sellingPricePaise: 2000,
          }),
        },
        adminToken1
      );
      assert.equal(adminProdRes.status, 403);
    });
  });

  await t.test('3. Multi-Tenant Business Isolation', async (t2) => {
    await t2.test('3.1 Business 2 cannot access Business 1 category', async () => {
      const res = await apiRequest(`/categories/${category1Id}`, {}, adminToken2);
      assert.equal(res.status, 404);
    });

    await t2.test('3.2 Business 2 product cannot reference Business 1 category', async () => {
      // Login cashier for Business 2
      const cashier2User = `cashier2_${Date.now()}`;
      await apiRequest(
        '/users',
        {
          method: 'POST',
          body: JSON.stringify({
            username: cashier2User,
            password: 'Password@123',
            fullName: 'Cashier 2',
            role: 'cashier',
          }),
        },
        adminToken2
      );

      const loginRes = await apiRequest('/auth/login', {
        method: 'POST',
        body: JSON.stringify({
          username: cashier2User,
          password: 'Password@123',
        }),
      });
      const cashier2Token = loginRes.data.data.token;

      // Attempt to link category1Id from Business 1
      const crossRes = await apiRequest(
        '/products',
        {
          method: 'POST',
          body: JSON.stringify({
            categoryId: category1Id,
            name: 'Croissant',
            sellingPricePaise: 5000,
          }),
        },
        cashier2Token
      );

      assert.equal(crossRes.status, 400);
      assert.ok(crossRes.data.error.includes('belongs to another business'));
    });
  });

  await t.test('4. Device Registration and Authorization', async (t2) => {
    await t2.test('4.1 Admin lists devices and modifies authorization', async () => {
      const listRes = await apiRequest('/devices', {}, adminToken1);
      assert.equal(listRes.status, 200);
      assert.ok(listRes.data.data.length >= 1);

      // Authorize
      const authRes = await apiRequest(
        `/devices/${device1Id}/authorization`,
        {
          method: 'PUT',
          body: JSON.stringify({ isAuthorized: true }),
        },
        adminToken1
      );
      assert.equal(authRes.status, 200);
      assert.equal(authRes.data.data.is_authorized, true);

      // Revoke
      const revokeRes = await apiRequest(
        `/devices/${device1Id}/authorization`,
        {
          method: 'PUT',
          body: JSON.stringify({ isAuthorized: false }),
        },
        adminToken1
      );
      assert.equal(revokeRes.status, 200);
      assert.equal(revokeRes.data.data.is_authorized, false);

      // Re-authorize so the terminal is active for subsequent cashier operations
      const reauthRes = await apiRequest(
        `/devices/${device1Id}/authorization`,
        {
          method: 'PUT',
          body: JSON.stringify({ isAuthorized: true }),
        },
        adminToken1
      );
      assert.equal(reauthRes.status, 200);
      assert.equal(reauthRes.data.data.is_authorized, true);
    });
  });

  await t.test('5. Invoice Lifecycle, Open-Order Items & Finalization Protection', async (t2) => {
    let itemId: string;

    await t2.test('5.1 Cashier creates an open pending invoice with initial item', async () => {
      const res = await apiRequest(
        '/invoices',
        {
          method: 'POST',
          body: JSON.stringify({
            idempotencyKey: `idemp-inv-${Date.now()}`,
            orderType: 'Dine In',
            orderStatus: 'Pending',
            paymentStatus: 'Pending',
            subtotalPaise: 2500,
            taxableAmountPaise: 2381,
            cgstPaise: 59,
            sgstPaise: 60,
            grandTotalPaise: 2500,
            paidAmountPaise: 0,
            items: [
              {
                productId: product1Id,
                productName: 'Filter Coffee',
                unit: 'cup',
                unitPricePaise: 2500,
                quantity: 1,
                taxableAmountPaise: 2381,
                taxAmountPaise: 119,
                totalAmountPaise: 2500,
              },
            ],
          }),
        },
        cashierToken1
      );

      assert.equal(res.status, 201);
      invoice1Id = res.data.data.id;
      itemId = res.data.data.invoice_items[0].id;
      assert.equal(res.data.data.order_status, 'Pending');
    });

    await t2.test('5.2 Cashier adds additional item to open invoice', async () => {
      const res = await apiRequest(
        `/invoices/${invoice1Id}/items`,
        {
          method: 'POST',
          body: JSON.stringify({
            productId: product1Id,
            productName: 'Filter Coffee',
            unit: 'cup',
            unitPricePaise: 2500,
            quantity: 2,
            taxableAmountPaise: 4762,
            taxAmountPaise: 238,
            totalAmountPaise: 5000,
          }),
        },
        cashierToken1
      );

      assert.equal(res.status, 201);
    });

    await t2.test('5.3 Cashier finalizes invoice to Completed', async () => {
      const res = await apiRequest(
        `/invoices/${invoice1Id}/finalize`,
        { method: 'POST' },
        cashierToken1
      );
      assert.equal(res.status, 200);
      assert.equal(res.data.data.order_status, 'Completed');
    });

    await t2.test('5.4 Rejects adding item to finalized invoice', async () => {
      const res = await apiRequest(
        `/invoices/${invoice1Id}/items`,
        {
          method: 'POST',
          body: JSON.stringify({
            productId: product1Id,
            productName: 'Illegal Tea',
            unit: 'cup',
            unitPricePaise: 2500,
            quantity: 1,
            taxableAmountPaise: 2500,
            taxAmountPaise: 0,
            totalAmountPaise: 2500,
          }),
        },
        cashierToken1
      );

      assert.equal(res.status, 400);
      assert.ok(res.data.error.includes('integrity') || res.data.details.includes('finalized'));
    });
  });

  await t.test('6. Payment Recording, Ledger Immutability & Idempotency', async (t2) => {
    const idempKey = `pay-key-${Date.now()}`;

    await t2.test('6.1 Record partial payment successfully', async () => {
      const res = await apiRequest(
        '/payments',
        {
          method: 'POST',
          body: JSON.stringify({
            invoiceId: invoice1Id,
            amountPaise: 3000,
            paymentMethod: 'UPI',
            referenceNumber: 'UPI1234567890',
            idempotencyKey: idempKey,
          }),
        },
        cashierToken1
      );

      assert.equal(res.status, 201);
      assert.equal(res.data.data.amount_paise, 3000);
    });

    await t2.test('6.2 Idempotent payment request returns existing payment cleanly', async () => {
      const res = await apiRequest(
        '/payments',
        {
          method: 'POST',
          body: JSON.stringify({
            invoiceId: invoice1Id,
            amountPaise: 3000,
            paymentMethod: 'UPI',
            referenceNumber: 'UPI1234567890',
            idempotencyKey: idempKey,
          }),
        },
        cashierToken1
      );

      // Must return status 200 or 201 with identical payment record
      assert.ok(res.status === 200 || res.status === 201);
      assert.equal(res.data.data.idempotency_key, idempKey);
    });
  });

  await t.test('7. Commit-Safe Sync Pull, Pagination & Reconnect', async (t2) => {
    let firstNextCursor: string;

    await t2.test('7.1 Pull initial changes with limit 2', async () => {
      const res = await apiRequest('/sync/pull?cursor=0&limit=2', {}, adminToken1);
      assert.equal(res.status, 200);
      assert.ok(res.data.data.changes.length <= 2);
      assert.ok(res.data.data.changes.length > 0);
      assert.ok(res.data.data.nextCursor);
      firstNextCursor = res.data.data.nextCursor;
    });

    await t2.test('7.2 Resume pull from nextCursor returns subsequent changes without gap', async () => {
      const res = await apiRequest(`/sync/pull?cursor=${firstNextCursor}&limit=10`, {}, adminToken1);
      assert.equal(res.status, 200);

      // Verify all cursors returned are strictly greater than firstNextCursor
      for (const ch of res.data.data.changes) {
        assert.ok(BigInt(ch.cursor) > BigInt(firstNextCursor));
      }
    });

    await t2.test('7.3 Push offline changes with conflict detection', async () => {
      const res = await apiRequest(
        '/sync/push',
        {
          method: 'POST',
          body: JSON.stringify({
            deviceId: device1Id,
            items: [
              {
                entityName: 'products',
                operation: 'UPDATE',
                recordId: product1Id,
                clientVersion: 0, // Stale version -> should trigger conflict detection!
                payload: {
                  name: 'Stale Offline Coffee Name',
                  sellingPricePaise: 9999,
                },
              },
            ],
          }),
        },
        cashierToken1
      );

      assert.equal(res.status, 200);
      assert.equal(res.data.data.results[0].status, 'conflict');
      assert.equal(res.data.data.results[0].resolution, 'SERVER_WINS');
    });
  });

  await t.test('8. Device Authorization & Revocation Security Enforcement', async (t2) => {
    let testDeviceId: string;
    let testDeviceToken: string;

    await t2.test('8.1 Authorized device can sync successfully', async () => {
      const devUid = `pos-auth-${Date.now()}`;
      const loginRes = await apiRequest('/auth/login', {
        method: 'POST',
        body: JSON.stringify({
          username: cashier1Username,
          password: 'CashierPassword@123',
          deviceUid: devUid,
          deviceName: 'Authorized POS Terminal',
        }),
      });

      assert.equal(loginRes.status, 200);
      testDeviceToken = loginRes.data.data.token;
      testDeviceId = loginRes.data.data.deviceId;
      assert.ok(testDeviceId);

      // Verify sync pull works for authorized device
      const pullRes = await apiRequest('/sync/pull?cursor=0&limit=5', {}, testDeviceToken);
      assert.equal(pullRes.status, 200);
      assert.ok(Array.isArray(pullRes.data.data.changes));

      // Verify sync push works for authorized device
      const pushRes = await apiRequest(
        '/sync/push',
        {
          method: 'POST',
          body: JSON.stringify({
            deviceId: testDeviceId,
            items: [
              {
                entityName: 'products',
                operation: 'UPDATE',
                recordId: product1Id,
                payload: {
                  name: 'Authorized Device Coffee Update',
                },
              },
            ],
          }),
        },
        testDeviceToken
      );
      assert.equal(pushRes.status, 200);
    });

    await t2.test('8.2 Unauthorized device cannot sync (HTTP 403)', async () => {
      // 1. Admin creates a new device entry with is_authorized = false
      const unauthUid = `unauth-terminal-${Date.now()}`;
      const regRes = await apiRequest(
        '/devices/register',
        {
          method: 'POST',
          body: JSON.stringify({
            deviceUid: unauthUid,
            deviceName: 'Pending Approval Terminal',
          }),
        },
        adminToken1
      );
      assert.equal(regRes.status, 201);
      const unauthDevId = regRes.data.data.id;
      assert.equal(regRes.data.data.is_authorized, false);

      // 2. User logs in with that device
      const loginRes = await apiRequest('/auth/login', {
        method: 'POST',
        body: JSON.stringify({
          username: cashier1Username,
          password: 'CashierPassword@123',
          deviceUid: unauthUid,
        }),
      });
      assert.equal(loginRes.status, 200);
      const unauthToken = loginRes.data.data.token;

      // 3. Sync pull must be rejected with HTTP 403
      const pullRes = await apiRequest('/sync/pull?cursor=0&limit=5', {}, unauthToken);
      assert.equal(pullRes.status, 403);
      assert.equal(pullRes.data.success, false);
      assert.ok(pullRes.data.error.includes('revoked or pending approval'));

      // 4. Sync push must be rejected with HTTP 403
      const pushRes = await apiRequest(
        '/sync/push',
        {
          method: 'POST',
          body: JSON.stringify({
            deviceId: unauthDevId,
            items: [],
          }),
        },
        unauthToken
      );
      assert.equal(pushRes.status, 403);
      assert.equal(pushRes.data.success, false);
    });

    await t2.test('8.3 Revoked device cannot sync even with a previously issued JWT', async () => {
      // 1. Device is initially authorized and syncing
      const pullBeforeRevoke = await apiRequest('/sync/pull?cursor=0&limit=5', {}, testDeviceToken);
      assert.equal(pullBeforeRevoke.status, 200);

      // 2. Admin revokes authorization for this device
      const revokeRes = await apiRequest(
        `/devices/${testDeviceId}/authorization`,
        {
          method: 'PUT',
          body: JSON.stringify({ isAuthorized: false }),
        },
        adminToken1
      );
      assert.equal(revokeRes.status, 200);
      assert.equal(revokeRes.data.data.is_authorized, false);

      // 3. Device uses the PREVIOUSLY ISSUED JWT (testDeviceToken) to call /sync/pull
      const pullAfterRevoke = await apiRequest('/sync/pull?cursor=0&limit=5', {}, testDeviceToken);
      assert.equal(pullAfterRevoke.status, 403, 'Previously issued JWT must not bypass device revocation on pull');
      assert.equal(pullAfterRevoke.data.success, false);
      assert.ok(pullAfterRevoke.data.error.includes('revoked or pending approval'));

      // 4. Device uses the PREVIOUSLY ISSUED JWT to call /sync/push
      const pushAfterRevoke = await apiRequest(
        '/sync/push',
        {
          method: 'POST',
          body: JSON.stringify({
            deviceId: testDeviceId,
            items: [],
          }),
        },
        testDeviceToken
      );
      assert.equal(pushAfterRevoke.status, 403, 'Previously issued JWT must not bypass device revocation on push');
      assert.equal(pushAfterRevoke.data.success, false);
    });

    await t2.test('8.4 Device belonging to another business cannot sync', async () => {
      // 1. Register a device in Business 2
      const biz2DevUid = `biz2-dev-${Date.now()}`;
      const regRes = await apiRequest(
        '/devices/register',
        {
          method: 'POST',
          body: JSON.stringify({
            deviceUid: biz2DevUid,
            deviceName: 'Business 2 Terminal',
          }),
        },
        adminToken2
      );
      assert.equal(regRes.status, 201);
      const biz2DevId = regRes.data.data.id;

      // Authorize Business 2 device
      await apiRequest(
        `/devices/${biz2DevId}/authorization`,
        {
          method: 'PUT',
          body: JSON.stringify({ isAuthorized: true }),
        },
        adminToken2
      );

      // 2. Attempt to use Business 1 token with Business 2 device in request body
      const spoofRes = await apiRequest(
        '/sync/push',
        {
          method: 'POST',
          body: JSON.stringify({
            deviceId: biz2DevId, // Foreign device from Business 2
            items: [],
          }),
        },
        cashierToken1
      );
      assert.equal(spoofRes.status, 403);
      assert.ok(spoofRes.data.error.includes('does not match authenticated device token'));
    });

    await t2.test('8.5 Revoking a device blocks its next sync request immediately', async () => {
      // 1. Create a fresh terminal
      const activeUid = `immediate-block-${Date.now()}`;
      const loginRes = await apiRequest('/auth/login', {
        method: 'POST',
        body: JSON.stringify({
          username: cashier1Username,
          password: 'CashierPassword@123',
          deviceUid: activeUid,
        }),
      });
      assert.equal(loginRes.status, 200);
      const activeToken = loginRes.data.data.token;
      const activeDevId = loginRes.data.data.deviceId;

      // 2. Active sync succeeds
      const firstPull = await apiRequest('/sync/pull?cursor=0&limit=1', {}, activeToken);
      assert.equal(firstPull.status, 200);

      // 3. Admin revokes the device
      const revoke = await apiRequest(
        `/devices/${activeDevId}/authorization`,
        {
          method: 'PUT',
          body: JSON.stringify({ isAuthorized: false }),
        },
        adminToken1
      );
      assert.equal(revoke.status, 200);
      assert.equal(revoke.data.data.is_authorized, false);

      // 4. Immediate subsequent sync call must fail with 403
      const immediateNextPull = await apiRequest('/sync/pull?cursor=0&limit=1', {}, activeToken);
      assert.equal(immediateNextPull.status, 403);
      assert.equal(immediateNextPull.data.success, false);
    });
  });
});
