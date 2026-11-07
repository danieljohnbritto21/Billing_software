import { Router } from 'express';
import { authRouter } from '../modules/auth/auth.routes';
import { categoriesRouter, adminCategoriesRouter, supplierCategoriesRouter } from '../modules/categories/categories.routes';
import { productsRouter, adminProductsRouter, supplierProductsRouter } from '../modules/products/products.routes';
import { customersRouter } from '../modules/customers/customers.routes';
import { diningTablesRouter } from '../modules/dining-tables/dining-tables.routes';
import { invoicesRouter } from '../modules/invoices/invoices.routes';
import { kotRouter } from '../modules/kot/kot.routes';
import { paymentsRouter } from '../modules/payments/payments.routes';
import { devicesRouter } from '../modules/devices/devices.routes';
import { usersRouter } from '../modules/users/users.routes';
import { businessesRouter } from '../modules/businesses/businesses.routes';
import { syncRouter } from '../modules/sync/sync.routes';
import { adminSuppliersRouter, supplierProfileRouter } from '../modules/suppliers/suppliers.routes';
import { adminOrdersRouter, adminInvoicesRouter } from '../modules/orders/orders.routes';
import {
  adminPurchaseOrdersRouter,
  adminPurchaseInvoicesRouter,
  adminSupplierPaymentsRouter,
  supplierPurchasesRouter,
} from '../modules/purchases/purchases.routes';

export const apiRouter = Router();

// 1. General & Legacy Namespaces (Full Backward Compatibility)
apiRouter.use('/auth', authRouter);
apiRouter.use('/categories', categoriesRouter);
apiRouter.use('/products', productsRouter);
apiRouter.use('/customers', customersRouter);
apiRouter.use('/dining-tables', diningTablesRouter);
apiRouter.use('/invoices', invoicesRouter);
apiRouter.use('/kot', kotRouter);
apiRouter.use('/payments', paymentsRouter);
apiRouter.use('/devices', devicesRouter);
apiRouter.use('/users', usersRouter);
apiRouter.use('/business', businessesRouter);
apiRouter.use('/sync', syncRouter);

// 2. Dedicated Admin Namespaces
apiRouter.use('/admin/suppliers', adminSuppliersRouter);
apiRouter.use('/admin/categories', adminCategoriesRouter);
apiRouter.use('/admin/products', adminProductsRouter);
apiRouter.use('/admin/orders', adminOrdersRouter);
apiRouter.use('/admin/invoices', adminInvoicesRouter);
apiRouter.use('/admin/purchase-orders', adminPurchaseOrdersRouter);
apiRouter.use('/admin/purchase-invoices', adminPurchaseInvoicesRouter);
apiRouter.use('/admin/supplier-payments', adminSupplierPaymentsRouter);

// 3. Dedicated Supplier Namespaces
apiRouter.use('/supplier/profile', supplierProfileRouter);
apiRouter.use('/supplier/categories', supplierCategoriesRouter);
apiRouter.use('/supplier/products', supplierProductsRouter);
apiRouter.use('/supplier', supplierPurchasesRouter);
