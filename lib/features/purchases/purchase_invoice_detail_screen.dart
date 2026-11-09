import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/database/app_database.dart';
import '../printer/invoice_pdf_generator.dart';
import '../settings/settings_repository.dart';
import '../suppliers/supplier_repository.dart';
import 'purchase_repository.dart';

class PurchaseInvoiceDetailScreen extends ConsumerStatefulWidget {
  final String invoiceId;
  const PurchaseInvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  ConsumerState<PurchaseInvoiceDetailScreen> createState() => _PurchaseInvoiceDetailScreenState();
}

class _PurchaseInvoiceDetailScreenState extends ConsumerState<PurchaseInvoiceDetailScreen> {
  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
  final _dateFormat = DateFormat('dd MMMM yyyy');
  bool _isActionLoading = false;

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

  Future<void> _printInvoice(PurchaseInvoiceEntry inv, List<PurchaseInvoiceItemEntry> items) async {
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error printing invoice: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _printKot(PurchaseInvoiceEntry inv, List<PurchaseInvoiceItemEntry> items) async {
    try {
      final settings = await ref.read(settingsRepositoryProvider).getAllSettings();
      await InvoicePdfGenerator.printPurchaseKot(
        invoice: inv,
        items: items,
        settings: settings,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error printing KOT: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _sharePdf(PurchaseInvoiceEntry inv, List<PurchaseInvoiceItemEntry> items) async {
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing invoice: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _approveInvoice() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve Purchase Invoice?'),
        content: const Text(
          'Approving this invoice verifies that the items have been inspected and accepted. '
          'It will make this invoice eligible for payment disbursement.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.green.shade700),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isActionLoading = true);
    try {
      await ref.read(purchaseRepositoryProvider).approvePurchaseInvoice(widget.invoiceId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase invoice approved successfully!'), backgroundColor: Colors.green),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Approval failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _rejectInvoice() async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Purchase Invoice'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please provide a reason for rejecting this supplier invoice:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g., Damaged items, rate mismatch, quantity incorrect...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Please enter a rejection reason.')),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isActionLoading = true);
    try {
      await ref.read(purchaseRepositoryProvider).rejectPurchaseInvoice(
            widget.invoiceId,
            reasonController.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase invoice rejected.'), backgroundColor: Colors.red),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rejection failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final purchaseRepo = ref.watch(purchaseRepositoryProvider);

    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        purchaseRepo.getPurchaseInvoiceById(widget.invoiceId),
        purchaseRepo.getPurchaseInvoiceItems(widget.invoiceId),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Invoice Details')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final inv = snapshot.data?[0] as PurchaseInvoiceEntry?;
        final items = (snapshot.data?[1] as List<PurchaseInvoiceItemEntry>?) ?? [];

        if (inv == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Invoice Details')),
            body: const Center(child: Text('Purchase Invoice not found.')),
          );
        }

        final verColor = _getVerificationColor(inv.verificationStatus);
        final payColor = _getPaymentColor(inv.paymentStatus);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Invoice Details'),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: 'Share Invoice PDF',
                onPressed: () => _sharePdf(inv, items),
              ),
              IconButton(
                icon: const Icon(Icons.restaurant_menu),
                tooltip: 'Print KOT (Kitchen Ticket)',
                onPressed: () => _printKot(inv, items),
              ),
              IconButton(
                icon: const Icon(Icons.print_outlined),
                tooltip: 'Print Invoice',
                onPressed: () => _printInvoice(inv, items),
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
                    tooltip: 'Share Invoice',
                    onPressed: () => _sharePdf(inv, items),
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
                      onPressed: () => _printKot(inv, items),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.print),
                      label: const Text(
                        'Print Invoice',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _printInvoice(inv, items),
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Prominent Quick Print and KOT bar
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
                          label: const Text('Print Invoice'),
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed: () => _printInvoice(inv, items),
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
                          onPressed: () => _printKot(inv, items),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.share, size: 18),
                        tooltip: 'Share PDF',
                        onPressed: () => _sharePdf(inv, items),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Verification / Status Header Card
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
                      FutureBuilder<SupplierEntry?>(
                        future: ref.read(supplierRepositoryProvider).getSupplierById(inv.supplierId),
                        builder: (context, supSnap) {
                          final sup = supSnap.data;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sup != null ? sup.name : 'Supplier ID: ${inv.supplierId}',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              if (sup?.gstin != null)
                                Text('GSTIN: ${sup!.gstin!}', style: theme.textTheme.bodyMedium),
                              if (sup?.phone != null)
                                Text('Phone: ${sup!.phone!}', style: theme.textTheme.bodyMedium),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Invoice Date:', style: TextStyle(color: Colors.grey.shade600)),
                          Text(_dateFormat.format(inv.invoiceDate), style: const TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      ),
                      if (inv.dueDate != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Due Date:', style: TextStyle(color: Colors.grey.shade600)),
                            Text(_dateFormat.format(inv.dueDate!), style: const TextStyle(fontWeight: FontWeight.w500)),
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
                                child: Text(
                                  'Rejection Reason: ${inv.rejectionReason}',
                                  style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.w500),
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

              // Line Items Table Card
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
                                  child: Text(_currencyFormat.format(it.unitPricePaise / 100), textAlign: TextAlign.right),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    _currencyFormat.format(it.totalAmountPaise / 100),
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

              // Financial Balance Card
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
                          Text(_currencyFormat.format(inv.subtotalPaise / 100), style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tax (GST):'),
                          Text(_currencyFormat.format(inv.taxPaise / 100), style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Grand Total:', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          Text(
                            _currencyFormat.format(inv.grandTotalPaise / 100),
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
                            _currencyFormat.format(inv.amountPaidPaise / 100),
                            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green.shade700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Balance Due:', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.red.shade800)),
                          Text(
                            _currencyFormat.format(inv.balanceDuePaise / 100),
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.red.shade800),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Administrator Database Traceability Card
              Card(
                elevation: 0,
                color: Colors.blueGrey.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.blueGrey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.storage, size: 18, color: Colors.blueGrey.shade800),
                          const SizedBox(width: 8),
                          Text(
                            'PostgreSQL Database Traceability (Admin)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.blueGrey.shade900,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Table:', style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade700)),
                          const Text('purchase_invoices', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Invoice Number:', style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade700)),
                          Text(inv.invoiceNumber, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Item Count:', style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade700)),
                          Text('${items.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Sync Status:', style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade700)),
                          Text(inv.syncStatus ?? 'synced', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Supplier ID:', style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade700)),
                          Text(inv.supplierId.length > 12 ? '${inv.supplierId.substring(0, 8)}...' : inv.supplierId, style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Invoice UUID (PostgreSQL ID):', style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade700)),
                                SelectableText(
                                  inv.id,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 18),
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

              // Action Buttons for Admin
              if (inv.balanceDuePaise > 0 && inv.verificationStatus != 'REJECTED' && inv.verificationStatus != 'CANCELLED') ...[
                Row(
                  children: [
                    if (inv.verificationStatus == 'SUBMITTED' || inv.verificationStatus == 'PENDING_VERIFICATION') ...[
                      OutlinedButton.icon(
                        onPressed: _isActionLoading ? null : _rejectInvoice,
                        icon: const Icon(Icons.close, color: Colors.red),
                        label: const Text('Reject', style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _isActionLoading ? null : _approveInvoice,
                        icon: const Icon(Icons.check, color: Colors.green),
                        label: const Text('Verify', style: TextStyle(color: Colors.green)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.green),
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => context.push('/purchases/invoices/${inv.id}/pay'),
                        icon: const Icon(Icons.payment),
                        label: const Text('Record Payment Voucher', style: TextStyle(fontSize: 15)),
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // Payment Vouchers History Stream
              const SizedBox(height: 24),
              Text('Disbursement Vouchers', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
                        subtitle: Text('${p.paymentMethod} • ${DateFormat('dd MMM yyyy').format(p.paymentDate)}'),
                        trailing: Text(
                          _currencyFormat.format(p.amountPaise / 100),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
