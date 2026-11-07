import { Router, Request, Response, NextFunction } from 'express';
import { requireAuth, requireRole } from '../../middleware/auth.middleware';
import { validateBody } from '../../middleware/validate.middleware';
import { createKotSchema } from './kot.schema';
import { kotService } from './kot.service';
import { apiSuccess } from '../../utils/response';

export const kotRouter = Router();

kotRouter.get(
  '/',
  requireAuth,
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const invoiceId = req.query.invoiceId as string | undefined;
      const kots = await kotService.listKot(req.user!.businessId, invoiceId);
      return apiSuccess(res, kots);
    } catch (err) {
      next(err);
    }
  }
);

kotRouter.get(
  '/:id',
  requireAuth,
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const kot = await kotService.getKotById(req.user!.businessId, req.params.id);
      return apiSuccess(res, kot);
    } catch (err) {
      next(err);
    }
  }
);

kotRouter.post(
  '/',
  requireAuth,
  requireRole('ADMIN'),
  validateBody(createKotSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const kot = await kotService.createKot(req.user!.businessId, req.body);
      return apiSuccess(res, kot, 'KOT generated successfully', 201);
    } catch (err) {
      next(err);
    }
  }
);

kotRouter.post(
  '/:id/reprint',
  requireAuth,
  requireRole('ADMIN'),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const updated = await kotService.reprintKot(
        req.user!.businessId,
        req.params.id
      );
      return apiSuccess(res, updated, 'KOT reprinted successfully');
    } catch (err) {
      next(err);
    }
  }
);
