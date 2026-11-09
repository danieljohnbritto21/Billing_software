import { z } from 'zod';

export const createProductSchema = z
  .object({
    id: z.string().uuid().optional(),
    categoryId: z.string().uuid().nullable().optional(),
    supplierId: z.string().uuid().optional(),
    name: z.string().min(1).max(150),
    code: z.string().max(60).optional(),
    description: z.string().optional(),
    costPriceRupees: z.number().nonnegative().optional(),
    sellingPriceRupees: z.number().nonnegative().optional(),
    costPricePaise: z.number().int().nonnegative().optional(),
    sellingPricePaise: z.number().int().nonnegative().optional(),
    gstRatePercent: z.number().nonnegative().default(0),
    isTaxInclusive: z.boolean().default(true),
    unit: z.string().max(30).default('plate'),
    isAvailable: z.boolean().default(true),
    imagePath: z.string().optional(),
  })
  .refine(
    (d) => d.sellingPriceRupees !== undefined || d.sellingPricePaise !== undefined,
    {
      message: 'Either sellingPriceRupees or sellingPricePaise is required',
      path: ['sellingPriceRupees'],
    }
  )
  .transform((d) => {
    const sellingRupees =
      d.sellingPriceRupees !== undefined
        ? d.sellingPriceRupees
        : Number(d.sellingPricePaise!) / 100;
    const costRupees =
      d.costPriceRupees !== undefined
        ? d.costPriceRupees
        : Number(d.costPricePaise ?? 0) / 100;
    const sellingPaise =
      d.sellingPricePaise !== undefined
        ? d.sellingPricePaise
        : Math.round(sellingRupees * 100);
    const costPaise =
      d.costPricePaise !== undefined
        ? d.costPricePaise
        : Math.round(costRupees * 100);

    return {
      ...d,
      costPriceRupees: costRupees,
      sellingPriceRupees: sellingRupees,
      costPricePaise: costPaise,
      sellingPricePaise: sellingPaise,
    };
  });

export const updateProductSchema = z
  .object({
    categoryId: z.string().uuid().nullable().optional(),
    supplierId: z.string().uuid().optional(),
    name: z.string().min(1).max(150).optional(),
    code: z.string().max(60).nullable().optional(),
    description: z.string().nullable().optional(),
    costPriceRupees: z.number().nonnegative().optional(),
    sellingPriceRupees: z.number().nonnegative().optional(),
    costPricePaise: z.number().int().nonnegative().optional(),
    sellingPricePaise: z.number().int().nonnegative().optional(),
    gstRatePercent: z.number().nonnegative().optional(),
    isTaxInclusive: z.boolean().optional(),
    unit: z.string().max(30).optional(),
    isAvailable: z.boolean().optional(),
    imagePath: z.string().nullable().optional(),
  })
  .transform((d) => {
    let sellingRupees = d.sellingPriceRupees;
    let sellingPaise = d.sellingPricePaise;
    if (sellingRupees !== undefined && sellingPaise === undefined) {
      sellingPaise = Math.round(sellingRupees * 100);
    } else if (sellingPaise !== undefined && sellingRupees === undefined) {
      sellingRupees = sellingPaise / 100;
    }

    let costRupees = d.costPriceRupees;
    let costPaise = d.costPricePaise;
    if (costRupees !== undefined && costPaise === undefined) {
      costPaise = Math.round(costRupees * 100);
    } else if (costPaise !== undefined && costRupees === undefined) {
      costRupees = costPaise / 100;
    }

    return {
      ...d,
      costPriceRupees: costRupees,
      sellingPriceRupees: sellingRupees,
      costPricePaise: costPaise,
      sellingPricePaise: sellingPaise,
    };
  });

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
