import { randomUUID } from 'crypto';
import { prisma } from '../../config/prisma';
import { AppError } from '../../middleware/error.middleware';
import { CreateKotInput } from './kot.schema';

export class KotService {
  async listKot(
    businessId: string,
    filter?: { invoiceId?: string; orderId?: string; purchaseInvoiceId?: string }
  ) {
    return prisma.kot_records.findMany({
      where: {
        OR: [
          { business_id: businessId },
          { invoices: { business_id: businessId } },
          { orders: { business_id: businessId } },
          { purchase_invoices: { business_id: businessId } },
        ],
        ...(filter?.invoiceId ? { invoice_id: filter.invoiceId } : {}),
        ...(filter?.orderId ? { order_id: filter.orderId } : {}),
        ...(filter?.purchaseInvoiceId ? { purchase_invoice_id: filter.purchaseInvoiceId } : {}),
      },
      include: {
        kot_items: true,
        invoices: {
          select: { id: true, invoice_number: true, table_number: true },
        },
        orders: {
          select: { id: true, order_number: true, dining_table_id: true },
        },
        purchase_invoices: {
          select: { id: true, supplier_invoice_number: true, invoice_date: true },
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
          { business_id: businessId },
          { invoices: { business_id: businessId } },
          { orders: { business_id: businessId } },
          { purchase_invoices: { business_id: businessId } },
        ],
      },
      include: {
        kot_items: true,
        invoices: true,
        orders: true,
        purchase_invoices: true,
      },
    });
    if (!kot) {
      throw new AppError(404, 'KOT record not found');
    }
    return kot;
  }

  async getKotsByPurchaseInvoiceId(businessId: string, purchaseInvoiceId: string) {
    return prisma.kot_records.findMany({
      where: {
        purchase_invoice_id: purchaseInvoiceId,
        OR: [
          { business_id: businessId },
          { purchase_invoices: { business_id: businessId } },
        ],
      },
      include: {
        kot_items: true,
        purchase_invoices: {
          select: {
            id: true,
            supplier_invoice_number: true,
            invoice_date: true,
            invoice_status: true,
            grand_total_paise: true,
          },
        },
      },
      orderBy: { printed_at: 'desc' },
    });
  }

  async createKot(businessId: string, data: CreateKotInput) {
    let invoice = null;
    let order = null;
    let purchaseInvoice = null;

    if (data.purchaseInvoiceId) {
      purchaseInvoice = await prisma.purchase_invoices.findFirst({
        where: { id: data.purchaseInvoiceId, business_id: businessId },
      });
      if (!purchaseInvoice) {
        throw new AppError(400, 'Invalid purchase invoice: does not exist or belongs to another business.');
      }
    }

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
            { business_id: businessId },
            { invoices: { business_id: businessId } },
            { orders: { business_id: businessId } },
            { purchase_invoices: { business_id: businessId } },
          ],
        },
      });
      kotNumber = `KOT-${String(count + 1).padStart(4, '0')}`;
    }

    const kotId = data.id || randomUUID();

    // Atomic transaction: Insert into kot_records AND all kot_items.
    // If any item insertion fails, the entire transaction rolls back.
    const createdKot = await prisma.$transaction(async (tx) => {
      const header = await tx.kot_records.create({
        data: {
          id: kotId,
          business_id: businessId,
          invoice_id: invoice?.id || data.invoiceId || null,
          order_id: order?.id || data.orderId || null,
          purchase_invoice_id: purchaseInvoice?.id || data.purchaseInvoiceId || null,
          supplier_invoice_number:
            data.supplierInvoiceNumber || purchaseInvoice?.supplier_invoice_number || null,
          kot_number: kotNumber,
          table_number:
            data.tableNumber || invoice?.table_number || (order?.dining_table_id ? 'Table' : null),
          order_type:
            data.orderType ||
            invoice?.order_type ||
            order?.order_type ||
            (purchaseInvoice ? 'Procurement' : 'Dine In'),
          items_json: data.items,
        },
      });

      // Insert line items into kot_items table
      for (const item of data.items) {
        await tx.kot_items.create({
          data: {
            id: item.id || randomUUID(),
            kot_id: header.id,
            product_id: item.productId || null,
            order_item_id: item.orderItemId || null,
            product_name_snapshot: item.productName,
            quantity: item.quantity,
            unit: item.unit || 'unit',
            special_instructions: item.notes || item.specialInstructions || null,
            item_status: item.status || 'PENDING',
          },
        });
      }

      return await tx.kot_records.findUnique({
        where: { id: header.id },
        include: {
          kot_items: true,
          purchase_invoices: true,
        },
      });
    });

    return createdKot;
  }

  async reprintKot(businessId: string, id: string) {
    const kot = await this.getKotById(businessId, id);
    return prisma.kot_records.update({
      where: { id: kot.id },
      data: {
        reprinted_count: kot.reprinted_count + 1,
        updated_at: new Date(),
      },
      include: {
        kot_items: true,
      },
    });
  }
}

export const kotService = new KotService();
