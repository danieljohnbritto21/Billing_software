import { z } from 'zod';

export const createDiningTableSchema = z.object({
  id: z.string().uuid().optional(),
  tableName: z.string().min(1).max(50),
  seatingCapacity: z.number().int().positive().default(4),
});

export const updateDiningTableSchema = z.object({
  tableName: z.string().min(1).max(50).optional(),
  seatingCapacity: z.number().int().positive().optional(),
  isOccupied: z.boolean().optional(),
  currentInvoiceId: z.string().uuid().nullable().optional(),
});

export type CreateDiningTableInput = z.infer<typeof createDiningTableSchema>;
export type UpdateDiningTableInput = z.infer<typeof updateDiningTableSchema>;
