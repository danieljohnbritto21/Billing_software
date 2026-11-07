import { Router, Request, Response, NextFunction } from 'express';
import { authService } from './auth.service';
import { validateBody } from '../../middleware/validate.middleware';
import { registerBusinessSchema, loginSchema, supplierLoginSchema } from './auth.schema';
import { requireAuth } from '../../middleware/auth.middleware';
import { apiSuccess } from '../../utils/response';

export const authRouter = Router();

authRouter.post(
  '/register-business',
  validateBody(registerBusinessSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await authService.registerBusiness(req.body);
      return apiSuccess(res, result, 'Business registered successfully', 201);
    } catch (err) {
      next(err);
    }
  }
);

authRouter.post(
  '/login',
  validateBody(loginSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await authService.login(req.body);
      return apiSuccess(res, result, 'Login successful');
    } catch (err) {
      next(err);
    }
  }
);

authRouter.post(
  '/supplier-login',
  validateBody(supplierLoginSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await authService.supplierLogin(req.body);
      return apiSuccess(res, result, 'Supplier login successful');
    } catch (err) {
      next(err);
    }
  }
);

authRouter.get(
  '/me',
  requireAuth,
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await authService.getMe(req.user!.userId);
      return apiSuccess(res, result, 'Profile retrieved successfully');
    } catch (err) {
      next(err);
    }
  }
);
