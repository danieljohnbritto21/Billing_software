import { z } from 'zod';

export const purchaseOrderItemInputSchema = z.object({
  id: z.string().uuid().optional(),
  productId: z.string().uuid().optional(),
  productName: z.string().min(1).max(150),
  quantity: z.number().positive(),
  unitPricePaise: z.number().int().nonnegative(),
  gstPercentage: z.number().nonnegative().default(0),
});

export const createPurchaseOrderSchema = z.object({
  id: z.string().uuid().optional(),
  supplierId: z.string().uuid(),
  purchaseOrderNumber: z.string().max(60).optional(),
  orderStatus: z.enum(['DRAFT', 'SENT', 'PARTIALLY_RECEIVED', 'RECEIVED', 'CANCELLED']).default('DRAFT'),
  discountPaise: z.number().int().nonnegative().default(0),
  notes: z.string().optional(),
  orderedAt: z.string().optional(),
  items: z.array(purchaseOrderItemInputSchema).min(1),
});

export const updatePurchaseOrderSchema = z.object({
  notes: z.string().optional(),
  discountPaise: z.number().int().nonnegative().optional(),
  items: z.array(purchaseOrderItemInputSchema).optional(),
});

export const updatePurchaseOrderStatusSchema = z.object({
  orderStatus: z.enum(['DRAFT', 'SENT', 'PARTIALLY_RECEIVED', 'RECEIVED', 'CANCELLED']),
});

export const receivePurchaseOrderSchema = z.object({
  receiveStatus: z.enum(['PARTIALLY_RECEIVED', 'RECEIVED']).default('RECEIVED'),
  notes: z.string().optional(),
});

export const purchaseInvoiceItemInputSchema = z.object({
  id: z.string().uuid().optional(),
  productId: z.string().uuid().optional(),
  productName: z.string().min(1).max(150),
  quantity: z.number().positive(),
  unitPricePaise: z.number().int().nonnegative(),
  gstPercentage: z.number().nonnegative().default(0),
});

export const createPurchaseInvoiceSchema = z.object({
  id: z.string().uuid().optional(),
  supplierId: z.string().uuid().optional(), // For Admin creation; for Supplier, taken from token
  purchaseOrderId: z.string().uuid().optional(),
  supplierInvoiceNumber: z.string().min(1).max(80),
  internalReferenceNumber: z.string().max(80).optional(),
  invoiceDate: z.string().optional(),
  discountPaise: z.number().int().nonnegative().default(0),
  items: z.array(purchaseInvoiceItemInputSchema).min(1),
});

export const approveRejectPurchaseInvoiceSchema = z.object({
  action: z.enum(['APPROVE', 'REJECT']),
  notes: z.string().optional(),
});

export const recordSupplierPaymentSchema = z.object({
  id: z.string().uuid().optional(),
  supplierId: z.string().uuid(),
  purchaseInvoiceId: z.string().uuid().optional(),
  amountPaise: z.number().int().positive(),
  paymentMethodId: z.string().min(1).max(40).default('Cash'),
  paymentReference: z.string().max(100).optional(),
  notes: z.string().optional(),
});

export type PurchaseOrderItemInput = z.infer<typeof purchaseOrderItemInputSchema>;
export type CreatePurchaseOrderInput = z.infer<typeof createPurchaseOrderSchema>;
export type UpdatePurchaseOrderInput = z.infer<typeof updatePurchaseOrderSchema>;
export type UpdatePurchaseOrderStatusInput = z.infer<typeof updatePurchaseOrderStatusSchema>;
export type ReceivePurchaseOrderInput = z.infer<typeof receivePurchaseOrderSchema>;
export type PurchaseInvoiceItemInput = z.infer<typeof purchaseInvoiceItemInputSchema>;
export type CreatePurchaseInvoiceInput = z.infer<typeof createPurchaseInvoiceSchema>;
export type ApproveRejectPurchaseInvoiceInput = z.infer<typeof approveRejectPurchaseInvoiceSchema>;
export type RecordSupplierPaymentInput = z.infer<typeof recordSupplierPaymentSchema>;
