import { Router, Request, Response, NextFunction } from 'express';
import { requireAuth, requireRole } from '../../middleware/auth.middleware';
import { validateBody } from '../../middleware/validate.middleware';
import { createCategorySchema, updateCategorySchema } from './categories.schema';
import { categoriesService } from './categories.service';
import { apiSuccess } from '../../utils/response';

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
  requireRole('admin'),
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
  requireRole('admin'),
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
  requireRole('admin'),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const deleted = await categoriesService.softDeleteCategory(
        req.user!.businessId,
        req.params.id
      );
      return apiSuccess(res, deleted, 'Category deleted successfully');
    } catch (err) {
      next(err);
    }
  }
);
