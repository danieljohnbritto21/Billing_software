import { Router, Request, Response, NextFunction } from 'express';
import { requireAuth, requireRole } from '../../middleware/auth.middleware';
import { apiSuccess } from '../../utils/response';
import { transactionsService } from './transactions.service';

export const adminTransactionsRouter = Router();
export const supplierTransactionsRouter = Router();

// ==========================================
// ADMIN TRANSACTIONS (Unified Sales & Procurement)
// ==========================================

adminTransactionsRouter.use(requireAuth, requireRole('ADMIN'));

adminTransactionsRouter.get('/sales/:id', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const businessId = req.user!.businessId;
    const result = await transactionsService.getSalesTransaction(businessId, req.params.id);
    return apiSuccess(res, result);
  } catch (err) {
    next(err);
  }
});

adminTransactionsRouter.get('/procurement/:id', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const businessId = req.user!.businessId;
    const result = await transactionsService.getProcurementTransaction(businessId, req.params.id);
    return apiSuccess(res, result);
  } catch (err) {
    next(err);
  }
});

// ==========================================
// SUPPLIER TRANSACTIONS (Role-Isolated Procurement Only)
// ==========================================

supplierTransactionsRouter.use(requireAuth, requireRole('SUPPLIER'));

supplierTransactionsRouter.get('/:id', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const businessId = req.user!.businessId;
    const supplierId = req.user!.supplierId;
    // Strictly enforced: Suppliers can ONLY view their own procurement transaction
    const result = await transactionsService.getProcurementTransaction(businessId, req.params.id, supplierId);
    return apiSuccess(res, result);
  } catch (err) {
    next(err);
  }
});
