import { z } from 'zod';

export const invoiceItemInputSchema = z.object({
  id: z.string().uuid().optional(),
  productId: z.string().uuid().nullable().optional(),
  productName: z.string().min(1).max(150),
  productCode: z.string().max(60).optional(),
  unit: z.string().max(30).default('plate'),
  unitPricePaise: z.number().int().nonnegative(),
  quantity: z.number().positive(),
  discountPaise: z.number().int().nonnegative().default(0),
  gstRatePercent: z.number().nonnegative().default(0),
  isTaxInclusive: z.boolean().default(true),
  taxableAmountPaise: z.number().int().nonnegative(),
  taxAmountPaise: z.number().int().nonnegative(),
  totalAmountPaise: z.number().int().nonnegative(),
});

export const createInvoiceSchema = z.object({
  id: z.string().uuid().optional(),
  idempotencyKey: z.string().min(1).max(128),
  invoiceNumber: z.string().max(60).optional(),
  deviceId: z.string().uuid().optional(),
  customerId: z.string().uuid().optional(),
  customerName: z.string().max(120).optional(),
  customerPhone: z.string().max(30).optional(),
  orderType: z.enum(['Dine In', 'Takeaway', 'Delivery']).default('Dine In'),
  orderStatus: z.enum(['Pending', 'In Progress', 'Completed', 'Cancelled']).default('Completed'),
  paymentStatus: z.enum(['Pending', 'Partially Paid', 'Paid', 'Cancelled', 'Refunded']).default('Paid'),
  paymentMethod: z.string().max(40).default('Cash'),
  tableNumber: z.string().max(40).optional(),
  deliveryAddress: z.string().optional(),
  billNote: z.string().optional(),
  subtotalPaise: z.number().int().nonnegative(),
  itemDiscountTotalPaise: z.number().int().nonnegative().default(0),
  billDiscountPaise: z.number().int().nonnegative().default(0),
  taxableAmountPaise: z.number().int().nonnegative(),
  cgstPaise: z.number().int().nonnegative().default(0),
  sgstPaise: z.number().int().nonnegative().default(0),
  igstPaise: z.number().int().nonnegative().default(0),
  roundOffPaise: z.number().int().default(0),
  grandTotalPaise: z.number().int().nonnegative(),
  paidAmountPaise: z.number().int().nonnegative().default(0),
  createdAt: z.string().datetime().optional(),
  items: z.array(invoiceItemInputSchema).min(1),
});

export const addInvoiceItemSchema = invoiceItemInputSchema;

export const cancelInvoiceSchema = z.object({
  reason: z.string().min(1).max(255),
});

export type CreateInvoiceInput = z.infer<typeof createInvoiceSchema>;
export type InvoiceItemInput = z.infer<typeof invoiceItemInputSchema>;
export type CancelInvoiceInput = z.infer<typeof cancelInvoiceSchema>;
