const { PrismaClient } = require('@prisma/client');
const p = new PrismaClient();
p.products.findFirst({ where: { name: 'babu' } }).then(r => {
  console.log('Record for babu:');
  console.log(r);
  p.$disconnect();
}).catch(e => {
  console.error(e);
  p.$disconnect();
});
