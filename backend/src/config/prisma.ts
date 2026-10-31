import { PrismaClient } from '@prisma/client';
import { env } from './env';

// Allow BigInt to serialize cleanly to JSON
(BigInt.prototype as any).toJSON = function () {
  const intVal = Number(this);
  return Number.isSafeInteger(intVal) ? intVal : this.toString();
};

export const prisma = new PrismaClient({
  log: env.NODE_ENV === 'development' ? ['warn', 'error'] : ['error'],
});

export async function connectPrisma() {
  await prisma.$connect();
}

export async function disconnectPrisma() {
  await prisma.$disconnect();
}
