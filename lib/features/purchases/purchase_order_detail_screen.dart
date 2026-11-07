import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/database/app_database.dart';
import '../suppliers/supplier_repository.dart';
import 'purchase_repository.dart';

class PurchaseOrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;
  const PurchaseOrderDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<PurchaseOrderDetailScreen> createState() => _PurchaseOrderDetailScreenState();
}

class _PurchaseOrderDetailScreenState extends ConsumerState<PurchaseOrderDetailScreen> {
  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
  final _dateFormat = DateFormat('dd MMMM yyyy, hh:mm a');

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
    final purchaseRepo = ref.watch(purchaseRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Order Details'),
      ),
      body: FutureBuilder<PurchaseOrderEntry?>(
        future: purchaseRepo.getPurchaseOrderById(widget.orderId),
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
                  // Header Card
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
                          FutureBuilder<SupplierEntry?>(
                            future: ref.read(supplierRepositoryProvider).getSupplierById(po.supplierId),
                            builder: (context, supSnap) {
                              final sup = supSnap.data;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sup != null ? sup.name : 'Supplier ID: ${po.supplierId}',
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  if (sup?.contactPerson != null)
                                    Text('Contact: ${sup!.contactPerson!}', style: theme.textTheme.bodyMedium),
                                  if (sup?.phone != null)
                                    Text('Phone: ${sup!.phone!}', style: theme.textTheme.bodyMedium),
                                  if (sup?.email != null)
                                    Text('Email: ${sup!.email!}', style: theme.textTheme.bodyMedium),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Ordered At:', style: TextStyle(color: Colors.grey.shade600)),
                              Text(_dateFormat.format(po.orderedAt), style: const TextStyle(fontWeight: FontWeight.w500)),
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
                              child: Text('Notes: ${po.notes}', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey.shade800)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Line Items Card
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ordered Items (${items.length})', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          if (items.isEmpty)
                            const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                          else
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
                              Text(_currencyFormat.format(po.subtotalPaise / 100), style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Tax (GST):'),
                              Text(_currencyFormat.format(po.taxPaise / 100), style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Grand Total:', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              Text(
                                _currencyFormat.format(po.grandTotalPaise / 100),
                                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.green.shade800),
                              ),
                            ],
                          ),
                        ],
                      ),
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
