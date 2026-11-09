import fs from 'fs';
import path from 'path';
import { randomUUID, createHash } from 'crypto';
import { prisma } from '../../config/prisma';
import { env } from '../../config/env';
import { AppError } from '../../middleware/error.middleware';
import { CreateProductInput, UpdateProductInput, UploadProductImageInput } from './products.schema';

function formatProductOutput(p: any) {
  if (!p) return p;
  const sellingRupees = p.selling_price_rupees != null
    ? Number(p.selling_price_rupees)
    : Number(p.selling_price_paise ?? 0) / 100;
  const costRupees = p.cost_price_rupees != null
    ? Number(p.cost_price_rupees)
    : Number(p.cost_price_paise ?? 0) / 100;

  return {
    ...p,
    costPriceRupees: costRupees,
    sellingPriceRupees: sellingRupees,
    cost_price_rupees: costRupees,
    selling_price_rupees: sellingRupees,
  };
}

export class ProductsService {
  async listProducts(
    businessId: string,
    options?: {
      categoryId?: string;
      supplierId?: string;
      search?: string;
      availableOnly?: boolean;
      page?: number;
      limit?: number;
    }
  ) {
    const page = options?.page ? Math.max(1, Number(options.page)) : undefined;
    const limit = options?.limit ? Math.min(100, Math.max(1, Number(options.limit))) : undefined;
    const skip = page && limit ? (page - 1) * limit : undefined;

    const where: any = {
      business_id: businessId,
      deleted_at: null,
      ...(options?.categoryId ? { category_id: options.categoryId } : {}),
      ...(options?.supplierId ? { supplier_id: options.supplierId } : {}),
      ...(options?.availableOnly ? { is_available: true } : {}),
      ...(options?.search
        ? {
            OR: [
              { name: { contains: options.search, mode: 'insensitive' } },
              { code: { contains: options.search, mode: 'insensitive' } },
              { description: { contains: options.search, mode: 'insensitive' } },
            ],
          }
        : {}),
    };

    const [items, total] = await Promise.all([
      prisma.products.findMany({
        where,
        skip,
        take: limit,
        include: {
          categories: {
            select: { id: true, name: true, icon: true },
          },
          suppliers: {
            select: { id: true, supplier_code: true, supplier_name: true },
          },
          product_images: {
            where: { deleted_at: null },
            select: { id: true, file_name: true, is_primary: true },
          },
        },
        orderBy: { name: 'asc' },
      }),
      prisma.products.count({ where }),
    ]);

    return {
      items: items.map(formatProductOutput),
      total,
      page: page || 1,
      limit: limit || total,
    };
  }

  async getProductById(businessId: string, id: string, enforcedSupplierId?: string) {
    const where: any = {
      id,
      business_id: businessId,
      deleted_at: null,
    };
    if (enforcedSupplierId) {
      where.supplier_id = enforcedSupplierId;
    }

    const product = await prisma.products.findFirst({
      where,
      include: {
        categories: true,
        suppliers: {
          select: { id: true, supplier_code: true, supplier_name: true, contact_person: true },
        },
        product_images: {
          where: { deleted_at: null },
        },
      },
    });

    if (!product) {
      throw new AppError(404, 'Product not found or access denied');
    }
    return formatProductOutput(product);
  }

  async createProduct(businessId: string, data: CreateProductInput, enforcedSupplierId?: string) {
    // 1. Validate Category (must belong to this business and be active)
    let categoryId = data.categoryId;
    if (categoryId) {
      const category = await prisma.categories.findFirst({
        where: { id: categoryId, business_id: businessId, deleted_at: null },
      });
      if (!category) {
        throw new AppError(400, 'Invalid category: category does not exist or belongs to another business.');
      }
      if (enforcedSupplierId && !category.is_active) {
        throw new AppError(400, 'Selected category is inactive.');
      }
    }

    // 2. Resolve Supplier ID
    let supplierId: string;
    if (enforcedSupplierId) {
      supplierId = enforcedSupplierId;
    } else if (data.supplierId) {
      const supplier = await prisma.suppliers.findFirst({
        where: { id: data.supplierId, business_id: businessId, deleted_at: null },
      });
      if (!supplier) {
        throw new AppError(400, 'Invalid supplier: supplier does not exist or belongs to another business.');
      }
      supplierId = supplier.id;
    } else {
      // Default to in-house supplier
      const defaultSupplier = await prisma.suppliers.findFirst({
        where: { business_id: businessId, supplier_code: 'SUP-DEFAULT' },
      });
      if (!defaultSupplier) {
        throw new AppError(500, 'No default supplier found for this business.');
      }
      supplierId = defaultSupplier.id;
    }

    const id = data.id || randomUUID();
    const created = await prisma.products.create({
      data: {
        id,
        business_id: businessId,
        category_id: categoryId,
        supplier_id: supplierId,
        name: data.name.trim(),
        code: data.code?.trim(),
        description: data.description?.trim(),
        cost_price_paise: BigInt(data.costPricePaise ?? 0),
        selling_price_paise: BigInt(data.sellingPricePaise ?? 0),
        cost_price_rupees: data.costPriceRupees ?? (Number(data.costPricePaise ?? 0) / 100),
        selling_price_rupees: data.sellingPriceRupees ?? (Number(data.sellingPricePaise ?? 0) / 100),
        gst_rate_percent: data.gstRatePercent ?? 0,
        is_tax_inclusive: data.isTaxInclusive ?? true,
        unit: data.unit ?? 'plate',
        is_available: data.isAvailable ?? true,
        image_path: data.imagePath,
      },
      include: {
        categories: true,
        suppliers: {
          select: { id: true, supplier_code: true, supplier_name: true },
        },
      },
    });
    return formatProductOutput(created);
  }

  async updateProduct(
    businessId: string,
    id: string,
    data: UpdateProductInput,
    enforcedSupplierId?: string
  ) {
    const existing = await this.getProductById(businessId, id, enforcedSupplierId);

    // Validate Category if changing
    if (data.categoryId !== undefined && data.categoryId !== null) {
      const category = await prisma.categories.findFirst({
        where: { id: data.categoryId, business_id: businessId, deleted_at: null },
      });
      if (!category) {
        throw new AppError(400, 'Invalid category: category does not exist or belongs to another business.');
      }
      if (enforcedSupplierId && !category.is_active) {
        throw new AppError(400, 'Selected category is inactive.');
      }
    }

    // Suppliers cannot change supplier_id; Admin can update supplier_id
    let supplierIdToSet = undefined;
    if (!enforcedSupplierId && data.supplierId !== undefined) {
      const supplier = await prisma.suppliers.findFirst({
        where: { id: data.supplierId, business_id: businessId, deleted_at: null },
      });
      if (!supplier) {
        throw new AppError(400, 'Invalid supplier: supplier does not exist or belongs to another business.');
      }
      supplierIdToSet = supplier.id;
    }

    const updated = await prisma.products.update({
      where: { id },
      data: {
        ...(data.categoryId !== undefined ? { category_id: data.categoryId } : {}),
        ...(supplierIdToSet !== undefined ? { supplier_id: supplierIdToSet } : {}),
        ...(data.name ? { name: data.name.trim() } : {}),
        ...(data.code !== undefined ? { code: data.code?.trim() || null } : {}),
        ...(data.description !== undefined ? { description: data.description?.trim() || null } : {}),
        ...(data.costPricePaise !== undefined ? {
          cost_price_paise: BigInt(data.costPricePaise),
          cost_price_rupees: data.costPriceRupees ?? (Number(data.costPricePaise) / 100),
        } : {}),
        ...(data.sellingPricePaise !== undefined ? {
          selling_price_paise: BigInt(data.sellingPricePaise),
          selling_price_rupees: data.sellingPriceRupees ?? (Number(data.sellingPricePaise) / 100),
        } : {}),
        ...(data.gstRatePercent !== undefined ? { gst_rate_percent: data.gstRatePercent } : {}),
        ...(data.isTaxInclusive !== undefined ? { is_tax_inclusive: data.isTaxInclusive } : {}),
        ...(data.unit !== undefined ? { unit: data.unit } : {}),
        ...(data.isAvailable !== undefined ? { is_available: data.isAvailable } : {}),
        ...(data.imagePath !== undefined ? { image_path: data.imagePath } : {}),
      },
      include: {
        categories: true,
        suppliers: {
          select: { id: true, supplier_code: true, supplier_name: true },
        },
      },
    });
    return formatProductOutput(updated);
  }

  async updateProductStatus(
    businessId: string,
    id: string,
    isAvailable: boolean,
    enforcedSupplierId?: string
  ) {
    await this.getProductById(businessId, id, enforcedSupplierId);
    return prisma.products.update({
      where: { id },
      data: { is_available: isAvailable },
    });
  }

  async softDeleteProduct(businessId: string, id: string, enforcedSupplierId?: string) {
    await this.getProductById(businessId, id, enforcedSupplierId);

    // Check if historical sales or purchases reference this product
    const [salesCount, invoiceCount, poCount, piCount] = await Promise.all([
      prisma.order_items.count({ where: { product_id: id } }),
      prisma.invoice_items.count({ where: { product_id: id } }),
      prisma.purchase_order_items.count({ where: { product_id: id } }),
      prisma.purchase_invoice_items.count({ where: { product_id: id } }),
    ]);

    // Always soft-delete to preserve snapshot referential integrity
    return prisma.products.update({
      where: { id },
      data: {
        deleted_at: new Date(),
        is_available: false,
      },
    });
  }

  async listProductImages(businessId: string, productId: string) {
    await this.getProductById(businessId, productId);
    return prisma.product_images.findMany({
      where: {
        product_id: productId,
        deleted_at: null,
      },
      orderBy: { display_order: 'asc' },
    });
  }

  async uploadProductImage(businessId: string, productId: string, data: UploadProductImageInput) {
    await this.getProductById(businessId, productId);

    let rawBase64 = data.imageBase64;
    let mimeType = data.mimeType || 'image/jpeg';
    if (rawBase64.startsWith('data:')) {
      const parts = rawBase64.split(',');
      const match = parts[0].match(/:(.*?);/);
      if (match) mimeType = match[1];
      rawBase64 = parts[1] || '';
    }

    const buffer = Buffer.from(rawBase64, 'base64');
    if (buffer.length > 5 * 1024 * 1024) {
      throw new AppError(400, 'Image file exceeds maximum limit of 5MB');
    }

    let ext = 'jpg';
    if (mimeType.includes('png')) ext = 'png';
    else if (mimeType.includes('webp')) ext = 'webp';

    const id = data.id || randomUUID();
    const uniqueFileName = `${id}_${Date.now()}.${ext}`;

    if (!fs.existsSync(env.IMAGE_STORAGE_PATH)) {
      fs.mkdirSync(env.IMAGE_STORAGE_PATH, { recursive: true });
    }

    const filePath = path.join(env.IMAGE_STORAGE_PATH, uniqueFileName);
    fs.writeFileSync(filePath, buffer);

    const hash = createHash('sha256').update(buffer).digest('hex');

    const imageRecord = await prisma.$transaction(async (tx) => {
      if (data.isPrimary) {
        await tx.product_images.updateMany({
          where: { product_id: productId },
          data: { is_primary: false },
        });
      }

      const rec = await tx.product_images.create({
        data: {
          id,
          product_id: productId,
          file_path: filePath,
          file_name: uniqueFileName,
          file_size_bytes: BigInt(buffer.length),
          mime_type: mimeType,
          file_hash_sha256: hash,
          is_primary: data.isPrimary,
          display_order: data.displayOrder,
        },
      });

      if (data.isPrimary) {
        await tx.products.update({
          where: { id: productId },
          data: { image_path: `/api/v1/products/images/${uniqueFileName}` },
        });
      }

      return rec;
    });

    return imageRecord;
  }

  async deleteProductImage(businessId: string, productId: string, imageId: string) {
    await this.getProductById(businessId, productId);
    const img = await prisma.product_images.findFirst({
      where: { id: imageId, product_id: productId },
    });
    if (!img) {
      throw new AppError(404, 'Image not found');
    }

    return prisma.product_images.update({
      where: { id: imageId },
      data: { deleted_at: new Date() },
    });
  }

  getImagePath(fileName: string): string {
    const cleanFileName = path.basename(fileName);
    const fullPath = path.join(env.IMAGE_STORAGE_PATH, cleanFileName);
    if (!fs.existsSync(fullPath)) {
      throw new AppError(404, 'Image file not found on server');
    }
    return fullPath;
  }
}

export const productsService = new ProductsService();
