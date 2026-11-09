import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/database/app_database.dart';
import '../suppliers/supplier_repository.dart';
import 'purchase_repository.dart';

class PurchaseInvoicesScreen extends ConsumerStatefulWidget {
  const PurchaseInvoicesScreen({super.key});

  @override
  ConsumerState<PurchaseInvoicesScreen> createState() => _PurchaseInvoicesScreenState();
}

class _PurchaseInvoicesScreenState extends ConsumerState<PurchaseInvoicesScreen> {
  String? _selectedSupplierId;
  String? _selectedVerificationStatus;
  String? _selectedPaymentStatus;
  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
  final _dateFormat = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(purchaseRepositoryProvider).fetchPurchaseInvoicesFromApi();
    });
  }

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final purchaseRepo = ref.watch(purchaseRepositoryProvider);
    final suppliersAsync = ref.watch(suppliersStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Invoices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Sync invoices',
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Syncing invoices...'), duration: Duration(seconds: 1)),
              );
              await purchaseRepo.fetchPurchaseInvoicesFromApi();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips and Controls
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            child: Column(
              children: [
                Row(
                  children: [
                    // Verification Status Filter
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String?>(
                        value: _selectedVerificationStatus,
                        decoration: const InputDecoration(
                          labelText: 'Approval',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('All Statuses')),
                          DropdownMenuItem(value: 'SUBMITTED', child: Text('Submitted')),
                          DropdownMenuItem(value: 'APPROVED', child: Text('Approved')),
                          DropdownMenuItem(value: 'REJECTED', child: Text('Rejected')),
                        ],
                        onChanged: (val) => setState(() => _selectedVerificationStatus = val),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Payment Status Filter
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String?>(
                        value: _selectedPaymentStatus,
                        decoration: const InputDecoration(
                          labelText: 'Payment',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('All Payments')),
                          DropdownMenuItem(value: 'PENDING', child: Text('Unpaid')),
                          DropdownMenuItem(value: 'PARTIALLY_PAID', child: Text('Partially Paid')),
                          DropdownMenuItem(value: 'PAID', child: Text('Paid')),
                        ],
                        onChanged: (val) => setState(() => _selectedPaymentStatus = val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Supplier Filter
                suppliersAsync.when(
                  data: (suppliers) => DropdownButtonFormField<String?>(
                    value: _selectedSupplierId,
                    decoration: const InputDecoration(
                      labelText: 'Filter by Supplier',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Suppliers')),
                      ...suppliers.map(
                        (s) => DropdownMenuItem(
                          value: s.id,
                          child: Text(s.name, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: (val) => setState(() => _selectedSupplierId = val),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          // Invoices Stream List
          Expanded(
            child: StreamBuilder<List<PurchaseInvoiceEntry>>(
              stream: purchaseRepo.watchPurchaseInvoices(
                supplierId: _selectedSupplierId,
                verificationStatus: _selectedVerificationStatus,
                paymentStatus: _selectedPaymentStatus,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final invoices = snapshot.data ?? [];
                if (invoices.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No purchase invoices found',
                          style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 8),
                        const Text('Supplier submitted bills will appear here for verification.'),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => purchaseRepo.fetchPurchaseInvoicesFromApi(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: invoices.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final inv = invoices[index];
                      final verColor = _getVerificationColor(inv.verificationStatus);
                      final payColor = _getPaymentColor(inv.paymentStatus);

                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: verColor.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => context.push('/purchases/invoices/${inv.id}'),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      inv.invoiceNumber,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: verColor.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: verColor.withValues(alpha: 0.4)),
                                          ),
                                          child: Text(
                                            inv.verificationStatus == 'PENDING_VERIFICATION'
                                                ? 'SUBMITTED'
                                                : inv.verificationStatus,
                                            style: TextStyle(color: verColor, fontWeight: FontWeight.bold, fontSize: 10),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: payColor.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: payColor.withValues(alpha: 0.4)),
                                          ),
                                          child: Text(
                                            inv.paymentStatus == 'PENDING' ? 'UNPAID' : inv.paymentStatus,
                                            style: TextStyle(color: payColor, fontWeight: FontWeight.bold, fontSize: 10),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                suppliersAsync.when(
                                  data: (suppliers) {
                                    final sup = suppliers.cast<SupplierEntry?>().firstWhere(
                                          (s) => s?.id == inv.supplierId,
                                          orElse: () => null,
                                        );
                                    return Text(
                                      'Supplier: ${sup?.name ?? 'Vendor ID: ${inv.supplierId.substring(0, 8)}...'}',
                                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                                    );
                                  },
                                  loading: () => const Text('Loading supplier...'),
                                  error: (_, __) => Text('Supplier ID: ${inv.supplierId}'),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Date: ${_dateFormat.format(inv.invoiceDate)}',
                                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          _currencyFormat.format(inv.grandTotalPaise / 100),
                                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                        ),
                                        if (inv.balanceDuePaise > 0)
                                          Text(
                                            'Due: ${_currencyFormat.format(inv.balanceDuePaise / 100)}',
                                            style: TextStyle(fontSize: 12, color: Colors.red.shade700, fontWeight: FontWeight.w600),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
