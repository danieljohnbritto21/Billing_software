import { randomUUID } from 'crypto';
import { prisma } from '../../config/prisma';
import { AppError } from '../../middleware/error.middleware';
import {
  CreateOrderInput,
  UpdateOrderInput,
  RecordOrderPaymentInput,
  AddOrderItemsInput,
} from './orders.schema';

export class OrdersService {
  async listOrders(
    businessId: string,
    options?: {
      orderStatus?: string;
      orderType?: string;
      paymentStatus?: string;
      startDate?: string;
      endDate?: string;
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
      ...(options?.orderStatus ? { order_status: options.orderStatus } : {}),
      ...(options?.orderType ? { order_type: options.orderType } : {}),
      ...(options?.paymentStatus ? { payment_status: options.paymentStatus } : {}),
      ...(options?.startDate || options?.endDate
        ? {
            ordered_at: {
              ...(options?.startDate ? { gte: new Date(options.startDate) } : {}),
              ...(options?.endDate ? { lte: new Date(options.endDate) } : {}),
            },
          }
        : {}),
    };

    const [items, total] = await Promise.all([
      prisma.orders.findMany({
        where,
        skip,
        take: limit,
        orderBy: { ordered_at: 'desc' },
        include: {
          order_items: true,
          invoices: {
            select: {
              id: true,
              invoice_number: true,
              payment_status: true,
              order_status: true,
              grand_total_paise: true,
              paid_amount_paise: true,
            },
          },
          payments: true,
        },
      }),
      prisma.orders.count({ where }),
    ]);

    return {
      items,
      total,
      page,
      limit,
    };
  }

  async getOrderById(businessId: string, orderId: string) {
    const order = await prisma.orders.findFirst({
      where: { id: orderId, business_id: businessId, deleted_at: null },
      include: {
        order_items: {
          include: {
            products: {
              select: { id: true, name: true, code: true, unit: true },
            },
          },
        },
        invoices: {
          include: {
            invoice_items: true,
            payments: true,
          },
        },
        payments: true,
        kot_records: true,
      },
    });

    if (!order) {
      throw new AppError(404, 'Order not found.');
    }
    return order;
  }

  async createOrder(
    businessId: string,
    userId: string,
    deviceId: string | undefined,
    data: CreateOrderInput
  ) {
    const orderId = data.id || randomUUID();
    const orderedAt = new Date();

    return await prisma.$transaction(async (tx) => {
      // 1. Calculate totals on server from validated line items
      let subtotalPaise = 0n;
      let totalItemDiscountPaise = 0n;
      let totalTaxableAmountPaise = 0n;
      let totalTaxPaise = 0n;

      const preparedItems: any[] = [];

      for (const item of data.items) {
        // Resolve product and snapshot supplier
        let supplierId: string | null = null;
        if (item.productId) {
          const product = await tx.products.findFirst({
            where: { id: item.productId, business_id: businessId },
          });
          if (product) {
            supplierId = product.supplier_id;
          }
        }

        const quantityInt = Math.round(item.quantity * 1000); // 3 decimals representation
        const unitPriceBig = BigInt(item.unitPricePaise);
        const itemDiscountBig = BigInt(item.discountPaise ?? 0);

        // line subtotal = (quantity * unitPrice)
        const lineGrossPaise = (BigInt(quantityInt) * unitPriceBig) / 1000n;
        const lineTaxablePaise = lineGrossPaise > itemDiscountBig ? lineGrossPaise - itemDiscountBig : 0n;
        const gstRateInt = Math.round(item.gstRatePercent * 100);
        const lineTaxPaise = (lineTaxablePaise * BigInt(gstRateInt)) / 10000n;
        const lineTotalPaise = lineTaxablePaise + lineTaxPaise;

        subtotalPaise += lineGrossPaise;
        totalItemDiscountPaise += itemDiscountBig;
        totalTaxableAmountPaise += lineTaxablePaise;
        totalTaxPaise += lineTaxPaise;

        preparedItems.push({
          id: item.id || randomUUID(),
          productId: item.productId,
          supplierId,
          productName: item.productName,
          productCode: item.productCode || null,
          quantity: item.quantity,
          unit: item.unit ?? 'plate',
          unitPricePaise: unitPriceBig,
          discountPaise: itemDiscountBig,
          gstPercentageSnapshot: item.gstRatePercent ?? 0,
          taxableAmountPaise: lineTaxablePaise,
          taxAmountPaise: lineTaxPaise,
          totalAmountPaise: lineTotalPaise,
          specialInstructions: item.specialInstructions || null,
        });
      }

      const billDiscountBig = BigInt(data.billDiscountPaise ?? 0);
      const grandTotalPaise =
        totalTaxableAmountPaise + totalTaxPaise > billDiscountBig
          ? totalTaxableAmountPaise + totalTaxPaise - billDiscountBig
          : 0n;

      const initialPaidBig = BigInt(data.amountPaidPaise ?? 0);
      const balanceDueBig = grandTotalPaise > initialPaidBig ? grandTotalPaise - initialPaidBig : 0n;

      const paymentStatus =
        initialPaidBig >= grandTotalPaise && grandTotalPaise > 0n
          ? 'Paid'
          : initialPaidBig > 0n
          ? 'Partially Paid'
          : 'Pending';

      // 2. Generate Sequential Order Number
      let orderNumber = data.orderNumber;
      if (!orderNumber) {
        const orderCount = await tx.orders.count({ where: { business_id: businessId } });
        orderNumber = `ORD-${String(orderCount + 1).padStart(5, '0')}`;
      }

      // 3. Create Orders record
      const order = await tx.orders.create({
        data: {
          id: orderId,
          business_id: businessId,
          order_number: orderNumber,
          created_by_user_id: userId,
          device_id: deviceId || null,
          dining_table_id: data.diningTableId || null,
          order_type: data.orderType,
          order_status: data.createInvoiceImmediately && paymentStatus === 'Paid' ? 'Completed' : 'Active',
          subtotal_paise: subtotalPaise,
          item_discount_paise: totalItemDiscountPaise,
          bill_discount_paise: billDiscountBig,
          taxable_amount_paise: totalTaxableAmountPaise,
          total_tax_paise: totalTaxPaise,
          cgst_paise: totalTaxPaise / 2n,
          sgst_paise: totalTaxPaise / 2n,
          grand_total_paise: grandTotalPaise,
          amount_paid_paise: initialPaidBig,
          balance_due_paise: balanceDueBig,
          payment_status: paymentStatus,
          notes: data.notes || null,
          ordered_at: orderedAt,
        },
      });

      // 4. Create Order Items
      for (const it of preparedItems) {
        await tx.order_items.create({
          data: {
            id: it.id,
            business_id: businessId,
            order_id: orderId,
            product_id: it.productId,
            supplier_id: it.supplierId,
            product_name_snapshot: it.productName,
            product_code_snapshot: it.productCode,
            quantity: it.quantity,
            unit: it.unit,
            unit_price_paise: it.unitPricePaise,
            discount_paise: it.discountPaise,
            gst_percentage_snapshot: it.gstPercentageSnapshot,
            taxable_amount_paise: it.taxableAmountPaise,
            tax_amount_paise: it.taxAmountPaise,
            total_amount_paise: it.totalAmountPaise,
            special_instructions: it.specialInstructions,
          },
        });
      }

      let createdInvoice = null;

      // 5. Create Invoices record if requested
      if (data.createInvoiceImmediately) {
        const invCount = await tx.invoices.count({ where: { business_id: businessId } });
        const invoiceNumber = `INV-${String(invCount + 1).padStart(5, '0')}`;
        const invoiceId = randomUUID();

        // Initial status is Pending so database trigger does not prevent inserting items
        createdInvoice = await tx.invoices.create({
          data: {
            id: invoiceId,
            business_id: businessId,
            order_id: orderId,
            device_id: deviceId || null,
            invoice_number: invoiceNumber,
            order_type: data.orderType,
            order_status: 'Pending',
            payment_status: 'Pending',
            payment_method: data.paymentMethod,
            subtotal_paise: subtotalPaise,
            item_discount_total_paise: totalItemDiscountPaise,
            bill_discount_paise: billDiscountBig,
            taxable_amount_paise: totalTaxableAmountPaise,
            cgst_paise: totalTaxPaise / 2n,
            sgst_paise: totalTaxPaise / 2n,
            grand_total_paise: grandTotalPaise,
            paid_amount_paise: initialPaidBig,
            idempotency_key: data.idempotencyKey || `auto-inv-${orderId}`,
            created_at: orderedAt,
          },
        });

        // Create Invoice Items linked to Order Items
        for (const it of preparedItems) {
          await tx.invoice_items.create({
            data: {
              id: randomUUID(),
              invoice_id: invoiceId,
              order_item_id: it.id,
              product_id: it.productId,
              product_name: it.productName,
              product_code: it.productCode,
              unit: it.unit,
              unit_price_paise: it.unitPricePaise,
              quantity: it.quantity,
              discount_paise: it.discountPaise,
              gst_rate_percent: it.gstPercentageSnapshot,
              is_tax_inclusive: true,
              taxable_amount_paise: it.taxableAmountPaise,
              tax_amount_paise: it.taxAmountPaise,
              total_amount_paise: it.totalAmountPaise,
            },
          });
        }

        // If paid, record payment linked to both order and invoice
        if (initialPaidBig > 0n) {
          await tx.payments.create({
            data: {
              id: randomUUID(),
              invoice_id: invoiceId,
              order_id: orderId,
              amount_paise: initialPaidBig,
              payment_method: data.paymentMethod,
              idempotency_key: data.idempotencyKey ? `${data.idempotencyKey}-initial` : `pay-${orderId}`,
              created_at: orderedAt,
            },
          });
        }

        // Update invoice to final status now that items and payments are recorded
        createdInvoice = await tx.invoices.update({
          where: { id: invoiceId },
          data: {
            order_status: paymentStatus === 'Paid' ? 'Completed' : 'Pending',
            payment_status: paymentStatus,
          },
        });
      }

      return {
        order,
        items: preparedItems,
        invoice: createdInvoice,
        transactionId: (order as any).transaction_id || order.id,
      };
    });
  }

  async addOrderItems(businessId: string, orderId: string, data: AddOrderItemsInput) {
    const order = await this.getOrderById(businessId, orderId);
    if (order.order_status === 'Completed' || order.order_status === 'Cancelled') {
      throw new AppError(400, `Cannot add items to an order in '${order.order_status}' status.`);
    }

    return await prisma.$transaction(async (tx) => {
      let additionalSubtotalPaise = 0n;
      let additionalItemDiscountPaise = 0n;
      let additionalTaxableAmountPaise = 0n;
      let additionalTaxPaise = 0n;

      const preparedItems: any[] = [];

      for (const item of data.items) {
        let supplierId: string | null = null;
        if (item.productId) {
          const product = await tx.products.findFirst({
            where: { id: item.productId, business_id: businessId },
          });
          if (product) {
            supplierId = product.supplier_id;
          }
        }

        const quantityInt = Math.round(item.quantity * 1000);
        const unitPriceBig = BigInt(item.unitPricePaise);
        const itemDiscountBig = BigInt(item.discountPaise ?? 0);

        const lineGrossPaise = (BigInt(quantityInt) * unitPriceBig) / 1000n;
        const lineTaxablePaise = lineGrossPaise > itemDiscountBig ? lineGrossPaise - itemDiscountBig : 0n;
        const gstRateInt = Math.round(item.gstRatePercent * 100);
        const lineTaxPaise = (lineTaxablePaise * BigInt(gstRateInt)) / 10000n;
        const lineTotalPaise = lineTaxablePaise + lineTaxPaise;

        additionalSubtotalPaise += lineGrossPaise;
        additionalItemDiscountPaise += itemDiscountBig;
        additionalTaxableAmountPaise += lineTaxablePaise;
        additionalTaxPaise += lineTaxPaise;

        const newOrderItemId = item.id || randomUUID();
        const createdOrderItem = await tx.order_items.create({
          data: {
            id: newOrderItemId,
            business_id: businessId,
            order_id: orderId,
            product_id: item.productId || null,
            supplier_id: supplierId,
            product_name_snapshot: item.productName,
            product_code_snapshot: item.productCode || null,
            quantity: item.quantity,
            unit: item.unit ?? 'plate',
            unit_price_paise: unitPriceBig,
            discount_paise: itemDiscountBig,
            gst_percentage_snapshot: item.gstRatePercent ?? 0,
            taxable_amount_paise: lineTaxablePaise,
            tax_amount_paise: lineTaxPaise,
            total_amount_paise: lineTotalPaise,
            special_instructions: item.specialInstructions || null,
          },
        });

        preparedItems.push({
          ...createdOrderItem,
          productName: item.productName,
          quantity: item.quantity,
          specialInstructions: item.specialInstructions || null,
        });
      }

      const newSubtotalPaise = BigInt(order.subtotal_paise) + additionalSubtotalPaise;
      const newItemDiscountPaise = BigInt(order.item_discount_paise) + additionalItemDiscountPaise;
      const newTaxableAmountPaise = BigInt(order.taxable_amount_paise) + additionalTaxableAmountPaise;
      const newTotalTaxPaise = BigInt(order.total_tax_paise) + additionalTaxPaise;
      const billDiscountBig = BigInt(order.bill_discount_paise);
      const newGrandTotalPaise =
        newTaxableAmountPaise + newTotalTaxPaise > billDiscountBig
          ? newTaxableAmountPaise + newTotalTaxPaise - billDiscountBig
          : 0n;
      const currentPaidBig = BigInt(order.amount_paid_paise);
      const newBalanceDueBig = newGrandTotalPaise > currentPaidBig ? newGrandTotalPaise - currentPaidBig : 0n;
      const newPaymentStatus =
        currentPaidBig >= newGrandTotalPaise && newGrandTotalPaise > 0n
          ? 'Paid'
          : currentPaidBig > 0n
          ? 'Partially Paid'
          : 'Pending';

      const updatedOrder = await tx.orders.update({
        where: { id: orderId },
        data: {
          subtotal_paise: newSubtotalPaise,
          item_discount_paise: newItemDiscountPaise,
          taxable_amount_paise: newTaxableAmountPaise,
          total_tax_paise: newTotalTaxPaise,
          cgst_paise: newTotalTaxPaise / 2n,
          sgst_paise: newTotalTaxPaise / 2n,
          grand_total_paise: newGrandTotalPaise,
          balance_due_paise: newBalanceDueBig,
          payment_status: newPaymentStatus,
        },
      });

      // If an invoice exists, update it and create matching invoice items
      let existingInvoice = await tx.invoices.findFirst({
        where: { order_id: orderId, business_id: businessId },
      });

      if (existingInvoice) {
        for (const it of preparedItems) {
          await tx.invoice_items.create({
            data: {
              id: randomUUID(),
              invoice_id: existingInvoice.id,
              order_item_id: it.id,
              product_id: it.product_id,
              product_name: it.product_name_snapshot,
              product_code: it.product_code_snapshot,
              unit: it.unit,
              unit_price_paise: it.unit_price_paise,
              quantity: it.quantity,
              discount_paise: it.discount_paise,
              gst_rate_percent: Number(it.gst_percentage_snapshot),
              is_tax_inclusive: true,
              taxable_amount_paise: it.taxable_amount_paise,
              tax_amount_paise: it.tax_amount_paise,
              total_amount_paise: it.total_amount_paise,
            },
          });
        }

        existingInvoice = await tx.invoices.update({
          where: { id: existingInvoice.id },
          data: {
            subtotal_paise: newSubtotalPaise,
            item_discount_total_paise: newItemDiscountPaise,
            taxable_amount_paise: newTaxableAmountPaise,
            cgst_paise: newTotalTaxPaise / 2n,
            sgst_paise: newTotalTaxPaise / 2n,
            grand_total_paise: newGrandTotalPaise,
            payment_status: newPaymentStatus,
          },
        });
      }

      // Generate incremental KOT for newly added items
      let generatedKot = null;
      if (data.generateKot !== false) {
        const totalKotCount = await tx.kot_records.count({
          where: {
            OR: [
              ...(existingInvoice ? [{ invoice_id: existingInvoice.id }] : []),
              { order_id: orderId },
            ],
          },
        });

        const kotNumber = `KOT-${String(totalKotCount + 1).padStart(4, '0')}`;

        generatedKot = await tx.kot_records.create({
          data: {
            id: randomUUID(),
            order_id: orderId,
            invoice_id: existingInvoice?.id || null,
            kot_number: kotNumber,
            table_number: order.dining_table_id ? 'Table' : null,
            order_type: order.order_type,
            items_json: preparedItems.map((p) => ({
              orderItemId: p.id,
              productName: p.product_name_snapshot,
              quantity: Number(p.quantity),
              notes: p.special_instructions || undefined,
            })),
          },
        });
      }

      return {
        order: updatedOrder,
        newItems: preparedItems,
        invoice: existingInvoice,
        kot: generatedKot,
        transactionId: (updatedOrder as any).transaction_id || updatedOrder.id,
      };
    });
  }

  async updateOrder(businessId: string, orderId: string, data: UpdateOrderInput) {
    const existing = await this.getOrderById(businessId, orderId);
    if (existing.order_status === 'Completed' || existing.order_status === 'Cancelled') {
      throw new AppError(400, `Cannot update order in '${existing.order_status}' status.`);
    }

    return prisma.orders.update({
      where: { id: orderId },
      data: {
        ...(data.orderType ? { order_type: data.orderType } : {}),
        ...(data.orderStatus ? { order_status: data.orderStatus } : {}),
        ...(data.notes !== undefined ? { notes: data.notes || null } : {}),
        ...(data.diningTableId !== undefined ? { dining_table_id: data.diningTableId || null } : {}),
      },
    });
  }

  async completeOrder(businessId: string, orderId: string) {
    const order = await this.getOrderById(businessId, orderId);
    if (order.order_status === 'Completed') {
      return order;
    }

    return await prisma.$transaction(async (tx) => {
      // Check if an invoice already exists
      let invoice = await tx.invoices.findFirst({
        where: { order_id: orderId, business_id: businessId },
      });

      if (!invoice) {
        const invCount = await tx.invoices.count({ where: { business_id: businessId } });
        const invoiceNumber = `INV-${String(invCount + 1).padStart(5, '0')}`;
        const invoiceId = randomUUID();

        // Create with Pending status initially
        invoice = await tx.invoices.create({
          data: {
            id: invoiceId,
            business_id: businessId,
            order_id: orderId,
            invoice_number: invoiceNumber,
            order_type: order.order_type,
            order_status: 'Pending',
            payment_status: 'Pending',
            payment_method: 'Cash',
            subtotal_paise: order.subtotal_paise,
            item_discount_total_paise: order.item_discount_paise,
            bill_discount_paise: order.bill_discount_paise,
            taxable_amount_paise: order.taxable_amount_paise,
            cgst_paise: order.cgst_paise,
            sgst_paise: order.sgst_paise,
            grand_total_paise: order.grand_total_paise,
            paid_amount_paise: order.amount_paid_paise,
            idempotency_key: `complete-inv-${orderId}`,
            created_at: new Date(),
          },
        });

        // Clone order items to invoice items
        for (const it of order.order_items) {
          await tx.invoice_items.create({
            data: {
              id: randomUUID(),
              invoice_id: invoiceId,
              order_item_id: it.id,
              product_id: it.product_id,
              product_name: it.product_name_snapshot,
              product_code: it.product_code_snapshot,
              unit: it.unit,
              unit_price_paise: it.unit_price_paise,
              quantity: it.quantity,
              discount_paise: it.discount_paise,
              gst_rate_percent: Number(it.gst_percentage_snapshot),
              is_tax_inclusive: true,
              taxable_amount_paise: it.taxable_amount_paise,
              tax_amount_paise: it.tax_amount_paise,
              total_amount_paise: it.total_amount_paise,
            },
          });
        }

        // Finalize invoice now that items are attached
        invoice = await tx.invoices.update({
          where: { id: invoiceId },
          data: {
            order_status: 'Completed',
            payment_status: order.payment_status,
          },
        });
      } else {
        await tx.invoices.update({
          where: { id: invoice.id },
          data: { order_status: 'Completed' },
        });
      }

      return tx.orders.update({
        where: { id: orderId },
        data: { order_status: 'Completed' },
      });
    });
  }

  async recordOrderPayment(businessId: string, orderId: string, data: RecordOrderPaymentInput) {
    const order = await this.getOrderById(businessId, orderId);

    // 1. Idempotency Check
    const existingPayment = await prisma.payments.findFirst({
      where: {
        order_id: orderId,
        idempotency_key: data.idempotencyKey,
      },
    });
    if (existingPayment) {
      return {
        payment: existingPayment,
        isDuplicate: true,
        message: 'Payment already processed with this idempotency key.',
      };
    }

    const paymentAmountBig = BigInt(data.amountPaise);
    if (paymentAmountBig <= 0n) {
      throw new AppError(400, 'Payment amount must be greater than zero.');
    }

    return await prisma.$transaction(async (tx) => {
      // Find associated invoice
      let invoice = await tx.invoices.findFirst({
        where: { order_id: orderId, business_id: businessId },
      });

      if (!invoice) {
        throw new AppError(400, 'Order does not have a generated invoice. Complete order first.');
      }

      const balanceDue = BigInt(order.balance_due_paise);
      if (paymentAmountBig > balanceDue) {
        throw new AppError(
          400,
          `Payment amount (${paymentAmountBig} paise) exceeds outstanding balance (${balanceDue} paise).`
        );
      }

      // Record in sales payments table (strictly sales payments)
      const payment = await tx.payments.create({
        data: {
          id: randomUUID(),
          invoice_id: invoice.id,
          order_id: orderId,
          amount_paise: paymentAmountBig,
          payment_method: data.paymentMethod,
          reference_number: data.referenceNumber || null,
          notes: data.notes || null,
          idempotency_key: data.idempotencyKey,
          created_at: new Date(),
        },
      });

      const newPaidAmount = BigInt(order.amount_paid_paise) + paymentAmountBig;
      const newBalanceDue = BigInt(order.grand_total_paise) - newPaidAmount;
      const newStatus = newBalanceDue <= 0n ? 'Paid' : 'Partially Paid';

      // Update Order balance
      await tx.orders.update({
        where: { id: orderId },
        data: {
          amount_paid_paise: newPaidAmount,
          balance_due_paise: newBalanceDue,
          payment_status: newStatus,
        },
      });

      // Update Invoice balance
      await tx.invoices.update({
        where: { id: invoice.id },
        data: {
          paid_amount_paise: newPaidAmount,
          payment_status: newStatus,
        },
      });

      return {
        payment,
        isDuplicate: false,
        amountPaid: newPaidAmount.toString(),
        balanceDue: newBalanceDue.toString(),
        paymentStatus: newStatus,
      };
    });
  }

  async getOrderPayments(businessId: string, orderId: string) {
    await this.getOrderById(businessId, orderId);
    return prisma.payments.findMany({
      where: { order_id: orderId },
      orderBy: { created_at: 'asc' },
      include: {
        payment_methods: true,
      },
    });
  }
}

export const ordersService = new OrdersService();
