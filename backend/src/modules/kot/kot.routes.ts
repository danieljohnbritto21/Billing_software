import { Router, Request, Response, NextFunction } from 'express';
import { requireAuth, requireActiveUser } from '../../middleware/auth.middleware';
import { validateBody } from '../../middleware/validate.middleware';
import { createKotSchema } from './kot.schema';
import { kotService } from './kot.service';
import { apiSuccess } from '../../utils/response';

export const kotRouter = Router();

kotRouter.use(requireAuth, requireActiveUser);

kotRouter.get(
  '/',
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const invoiceId = req.query.invoiceId as string | undefined;
      const orderId = req.query.orderId as string | undefined;
      const purchaseInvoiceId = req.query.purchaseInvoiceId as string | undefined;
      const kots = await kotService.listKot(req.user!.businessId, {
        invoiceId,
        orderId,
        purchaseInvoiceId,
      });
      return apiSuccess(res, kots);
    } catch (err) {
      next(err);
    }
  }
);

kotRouter.get(
  '/purchase-invoice/:purchaseInvoiceId',
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const kots = await kotService.getKotsByPurchaseInvoiceId(
        req.user!.businessId,
        req.params.purchaseInvoiceId
      );
      return apiSuccess(res, kots);
    } catch (err) {
      next(err);
    }
  }
);

kotRouter.get(
  '/:id',
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
