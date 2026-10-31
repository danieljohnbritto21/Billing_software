import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../categories/category_repository.dart';
import '../invoices/invoice_repository.dart';
import '../products/product_repository.dart';
import 'dashboard_repository.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Seed default categories and sample items on first run if empty
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(categoryRepositoryProvider).seedDefaultCategoriesIfEmpty();
      await ref.read(productRepositoryProvider).seedSampleProductsIfEmpty();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboardRepo = ref.watch(dashboardRepositoryProvider);
    final invoiceRepo = ref.watch(invoiceRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.restaurant,
                  color: AppTheme.primaryGreen, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('FoodBill Pro'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_shopping_cart),
            tooltip: 'New Bill',
            color: AppTheme.primaryGreen,
            onPressed: () => context.go('/billing'),
          ),
        ],
      ),
      body: StreamBuilder<DashboardStats>(
        stream: dashboardRepo.watchDashboardStats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final stats = snapshot.data;
          if (stats == null) {
            return const Center(child: Text('Unable to load dashboard stats'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Hero Banner: Today's Sales
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryGreen, AppTheme.primaryGreenDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "TODAY'S TOTAL SALES",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${stats.todayBillsCount} Bills Today',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      CurrencyFormatter.formatPaise(stats.todaySalesPaise),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _heroMetric(
                          'Today Collected',
                          CurrencyFormatter.formatPaise(
                              stats.todayCollectionsPaise),
                        ),
                        Container(
                            height: 24,
                            width: 1,
                            color: Colors.white24,
                            margin: const EdgeInsets.symmetric(horizontal: 16)),
                        _heroMetric(
                          'Total Pending Due',
                          CurrencyFormatter.formatPaise(
                              stats.totalPendingAmountPaise),
                          highlight: stats.totalPendingAmountPaise > 0,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // KPI Summary Cards
              const Text(
                'Business Overview',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _kpiCard(
                      title: 'Total Invoices',
                      value: stats.totalBillsCount.toString(),
                      subtitle: '${stats.completedOrdersCount} completed',
                      icon: Icons.receipt_long_outlined,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _kpiCard(
                      title: 'Total Collected',
                      value: CurrencyFormatter.formatPaise(
                          stats.totalCollectionsPaise),
                      subtitle: 'All-time collections',
                      icon: Icons.account_balance_wallet_outlined,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _kpiCard(
                      title: 'Pending Balance',
                      value: CurrencyFormatter.formatPaise(
                          stats.totalPendingAmountPaise),
                      subtitle: '${stats.pendingPaymentsCount} pending bills',
                      icon: Icons.pending_actions_outlined,
                      color: stats.totalPendingAmountPaise > 0
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _kpiCard(
                      title: 'Pending Orders',
                      value: stats.pendingOrdersCount.toString(),
                      subtitle: 'Active in kitchen / queue',
                      icon: Icons.hourglass_top_outlined,
                      color: const Color(0xFFD97706),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Payment Breakdown Grid (Cash, UPI, Card)
              const Text(
                "Today's Payment Methods",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _collectionCard(
                    title: 'Cash',
                    amountPaise: stats.cashCollectionsPaise,
                    icon: Icons.payments_outlined,
                    color: const Color(0xFF16A34A),
                  ),
                  const SizedBox(width: 10),
                  _collectionCard(
                    title: 'UPI / QR',
                    amountPaise: stats.upiCollectionsPaise,
                    icon: Icons.qr_code,
                    color: const Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 10),
                  _collectionCard(
                    title: 'Card',
                    amountPaise: stats.cardCollectionsPaise,
                    icon: Icons.credit_card,
                    color: const Color(0xFF9333EA),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Quick Actions Row
              Row(
                children: [
                  Expanded(
                    child: _actionButton(
                      context: context,
                      label: 'New Bill',
                      icon: Icons.add_shopping_cart,
                      color: AppTheme.primaryGreen,
                      onTap: () => context.go('/billing'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _actionButton(
                      context: context,
                      label: 'Categories',
                      icon: Icons.category_outlined,
                      color: const Color(0xFF8B5CF6),
                      onTap: () => context.push('/categories'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _actionButton(
                      context: context,
                      label: 'Staff Users',
                      icon: Icons.people_outline,
                      color: const Color(0xFF0284C7),
                      onTap: () => context.push('/cashiers'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Pending Customers / Outstanding Debts Section
              StreamBuilder<List<CustomerPendingSummary>>(
                stream: invoiceRepo.watchCustomerPendingSummaries(),
                builder: (context, pendingSnapshot) {
                  final pendingList = pendingSnapshot.data ?? [];
                  if (pendingList.isEmpty) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.account_balance_wallet,
                                  color: Color(0xFFDC2626), size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Pending Amounts / Debts',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${pendingList.length} Customers',
                              style: const TextStyle(
                                color: Color(0xFFDC2626),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFFECACA)),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: pendingList.length > 5
                              ? 5
                              : pendingList.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (context, idx) {
                            final p = pendingList[idx];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFFFEE2E2),
                                child: const Icon(Icons.person_outline,
                                    color: Color(0xFFDC2626), size: 20),
                              ),
                              title: Text(
                                p.customerName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              subtitle: Text(
                                '${p.totalBillsCount} bill(s) • Total: ${CurrencyFormatter.formatPaise(p.totalAmountPaise)} • Paid: ${CurrencyFormatter.formatPaise(p.paidAmountPaise)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'DUE',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFDC2626),
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.formatPaise(
                                        p.remainingAmountPaise),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFFDC2626),
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () => context.go('/bills'),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),

              // 7-Day Sales Trend Chart
              const Text(
                '7-Day Sales Trend',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    height: 180,
                    child: stats.last7DaysSales.every((p) => p.salesPaise == 0)
                        ? const Center(
                            child: Text(
                              'Sales graph will appear as you create bills',
                              style: TextStyle(
                                  color: AppTheme.textMuted, fontSize: 13),
                            ),
                          )
                        : BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              barTouchData: BarTouchData(
                                enabled: true,
                                touchTooltipData: BarTouchTooltipData(
                                  getTooltipItem:
                                      (group, groupIndex, rod, rodIndex) {
                                    final point =
                                        stats.last7DaysSales[groupIndex];
                                    final dateStr =
                                        DateFormat('dd MMM').format(point.date);
                                    return BarTooltipItem(
                                      '$dateStr\n${CurrencyFormatter.formatPaise(point.salesPaise)}',
                                      const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11),
                                    );
                                  },
                                ),
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                leftTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (val, meta) {
                                      final idx = val.toInt();
                                      if (idx < 0 ||
                                          idx >= stats.last7DaysSales.length) {
                                        return const SizedBox();
                                      }
                                      final point = stats.last7DaysSales[idx];
                                      final isToday = idx ==
                                          stats.last7DaysSales.length - 1;
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text(
                                          isToday
                                              ? 'Today'
                                              : DateFormat('E')
                                                  .format(point.date),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: isToday
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: isToday
                                                ? AppTheme.primaryGreen
                                                : AppTheme.textMuted,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              gridData: const FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                              barGroups: stats.last7DaysSales
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                final idx = entry.key;
                                final point = entry.value;
                                final rupees = CurrencyFormatter.paiseToRupees(
                                    point.salesPaise);
                                final isToday =
                                    idx == stats.last7DaysSales.length - 1;

                                return BarChartGroupData(
                                  x: idx,
                                  barRods: [
                                    BarChartRodData(
                                      toY: rupees > 0 ? rupees : 1.0,
                                      color: isToday
                                          ? AppTheme.primaryGreen
                                          : const Color(0xFF86EFAC),
                                      width: 18,
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(6)),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Top Selling Food Items
              if (stats.topProducts.isNotEmpty) ...[
                const Text(
                  'Popular Menu Items',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: stats.topProducts.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final p = stats.topProducts[index];
                      final qtyStr = p.quantitySold.truncateToDouble() ==
                              p.quantitySold
                          ? p.quantitySold.toInt().toString()
                          : p.quantitySold.toStringAsFixed(1);

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFDCFCE7),
                          child: Text(
                            '#${index + 1}',
                            style: const TextStyle(
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        title: Text(p.productName,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('$qtyStr sold'),
                        trailing: Text(
                          CurrencyFormatter.formatPaise(p.totalRevenuePaise),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Recent Invoices Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Invoices',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => context.go('/bills'),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (stats.recentInvoices.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          const Text(
                            'No bills generated yet',
                            style: TextStyle(color: AppTheme.textMuted),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () => context.go('/billing'),
                            icon: const Icon(Icons.point_of_sale),
                            label: const Text('Create First Bill'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: stats.recentInvoices.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final inv = stats.recentInvoices[index];
                      final dateFormat = DateFormat('dd MMM, hh:mm a');
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: inv.isCancelled
                              ? Colors.red.shade100
                              : (inv.paymentStatus == AppConstants.statusPaid
                                  ? const Color(0xFFDCFCE7)
                                  : Colors.amber.shade100),
                          child: Icon(
                            inv.isCancelled
                                ? Icons.cancel_outlined
                                : Icons.receipt,
                            color: inv.isCancelled
                                ? Colors.red
                                : (inv.paymentStatus == AppConstants.statusPaid
                                    ? AppTheme.primaryGreen
                                    : Colors.amber.shade900),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          inv.invoiceNumber,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${dateFormat.format(inv.createdAt)}${inv.cashierName != null ? " • by ${inv.cashierName}" : ""}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              CurrencyFormatter.formatPaise(inv.grandTotalPaise),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              inv.isCancelled ? 'CANCELLED' : inv.paymentStatus,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: inv.isCancelled
                                    ? Colors.red
                                    : (inv.paymentStatus ==
                                            AppConstants.statusPaid
                                        ? AppTheme.primaryGreen
                                        : Colors.amber.shade800),
                              ),
                            ),
                          ],
                        ),
                        onTap: () => context.push('/bills/${inv.id}'),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _kpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppTheme.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroMetric(String label, String value, {bool highlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: highlight ? const Color(0xFFFDE047) : Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _collectionCard({
    required String title,
    required int amountPaise,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppTheme.borderLight, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                CurrencyFormatter.formatPaise(amountPaise),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
