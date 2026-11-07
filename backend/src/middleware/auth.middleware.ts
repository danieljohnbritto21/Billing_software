import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { env } from '../config/env';
import { prisma } from '../config/prisma';

export type AppRole = 'ADMIN' | 'SUPPLIER' | 'CASHIER_LEGACY' | 'admin' | 'cashier';

export interface AuthUser {
  userId: string;
  businessId: string;
  role: AppRole;
  username: string;
  supplierId?: string;
  deviceId?: string;
  sessionId?: string;
}

declare global {
  namespace Express {
    interface Request {
      user?: AuthUser;
      device?: any;
    }
  }
}

/**
 * Normalizes role string to canonical uppercase ('ADMIN' | 'SUPPLIER' | 'CASHIER_LEGACY')
 */
export function normalizeRole(role: string): 'ADMIN' | 'SUPPLIER' | 'CASHIER_LEGACY' | string {
  const upper = role.toUpperCase();
  if (upper === 'ADMIN' || upper === 'SUPPLIER' || upper === 'CASHIER_LEGACY') {
    return upper;
  }
  if (role.toLowerCase() === 'admin') return 'ADMIN';
  if (role.toLowerCase() === 'cashier') return 'CASHIER_LEGACY';
  return upper;
}

/**
 * Authenticates bearer JWT token
 */
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
    const normalizedRole = normalizeRole(payload.role);
    if (normalizedRole === 'CASHIER_LEGACY') {
      return res.status(403).json({
        success: false,
        error: 'Forbidden: Cashier accounts are deprecated and permanently deactivated. Only Admin and Supplier accounts are active.',
      });
    }
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

export const authenticateToken = requireAuth;

/**
 * Requires one of the specified roles
 */
export function requireRole(...allowedRoles: Array<AppRole>) {
  const canonicalAllowed = allowedRoles.map((r) => normalizeRole(r));
  return (req: Request, res: Response, next: NextFunction) => {
    if (!req.user) {
      return res.status(401).json({ success: false, error: 'Unauthorized: Authentication required.' });
    }
    const userRole = normalizeRole(req.user.role);
    if (!canonicalAllowed.includes(userRole)) {
      return res.status(403).json({
        success: false,
        error: `Forbidden: role '${req.user.role}' is not authorized to access this resource.`,
      });
    }
    return next();
  };
}

/**
 * Requires ADMIN role
 */
export function requireAdmin(req: Request, res: Response, next: NextFunction) {
  if (!req.user) {
    return res.status(401).json({ success: false, error: 'Unauthorized: Authentication required.' });
  }
  const userRole = normalizeRole(req.user.role);
  if (userRole !== 'ADMIN') {
    return res.status(403).json({
      success: false,
      error: 'Forbidden: Admin privilege required.',
    });
  }
  return next();
}

/**
 * Requires SUPPLIER role
 */
export function requireSupplier(req: Request, res: Response, next: NextFunction) {
  if (!req.user) {
    return res.status(401).json({ success: false, error: 'Unauthorized: Authentication required.' });
  }
  const userRole = normalizeRole(req.user.role);
  if (userRole !== 'SUPPLIER') {
    return res.status(403).json({
      success: false,
      error: 'Forbidden: Supplier privilege required.',
    });
  }
  if (!req.user.supplierId) {
    return res.status(403).json({
      success: false,
      error: 'Forbidden: Supplier account has no assigned supplier profile.',
    });
  }
  return next();
}

/**
 * Verifies that the authenticated user account is active in the database
 */
export async function requireActiveUser(req: Request, res: Response, next: NextFunction) {
  if (!req.user) {
    return res.status(401).json({ success: false, error: 'Unauthorized: Authentication required.' });
  }
  try {
    const user = await prisma.users.findUnique({
      where: { id: req.user.userId },
      select: { id: true, is_active: true, deleted_at: true, role_id: true, business_id: true },
    });
    if (!user || !user.is_active || user.deleted_at !== null) {
      return res.status(401).json({
        success: false,
        error: 'Unauthorized: User account is inactive or has been disabled.',
      });
    }
    if (user.role_id === 'CASHIER_LEGACY') {
      return res.status(403).json({
        success: false,
        error: 'Forbidden: Cashier role is deprecated. Only Admin and Supplier accounts are active.',
      });
    }
    return next();
  } catch (err) {
    return next(err);
  }
}

/**
 * Ensures authenticated user belongs to the requested business
 */
export function requireBusinessAccess(paramName = 'businessId') {
  return (req: Request, res: Response, next: NextFunction) => {
    if (!req.user) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }
    const targetBusinessId = req.params[paramName] || req.body?.[paramName] || req.query?.[paramName];
    if (targetBusinessId && targetBusinessId !== req.user.businessId) {
      return res.status(403).json({
        success: false,
        error: 'Forbidden: You do not have access to this business.',
      });
    }
    return next();
  };
}

/**
 * Ensures a supplier can only access records owned by their authenticated supplierId.
 * Admin users are granted access to all suppliers within their business.
 */
export function requireSupplierOwnership(paramName = 'supplierId') {
  return (req: Request, res: Response, next: NextFunction) => {
    if (!req.user) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }
    const userRole = normalizeRole(req.user.role);
    if (userRole === 'ADMIN') {
      return next(); // Admins can manage all suppliers within their business
    }
    if (userRole === 'SUPPLIER') {
      const targetSupplierId = req.params[paramName] || req.body?.[paramName];
      if (targetSupplierId && targetSupplierId !== req.user.supplierId) {
        return res.status(403).json({
          success: false,
          error: 'Forbidden: Cross-supplier access is strictly prohibited.',
        });
      }
      return next();
    }
    return res.status(403).json({
      success: false,
      error: 'Forbidden: Insufficient privileges.',
    });
  };
}

/**
 * Enforces strict device authorization and revocation checks on sensitive sync endpoints.
 */
export async function requireDeviceAuth(req: Request, res: Response, next: NextFunction) {
  if (!req.user) {
    return res.status(401).json({
      success: false,
      error: 'Authentication required. No authenticated user.',
    });
  }

  const tokenDeviceId = req.user.deviceId;
  if (!tokenDeviceId) {
    return res.status(403).json({
      success: false,
      error: 'Forbidden: No registered device associated with this token. Please authenticate with an authorized device.',
    });
  }

  try {
    const device = await prisma.devices.findUnique({
      where: { id: tokenDeviceId },
    });

    if (!device) {
      return res.status(403).json({
        success: false,
        error: 'Forbidden: Device does not exist or has been removed.',
      });
    }

    if (device.business_id !== req.user.businessId) {
      return res.status(403).json({
        success: false,
        error: 'Forbidden: Device does not belong to the authenticated business.',
      });
    }

    if (!device.is_authorized) {
      return res.status(403).json({
        success: false,
        error: 'Forbidden: Device authorization revoked or pending approval.',
      });
    }

    const bodyDeviceId = req.body?.deviceId;
    const headerDeviceId = req.headers['x-device-id'] as string | undefined;

    if (bodyDeviceId && bodyDeviceId !== device.id && bodyDeviceId !== device.device_uid) {
      return res.status(403).json({
        success: false,
        error: 'Forbidden: Device ID in request body does not match authenticated device token.',
      });
    }

    if (headerDeviceId && headerDeviceId !== device.id && headerDeviceId !== device.device_uid) {
      return res.status(403).json({
        success: false,
        error: 'Forbidden: Device ID in request header does not match authenticated device token.',
      });
    }

    if (req.user.sessionId) {
      const session = await prisma.user_sessions.findUnique({
        where: { id: req.user.sessionId },
      });
      if (!session || session.is_revoked || session.device_id !== device.id) {
        return res.status(403).json({
          success: false,
          error: 'Forbidden: Session is revoked or invalid for this device.',
        });
      }
    }

    req.device = device;
    return next();
  } catch (err: any) {
    return next(err);
  }
}

export const requireDeviceAuthorization = requireDeviceAuth;
