import { Router, Request, Response, NextFunction } from 'express';
import { requireAuth, requireRole } from '../../middleware/auth.middleware';
import { validateBody } from '../../middleware/validate.middleware';
import { createStaffUserSchema, updateUserStatusSchema } from './users.schema';
import { usersService } from './users.service';
import { apiSuccess } from '../../utils/response';

export const usersRouter = Router();

usersRouter.get(
  '/',
  requireAuth,
  requireRole('admin'),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const users = await usersService.listUsers(req.user!.businessId);
      return apiSuccess(res, users);
    } catch (err) {
      next(err);
    }
  }
);

usersRouter.post(
  '/',
  requireAuth,
  requireRole('admin'),
  validateBody(createStaffUserSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const user = await usersService.createStaffUser(
        req.user!.businessId,
        req.body
      );
      return apiSuccess(res, user, 'Staff user created successfully', 201);
    } catch (err) {
      next(err);
    }
  }
);

usersRouter.put(
  '/:id/status',
  requireAuth,
  requireRole('admin'),
  validateBody(updateUserStatusSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const updated = await usersService.setUserStatus(
        req.user!.businessId,
        req.params.id,
        req.body
      );
      return apiSuccess(res, updated, 'User status updated successfully');
    } catch (err) {
      next(err);
    }
  }
);
