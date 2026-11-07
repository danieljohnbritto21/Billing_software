import bcrypt from 'bcryptjs';
import { prisma } from '../../config/prisma';
import { AppError } from '../../middleware/error.middleware';
import {
  CreateSupplierInput,
  UpdateSupplierInput,
  UpdateSupplierProfileInput,
} from './suppliers.schema';

export class SuppliersService {
  async listSuppliers(
    businessId: string,
    query?: { search?: string; isActive?: string | boolean; page?: number; limit?: number }
  ) {
    const page = Math.max(1, Number(query?.page) || 1);
    const limit = Math.min(100, Math.max(1, Number(query?.limit) || 20));
    const skip = (page - 1) * limit;

    const where: any = {
      business_id: businessId,
      deleted_at: null,
    };

    if (query?.isActive !== undefined && query?.isActive !== '') {
      where.is_active = String(query.isActive) === 'true';
    }

    if (query?.search) {
      where.OR = [
        { supplier_name: { contains: query.search, mode: 'insensitive' } },
        { supplier_code: { contains: query.search, mode: 'insensitive' } },
        { contact_person: { contains: query.search, mode: 'insensitive' } },
        { phone_number: { contains: query.search, mode: 'insensitive' } },
      ];
    }

    const [items, total] = await Promise.all([
      prisma.suppliers.findMany({
        where,
        skip,
        take: limit,
        orderBy: { supplier_name: 'asc' },
        include: {
          _count: {
            select: {
              products: true,
              purchase_orders: true,
              purchase_invoices: true,
            },
          },
        },
      }),
      prisma.suppliers.count({ where }),
    ]);

    return {
      items,
      total,
      page,
      limit,
    };
  }

  async getSupplierById(businessId: string, supplierId: string) {
    const supplier = await prisma.suppliers.findFirst({
      where: {
        id: supplierId,
        business_id: businessId,
        deleted_at: null,
      },
      include: {
        _count: {
          select: {
            products: true,
            purchase_orders: true,
            purchase_invoices: true,
            supplier_payments: true,
          },
        },
      },
    });

    if (!supplier) {
      throw new AppError(404, 'Supplier not found.');
    }
    return supplier;
  }

  async createSupplier(businessId: string, data: CreateSupplierInput) {
    // 1. Verify code uniqueness in business
    const existing = await prisma.suppliers.findFirst({
      where: {
        business_id: businessId,
        supplier_code: data.supplierCode.trim(),
        deleted_at: null,
      },
    });
    if (existing) {
      throw new AppError(409, `Supplier with code '${data.supplierCode}' already exists in this business.`);
    }

    return await prisma.$transaction(async (tx) => {
      const supplier = await tx.suppliers.create({
        data: {
          business_id: businessId,
          supplier_code: data.supplierCode.trim(),
          supplier_name: data.supplierName.trim(),
          contact_person: data.contactPerson?.trim(),
          phone_number: data.phoneNumber?.trim(),
          email: data.email?.trim() || null,
          address: data.address?.trim(),
          gstin: data.gstin?.trim(),
          notes: data.notes?.trim(),
          is_active: data.isActive ?? true,
        },
      });

      let createdUser = null;
      if (data.createLoginUser && data.username && data.password) {
        const existingUser = await tx.users.findFirst({
          where: { username: data.username.trim() },
        });
        if (existingUser) {
          throw new AppError(409, `Username '${data.username}' is already taken.`);
        }

        const salt = await bcrypt.genSalt(10);
        const passwordHash = await bcrypt.hash(data.password, salt);

        createdUser = await tx.users.create({
          data: {
            business_id: businessId,
            supplier_id: supplier.id,
            username: data.username.trim(),
            full_name: data.fullName?.trim() || data.contactPerson?.trim() || data.supplierName.trim(),
            role_id: 'SUPPLIER',
            password_hash: passwordHash,
            salt: salt,
            is_active: true,
          },
          select: {
            id: true,
            username: true,
            full_name: true,
            role_id: true,
            is_active: true,
          },
        });
      }

      return {
        supplier,
        user: createdUser,
      };
    });
  }

  async updateSupplier(businessId: string, supplierId: string, data: UpdateSupplierInput) {
    const existing = await prisma.suppliers.findFirst({
      where: { id: supplierId, business_id: businessId, deleted_at: null },
    });
    if (!existing) {
      throw new AppError(404, 'Supplier not found.');
    }

    const updated = await prisma.suppliers.update({
      where: { id: supplierId },
      data: {
        ...(data.supplierName ? { supplier_name: data.supplierName.trim() } : {}),
        ...(data.contactPerson !== undefined ? { contact_person: data.contactPerson?.trim() || null } : {}),
        ...(data.phoneNumber !== undefined ? { phone_number: data.phoneNumber?.trim() || null } : {}),
        ...(data.email !== undefined ? { email: data.email?.trim() || null } : {}),
        ...(data.address !== undefined ? { address: data.address?.trim() || null } : {}),
        ...(data.gstin !== undefined ? { gstin: data.gstin?.trim() || null } : {}),
        ...(data.notes !== undefined ? { notes: data.notes?.trim() || null } : {}),
        ...(data.isActive !== undefined ? { is_active: data.isActive } : {}),
      },
    });

    return updated;
  }

  async updateSupplierStatus(businessId: string, supplierId: string, isActive: boolean) {
    const existing = await prisma.suppliers.findFirst({
      where: { id: supplierId, business_id: businessId, deleted_at: null },
    });
    if (!existing) {
      throw new AppError(404, 'Supplier not found.');
    }

    return await prisma.suppliers.update({
      where: { id: supplierId },
      data: { is_active: isActive },
    });
  }

  async getSupplierProducts(businessId: string, supplierId: string, query?: any) {
    const page = Math.max(1, Number(query?.page) || 1);
    const limit = Math.min(100, Math.max(1, Number(query?.limit) || 30));
    const skip = (page - 1) * limit;

    const where: any = {
      business_id: businessId,
      supplier_id: supplierId,
      deleted_at: null,
    };

    const [products, total] = await Promise.all([
      prisma.products.findMany({
        where,
        skip,
        take: limit,
        orderBy: { name: 'asc' },
        include: {
          categories: { select: { id: true, name: true } },
        },
      }),
      prisma.products.count({ where }),
    ]);

    return {
      items: products,
      total,
      page,
      limit,
    };
  }

  async getSupplierPurchaseHistory(businessId: string, supplierId: string, query?: any) {
    const page = Math.max(1, Number(query?.page) || 1);
    const limit = Math.min(100, Math.max(1, Number(query?.limit) || 20));
    const skip = (page - 1) * limit;

    const where: any = {
      business_id: businessId,
      supplier_id: supplierId,
      deleted_at: null,
    };

    const [orders, total] = await Promise.all([
      prisma.purchase_orders.findMany({
        where,
        skip,
        take: limit,
        orderBy: { ordered_at: 'desc' },
        include: {
          purchase_order_items: true,
          purchase_invoices: true,
        },
      }),
      prisma.purchase_orders.count({ where }),
    ]);

    return {
      items: orders,
      total,
      page,
      limit,
    };
  }

  async getSupplierPaymentHistory(businessId: string, supplierId: string, query?: any) {
    const page = Math.max(1, Number(query?.page) || 1);
    const limit = Math.min(100, Math.max(1, Number(query?.limit) || 20));
    const skip = (page - 1) * limit;

    const where: any = {
      business_id: businessId,
      supplier_id: supplierId,
    };

    const [payments, total] = await Promise.all([
      prisma.supplier_payments.findMany({
        where,
        skip,
        take: limit,
        orderBy: { paid_at: 'desc' },
        include: {
          purchase_invoices: {
            select: {
              id: true,
              supplier_invoice_number: true,
              grand_total_paise: true,
              amount_paid_paise: true,
            },
          },
          payment_methods: true,
        },
      }),
      prisma.supplier_payments.count({ where }),
    ]);

    return {
      items: payments,
      total,
      page,
      limit,
    };
  }

  async getSupplierProfile(businessId: string, supplierId: string) {
    const supplier = await prisma.suppliers.findFirst({
      where: {
        id: supplierId,
        business_id: businessId,
        deleted_at: null,
      },
    });
    if (!supplier) {
      throw new AppError(404, 'Supplier profile not found.');
    }
    return supplier;
  }

  async updateSupplierProfile(businessId: string, supplierId: string, data: UpdateSupplierProfileInput) {
    const supplier = await prisma.suppliers.findFirst({
      where: {
        id: supplierId,
        business_id: businessId,
        deleted_at: null,
      },
    });
    if (!supplier) {
      throw new AppError(404, 'Supplier profile not found.');
    }

    const updated = await prisma.suppliers.update({
      where: { id: supplierId },
      data: {
        ...(data.contactPerson !== undefined ? { contact_person: data.contactPerson?.trim() || null } : {}),
        ...(data.phoneNumber !== undefined ? { phone_number: data.phoneNumber?.trim() || null } : {}),
        ...(data.email !== undefined ? { email: data.email?.trim() || null } : {}),
        ...(data.address !== undefined ? { address: data.address?.trim() || null } : {}),
        ...(data.notes !== undefined ? { notes: data.notes?.trim() || null } : {}),
      },
    });

    return updated;
  }
}

export const suppliersService = new SuppliersService();
