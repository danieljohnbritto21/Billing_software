import { z } from 'zod';

export const createKotSchema = z
  .object({
    id: z.string().uuid().optional(),
    invoiceId: z.string().uuid().optional().nullable(),
    orderId: z.string().uuid().optional().nullable(),
    purchaseInvoiceId: z.string().uuid().optional().nullable(),
    supplierInvoiceNumber: z.string().max(80).optional().nullable(),
    transactionId: z.string().uuid().optional().nullable(),
    kotNumber: z.string().max(60).optional(),
    tableNumber: z.string().max(40).optional().nullable(),
    orderType: z.string().max(40).default('Dine In'),
    items: z
      .array(
        z.object({
          id: z.string().uuid().optional(),
          itemId: z.string().optional(),
          productId: z.string().uuid().optional().nullable(),
          orderItemId: z.string().uuid().optional().nullable(),
          productName: z.string(),
          quantity: z.number().positive(),
          unit: z.string().optional().default('unit'),
          notes: z.string().optional().nullable(),
          specialInstructions: z.string().optional().nullable(),
          status: z.string().optional().default('PENDING'),
        })
      )
      .min(1),
  })
  .refine((data) => data.invoiceId || data.orderId || data.purchaseInvoiceId, {
    message: 'Either invoiceId, orderId, or purchaseInvoiceId must be provided.',
  });

export type CreateKotInput = z.infer<typeof createKotSchema>;
