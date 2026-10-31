import fs from 'fs';
import path from 'path';
import { randomUUID, createHash } from 'crypto';
import { prisma } from '../../config/prisma';
import { env } from '../../config/env';
import { AppError } from '../../middleware/error.middleware';
import { CreateProductInput, UpdateProductInput, UploadProductImageInput } from './products.schema';

export class ProductsService {
  async listProducts(
    businessId: string,
    options?: { categoryId?: string; search?: string; availableOnly?: boolean }
  ) {
    return prisma.products.findMany({
      where: {
        business_id: businessId,
        deleted_at: null,
        ...(options?.categoryId ? { category_id: options.categoryId } : {}),
        ...(options?.availableOnly ? { is_available: true } : {}),
        ...(options?.search
          ? {
              OR: [
                { name: { contains: options.search, mode: 'insensitive' } },
                { code: { contains: options.search, mode: 'insensitive' } },
              ],
            }
          : {}),
      },
      include: {
        categories: {
          select: { id: true, name: true, icon: true },
        },
      },
      orderBy: { name: 'asc' },
    });
  }

  async getProductById(businessId: string, id: string) {
    const product = await prisma.products.findFirst({
      where: { id, business_id: businessId, deleted_at: null },
      include: {
        categories: true,
        product_images: true,
      },
    });
    if (!product) {
      throw new AppError(404, 'Product not found');
    }
    return product;
  }

  async createProduct(businessId: string, data: CreateProductInput) {
    if (data.categoryId) {
      const category = await prisma.categories.findFirst({
        where: { id: data.categoryId, business_id: businessId, deleted_at: null },
      });
      if (!category) {
        throw new AppError(400, 'Invalid category: category does not exist or belongs to another business.');
      }
    }

    const id = data.id || randomUUID();
    return prisma.products.create({
      data: {
        id,
        business_id: businessId,
        category_id: data.categoryId,
        name: data.name,
        code: data.code,
        description: data.description,
        cost_price_paise: BigInt(data.costPricePaise ?? 0),
        selling_price_paise: BigInt(data.sellingPricePaise),
        gst_rate_percent: data.gstRatePercent ?? 0,
        is_tax_inclusive: data.isTaxInclusive ?? true,
        unit: data.unit ?? 'plate',
        is_available: data.isAvailable ?? true,
        image_path: data.imagePath,
      },
    });
  }

  async updateProduct(businessId: string, id: string, data: UpdateProductInput) {
    await this.getProductById(businessId, id);

    if (data.categoryId) {
      const category = await prisma.categories.findFirst({
        where: { id: data.categoryId, business_id: businessId, deleted_at: null },
      });
      if (!category) {
        throw new AppError(400, 'Invalid category: category does not exist or belongs to another business.');
      }
    }

    return prisma.products.update({
      where: { id },
      data: {
        ...(data.categoryId !== undefined ? { category_id: data.categoryId } : {}),
        ...(data.name ? { name: data.name } : {}),
        ...(data.code !== undefined ? { code: data.code } : {}),
        ...(data.description !== undefined ? { description: data.description } : {}),
        ...(data.costPricePaise !== undefined ? { cost_price_paise: BigInt(data.costPricePaise) } : {}),
        ...(data.sellingPricePaise !== undefined ? { selling_price_paise: BigInt(data.sellingPricePaise) } : {}),
        ...(data.gstRatePercent !== undefined ? { gst_rate_percent: data.gstRatePercent } : {}),
        ...(data.isTaxInclusive !== undefined ? { is_tax_inclusive: data.isTaxInclusive } : {}),
        ...(data.unit !== undefined ? { unit: data.unit } : {}),
        ...(data.isAvailable !== undefined ? { is_available: data.isAvailable } : {}),
        ...(data.imagePath !== undefined ? { image_path: data.imagePath } : {}),
      },
    });
  }

  async softDeleteProduct(businessId: string, id: string) {
    await this.getProductById(businessId, id);
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
