import { randomUUID } from 'crypto';
import { prisma } from '../../config/prisma';
import { AppError } from '../../middleware/error.middleware';
import { CreateInvoiceInput, InvoiceItemInput, CancelInvoiceInput } from './invoices.schema';

export class InvoicesService {
  async listInvoices(
    businessId: string,
    options?: {
      page?: number;
      limit?: number;
      orderStatus?: string;
      paymentStatus?: string;
      startDate?: string;
      endDate?: string;
    }
  ) {
    const page = Math.max(1, options?.page ?? 1);
    const limit = Math.min(100, Math.max(1, options?.limit ?? 20));
    const skip = (page - 1) * limit;

    const where: any = {
      business_id: businessId,
      ...(options?.orderStatus ? { order_status: options.orderStatus } : {}),
      ...(options?.paymentStatus ? { payment_status: options.paymentStatus } : {}),
      ...(options?.startDate || options?.endDate
        ? {
            created_at: {
              ...(options?.startDate ? { gte: new Date(options.startDate) } : {}),
              ...(options?.endDate ? { lte: new Date(options.endDate) } : {}),
            },
          }
        : {}),
    };

    const [total, items] = await Promise.all([
      prisma.invoices.count({ where }),
      prisma.invoices.findMany({
        where,
        include: {
          invoice_items: true,
          bill_notes: true,
          payments: true,
        },
        orderBy: { created_at: 'desc' },
        skip,
        take: limit,
      }),
    ]);

    return { items, total, page, limit };
  }

  async getInvoiceById(businessId: string, id: string) {
    const invoice = await prisma.invoices.findFirst({
      where: { id, business_id: businessId },
      include: {
        invoice_items: true,
        bill_notes: true,
        payments: true,
        customers: true,
        devices: true,
      },
    });
    if (!invoice) {
      throw new AppError(404, 'Invoice not found');
    }
    return invoice;
  }

  async createInvoice(
    businessId: string,
    cashierId: string | undefined,
    cashierName: string | undefined,
    data: CreateInvoiceInput
  ) {
    // 1. Idempotency Check
    const existing = await prisma.invoices.findUnique({
      where: {
        business_id_idempotency_key: {
          business_id: businessId,
          idempotency_key: data.idempotencyKey,
        },
      },
      include: {
        invoice_items: true,
        bill_notes: true,
        payments: true,
      },
    });

    if (existing) {
      return existing; // Return existing idempotent invoice cleanly
    }

    // 2. Validate customer isolation if provided
    if (data.customerId) {
      const cust = await prisma.customers.findFirst({
        where: { id: data.customerId, business_id: businessId },
      });
      if (!cust) {
        throw new AppError(400, 'Invalid customer: does not exist or belongs to another business.');
      }
    }

    const invoiceId = data.id || randomUUID();
    const createdAt = data.createdAt ? new Date(data.createdAt) : new Date();

    return prisma.$transaction(async (tx) => {
      // 3. Generate Sequential Invoice Number if not supplied
      let invoiceNumber = data.invoiceNumber;
      if (!invoiceNumber) {
        const count = await tx.invoices.count({ where: { business_id: businessId } });
        const prefix = 'INV-';
        invoiceNumber = `${prefix}${String(count + 1).padStart(5, '0')}`;
      }

      // 4. Create Invoice
      const invoice = await tx.invoices.create({
        data: {
          id: invoiceId,
          business_id: businessId,
          device_id: data.deviceId,
          invoice_number: invoiceNumber,
          customer_id: data.customerId,
          customer_name: data.customerName,
          customer_phone: data.customerPhone,
          order_type: data.orderType,
          order_status: data.orderStatus,
          payment_status: data.paymentStatus,
          payment_method: data.paymentMethod,
          table_number: data.tableNumber,
          delivery_address: data.deliveryAddress,
          cashier_id: cashierId,
          cashier_name: cashierName,
          subtotal_paise: BigInt(data.subtotalPaise),
          item_discount_total_paise: BigInt(data.itemDiscountTotalPaise ?? 0),
          bill_discount_paise: BigInt(data.billDiscountPaise ?? 0),
          taxable_amount_paise: BigInt(data.taxableAmountPaise),
          cgst_paise: BigInt(data.cgstPaise ?? 0),
          sgst_paise: BigInt(data.sgstPaise ?? 0),
          igst_paise: BigInt(data.igstPaise ?? 0),
          round_off_paise: BigInt(data.roundOffPaise ?? 0),
          grand_total_paise: BigInt(data.grandTotalPaise),
          paid_amount_paise: BigInt(data.paidAmountPaise ?? 0),
          idempotency_key: data.idempotencyKey,
          created_at: createdAt,
        },
      });

      // 5. Create Invoice Items
      for (const item of data.items) {
        await tx.invoice_items.create({
          data: {
            id: item.id || randomUUID(),
            invoice_id: invoiceId,
            product_id: item.productId,
            product_name: item.productName,
            product_code: item.productCode,
            unit: item.unit ?? 'plate',
            unit_price_paise: BigInt(item.unitPricePaise),
            quantity: item.quantity,
            discount_paise: BigInt(item.discountPaise ?? 0),
            gst_rate_percent: item.gstRatePercent ?? 0,
            is_tax_inclusive: item.isTaxInclusive ?? true,
            taxable_amount_paise: BigInt(item.taxableAmountPaise),
            tax_amount_paise: BigInt(item.taxAmountPaise),
            total_amount_paise: BigInt(item.totalAmountPaise),
          },
        });
      }

      // 6. Optional Bill Note
      if (data.billNote) {
        await tx.bill_notes.create({
          data: {
            id: randomUUID(),
            invoice_id: invoiceId,
            note: data.billNote,
            is_customer_facing: true,
          },
        });
      }

      // 7. Initial Payment record if paid
      if (data.paymentStatus === 'Paid' && data.grandTotalPaise > 0) {
        await tx.payments.create({
          data: {
            id: randomUUID(),
            invoice_id: invoiceId,
            amount_paise: BigInt(data.grandTotalPaise),
            payment_method: data.paymentMethod,
            idempotency_key: `init-pay-${data.idempotencyKey}`,
            notes: 'Initial invoice settlement',
          },
        });
      }

      return tx.invoices.findUnique({
        where: { id: invoiceId },
        include: {
          invoice_items: true,
          bill_notes: true,
          payments: true,
        },
      });
    });
  }

  async addItemToInvoice(businessId: string, invoiceId: string, item: InvoiceItemInput) {
    const inv = await this.getInvoiceById(businessId, invoiceId);

    return prisma.$transaction(async (tx) => {
      const createdItem = await tx.invoice_items.create({
        data: {
          id: item.id || randomUUID(),
          invoice_id: invoiceId,
          product_id: item.productId,
          product_name: item.productName,
          product_code: item.productCode,
          unit: item.unit ?? 'plate',
          unit_price_paise: BigInt(item.unitPricePaise),
          quantity: item.quantity,
          discount_paise: BigInt(item.discountPaise ?? 0),
          gst_rate_percent: item.gstRatePercent ?? 0,
          is_tax_inclusive: item.isTaxInclusive ?? true,
          taxable_amount_paise: BigInt(item.taxableAmountPaise),
          tax_amount_paise: BigInt(item.taxAmountPaise),
          total_amount_paise: BigInt(item.totalAmountPaise),
        },
      });

      // Recalculate totals on parent invoice
      const newSubtotal = BigInt(inv.subtotal_paise) + BigInt(item.taxableAmountPaise);
      const newGrand = BigInt(inv.grand_total_paise) + BigInt(item.totalAmountPaise);

      await tx.invoices.update({
        where: { id: invoiceId },
        data: {
          subtotal_paise: newSubtotal,
          taxable_amount_paise: newSubtotal,
          grand_total_paise: newGrand,
          updated_at: new Date(),
        },
      });

      return createdItem;
    });
  }

  async removeItemFromInvoice(businessId: string, invoiceId: string, itemId: string) {
    const inv = await this.getInvoiceById(businessId, invoiceId);
    const item = await prisma.invoice_items.findFirst({
      where: { id: itemId, invoice_id: invoiceId },
    });
    if (!item) {
      throw new AppError(404, 'Invoice item not found');
    }

    return prisma.$transaction(async (tx) => {
      await tx.invoice_items.delete({ where: { id: itemId } });

      const newSubtotal = BigInt(inv.subtotal_paise) - BigInt(item.taxable_amount_paise);
      const newGrand = BigInt(inv.grand_total_paise) - BigInt(item.total_amount_paise);

      await tx.invoices.update({
        where: { id: invoiceId },
        data: {
          subtotal_paise: newSubtotal >= 0n ? newSubtotal : 0n,
          taxable_amount_paise: newSubtotal >= 0n ? newSubtotal : 0n,
          grand_total_paise: newGrand >= 0n ? newGrand : 0n,
          updated_at: new Date(),
        },
      });

      return { deletedItemId: itemId };
    });
  }

  async finalizeInvoice(businessId: string, invoiceId: string) {
    await this.getInvoiceById(businessId, invoiceId);
    return prisma.invoices.update({
      where: { id: invoiceId },
      data: {
        order_status: 'Completed',
        payment_status: 'Paid',
        updated_at: new Date(),
      },
      include: {
        invoice_items: true,
        payments: true,
      },
    });
  }

  async cancelInvoice(businessId: string, invoiceId: string, data: CancelInvoiceInput) {
    await this.getInvoiceById(businessId, invoiceId);
    return prisma.invoices.update({
      where: { id: invoiceId },
      data: {
        is_cancelled: true,
        cancelled_at: new Date(),
        cancel_reason: data.reason,
        order_status: 'Cancelled',
        payment_status: 'Cancelled',
        updated_at: new Date(),
      },
    });
  }
}

export const invoicesService = new InvoicesService();
