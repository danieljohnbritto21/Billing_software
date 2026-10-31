import { prisma } from '../../config/prisma';
import { AppError } from '../../middleware/error.middleware';

export class BusinessesService {
  async getProfile(businessId: string) {
    const business = await prisma.businesses.findUnique({
      where: { id: businessId },
      include: {
        business_settings: true,
      },
    });
    if (!business) {
      throw new AppError(404, 'Business not found');
    }
    return business;
  }

  async updateProfile(
    businessId: string,
    data: {
      name?: string;
      tagline?: string;
      address?: string;
      phone?: string;
      gstin?: string;
      invoicePrefix?: string;
      printerWidth?: string;
    }
  ) {
    return prisma.businesses.update({
      where: { id: businessId },
      data: {
        ...(data.name ? { name: data.name } : {}),
        ...(data.tagline !== undefined ? { tagline: data.tagline } : {}),
        ...(data.address !== undefined ? { address: data.address } : {}),
        ...(data.phone !== undefined ? { phone: data.phone } : {}),
        ...(data.gstin !== undefined ? { gstin: data.gstin } : {}),
        ...(data.invoicePrefix !== undefined ? { invoice_prefix: data.invoicePrefix } : {}),
        ...(data.printerWidth !== undefined ? { printer_width: data.printerWidth } : {}),
      },
    });
  }

  async getAdminStats(businessId: string) {
    const [
      totalInvoices,
      totalSalesAgg,
      pendingInvoices,
      totalCustomers,
      totalProducts,
    ] = await Promise.all([
      prisma.invoices.count({
        where: { business_id: businessId, is_cancelled: false },
      }),
      prisma.invoices.aggregate({
        where: { business_id: businessId, is_cancelled: false },
        _sum: {
          grand_total_paise: true,
          paid_amount_paise: true,
        },
      }),
      prisma.invoices.count({
        where: {
          business_id: businessId,
          is_cancelled: false,
          payment_status: { in: ['Pending', 'Partially Paid'] },
        },
      }),
      prisma.customers.count({
        where: { business_id: businessId, deleted_at: null },
      }),
      prisma.products.count({
        where: { business_id: businessId, deleted_at: null },
      }),
    ]);

    const totalSalesPaise = totalSalesAgg._sum.grand_total_paise ?? 0n;
    const totalPaidPaise = totalSalesAgg._sum.paid_amount_paise ?? 0n;
    const pendingAmountPaise =
      totalSalesPaise > totalPaidPaise ? totalSalesPaise - totalPaidPaise : 0n;

    return {
      totalInvoices,
      totalSalesPaise: totalSalesPaise.toString(),
      totalPaidPaise: totalPaidPaise.toString(),
      pendingAmountPaise: pendingAmountPaise.toString(),
      pendingInvoicesCount: pendingInvoices,
      totalCustomers,
      totalProducts,
    };
  }
}

export const businessesService = new BusinessesService();
