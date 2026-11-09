import { Router, Request, Response, NextFunction } from 'express';
import {
  requireAuth,
  requireAdmin,
  requireActiveUser,
} from '../../middleware/auth.middleware';
import { validateBody } from '../../middleware/validate.middleware';
import {
  createOrderSchema,
  updateOrderSchema,
  recordOrderPaymentSchema,
  addOrderItemsSchema,
} from './orders.schema';
import { ordersService } from './orders.service';
import { invoicesService } from '../invoices/invoices.service';
import { apiSuccess, apiPaginated } from '../../utils/response';

// Admin Orders Router: mounted at /api/v1/admin/orders
export const adminOrdersRouter = Router();

adminOrdersRouter.use(requireAuth, requireActiveUser, requireAdmin);

adminOrdersRouter.get('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await ordersService.listOrders(req.user!.businessId, req.query as any);
    return apiPaginated(res, result.items, result.total, result.page, result.limit);
  } catch (err) {
    next(err);
  }
});

adminOrdersRouter.get('/:id', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await ordersService.getOrderById(req.user!.businessId, req.params.id);
    return apiSuccess(res, result);
  } catch (err) {
    next(err);
  }
});

adminOrdersRouter.post(
  '/',
  validateBody(createOrderSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await ordersService.createOrder(
        req.user!.businessId,
        req.user!.userId,
        req.user!.deviceId,
        req.body
      );
      return apiSuccess(res, result, 'Order created successfully', 201);
    } catch (err) {
      next(err);
    }
  }
);

adminOrdersRouter.put(
  '/:id',
  validateBody(updateOrderSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await ordersService.updateOrder(
        req.user!.businessId,
        req.params.id,
        req.body
      );
      return apiSuccess(res, result, 'Order updated successfully');
    } catch (err) {
      next(err);
    }
  }
);

adminOrdersRouter.post(
  '/:id/items',
  validateBody(addOrderItemsSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await ordersService.addOrderItems(
        req.user!.businessId,
        req.params.id,
        req.body
      );
      return apiSuccess(res, result, 'Items added to order and incremental KOT generated', 201);
    } catch (err) {
      next(err);
    }
  }
);

adminOrdersRouter.post('/:id/complete', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await ordersService.completeOrder(req.user!.businessId, req.params.id);
    return apiSuccess(res, result, 'Order completed successfully');
  } catch (err) {
    next(err);
  }
});

adminOrdersRouter.post(
  '/:id/payments',
  validateBody(recordOrderPaymentSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await ordersService.recordOrderPayment(
        req.user!.businessId,
        req.params.id,
        req.body
      );
      const msg = (result as any).message || (result.isDuplicate ? 'Duplicate payment detected' : 'Payment recorded successfully');
      return apiSuccess(
        res,
        result,
        msg,
        result.isDuplicate ? 200 : 201
      );
    } catch (err) {
      next(err);
    }
  }
);

adminOrdersRouter.get('/:id/payments', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await ordersService.getOrderPayments(req.user!.businessId, req.params.id);
    return apiSuccess(res, result);
  } catch (err) {
    next(err);
  }
});

// Admin Invoices Router: mounted at /api/v1/admin/invoices
export const adminInvoicesRouter = Router();

adminInvoicesRouter.use(requireAuth, requireActiveUser, requireAdmin);

adminInvoicesRouter.get('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await invoicesService.listInvoices(req.user!.businessId, {
      page: req.query.page ? Number(req.query.page) : undefined,
      limit: req.query.limit ? Number(req.query.limit) : undefined,
      orderStatus: req.query.orderStatus as string,
      paymentStatus: req.query.paymentStatus as string,
      startDate: req.query.startDate as string,
      endDate: req.query.endDate as string,
    });
    return apiPaginated(res, result.items, result.total, result.page, result.limit);
  } catch (err) {
    next(err);
  }
});

adminInvoicesRouter.get('/:id', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await invoicesService.getInvoiceById(req.user!.businessId, req.params.id);
    return apiSuccess(res, result);
  } catch (err) {
    next(err);
  }
});
