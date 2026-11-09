import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/database/app_database.dart';
import '../suppliers/supplier_repository.dart';
import 'purchase_repository.dart';

class SupplierPaymentScreen extends ConsumerStatefulWidget {
  final String invoiceId;
  const SupplierPaymentScreen({super.key, required this.invoiceId});

  @override
  ConsumerState<SupplierPaymentScreen> createState() => _SupplierPaymentScreenState();
}

class _SupplierPaymentScreenState extends ConsumerState<SupplierPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedMethod = 'Bank Transfer';
  bool _isLoading = false;

  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit(PurchaseInvoiceEntry inv) async {
    if (!_formKey.currentState!.validate()) return;

    final amountRupees = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final amountPaise = (amountRupees * 100).round();

    if (amountPaise <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment amount must be greater than zero.')),
      );
      return;
    }

    if (amountPaise > inv.balanceDuePaise) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment exceeds remaining balance due of ${_currencyFormat.format(inv.balanceDuePaise / 100)}.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(purchaseRepositoryProvider).recordSupplierPayment(
            purchaseInvoiceId: inv.id,
            supplierId: inv.supplierId,
            amountPaise: amountPaise,
            paymentMethod: _selectedMethod,
            referenceNumber: _referenceController.text.trim().isNotEmpty ? _referenceController.text.trim() : null,
            notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment voucher recorded successfully!'), backgroundColor: Colors.green),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final purchaseRepo = ref.watch(purchaseRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Supplier Payment'),
      ),
      body: FutureBuilder<PurchaseInvoiceEntry?>(
        future: purchaseRepo.getPurchaseInvoiceById(widget.invoiceId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final inv = snapshot.data;
          if (inv == null) {
            return const Center(child: Text('Purchase invoice not found.'));
          }

          if (inv.verificationStatus == 'REJECTED' || inv.verificationStatus == 'CANCELLED') {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.block, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Invoice ${inv.verificationStatus}',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Supplier payments cannot be disbursed against ${inv.verificationStatus.toLowerCase()} invoices.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          if (inv.balanceDuePaise <= 0) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                    const SizedBox(height: 16),
                    Text(
                      'Invoice Fully Paid',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text('This invoice has zero remaining balance due.'),
                  ],
                ),
              ),
            );
          }

          if (_amountController.text.isEmpty) {
            _amountController.text = (inv.balanceDuePaise / 100).toStringAsFixed(2);
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Invoice Balance Summary Card
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Invoice: ${inv.invoiceNumber}', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        FutureBuilder<SupplierEntry?>(
                          future: ref.read(supplierRepositoryProvider).getSupplierById(inv.supplierId),
                          builder: (context, supSnap) {
                            return Text('Supplier: ${supSnap.data?.name ?? inv.supplierId}');
                          },
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Invoice Grand Total:'),
                            Text(_currencyFormat.format(inv.grandTotalPaise / 100), style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Already Paid:'),
                            Text(_currencyFormat.format(inv.amountPaidPaise / 100), style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Balance Due:', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.red.shade800)),
                            Text(
                              _currencyFormat.format(inv.balanceDuePaise / 100),
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.red.shade800),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Disbursement Voucher Form Card
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Payment Voucher Details', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Payment Amount (₹) *',
                            prefixIcon: Icon(Icons.currency_rupee),
                            border: OutlineInputBorder(),
                          ),
                          validator: (val) {
                            final n = double.tryParse(val ?? '');
                            if (n == null || n <= 0) return 'Please enter a valid amount';
                            if ((n * 100).round() > inv.balanceDuePaise) {
                              return 'Amount exceeds remaining balance';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedMethod,
                          decoration: const InputDecoration(
                            labelText: 'Payment Method *',
                            prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer (NEFT/RTGS/IMPS)')),
                            DropdownMenuItem(value: 'UPI', child: Text('UPI / QR')),
                            DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                            DropdownMenuItem(value: 'Cheque', child: Text('Cheque')),
                            DropdownMenuItem(value: 'Card', child: Text('Debit/Credit Card')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedMethod = val);
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _referenceController,
                          decoration: const InputDecoration(
                            labelText: 'Transaction / UTR / Reference No.',
                            prefixIcon: Icon(Icons.receipt_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _notesController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Disbursement Notes',
                            prefixIcon: Icon(Icons.note_alt_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                FilledButton.icon(
                  onPressed: _isLoading ? null : () => _submit(inv),
                  icon: _isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check),
                  label: Text(_isLoading ? 'Recording Payment...' : 'Disburse & Record Voucher', style: const TextStyle(fontSize: 16)),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
