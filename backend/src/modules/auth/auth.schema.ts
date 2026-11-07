import { z } from 'zod';

export const registerBusinessSchema = z.object({
  businessName: z.string().min(2).max(150),
  tagline: z.string().max(255).optional(),
  phone: z.string().max(30).optional(),
  address: z.string().optional(),
  gstin: z.string().max(20).optional(),
  username: z.string().min(3).max(60),
  password: z.string().min(6).max(100),
  fullName: z.string().min(2).max(120),
});

export const loginSchema = z.object({
  username: z.string().min(1),
  password: z.string().min(1),
  businessId: z.string().uuid().optional(),
  deviceUid: z.string().max(128).optional(),
  deviceName: z.string().max(100).optional(),
});

export const supplierLoginSchema = z.object({
  username: z.string().min(1),
  password: z.string().min(1),
  businessId: z.string().uuid().optional(),
  deviceUid: z.string().max(128).optional(),
  deviceName: z.string().max(100).optional(),
});

export type RegisterBusinessInput = z.infer<typeof registerBusinessSchema>;
export type LoginInput = z.infer<typeof loginSchema>;
export type SupplierLoginInput = z.infer<typeof supplierLoginSchema>;
