import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/database/app_database.dart';
import '../../core/sync/sync_provider.dart';
import '../auth/auth_provider.dart';
import '../products/product_repository.dart';
import '../purchases/purchase_repository.dart';

class SupplierDashboardScreen extends ConsumerStatefulWidget {
  const SupplierDashboardScreen({super.key});

  @override
  ConsumerState<SupplierDashboardScreen> createState() => _SupplierDashboardScreenState();
}

class _SupplierDashboardScreenState extends ConsumerState<SupplierDashboardScreen> {
  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
  Map<String, dynamic>? _ledgerSummary;
  bool _isLoadingSummary = false;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() => _isLoadingSummary = true);
    final purchaseRepo = ref.read(purchaseRepositoryProvider);
    try {
      await Future.wait([
        purchaseRepo.fetchPurchaseOrdersFromApi(),
        purchaseRepo.fetchPurchaseInvoicesFromApi(),
        purchaseRepo.fetchSupplierPaymentsFromApi(),
      ]);
      final summary = await purchaseRepo.fetchSupplierLedgerSummary();
      if (mounted) {
        setState(() => _ledgerSummary = summary);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingSummary = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final supplierId = ref.watch(apiClientProvider).supplierId ?? user?.supplierId;
    final purchaseRepo = ref.watch(purchaseRepositoryProvider);
    final productRepo = ref.watch(productRepositoryProvider);

    final outstandingPaise = _ledgerSummary?['outstandingBalancePaise'] ?? 0;
    final totalBilledPaise = _ledgerSummary?['totalBilledPaise'] ?? 0;
    final totalPaidPaise = _ledgerSummary?['totalPaidPaise'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Supplier Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _refreshData,
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Profile',
            onPressed: () => context.push('/supplier/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Welcome Header Card
            Card(
              elevation: 0,
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: theme.colorScheme.primary,
                      child: const Icon(Icons.storefront, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? 'Supplier Partner',
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.username ?? 'Vendor Account',
                            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'SUPPLIER ROLE',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Live Outstanding Balance Banner
            Card(
              elevation: 2,
              color: Colors.blueGrey.shade900,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'OUTSTANDING RECEIVABLES',
                          style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                        if (_isLoadingSummary)
                          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        else
                          const Icon(Icons.account_balance_wallet, color: Colors.white70, size: 20),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _currencyFormat.format(outstandingPaise / 100),
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white24, height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Invoiced', style: TextStyle(color: Colors.white60, fontSize: 11)),
                            const SizedBox(height: 2),
                            Text(
                              _currencyFormat.format(totalBilledPaise / 100),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Disbursements Received', style: TextStyle(color: Colors.white60, fontSize: 11)),
                            const SizedBox(height: 2),
                            Text(
                              _currencyFormat.format(totalPaidPaise / 100),
                              style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Quick Metrics Grid
            Row(
              children: [
                // Products Count
                Expanded(
                  child: StreamBuilder<List<ProductWithCategory>>(
                    stream: productRepo.watchSupplierProducts(supplierId ?? ''),
                    builder: (context, snap) {
                      final count = snap.data?.length ?? 0;
                      return _buildMetricCard(
                        title: 'My Catalog',
                        count: '$count Products',
                        icon: Icons.inventory_2_outlined,
                        color: Colors.indigo,
                        onTap: () => context.push('/supplier/catalog'),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Open POs Count
                Expanded(
                  child: StreamBuilder<List<PurchaseOrderEntry>>(
                    stream: purchaseRepo.watchPurchaseOrders(supplierId: supplierId),
                    builder: (context, snap) {
                      final pos = snap.data ?? [];
                      final openCount = pos.where((p) => p.orderStatus == 'SENT' || p.orderStatus == 'PARTIALLY_RECEIVED').length;
                      return _buildMetricCard(
                        title: 'Open Orders',
                        count: '$openCount New',
                        icon: Icons.shopping_bag_outlined,
                        color: Colors.orange,
                        onTap: () => context.push('/supplier/orders'),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Invoices Count
                Expanded(
                  child: StreamBuilder<List<PurchaseInvoiceEntry>>(
                    stream: purchaseRepo.watchPurchaseInvoices(supplierId: supplierId),
                    builder: (context, snap) {
                      final count = snap.data?.length ?? 0;
                      return _buildMetricCard(
                        title: 'Submitted Bills',
                        count: '$count Invoices',
                        icon: Icons.receipt_long_outlined,
                        color: Colors.teal,
                        onTap: () => context.push('/supplier/invoices'),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Ledger
                Expanded(
                  child: _buildMetricCard(
                    title: 'Account Ledger',
                    count: 'Statement',
                    icon: Icons.history_edu_outlined,
                    color: Colors.purple,
                    onTap: () => context.push('/supplier/ledger'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Quick Actions Bar
            Text('Quick Operations', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => context.push('/supplier/invoices/create'),
                    icon: const Icon(Icons.post_add),
                    label: const Text('Submit Bill'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/supplier/catalog/add'),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Product'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recent Purchase Orders Received
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Orders From Admin', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => context.push('/supplier/orders'),
                  child: const Text('See All'),
                ),
              ],
            ),
            StreamBuilder<List<PurchaseOrderEntry>>(
              stream: purchaseRepo.watchPurchaseOrders(supplierId: supplierId),
              builder: (context, snap) {
                final orders = snap.data ?? [];
                if (orders.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const Center(child: Text('No orders received yet.')),
                  );
                }

                final recent = orders.take(3).toList();
                return Column(
                  children: recent.map((po) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade50,
                          child: Icon(Icons.shopping_cart_outlined, color: Colors.blue.shade700),
                        ),
                        title: Text(po.poNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(DateFormat('dd MMM yyyy').format(po.orderedAt)),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _currencyFormat.format(po.grandTotalPaise / 100),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              po.orderStatus,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: po.orderStatus == 'RECEIVED' ? Colors.green : Colors.orange.shade800,
                              ),
                            ),
                          ],
                        ),
                        onTap: () => context.push('/supplier/orders/${po.id}'),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 12),
              Text(count, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }
}
