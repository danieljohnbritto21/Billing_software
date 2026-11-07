import { z } from 'zod';

export const createProductSchema = z.object({
  id: z.string().uuid().optional(),
  categoryId: z.string().uuid().nullable().optional(),
  supplierId: z.string().uuid().optional(),
  name: z.string().min(1).max(150),
  code: z.string().max(60).optional(),
  description: z.string().optional(),
  costPricePaise: z.number().int().nonnegative().default(0),
  sellingPricePaise: z.number().int().nonnegative(),
  gstRatePercent: z.number().nonnegative().default(0),
  isTaxInclusive: z.boolean().default(true),
  unit: z.string().max(30).default('plate'),
  isAvailable: z.boolean().default(true),
  imagePath: z.string().optional(),
});

export const updateProductSchema = createProductSchema.partial();

export const updateProductStatusSchema = z.object({
  isAvailable: z.boolean(),
});

export const uploadProductImageSchema = z.object({
  id: z.string().uuid().optional(),
  imageBase64: z.string().min(10),
  fileName: z.string().max(150).optional(),
  mimeType: z.string().max(50).default('image/jpeg'),
  isPrimary: z.boolean().default(false),
  displayOrder: z.number().int().default(0),
});

export type CreateProductInput = z.infer<typeof createProductSchema>;
export type UpdateProductInput = z.infer<typeof updateProductSchema>;
export type UpdateProductStatusInput = z.infer<typeof updateProductStatusSchema>;
export type UploadProductImageInput = z.infer<typeof uploadProductImageSchema>;
