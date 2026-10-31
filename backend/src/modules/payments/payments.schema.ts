import { z } from 'zod';

export const recordPaymentSchema = z.object({
  id: z.string().uuid().optional(),
  invoiceId: z.string().uuid(),
  amountPaise: z.number().int(),
  paymentMethod: z.enum(['Cash', 'Card', 'UPI', 'Split', 'Credit', 'Due']),
  referenceNumber: z.string().max(100).optional(),
  notes: z.string().optional(),
  idempotencyKey: z.string().min(1).max(128),
});

export type RecordPaymentInput = z.infer<typeof recordPaymentSchema>;
