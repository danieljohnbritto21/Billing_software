import { z } from 'zod';

export const createCategorySchema = z.object({
  id: z.string().uuid().optional(),
  name: z.string().min(1).max(100),
  icon: z.string().max(60).optional(),
  colorValue: z.number().int().optional(),
  displayOrder: z.number().int().default(0),
  isActive: z.boolean().default(true),
});

export const updateCategorySchema = createCategorySchema.partial();

export type CreateCategoryInput = z.infer<typeof createCategorySchema>;
export type UpdateCategoryInput = z.infer<typeof updateCategorySchema>;
