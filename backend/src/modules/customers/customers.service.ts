import { randomUUID } from 'crypto';
import { prisma } from '../../config/prisma';
import { AppError } from '../../middleware/error.middleware';
import { CreateCustomerInput, UpdateCustomerInput } from './customers.schema';

export class CustomersService {
  async listCustomers(businessId: string, search?: string) {
    return prisma.customers.findMany({
      where: {
        business_id: businessId,
        deleted_at: null,
        ...(search
          ? {
              OR: [
                { name: { contains: search, mode: 'insensitive' } },
                { phone: { contains: search } },
              ],
            }
          : {}),
      },
      orderBy: { name: 'asc' },
    });
  }

  async getCustomerById(businessId: string, id: string) {
    const customer = await prisma.customers.findFirst({
      where: { id, business_id: businessId, deleted_at: null },
    });
    if (!customer) {
      throw new AppError(404, 'Customer not found');
    }
    return customer;
  }

  async createCustomer(businessId: string, data: CreateCustomerInput) {
    const id = data.id || randomUUID();
    return prisma.customers.create({
      data: {
        id,
        business_id: businessId,
        name: data.name,
        phone: data.phone,
        address: data.address,
        notes: data.notes,
      },
    });
  }

  async updateCustomer(businessId: string, id: string, data: UpdateCustomerInput) {
    await this.getCustomerById(businessId, id);
    return prisma.customers.update({
      where: { id },
      data: {
        ...(data.name ? { name: data.name } : {}),
        ...(data.phone !== undefined ? { phone: data.phone } : {}),
        ...(data.address !== undefined ? { address: data.address } : {}),
        ...(data.notes !== undefined ? { notes: data.notes } : {}),
      },
    });
  }

  async softDeleteCustomer(businessId: string, id: string) {
    await this.getCustomerById(businessId, id);
    return prisma.customers.update({
      where: { id },
      data: {
        deleted_at: new Date(),
      },
    });
  }
}

export const customersService = new CustomersService();
