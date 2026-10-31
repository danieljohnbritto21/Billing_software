import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/database/app_database.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../printer/invoice_pdf_generator.dart';
import '../settings/settings_repository.dart';
import 'invoice_repository.dart';

class BillDetailsScreen extends ConsumerStatefulWidget {
  final String invoiceId;

  const BillDetailsScreen({super.key, required this.invoiceId});

  @override
  ConsumerState<BillDetailsScreen> createState() => _BillDetailsScreenState();
}

class _BillDetailsScreenState extends ConsumerState<BillDetailsScreen> {
  void _showCollectPaymentDialog(
      BuildContext context, InvoiceEntry invoice, int balanceDuePaise) {
    final amountController = TextEditingController(
      text: CurrencyFormatter.paiseToRupees(balanceDuePaise).toStringAsFixed(2),
    );
    final refController = TextEditingController();
    String selectedMethod = AppConstants.paymentCash;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.payment, color: AppTheme.primaryGreen),
              SizedBox(width: 8),
              Text('Collect Payment',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Balance Due:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        CurrencyFormatter.formatPaise(balanceDuePaise),
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Colors.red.shade700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount Received (₹)',
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Enter amount';
                    }
                    final val = double.tryParse(v.trim());
                    if (val == null || val <= 0) {
                      return 'Enter a valid positive amount';
                    }
                    final paise = CurrencyFormatter.rupeesToPaise(val);
                    if (paise > balanceDuePaise) {
                      return 'Cannot exceed balance due';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: selectedMethod,
                  decoration: const InputDecoration(
                    labelText: 'Payment Method',
                    prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: AppConstants.paymentCash, child: Text('Cash')),
                    DropdownMenuItem(
                        value: AppConstants.paymentUpi, child: Text('UPI / QR')),
                    DropdownMenuItem(
                        value: AppConstants.paymentCard, child: Text('Card')),
                    DropdownMenuItem(
                        value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedMethod = val);
                    }
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: refController,
                  decoration: const InputDecoration(
                    labelText: 'Reference / Transaction ID (optional)',
                    prefixIcon: Icon(Icons.numbers),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final amountRupees =
                    double.parse(amountController.text.trim());
                final amountPaise =
                    CurrencyFormatter.rupeesToPaise(amountRupees);
                final repo = ref.read(invoiceRepositoryProvider);
                final scaffold = ScaffoldMessenger.of(context);

                try {
                  await repo.recordAdditionalPayment(
                    invoiceId: invoice.id,
                    amountPaise: amountPaise,
                    paymentMethod: selectedMethod,
                    referenceNumber: refController.text.trim().isEmpty
                        ? null
                        : refController.text.trim(),
                  );
                  if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                  scaffold.showSnackBar(
                    const SnackBar(
                        content: Text('Payment recorded successfully!')),
                  );
                } catch (e) {
                  scaffold.showSnackBar(
                    SnackBar(
                      content: Text('Failed to record payment: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Save Payment'),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateOrderStatusDialog(
      BuildContext context, InvoiceEntry invoice) {
    String currentStatus = invoice.orderStatus;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text(
            'Update Order Status',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('Completed'),
                value: AppConstants.orderCompleted,
                groupValue: currentStatus,
                activeColor: AppTheme.primaryGreen,
                onChanged: (v) => setDialogState(() => currentStatus = v!),
              ),
              RadioListTile<String>(
                title: const Text('In Progress'),
                value: AppConstants.orderInProgress,
                groupValue: currentStatus,
                activeColor: Colors.blue,
                onChanged: (v) => setDialogState(() => currentStatus = v!),
              ),
              RadioListTile<String>(
                title: const Text('Pending'),
                value: AppConstants.orderPending,
                groupValue: currentStatus,
                activeColor: Colors.amber.shade800,
                onChanged: (v) => setDialogState(() => currentStatus = v!),
              ),
              RadioListTile<String>(
                title: const Text('Cancelled'),
                value: AppConstants.orderCancelled,
                groupValue: currentStatus,
                activeColor: Colors.red,
                onChanged: (v) => setDialogState(() => currentStatus = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final scaffold = ScaffoldMessenger.of(context);
                await ref
                    .read(invoiceRepositoryProvider)
                    .updateOrderStatus(
                      invoiceId: invoice.id,
                      orderStatus: currentStatus,
                    );
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                scaffold.showSnackBar(
                  SnackBar(
                      content: Text('Order status updated to $currentStatus')),
                );
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final invoiceRepo = ref.watch(invoiceRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share PDF',
            onPressed: () => _sharePdf(context),
          ),
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Print',
            onPressed: () => _printBill(context),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.share),
                  label: const Text('Share PDF'),
                  onPressed: () => _sharePdf(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.print),
                  label: const Text('Print Receipt',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => _printBill(context),
                ),
              ),
            ],
          ),
        ),
      ),
      body: StreamBuilder<InvoiceDetails?>(
        stream: invoiceRepo.watchInvoiceWithDetails(widget.invoiceId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final details = snapshot.data;
          if (details == null) {
            return const Center(child: Text('Invoice not found'));
          }

          final inv = details.invoice;
          final dateFormat = DateFormat('dd MMMM yyyy, hh:mm a');
          final formattedDate = dateFormat.format(inv.createdAt);
          final balanceDuePaise = inv.grandTotalPaise - inv.paidAmountPaise;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            children: [
              // Header Card
              Card(
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
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textDark,
                            ),
                          ),
                          Wrap(
                            spacing: 6,
                            children: [
                              // Payment Status Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: inv.isCancelled
                                      ? Colors.red.shade100
                                      : (inv.paymentStatus ==
                                              AppConstants.statusPaid
                                          ? const Color(0xFFDCFCE7)
                                          : (inv.paymentStatus ==
                                                  AppConstants.statusPartial
                                              ? Colors.amber.shade100
                                              : Colors.red.shade50)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  inv.isCancelled
                                      ? 'CANCELLED'
                                      : inv.paymentStatus.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: inv.isCancelled
                                        ? Colors.red.shade800
                                        : (inv.paymentStatus ==
                                                AppConstants.statusPaid
                                            ? AppTheme.primaryGreen
                                            : (inv.paymentStatus ==
                                                    AppConstants.statusPartial
                                                ? Colors.amber.shade900
                                                : Colors.red.shade800)),
                                  ),
                                ),
                              ),
                              // Order Status Badge
                              InkWell(
                                onTap: () => _showUpdateOrderStatusDialog(
                                    context, inv),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: const Color(0xFFBFDBFE)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        inv.orderStatus,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1D4ED8),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.arrow_drop_down,
                                          size: 14, color: Color(0xFF1D4ED8)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        formattedDate,
                        style: const TextStyle(
                            fontSize: 13, color: AppTheme.textMuted),
                      ),
                      if (inv.cashierName != null &&
                          inv.cashierName!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.person_pin,
                                size: 15, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Text(
                              'Billed by: ${inv.cashierName}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (inv.customerName != null &&
                          inv.customerName!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Billed to: ${inv.customerName} ${inv.customerPhone != null ? "(${inv.customerPhone})" : ""}',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                      if (inv.isCancelled && inv.cancelReason != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Cancel Reason: ${inv.cancelReason}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.red.shade800),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // HIGHEST PRIORITY FEATURE: DEDICATED INDIVIDUAL BILL NOTE CARD
              Card(
                color: AppTheme.noteBannerBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(
                      color: AppTheme.noteBannerBorder, width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.edit_note,
                                  color: AppTheme.noteBannerText, size: 22),
                              SizedBox(width: 8),
                              Text(
                                'BILL NOTE',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.noteBannerText,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.noteBannerText,
                              side: const BorderSide(
                                  color: AppTheme.noteBannerText, width: 1.2),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              visualDensity: VisualDensity.compact,
                            ),
                            icon: const Icon(Icons.edit, size: 14),
                            label: Text(
                              details.billNote != null &&
                                      details.billNote!.note.isNotEmpty
                                  ? 'Edit Note'
                                  : 'Add Note',
                              style: const TextStyle(fontSize: 12),
                            ),
                            onPressed: () => _showEditNoteDialog(
                              context,
                              details.billNote?.note ?? '',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        details.billNote != null &&
                                details.billNote!.note.trim().isNotEmpty
                            ? details.billNote!.note
                            : 'No private note attached to this bill. Tap "Add Note" to add instructions, delivery details, or customer requests.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: details.billNote != null &&
                                  details.billNote!.note.trim().isNotEmpty
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: details.billNote != null &&
                                  details.billNote!.note.trim().isNotEmpty
                              ? AppTheme.textDark
                              : AppTheme.textMuted,
                          height: 1.4,
                        ),
                      ),
                      if (details.billNote != null &&
                          details.billNote!.updatedAt !=
                              details.billNote!.createdAt) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Last updated: ${dateFormat.format(details.billNote!.updatedAt)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Items Ordered Section
              Text(
                'Items Ordered (${details.items.length})',
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              Card(
                child: Column(
                  children: [
                    ...details.items.asMap().entries.map((entry) {
                      final item = entry.value;
                      final isLast = entry.key == details.items.length - 1;
                      final qtyStr = item.quantity.truncateToDouble() ==
                              item.quantity
                          ? item.quantity.toInt().toString()
                          : item.quantity.toStringAsFixed(1);

                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 6,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.productName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$qtyStr × ${CurrencyFormatter.formatPaise(item.unitPricePaise)} / ${item.unit}  •  GST ${item.gstRatePercent}% ${item.isTaxInclusive ? "(Incl)" : "(Excl)"}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                      if (item.discountPaise > 0)
                                        Text(
                                          'Item Discount: -${CurrencyFormatter.formatPaise(item.discountPaise)}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.formatPaise(
                                      item.totalAmountPaise),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isLast) const Divider(height: 1),
                        ],
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Payment & Financial Totals Breakdown
              const Text(
                'Payment Summary',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _row('Subtotal', inv.subtotalPaise),
                      if (inv.itemDiscountTotalPaise > 0)
                        _row('Item Discounts', -inv.itemDiscountTotalPaise),
                      if (inv.billDiscountPaise > 0)
                        _row('Bill Discount', -inv.billDiscountPaise),
                      _row('Taxable Value', inv.taxableAmountPaise),
                      if (inv.cgstPaise > 0) _row('CGST', inv.cgstPaise),
                      if (inv.sgstPaise > 0) _row('SGST', inv.sgstPaise),
                      if (inv.roundOffPaise != 0)
                        _row('Round Off', inv.roundOffPaise),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Grand Total',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.formatPaise(inv.grandTotalPaise),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      _row('Payment Method', null,
                          customValue: inv.paymentMethod),
                      _row('Amount Paid', inv.paidAmountPaise),
                      if (balanceDuePaise > 0) ...[
                        _row(
                          'Balance Due',
                          balanceDuePaise,
                          isHighlight: true,
                        ),
                        if (!inv.isCancelled) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD97706),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () => _showCollectPaymentDialog(
                                  context, inv, balanceDuePaise),
                              icon: const Icon(Icons.payment, size: 18),
                              label: Text(
                                'Collect Remaining Balance (${CurrencyFormatter.formatPaise(balanceDuePaise)})',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),

              // Payment Transactions List if payments exist
              if (details.payments.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Payment Records (${details.payments.length})',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: details.payments.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, idx) {
                      final p = details.payments[idx];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              AppTheme.primaryGreen.withValues(alpha: 0.12),
                          child: const Icon(Icons.check,
                              color: AppTheme.primaryGreen, size: 18),
                        ),
                        title: Text(
                          CurrencyFormatter.formatPaise(p.amountPaise),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        subtitle: Text(
                          '${p.paymentMethod} • ${dateFormat.format(p.createdAt)}${p.referenceNumber != null ? " • Ref: ${p.referenceNumber}" : ""}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Cancel Invoice Option
              if (!inv.isCancelled)
                Center(
                  child: TextButton.icon(
                    icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                    label: const Text('Cancel / Void Invoice',
                        style: TextStyle(color: Colors.red)),
                    onPressed: () => _confirmCancelInvoice(context, inv),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(String label, int? amountPaise,
      {String? customValue, bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: 13,
                color: isHighlight ? Colors.red.shade800 : AppTheme.textMuted,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              )),
          Text(
            customValue ??
                CurrencyFormatter.formatPaise(amountPaise ?? 0),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isHighlight ? Colors.red.shade800 : AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditNoteDialog(BuildContext context, String currentNote) {
    final controller = TextEditingController(text: currentNote);
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.edit_note, color: AppTheme.noteBannerText),
              SizedBox(width: 8),
              Text('Edit Individual Bill Note',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Note is tied permanently to this bill only:',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Enter instructions, special requests, or comments...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newNote = controller.text.trim();
                final invoiceRepo = ref.read(invoiceRepositoryProvider);
                final scaffold = ScaffoldMessenger.of(context);
                await invoiceRepo.updateBillNote(
                  invoiceId: widget.invoiceId,
                  noteText: newNote,
                );
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                scaffold.showSnackBar(
                  const SnackBar(
                    content: Text('Bill note updated successfully!'),
                    backgroundColor: AppTheme.primaryGreen,
                  ),
                );
              },
              child: const Text('Save Note'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmCancelInvoice(BuildContext context, InvoiceEntry invoice) async {
    final controller = TextEditingController();
    final scaffold = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Cancel Invoice?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to cancel ${invoice.invoiceNumber}? This action cannot be undone.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Reason for cancellation',
                hintText: 'e.g. Customer cancelled order, wrong item',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('No, Keep Active'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Yes, Cancel Invoice'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final invoiceRepo = ref.read(invoiceRepositoryProvider);
      final reason = controller.text.trim().isEmpty ? 'Cancelled by user' : controller.text.trim();
      await invoiceRepo.cancelInvoice(
        invoice.id,
        reason,
      );
      scaffold.showSnackBar(
        const SnackBar(content: Text('Invoice cancelled')),
      );
    }
  }

  Future<void> _sharePdf(BuildContext context) async {
    try {
      final invoiceRepo = ref.read(invoiceRepositoryProvider);
      final details = await invoiceRepo.getInvoiceWithDetails(widget.invoiceId);
      if (details == null) return;

      final settings = await ref.read(settingsRepositoryProvider).getAllSettings();
      await InvoicePdfGenerator.shareInvoice(
        details: details,
        settings: settings,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _printBill(BuildContext context) async {
    try {
      final invoiceRepo = ref.read(invoiceRepositoryProvider);
      final details = await invoiceRepo.getInvoiceWithDetails(widget.invoiceId);
      if (details == null) return;

      final settings = await ref.read(settingsRepositoryProvider).getAllSettings();
      await InvoicePdfGenerator.printInvoice(
        details: details,
        settings: settings,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error printing: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
