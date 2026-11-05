import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { env } from '../config/env';
import { prisma } from '../config/prisma';

export interface AuthUser {
  userId: string;
  businessId: string;
  role: 'admin' | 'cashier';
  username: string;
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

/**
 * Enforces strict device authorization and revocation checks on sensitive sync endpoints.
 * Never trusts a device ID supplied solely in the request body or headers.
 * Verifies JWT device binding, database existence, business ownership, and active authorization status.
 */
export async function requireDeviceAuth(req: Request, res: Response, next: NextFunction) {
  if (!req.user) {
    return res.status(401).json({
      success: false,
      error: 'Authentication required. No authenticated user.',
    });
  }

  // 1. Authenticated device ID must be present in the cryptographic JWT token
  const tokenDeviceId = req.user.deviceId;
  if (!tokenDeviceId) {
    return res.status(403).json({
      success: false,
      error: 'Forbidden: No registered device associated with this token. Please authenticate with an authorized device.',
    });
  }

  try {
    // 2. Fetch authoritative device record from database
    const device = await prisma.devices.findUnique({
      where: { id: tokenDeviceId },
    });

    if (!device) {
      return res.status(403).json({
        success: false,
        error: 'Forbidden: Device does not exist or has been removed.',
      });
    }

    // 3. Verify device belongs to the authenticated business
    if (device.business_id !== req.user.businessId) {
      return res.status(403).json({
        success: false,
        error: 'Forbidden: Device does not belong to the authenticated business.',
      });
    }

    // 4. Verify device authorization status (reject unauthorized or revoked devices)
    if (!device.is_authorized) {
      return res.status(403).json({
        success: false,
        error: 'Forbidden: Device authorization revoked or pending approval.',
      });
    }

    // 5. Anti-spoofing: If client supplies deviceId in body or header, it MUST match the authenticated token device
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

    // 6. If session ID is present in JWT, verify that the session has not been revoked
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

    // Attach verified device to request context
    req.device = device;
    return next();
  } catch (err: any) {
    return next(err);
  }
}

