import { randomUUID } from 'crypto';
import { prisma } from '../../config/prisma';
import { AppError } from '../../middleware/error.middleware';
import { RecordPaymentInput } from './payments.schema';

export class PaymentsService {
  async listPayments(businessId: string, invoiceId?: string) {
    return prisma.payments.findMany({
      where: {
        invoices: { business_id: businessId },
        ...(invoiceId ? { invoice_id: invoiceId } : {}),
      },
      include: {
        invoices: {
          select: {
            id: true,
            invoice_number: true,
            grand_total_paise: true,
            paid_amount_paise: true,
            payment_status: true,
          },
        },
      },
      orderBy: { created_at: 'desc' },
    });
  }

  async recordPayment(businessId: string, data: RecordPaymentInput) {
    // 1. Idempotency check
    const existing = await prisma.payments.findUnique({
      where: {
        invoice_id_idempotency_key: {
          invoice_id: data.invoiceId,
          idempotency_key: data.idempotencyKey,
        },
      },
      include: {
        invoices: true,
      },
    });

    if (existing) {
      return existing; // Duplicate network call safely returns existing payment
    }

    // 2. Validate invoice belongs to this business
    const invoice = await prisma.invoices.findFirst({
      where: { id: data.invoiceId, business_id: businessId },
    });
    if (!invoice) {
      throw new AppError(404, 'Invoice not found or belongs to another business.');
    }

    if (invoice.is_cancelled) {
      throw new AppError(400, 'Cannot record payment for a cancelled invoice.');
    }

    const paymentId = data.id || randomUUID();

    return prisma.$transaction(async (tx) => {
      // 3. Create payment record
      const payment = await tx.payments.create({
        data: {
          id: paymentId,
          invoice_id: data.invoiceId,
          amount_paise: BigInt(data.amountPaise),
          payment_method: data.paymentMethod,
          reference_number: data.referenceNumber,
          notes: data.notes,
          idempotency_key: data.idempotencyKey,
        },
      });

      // 4. Update parent invoice balance and status
      const newPaidPaise = BigInt(invoice.paid_amount_paise) + BigInt(data.amountPaise);
      let newPaymentStatus = invoice.payment_status;

      if (newPaidPaise >= BigInt(invoice.grand_total_paise)) {
        newPaymentStatus = 'Paid';
      } else if (newPaidPaise > 0n) {
        newPaymentStatus = 'Partially Paid';
      }

      await tx.invoices.update({
        where: { id: data.invoiceId },
        data: {
          paid_amount_paise: newPaidPaise,
          payment_status: newPaymentStatus,
          updated_at: new Date(),
        },
      });

      return payment;
    });
  }
}

export const paymentsService = new PaymentsService();
