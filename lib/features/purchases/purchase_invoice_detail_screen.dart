import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/database/app_database.dart';
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
      case 'PENDING_VERIFICATION':
        return Colors.amber.shade800;
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
        return Colors.orange.shade800;
      default:
        return Colors.grey.shade700;
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Details'),
      ),
      body: FutureBuilder<PurchaseInvoiceEntry?>(
        future: purchaseRepo.getPurchaseInvoiceById(widget.invoiceId),
        builder: (context, invSnap) {
          if (invSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final inv = invSnap.data;
          if (inv == null) {
            return const Center(child: Text('Purchase Invoice not found.'));
          }

          final verColor = _getVerificationColor(inv.verificationStatus);
          final payColor = _getPaymentColor(inv.paymentStatus);

          return FutureBuilder<List<PurchaseInvoiceItemEntry>>(
            future: purchaseRepo.getPurchaseInvoiceItems(inv.id),
            builder: (context, itemsSnap) {
              final items = itemsSnap.data ?? [];

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
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
                                      inv.paymentStatus,
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
                  const SizedBox(height: 24),

                  // Action Buttons for Admin
                  if (inv.verificationStatus == 'PENDING_VERIFICATION') ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isActionLoading ? null : _rejectInvoice,
                            icon: const Icon(Icons.close, color: Colors.red),
                            label: const Text('Reject Invoice', style: TextStyle(color: Colors.red)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _isActionLoading ? null : _approveInvoice,
                            icon: const Icon(Icons.check),
                            label: const Text('Approve Invoice'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else if (inv.verificationStatus == 'APPROVED' && inv.balanceDuePaise > 0) ...[
                    FilledButton.icon(
                      onPressed: () => context.push('/purchases/invoices/${inv.id}/pay'),
                      icon: const Icon(Icons.payment),
                      label: const Text('Record Supplier Payment Voucher', style: TextStyle(fontSize: 16)),
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
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
              );
            },
          );
        },
      ),
    );
  }
}
