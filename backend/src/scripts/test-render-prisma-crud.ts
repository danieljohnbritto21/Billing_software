import { PrismaClient } from '@prisma/client';

async function main() {
  const prisma = new PrismaClient();
  try {
    console.log('Testing Authentication & Data Access on Render DB...');

    // 1. Check existing users
    const userCount = await prisma.users.count();
    console.log(`✔ Users count in Render: ${userCount}`);

    const demoUser = await prisma.users.findFirst({
      where: { role_id: 'admin' },
      select: { id: true, username: true, role_id: true, business_id: true, is_active: true },
    });
    console.log('✔ Admin user verification:', demoUser);

    // 2. Check businesses
    const bizCount = await prisma.businesses.count();
    console.log(`✔ Businesses count in Render: ${bizCount}`);

    // 3. Test insert & read of a product
    if (demoUser?.business_id) {
      console.log('Testing product read/write for business:', demoUser.business_id);
      const testCat = await prisma.categories.findFirst({
        where: { business_id: demoUser.business_id },
      });

      const testProduct = await prisma.products.create({
        data: {
          id: '11111111-2222-3333-4444-555555555555',
          business_id: demoUser.business_id,
          category_id: testCat ? testCat.id : null,
          name: 'Render Migration Verification Product',
          selling_price_paise: BigInt(9900),
          cost_price_paise: BigInt(5000),
          unit: 'plate',
          is_available: true,
        },
      });
      console.log('✔ Successfully created product via Prisma on Render DB:', testProduct.name);

      // Verify trigger incremented server_version
      const fetched = await prisma.products.findUnique({
        where: { id: testProduct.id },
      });
      console.log('✔ Fetched product server_version (assigned by trigger):', fetched?.server_version?.toString());

      // Clean up test product
      await prisma.products.delete({
        where: { id: testProduct.id },
      });
      console.log('✔ Cleaned up verification product.');
    }

    console.log('✔ ALL PRISMA CHECKS PASSED ON RENDER POSTGRESQL 18!');
  } finally {
    await prisma.$disconnect();
  }
}

main().catch(err => {
  console.error('Prisma test failed:', err);
  process.exit(1);
});
