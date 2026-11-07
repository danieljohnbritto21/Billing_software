import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/database/app_database.dart';
import '../purchases/purchase_repository.dart';

class SupplierPurchaseOrderDetailScreen extends ConsumerWidget {
  final String orderId;
  const SupplierPurchaseOrderDetailScreen({super.key, required this.orderId});

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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final purchaseRepo = ref.watch(purchaseRepositoryProvider);
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    final dateFormat = DateFormat('dd MMMM yyyy, hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
      ),
      body: FutureBuilder<PurchaseOrderEntry?>(
        future: purchaseRepo.getPurchaseOrderById(orderId),
        builder: (context, poSnap) {
          if (poSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final po = poSnap.data;
          if (po == null) {
            return const Center(child: Text('Purchase Order not found.'));
          }

          final statusColor = _getStatusColor(po.orderStatus);

          return FutureBuilder<List<PurchaseOrderItemEntry>>(
            future: purchaseRepo.getPurchaseOrderItems(po.id),
            builder: (context, itemsSnap) {
              final items = itemsSnap.data ?? [];

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
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
                                po.poNumber,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                                ),
                                child: Text(
                                  po.orderStatus,
                                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Order Date:', style: TextStyle(color: Colors.grey.shade600)),
                              Text(dateFormat.format(po.orderedAt), style: const TextStyle(fontWeight: FontWeight.w500)),
                            ],
                          ),
                          if (po.expectedDeliveryDate != null) ...[
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Expected Delivery:', style: TextStyle(color: Colors.grey.shade600)),
                                Text(
                                  DateFormat('dd MMMM yyyy').format(po.expectedDeliveryDate!),
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ],
                          if (po.notes != null && po.notes!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('Admin Notes: ${po.notes}', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey.shade800)),
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
                          Text('Requested Items (${items.length})', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
                                      child: Text(currencyFormat.format(it.unitPricePaise / 100), textAlign: TextAlign.right),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Text(
                                        currencyFormat.format(it.totalAmountPaise / 100),
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
                              Text(currencyFormat.format(po.subtotalPaise / 100), style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Tax (GST):'),
                              Text(currencyFormat.format(po.taxPaise / 100), style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Grand Total:', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              Text(
                                currencyFormat.format(po.grandTotalPaise / 100),
                                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.green.shade800),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit Bill from this Order Button
                  FilledButton.icon(
                    onPressed: () {
                      context.push('/supplier/invoices/create?purchaseOrderId=${po.id}');
                    },
                    icon: const Icon(Icons.receipt),
                    label: const Text('Generate & Submit Invoice for this Order', style: TextStyle(fontSize: 16)),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
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
