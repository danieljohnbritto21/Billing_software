import { prisma } from '../../config/prisma';
import { AppError } from '../../middleware/error.middleware';

export class TransactionsService {
  async getSalesTransaction(businessId: string, idOrTransactionId: string) {
    let order = await prisma.orders.findFirst({
      where: {
        business_id: businessId,
        OR: [
          { id: idOrTransactionId },
          { order_number: idOrTransactionId },
        ],
        deleted_at: null,
      },
      include: {
        order_items: true,
        invoices: {
          include: {
            invoice_items: true,
            payments: true,
            bill_notes: true,
          },
        },
        kot_records: {
          orderBy: { printed_at: 'asc' },
        },
        payments: true,
      },
    });

    let invoice = null;
    if (!order) {
      invoice = await prisma.invoices.findFirst({
        where: {
          business_id: businessId,
          OR: [
            { id: idOrTransactionId },
            { invoice_number: idOrTransactionId },
          ],
        },
        include: {
          invoice_items: true,
          payments: true,
          bill_notes: true,
          orders: {
            include: {
              order_items: true,
              kot_records: { orderBy: { printed_at: 'asc' } },
              payments: true,
            },
          },
          kot_records: { orderBy: { printed_at: 'asc' } },
        },
      });

      if (invoice?.orders) {
        order = invoice.orders as any;
      }
    }

    if (!order && !invoice) {
      throw new AppError(404, 'Sales transaction not found.');
    }

    const transactionId =
      (order as any)?.transaction_id ||
      order?.id ||
      (invoice as any)?.transaction_id ||
      invoice?.order_id ||
      invoice?.id;

    const orderId = order?.id || invoice?.order_id;
    const invoiceId = invoice?.id || order?.invoices?.[0]?.id;

    const kotRecords = await prisma.kot_records.findMany({
      where: {
        OR: [
          ...(orderId ? [{ order_id: orderId }] : []),
          ...(invoiceId ? [{ invoice_id: invoiceId }] : []),
        ],
      },
      orderBy: { printed_at: 'asc' },
    });

    const activeInvoice = invoice || order?.invoices?.[0] || null;

    return {
      transactionId,
      salesOrder: order
        ? {
            id: order.id,
            orderNumber: order.order_number,
            orderType: order.order_type,
            orderStatus: order.order_status,
            paymentStatus: order.payment_status,
            subtotalPaise: order.subtotal_paise.toString(),
            grandTotalPaise: order.grand_total_paise.toString(),
            amountPaidPaise: order.amount_paid_paise.toString(),
            balanceDuePaise: order.balance_due_paise.toString(),
            orderedAt: order.ordered_at,
            items: order.order_items,
          }
        : null,
      kotHistory: kotRecords.map((k) => ({
        id: k.id,
        kotNumber: k.kot_number,
        orderType: k.order_type,
        tableNumber: k.table_number,
        items: k.items_json,
        printedAt: k.printed_at,
        reprintCount: k.reprinted_count,
      })),
      customerInvoice: activeInvoice
        ? {
            id: activeInvoice.id,
            invoiceNumber: activeInvoice.invoice_number,
            orderType: activeInvoice.order_type,
            orderStatus: activeInvoice.order_status,
            paymentStatus: activeInvoice.payment_status,
            paymentMethod: activeInvoice.payment_method,
            subtotalPaise: activeInvoice.subtotal_paise.toString(),
            taxableAmountPaise: activeInvoice.taxable_amount_paise.toString(),
            grandTotalPaise: activeInvoice.grand_total_paise.toString(),
            paidAmountPaise: activeInvoice.paid_amount_paise.toString(),
            tableNumber: activeInvoice.table_number,
            customerName: activeInvoice.customer_name,
            customerPhone: activeInvoice.customer_phone,
            createdAt: activeInvoice.created_at,
            items: (activeInvoice as any).invoice_items || [],
            payments: (activeInvoice as any).payments || [],
          }
        : null,
      paymentStatus: activeInvoice?.payment_status || order?.payment_status || 'Pending',
    };
  }

  async getProcurementTransaction(
    businessId: string,
    idOrTransactionId: string,
    enforcedSupplierId?: string
  ) {
    let pi = await prisma.purchase_invoices.findFirst({
      where: {
        business_id: businessId,
        OR: [
          { id: idOrTransactionId },
          { supplier_invoice_number: idOrTransactionId },
          ...(idOrTransactionId ? [{ purchase_order_id: idOrTransactionId }] : []),
        ],
        deleted_at: null,
        ...(enforcedSupplierId ? { supplier_id: enforcedSupplierId } : {}),
      },
      include: {
        suppliers: true,
        purchase_orders: {
          include: {
            purchase_order_items: true,
          },
        },
        purchase_invoice_items: true,
        supplier_payments: {
          include: { payment_methods: true },
        },
      },
    });

    let po: any = null;
    if (!pi) {
      po = await prisma.purchase_orders.findFirst({
        where: {
          business_id: businessId,
          OR: [
            { id: idOrTransactionId },
            { purchase_order_number: idOrTransactionId },
          ],
          deleted_at: null,
          ...(enforcedSupplierId ? { supplier_id: enforcedSupplierId } : {}),
        },
        include: {
          suppliers: true,
          purchase_order_items: true,
          purchase_invoices: {
            include: {
              purchase_invoice_items: true,
              supplier_payments: true,
            },
          },
        },
      });

      if (po?.purchase_invoices?.[0]) {
        pi = po.purchase_invoices[0] as any;
      }
    }

    if (!pi && !po) {
      throw new AppError(404, 'Procurement transaction not found or access denied.');
    }

    const supplier = pi?.suppliers || po?.suppliers;
    const activePo = po || pi?.purchase_orders || null;
    const transactionId =
      (pi as any)?.transaction_id ||
      pi?.purchase_order_id ||
      pi?.id ||
      po?.id;

    return {
      transactionId,
      purchaseOrder: activePo
        ? {
            id: activePo.id,
            poNumber: activePo.purchase_order_number,
            orderStatus: activePo.order_status,
            orderedAt: activePo.ordered_at,
            grandTotalPaise: activePo.grand_total_paise?.toString() || '0',
            items: activePo.purchase_order_items || [],
          }
        : null,
      supplier: supplier
        ? {
            id: supplier.id,
            supplierCode: supplier.supplier_code,
            supplierName: supplier.supplier_name,
            contactPerson: supplier.contact_person,
            phone: supplier.phone,
          }
        : null,
      supplierInvoiceNumber: pi ? pi.supplier_invoice_number : null,
      supplierInvoice: pi
        ? {
            id: pi.id,
            supplierInvoiceNumber: pi.supplier_invoice_number,
            invoiceDate: pi.invoice_date,
            invoiceStatus: pi.invoice_status,
            paymentStatus: pi.payment_status,
            subtotalPaise: pi.subtotal_paise.toString(),
            taxAmountPaise: pi.tax_amount_paise.toString(),
            grandTotalPaise: pi.grand_total_paise.toString(),
            amountPaidPaise: pi.amount_paid_paise.toString(),
            balanceDuePaise: pi.balance_due_paise.toString(),
            items: pi.purchase_invoice_items,
          }
        : null,
      grn: pi
        ? {
            grnNumber: `GRN-${pi.supplier_invoice_number.replace(/[^a-zA-Z0-9]/g, '')}`,
            receivedAt: pi.created_at,
            status: pi.invoice_status === 'APPROVED' ? 'ACCEPTED' : 'PENDING_INSPECTION',
          }
        : null,
      supplierPaymentHistory: pi?.supplier_payments || [],
    };
  }
}

export const transactionsService = new TransactionsService();
