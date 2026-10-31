import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { env } from '../config/env';

export interface AuthUser {
  userId: string;
  businessId: string;
  role: 'admin' | 'cashier';
  username: string;
  deviceId?: string;
}

declare global {
  namespace Express {
    interface Request {
      user?: AuthUser;
    }
  }
}

export function requireAuth(req: Request, res: Response, next: NextFunction) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      success: false,
      error: 'Authentication required. Missing or malformed Bearer token.',
    });
  }

  const token = authHeader.substring(7);
  try {
    const payload = jwt.verify(token, env.JWT_SECRET) as AuthUser;
    req.user = payload;
    return next();
  } catch (err: any) {
    return res.status(401).json({
      success: false,
      error: 'Invalid or expired token',
      details: err.message,
    });
  }
}

export function requireRole(...allowedRoles: Array<'admin' | 'cashier'>) {
  return (req: Request, res: Response, next: NextFunction) => {
    if (!req.user) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }
    if (!allowedRoles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        error: `Forbidden: role '${req.user.role}' is not authorized to access this resource.`,
      });
    }
    return next();
  };
}
