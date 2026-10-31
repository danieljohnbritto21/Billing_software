import { Router, Request, Response, NextFunction } from 'express';
import { requireAuth, requireRole } from '../../middleware/auth.middleware';
import { validateBody } from '../../middleware/validate.middleware';
import { createProductSchema, updateProductSchema, uploadProductImageSchema } from './products.schema';
import { productsService } from './products.service';
import { apiSuccess } from '../../utils/response';

export const productsRouter = Router();

productsRouter.get(
  '/',
  requireAuth,
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const categoryId = req.query.categoryId as string | undefined;
      const search = req.query.search as string | undefined;
      const availableOnly = req.query.availableOnly === 'true';

      const products = await productsService.listProducts(req.user!.businessId, {
        categoryId,
        search,
        availableOnly,
      });
      return apiSuccess(res, products);
    } catch (err) {
      next(err);
    }
  }
);

// Serve product images directly with caching headers
productsRouter.get(
  '/images/:fileName',
  (req: Request, res: Response, next: NextFunction) => {
    try {
      const fullPath = productsService.getImagePath(req.params.fileName);
      res.setHeader('Cache-Control', 'public, max-age=86400');
      return res.sendFile(fullPath);
    } catch (err) {
      next(err);
    }
  }
);

productsRouter.get(
  '/:id',
  requireAuth,
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const product = await productsService.getProductById(
        req.user!.businessId,
        req.params.id
      );
      return apiSuccess(res, product);
    } catch (err) {
      next(err);
    }
  }
);

// Cashier manages products per FoodBill Pro specifications
productsRouter.post(
  '/',
  requireAuth,
  requireRole('cashier'),
  validateBody(createProductSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const created = await productsService.createProduct(
        req.user!.businessId,
        req.body
      );
      return apiSuccess(res, created, 'Product created successfully', 201);
    } catch (err) {
      next(err);
    }
  }
);

productsRouter.put(
  '/:id',
  requireAuth,
  requireRole('cashier'),
  validateBody(updateProductSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const updated = await productsService.updateProduct(
        req.user!.businessId,
        req.params.id,
        req.body
      );
      return apiSuccess(res, updated, 'Product updated successfully');
    } catch (err) {
      next(err);
    }
  }
);

productsRouter.delete(
  '/:id',
  requireAuth,
  requireRole('cashier'),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const deleted = await productsService.softDeleteProduct(
        req.user!.businessId,
        req.params.id
      );
      return apiSuccess(res, deleted, 'Product deleted successfully');
    } catch (err) {
      next(err);
    }
  }
);

productsRouter.get(
  '/:id/images',
  requireAuth,
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const images = await productsService.listProductImages(
        req.user!.businessId,
        req.params.id
      );
      return apiSuccess(res, images);
    } catch (err) {
      next(err);
    }
  }
);

productsRouter.post(
  '/:id/images',
  requireAuth,
  requireRole('cashier'),
  validateBody(uploadProductImageSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const uploaded = await productsService.uploadProductImage(
        req.user!.businessId,
        req.params.id,
        req.body
      );
      return apiSuccess(res, uploaded, 'Product image uploaded successfully', 201);
    } catch (err) {
      next(err);
    }
  }
);

productsRouter.delete(
  '/:id/images/:imageId',
  requireAuth,
  requireRole('cashier'),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const deleted = await productsService.deleteProductImage(
        req.user!.businessId,
        req.params.id,
        req.params.imageId
      );
      return apiSuccess(res, deleted, 'Product image deleted successfully');
    } catch (err) {
      next(err);
    }
  }
);
