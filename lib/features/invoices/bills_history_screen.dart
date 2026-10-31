import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import 'invoice_repository.dart';

final billsSearchProvider = StateProvider<String>((ref) => '');
final billsStatusFilterProvider = StateProvider<String>((ref) => 'ALL');

class BillsHistoryScreen extends ConsumerWidget {
  const BillsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final search = ref.watch(billsSearchProvider);
    final statusFilter = ref.watch(billsStatusFilterProvider);
    final invoiceRepo = ref.watch(invoiceRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bills & Invoices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_shopping_cart),
            tooltip: 'New Bill',
            onPressed: () => context.go('/billing'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by Invoice #, customer, or phone...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
                suffixIcon: search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () =>
                            ref.read(billsSearchProvider.notifier).state = '',
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
              onChanged: (val) {
                ref.read(billsSearchProvider.notifier).state = val;
              },
            ),
          ),

          // Status Filter Chips
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _filterChip(ref, 'All Bills', 'ALL', statusFilter),
                _filterChip(ref, 'Paid', AppConstants.statusPaid, statusFilter),
                _filterChip(ref, 'Partially Paid', AppConstants.statusPartial, statusFilter),
                _filterChip(ref, 'Pending', AppConstants.statusPending, statusFilter),
                _filterChip(ref, 'Cancelled', AppConstants.statusCancelled, statusFilter),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // Invoices List
          Expanded(
            child: StreamBuilder<List<InvoiceSummary>>(
              stream: invoiceRepo.watchInvoicesSummary(
                searchQuery: search,
                paymentStatus: statusFilter,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final invoices = snapshot.data ?? [];

                if (invoices.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          const Text(
                            'No Invoices Found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            search.isNotEmpty
                                ? 'No bill matched "$search"'
                                : 'Created bills will appear here with instant reprint, PDF export, and individual notes.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: invoices.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final summary = invoices[index];
                    return _InvoiceCard(
                      summary: summary,
                      onTap: () {
                        context.push('/bills/${summary.invoice.id}');
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(
      WidgetRef ref, String label, String value, String currentSelected) {
    final isSelected = currentSelected == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) =>
            ref.read(billsStatusFilterProvider.notifier).state = value,
        selectedColor: const Color(0xFFDCFCE7),
        checkmarkColor: AppTheme.primaryGreen,
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.primaryGreen : AppTheme.textDark,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final InvoiceSummary summary;
  final VoidCallback onTap;

  const _InvoiceCard({
    required this.summary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final inv = summary.invoice;
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final dateStr = dateFormat.format(inv.createdAt);
    final balanceDue = inv.grandTotalPaise - inv.paidAmountPaise;

    Color statusColor;
    if (inv.isCancelled) {
      statusColor = AppTheme.statusCancelled;
    } else if (inv.paymentStatus == AppConstants.statusPaid) {
      statusColor = AppTheme.statusPaid;
    } else if (inv.paymentStatus == AppConstants.statusPartial) {
      statusColor = Colors.amber.shade900;
    } else {
      statusColor = AppTheme.statusPending;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppTheme.borderLight, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Invoice #, Items, Order Status, Payment Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          inv.invoiceNumber,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${summary.itemCount} items',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      if (inv.cashierName != null && inv.cashierName!.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          '• ${inv.cashierName}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ],
                  ),
                  Wrap(
                    spacing: 6,
                    children: [
                      // Order Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          inv.orderStatus,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1D4ED8),
                          ),
                        ),
                      ),
                      // Payment Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          inv.isCancelled ? 'Cancelled' : inv.paymentStatus,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Middle Row: Customer (if any) & Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      inv.customerName != null && inv.customerName!.isNotEmpty
                          ? 'Customer: ${inv.customerName}'
                          : dateStr,
                      style: TextStyle(
                        fontSize: 12,
                        color: inv.customerName != null &&
                                inv.customerName!.isNotEmpty
                            ? AppTheme.textDark
                            : AppTheme.textMuted,
                        fontWeight: inv.customerName != null &&
                                inv.customerName!.isNotEmpty
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          inv.paymentMethod,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            CurrencyFormatter.formatPaise(inv.grandTotalPaise),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: inv.isCancelled
                                  ? Colors.grey
                                  : AppTheme.primaryGreen,
                            ),
                          ),
                          if (balanceDue > 0 && !inv.isCancelled)
                            Text(
                              'Due: ${CurrencyFormatter.formatPaise(balanceDue)}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              // INDIVIDUAL BILL NOTE INDICATOR & PREVIEW
              if (summary.hasNote && summary.notePreview != null) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.noteBannerBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppTheme.noteBannerBorder, width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.sticky_note_2_outlined,
                        size: 15,
                        color: AppTheme.noteBannerText,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Note: ${summary.notePreview}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.noteBannerText,
                          ),
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
    );
  }
}
