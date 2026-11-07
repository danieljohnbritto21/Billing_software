import { z } from 'zod';

export const orderItemInputSchema = z.object({
  id: z.string().uuid().optional(),
  productId: z.string().uuid().nullable().optional(),
  productName: z.string().min(1).max(150),
  productCode: z.string().max(60).optional(),
  quantity: z.number().positive(),
  unit: z.string().max(30).default('plate'),
  unitPricePaise: z.number().int().nonnegative(),
  discountPaise: z.number().int().nonnegative().default(0),
  gstRatePercent: z.number().nonnegative().default(0),
  specialInstructions: z.string().optional(),
});

export const createOrderSchema = z.object({
  id: z.string().uuid().optional(),
  orderNumber: z.string().max(60).optional(),
  diningTableId: z.string().uuid().optional(),
  orderType: z.string().max(40).default('Dine In'),
  notes: z.string().optional(),
  billDiscountPaise: z.number().int().nonnegative().default(0),
  items: z.array(orderItemInputSchema).min(1),
  createInvoiceImmediately: z.boolean().default(true),
  paymentMethod: z.string().max(40).default('Cash'),
  amountPaidPaise: z.number().int().nonnegative().default(0),
  idempotencyKey: z.string().max(128).optional(),
});

export const updateOrderSchema = z.object({
  orderType: z.string().max(40).optional(),
  orderStatus: z.string().max(40).optional(),
  notes: z.string().optional(),
  diningTableId: z.string().uuid().nullable().optional(),
});

export const recordOrderPaymentSchema = z.object({
  amountPaise: z.number().int().positive(),
  paymentMethod: z.string().max(40).default('Cash'),
  referenceNumber: z.string().max(100).optional(),
  notes: z.string().optional(),
  idempotencyKey: z.string().max(128),
});

export type OrderItemInput = z.infer<typeof orderItemInputSchema>;
export type CreateOrderInput = z.infer<typeof createOrderSchema>;
export type UpdateOrderInput = z.infer<typeof updateOrderSchema>;
export type RecordOrderPaymentInput = z.infer<typeof recordOrderPaymentSchema>;
