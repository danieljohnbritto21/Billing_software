import { z } from 'zod';

export const syncPullQuerySchema = z.object({
  cursor: z.coerce.number().int().nonnegative().default(0),
  limit: z.coerce.number().int().positive().max(200).default(50),
});

export const syncPushItemSchema = z.object({
  entityName: z.enum([
    'categories',
    'suppliers',
    'products',
    'customers',
    'dining_tables',
    'orders',
    'order_items',
    'invoices',
    'invoice_items',
    'payments',
    'kot_records',
    'kot_items',
    'product_images',
    'purchase_orders',
    'purchase_invoices',
    'supplier_payments',
  ]),
  operation: z.enum(['INSERT', 'UPDATE', 'DELETE']),
  recordId: z.string().uuid(),
  clientVersion: z.number().int().nonnegative().optional(),
  payload: z.record(z.any()),
});

export const syncPushBodySchema = z.object({
  deviceId: z.string().uuid().optional(),
  items: z.array(syncPushItemSchema).min(1),
});

export type SyncPullQuery = z.infer<typeof syncPullQuerySchema>;
export type SyncPushItem = z.infer<typeof syncPushItemSchema>;
export type SyncPushBody = z.infer<typeof syncPushBodySchema>;
