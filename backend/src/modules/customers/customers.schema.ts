import { z } from 'zod';

export const createCustomerSchema = z.object({
  id: z.string().uuid().optional(),
  name: z.string().min(1).max(120),
  phone: z.string().max(30).optional(),
  address: z.string().optional(),
  notes: z.string().optional(),
});

export const updateCustomerSchema = createCustomerSchema.partial();

export type CreateCustomerInput = z.infer<typeof createCustomerSchema>;
export type UpdateCustomerInput = z.infer<typeof updateCustomerSchema>;
