import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/database/app_database.dart';
import '../printer/invoice_pdf_generator.dart';
import '../purchases/purchase_repository.dart';
import '../settings/settings_repository.dart';
import '../suppliers/supplier_repository.dart';

class SupplierInvoiceDetailScreen extends ConsumerStatefulWidget {
  final String invoiceId;
  const SupplierInvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  ConsumerState<SupplierInvoiceDetailScreen> createState() => _SupplierInvoiceDetailScreenState();
}

class _SupplierInvoiceDetailScreenState extends ConsumerState<SupplierInvoiceDetailScreen> {
  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
  final _dateFormat = DateFormat('dd MMMM yyyy');
  bool _isActionLoading = false;

  Color _getVerificationColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return Colors.green.shade800;
      case 'APPROVED':
        return Colors.green.shade700;
      case 'SUBMITTED':
      case 'PENDING_VERIFICATION':
        return Colors.blue.shade700;
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error printing bill: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _printKot(
    PurchaseInvoiceEntry inv,
    List<PurchaseInvoiceItemEntry> items,
  ) async {
    try {
      final settings = await ref.read(settingsRepositoryProvider).getAllSettings();
      // Ensure KOT record and all items are permanently stored in database
      final kotWithItems = await ref.read(purchaseRepositoryProvider).getOrSavePurchaseKot(
            invoice: inv,
            items: items,
          );
      await InvoicePdfGenerator.printPurchaseKot(
        invoice: inv,
        items: items,
        settings: settings,
        kotNumber: kotWithItems.record.kotNumber,
        reprintCount: kotWithItems.record.reprintCount,
      );
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error printing KOT: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _sharePdf(
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing bill: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showReceivePaymentModal(
    PurchaseInvoiceEntry inv,
    SupplierEntry? supplier,
  ) async {
    final balanceRupees = inv.balanceDuePaise / 100.0;
    if (balanceRupees <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice is already fully paid.'), backgroundColor: Colors.orange),
      );
      return;
    }

    final amountController = TextEditingController(text: balanceRupees.toStringAsFixed(2));
    final referenceController = TextEditingController();
    final notesController = TextEditingController();
    String selectedMethod = 'Cash';
    DateTime selectedDate = DateTime.now();

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Receive Payment',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx, false),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Read-only invoice summary
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Invoice #:', style: TextStyle(fontWeight: FontWeight.w500)),
                              Text(inv.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Supplier:', style: TextStyle(fontWeight: FontWeight.w500)),
                              Text(supplier?.name ?? 'Supplier', style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Grand Total:'),
                              Text(_currencyFormat.format(inv.grandTotalPaise / 100)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Previously Paid:'),
                              Text(_currencyFormat.format(inv.amountPaidPaise / 100), style: TextStyle(color: Colors.blue.shade800)),
                            ],
                          ),
                          const Divider(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Balance Due:', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(
                                _currencyFormat.format(balanceRupees),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Payment Amount field
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Payment Amount (₹)*',
                        prefixText: '₹ ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Payment Method Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedMethod,
                      decoration: const InputDecoration(
                        labelText: 'Payment Method*',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                        DropdownMenuItem(value: 'UPI', child: Text('UPI / QR')),
                        DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer (NEFT/IMPS)')),
                        DropdownMenuItem(value: 'Card', child: Text('Debit / Credit Card')),
                        DropdownMenuItem(value: 'Cheque', child: Text('Cheque')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedMethod = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Payment Date picker
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                        );
                        if (picked != null) {
                          setModalState(() => selectedDate = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Payment Date',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today, size: 20),
                        ),
                        child: Text(_dateFormat.format(selectedDate)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Reference Number
                    TextField(
                      controller: referenceController,
                      decoration: const InputDecoration(
                        labelText: 'Reference / Voucher / UTR # (Optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Notes
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Notes (Optional)',
                        hintText: 'e.g., Cash collected at delivery',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Confirm Payment Button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Confirm Payment', style: TextStyle(fontSize: 16)),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          final parsed = double.tryParse(amountController.text.trim());
                          if (parsed == null || parsed <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a valid payment amount > 0.')),
                            );
                            return;
                          }
                          if (parsed > balanceRupees + 0.01) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Amount cannot exceed balance due (${_currencyFormat.format(balanceRupees)}).')),
                            );
                            return;
                          }
                          Navigator.pop(ctx, true);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (confirmed == true) {
      final amountRupees = double.parse(amountController.text.trim());
      final amountPaise = (amountRupees * 100).round();

      setState(() => _isActionLoading = true);
      try {
        await ref.read(purchaseRepositoryProvider).recordSupplierPayment(
              purchaseInvoiceId: inv.id,
              supplierId: inv.supplierId,
              amountPaise: amountPaise,
              paymentMethod: selectedMethod,
              referenceNumber: referenceController.text.trim().isNotEmpty ? referenceController.text.trim() : null,
              notes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment of ${_currencyFormat.format(amountRupees)} recorded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {});
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to record payment: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isActionLoading = false);
      }
    }
  }

  Future<void> _completeInvoice(PurchaseInvoiceEntry inv) async {
    if (inv.verificationStatus == 'COMPLETED') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice is already marked as COMPLETED.')),
      );
      return;
    }

    if (inv.balanceDuePaise > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot complete invoice with outstanding balance (${_currencyFormat.format(inv.balanceDuePaise / 100)}). Full payment is required.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete Invoice?'),
        content: Text(
          'Mark invoice ${inv.invoiceNumber} as COMPLETED?\n\n'
          'This finalizes the invoice record. All items and cash disbursements will be recorded as completed.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.blue.shade800),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isActionLoading = true);
    try {
      await ref.read(purchaseRepositoryProvider).completePurchaseInvoice(inv.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice marked as COMPLETED!'), backgroundColor: Colors.green),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Completion failed: $e'), backgroundColor: Colors.red),
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
        final isCompleted = inv.verificationStatus == 'COMPLETED';
        final isFullyPaid = inv.balanceDuePaise <= 0;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Invoice Status & Details'),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: 'Share Bill PDF',
                onPressed: () => _sharePdf(inv, items),
              ),
              IconButton(
                icon: const Icon(Icons.restaurant_menu),
                tooltip: 'Print KOT (Kitchen Ticket)',
                onPressed: () => _printKot(inv, items),
              ),
              IconButton(
                icon: const Icon(Icons.print_outlined),
                tooltip: 'Print Bill',
                onPressed: () => _printBill(inv, items),
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
                        'Print Bill',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _printBill(inv, items),
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Completed Banner
              if (isCompleted) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade700, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Invoice Completed & Settled',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade900,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'All disbursements are recorded and balance due is settled.',
                              style: TextStyle(color: Colors.green.shade800, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Quick Action Bar: Receive Payment & Complete
              FutureBuilder<SupplierEntry?>(
                future: ref.read(supplierRepositoryProvider).getSupplierById(inv.supplierId),
                builder: (context, supSnap) {
                  final supplier = supSnap.data;
                  return Card(
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
                          // Prominent Receive Payment button
                          Expanded(
                            child: FilledButton.icon(
                              icon: const Icon(Icons.payments, size: 18),
                              label: const Text('Receive Payment', style: TextStyle(fontWeight: FontWeight.bold)),
                              style: FilledButton.styleFrom(
                                backgroundColor: isFullyPaid ? Colors.grey.shade400 : Colors.green.shade700,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              onPressed: (isFullyPaid || _isActionLoading)
                                  ? null
                                  : () => _showReceivePaymentModal(inv, supplier),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Prominent Complete button
                          Expanded(
                            child: FilledButton.icon(
                              icon: Icon(isCompleted ? Icons.done_all : Icons.check_circle_outline, size: 18),
                              label: Text(
                                isCompleted ? 'Completed' : 'Complete',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: isCompleted
                                    ? Colors.grey.shade400
                                    : (isFullyPaid ? Colors.blue.shade800 : Colors.grey.shade400),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              onPressed: (!isFullyPaid || isCompleted || _isActionLoading)
                                  ? null
                                  : () => _completeInvoice(inv),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Status and Basic Details Card
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
                                  inv.verificationStatus,
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
                          Text(_dateFormat.format(inv.invoiceDate), style: const TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      ),
                      if (inv.dueDate != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Payment Due Date:', style: TextStyle(color: Colors.grey.shade600)),
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
                            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue.shade800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Balance Due:',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isFullyPaid ? Colors.green.shade800 : Colors.red.shade800,
                            ),
                          ),
                          Text(
                            _currencyFormat.format(inv.balanceDuePaise / 100),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isFullyPaid ? Colors.green.shade800 : Colors.red.shade800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ==========================================
              // Associated KOT Details Card
              // ==========================================
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
                          Row(
                            children: [
                              const Icon(Icons.restaurant_menu, color: Colors.deepOrange, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Associated KOT Details',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.print, size: 16, color: Colors.deepOrange),
                            label: const Text('Print KOT', style: TextStyle(color: Colors.deepOrange, fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.deepOrange),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            ),
                            onPressed: () => _printKot(inv, items),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      StreamBuilder<List<KotWithItems>>(
                        stream: purchaseRepo.watchKotsForPurchaseInvoice(inv.id),
                        builder: (context, kotSnap) {
                          final kots = kotSnap.data ?? [];
                          if (kots.isEmpty) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange.shade200),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.receipt_long_outlined, size: 36, color: Colors.orange.shade400),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'No KOT records found for this invoice.',
                                    style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 8),
                                  FilledButton.icon(
                                    icon: const Icon(Icons.add, size: 16),
                                    label: const Text('Generate & Save KOT'),
                                    style: FilledButton.styleFrom(backgroundColor: Colors.deepOrange.shade700),
                                    onPressed: () => _printKot(inv, items),
                                  ),
                                ],
                              ),
                            );
                          }

                          return Column(
                            children: kots.map((k) {
                              final kotRec = k.record;
                              final kotItems = k.items;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          kotRec.kotNumber,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: Colors.deepOrange,
                                          ),
                                        ),
                                        if (kotRec.reprintCount > 0)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.amber.shade100,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              'Reprinted x${kotRec.reprintCount}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.amber.shade900,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Supplier Bill Ref: ${kotRec.supplierInvoiceNumber ?? inv.invoiceNumber}',
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                        ),
                                        Text(
                                          _dateFormat.format(kotRec.createdAt),
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 16),
                                    ...kotItems.map((ki) => Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 3),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  ki.productNameSnapshot,
                                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                                ),
                                              ),
                                              Text(
                                                '${ki.quantity} ${ki.unit ?? ''}',
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.shade50,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  ki.itemStatus,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.blue.shade800,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
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
                        subtitle: Text('${p.paymentMethod} • ${_dateFormat.format(p.paymentDate)}'),
                        trailing: Text(
                          _currencyFormat.format(p.amountPaise / 100),
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
