import { Router, Request, Response, NextFunction } from 'express';
import { requireAuth, requireRole } from '../../middleware/auth.middleware';
import { validateBody } from '../../middleware/validate.middleware';
import {
  createInvoiceSchema,
  addInvoiceItemSchema,
  cancelInvoiceSchema,
} from './invoices.schema';
import { invoicesService } from './invoices.service';
import { apiSuccess, apiPaginated } from '../../utils/response';

export const invoicesRouter = Router();

invoicesRouter.get(
  '/',
  requireAuth,
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const page = req.query.page ? parseInt(req.query.page as string, 10) : 1;
      const limit = req.query.limit ? parseInt(req.query.limit as string, 10) : 20;
      const orderStatus = req.query.orderStatus as string | undefined;
      const paymentStatus = req.query.paymentStatus as string | undefined;
      const startDate = req.query.startDate as string | undefined;
      const endDate = req.query.endDate as string | undefined;

      const result = await invoicesService.listInvoices(req.user!.businessId, {
        page,
        limit,
        orderStatus,
        paymentStatus,
        startDate,
        endDate,
      });

      return apiPaginated(res, result.items, result.total, result.page, result.limit);
    } catch (err) {
      next(err);
    }
  }
);

invoicesRouter.get(
  '/:id',
  requireAuth,
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const invoice = await invoicesService.getInvoiceById(
        req.user!.businessId,
        req.params.id
      );
      return apiSuccess(res, invoice);
    } catch (err) {
      next(err);
    }
  }
);

invoicesRouter.post(
  '/',
  requireAuth,
  requireRole('cashier'),
  validateBody(createInvoiceSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const invoice = await invoicesService.createInvoice(
        req.user!.businessId,
        req.user!.userId,
        req.user!.username,
        req.body
      );
      return apiSuccess(res, invoice, 'Invoice created successfully', 201);
    } catch (err) {
      next(err);
    }
  }
);

invoicesRouter.post(
  '/:id/items',
  requireAuth,
  requireRole('cashier'),
  validateBody(addInvoiceItemSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const item = await invoicesService.addItemToInvoice(
        req.user!.businessId,
        req.params.id,
        req.body
      );
      return apiSuccess(res, item, 'Item added to invoice successfully', 201);
    } catch (err) {
      next(err);
    }
  }
);

invoicesRouter.delete(
  '/:id/items/:itemId',
  requireAuth,
  requireRole('cashier'),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await invoicesService.removeItemFromInvoice(
        req.user!.businessId,
        req.params.id,
        req.params.itemId
      );
      return apiSuccess(res, result, 'Item removed from invoice successfully');
    } catch (err) {
      next(err);
    }
  }
);

invoicesRouter.post(
  '/:id/finalize',
  requireAuth,
  requireRole('cashier'),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const finalized = await invoicesService.finalizeInvoice(
        req.user!.businessId,
        req.params.id
      );
      return apiSuccess(res, finalized, 'Invoice finalized successfully');
    } catch (err) {
      next(err);
    }
  }
);

invoicesRouter.post(
  '/:id/cancel',
  requireAuth,
  validateBody(cancelInvoiceSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const cancelled = await invoicesService.cancelInvoice(
        req.user!.businessId,
        req.params.id,
        req.body
      );
      return apiSuccess(res, cancelled, 'Invoice cancelled successfully');
    } catch (err) {
      next(err);
    }
  }
);
