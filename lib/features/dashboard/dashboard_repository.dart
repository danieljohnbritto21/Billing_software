import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DashboardRepository(db);
});

class DashboardStats {
  // All-time metrics
  final int totalBillsCount;
  final int totalCollectionsPaise;
  final int totalPendingAmountPaise;
  final int pendingPaymentsCount;
  final int completedOrdersCount;
  final int pendingOrdersCount;

  // Today metrics
  final int todaySalesPaise;
  final int todayBillsCount;
  final int todayCollectionsPaise;
  final int cashCollectionsPaise;
  final int upiCollectionsPaise;
  final int cardCollectionsPaise;
  final int pendingAmountPaise;

  final List<InvoiceEntry> recentInvoices;
  final List<TopSellingProduct> topProducts;
  final List<DailySalesPoint> last7DaysSales;

  const DashboardStats({
    required this.totalBillsCount,
    required this.totalCollectionsPaise,
    required this.totalPendingAmountPaise,
    required this.pendingPaymentsCount,
    required this.completedOrdersCount,
    required this.pendingOrdersCount,
    required this.todaySalesPaise,
    required this.todayBillsCount,
    required this.todayCollectionsPaise,
    required this.cashCollectionsPaise,
    required this.upiCollectionsPaise,
    required this.cardCollectionsPaise,
    required this.pendingAmountPaise,
    required this.recentInvoices,
    required this.topProducts,
    required this.last7DaysSales,
  });
}

class TopSellingProduct {
  final String productName;
  final double quantitySold;
  final int totalRevenuePaise;

  const TopSellingProduct({
    required this.productName,
    required this.quantitySold,
    required this.totalRevenuePaise,
  });
}

class DailySalesPoint {
  final DateTime date;
  final int salesPaise;
  final int billCount;

  const DailySalesPoint({
    required this.date,
    required this.salesPaise,
    required this.billCount,
  });
}

class DashboardRepository {
  final AppDatabase _db;

  DashboardRepository(this._db);

  Stream<DashboardStats> watchDashboardStats() {
    // Watch changes in invoices to recompute stats reactively
    return _db.select(_db.invoices).watch().asyncMap((_) async {
      return await getDashboardStats();
    });
  }

  Future<DashboardStats> getDashboardStats() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    // All active invoices
    final allActiveInvoices = await (_db.select(_db.invoices)
          ..where((t) => t.isCancelled.equals(false)))
        .get();

    int totalBillsCount = allActiveInvoices.length;
    int totalCollectionsPaise = 0;
    int totalPendingAmountPaise = 0;
    int pendingPaymentsCount = 0;
    int completedOrdersCount = 0;
    int pendingOrdersCount = 0;

    for (final inv in allActiveInvoices) {
      totalCollectionsPaise += inv.paidAmountPaise;
      final balance = inv.grandTotalPaise - inv.paidAmountPaise;
      if (balance > 0) {
        totalPendingAmountPaise += balance;
        pendingPaymentsCount++;
      }
      if (inv.orderStatus == AppConstants.orderCompleted) {
        completedOrdersCount++;
      } else if (inv.orderStatus == AppConstants.orderPending ||
          inv.orderStatus == AppConstants.orderInProgress) {
        pendingOrdersCount++;
      }
    }

    // Today's active invoices
    final todayInvoices = allActiveInvoices.where((t) =>
        t.createdAt.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
        t.createdAt.isBefore(todayEnd.add(const Duration(seconds: 1)))).toList();

    int todaySalesPaise = 0;
    int todayCollectionsPaise = 0;
    int cashCollectionsPaise = 0;
    int upiCollectionsPaise = 0;
    int cardCollectionsPaise = 0;
    int todayPendingAmountPaise = 0;

    for (final inv in todayInvoices) {
      todaySalesPaise += inv.grandTotalPaise;
      todayCollectionsPaise += inv.paidAmountPaise;

      final balance = inv.grandTotalPaise - inv.paidAmountPaise;
      if (balance > 0) {
        todayPendingAmountPaise += balance;
      }

      if (inv.paymentMethod == 'Cash') {
        cashCollectionsPaise += inv.paidAmountPaise;
      } else if (inv.paymentMethod == 'UPI') {
        upiCollectionsPaise += inv.paidAmountPaise;
      } else if (inv.paymentMethod == 'Card') {
        cardCollectionsPaise += inv.paidAmountPaise;
      } else {
        // Other or split
        cashCollectionsPaise += inv.paidAmountPaise;
      }
    }

    // Recent 5 invoices
    final recentInvoices = await (_db.select(_db.invoices)
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ])
          ..limit(5))
        .get();

    // Top selling products
    final allItems = await _db.select(_db.invoiceItems).get();
    final Map<String, _ProductAgg> agg = {};
    for (final item in allItems) {
      final cur = agg.putIfAbsent(
        item.productName,
        () => _ProductAgg(item.productName),
      );
      cur.quantity += item.quantity;
      cur.revenue += item.totalAmountPaise;
    }

    final topList = agg.values.toList()
      ..sort((a, b) => b.quantity.compareTo(a.quantity));
    final topProducts = topList
        .take(5)
        .map((p) => TopSellingProduct(
              productName: p.name,
              quantitySold: p.quantity,
              totalRevenuePaise: p.revenue,
            ))
        .toList();

    // Last 7 days sales
    final last7Days = <DailySalesPoint>[];
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = DateTime(day.year, day.month, day.day, 23, 59, 59);

      final dayInvoices = allActiveInvoices.where((t) =>
          t.createdAt.isAfter(dayStart.subtract(const Duration(seconds: 1))) &&
          t.createdAt.isBefore(dayEnd.add(const Duration(seconds: 1)))).toList();

      final dayTotal = dayInvoices.fold<int>(
        0,
        (sum, inv) => sum + inv.grandTotalPaise,
      );

      last7Days.add(DailySalesPoint(
        date: dayStart,
        salesPaise: dayTotal,
        billCount: dayInvoices.length,
      ));
    }

    return DashboardStats(
      totalBillsCount: totalBillsCount,
      totalCollectionsPaise: totalCollectionsPaise,
      totalPendingAmountPaise: totalPendingAmountPaise,
      pendingPaymentsCount: pendingPaymentsCount,
      completedOrdersCount: completedOrdersCount,
      pendingOrdersCount: pendingOrdersCount,
      todaySalesPaise: todaySalesPaise,
      todayBillsCount: todayInvoices.length,
      todayCollectionsPaise: todayCollectionsPaise,
      cashCollectionsPaise: cashCollectionsPaise,
      upiCollectionsPaise: upiCollectionsPaise,
      cardCollectionsPaise: cardCollectionsPaise,
      pendingAmountPaise: todayPendingAmountPaise,
      recentInvoices: recentInvoices,
      topProducts: topProducts,
      last7DaysSales: last7Days,
    );
  }
}

class _ProductAgg {
  final String name;
  double quantity = 0.0;
  int revenue = 0;
  _ProductAgg(this.name);
}
