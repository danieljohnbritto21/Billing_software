import { z } from 'zod';

export const createStaffUserSchema = z.object({
  username: z.string().min(3).max(60),
  password: z.string().min(6).max(100),
  fullName: z.string().min(2).max(120),
  role: z.enum(['cashier', 'admin']).default('cashier'),
});

export const updateUserStatusSchema = z.object({
  isActive: z.boolean(),
});

export type CreateStaffUserInput = z.infer<typeof createStaffUserSchema>;
export type UpdateUserStatusInput = z.infer<typeof updateUserStatusSchema>;
