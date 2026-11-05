import crypto from 'crypto';

const BASE_URL = 'http://127.0.0.1:3000/api/v1';

async function run() {
  console.log('=== MULTI-DEVICE CHROME & ANDROID PRODUCT SYNC TEST ===\n');

  // 1. Device 1: Chrome (Flutter Web) Login Simulation
  console.log('1. Testing Chrome (Flutter Web) Login with Cross-Origin headers...');
  const chromeRes = await fetch(`${BASE_URL}/auth/login`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Origin': 'http://localhost:54321', // Simulates Chrome Flutter Web local server origin
    },
    body: JSON.stringify({
      username: 'cashier',
      password: 'cashier123',
      deviceUid: 'chrome-web-client-uid-001',
      deviceName: 'Chrome Browser (Flutter Web)',
    }),
  });

  const corpHeader = chromeRes.headers.get('cross-origin-resource-policy');
  const acaoHeader = chromeRes.headers.get('access-control-allow-origin');
  console.log(`  - Status: ${chromeRes.status}`);
  console.log(`  - Cross-Origin-Resource-Policy: ${corpHeader}`);
  console.log(`  - Access-Control-Allow-Origin: ${acaoHeader}`);

  if (corpHeader === 'same-origin') {
    throw new Error('FAIL: Helmet blocked cross-origin requests with same-origin CORP!');
  }

  const chromeData: any = await chromeRes.json();
  if (!chromeRes.ok || !chromeData.success) {
    throw new Error(`Chrome login failed: ${JSON.stringify(chromeData)}`);
  }
  const chromeToken = chromeData.data.token;
  const chromeDeviceId = chromeData.data.deviceId;
  const businessId = chromeData.data.business.id;
  console.log(`✔ Chrome logged in successfully as Cashier (Business: ${businessId}, Device: ${chromeDeviceId})`);

  // 2. Device 2: Android Physical Phone Login Simulation
  console.log('\n2. Testing Android Phone Login as Admin...');
  const androidRes = await fetch(`${BASE_URL}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      username: 'admin',
      password: 'admin123',
      deviceUid: 'android-physical-phone-uid-002',
      deviceName: 'Samsung Galaxy / Pixel (Android App)',
    }),
  });

  const androidData: any = await androidRes.json();
  if (!androidRes.ok || !androidData.success) {
    throw new Error(`Android login failed: ${JSON.stringify(androidData)}`);
  }
  const androidToken = androidData.data.token;
  const androidDeviceId = androidData.data.deviceId;
  console.log(`✔ Android logged in successfully as Admin (Device: ${androidDeviceId})`);

  // 3. Get initial cursors for both devices
  const initialAndroidPullRes = await fetch(`${BASE_URL}/sync/pull?cursor=0&limit=50`, {
    headers: { Authorization: `Bearer ${androidToken}`, 'X-Device-Id': androidDeviceId },
  });
  const initialAndroidPull: any = await initialAndroidPullRes.json();
  let androidCursor = parseInt(initialAndroidPull.data.nextCursor);
  console.log(`  - Initial Android server cursor: ${androidCursor}`);

  // 4. Chrome creates and pushes a new product "Paneer Butter Masala"
  console.log('\n3. Chrome Cashier creates product "Paneer Butter Masala" (₹180.00)...');
  const testProductId = crypto.randomUUID();
  const pushProductRes = await fetch(`${BASE_URL}/sync/push`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${chromeToken}`,
      'X-Device-Id': chromeDeviceId,
    },
    body: JSON.stringify({
      deviceId: chromeDeviceId,
      items: [
        {
          entityName: 'products',
          operation: 'INSERT',
          recordId: testProductId,
          clientVersion: 1,
          payload: {
            id: testProductId,
            name: 'Paneer Butter Masala',
            code: 'PBM-01',
            sellingPricePaise: 18000,
            costPricePaise: 9000,
            gstRatePercent: 5.0,
            isTaxInclusive: true,
            unit: 'plate',
            isAvailable: true,
          },
        },
      ],
    }),
  });

  const pushProductData: any = await pushProductRes.json();
  if (!pushProductRes.ok || pushProductData.data.results[0].status !== 'synced') {
    throw new Error(`Product push failed: ${JSON.stringify(pushProductData)}`);
  }
  console.log(`✔ Chrome successfully pushed product to PostgreSQL. Server response: synced`);

  // 5. Android Phone Pulls Changes (Simulating auto-sync loop)
  console.log('\n4. Android Phone auto-sync pulls changes from server...');
  const androidPullRes = await fetch(`${BASE_URL}/sync/pull?cursor=${androidCursor}&limit=50`, {
    headers: { Authorization: `Bearer ${androidToken}`, 'X-Device-Id': androidDeviceId },
  });
  const androidPullData: any = await androidPullRes.json();
  const receivedProduct = androidPullData.data.changes.find(
    (c: any) => c.entityName === 'products' && c.recordId === testProductId
  );

  if (!receivedProduct) {
    throw new Error(`FAIL: Android phone did not receive the product created in Chrome!`);
  }
  console.log(`✔ Android phone received product: "${receivedProduct.data.name}"`);
  console.log(`  - Selling Price: ₹${receivedProduct.data.selling_price_paise / 100}`);
  console.log(`  - GST Rate: ${receivedProduct.data.gst_rate_percent}%`);
  androidCursor = parseInt(androidPullData.data.nextCursor);

  // 6. Android Phone Admin creates a Category "North Indian Curries"
  console.log('\n5. Android Phone Admin creates category "North Indian Curries"...');
  const testCategoryId = crypto.randomUUID();
  const pushCategoryRes = await fetch(`${BASE_URL}/sync/push`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${androidToken}`,
      'X-Device-Id': androidDeviceId,
    },
    body: JSON.stringify({
      deviceId: androidDeviceId,
      items: [
        {
          entityName: 'categories',
          operation: 'INSERT',
          recordId: testCategoryId,
          clientVersion: 1,
          payload: {
            id: testCategoryId,
            name: 'North Indian Curries',
            displayOrder: 1,
            isActive: true,
          },
        },
      ],
    }),
  });

  const pushCategoryData: any = await pushCategoryRes.json();
  if (!pushCategoryRes.ok || pushCategoryData.data.results[0].status !== 'synced') {
    throw new Error(`Category push from Android failed: ${JSON.stringify(pushCategoryData)}`);
  }
  console.log(`✔ Android successfully pushed category to PostgreSQL.`);

  // 7. Chrome Pulls Category (Simulating auto-sync loop)
  console.log('\n6. Chrome Browser auto-sync pulls changes to receive category...');
  const chromePullRes = await fetch(`${BASE_URL}/sync/pull?cursor=0&limit=50`, {
    headers: { Authorization: `Bearer ${chromeToken}`, 'X-Device-Id': chromeDeviceId },
  });
  const chromePullData: any = await chromePullRes.json();
  const receivedCategory = chromePullData.data.changes.find(
    (c: any) => c.entityName === 'categories' && c.recordId === testCategoryId
  );

  if (!receivedCategory) {
    throw new Error(`FAIL: Chrome browser did not receive category created on Android phone!`);
  }
  console.log(`✔ Chrome browser received category: "${receivedCategory.data.name}" (ID: ${receivedCategory.recordId})`);

  // 8. Chrome updates "Paneer Butter Masala" to link category and update price to ₹200.00
  console.log('\n7. Chrome Cashier edits product price to ₹200.00 and links category...');
  // Find current server version of the product
  const chromeProductPullRes = await fetch(`${BASE_URL}/sync/pull?cursor=0&limit=50`, {
    headers: { Authorization: `Bearer ${chromeToken}`, 'X-Device-Id': chromeDeviceId },
  });
  const chromeProductPullData: any = await chromeProductPullRes.json();
  const chromeProductChange = chromeProductPullData.data.changes.find((c: any) => c.recordId === testProductId);
  const currentProductVersion = chromeProductChange ? parseInt(chromeProductChange.version) : 0;

  const updateProductRes = await fetch(`${BASE_URL}/sync/push`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${chromeToken}`,
      'X-Device-Id': chromeDeviceId,
    },
    body: JSON.stringify({
      deviceId: chromeDeviceId,
      items: [
        {
          entityName: 'products',
          operation: 'UPDATE',
          recordId: testProductId,
          clientVersion: currentProductVersion,
          payload: {
            id: testProductId,
            categoryId: testCategoryId,
            name: 'Paneer Butter Masala (Special)',
            sellingPricePaise: 20000, // ₹200.00
            isAvailable: true,
          },
        },
      ],
    }),
  });

  const updateProductData: any = await updateProductRes.json();
  if (!updateProductRes.ok || updateProductData.data.results[0].status !== 'synced') {
    throw new Error(`Product update from Chrome failed: ${JSON.stringify(updateProductData)}`);
  }
  console.log(`✔ Product update pushed from Chrome.`);

  // 9. Android Phone pulls the updated product
  console.log('\n8. Android Phone pulls product update...');
  const androidPullUpdateRes = await fetch(`${BASE_URL}/sync/pull?cursor=${androidCursor}&limit=50`, {
    headers: { Authorization: `Bearer ${androidToken}`, 'X-Device-Id': androidDeviceId },
  });
  const androidPullUpdateData: any = await androidPullUpdateRes.json();
  const updatedProduct = androidPullUpdateData.data.changes.find(
    (c: any) => c.entityName === 'products' && c.recordId === testProductId
  );

  if (!updatedProduct) {
    throw new Error(`FAIL: Android phone did not receive the product update!`);
  }
  console.log(`✔ Android received updated product: "${updatedProduct.data.name}"`);
  console.log(`  - New Price: ₹${updatedProduct.data.selling_price_paise / 100}`);
  console.log(`  - Linked Category: ${updatedProduct.data.category_id}`);

  console.log('\n=== ALL CHROME <-> ANDROID SYNC TESTS PASSED PERFECTLY! ===');
}

run().catch((err) => {
  console.error('\n❌ TEST FAILED:', err);
  process.exit(1);
});
