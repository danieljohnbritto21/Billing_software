import { Router, Request, Response, NextFunction } from 'express';
import { requireAuth, requireRole } from '../../middleware/auth.middleware';
import { validateBody } from '../../middleware/validate.middleware';
import { createDiningTableSchema, updateDiningTableSchema } from './dining-tables.schema';
import { diningTablesService } from './dining-tables.service';
import { apiSuccess } from '../../utils/response';

export const diningTablesRouter = Router();

diningTablesRouter.get(
  '/',
  requireAuth,
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const tables = await diningTablesService.listTables(req.user!.businessId);
      return apiSuccess(res, tables);
    } catch (err) {
      next(err);
    }
  }
);

diningTablesRouter.get(
  '/:id',
  requireAuth,
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const table = await diningTablesService.getTableById(
        req.user!.businessId,
        req.params.id
      );
      return apiSuccess(res, table);
    } catch (err) {
      next(err);
    }
  }
);

diningTablesRouter.post(
  '/',
  requireAuth,
  requireRole('admin'),
  validateBody(createDiningTableSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const created = await diningTablesService.createTable(
        req.user!.businessId,
        req.body
      );
      return apiSuccess(res, created, 'Dining table created successfully', 201);
    } catch (err) {
      next(err);
    }
  }
);

diningTablesRouter.put(
  '/:id',
  requireAuth,
  validateBody(updateDiningTableSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const updated = await diningTablesService.updateTable(
        req.user!.businessId,
        req.params.id,
        req.body
      );
      return apiSuccess(res, updated, 'Dining table updated successfully');
    } catch (err) {
      next(err);
    }
  }
);

diningTablesRouter.delete(
  '/:id',
  requireAuth,
  requireRole('admin'),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const deleted = await diningTablesService.softDeleteTable(
        req.user!.businessId,
        req.params.id
      );
      return apiSuccess(res, deleted, 'Dining table deleted successfully');
    } catch (err) {
      next(err);
    }
  }
);
