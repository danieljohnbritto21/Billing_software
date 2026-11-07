import { Router, Request, Response, NextFunction } from 'express';
import { suppliersService } from './suppliers.service';
import { validateBody } from '../../middleware/validate.middleware';
import {
  createSupplierSchema,
  updateSupplierSchema,
  updateSupplierStatusSchema,
  updateSupplierProfileSchema,
} from './suppliers.schema';
import {
  requireAuth,
  requireAdmin,
  requireSupplier,
  requireActiveUser,
} from '../../middleware/auth.middleware';
import { apiSuccess, apiPaginated } from '../../utils/response';

// Admin Suppliers Router: mounted at /api/v1/admin/suppliers
export const adminSuppliersRouter = Router();

adminSuppliersRouter.use(requireAuth, requireActiveUser, requireAdmin);

adminSuppliersRouter.get('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await suppliersService.listSuppliers(req.user!.businessId, req.query as any);
    return apiPaginated(res, result.items, result.total, result.page, result.limit);
  } catch (err) {
    next(err);
  }
});

adminSuppliersRouter.get('/:id', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await suppliersService.getSupplierById(req.user!.businessId, req.params.id);
    return apiSuccess(res, result);
  } catch (err) {
    next(err);
  }
});

adminSuppliersRouter.post(
  '/',
  validateBody(createSupplierSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await suppliersService.createSupplier(req.user!.businessId, req.body);
      return apiSuccess(res, result, 'Supplier created successfully', 201);
    } catch (err) {
      next(err);
    }
  }
);

adminSuppliersRouter.put(
  '/:id',
  validateBody(updateSupplierSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await suppliersService.updateSupplier(req.user!.businessId, req.params.id, req.body);
      return apiSuccess(res, result, 'Supplier updated successfully');
    } catch (err) {
      next(err);
    }
  }
);

adminSuppliersRouter.patch(
  '/:id/status',
  validateBody(updateSupplierStatusSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await suppliersService.updateSupplierStatus(
        req.user!.businessId,
        req.params.id,
        req.body.isActive
      );
      return apiSuccess(res, result, `Supplier ${req.body.isActive ? 'activated' : 'deactivated'} successfully`);
    } catch (err) {
      next(err);
    }
  }
);

adminSuppliersRouter.get('/:id/products', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await suppliersService.getSupplierProducts(req.user!.businessId, req.params.id, req.query);
    return apiPaginated(res, result.items, result.total, result.page, result.limit);
  } catch (err) {
    next(err);
  }
});

adminSuppliersRouter.get('/:id/purchase-history', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await suppliersService.getSupplierPurchaseHistory(req.user!.businessId, req.params.id, req.query);
    return apiPaginated(res, result.items, result.total, result.page, result.limit);
  } catch (err) {
    next(err);
  }
});

adminSuppliersRouter.get('/:id/payment-history', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await suppliersService.getSupplierPaymentHistory(req.user!.businessId, req.params.id, req.query);
    return apiPaginated(res, result.items, result.total, result.page, result.limit);
  } catch (err) {
    next(err);
  }
});

// Supplier Profile Router: mounted at /api/v1/supplier/profile
export const supplierProfileRouter = Router();

supplierProfileRouter.use(requireAuth, requireActiveUser, requireSupplier);

supplierProfileRouter.get('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await suppliersService.getSupplierProfile(req.user!.businessId, req.user!.supplierId!);
    return apiSuccess(res, result);
  } catch (err) {
    next(err);
  }
});

supplierProfileRouter.put(
  '/',
  validateBody(updateSupplierProfileSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await suppliersService.updateSupplierProfile(
        req.user!.businessId,
        req.user!.supplierId!,
        req.body
      );
      return apiSuccess(res, result, 'Profile updated successfully');
    } catch (err) {
      next(err);
    }
  }
);
