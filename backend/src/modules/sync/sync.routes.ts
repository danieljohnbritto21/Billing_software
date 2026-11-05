import { Router, Request, Response, NextFunction } from 'express';
import { requireAuth, requireDeviceAuth } from '../../middleware/auth.middleware';
import { validateQuery, validateBody } from '../../middleware/validate.middleware';
import { syncPullQuerySchema, syncPushBodySchema } from './sync.schema';
import { syncService } from './sync.service';
import { apiSuccess } from '../../utils/response';

export const syncRouter = Router();

syncRouter.get(
  '/pull',
  requireAuth,
  requireDeviceAuth,
  validateQuery(syncPullQuerySchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await syncService.pullChanges(
        req.user!.businessId,
        req.device!.id,
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
  requireDeviceAuth,
  validateBody(syncPushBodySchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await syncService.pushChanges(
        req.user!.businessId,
        req.device!.id,
        req.body
      );

      const items = result.results || [];
      const errorCount = items.filter((r: any) => r.status === 'error').length;
      const successCount = items.filter((r: any) => r.status === 'synced' || r.status === 'conflict').length;

      if (items.length > 0 && errorCount === items.length) {
        // All items failed to commit to database: Return genuine HTTP 422 failure
        return res.status(422).json({
          success: false,
          error: `Push sync failed: all ${errorCount} items failed to commit to database`,
          data: result,
        });
      }

      if (errorCount > 0 && successCount > 0) {
        // Multi-status partial batch success
        return res.status(207).json({
          success: true,
          message: `Push sync partially processed: ${successCount} succeeded, ${errorCount} failed`,
          data: result,
        });
      }

      return apiSuccess(res, result, 'Push changes processed');
    } catch (err) {
      next(err);
    }
  }
);

syncRouter.get(
  '/status',
  requireAuth,
  requireDeviceAuth,
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const status = await syncService.getSyncStatus(req.user!.businessId);
      return apiSuccess(res, status);
    } catch (err) {
      next(err);
    }
  }
);

