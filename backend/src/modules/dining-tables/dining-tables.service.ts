import { prisma } from '../../config/prisma';
import { AppError } from '../../middleware/error.middleware';
import { CreateDiningTableInput, UpdateDiningTableInput } from './dining-tables.schema';

export class DiningTablesService {
  async listTables(businessId: string) {
    return prisma.dining_tables.findMany({
      where: {
        business_id: businessId,
        deleted_at: null,
      },
      include: {
        invoices: {
          select: {
            id: true,
            invoice_number: true,
            order_status: true,
            payment_status: true,
            grand_total_paise: true,
          },
        },
      },
      orderBy: { table_name: 'asc' },
    });
  }

  async getTableById(businessId: string, id: string) {
    const table = await prisma.dining_tables.findFirst({
      where: { id, business_id: businessId, deleted_at: null },
    });
    if (!table) {
      throw new AppError(404, 'Dining table not found');
    }
    return table;
  }

  async createTable(businessId: string, data: CreateDiningTableInput) {
    return prisma.dining_tables.create({
      data: {
        ...(data.id ? { id: data.id } : {}),
        business_id: businessId,
        table_name: data.tableName,
        seating_capacity: data.seatingCapacity,
      },
    });
  }

  async updateTable(businessId: string, id: string, data: UpdateDiningTableInput) {
    await this.getTableById(businessId, id);

    // If setting currentInvoiceId, verify it belongs to the same business
    if (data.currentInvoiceId) {
      const inv = await prisma.invoices.findFirst({
        where: { id: data.currentInvoiceId, business_id: businessId },
      });
      if (!inv) {
        throw new AppError(400, 'Invalid invoice: does not exist or belongs to another business.');
      }
    }

    return prisma.dining_tables.update({
      where: { id },
      data: {
        ...(data.tableName ? { table_name: data.tableName } : {}),
        ...(data.seatingCapacity !== undefined ? { seating_capacity: data.seatingCapacity } : {}),
        ...(data.isOccupied !== undefined ? { is_occupied: data.isOccupied } : {}),
        ...(data.currentInvoiceId !== undefined ? { current_invoice_id: data.currentInvoiceId } : {}),
      },
    });
  }

  async softDeleteTable(businessId: string, id: string) {
    await this.getTableById(businessId, id);
    return prisma.dining_tables.update({
      where: { id },
      data: {
        deleted_at: new Date(),
        is_occupied: false,
        current_invoice_id: null,
      },
    });
  }
}

export const diningTablesService = new DiningTablesService();
