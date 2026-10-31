import { Router, Request, Response, NextFunction } from 'express';
import { requireAuth, requireRole } from '../../middleware/auth.middleware';
import { businessesService } from './businesses.service';
import { apiSuccess } from '../../utils/response';

export const businessesRouter = Router();

businessesRouter.get(
  '/profile',
  requireAuth,
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const profile = await businessesService.getProfile(req.user!.businessId);
      return apiSuccess(res, profile);
    } catch (err) {
      next(err);
    }
  }
);

businessesRouter.put(
  '/profile',
  requireAuth,
  requireRole('admin'),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const updated = await businessesService.updateProfile(
        req.user!.businessId,
        req.body
      );
      return apiSuccess(res, updated, 'Business profile updated successfully');
    } catch (err) {
      next(err);
    }
  }
);

businessesRouter.get(
  '/stats',
  requireAuth,
  requireRole('admin'),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const stats = await businessesService.getAdminStats(req.user!.businessId);
      return apiSuccess(res, stats);
    } catch (err) {
      next(err);
    }
  }
);
