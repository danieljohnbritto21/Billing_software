import { z } from 'zod';

export const createKotSchema = z.object({
  id: z.string().uuid().optional(),
  invoiceId: z.string().uuid(),
  kotNumber: z.string().max(60).optional(),
  tableNumber: z.string().max(40).optional(),
  orderType: z.string().max(40).default('Dine In'),
  items: z.array(
    z.object({
      itemId: z.string().optional(),
      productName: z.string(),
      quantity: z.number().positive(),
      notes: z.string().optional(),
    })
  ).min(1),
});

export type CreateKotInput = z.infer<typeof createKotSchema>;
