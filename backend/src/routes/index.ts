import { Router } from 'express';
import { authRouter } from '../modules/auth/auth.routes';
import { categoriesRouter } from '../modules/categories/categories.routes';
import { productsRouter } from '../modules/products/products.routes';
import { customersRouter } from '../modules/customers/customers.routes';
import { diningTablesRouter } from '../modules/dining-tables/dining-tables.routes';
import { invoicesRouter } from '../modules/invoices/invoices.routes';
import { kotRouter } from '../modules/kot/kot.routes';
import { paymentsRouter } from '../modules/payments/payments.routes';
import { devicesRouter } from '../modules/devices/devices.routes';
import { usersRouter } from '../modules/users/users.routes';
import { businessesRouter } from '../modules/businesses/businesses.routes';
import { syncRouter } from '../modules/sync/sync.routes';

export const apiRouter = Router();

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
