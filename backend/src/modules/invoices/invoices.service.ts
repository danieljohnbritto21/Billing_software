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
        orders: {
          include: {
            order_items: true,
          },
        },
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
    const existing = await prisma.invoices.findFirst({
      where: {
        business_id: businessId,
        idempotency_key: data.idempotencyKey,
      },
      include: {
        invoice_items: true,
        bill_notes: true,
        payments: true,
      },
    });

    if (existing) {
      return existing;
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
    const orderId = randomUUID();
    const createdAt = data.createdAt ? new Date(data.createdAt) : new Date();

    return prisma.$transaction(async (tx) => {
      // 3. Generate Sequential Invoice Number if not supplied
      let invoiceNumber = data.invoiceNumber;
      if (!invoiceNumber) {
        const count = await tx.invoices.count({ where: { business_id: businessId } });
        const prefix = 'INV-';
        invoiceNumber = `${prefix}${String(count + 1).padStart(5, '0')}` ;
      }

      const subtotalBig = BigInt(data.subtotalPaise);
      const itemDiscountBig = BigInt(data.itemDiscountTotalPaise ?? 0);
      const billDiscountBig = BigInt(data.billDiscountPaise ?? 0);
      const taxableBig = BigInt(data.taxableAmountPaise);
      const cgstBig = BigInt(data.cgstPaise ?? 0);
      const sgstBig = BigInt(data.sgstPaise ?? 0);
      const igstBig = BigInt(data.igstPaise ?? 0);
      const roundOffBig = BigInt(data.roundOffPaise ?? 0);
      const grandTotalBig = BigInt(data.grandTotalPaise);
      const paidAmountBig = BigInt(data.paidAmountPaise ?? 0);
      const balanceDueBig = grandTotalBig > paidAmountBig ? grandTotalBig - paidAmountBig : 0n;

      // 4. Create Backing Orders record
      await tx.orders.create({
        data: {
          id: orderId,
          business_id: businessId,
          order_number: invoiceNumber,
          device_id: data.deviceId || null,
          order_type: data.orderType || 'Dine In',
          order_status: data.orderStatus || 'Completed',
          subtotal_paise: subtotalBig,
          item_discount_paise: itemDiscountBig,
          bill_discount_paise: billDiscountBig,
          taxable_amount_paise: taxableBig,
          total_tax_paise: cgstBig + sgstBig + igstBig,
          cgst_paise: cgstBig,
          sgst_paise: sgstBig,
          igst_paise: igstBig,
          round_off_paise: roundOffBig,
          grand_total_paise: grandTotalBig,
          amount_paid_paise: paidAmountBig,
          balance_due_paise: balanceDueBig,
          payment_status: data.paymentStatus || 'Paid',
          ordered_at: createdAt,
          created_at: createdAt,
        },
      });

      // 5. Create Invoices record linked to order_id
      // Initial status is Pending so that invoice_items trigger does not fire prematurely
      await tx.invoices.create({
        data: {
          id: invoiceId,
          business_id: businessId,
          order_id: orderId,
          device_id: data.deviceId,
          invoice_number: invoiceNumber,
          customer_id: data.customerId,
          customer_name: data.customerName,
          customer_phone: data.customerPhone,
          order_type: data.orderType,
          order_status: 'Pending',
          payment_status: 'Pending',
          payment_method: data.paymentMethod,
          table_number: data.tableNumber,
          delivery_address: data.deliveryAddress,
          cashier_id: cashierId,
          cashier_name: cashierName,
          subtotal_paise: subtotalBig,
          item_discount_total_paise: itemDiscountBig,
          bill_discount_paise: billDiscountBig,
          taxable_amount_paise: taxableBig,
          cgst_paise: cgstBig,
          sgst_paise: sgstBig,
          igst_paise: igstBig,
          round_off_paise: roundOffBig,
          grand_total_paise: grandTotalBig,
          paid_amount_paise: paidAmountBig,
          idempotency_key: data.idempotencyKey,
          created_at: createdAt,
        },
      });

      // 6. Create Order Items and Invoice Items linked
      for (const item of data.items) {
        const orderItemId = randomUUID();
        const invoiceItemId = item.id || randomUUID();

        // Resolve product supplier
        let supplierId: string | null = null;
        if (item.productId) {
          const product = await tx.products.findFirst({
            where: { id: item.productId, business_id: businessId },
          });
          if (product) {
            supplierId = product.supplier_id;
          }
        }

        await tx.order_items.create({
          data: {
            id: orderItemId,
            business_id: businessId,
            order_id: orderId,
            product_id: item.productId,
            supplier_id: supplierId,
            product_name_snapshot: item.productName,
            product_code_snapshot: item.productCode || null,
            quantity: item.quantity,
            unit: item.unit ?? 'plate',
            unit_price_paise: BigInt(item.unitPricePaise),
            discount_paise: BigInt(item.discountPaise ?? 0),
            gst_percentage_snapshot: item.gstRatePercent ?? 0,
            taxable_amount_paise: BigInt(item.taxableAmountPaise),
            tax_amount_paise: BigInt(item.taxAmountPaise),
            total_amount_paise: BigInt(item.totalAmountPaise),
          },
        });

        await tx.invoice_items.create({
          data: {
            id: invoiceItemId,
            invoice_id: invoiceId,
            order_item_id: orderItemId,
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

      // 7. Optional Bill Note
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

      // 8. Initial Payment record if paid
      if (data.paymentStatus === 'Paid' && data.grandTotalPaise > 0) {
        await tx.payments.create({
          data: {
            id: randomUUID(),
            invoice_id: invoiceId,
            order_id: orderId,
            amount_paise: BigInt(data.grandTotalPaise),
            payment_method: data.paymentMethod,
            idempotency_key: `init-pay-${data.idempotencyKey}`,
            notes: 'Initial invoice settlement',
            created_at: createdAt,
          },
        });
      }

      // 9. Update Invoice to target status once items and payment are safely recorded
      const finalOrderStatus = data.orderStatus || 'Completed';
      const finalPaymentStatus = data.paymentStatus || 'Paid';
      const finalInvoice = await tx.invoices.update({
        where: { id: invoiceId },
        data: {
          order_status: finalOrderStatus,
          payment_status: finalPaymentStatus,
        },
        include: {
          invoice_items: true,
          bill_notes: true,
          payments: true,
        },
      });

      return finalInvoice;
    });
  }

  async finalizeInvoice(businessId: string, id: string) {
    await this.getInvoiceById(businessId, id);
    return prisma.invoices.update({
      where: { id },
      data: { order_status: 'Completed' },
    });
  }

  async cancelInvoice(businessId: string, id: string, data: CancelInvoiceInput) {
    const inv = await this.getInvoiceById(businessId, id);
    if (inv.is_cancelled) {
      throw new AppError(400, 'Invoice is already cancelled.');
    }

    const cancelReason = (data as any).reason || (data as any).cancelReason || 'Cancelled by user';

    return prisma.$transaction(async (tx) => {
      if (inv.order_id) {
        await tx.orders.update({
          where: { id: inv.order_id },
          data: {
            order_status: 'Cancelled',
            notes: cancelReason,
          },
        });
      }

      return tx.invoices.update({
        where: { id },
        data: {
          is_cancelled: true,
          cancelled_at: new Date(),
          cancel_reason: cancelReason,
          order_status: 'Cancelled',
          payment_status: 'Cancelled',
        },
      });
    });
  }

  async addInvoiceItem(businessId: string, invoiceId: string, item: InvoiceItemInput) {
    const inv = await this.getInvoiceById(businessId, invoiceId);
    if (inv.order_status === 'Completed' || inv.payment_status === 'Paid') {
      throw new AppError(400, 'Cannot modify finalized invoice.');
    }

    const orderItemId = randomUUID();
    return prisma.$transaction(async (tx) => {
      if (inv.order_id) {
        await tx.order_items.create({
          data: {
            id: orderItemId,
            business_id: businessId,
            order_id: inv.order_id,
            product_id: item.productId,
            product_name_snapshot: item.productName,
            product_code_snapshot: item.productCode || null,
            quantity: item.quantity,
            unit: item.unit ?? 'plate',
            unit_price_paise: BigInt(item.unitPricePaise),
            discount_paise: BigInt(item.discountPaise ?? 0),
            gst_percentage_snapshot: item.gstRatePercent ?? 0,
            taxable_amount_paise: BigInt(item.taxableAmountPaise),
            tax_amount_paise: BigInt(item.taxAmountPaise),
            total_amount_paise: BigInt(item.totalAmountPaise),
          },
        });
      }

      const createdItem = await tx.invoice_items.create({
        data: {
          id: item.id || randomUUID(),
          invoice_id: invoiceId,
          order_item_id: inv.order_id ? orderItemId : null,
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

      const newSubtotal = BigInt(inv.subtotal_paise) + BigInt(item.taxableAmountPaise);
      const newGrand = BigInt(inv.grand_total_paise) + BigInt(item.totalAmountPaise);

      await tx.invoices.update({
        where: { id: invoiceId },
        data: {
          subtotal_paise: newSubtotal,
          grand_total_paise: newGrand,
        },
      });

      if (inv.order_id) {
        await tx.orders.update({
          where: { id: inv.order_id },
          data: {
            subtotal_paise: newSubtotal,
            grand_total_paise: newGrand,
            balance_due_paise: newGrand - BigInt(inv.paid_amount_paise),
          },
        });
      }

      return createdItem;
    });
  }

  async removeInvoiceItem(businessId: string, invoiceId: string, itemId: string) {
    const inv = await this.getInvoiceById(businessId, invoiceId);
    if (inv.order_status === 'Completed' || inv.payment_status === 'Paid') {
      throw new AppError(400, 'Cannot modify finalized invoice.');
    }

    const item = await prisma.invoice_items.findFirst({
      where: { id: itemId, invoice_id: invoiceId },
    });
    if (!item) {
      throw new AppError(404, 'Invoice item not found');
    }

    return prisma.$transaction(async (tx) => {
      await tx.invoice_items.delete({ where: { id: itemId } });
      if (item.order_item_id) {
        await tx.order_items.delete({ where: { id: item.order_item_id } }).catch(() => {});
      }

      const newSubtotal = BigInt(inv.subtotal_paise) - BigInt(item.taxable_amount_paise);
      const newGrand = BigInt(inv.grand_total_paise) - BigInt(item.total_amount_paise);

      await tx.invoices.update({
        where: { id: invoiceId },
        data: {
          subtotal_paise: newSubtotal,
          grand_total_paise: newGrand,
        },
      });

      if (inv.order_id) {
        await tx.orders.update({
          where: { id: inv.order_id },
          data: {
            subtotal_paise: newSubtotal,
            grand_total_paise: newGrand,
            balance_due_paise: newGrand - BigInt(inv.paid_amount_paise),
          },
        });
      }

      return { removed: true };
    });
  }

  addItemToInvoice = this.addInvoiceItem.bind(this);
  removeItemFromInvoice = this.removeInvoiceItem.bind(this);
}

export const invoicesService = new InvoicesService();
