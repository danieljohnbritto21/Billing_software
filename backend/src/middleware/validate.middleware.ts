import { Request, Response, NextFunction } from 'express';
import { ZodSchema, ZodError } from 'zod';

export function validateBody(schema: ZodSchema) {
  return (req: Request, res: Response, next: NextFunction) => {
    const result = schema.safeParse(req.body);
    if (!result.success) {
      return res.status(400).json({
        success: false,
        error: 'Validation failed on request body',
        details: formatZodError(result.error),
      });
    }
    req.body = result.data;
    next();
  };
}

export function validateQuery(schema: ZodSchema) {
  return (req: Request, res: Response, next: NextFunction) => {
    const result = schema.safeParse(req.query);
    if (!result.success) {
      return res.status(400).json({
        success: false,
        error: 'Validation failed on query parameters',
        details: formatZodError(result.error),
      });
    }
    req.query = result.data as any;
    next();
  };
}

export function validateParams(schema: ZodSchema) {
  return (req: Request, res: Response, next: NextFunction) => {
    const result = schema.safeParse(req.params);
    if (!result.success) {
      return res.status(400).json({
        success: false,
        error: 'Validation failed on path parameters',
        details: formatZodError(result.error),
      });
    }
    req.params = result.data as any;
    next();
  };
}

function formatZodError(error: ZodError) {
  return error.errors.map((err) => ({
    path: err.path.join('.'),
    message: err.message,
  }));
}
