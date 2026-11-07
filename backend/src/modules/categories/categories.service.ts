import { randomUUID } from 'crypto';
import { prisma } from '../../config/prisma';
import { AppError } from '../../middleware/error.middleware';
import { CreateCategoryInput, UpdateCategoryInput } from './categories.schema';

export class CategoriesService {
  async listCategories(businessId: string, includeInactive = false) {
    return prisma.categories.findMany({
      where: {
        business_id: businessId,
        deleted_at: null,
        ...(includeInactive ? {} : { is_active: true }),
      },
      orderBy: [{ display_order: 'asc' }, { name: 'asc' }],
    });
  }

  async getCategoryById(businessId: string, id: string) {
    const category = await prisma.categories.findFirst({
      where: { id, business_id: businessId, deleted_at: null },
    });
    if (!category) {
      throw new AppError(404, 'Category not found');
    }
    return category;
  }

  async createCategory(businessId: string, data: CreateCategoryInput) {
    const id = data.id || randomUUID();
    return prisma.categories.create({
      data: {
        id,
        business_id: businessId,
        name: data.name,
        icon: data.icon,
        color_value: data.colorValue,
        display_order: data.displayOrder ?? 0,
        is_active: data.isActive ?? true,
      },
    });
  }

  async updateCategory(businessId: string, id: string, data: UpdateCategoryInput) {
    await this.getCategoryById(businessId, id);
    return prisma.categories.update({
      where: { id },
      data: {
        name: data.name,
        icon: data.icon,
        color_value: data.colorValue,
        display_order: data.displayOrder,
        is_active: data.isActive,
      },
    });
  }

  async updateCategoryStatus(businessId: string, id: string, isActive: boolean) {
    await this.getCategoryById(businessId, id);
    return prisma.categories.update({
      where: { id },
      data: {
        is_active: isActive,
      },
    });
  }

  async softDeleteCategory(businessId: string, id: string) {
    await this.getCategoryById(businessId, id);
    return prisma.categories.update({
      where: { id },
      data: {
        deleted_at: new Date(),
        is_active: false,
      },
    });
  }
}

export const categoriesService = new CategoriesService();
