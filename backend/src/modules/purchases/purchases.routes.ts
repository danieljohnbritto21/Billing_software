import { Router, Request, Response, NextFunction } from 'express';
import {
  requireAuth,
  requireAdmin,
  requireSupplier,
  requireActiveUser,
} from '../../middleware/auth.middleware';
import { validateBody } from '../../middleware/validate.middleware';
import {
  createPurchaseOrderSchema,
  updatePurchaseOrderSchema,
  updatePurchaseOrderStatusSchema,
  receivePurchaseOrderSchema,
  createPurchaseInvoiceSchema,
  approveRejectPurchaseInvoiceSchema,
  recordSupplierPaymentSchema,
} from './purchases.schema';
import { purchasesService } from './purchases.service';
import { apiSuccess, apiPaginated } from '../../utils/response';

// ==========================================
// 1. ADMIN PURCHASE ORDERS ROUTER
// Mounted at: /api/v1/admin/purchase-orders
// ==========================================
export const adminPurchaseOrdersRouter = Router();

adminPurchaseOrdersRouter.use(requireAuth, requireActiveUser, requireAdmin);

adminPurchaseOrdersRouter.get('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await purchasesService.listPurchaseOrders(req.user!.businessId, {
      supplierId: req.query.supplierId as string,
      orderStatus: req.query.orderStatus as string,
      page: req.query.page ? Number(req.query.page) : undefined,
      limit: req.query.limit ? Number(req.query.limit) : undefined,
    });
    return apiPaginated(res, result.items, result.total, result.page, result.limit);
  } catch (err) {
    next(err);
  }
});

adminPurchaseOrdersRouter.get('/:id', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await purchasesService.getPurchaseOrderById(req.user!.businessId, req.params.id);
    return apiSuccess(res, result);
  } catch (err) {
    next(err);
  }
});

adminPurchaseOrdersRouter.post(
  '/',
  validateBody(createPurchaseOrderSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await purchasesService.createPurchaseOrder(
        req.user!.businessId,
        req.user!.userId,
        req.body
      );
      return apiSuccess(res, result, 'Purchase order created successfully', 201);
    } catch (err) {
      next(err);
    }
  }
);

adminPurchaseOrdersRouter.put(
  '/:id',
  validateBody(updatePurchaseOrderSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await purchasesService.updatePurchaseOrder(
        req.user!.businessId,
        req.params.id,
        req.body
      );
      return apiSuccess(res, result, 'Purchase order updated successfully');
    } catch (err) {
      next(err);
    }
  }
);

adminPurchaseOrdersRouter.patch(
  '/:id/status',
  validateBody(updatePurchaseOrderStatusSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await purchasesService.updatePurchaseOrderStatus(
        req.user!.businessId,
        req.params.id,
        req.body.orderStatus
      );
      return apiSuccess(res, result, `Purchase order status updated to ${req.body.orderStatus}`);
    } catch (err) {
      next(err);
    }
  }
);

adminPurchaseOrdersRouter.post(
  '/:id/receive',
  validateBody(receivePurchaseOrderSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await purchasesService.receivePurchaseOrder(
        req.user!.businessId,
        req.params.id,
        req.body
      );
      return apiSuccess(res, result, 'Purchase order receiving recorded successfully');
    } catch (err) {
      next(err);
    }
  }
);

adminPurchaseOrdersRouter.get('/:id/items', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await purchasesService.getPurchaseOrderItems(req.user!.businessId, req.params.id);
    return apiSuccess(res, result);
  } catch (err) {
    next(err);
  }
});

// ==========================================
// 2. ADMIN PURCHASE INVOICES ROUTER
// Mounted at: /api/v1/admin/purchase-invoices
// ==========================================
export const adminPurchaseInvoicesRouter = Router();

adminPurchaseInvoicesRouter.use(requireAuth, requireActiveUser, requireAdmin);

adminPurchaseInvoicesRouter.get('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await purchasesService.listPurchaseInvoices(req.user!.businessId, {
      supplierId: req.query.supplierId as string,
      invoiceStatus: req.query.invoiceStatus as string,
      paymentStatus: req.query.paymentStatus as string,
      page: req.query.page ? Number(req.query.page) : undefined,
      limit: req.query.limit ? Number(req.query.limit) : undefined,
    });
    return apiPaginated(res, result.items, result.total, result.page, result.limit);
  } catch (err) {
    next(err);
  }
});

adminPurchaseInvoicesRouter.get('/:id', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await purchasesService.getPurchaseInvoiceById(req.user!.businessId, req.params.id);
    return apiSuccess(res, result);
  } catch (err) {
    next(err);
  }
});

adminPurchaseInvoicesRouter.post(
  '/',
  validateBody(createPurchaseInvoiceSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await purchasesService.createPurchaseInvoice(req.user!.businessId, req.body);
      const statusCode = result.isDuplicate ? 200 : 201;
      const msg = result.isDuplicate
        ? 'Purchase invoice already exists. Existing invoice returned.'
        : 'Purchase invoice created successfully';
      return apiSuccess(res, result, msg, statusCode);
    } catch (err) {
      next(err);
    }
  }
);

adminPurchaseInvoicesRouter.post('/:id/approve', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await purchasesService.approvePurchaseInvoice(req.user!.businessId, req.params.id);
    return apiSuccess(res, result, 'Purchase invoice approved successfully');
  } catch (err) {
    next(err);
  }
});

adminPurchaseInvoicesRouter.post(
  '/:id/reject',
  validateBody(approveRejectPurchaseInvoiceSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await purchasesService.rejectPurchaseInvoice(
        req.user!.businessId,
        req.params.id,
        req.body.notes
      );
      return apiSuccess(res, result, 'Purchase invoice rejected successfully');
    } catch (err) {
      next(err);
    }
  }
);

adminPurchaseInvoicesRouter.post(
  '/:id/payments',
  validateBody(recordSupplierPaymentSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await purchasesService.recordSupplierPayment(
        req.user!.businessId,
        req.user!.userId,
        {
          ...req.body,
          purchaseInvoiceId: req.params.id,
        }
      );
      return apiSuccess(res, result, 'Supplier payment recorded successfully', 201);
    } catch (err) {
      next(err);
    }
  }
);

// ==========================================
// 3. ADMIN SUPPLIER PAYMENTS ROUTER
// Mounted at: /api/v1/admin/supplier-payments
// ==========================================
export const adminSupplierPaymentsRouter = Router();

adminSupplierPaymentsRouter.use(requireAuth, requireActiveUser, requireAdmin);

adminSupplierPaymentsRouter.get('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await purchasesService.listSupplierPayments(req.user!.businessId, {
      supplierId: req.query.supplierId as string,
      page: req.query.page ? Number(req.query.page) : undefined,
      limit: req.query.limit ? Number(req.query.limit) : undefined,
    });
    return apiPaginated(res, result.items, result.total, result.page, result.limit);
  } catch (err) {
    next(err);
  }
});

adminSupplierPaymentsRouter.post(
  '/',
  validateBody(recordSupplierPaymentSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await purchasesService.recordSupplierPayment(
        req.user!.businessId,
        req.user!.userId,
        req.body
      );
      return apiSuccess(res, result, 'Supplier payment recorded successfully', 201);
    } catch (err) {
      next(err);
    }
  }
);

// ==========================================
// 4. SUPPLIER PURCHASES & INVOICES ROUTER
// Mounted at: /api/v1/supplier
// ==========================================
export const supplierPurchasesRouter = Router();

supplierPurchasesRouter.use(requireAuth, requireActiveUser, requireSupplier);

// Supplier Orders (Purchase Orders assigned to this supplier)
supplierPurchasesRouter.get('/orders', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await purchasesService.listPurchaseOrders(req.user!.businessId, {
      supplierId: req.user!.supplierId!,
      orderStatus: req.query.orderStatus as string,
      page: req.query.page ? Number(req.query.page) : undefined,
      limit: req.query.limit ? Number(req.query.limit) : undefined,
    });
    return apiPaginated(res, result.items, result.total, result.page, result.limit);
  } catch (err) {
    next(err);
  }
});

supplierPurchasesRouter.get('/orders/:id', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await purchasesService.getPurchaseOrderById(
      req.user!.businessId,
      req.params.id,
      req.user!.supplierId!
    );
    return apiSuccess(res, result);
  } catch (err) {
    next(err);
  }
});

// Supplier Invoices
supplierPurchasesRouter.get('/invoices', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await purchasesService.listPurchaseInvoices(req.user!.businessId, {
      supplierId: req.user!.supplierId!,
      invoiceStatus: req.query.invoiceStatus as string,
      paymentStatus: req.query.paymentStatus as string,
      page: req.query.page ? Number(req.query.page) : undefined,
      limit: req.query.limit ? Number(req.query.limit) : undefined,
    });
    return apiPaginated(res, result.items, result.total, result.page, result.limit);
  } catch (err) {
    next(err);
  }
});

supplierPurchasesRouter.get('/invoices/:id', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await purchasesService.getPurchaseInvoiceById(
      req.user!.businessId,
      req.params.id,
      req.user!.supplierId!
    );
    return apiSuccess(res, result);
  } catch (err) {
    next(err);
  }
});

supplierPurchasesRouter.post(
  '/invoices',
  validateBody(createPurchaseInvoiceSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await purchasesService.createPurchaseInvoice(
        req.user!.businessId,
        req.body,
        req.user!.supplierId!
      );
      const statusCode = result.isDuplicate ? 200 : 201;
      const msg = result.isDuplicate
        ? 'Invoice already submitted. Existing invoice returned.'
        : 'Invoice submitted successfully. Awaiting verification.';
      return apiSuccess(res, result, msg, statusCode);
    } catch (err) {
      next(err);
    }
  }
);

supplierPurchasesRouter.post('/invoices/:id/submit', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await purchasesService.submitPurchaseInvoice(
      req.user!.businessId,
      req.params.id,
      req.user!.supplierId!
    );
    return apiSuccess(res, result, 'Invoice submitted for verification');
  } catch (err) {
    next(err);
  }
});

// Supplier Payment History
supplierPurchasesRouter.get('/payment-history', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await purchasesService.listSupplierPayments(req.user!.businessId, {
      supplierId: req.user!.supplierId!,
      page: req.query.page ? Number(req.query.page) : undefined,
      limit: req.query.limit ? Number(req.query.limit) : undefined,
    });
    return apiPaginated(res, result.items, result.total, result.page, result.limit);
  } catch (err) {
    next(err);
  }
});

// Supplier Outstanding Balance Summary
supplierPurchasesRouter.get('/outstanding-balance', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await purchasesService.getSupplierOutstandingBalance(
      req.user!.businessId,
      req.user!.supplierId!
    );
    return apiSuccess(res, result);
  } catch (err) {
    next(err);
  }
});
