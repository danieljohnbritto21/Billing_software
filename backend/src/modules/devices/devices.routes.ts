import { Router, Request, Response, NextFunction } from 'express';
import { requireAuth, requireRole } from '../../middleware/auth.middleware';
import { validateBody } from '../../middleware/validate.middleware';
import { registerDeviceSchema, updateDeviceAuthSchema } from './devices.schema';
import { devicesService } from './devices.service';
import { apiSuccess } from '../../utils/response';

export const devicesRouter = Router();

devicesRouter.get(
  '/',
  requireAuth,
  requireRole('admin'),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const devices = await devicesService.listDevices(req.user!.businessId);
      return apiSuccess(res, devices);
    } catch (err) {
      next(err);
    }
  }
);

devicesRouter.post(
  '/register',
  requireAuth,
  validateBody(registerDeviceSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const device = await devicesService.registerDevice(
        req.user!.businessId,
        req.body
      );
      return apiSuccess(res, device, 'Device registered successfully', 201);
    } catch (err) {
      next(err);
    }
  }
);

devicesRouter.put(
  '/:id/authorization',
  requireAuth,
  requireRole('admin'),
  validateBody(updateDeviceAuthSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const updated = await devicesService.setDeviceAuthorization(
        req.user!.businessId,
        req.params.id,
        req.body
      );
      return apiSuccess(
        res,
        updated,
        `Device authorization set to ${req.body.isAuthorized}`
      );
    } catch (err) {
      next(err);
    }
  }
);
