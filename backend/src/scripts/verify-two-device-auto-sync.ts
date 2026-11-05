import { randomUUID } from 'crypto';
import { prisma } from '../config/prisma';

const BASE_URL = process.env.API_BASE_URL || 'http://127.0.0.1:3000/api/v1';

async function runTwoDeviceAutoSyncTest() {
  console.log('================================================================');
  console.log('  FOODBILL PRO — TWO-DEVICE LIVE PRODUCT AUTO-SYNC VERIFICATION');
  console.log('================================================================\n');

  try {
    // 1. Device Registration & Login for Phone A (Admin) and Phone B (Cashier)
    console.log('[Step 1] Authenticating Phone A (Admin) and Phone B (Cashier)...');
    const deviceAUid = randomUUID();
    const deviceBUid = randomUUID();

    const loginResA = await fetch(`${BASE_URL}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        username: 'admin',
        password: 'admin123',
        deviceUid: deviceAUid,
        deviceName: 'Pixel 8 Pro (Admin Handset)',
      }),
    });
    const loginDataA: any = await loginResA.json();
    if (!loginResA.ok || !loginDataA.success) {
      throw new Error(`Phone A login failed: ${JSON.stringify(loginDataA)}`);
    }
    const tokenA = loginDataA.data.token;
    const businessIdA = loginDataA.data.business.id;
    console.log(`  -> Phone A authenticated: Business=${businessIdA}, User=${loginDataA.data.user.username}`);

    const loginResB = await fetch(`${BASE_URL}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        username: 'cashier',
        password: 'cashier123',
        deviceUid: deviceBUid,
        deviceName: 'Galaxy S23 (Cashier Handset)',
      }),
    });
    const loginDataB: any = await loginResB.json();
    if (!loginResB.ok || !loginDataB.success) {
      throw new Error(`Phone B login failed: ${JSON.stringify(loginDataB)}`);
    }
    const tokenB = loginDataB.data.token;
    const businessIdB = loginDataB.data.business.id;
    console.log(`  -> Phone B authenticated: Business=${businessIdB}, User=${loginDataB.data.user.username}`);

    if (businessIdA !== businessIdB) {
      throw new Error(`Business ID mismatch: Phone A=${businessIdA}, Phone B=${businessIdB}`);
    }
    console.log('  [PASS] Both devices successfully authenticated to the same business.\n');

    // 2. Initial Sync Pull for both devices
    console.log('[Step 2] Initializing sync cursors for Phone A and Phone B...');
    const pullA0 = await fetch(`${BASE_URL}/sync/pull?cursor=0&limit=50`, {
      headers: { Authorization: `Bearer ${tokenA}` },
    });
    const pullDataA0: any = await pullA0.json();
    let cursorA = BigInt(pullDataA0.data.nextCursor || 0);

    const pullB0 = await fetch(`${BASE_URL}/sync/pull?cursor=0&limit=50`, {
      headers: { Authorization: `Bearer ${tokenB}` },
    });
    const pullDataB0: any = await pullB0.json();
    let cursorB = BigInt(pullDataB0.data.nextCursor || 0);

    console.log(`  -> Initial Phone A cursor: ${cursorA}`);
    console.log(`  -> Initial Phone B cursor: ${cursorB}`);
    console.log('  [PASS] Cursors initialized.\n');

    // 3. Admin on Phone A creates a new Category: "Live Shakes"
    const testCatId = randomUUID();
    console.log(`[Step 3] Phone A (Admin) creates Category: "Live Shakes" (ID=${testCatId})...`);
    const catPushRes = await fetch(`${BASE_URL}/sync/push`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenA}`,
      },
      body: JSON.stringify({
        deviceId: deviceAUid,
        items: [
          {
            entityName: 'categories',
            operation: 'INSERT',
            recordId: testCatId,
            clientVersion: 0,
            payload: {
              id: testCatId,
              name: 'Live Shakes',
              icon: 'restaurant_menu',
              colorValue: 4283215696,
              displayOrder: 10,
              isActive: true,
            },
          },
        ],
      }),
    });
    const catPushData: any = await catPushRes.json();
    if (!catPushRes.ok || !catPushData.success) {
      throw new Error(`Category push failed: ${JSON.stringify(catPushData)}`);
    }
    const catResult = catPushData.data.results[0];
    console.log(`  -> Phone A push result: status=${catResult.status}, serverVersion=${catResult.serverVersion}`);
    if (catResult.status !== 'synced') {
      throw new Error(`Category push status not synced: ${JSON.stringify(catResult)}`);
    }

    // Verify in PostgreSQL
    const catInDb = await prisma.categories.findFirst({
      where: { id: testCatId, business_id: businessIdA },
    });
    if (!catInDb) throw new Error(`Category ${testCatId} not found in PostgreSQL!`);
    console.log(`  -> Verified in PostgreSQL: name="${catInDb.name}", version=${catInDb.server_version}`);
    console.log('  [PASS] Category committed permanently to PostgreSQL.\n');

    // 4. Phone B automatically pulls changes (simulating 5s auto-sync loop)
    console.log('[Step 4] Phone B (Cashier) auto-syncs (pulls from server)...');
    const pullB1 = await fetch(`${BASE_URL}/sync/pull?cursor=${cursorB}&limit=50`, {
      headers: { Authorization: `Bearer ${tokenB}` },
    });
    const pullDataB1: any = await pullB1.json();
    const changesForB1 = pullDataB1.data.changes;
    cursorB = BigInt(pullDataB1.data.nextCursor);

    const receivedCat = changesForB1.find((c: any) => c.entityName === 'categories' && c.recordId === testCatId);
    if (!receivedCat) {
      throw new Error(`Phone B did not receive the category! Changes=${JSON.stringify(changesForB1)}`);
    }
    console.log(`  -> Phone B received category: "${receivedCat.data.name}" at cursor ${receivedCat.cursor}`);
    console.log('  [PASS] Phone B received category automatically.\n');

    // 5. Cashier on Phone B creates a new Product: "Mango Delight Shake"
    const testProdId1 = randomUUID();
    console.log(`[Step 5] Phone B (Cashier) creates Product: "Mango Delight Shake" (ID=${testProdId1})...`);
    const prodPushRes = await fetch(`${BASE_URL}/sync/push`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenB}`,
      },
      body: JSON.stringify({
        deviceId: deviceBUid,
        items: [
          {
            entityName: 'products',
            operation: 'INSERT',
            recordId: testProdId1,
            clientVersion: 0,
            payload: {
              id: testProdId1,
              name: 'Mango Delight Shake',
              code: 'MDS-01',
              categoryId: testCatId,
              categoryName: 'Live Shakes',
              sellingPricePaise: 16000, // Rs 160
              costPricePaise: 6000,
              gstRatePercent: 5.0,
              isTaxInclusive: true,
              unit: 'glass',
              isAvailable: true,
            },
          },
        ],
      }),
    });
    const prodPushData: any = await prodPushRes.json();
    if (!prodPushRes.ok || !prodPushData.success) {
      throw new Error(`Product push failed: ${JSON.stringify(prodPushData)}`);
    }
    const prodResult = prodPushData.data.results[0];
    console.log(`  -> Phone B push result: status=${prodResult.status}, serverVersion=${prodResult.serverVersion}`);
    if (prodResult.status !== 'synced') {
      throw new Error(`Product push failed: ${JSON.stringify(prodResult)}`);
    }

    // Verify product in PostgreSQL
    const prodInDb = await prisma.products.findFirst({
      where: { id: testProdId1, business_id: businessIdB },
      include: { categories: true },
    });
    if (!prodInDb) throw new Error(`Product ${testProdId1} not found in PostgreSQL!`);
    console.log(`  -> Verified in PostgreSQL: name="${prodInDb.name}", price=${prodInDb.selling_price_paise} paise, category="${prodInDb.categories?.name}"`);
    console.log('  [PASS] Product committed permanently to PostgreSQL.\n');

    // 6. Phone A automatically pulls changes (simulating 5s auto-sync loop)
    console.log('[Step 6] Phone A (Admin) auto-syncs (pulls from server)...');
    const pullA1 = await fetch(`${BASE_URL}/sync/pull?cursor=${cursorA}&limit=50`, {
      headers: { Authorization: `Bearer ${tokenA}` },
    });
    const pullDataA1: any = await pullA1.json();
    const changesForA1 = pullDataA1.data.changes;
    cursorA = BigInt(pullDataA1.data.nextCursor);

    const receivedProd = changesForA1.find((c: any) => c.entityName === 'products' && c.recordId === testProdId1);
    if (!receivedProd) {
      throw new Error(`Phone A did not receive the product! Changes=${JSON.stringify(changesForA1)}`);
    }
    console.log(`  -> Phone A received product: "${receivedProd.data.name}", price=${receivedProd.data.selling_price_paise} paise, category_name="${receivedProd.data.category_name}"`);
    console.log('  [PASS] Phone A received product automatically.\n');

    // 7. Phone B updates product price from Rs 160 to Rs 180
    console.log('[Step 7] Phone B (Cashier) updates price of "Mango Delight Shake" to Rs 180 (18000 paise)...');
    const updatePushRes = await fetch(`${BASE_URL}/sync/push`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenB}`,
      },
      body: JSON.stringify({
        deviceId: deviceBUid,
        items: [
          {
            entityName: 'products',
            operation: 'UPDATE',
            recordId: testProdId1,
            clientVersion: Number(prodInDb.server_version || 0n),
            payload: {
              id: testProdId1,
              name: 'Mango Delight Shake',
              code: 'MDS-01',
              categoryId: testCatId,
              sellingPricePaise: 18000,
              costPricePaise: 6000,
              gstRatePercent: 5.0,
              isTaxInclusive: true,
              unit: 'glass',
              isAvailable: true,
            },
          },
        ],
      }),
    });
    const updatePushData: any = await updatePushRes.json();
    if (!updatePushRes.ok || !updatePushData.success) {
      throw new Error(`Update push failed: ${JSON.stringify(updatePushData)}`);
    }
    const updateResult = updatePushData.data.results[0];
    console.log(`  -> Phone B update push result: status=${updateResult.status}, serverVersion=${updateResult.serverVersion}`);
    if (updateResult.status !== 'synced') {
      throw new Error(`Product update push failed: ${JSON.stringify(updateResult)}`);
    }

    // Phone A pulls update
    const pullA2 = await fetch(`${BASE_URL}/sync/pull?cursor=${cursorA}&limit=50`, {
      headers: { Authorization: `Bearer ${tokenA}` },
    });
    const pullDataA2: any = await pullA2.json();
    const receivedUpdatedProd = pullDataA2.data.changes.find((c: any) => c.entityName === 'products' && c.recordId === testProdId1);
    if (!receivedUpdatedProd || Number(receivedUpdatedProd.data.selling_price_paise) !== 18000) {
      throw new Error(`Phone A did not receive updated price! Record=${JSON.stringify(receivedUpdatedProd)}`);
    }
    cursorA = BigInt(pullDataA2.data.nextCursor);
    console.log(`  -> Phone A received updated price: ${receivedUpdatedProd.data.selling_price_paise} paise`);
    console.log('  [PASS] Product update synchronized across phones.\n');

    // 8. Offline & Reconnect Workflow Simulation
    console.log('[Step 8] Simulating Offline & Reconnection Workflow:');
    console.log('  -> Phone B enters offline mode (airplane mode/no Wi-Fi).');
    const testProdId2 = randomUUID();
    const testProdId3 = randomUUID();

    // Phone A creates a product while Phone B is offline
    console.log(`  -> Phone A creates product while Phone B is offline: "Cold Coffee" (ID=${testProdId2})...`);
    await fetch(`${BASE_URL}/sync/push`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenA}`,
      },
      body: JSON.stringify({
        deviceId: deviceAUid,
        items: [
          {
            entityName: 'products',
            operation: 'INSERT',
            recordId: testProdId2,
            clientVersion: 0,
            payload: {
              id: testProdId2,
              name: 'Cold Coffee Special',
              code: 'CCS-01',
              categoryId: testCatId,
              sellingPricePaise: 12000, // Rs 120
              isTaxInclusive: true,
              unit: 'cup',
              isAvailable: true,
            },
          },
        ],
      }),
    });
    console.log('  -> "Cold Coffee Special" committed to server outbox.');

    // Phone B creates a product locally while offline (stored in local queue)
    console.log(`  -> Phone B creates product locally while offline: "Oreo Shake" (ID=${testProdId3})...`);
    console.log('  -> Phone B regains connectivity (reconnected to Wi-Fi).');

    // Phone B comes online: pushes its offline product
    console.log('  -> Phone B flushes offline queue (pushes "Oreo Shake")...');
    const offlineFlushRes = await fetch(`${BASE_URL}/sync/push`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenB}`,
      },
      body: JSON.stringify({
        deviceId: deviceBUid,
        items: [
          {
            entityName: 'products',
            operation: 'INSERT',
            recordId: testProdId3,
            clientVersion: 0,
            payload: {
              id: testProdId3,
              name: 'Oreo Shake Supreme',
              code: 'OSS-01',
              categoryId: testCatId,
              sellingPricePaise: 15000, // Rs 150
              isTaxInclusive: true,
              unit: 'glass',
              isAvailable: true,
            },
          },
        ],
      }),
    });
    const offlineFlushData: any = await offlineFlushRes.json();
    if (!offlineFlushRes.ok || offlineFlushData.data.results[0].status !== 'synced') {
      throw new Error(`Offline flush failed: ${JSON.stringify(offlineFlushData)}`);
    }
    console.log('  -> Phone B offline product successfully committed to server.');

    // Phone B pulls remote changes accumulated while it was offline
    console.log('  -> Phone B pulls server changes since cursor ' + cursorB + '...');
    const pullBOffline = await fetch(`${BASE_URL}/sync/pull?cursor=${cursorB}&limit=50`, {
      headers: { Authorization: `Bearer ${tokenB}` },
    });
    const pullDataBOffline: any = await pullBOffline.json();
    const phoneBReceivedFromA = pullDataBOffline.data.changes.find((c: any) => c.entityName === 'products' && c.recordId === testProdId2);
    if (!phoneBReceivedFromA) {
      throw new Error(`Phone B did not receive product created by Phone A during offline period!`);
    }
    console.log(`  -> Phone B received "Cold Coffee Special" created while it was offline!`);

    // Phone A pulls changes created by Phone B
    console.log('  -> Phone A pulls server changes since cursor ' + cursorA + '...');
    const pullAOffline = await fetch(`${BASE_URL}/sync/pull?cursor=${cursorA}&limit=50`, {
      headers: { Authorization: `Bearer ${tokenA}` },
    });
    const pullDataAOffline: any = await pullAOffline.json();
    const phoneAReceivedFromB = pullDataAOffline.data.changes.find((c: any) => c.entityName === 'products' && c.recordId === testProdId3);
    if (!phoneAReceivedFromB) {
      throw new Error(`Phone A did not receive product created by Phone B while offline!`);
    }
    console.log(`  -> Phone A received "Oreo Shake Supreme" flushed by Phone B!`);
    console.log('  [PASS] Offline creation, queue flush, and catch-up pull verified in both directions.\n');

    // 9. Clean up test products/categories so demo business remains pristine
    console.log('[Step 9] Cleaning up test records to preserve pristine demo database...');
    await prisma.sync_change_log.deleteMany({
      where: {
        business_id: businessIdA,
        record_id: { in: [testCatId, testProdId1, testProdId2, testProdId3] },
      },
    });
    await prisma.products.deleteMany({
      where: {
        business_id: businessIdA,
        id: { in: [testProdId1, testProdId2, testProdId3] },
      },
    });
    await prisma.categories.deleteMany({
      where: {
        business_id: businessIdA,
        id: testCatId,
      },
    });
    console.log('  [PASS] Test records safely cleaned up.\n');

    console.log('================================================================');
    console.log('  RESULT: 100% OF TWO-DEVICE AUTOMATIC SYNC TESTS PASSED!');
    console.log('================================================================');
  } catch (err: any) {
    console.error('\n[FATAL ERROR in Two-Device Auto-Sync Test]:', err.message);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

runTwoDeviceAutoSyncTest();
