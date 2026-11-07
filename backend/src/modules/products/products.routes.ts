import { Router, Request, Response, NextFunction } from 'express';
import {
  requireAuth,
  requireAdmin,
  requireSupplier,
  requireActiveUser,
} from '../../middleware/auth.middleware';
import { validateBody } from '../../middleware/validate.middleware';
import {
  createProductSchema,
  updateProductSchema,
  updateProductStatusSchema,
  uploadProductImageSchema,
} from './products.schema';
import { productsService } from './products.service';
import { apiSuccess, apiPaginated } from '../../utils/response';

// Legacy / General Products Router: mounted at /api/v1/products
export const productsRouter = Router();

productsRouter.get(
  '/',
  requireAuth,
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const categoryId = req.query.categoryId as string | undefined;
      const supplierId = req.query.supplierId as string | undefined;
      const search = req.query.search as string | undefined;
      const availableOnly = req.query.availableOnly === 'true';

      const result = await productsService.listProducts(req.user!.businessId, {
        categoryId,
        supplierId,
        search,
        availableOnly,
      });
      return apiSuccess(res, result.items);
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

productsRouter.post(
  '/',
  requireAuth,
  requireAdmin,
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
  requireAdmin,
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
  requireAdmin,
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      await productsService.softDeleteProduct(
        req.user!.businessId,
        req.params.id
      );
      return apiSuccess(res, null, 'Product deleted successfully');
    } catch (err) {
      next(err);
    }
  }
);

// Admin Products Router: mounted at /api/v1/admin/products
export const adminProductsRouter = Router();

adminProductsRouter.use(requireAuth, requireActiveUser, requireAdmin);

adminProductsRouter.get('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const categoryId = req.query.categoryId as string | undefined;
    const supplierId = req.query.supplierId as string | undefined;
    const search = req.query.search as string | undefined;
    const availableOnly = req.query.availableOnly === 'true';

    const result = await productsService.listProducts(req.user!.businessId, {
      categoryId,
      supplierId,
      search,
      availableOnly,
      page: req.query.page ? Number(req.query.page) : undefined,
      limit: req.query.limit ? Number(req.query.limit) : undefined,
    });
    return apiPaginated(res, result.items, result.total, result.page, result.limit);
  } catch (err) {
    next(err);
  }
});

adminProductsRouter.get('/:id', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const product = await productsService.getProductById(req.user!.businessId, req.params.id);
    return apiSuccess(res, product);
  } catch (err) {
    next(err);
  }
});

adminProductsRouter.post(
  '/',
  validateBody(createProductSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const created = await productsService.createProduct(req.user!.businessId, req.body);
      return apiSuccess(res, created, 'Product created successfully', 201);
    } catch (err) {
      next(err);
    }
  }
);

adminProductsRouter.put(
  '/:id',
  validateBody(updateProductSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const updated = await productsService.updateProduct(req.user!.businessId, req.params.id, req.body);
      return apiSuccess(res, updated, 'Product updated successfully');
    } catch (err) {
      next(err);
    }
  }
);

adminProductsRouter.patch(
  '/:id/status',
  validateBody(updateProductStatusSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const updated = await productsService.updateProductStatus(
        req.user!.businessId,
        req.params.id,
        req.body.isAvailable
      );
      return apiSuccess(res, updated, `Product ${req.body.isAvailable ? 'available' : 'unavailable'} updated successfully`);
    } catch (err) {
      next(err);
    }
  }
);

adminProductsRouter.delete('/:id', async (req: Request, res: Response, next: NextFunction) => {
  try {
    await productsService.softDeleteProduct(req.user!.businessId, req.params.id);
    return apiSuccess(res, null, 'Product deleted successfully');
  } catch (err) {
    next(err);
  }
});

// Supplier Products Router: mounted at /api/v1/supplier/products
export const supplierProductsRouter = Router();

supplierProductsRouter.use(requireAuth, requireActiveUser, requireSupplier);

supplierProductsRouter.get('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    // ENFORCE: supplier can ONLY list products belonging to their authenticated supplierId
    const result = await productsService.listProducts(req.user!.businessId, {
      supplierId: req.user!.supplierId!,
      categoryId: req.query.categoryId as string | undefined,
      search: req.query.search as string | undefined,
      availableOnly: req.query.availableOnly === 'true',
      page: req.query.page ? Number(req.query.page) : undefined,
      limit: req.query.limit ? Number(req.query.limit) : undefined,
    });
    return apiPaginated(res, result.items, result.total, result.page, result.limit);
  } catch (err) {
    next(err);
  }
});

supplierProductsRouter.get('/:id', async (req: Request, res: Response, next: NextFunction) => {
  try {
    // ENFORCE: supplier can ONLY retrieve product if it belongs to their authenticated supplierId
    const product = await productsService.getProductById(
      req.user!.businessId,
      req.params.id,
      req.user!.supplierId!
    );
    return apiSuccess(res, product);
  } catch (err) {
    next(err);
  }
});

supplierProductsRouter.post(
  '/',
  validateBody(createProductSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      // ENFORCE: automatically assign authenticated supplier_id; ignore any client-supplied supplierId
      const created = await productsService.createProduct(
        req.user!.businessId,
        req.body,
        req.user!.supplierId!
      );
      return apiSuccess(res, created, 'Product created successfully', 201);
    } catch (err) {
      next(err);
    }
  }
);

supplierProductsRouter.put(
  '/:id',
  validateBody(updateProductSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      // ENFORCE: supplier can ONLY modify their own products
      const updated = await productsService.updateProduct(
        req.user!.businessId,
        req.params.id,
        req.body,
        req.user!.supplierId!
      );
      return apiSuccess(res, updated, 'Product updated successfully');
    } catch (err) {
      next(err);
    }
  }
);

supplierProductsRouter.patch(
  '/:id/status',
  validateBody(updateProductStatusSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const updated = await productsService.updateProductStatus(
        req.user!.businessId,
        req.params.id,
        req.body.isAvailable,
        req.user!.supplierId!
      );
      return apiSuccess(res, updated, `Product ${req.body.isAvailable ? 'available' : 'unavailable'} updated successfully`);
    } catch (err) {
      next(err);
    }
  }
);

supplierProductsRouter.delete('/:id', async (req: Request, res: Response, next: NextFunction) => {
  try {
    await productsService.softDeleteProduct(
      req.user!.businessId,
      req.params.id,
      req.user!.supplierId!
    );
    return apiSuccess(res, null, 'Product deleted successfully');
  } catch (err) {
    next(err);
  }
});
