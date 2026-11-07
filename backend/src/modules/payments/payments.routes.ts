import { Router, Request, Response, NextFunction } from 'express';
import { requireAuth, requireRole } from '../../middleware/auth.middleware';
import { validateBody } from '../../middleware/validate.middleware';
import { recordPaymentSchema } from './payments.schema';
import { paymentsService } from './payments.service';
import { apiSuccess } from '../../utils/response';

export const paymentsRouter = Router();

paymentsRouter.get(
  '/',
  requireAuth,
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const invoiceId = req.query.invoiceId as string | undefined;
      const payments = await paymentsService.listPayments(
        req.user!.businessId,
        invoiceId
      );
      return apiSuccess(res, payments);
    } catch (err) {
      next(err);
    }
  }
);

paymentsRouter.post(
  '/',
  requireAuth,
  requireRole('ADMIN'),
  validateBody(recordPaymentSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const payment = await paymentsService.recordPayment(
        req.user!.businessId,
        req.body
      );
      return apiSuccess(res, payment, 'Payment recorded successfully', 201);
    } catch (err) {
      next(err);
    }
  }
);
