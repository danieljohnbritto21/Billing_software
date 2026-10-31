import { app } from './app';
import { env } from './config/env';
import { connectPrisma, disconnectPrisma } from './config/prisma';
import { logger } from './utils/logger';

async function bootstrap() {
  try {
    logger.info('Connecting to PostgreSQL database...');
    await connectPrisma();
    logger.info('PostgreSQL connected successfully.');

    const server = app.listen(env.PORT, env.HOST, () => {
      logger.info(`🚀 FoodBill Pro Backend running at http://${env.HOST}:${env.PORT}`);
      logger.info(`Health check available at http://${env.HOST}:${env.PORT}/health`);
      logger.info(`API endpoints mounted at http://${env.HOST}:${env.PORT}/api/v1`);
    });

    const shutdown = async (signal: string) => {
      logger.info(`Received ${signal}. Shutting down gracefully...`);
      server.close(async () => {
        await disconnectPrisma();
        logger.info('Database disconnected. Process exited.');
        process.exit(0);
      });
    };

    process.on('SIGINT', () => shutdown('SIGINT'));
    process.on('SIGTERM', () => shutdown('SIGTERM'));
  } catch (err: any) {
    logger.error('Failed to start FoodBill Pro backend:', err);
    process.exit(1);
  }
}

bootstrap();
