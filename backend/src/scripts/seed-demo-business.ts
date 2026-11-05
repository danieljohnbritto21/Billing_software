import bcrypt from 'bcryptjs';
import { randomUUID } from 'crypto';
import { prisma } from '../config/prisma';

export const DEMO_BUSINESS_NAME = 'FoodBill Pro Demo';
export const DEMO_ADMIN_USERNAME = 'admin';
export const DEMO_ADMIN_PASSWORD = 'admin123';
export const DEMO_CASHIER_USERNAME = 'cashier';
export const DEMO_CASHIER_PASSWORD = 'cashier123';

export const STANDARD_CATEGORIES = [
  { name: 'Fast Food', display_order: 0, icon: 'fastfood' },
  { name: 'Beverages', display_order: 1, icon: 'local_cafe' },
  { name: 'Main Course', display_order: 2, icon: 'restaurant' },
  { name: 'Snacks', display_order: 3, icon: 'lunch_dining' },
  { name: 'Bakery', display_order: 4, icon: 'bakery_dining' },
  { name: 'Desserts', display_order: 5, icon: 'icecream' },
  { name: 'Combos', display_order: 6, icon: 'set_meal' },
];

/**
 * Idempotently ensures all standard categories exist for the demo business.
 */
export async function ensureDemoCategories(businessId: string) {
  for (const cat of STANDARD_CATEGORIES) {
    const existing = await prisma.categories.findFirst({
      where: { business_id: businessId, name: cat.name, deleted_at: null },
    });
    if (!existing) {
      await prisma.categories.create({
        data: {
          id: randomUUID(),
          business_id: businessId,
          name: cat.name,
          display_order: cat.display_order,
          icon: cat.icon,
          is_active: true,
        },
      });
      console.log(`  + Seeded standard category "${cat.name}" for demo business`);
    }
  }
}

/**
 * Idempotently seeds the isolated demo business and its admin/cashier accounts.
 * If the demo business or demo users already exist, it leaves them untouched.
 * Never touches or modifies any other business or production users.
 */
export async function seedDemoBusiness() {
  console.log('--- Checking for existing demo business ---');

  // Check by business name
  const existingBiz = await prisma.businesses.findFirst({
    where: { name: DEMO_BUSINESS_NAME },
  });

  // Check by username
  const existingAdmin = await prisma.users.findFirst({
    where: { username: DEMO_ADMIN_USERNAME },
  });

  const existingCashier = await prisma.users.findFirst({
    where: { username: DEMO_CASHIER_USERNAME },
  });

  if (existingBiz || existingAdmin || existingCashier) {
    console.log('Demo business or demo users already exist:');
    if (existingBiz) {
      console.log(`  - Business "${DEMO_BUSINESS_NAME}" ID: ${existingBiz.id}`);
      await ensureDemoCategories(existingBiz.id);
    }
    if (existingAdmin) console.log(`  - User "${DEMO_ADMIN_USERNAME}" ID: ${existingAdmin.id} (Biz: ${existingAdmin.business_id})`);
    if (existingCashier) console.log(`  - User "${DEMO_CASHIER_USERNAME}" ID: ${existingCashier.id} (Biz: ${existingCashier.business_id})`);
    console.log('Idempotent check satisfied: Verified demo business configuration.');
    return {
      businessId: existingBiz?.id,
      adminId: existingAdmin?.id,
      cashierId: existingCashier?.id,
      created: false,
    };
  }

  console.log(`Creating isolated business: "${DEMO_BUSINESS_NAME}"...`);

  return await prisma.$transaction(async (tx) => {
    // 1. Create Demo Business
    const business = await tx.businesses.create({
      data: {
        name: DEMO_BUSINESS_NAME,
        tagline: 'Restaurant & POS Demo',
        phone: '+919876543210',
        address: 'Demo Food Court, Cyber Hub, Bengaluru',
        gstin: '29ABCDE1234F1Z5',
        invoice_prefix: 'DEMO-',
        printer_width: '80mm',
      },
    });

    // 2. Ensure cursor entry exists for business
    await tx.business_sync_cursors.create({
      data: {
        business_id: business.id,
        last_cursor: 0,
      },
    });

    // 3. Create Demo Admin User
    const adminSalt = await bcrypt.genSalt(10);
    const adminPasswordHash = await bcrypt.hash(DEMO_ADMIN_PASSWORD, adminSalt);

    const adminUser = await tx.users.create({
      data: {
        business_id: business.id,
        username: DEMO_ADMIN_USERNAME,
        full_name: 'Demo Administrator',
        role_id: 'admin',
        password_hash: adminPasswordHash,
        salt: adminSalt,
        is_active: true,
      },
    });

    // 4. Create Demo Cashier User under the EXACT SAME business_id
    const cashierSalt = await bcrypt.genSalt(10);
    const cashierPasswordHash = await bcrypt.hash(DEMO_CASHIER_PASSWORD, cashierSalt);

    const cashierUser = await tx.users.create({
      data: {
        business_id: business.id,
        username: DEMO_CASHIER_USERNAME,
        full_name: 'Demo Cashier',
        role_id: 'cashier',
        password_hash: cashierPasswordHash,
        salt: cashierSalt,
        is_active: true,
      },
    });

    // 5. Default Business Settings for POS
    const defaultSettings = [
      { setting_key: 'tax_rate', setting_value: '5.0' },
      { setting_key: 'tax_inclusive', setting_value: 'true' },
      { setting_key: 'printer_paper_width', setting_value: '80mm' },
      { setting_key: 'invoice_prefix', setting_value: 'DEMO-' },
      { setting_key: 'currency_code', setting_value: 'INR' },
      { setting_key: 'currency_symbol', setting_value: '₹' },
    ];

    for (const s of defaultSettings) {
      await tx.business_settings.create({
        data: {
          business_id: business.id,
          setting_key: s.setting_key,
          setting_value: s.setting_value,
        },
      });
    }

    // 6. Pre-seed standard categories for the demo business
    for (const cat of STANDARD_CATEGORIES) {
      await tx.categories.create({
        data: {
          id: randomUUID(),
          business_id: business.id,
          name: cat.name,
          display_order: cat.display_order,
          icon: cat.icon,
          is_active: true,
        },
      });
    }

    // 7. Pre-register authorized terminals for Admin and Cashier so physical phones sync seamlessly
    const adminDevice = await tx.devices.create({
      data: {
        business_id: business.id,
        device_uid: `demo-admin-${business.id}`,
        device_name: 'Demo Admin Phone',
        is_authorized: true,
        authorized_at: new Date(),
        last_seen_at: new Date(),
      },
    });

    const cashierDevice = await tx.devices.create({
      data: {
        business_id: business.id,
        device_uid: `demo-cashier-${business.id}`,
        device_name: 'Demo Cashier Phone',
        is_authorized: true,
        authorized_at: new Date(),
        last_seen_at: new Date(),
      },
    });

    console.log(`Demo business successfully created:`);
    console.log(`  - Business ID: ${business.id}`);
    console.log(`  - Admin User: ${adminUser.username} (${adminUser.id})`);
    console.log(`  - Cashier User: ${cashierUser.username} (${cashierUser.id})`);
    console.log(`  - Admin Device: ${adminDevice.device_name} (${adminDevice.id})`);
    console.log(`  - Cashier Device: ${cashierDevice.device_name} (${cashierDevice.id})`);

    return {
      businessId: business.id,
      adminId: adminUser.id,
      cashierId: cashierUser.id,
      created: true,
    };
  });
}

/**
 * Reversibly removes ONLY the demo business and its child entities.
 * Strictly checks for DEMO_BUSINESS_NAME. Never affects any other business.
 */
export async function undoDemoBusiness() {
  console.log(`--- Reversing demo business: "${DEMO_BUSINESS_NAME}" ---`);

  const demoBiz = await prisma.businesses.findFirst({
    where: { name: DEMO_BUSINESS_NAME },
  });

  if (!demoBiz) {
    console.log(`Demo business "${DEMO_BUSINESS_NAME}" not found. Nothing to undo.`);
    return;
  }

  const bizId = demoBiz.id;
  console.log(`Found demo business ID: ${bizId}. Deleting demo entities...`);

  await prisma.$transaction(async (tx) => {
    // Delete in reverse FK dependency order
    await tx.user_sessions.deleteMany({ where: { business_id: bizId } });
    await tx.device_sync_state.deleteMany({ where: { devices: { business_id: bizId } } });
    await tx.devices.deleteMany({ where: { business_id: bizId } });
    await tx.users.deleteMany({ where: { business_id: bizId } });
    await tx.business_settings.deleteMany({ where: { business_id: bizId } });
    await tx.business_sync_cursors.deleteMany({ where: { business_id: bizId } });
    await tx.sync_change_log.deleteMany({ where: { business_id: bizId } });
    await tx.products.deleteMany({ where: { business_id: bizId } });
    await tx.categories.deleteMany({ where: { business_id: bizId } });
    await tx.dining_tables.deleteMany({ where: { business_id: bizId } });
    await tx.customers.deleteMany({ where: { business_id: bizId } });
    await tx.businesses.delete({ where: { id: bizId } });
  });

  console.log(`Demo business ${bizId} successfully removed. No production data touched.`);
}

// CLI runner
async function main() {
  const isUndo = process.argv.includes('--undo');
  try {
    if (isUndo) {
      await undoDemoBusiness();
    } else {
      await seedDemoBusiness();
    }
  } catch (err) {
    console.error('Demo business seed error:', err);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

if (require.main === module) {
  main();
}
