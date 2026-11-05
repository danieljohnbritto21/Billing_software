import express, { Request, Response, NextFunction } from 'express';
import helmet from 'helmet';
import cors from 'cors';
import { apiRouter } from './routes';
import { errorHandler } from './middleware/error.middleware';
import { prisma } from './config/prisma';
import { logger } from './utils/logger';

export const app = express();

// Disable ETag generation to prevent HTTP 304 caching on dynamic sync and API endpoints
app.set('etag', false);

// Security Middlewares
app.use(
  helmet({
    crossOriginResourcePolicy: { policy: 'cross-origin' },
  })
);
app.use(
  cors({
    origin: true, // Dynamically reflect caller origin (Flutter Web on Chrome localhost, mobile, etc.)
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Device-Id', 'X-Idempotency-Key', 'Accept', 'Cache-Control', 'Pragma'],
  })
);

// Body Parsers with limits
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Request Logging Middleware
app.use((req: Request, res: Response, next: NextFunction) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = Date.now() - start;
    const deviceId = req.headers['x-device-id'] || req.user?.deviceId || 'none';
    logger.info(`${req.method} ${req.originalUrl} ${res.statusCode} - ${duration}ms [device: ${deviceId}]`);
  });
  next();
});

// Health check endpoint (checks DB connection)
app.get('/health', async (req: Request, res: Response) => {
  try {
    await prisma.$queryRaw`SELECT 1`;
    return res.status(200).json({
      status: 'UP',
      database: 'connected',
      timestamp: new Date().toISOString(),
      uptimeSeconds: process.uptime(),
    });
  } catch (err: any) {
    return res.status(503).json({
      status: 'DOWN',
      database: 'disconnected',
      error: err.message,
    });
  }
});

// Explicitly prevent caching on all /api/v1 endpoints
app.use('/api/v1', (req: Request, res: Response, next: NextFunction) => {
  res.set({
    'Cache-Control': 'no-store, no-cache, must-revalidate, proxy-revalidate',
    'Pragma': 'no-cache',
    'Expires': '0',
    'Surrogate-Control': 'no-store',
  });
  next();
});

// API Routes
app.use('/api/v1', apiRouter);

// 404 Handler
app.use((req: Request, res: Response) => {
  res.status(404).json({
    success: false,
    error: `Route ${req.method} ${req.originalUrl} not found`,
  });
});

// Centralized Error Handler
app.use(errorHandler);
