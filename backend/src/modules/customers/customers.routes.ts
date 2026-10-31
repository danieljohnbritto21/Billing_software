import { Router, Request, Response, NextFunction } from 'express';
import { requireAuth } from '../../middleware/auth.middleware';
import { validateBody } from '../../middleware/validate.middleware';
import { createCustomerSchema, updateCustomerSchema } from './customers.schema';
import { customersService } from './customers.service';
import { apiSuccess } from '../../utils/response';

export const customersRouter = Router();

customersRouter.get(
  '/',
  requireAuth,
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const search = req.query.search as string | undefined;
      const customers = await customersService.listCustomers(
        req.user!.businessId,
        search
      );
      return apiSuccess(res, customers);
    } catch (err) {
      next(err);
    }
  }
);

customersRouter.get(
  '/:id',
  requireAuth,
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const customer = await customersService.getCustomerById(
        req.user!.businessId,
        req.params.id
      );
      return apiSuccess(res, customer);
    } catch (err) {
      next(err);
    }
  }
);

customersRouter.post(
  '/',
  requireAuth,
  validateBody(createCustomerSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const created = await customersService.createCustomer(
        req.user!.businessId,
        req.body
      );
      return apiSuccess(res, created, 'Customer created successfully', 201);
    } catch (err) {
      next(err);
    }
  }
);

customersRouter.put(
  '/:id',
  requireAuth,
  validateBody(updateCustomerSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const updated = await customersService.updateCustomer(
        req.user!.businessId,
        req.params.id,
        req.body
      );
      return apiSuccess(res, updated, 'Customer updated successfully');
    } catch (err) {
      next(err);
    }
  }
);

customersRouter.delete(
  '/:id',
  requireAuth,
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const deleted = await customersService.softDeleteCustomer(
        req.user!.businessId,
        req.params.id
      );
      return apiSuccess(res, deleted, 'Customer deleted successfully');
    } catch (err) {
      next(err);
    }
  }
);
