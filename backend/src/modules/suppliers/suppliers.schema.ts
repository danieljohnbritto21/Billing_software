import { z } from 'zod';

export const createSupplierSchema = z.object({
  supplierCode: z.string().min(1).max(60),
  supplierName: z.string().min(1).max(150),
  contactPerson: z.string().max(120).optional(),
  phoneNumber: z.string().max(30).optional(),
  email: z.string().email().max(120).optional().or(z.literal('')),
  address: z.string().optional(),
  gstin: z.string().max(20).optional(),
  notes: z.string().optional(),
  isActive: z.boolean().optional().default(true),
  // Optional login user creation for the supplier
  createLoginUser: z.boolean().optional().default(false),
  username: z.string().min(3).max(60).optional(),
  password: z.string().min(6).max(100).optional(),
  fullName: z.string().min(2).max(120).optional(),
});

export const updateSupplierSchema = z.object({
  supplierName: z.string().min(1).max(150).optional(),
  contactPerson: z.string().max(120).optional(),
  phoneNumber: z.string().max(30).optional(),
  email: z.string().email().max(120).optional().or(z.literal('')),
  address: z.string().optional(),
  gstin: z.string().max(20).optional(),
  notes: z.string().optional(),
  isActive: z.boolean().optional(),
});

export const updateSupplierStatusSchema = z.object({
  isActive: z.boolean(),
});

export const updateSupplierProfileSchema = z.object({
  contactPerson: z.string().max(120).optional(),
  phoneNumber: z.string().max(30).optional(),
  email: z.string().email().max(120).optional().or(z.literal('')),
  address: z.string().optional(),
  notes: z.string().optional(),
});

export type CreateSupplierInput = z.infer<typeof createSupplierSchema>;
export type UpdateSupplierInput = z.infer<typeof updateSupplierSchema>;
export type UpdateSupplierStatusInput = z.infer<typeof updateSupplierStatusSchema>;
export type UpdateSupplierProfileInput = z.infer<typeof updateSupplierProfileSchema>;
