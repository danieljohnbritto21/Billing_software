import { Router, Request, Response, NextFunction } from 'express';
import { requireAuth } from '../../middleware/auth.middleware';
import { validateQuery, validateBody } from '../../middleware/validate.middleware';
import { syncPullQuerySchema, syncPushBodySchema } from './sync.schema';
import { syncService } from './sync.service';
import { apiSuccess } from '../../utils/response';

export const syncRouter = Router();

syncRouter.get(
  '/pull',
  requireAuth,
  validateQuery(syncPullQuerySchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await syncService.pullChanges(
        req.user!.businessId,
        req.user!.deviceId,
        req.query as any
      );
      return apiSuccess(res, result);
    } catch (err) {
      next(err);
    }
  }
);

syncRouter.post(
  '/push',
  requireAuth,
  validateBody(syncPushBodySchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await syncService.pushChanges(
        req.user!.businessId,
        req.body
      );
      return apiSuccess(res, result, 'Push changes processed');
    } catch (err) {
      next(err);
    }
  }
);

syncRouter.get(
  '/status',
  requireAuth,
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const status = await syncService.getSyncStatus(req.user!.businessId);
      return apiSuccess(res, status);
    } catch (err) {
      next(err);
    }
  }
);
