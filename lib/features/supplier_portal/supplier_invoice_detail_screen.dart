import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/database/app_database.dart';
import '../printer/invoice_pdf_generator.dart';
import '../purchases/purchase_repository.dart';
import '../settings/settings_repository.dart';
import '../suppliers/supplier_repository.dart';

class SupplierInvoiceDetailScreen extends ConsumerWidget {
  final String invoiceId;
  const SupplierInvoiceDetailScreen({super.key, required this.invoiceId});

  Color _getVerificationColor(String status) {
    switch (status.toUpperCase()) {
      case 'SUBMITTED':
        return Colors.blue.shade700;
      case 'PENDING_VERIFICATION':
        return Colors.blue.shade700;
      case 'APPROVED':
        return Colors.green.shade700;
      case 'REJECTED':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  Color _getPaymentColor(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
        return Colors.green.shade700;
      case 'PARTIALLY_PAID':
        return Colors.blue.shade700;
      case 'PENDING':
      case 'UNPAID':
        return Colors.orange.shade800;
      default:
        return Colors.grey.shade700;
    }
  }

  Future<void> _printBill(
    BuildContext context,
    WidgetRef ref,
    PurchaseInvoiceEntry inv,
    List<PurchaseInvoiceItemEntry> items,
  ) async {
    try {
      final settings = await ref.read(settingsRepositoryProvider).getAllSettings();
      final supplier = await ref.read(supplierRepositoryProvider).getSupplierById(inv.supplierId);
      await InvoicePdfGenerator.printPurchaseInvoice(
        invoice: inv,
        items: items,
        supplier: supplier,
        settings: settings,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error printing bill: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _printKot(
    BuildContext context,
    WidgetRef ref,
    PurchaseInvoiceEntry inv,
    List<PurchaseInvoiceItemEntry> items,
  ) async {
    try {
      final settings = await ref.read(settingsRepositoryProvider).getAllSettings();
      await InvoicePdfGenerator.printPurchaseKot(
        invoice: inv,
        items: items,
        settings: settings,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error printing KOT: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _sharePdf(
    BuildContext context,
    WidgetRef ref,
    PurchaseInvoiceEntry inv,
    List<PurchaseInvoiceItemEntry> items,
  ) async {
    try {
      final settings = await ref.read(settingsRepositoryProvider).getAllSettings();
      final supplier = await ref.read(supplierRepositoryProvider).getSupplierById(inv.supplierId);
      await InvoicePdfGenerator.sharePurchaseInvoice(
        invoice: inv,
        items: items,
        supplier: supplier,
        settings: settings,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing bill: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final purchaseRepo = ref.watch(purchaseRepositoryProvider);
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    final dateFormat = DateFormat('dd MMMM yyyy');

    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        purchaseRepo.getPurchaseInvoiceById(invoiceId),
        purchaseRepo.getPurchaseInvoiceItems(invoiceId),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Invoice Status & Details')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final inv = snapshot.data?[0] as PurchaseInvoiceEntry?;
        final items = (snapshot.data?[1] as List<PurchaseInvoiceItemEntry>?) ?? [];

        if (inv == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Invoice Status & Details')),
            body: const Center(child: Text('Purchase Invoice not found.')),
          );
        }

        final verColor = _getVerificationColor(inv.verificationStatus);
        final payColor = _getPaymentColor(inv.paymentStatus);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Invoice Status & Details'),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: 'Share Bill PDF',
                onPressed: () => _sharePdf(context, ref, inv, items),
              ),
              IconButton(
                icon: const Icon(Icons.restaurant_menu),
                tooltip: 'Print KOT (Kitchen Ticket)',
                onPressed: () => _printKot(context, ref, inv, items),
              ),
              IconButton(
                icon: const Icon(Icons.print_outlined),
                tooltip: 'Print Bill',
                onPressed: () => _printBill(context, ref, inv, items),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton.filledTonal(
                    icon: const Icon(Icons.share),
                    tooltip: 'Share Bill',
                    onPressed: () => _sharePdf(context, ref, inv, items),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.restaurant_menu, color: Colors.deepOrange),
                      label: const Text(
                        'Print KOT',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.deepOrange, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _printKot(context, ref, inv, items),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.print),
                      label: const Text(
                        'Print Bill',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _printBill(context, ref, inv, items),
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Quick Print & KOT Action Bar
              Card(
                elevation: 0,
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.25)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.print, size: 18),
                          label: const Text('Print Bill'),
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed: () => _printBill(context, ref, inv, items),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.restaurant_menu, size: 18),
                          label: const Text('Print KOT'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.deepOrange.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed: () => _printKot(context, ref, inv, items),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.share, size: 18),
                        tooltip: 'Share PDF',
                        onPressed: () => _sharePdf(context, ref, inv, items),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            inv.invoiceNumber,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: verColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: verColor.withValues(alpha: 0.4)),
                                ),
                                child: Text(
                                  inv.verificationStatus == 'PENDING_VERIFICATION' ? 'SUBMITTED' : inv.verificationStatus,
                                  style: TextStyle(color: verColor, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: payColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: payColor.withValues(alpha: 0.4)),
                                ),
                                child: Text(
                                  inv.paymentStatus == 'PENDING' ? 'UNPAID' : inv.paymentStatus,
                                  style: TextStyle(color: payColor, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Invoice Date:', style: TextStyle(color: Colors.grey.shade600)),
                          Text(dateFormat.format(inv.invoiceDate), style: const TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      ),
                      if (inv.dueDate != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Payment Due Date:', style: TextStyle(color: Colors.grey.shade600)),
                            Text(dateFormat.format(inv.dueDate!), style: const TextStyle(fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ],
                      if (inv.rejectionReason != null && inv.rejectionReason!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Rejected by Admin', style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 2),
                                    Text(inv.rejectionReason!, style: TextStyle(color: Colors.red.shade800)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Line Items Table
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Billed Items (${items.length})', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Table(
                        columnWidths: const {
                          0: FlexColumnWidth(4),
                          1: FlexColumnWidth(2),
                          2: FlexColumnWidth(2.5),
                          3: FlexColumnWidth(3),
                        },
                        children: [
                          TableRow(
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 1.5)),
                            ),
                            children: const [
                              Padding(padding: EdgeInsets.only(bottom: 8), child: Text('Item', style: TextStyle(fontWeight: FontWeight.bold))),
                              Padding(padding: EdgeInsets.only(bottom: 8), child: Text('Qty', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                              Padding(padding: EdgeInsets.only(bottom: 8), child: Text('Price', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold))),
                              Padding(padding: EdgeInsets.only(bottom: 8), child: Text('Total', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                          ),
                          ...items.map((it) {
                            return TableRow(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(it.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                      if (it.gstRatePercent > 0)
                                        Text('GST ${it.gstRatePercent}%', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Text('${it.quantity} ${it.unit}', textAlign: TextAlign.center),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Text(currencyFormat.format(it.unitPricePaise / 100), textAlign: TextAlign.right),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    currencyFormat.format(it.totalAmountPaise / 100),
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Financial Totals Card
              Card(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal:'),
                          Text(currencyFormat.format(inv.subtotalPaise / 100), style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tax (GST):'),
                          Text(currencyFormat.format(inv.taxPaise / 100), style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Grand Total:', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          Text(
                            currencyFormat.format(inv.grandTotalPaise / 100),
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Amount Paid:'),
                          Text(
                            currencyFormat.format(inv.amountPaidPaise / 100),
                            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue.shade800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Balance Due:', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                          Text(
                            currencyFormat.format(inv.balanceDuePaise / 100),
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.green.shade800),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Database Reference Card
              Card(
                elevation: 0,
                color: Colors.grey.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 16, color: Colors.grey.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'System Record Reference',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Database Table:', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          const Text('purchase_invoices', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Sync Status:', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          Text(inv.syncStatus ?? 'synced', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Invoice UUID:', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                                SelectableText(
                                  inv.id,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 16),
                            tooltip: 'Copy Database UUID',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: inv.id));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Copied UUID: ${inv.id}')),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Payments Received
              Text('Disbursement Payments Received', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              StreamBuilder<List<SupplierPaymentEntry>>(
                stream: purchaseRepo.watchSupplierPayments(purchaseInvoiceId: inv.id),
                builder: (context, paySnap) {
                  final payments = paySnap.data ?? [];
                  if (payments.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: const Center(child: Text('No payments recorded against this invoice yet.')),
                    );
                  }

                  return Column(
                    children: payments.map((p) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade50,
                          child: const Icon(Icons.check, color: Colors.green),
                        ),
                        title: Text(p.paymentVoucherNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${p.paymentMethod} • ${dateFormat.format(p.paymentDate)}'),
                        trailing: Text(
                          currencyFormat.format(p.amountPaise / 100),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
