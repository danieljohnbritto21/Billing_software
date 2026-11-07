import { Router, Request, Response, NextFunction } from 'express';
import {
  requireAuth,
  requireAdmin,
  requireSupplier,
  requireActiveUser,
} from '../../middleware/auth.middleware';
import { validateBody } from '../../middleware/validate.middleware';
import {
  createCategorySchema,
  updateCategorySchema,
  updateCategoryStatusSchema,
} from './categories.schema';
import { categoriesService } from './categories.service';
import { apiSuccess } from '../../utils/response';

// Legacy / General Categories Router: mounted at /api/v1/categories
export const categoriesRouter = Router();

categoriesRouter.get(
  '/',
  requireAuth,
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const includeInactive = req.query.includeInactive === 'true';
      const categories = await categoriesService.listCategories(
        req.user!.businessId,
        includeInactive
      );
      return apiSuccess(res, categories);
    } catch (err) {
      next(err);
    }
  }
);

categoriesRouter.get(
  '/:id',
  requireAuth,
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const category = await categoriesService.getCategoryById(
        req.user!.businessId,
        req.params.id
      );
      return apiSuccess(res, category);
    } catch (err) {
      next(err);
    }
  }
);

categoriesRouter.post(
  '/',
  requireAuth,
  requireAdmin,
  validateBody(createCategorySchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const created = await categoriesService.createCategory(
        req.user!.businessId,
        req.body
      );
      return apiSuccess(res, created, 'Category created successfully', 201);
    } catch (err) {
      next(err);
    }
  }
);

categoriesRouter.put(
  '/:id',
  requireAuth,
  requireAdmin,
  validateBody(updateCategorySchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const updated = await categoriesService.updateCategory(
        req.user!.businessId,
        req.params.id,
        req.body
      );
      return apiSuccess(res, updated, 'Category updated successfully');
    } catch (err) {
      next(err);
    }
  }
);

categoriesRouter.delete(
  '/:id',
  requireAuth,
  requireAdmin,
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      await categoriesService.softDeleteCategory(
        req.user!.businessId,
        req.params.id
      );
      return apiSuccess(res, null, 'Category deleted successfully');
    } catch (err) {
      next(err);
    }
  }
);

// Admin Categories Router: mounted at /api/v1/admin/categories
export const adminCategoriesRouter = Router();

adminCategoriesRouter.use(requireAuth, requireActiveUser, requireAdmin);

adminCategoriesRouter.get('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const includeInactive = req.query.includeInactive === 'true';
    const categories = await categoriesService.listCategories(req.user!.businessId, includeInactive);
    return apiSuccess(res, categories);
  } catch (err) {
    next(err);
  }
});

adminCategoriesRouter.post(
  '/',
  validateBody(createCategorySchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const created = await categoriesService.createCategory(req.user!.businessId, req.body);
      return apiSuccess(res, created, 'Category created successfully', 201);
    } catch (err) {
      next(err);
    }
  }
);

adminCategoriesRouter.put(
  '/:id',
  validateBody(updateCategorySchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const updated = await categoriesService.updateCategory(req.user!.businessId, req.params.id, req.body);
      return apiSuccess(res, updated, 'Category updated successfully');
    } catch (err) {
      next(err);
    }
  }
);

adminCategoriesRouter.patch(
  '/:id/status',
  validateBody(updateCategoryStatusSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const updated = await categoriesService.updateCategoryStatus(
        req.user!.businessId,
        req.params.id,
        req.body.isActive
      );
      return apiSuccess(res, updated, `Category ${req.body.isActive ? 'activated' : 'deactivated'} successfully`);
    } catch (err) {
      next(err);
    }
  }
);

// Supplier Categories Router: mounted at /api/v1/supplier/categories (read-only)
export const supplierCategoriesRouter = Router();

supplierCategoriesRouter.use(requireAuth, requireActiveUser, requireSupplier);

supplierCategoriesRouter.get('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    // Suppliers can ONLY view active categories belonging to their business
    const categories = await categoriesService.listCategories(req.user!.businessId, false);
    return apiSuccess(res, categories);
  } catch (err) {
    next(err);
  }
});
