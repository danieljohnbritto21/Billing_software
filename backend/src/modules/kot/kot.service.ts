import { prisma } from '../../config/prisma';
import { AppError } from '../../middleware/error.middleware';
import { CreateKotInput } from './kot.schema';

export class KotService {
  async listKot(businessId: string, invoiceId?: string) {
    return prisma.kot_records.findMany({
      where: {
        invoices: { business_id: businessId },
        ...(invoiceId ? { invoice_id: invoiceId } : {}),
      },
      include: {
        invoices: {
          select: { id: true, invoice_number: true, table_number: true },
        },
      },
      orderBy: { printed_at: 'desc' },
    });
  }

  async getKotById(businessId: string, id: string) {
    const kot = await prisma.kot_records.findFirst({
      where: {
        id,
        invoices: { business_id: businessId },
      },
      include: {
        invoices: true,
      },
    });
    if (!kot) {
      throw new AppError(404, 'KOT record not found');
    }
    return kot;
  }

  async createKot(businessId: string, data: CreateKotInput) {
    const invoice = await prisma.invoices.findFirst({
      where: { id: data.invoiceId, business_id: businessId },
    });
    if (!invoice) {
      throw new AppError(400, 'Invalid invoice: does not exist or belongs to another business.');
    }

    let kotNumber = data.kotNumber;
    if (!kotNumber) {
      const count = await prisma.kot_records.count({
        where: { invoices: { business_id: businessId } },
      });
      kotNumber = `KOT-${String(count + 1).padStart(4, '0')}`;
    }

    return prisma.kot_records.create({
      data: {
        ...(data.id ? { id: data.id } : {}),
        invoice_id: data.invoiceId,
        kot_number: kotNumber,
        table_number: data.tableNumber || invoice.table_number,
        order_type: data.orderType || invoice.order_type,
        items_json: data.items,
      },
    });
  }

  async reprintKot(businessId: string, id: string) {
    const kot = await this.getKotById(businessId, id);
    return prisma.kot_records.update({
      where: { id: kot.id },
      data: {
        reprinted_count: kot.reprinted_count + 1,
        updated_at: new Date(),
      },
    });
  }
}

export const kotService = new KotService();
