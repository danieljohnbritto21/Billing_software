import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/database/app_database.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../billing/cart_provider.dart';
import '../printer/invoice_pdf_generator.dart';
import '../products/product_repository.dart';
import '../settings/settings_repository.dart';
import 'invoice_repository.dart';

final cashierHistorySearchProvider = StateProvider<String>((ref) => '');

class CashierHistoryScreen extends ConsumerStatefulWidget {
  const CashierHistoryScreen({super.key});

  @override
  ConsumerState<CashierHistoryScreen> createState() => _CashierHistoryScreenState();
}

class _CashierHistoryScreenState extends ConsumerState<CashierHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final search = ref.watch(cashierHistorySearchProvider);
    final invoiceRepo = ref.watch(invoiceRepositoryProvider);
    final pendingCountStream = invoiceRepo.watchPendingOrdersCount();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppTheme.posYellowHeader,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text(
          'Order History',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_shopping_cart),
            tooltip: 'New Order',
            onPressed: () => context.go('/billing'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(104),
          child: Column(
            children: [
              // Search Input
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1)),
                    ],
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search order #, customer, or table...',
                      hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                      prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
                      suffixIcon: search.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () => ref.read(cashierHistorySearchProvider.notifier).state = '',
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                    onChanged: (val) => ref.read(cashierHistorySearchProvider.notifier).state = val,
                  ),
                ),
              ),

              // Two Tabs: Pending Orders (with badge) & Completed Orders
              StreamBuilder<int>(
                stream: pendingCountStream,
                builder: (context, snapshot) {
                  final pendingCount = snapshot.data ?? 0;

                  return Container(
                    color: Colors.white,
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: const Color(0xFFB45309),
                      indicatorWeight: 3,
                      labelColor: const Color(0xFF1E293B),
                      unselectedLabelColor: const Color(0xFF64748B),
                      labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Pending Orders'),
                              if (pendingCount > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEA580C),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$pendingCount',
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const Tab(text: 'Completed Orders'),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Pending Orders
          _ordersList(context, ref, orderStatus: AppConstants.orderPending, searchQuery: search),
          // Tab 2: Completed Orders
          _ordersList(context, ref, orderStatus: AppConstants.orderCompleted, searchQuery: search),
        ],
      ),
    );
  }

  Widget _ordersList(
    BuildContext context,
    WidgetRef ref, {
    required String orderStatus,
    required String searchQuery,
  }) {
    final invoiceRepo = ref.watch(invoiceRepositoryProvider);
    final ordersStream = invoiceRepo.watchOrdersWithDetails(
      orderStatus: orderStatus,
      searchQuery: searchQuery,
    );

    return StreamBuilder<List<InvoiceDetails>>(
      stream: ordersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data ?? [];

        if (orders.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    orderStatus == AppConstants.orderPending ? Icons.pending_actions_outlined : Icons.receipt_long_outlined,
                    size: 60,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    orderStatus == AppConstants.orderPending ? 'No Pending Orders' : 'No Completed Orders',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    orderStatus == AppConstants.orderPending
                        ? 'Orders saved as Pending from the Cart will appear here for Add More, KOT, and final billing.'
                        : 'Completed sales and paid orders will appear here for reprinting.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final orderDetails = orders[index];
            return _orderCard(context, ref, orderDetails);
          },
        );
      },
    );
  }

  Widget _orderCard(BuildContext context, WidgetRef ref, InvoiceDetails details) {
    final inv = details.invoice;
    final isPending = inv.orderStatus == AppConstants.orderPending;
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final formattedDate = dateFormat.format(inv.createdAt);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isPending ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0),
          width: isPending ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Status badge, Order #, Date & Time, More Options
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isPending ? const Color(0xFFFFFBEB) : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isPending ? const Color(0xFFF59E0B) : const Color(0xFF16A34A),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        inv.orderStatus.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: isPending ? const Color(0xFFB45309) : const Color(0xFF15803D),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      inv.invoiceNumber,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20, color: Color(0xFF64748B)),
                  onSelected: (val) {
                    if (val == 'view') {
                      context.go('/bills/${inv.id}');
                    } else if (val == 'cancel') {
                      _confirmCancelOrder(context, ref, inv);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'view', child: Text('View Details')),
                    if (isPending)
                      const PopupMenuItem(
                        value: 'cancel',
                        child: Text('Cancel Order', style: TextStyle(color: Colors.red)),
                      ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Order Type & Table & Date
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        inv.orderType == AppConstants.orderTypeDineIn
                            ? Icons.table_restaurant
                            : (inv.orderType == AppConstants.orderTypeDelivery ? Icons.delivery_dining : Icons.takeout_dining),
                        size: 14,
                        color: const Color(0xFF334155),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${inv.orderType.toUpperCase()}${inv.tableNumber != null ? ' • ${inv.tableNumber}' : ''}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF334155)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formattedDate,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),

            // Customer Name
            if (inv.customerName != null && inv.customerName!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.person, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Text(
                    inv.customerName!,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                  ),
                  if (inv.customerPhone != null && inv.customerPhone!.isNotEmpty)
                    Text(' (${inv.customerPhone})', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                ],
              ),
            ],

            const Divider(height: 16),

            // Order Items Summary List
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: details.items.map((item) {
                final qty = item.quantity % 1 == 0 ? item.quantity.toInt().toString() : item.quantity.toString();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item.productName} x $qty ${item.unit}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.formatPaise(item.totalAmountPaise),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

            const Divider(height: 16),

            // Total Amount & Item Count
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${details.items.length} items',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                ),
                Row(
                  children: [
                    const Text('Total: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                    Text(
                      CurrencyFormatter.formatPaise(inv.grandTotalPaise),
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ACTIONS ROW
            if (isPending) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // 1. "Add More" - Reopens order into cart
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add More', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    onPressed: () => _handleReopenOrder(context, ref, details),
                  ),

                  // 2. "Print KOT"
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFB45309),
                      side: const BorderSide(color: Color(0xFFF59E0B)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.restaurant, size: 16),
                    label: const Text('Print KOT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    onPressed: () async {
                      final settings = await ref.read(settingsRepositoryProvider).getAllSettings();
                      await InvoicePdfGenerator.printKot(details: details, settings: settings);
                    },
                  ),

                  // 3. "Print Bill"
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF15803D),
                      side: const BorderSide(color: Color(0xFF16A34A)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.print, size: 16),
                    label: const Text('Print Bill', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    onPressed: () async {
                      final settings = await ref.read(settingsRepositoryProvider).getAllSettings();
                      await InvoicePdfGenerator.printInvoice(details: details, settings: settings);
                    },
                  ),

                  // 4. "Complete Order"
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.posYellowHeader,
                      foregroundColor: const Color(0xFF1E293B),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('Complete Order', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                    onPressed: () => _handleCompletePendingOrder(context, ref, details),
                  ),
                ],
              ),
            ] else ...[
              // Completed Orders Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1E293B),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: const Text('View Bill', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    onPressed: () => context.go('/bills/${inv.id}'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.posYellowHeader,
                      foregroundColor: const Color(0xFF1E293B),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.print, size: 16),
                    label: const Text('Reprint Bill', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                    onPressed: () async {
                      final settings = await ref.read(settingsRepositoryProvider).getAllSettings();
                      await InvoicePdfGenerator.printInvoice(details: details, settings: settings);
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Reopens a pending order into the active cart for adding more items without creating duplicate invoices
  Future<void> _handleReopenOrder(BuildContext context, WidgetRef ref, InvoiceDetails details) async {
    final products = await ref.read(productRepositoryProvider).getAllProducts();
    final availableProducts = products.map((p) => p.product).toList();

    ref.read(cartProvider.notifier).loadPendingOrder(
      details: details,
      availableProducts: availableProducts,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order ${details.invoice.invoiceNumber} loaded! Add items from Menu or proceed to Cart.'),
          backgroundColor: const Color(0xFFB45309),
        ),
      );
      context.go('/billing');
    }
  }

  /// Completes a pending order directly from History by recording payment
  void _handleCompletePendingOrder(BuildContext context, WidgetRef ref, InvoiceDetails details) {
    String selectedMethod = AppConstants.paymentCash;
    int amountPaidPaise = details.invoice.grandTotalPaise;
    final paidController = TextEditingController(text: CurrencyFormatter.paiseToRupees(amountPaidPaise).toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final double enteredRupees = double.tryParse(paidController.text) ?? 0.0;
            final int currentPaidPaise = CurrencyFormatter.rupeesToPaise(enteredRupees);

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Complete ${details.invoice.invoiceNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Amount:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          CurrencyFormatter.formatPaise(details.invoice.grandTotalPaise),
                          style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF92400E)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: [
                      AppConstants.paymentCash,
                      AppConstants.paymentUpi,
                      AppConstants.paymentCard,
                    ].map((method) {
                      final isSelected = selectedMethod == method;
                      return ChoiceChip(
                        label: Text(method),
                        selected: isSelected,
                        selectedColor: AppTheme.posYellowHeader,
                        onSelected: (val) {
                          if (val) setDialogState(() => selectedMethod = method);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: paidController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Amount Paid (₹)',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.posYellowHeader,
                    foregroundColor: const Color(0xFF1E293B),
                  ),
                  onPressed: () async {
                    Navigator.pop(dialogCtx);
                    await ref.read(invoiceRepositoryProvider).completeOrder(
                      invoiceId: details.invoice.id,
                      paidAmountPaise: currentPaidPaise,
                      paymentMethod: selectedMethod,
                    );
                    final settings = await ref.read(settingsRepositoryProvider).getAllSettings();
                    final updatedDetails = await ref.read(invoiceRepositoryProvider).getInvoiceWithDetails(details.invoice.id);
                    if (updatedDetails != null) {
                      await InvoicePdfGenerator.printInvoice(details: updatedDetails, settings: settings);
                    }
                  },
                  child: const Text('Complete & Print', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmCancelOrder(BuildContext context, WidgetRef ref, InvoiceEntry invoice) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Order?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to cancel order ${invoice.invoiceNumber}?'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for cancellation',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep Active')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final reason = reasonController.text.trim().isEmpty ? 'Cancelled by cashier' : reasonController.text.trim();
      await ref.read(invoiceRepositoryProvider).cancelInvoice(invoice.id, reason);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order cancelled')),
        );
      }
    }
  }
}
