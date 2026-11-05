import { DEMO_ADMIN_PASSWORD, DEMO_ADMIN_USERNAME, DEMO_CASHIER_PASSWORD, DEMO_CASHIER_USERNAME } from './seed-demo-business';

const BASE_URL = 'http://127.0.0.1:3000/api/v1';

async function main() {
  console.log('=== FOODBILL PRO DEMO AUTH & SYNC VERIFICATION ===\n');

  // 1. Admin Login
  console.log('1. Testing Demo Admin Login...');
  const adminRes = await fetch(`${BASE_URL}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      username: DEMO_ADMIN_USERNAME,
      password: DEMO_ADMIN_PASSWORD,
      deviceUid: 'demo-admin-test-phone-uid',
      deviceName: 'Phone A (Admin Device)',
    }),
  });

  const adminRaw: any = await adminRes.json();
  if (!adminRes.ok || !adminRaw.success) {
    throw new Error(`Admin login failed (${adminRes.status}): ${JSON.stringify(adminRaw)}`);
  }
  const adminData = adminRaw.data;
  console.log(`✔ Admin logged in successfully.`);
  console.log(`  - Business: "${adminData.business.name}" (${adminData.business.id})`);
  console.log(`  - User: ${adminData.user.username} (Role: ${adminData.user.role})`);
  console.log(`  - Device ID: ${adminData.deviceId}`);

  const adminToken = adminData.token;
  const adminBusinessId = adminData.business.id;
  const adminDeviceId = adminData.deviceId;

  // 2. Cashier Login
  console.log('\n2. Testing Demo Cashier Login...');
  const cashierRes = await fetch(`${BASE_URL}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      username: DEMO_CASHIER_USERNAME,
      password: DEMO_CASHIER_PASSWORD,
      deviceUid: 'demo-cashier-test-phone-uid',
      deviceName: 'Phone B (Cashier Device)',
    }),
  });

  const cashierRaw: any = await cashierRes.json();
  if (!cashierRes.ok || !cashierRaw.success) {
    throw new Error(`Cashier login failed (${cashierRes.status}): ${JSON.stringify(cashierRaw)}`);
  }
  const cashierData = cashierRaw.data;
  console.log(`✔ Cashier logged in successfully.`);
  console.log(`  - Business: "${cashierData.business.name}" (${cashierData.business.id})`);
  console.log(`  - User: ${cashierData.user.username} (Role: ${cashierData.user.role})`);
  console.log(`  - Device ID: ${cashierData.deviceId}`);

  const cashierToken = cashierData.token;
  const cashierBusinessId = cashierData.business.id;
  const cashierDeviceId = cashierData.deviceId;

  // 3. Verify Same Business Tenant Isolation
  console.log('\n3. Verifying Multi-Device Business Association...');
  if (adminBusinessId !== cashierBusinessId) {
    throw new Error(`FAIL: Admin business (${adminBusinessId}) does not match Cashier business (${cashierBusinessId})`);
  }
  console.log(`✔ Verified: Both Phone A and Phone B belong to the exact same business ID: ${adminBusinessId}`);

  // 4. Admin Creates Category via Sync Push
  console.log('\n4. Testing Category Creation & Sync Push from Admin (Phone A)...');
  const testCategoryId = crypto.randomUUID();
  const categoryPushRes = await fetch(`${BASE_URL}/sync/push`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${adminToken}`,
      'X-Device-Id': adminDeviceId,
    },
    body: JSON.stringify({
      deviceId: adminDeviceId,
      items: [
        {
          entityName: 'categories',
          operation: 'INSERT',
          recordId: testCategoryId,
          clientVersion: 1,
          payload: {
            id: testCategoryId,
            name: 'Hot Beverages',
            displayOrder: 1,
            isActive: true,
          },
        },
      ],
    }),
  });

  const categoryPushRaw: any = await categoryPushRes.json();
  if (!categoryPushRes.ok || !categoryPushRaw.success) {
    throw new Error(`Category push failed (${categoryPushRes.status}): ${JSON.stringify(categoryPushRaw)}`);
  }
  const categoryPushData = categoryPushRaw.data;
  console.log(`✔ Category "Hot Beverages" pushed by Admin: status = ${categoryPushData.results[0].status}`);

  // 5. Cashier Pulls Category via Sync Pull
  console.log('\n5. Testing Sync Pull on Cashier (Phone B) to receive Category...');
  const cashierPullRes = await fetch(`${BASE_URL}/sync/pull?cursor=0&limit=50`, {
    headers: {
      Authorization: `Bearer ${cashierToken}`,
      'X-Device-Id': cashierDeviceId,
    },
  });

  const cashierPullRaw: any = await cashierPullRes.json();
  if (!cashierPullRes.ok || !cashierPullRaw.success) {
    throw new Error(`Cashier pull failed (${cashierPullRes.status}): ${JSON.stringify(cashierPullRaw)}`);
  }
  const cashierPullData = cashierPullRaw.data;

  const categoryChange = cashierPullData.changes.find(
    (c: any) => c.entityName === 'categories' && c.recordId === testCategoryId
  );
  if (!categoryChange) {
    throw new Error(`FAIL: Cashier did not receive the category created by Admin! Changes received: ${cashierPullData.changes.length}`);
  }
  console.log(`✔ Cashier successfully pulled category "${categoryChange.data?.name}" (ID: ${categoryChange.recordId})`);
  console.log(`  - Server cursor advanced to: ${cashierPullData.nextCursor}`);

  // 6. Cashier Creates Product "Masala Chai" (₹20 = 2000 paise) via Sync Push
  console.log('\n6. Testing Product Creation & Sync Push from Cashier (Phone B)...');
  const testProductId = crypto.randomUUID();
  const productPushRes = await fetch(`${BASE_URL}/sync/push`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${cashierToken}`,
      'X-Device-Id': cashierDeviceId,
    },
    body: JSON.stringify({
      deviceId: cashierDeviceId,
      items: [
        {
          entityName: 'products',
          operation: 'INSERT',
          recordId: testProductId,
          clientVersion: 1,
          payload: {
            id: testProductId,
            categoryId: testCategoryId,
            name: 'Masala Chai',
            sellingPricePaise: 2000, // ₹20.00
            unit: 'cup',
            isActive: true,
          },
        },
      ],
    }),
  });

  const productPushRaw: any = await productPushRes.json();
  if (!productPushRes.ok || !productPushRaw.success) {
    throw new Error(`Product push failed (${productPushRes.status}): ${JSON.stringify(productPushRaw)}`);
  }
  const productPushData = productPushRaw.data;
  console.log(`✔ Product "Masala Chai" pushed by Cashier: status = ${productPushData.results[0].status}`);

  // 7. Admin Pulls Product via Sync Pull
  console.log('\n7. Testing Sync Pull on Admin (Phone A) to receive Product...');
  const adminPullRes = await fetch(`${BASE_URL}/sync/pull?cursor=0&limit=50`, {
    headers: {
      Authorization: `Bearer ${adminToken}`,
      'X-Device-Id': adminDeviceId,
    },
  });

  const adminPullRaw: any = await adminPullRes.json();
  if (!adminPullRes.ok || !adminPullRaw.success) {
    throw new Error(`Admin pull failed (${adminPullRes.status}): ${JSON.stringify(adminPullRaw)}`);
  }
  const adminPullData = adminPullRaw.data;

  const productChange = adminPullData.changes.find(
    (c: any) => c.entityName === 'products' && c.recordId === testProductId
  );
  if (!productChange) {
    throw new Error(`FAIL: Admin did not receive the product created by Cashier! Changes received: ${adminPullData.changes.length}`);
  }
  const price = Number(productChange.data?.selling_price_paise ?? productChange.data?.sellingPricePaise ?? 0);
  console.log(`✔ Admin successfully pulled product "${productChange.data?.name}" (Price: ₹${price / 100})`);
  console.log(`  - Server cursor advanced to: ${adminPullData.nextCursor}`);

  console.log('\n=== ALL DEMO AUTH, MULTI-DEVICE PAIRING & SYNC TESTS PASSED! ===');
}

main().catch((err) => {
  console.error('\nVerification failed:', err);
  process.exit(1);
});
