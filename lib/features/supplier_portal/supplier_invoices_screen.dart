import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/database/app_database.dart';
import '../../core/sync/sync_provider.dart';
import '../auth/auth_provider.dart';
import '../purchases/purchase_repository.dart';

class SupplierInvoicesScreen extends ConsumerStatefulWidget {
  const SupplierInvoicesScreen({super.key});

  @override
  ConsumerState<SupplierInvoicesScreen> createState() => _SupplierInvoicesScreenState();
}

class _SupplierInvoicesScreenState extends ConsumerState<SupplierInvoicesScreen> {
  String? _selectedVerificationStatus;
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
    final user = ref.watch(currentUserProvider);
    final supplierId = ref.watch(apiClientProvider).supplierId ?? user?.supplierId ?? '';
    final purchaseRepo = ref.watch(purchaseRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Submitted Bills / Invoices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => purchaseRepo.fetchPurchaseInvoicesFromApi(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/supplier/invoices/create'),
        icon: const Icon(Icons.post_add),
        label: const Text('Submit Bill'),
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            child: DropdownButtonFormField<String?>(
              value: _selectedVerificationStatus,
              decoration: const InputDecoration(
                labelText: 'Approval Status Filter',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('All Bills')),
                DropdownMenuItem(value: 'SUBMITTED', child: Text('Submitted Bills')),
                DropdownMenuItem(value: 'APPROVED', child: Text('Approved Bills')),
                DropdownMenuItem(value: 'REJECTED', child: Text('Rejected Bills')),
              ],
              onChanged: (val) => setState(() => _selectedVerificationStatus = val),
            ),
          ),
          // Invoice Stream List
          Expanded(
            child: StreamBuilder<List<PurchaseInvoiceEntry>>(
              stream: purchaseRepo.watchPurchaseInvoices(
                supplierId: supplierId,
                verificationStatus: _selectedVerificationStatus,
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
                        Text('No submitted invoices found', style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey.shade600)),
                        const SizedBox(height: 8),
                        const Text('Submit your bills for store verification and payment.'),
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
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => context.push('/supplier/invoices/${inv.id}'),
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
                                            inv.verificationStatus == 'PENDING_VERIFICATION' ? 'SUBMITTED' : inv.verificationStatus,
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
                                const SizedBox(height: 8),
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
                                            'Balance Due: ${_currencyFormat.format(inv.balanceDuePaise / 100)}',
                                            style: TextStyle(fontSize: 12, color: Colors.green.shade800, fontWeight: FontWeight.w600),
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
