import { randomUUID } from 'crypto';
import { prisma } from '../../config/prisma';
import { AppError } from '../../middleware/error.middleware';
import {
  CreatePurchaseOrderInput,
  UpdatePurchaseOrderInput,
  ReceivePurchaseOrderInput,
  CreatePurchaseInvoiceInput,
  RecordSupplierPaymentInput,
} from './purchases.schema';

export class PurchasesService {
  // ==========================================
  // 1. PURCHASE ORDERS
  // ==========================================

  async listPurchaseOrders(
    businessId: string,
    options?: {
      supplierId?: string;
      orderStatus?: string;
      page?: number;
      limit?: number;
    }
  ) {
    const page = Math.max(1, Number(options?.page) || 1);
    const limit = Math.min(100, Math.max(1, Number(options?.limit) || 20));
    const skip = (page - 1) * limit;

    const where: any = {
      business_id: businessId,
      deleted_at: null,
      ...(options?.supplierId ? { supplier_id: options.supplierId } : {}),
      ...(options?.orderStatus ? { order_status: options.orderStatus } : {}),
    };

    const [items, total] = await Promise.all([
      prisma.purchase_orders.findMany({
        where,
        skip,
        take: limit,
        orderBy: { ordered_at: 'desc' },
        include: {
          suppliers: {
            select: { id: true, supplier_code: true, supplier_name: true, contact_person: true },
          },
          purchase_order_items: true,
          purchase_invoices: {
            select: { id: true, supplier_invoice_number: true, invoice_status: true, grand_total_paise: true },
          },
        },
      }),
      prisma.purchase_orders.count({ where }),
    ]);

    return { items, total, page, limit };
  }

  async getPurchaseOrderById(businessId: string, id: string, enforcedSupplierId?: string) {
    const where: any = {
      id,
      business_id: businessId,
      deleted_at: null,
    };
    if (enforcedSupplierId) {
      where.supplier_id = enforcedSupplierId;
    }

    const order = await prisma.purchase_orders.findFirst({
      where,
      include: {
        suppliers: true,
        purchase_order_items: {
          include: {
            products: {
              select: { id: true, name: true, code: true, unit: true },
            },
          },
        },
        purchase_invoices: true,
      },
    });

    if (!order) {
      throw new AppError(404, 'Purchase order not found or access denied.');
    }
    return order;
  }

  async createPurchaseOrder(businessId: string, userId: string, data: CreatePurchaseOrderInput) {
    // 1. Validate Supplier
    const supplier = await prisma.suppliers.findFirst({
      where: { id: data.supplierId, business_id: businessId, deleted_at: null },
    });
    if (!supplier) {
      throw new AppError(400, 'Invalid supplier: supplier does not exist or belongs to another business.');
    }

    const orderId = data.id || randomUUID();
    const orderedAt = data.orderedAt ? new Date(data.orderedAt) : new Date();

    return await prisma.$transaction(async (tx) => {
      // 2. Generate PO Number if not provided
      let poNumber = data.purchaseOrderNumber;
      if (!poNumber) {
        const count = await tx.purchase_orders.count({ where: { business_id: businessId } });
        poNumber = `PO-${String(count + 1).padStart(5, '0')}`;
      }

      // Check uniqueness
      const existingPo = await tx.purchase_orders.findFirst({
        where: { business_id: businessId, purchase_order_number: poNumber },
      });
      if (existingPo) {
        throw new AppError(409, `Purchase order number '${poNumber}' already exists.`);
      }

      // 3. Calculate line totals on server
      let subtotalPaise = 0n;
      let totalTaxPaise = 0n;

      const preparedItems = [];
      for (const item of data.items) {
        const quantityInt = Math.round(item.quantity * 1000);
        const unitPriceBig = BigInt(item.unitPricePaise);
        const lineGrossPaise = (BigInt(quantityInt) * unitPriceBig) / 1000n;
        const gstRateInt = Math.round(item.gstPercentage * 100);
        const lineTaxPaise = (lineGrossPaise * BigInt(gstRateInt)) / 10000n;
        const lineTotalPaise = lineGrossPaise + lineTaxPaise;

        subtotalPaise += lineGrossPaise;
        totalTaxPaise += lineTaxPaise;

        preparedItems.push({
          id: item.id || randomUUID(),
          purchase_order_id: orderId,
          product_id: item.productId || null,
          product_name_snapshot: item.productName,
          quantity: item.quantity,
          unit_price_paise: unitPriceBig,
          gst_percentage_snapshot: item.gstPercentage,
          tax_amount_paise: lineTaxPaise,
          total_amount_paise: lineTotalPaise,
        });
      }

      const discountBig = BigInt(data.discountPaise ?? 0);
      const grandTotalPaise =
        subtotalPaise + totalTaxPaise > discountBig ? subtotalPaise + totalTaxPaise - discountBig : 0n;

      const order = await tx.purchase_orders.create({
        data: {
          id: orderId,
          business_id: businessId,
          supplier_id: supplier.id,
          purchase_order_number: poNumber,
          created_by_user_id: userId,
          order_status: data.orderStatus,
          subtotal_paise: subtotalPaise,
          discount_paise: discountBig,
          total_tax_paise: totalTaxPaise,
          grand_total_paise: grandTotalPaise,
          notes: data.notes || null,
          ordered_at: orderedAt,
        },
      });

      for (const it of preparedItems) {
        await tx.purchase_order_items.create({ data: it });
      }

      return {
        order,
        items: preparedItems,
      };
    });
  }

  async updatePurchaseOrder(businessId: string, id: string, data: UpdatePurchaseOrderInput) {
    const existing = await this.getPurchaseOrderById(businessId, id);
    if (existing.order_status === 'RECEIVED' || existing.order_status === 'CANCELLED') {
      throw new AppError(400, `Cannot update purchase order in '${existing.order_status}' status.`);
    }

    return prisma.purchase_orders.update({
      where: { id },
      data: {
        ...(data.notes !== undefined ? { notes: data.notes || null } : {}),
        ...(data.discountPaise !== undefined ? { discount_paise: BigInt(data.discountPaise) } : {}),
      },
    });
  }

  async updatePurchaseOrderStatus(businessId: string, id: string, orderStatus: string) {
    await this.getPurchaseOrderById(businessId, id);
    return prisma.purchase_orders.update({
      where: { id },
      data: { order_status: orderStatus },
    });
  }

  async receivePurchaseOrder(businessId: string, id: string, data: ReceivePurchaseOrderInput) {
    const existing = await this.getPurchaseOrderById(businessId, id);
    if (existing.order_status === 'CANCELLED') {
      throw new AppError(400, 'Cannot receive cancelled purchase order.');
    }

    return prisma.purchase_orders.update({
      where: { id },
      data: {
        order_status: data.receiveStatus,
        notes: data.notes ? `${existing.notes ? existing.notes + '\n' : ''}[Received] ${data.notes}` : existing.notes,
      },
    });
  }

  async getPurchaseOrderItems(businessId: string, id: string, enforcedSupplierId?: string) {
    await this.getPurchaseOrderById(businessId, id, enforcedSupplierId);
    return prisma.purchase_order_items.findMany({
      where: { purchase_order_id: id },
      orderBy: { created_at: 'asc' },
    });
  }

  // ==========================================
  // 2. PURCHASE INVOICES
  // ==========================================

  async listPurchaseInvoices(
    businessId: string,
    options?: {
      supplierId?: string;
      invoiceStatus?: string;
      paymentStatus?: string;
      page?: number;
      limit?: number;
    }
  ) {
    const page = Math.max(1, Number(options?.page) || 1);
    const limit = Math.min(100, Math.max(1, Number(options?.limit) || 20));
    const skip = (page - 1) * limit;

    const where: any = {
      business_id: businessId,
      deleted_at: null,
      ...(options?.supplierId ? { supplier_id: options.supplierId } : {}),
      ...(options?.invoiceStatus ? { invoice_status: options.invoiceStatus } : {}),
      ...(options?.paymentStatus ? { payment_status: options.paymentStatus } : {}),
    };

    const [items, total] = await Promise.all([
      prisma.purchase_invoices.findMany({
        where,
        skip,
        take: limit,
        orderBy: { invoice_date: 'desc' },
        include: {
          suppliers: {
            select: { id: true, supplier_code: true, supplier_name: true, contact_person: true },
          },
          purchase_orders: {
            select: { id: true, purchase_order_number: true, order_status: true },
          },
          purchase_invoice_items: true,
          supplier_payments: true,
        },
      }),
      prisma.purchase_invoices.count({ where }),
    ]);

    return { items, total, page, limit };
  }

  async getPurchaseInvoiceById(businessId: string, id: string, enforcedSupplierId?: string) {
    const where: any = {
      id,
      business_id: businessId,
      deleted_at: null,
    };
    if (enforcedSupplierId) {
      where.supplier_id = enforcedSupplierId;
    }

    const invoice = await prisma.purchase_invoices.findFirst({
      where,
      include: {
        suppliers: true,
        purchase_orders: true,
        purchase_invoice_items: true,
        supplier_payments: {
          include: { payment_methods: true },
        },
      },
    });

    if (!invoice) {
      throw new AppError(404, 'Purchase invoice not found or access denied.');
    }
    return invoice;
  }

  async createPurchaseInvoice(
    businessId: string,
    data: CreatePurchaseInvoiceInput,
    enforcedSupplierId?: string
  ) {
    const supplierId = enforcedSupplierId || data.supplierId;
    if (!supplierId) {
      throw new AppError(400, 'Supplier ID is required.');
    }

    // Verify supplier belongs to business
    const supplier = await prisma.suppliers.findFirst({
      where: { id: supplierId, business_id: businessId, deleted_at: null },
    });
    if (!supplier) {
      throw new AppError(400, 'Invalid supplier.');
    }

    // Check unique supplier invoice number for this business and supplier
    const existing = await prisma.purchase_invoices.findFirst({
      where: {
        business_id: businessId,
        supplier_id: supplierId,
        supplier_invoice_number: data.supplierInvoiceNumber.trim(),
        deleted_at: null,
      },
    });
    if (existing) {
      throw new AppError(
        409,
        `Invoice number '${data.supplierInvoiceNumber}' already submitted for this supplier.`
      );
    }

    const invoiceId = data.id || randomUUID();
    const invoiceDate = data.invoiceDate ? new Date(data.invoiceDate) : new Date();

    return await prisma.$transaction(async (tx) => {
      let subtotalPaise = 0n;
      let totalTaxPaise = 0n;

      const preparedItems = [];
      for (const item of data.items) {
        const quantityInt = Math.round(item.quantity * 1000);
        const unitPriceBig = BigInt(item.unitPricePaise);
        const lineGrossPaise = (BigInt(quantityInt) * unitPriceBig) / 1000n;
        const gstRateInt = Math.round(item.gstPercentage * 100);
        const lineTaxPaise = (lineGrossPaise * BigInt(gstRateInt)) / 10000n;
        const lineTotalPaise = lineGrossPaise + lineTaxPaise;

        subtotalPaise += lineGrossPaise;
        totalTaxPaise += lineTaxPaise;

        preparedItems.push({
          id: item.id || randomUUID(),
          purchase_invoice_id: invoiceId,
          product_id: item.productId || null,
          product_name_snapshot: item.productName,
          quantity: item.quantity,
          unit_price_paise: unitPriceBig,
          gst_percentage_snapshot: item.gstPercentage,
          tax_amount_paise: lineTaxPaise,
          total_amount_paise: lineTotalPaise,
        });
      }

      const discountBig = BigInt(data.discountPaise ?? 0);
      const grandTotalPaise =
        subtotalPaise + totalTaxPaise > discountBig ? subtotalPaise + totalTaxPaise - discountBig : 0n;

      // Supplier submissions enter 'PENDING_VERIFICATION'; Admin creation enters 'RECEIVED'
      const invoiceStatus = enforcedSupplierId ? 'PENDING_VERIFICATION' : 'RECEIVED';

      const invoice = await tx.purchase_invoices.create({
        data: {
          id: invoiceId,
          business_id: businessId,
          supplier_id: supplierId,
          purchase_order_id: data.purchaseOrderId || null,
          supplier_invoice_number: data.supplierInvoiceNumber.trim(),
          internal_reference_number: data.internalReferenceNumber?.trim() || null,
          invoice_date: invoiceDate,
          subtotal_paise: subtotalPaise,
          discount_paise: discountBig,
          tax_amount_paise: totalTaxPaise,
          grand_total_paise: grandTotalPaise,
          amount_paid_paise: 0n,
          balance_due_paise: grandTotalPaise,
          invoice_status: invoiceStatus,
          payment_status: 'UNPAID',
        },
      });

      for (const it of preparedItems) {
        await tx.purchase_invoice_items.create({ data: it });
      }

      return {
        invoice,
        items: preparedItems,
      };
    });
  }

  async submitPurchaseInvoice(businessId: string, id: string, enforcedSupplierId: string) {
    const invoice = await this.getPurchaseInvoiceById(businessId, id, enforcedSupplierId);
    if (invoice.invoice_status === 'APPROVED' || invoice.invoice_status === 'PAID') {
      throw new AppError(400, `Cannot resubmit invoice in '${invoice.invoice_status}' status.`);
    }

    return prisma.purchase_invoices.update({
      where: { id },
      data: { invoice_status: 'PENDING_VERIFICATION' },
    });
  }

  async approvePurchaseInvoice(businessId: string, id: string) {
    const invoice = await this.getPurchaseInvoiceById(businessId, id);
    if (invoice.invoice_status === 'APPROVED') {
      return invoice;
    }

    return prisma.purchase_invoices.update({
      where: { id },
      data: { invoice_status: 'APPROVED' },
    });
  }

  async rejectPurchaseInvoice(businessId: string, id: string, notes?: string) {
    const invoice = await this.getPurchaseInvoiceById(businessId, id);
    if (invoice.payment_status === 'PAID' || invoice.amount_paid_paise > 0n) {
      throw new AppError(400, 'Cannot reject invoice that has recorded payments.');
    }

    return prisma.purchase_invoices.update({
      where: { id },
      data: {
        invoice_status: 'REJECTED',
        internal_reference_number: notes
          ? `[Rejected: ${notes}] ${invoice.internal_reference_number || ''}`.trim()
          : invoice.internal_reference_number,
      },
    });
  }

  // ==========================================
  // 3. SUPPLIER PAYMENTS (STRICT SEPARATION)
  // ==========================================

  async recordSupplierPayment(businessId: string, userId: string, data: RecordSupplierPaymentInput) {
    const paymentAmountBig = BigInt(data.amountPaise);
    if (paymentAmountBig <= 0n) {
      throw new AppError(400, 'Payment amount must be greater than zero.');
    }

    // 1. Verify Supplier belongs to Business
    const supplier = await prisma.suppliers.findFirst({
      where: { id: data.supplierId, business_id: businessId, deleted_at: null },
    });
    if (!supplier) {
      throw new AppError(400, 'Invalid supplier: supplier does not exist or belongs to another business.');
    }

    return await prisma.$transaction(async (tx) => {
      let purchaseInvoice = null;
      if (data.purchaseInvoiceId) {
        purchaseInvoice = await tx.purchase_invoices.findFirst({
          where: {
            id: data.purchaseInvoiceId,
            business_id: businessId,
            supplier_id: supplier.id,
            deleted_at: null,
          },
        });
        if (!purchaseInvoice) {
          throw new AppError(400, 'Purchase invoice not found or does not belong to this supplier.');
        }

        // An unapproved supplier invoice cannot be paid!
        if (purchaseInvoice.invoice_status !== 'APPROVED') {
          throw new AppError(
            400,
            `Cannot pay unapproved invoice. Current invoice status is '${purchaseInvoice.invoice_status}'. Invoice must be APPROVED first.`
          );
        }

        const balanceDue = BigInt(purchaseInvoice.balance_due_paise);
        if (paymentAmountBig > balanceDue) {
          throw new AppError(
            400,
            `Payment amount (${paymentAmountBig} paise) exceeds invoice outstanding balance (${balanceDue} paise).`
          );
        }
      }

      // Record in dedicated supplier_payments table (Strict Separation from sales payments)
      const payment = await tx.supplier_payments.create({
        data: {
          id: data.id || randomUUID(),
          business_id: businessId,
          supplier_id: supplier.id,
          purchase_invoice_id: data.purchaseInvoiceId || null,
          amount_paise: paymentAmountBig,
          payment_method_id: data.paymentMethodId,
          payment_reference: data.paymentReference || null,
          payment_status: 'COMPLETED',
          paid_by_user_id: userId,
          paid_at: new Date(),
          notes: data.notes || null,
        },
      });

      // Update invoice balance if payment was against a specific invoice
      if (purchaseInvoice) {
        const newPaidAmount = BigInt(purchaseInvoice.amount_paid_paise) + paymentAmountBig;
        const newBalanceDue = BigInt(purchaseInvoice.grand_total_paise) - newPaidAmount;
        const newPaymentStatus = newBalanceDue <= 0n ? 'PAID' : 'PARTIALLY_PAID';

        await tx.purchase_invoices.update({
          where: { id: purchaseInvoice.id },
          data: {
            amount_paid_paise: newPaidAmount,
            balance_due_paise: newBalanceDue,
            payment_status: newPaymentStatus,
          },
        });
      }

      return payment;
    });
  }

  async listSupplierPayments(
    businessId: string,
    options?: { supplierId?: string; page?: number; limit?: number }
  ) {
    const page = Math.max(1, Number(options?.page) || 1);
    const limit = Math.min(100, Math.max(1, Number(options?.limit) || 20));
    const skip = (page - 1) * limit;

    const where: any = {
      business_id: businessId,
      ...(options?.supplierId ? { supplier_id: options.supplierId } : {}),
    };

    const [items, total] = await Promise.all([
      prisma.supplier_payments.findMany({
        where,
        skip,
        take: limit,
        orderBy: { paid_at: 'desc' },
        include: {
          suppliers: {
            select: { id: true, supplier_code: true, supplier_name: true },
          },
          purchase_invoices: {
            select: { id: true, supplier_invoice_number: true, grand_total_paise: true },
          },
          payment_methods: true,
        },
      }),
      prisma.supplier_payments.count({ where }),
    ]);

    return { items, total, page, limit };
  }

  async getSupplierOutstandingBalance(businessId: string, supplierId: string) {
    const invoices = await prisma.purchase_invoices.findMany({
      where: {
        business_id: businessId,
        supplier_id: supplierId,
        deleted_at: null,
      },
      select: {
        grand_total_paise: true,
        amount_paid_paise: true,
        balance_due_paise: true,
        invoice_status: true,
        payment_status: true,
      },
    });

    let totalBilledPaise = 0n;
    let totalPaidPaise = 0n;
    let totalOutstandingPaise = 0n;

    for (const inv of invoices) {
      if (inv.invoice_status === 'APPROVED' || inv.payment_status === 'PAID') {
        totalBilledPaise += BigInt(inv.grand_total_paise);
        totalPaidPaise += BigInt(inv.amount_paid_paise);
        totalOutstandingPaise += BigInt(inv.balance_due_paise);
      }
    }

    return {
      supplierId,
      totalBilledPaise: totalBilledPaise.toString(),
      totalPaidPaise: totalPaidPaise.toString(),
      totalOutstandingPaise: totalOutstandingPaise.toString(),
      invoiceCount: invoices.length,
    };
  }
}

export const purchasesService = new PurchasesService();
