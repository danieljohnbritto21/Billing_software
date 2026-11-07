import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/database/app_database.dart';
import '../../core/sync/sync_provider.dart';
import '../auth/auth_provider.dart';
import '../purchases/purchase_repository.dart';

class SupplierPurchaseOrdersScreen extends ConsumerStatefulWidget {
  const SupplierPurchaseOrdersScreen({super.key});

  @override
  ConsumerState<SupplierPurchaseOrdersScreen> createState() => _SupplierPurchaseOrdersScreenState();
}

class _SupplierPurchaseOrdersScreenState extends ConsumerState<SupplierPurchaseOrdersScreen> {
  String? _selectedStatus;
  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
  final _dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(purchaseRepositoryProvider).fetchPurchaseOrdersFromApi();
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'DRAFT':
        return Colors.grey.shade700;
      case 'SENT':
        return Colors.blue.shade700;
      case 'PARTIALLY_RECEIVED':
        return Colors.orange.shade700;
      case 'RECEIVED':
        return Colors.green.shade700;
      case 'CANCELLED':
        return Colors.red.shade700;
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
        title: const Text('Purchase Orders Received'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => purchaseRepo.fetchPurchaseOrdersFromApi(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            child: DropdownButtonFormField<String?>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Order Status Filter',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('All Orders')),
                DropdownMenuItem(value: 'SENT', child: Text('New Orders (Sent)')),
                DropdownMenuItem(value: 'PARTIALLY_RECEIVED', child: Text('Partially Received')),
                DropdownMenuItem(value: 'RECEIVED', child: Text('Fulfilled / Received')),
                DropdownMenuItem(value: 'CANCELLED', child: Text('Cancelled')),
              ],
              onChanged: (val) => setState(() => _selectedStatus = val),
            ),
          ),
          // Orders List
          Expanded(
            child: StreamBuilder<List<PurchaseOrderEntry>>(
              stream: purchaseRepo.watchPurchaseOrders(
                supplierId: supplierId,
                orderStatus: _selectedStatus,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final orders = snapshot.data ?? [];
                if (orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text('No purchase orders found', style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey.shade600)),
                        const SizedBox(height: 8),
                        const Text('Orders placed by the store will appear here.'),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => purchaseRepo.fetchPurchaseOrdersFromApi(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final po = orders[index];
                      final statusColor = _getStatusColor(po.orderStatus);

                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => context.push('/supplier/orders/${po.id}'),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      po.poNumber,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                                      ),
                                      child: Text(
                                        po.orderStatus,
                                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _dateFormat.format(po.orderedAt),
                                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                                    ),
                                    Text(
                                      _currencyFormat.format(po.grandTotalPaise / 100),
                                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.green.shade800),
                                    ),
                                  ],
                                ),
                                if (po.expectedDeliveryDate != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Delivery By: ${DateFormat('dd MMM yyyy').format(po.expectedDeliveryDate!)}',
                                    style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade700),
                                  ),
                                ],
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
