import { prisma } from '../../config/prisma';
import { AppError } from '../../middleware/error.middleware';
import { CreateKotInput } from './kot.schema';

export class KotService {
  async listKot(businessId: string, filter?: { invoiceId?: string; orderId?: string }) {
    return prisma.kot_records.findMany({
      where: {
        OR: [
          { invoices: { business_id: businessId } },
          { orders: { business_id: businessId } },
        ],
        ...(filter?.invoiceId ? { invoice_id: filter.invoiceId } : {}),
        ...(filter?.orderId ? { order_id: filter.orderId } : {}),
      },
      include: {
        invoices: {
          select: { id: true, invoice_number: true, table_number: true },
        },
        orders: {
          select: { id: true, order_number: true, dining_table_id: true },
        },
      },
      orderBy: { printed_at: 'desc' },
    });
  }

  async getKotById(businessId: string, id: string) {
    const kot = await prisma.kot_records.findFirst({
      where: {
        id,
        OR: [
          { invoices: { business_id: businessId } },
          { orders: { business_id: businessId } },
        ],
      },
      include: {
        invoices: true,
        orders: true,
      },
    });
    if (!kot) {
      throw new AppError(404, 'KOT record not found');
    }
    return kot;
  }

  async createKot(businessId: string, data: CreateKotInput) {
    let invoice = null;
    let order = null;

    if (data.invoiceId) {
      invoice = await prisma.invoices.findFirst({
        where: { id: data.invoiceId, business_id: businessId },
        include: { orders: true },
      });
      if (!invoice) {
        throw new AppError(400, 'Invalid invoice: does not exist or belongs to another business.');
      }
      if (invoice.orders) {
        order = invoice.orders;
      }
    }

    if (data.orderId && !order) {
      order = await prisma.orders.findFirst({
        where: { id: data.orderId, business_id: businessId, deleted_at: null },
        include: { invoices: true },
      });
      if (!order) {
        throw new AppError(400, 'Invalid order: does not exist or belongs to another business.');
      }
      if (!invoice && order.invoices?.length) {
        invoice = order.invoices[0];
      }
    }

    let kotNumber = data.kotNumber;
    if (!kotNumber) {
      const count = await prisma.kot_records.count({
        where: {
          OR: [
            { invoices: { business_id: businessId } },
            { orders: { business_id: businessId } },
          ],
        },
      });
      kotNumber = `KOT-${String(count + 1).padStart(4, '0')}`;
    }

    const created = await prisma.kot_records.create({
      data: {
        ...(data.id ? { id: data.id } : {}),
        invoice_id: invoice?.id || data.invoiceId || null,
        order_id: order?.id || data.orderId || null,
        kot_number: kotNumber,
        table_number: data.tableNumber || invoice?.table_number || (order?.dining_table_id ? 'Table' : null),
        order_type: data.orderType || invoice?.order_type || order?.order_type || 'Dine In',
        items_json: data.items,
      },
    });

    return created;
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
