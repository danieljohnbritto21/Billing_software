import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/database/app_database.dart';
import '../../core/sync/sync_provider.dart';
import '../auth/auth_provider.dart';
import '../purchases/purchase_repository.dart';

class SupplierLedgerScreen extends ConsumerStatefulWidget {
  const SupplierLedgerScreen({super.key});

  @override
  ConsumerState<SupplierLedgerScreen> createState() => _SupplierLedgerScreenState();
}

class _SupplierLedgerScreenState extends ConsumerState<SupplierLedgerScreen> {
  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
  final _dateFormat = DateFormat('dd MMM yyyy');
  Map<String, dynamic>? _summary;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLedger();
  }

  Future<void> _loadLedger() async {
    setState(() => _isLoading = true);
    final purchaseRepo = ref.read(purchaseRepositoryProvider);
    try {
      await Future.wait([
        purchaseRepo.fetchPurchaseInvoicesFromApi(),
        purchaseRepo.fetchSupplierPaymentsFromApi(),
      ]);
      final sum = await purchaseRepo.fetchSupplierLedgerSummary();
      if (mounted) setState(() => _summary = sum);
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final supplierId = ref.watch(apiClientProvider).supplierId ?? user?.supplierId ?? '';
    final purchaseRepo = ref.watch(purchaseRepositoryProvider);

    final outstanding = _summary?['outstandingBalancePaise'] ?? 0;
    final totalBilled = _summary?['totalBilledPaise'] ?? 0;
    final totalPaid = _summary?['totalPaidPaise'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Statement & Ledger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLedger,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadLedger,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Outstanding Balance Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.green.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Outstanding Payable to You', style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey.shade700)),
                    const SizedBox(height: 6),
                    _isLoading
                        ? const LinearProgressIndicator()
                        : Text(
                            _currencyFormat.format(outstanding / 100),
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                            ),
                          ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total Invoiced', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            const SizedBox(height: 2),
                            Text(_currencyFormat.format(totalBilled / 100), style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Total Received', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            const SizedBox(height: 2),
                            Text(
                              _currencyFormat.format(totalPaid / 100),
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Ledger Transactions History
            Text('Disbursement Payments Received', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            StreamBuilder<List<SupplierPaymentEntry>>(
              stream: purchaseRepo.watchSupplierPayments(supplierId: supplierId),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
                }

                final payments = snap.data ?? [];
                if (payments.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const Center(child: Text('No payment vouchers recorded yet.')),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: payments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final p = payments[index];
                    return Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade50,
                          child: const Icon(Icons.arrow_downward, color: Colors.green),
                        ),
                        title: Text(p.paymentVoucherNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${p.paymentMethod} • ${_dateFormat.format(p.paymentDate)}${p.referenceNumber != null ? '\nRef: ${p.referenceNumber}' : ''}'),
                        trailing: Text(
                          _currencyFormat.format(p.amountPaise / 100),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
