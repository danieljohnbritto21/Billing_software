import { Request, Response, NextFunction } from 'express';
import { Prisma } from '@prisma/client';

export class AppError extends Error {
  constructor(
    public statusCode: number,
    public override message: string,
    public details?: any
  ) {
    super(message);
    Object.setPrototypeOf(this, new.target.prototype);
  }
}

export function errorHandler(
  err: any,
  req: Request,
  res: Response,
  next: NextFunction
) {
  // If headers already sent, delegate to default express error handler
  if (res.headersSent) {
    return next(err);
  }

  // Custom AppError
  if (err instanceof AppError) {
    return res.status(err.statusCode).json({
      success: false,
      error: err.message,
      details: err.details,
    });
  }

  // Prisma Known Request Error
  if (err instanceof Prisma.PrismaClientKnownRequestError) {
    switch (err.code) {
      case 'P2002': {
        const target = (err.meta?.target as string[]) || [];
        return res.status(409).json({
          success: false,
          error: `Unique constraint violation on field(s): ${target.join(', ')}`,
          code: err.code,
        });
      }
      case 'P2003': {
        return res.status(400).json({
          success: false,
          error: 'Foreign key constraint failure. Referenced record does not exist or belongs to another business.',
          code: err.code,
        });
      }
      case 'P2025': {
        return res.status(404).json({
          success: false,
          error: 'Record not found or already deleted.',
          code: err.code,
        });
      }
      default:
        break;
    }
  }

  // PostgreSQL Trigger / Constraint Exception (passed via Prisma)
  const message = err.message || '';
  if (
    message.includes('strictly prohibited') ||
    message.includes('finalized') ||
    message.includes('cannot be altered') ||
    message.includes('Cannot add items') ||
    message.includes('Cannot modify items') ||
    message.includes('Cannot move item')
  ) {
    return res.status(400).json({
      success: false,
      error: 'Business rule / integrity constraint violation',
      details: message,
    });
  }

  console.error('Unhandled Server Error:', err);
  return res.status(500).json({
    success: false,
    error: 'Internal Server Error',
    message: process.env.NODE_ENV === 'development' ? err.message : undefined,
  });
}
