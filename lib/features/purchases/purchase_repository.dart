import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/api/api_client.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';
import '../../core/sync/sync_provider.dart';
import '../../core/sync/sync_service.dart';

final purchaseRepositoryProvider = Provider<PurchaseRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final api = ref.watch(apiClientProvider);
  final sync = ref.watch(syncServiceProvider);
  return PurchaseRepository(db, api, sync);
});

class PurchaseRepository {
  final AppDatabase _db;
  final ApiClient? _api;
  final SyncService? _sync;
  final _uuid = const Uuid();

  PurchaseRepository(this._db, [this._api, this._sync]);

  Future<String?> _resolveBusinessId() async {
    final apiBizId = _api?.businessId;
    if (apiBizId != null && apiBizId.isNotEmpty) {
      return apiBizId;
    }
    final setting = await (_db.select(_db.appSettings)
          ..where((s) => s.key.equals('business_id')))
        .getSingleOrNull();
    return setting?.value;
  }

  // ---------------------------------------------------------------------------
  // PURCHASE ORDERS (Procurement Stream)
  // ---------------------------------------------------------------------------

  Stream<List<PurchaseOrderEntry>> watchPurchaseOrders({
    String? supplierId,
    String? orderStatus,
  }) {
    final query = _db.select(_db.purchaseOrders);
    query.where((p) => p.deletedAt.isNull());

    if (supplierId != null && supplierId.isNotEmpty) {
      query.where((p) => p.supplierId.equals(supplierId));
    }
    if (orderStatus != null && orderStatus.isNotEmpty) {
      query.where((p) => p.orderStatus.equals(orderStatus));
    }

    query.orderBy([
      (p) => OrderingTerm(expression: p.orderedAt, mode: OrderingMode.desc),
    ]);

    return query.watch();
  }

  Future<PurchaseOrderEntry?> getPurchaseOrderById(String id) async {
    return (_db.select(_db.purchaseOrders)..where((p) => p.id.equals(id))).getSingleOrNull();
  }

  Future<List<PurchaseOrderItemEntry>> getPurchaseOrderItems(String poId) async {
    return (_db.select(_db.purchaseOrderItems)..where((p) => p.purchaseOrderId.equals(poId))).get();
  }

  Future<String> createPurchaseOrder({
    required String supplierId,
    required List<Map<String, dynamic>> items,
    String? notes,
    DateTime? expectedDeliveryDate,
  }) async {
    final bizId = await _resolveBusinessId() ?? 'biz';
    final id = _uuid.v4();
    final now = DateTime.now();

    int subtotalPaise = 0;
    int totalTaxPaise = 0;

    for (final it in items) {
      final qty = (it['quantity'] as num).toDouble();
      final unitPrice = it['unitPricePaise'] as int;
      final gstRate = (it['gstRatePercent'] as num?)?.toDouble() ?? 0.0;

      final taxable = (qty * unitPrice).round();
      final tax = (taxable * gstRate / 100.0).round();

      subtotalPaise += taxable;
      totalTaxPaise += tax;
    }

    final grandTotalPaise = subtotalPaise + totalTaxPaise;
    final poNumber = 'PO-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    final payload = {
      'id': id,
      'supplierId': supplierId,
      'notes': notes,
      if (expectedDeliveryDate != null)
        'expectedDeliveryDate': expectedDeliveryDate.toIso8601String(),
      'items': items,
    };

    final api = _api;
    bool synced = false;
    if (api != null && api.authToken != null) {
      try {
        await api.post('/admin/purchase-orders', body: payload);
        synced = true;
      } catch (_) {}
    }

    await _db.into(_db.purchaseOrders).insert(
      PurchaseOrdersCompanion.insert(
        id: id,
        businessId: bizId,
        supplierId: supplierId,
        poNumber: poNumber,
        subtotalPaise: subtotalPaise,
        taxPaise: Value(totalTaxPaise),
        grandTotalPaise: grandTotalPaise,
        notes: Value(notes),
        expectedDeliveryDate: Value(expectedDeliveryDate),
        orderedAt: now,
        createdAt: now,
        updatedAt: now,
        syncStatus: Value(synced ? 'synced' : 'pending'),
      ),
    );

    for (final it in items) {
      final qty = (it['quantity'] as num).toDouble();
      final unitPrice = it['unitPricePaise'] as int;
      final gstRate = (it['gstRatePercent'] as num?)?.toDouble() ?? 0.0;
      final taxable = (qty * unitPrice).round();
      final tax = (taxable * gstRate / 100.0).round();

      await _db.into(_db.purchaseOrderItems).insert(
        PurchaseOrderItemsCompanion.insert(
          id: it['id']?.toString() ?? _uuid.v4(),
          purchaseOrderId: id,
          productId: Value(it['productId']?.toString()),
          productName: it['productName'].toString(),
          productCode: Value(it['productCode']?.toString()),
          quantity: qty,
          unit: Value(it['unit']?.toString() ?? 'unit'),
          unitPricePaise: unitPrice,
          gstRatePercent: Value(gstRate),
          taxableAmountPaise: taxable,
          taxAmountPaise: tax,
          totalAmountPaise: taxable + tax,
          createdAt: now,
        ),
      );
    }

    if (!synced) {
      await _sync?.enqueueChange(
        entityName: 'purchase_orders',
        recordId: id,
        operation: 'INSERT',
        payload: payload,
      );
    }

    return id;
  }

  // ---------------------------------------------------------------------------
  // PURCHASE INVOICES (Supplier Invoicing & Approvals)
  // ---------------------------------------------------------------------------

  Stream<List<PurchaseInvoiceEntry>> watchPurchaseInvoices({
    String? supplierId,
    String? verificationStatus,
    String? paymentStatus,
  }) {
    final query = _db.select(_db.purchaseInvoices);
    query.where((p) => p.deletedAt.isNull());

    if (supplierId != null && supplierId.isNotEmpty) {
      query.where((p) => p.supplierId.equals(supplierId));
    }
    if (verificationStatus != null && verificationStatus.isNotEmpty) {
      query.where((p) => p.verificationStatus.equals(verificationStatus));
    }
    if (paymentStatus != null && paymentStatus.isNotEmpty) {
      query.where((p) => p.paymentStatus.equals(paymentStatus));
    }

    query.orderBy([
      (p) => OrderingTerm(expression: p.invoiceDate, mode: OrderingMode.desc),
    ]);

    return query.watch();
  }

  Future<PurchaseInvoiceEntry?> getPurchaseInvoiceById(String id) async {
    return (_db.select(_db.purchaseInvoices)..where((p) => p.id.equals(id))).getSingleOrNull();
  }

  Future<List<PurchaseInvoiceItemEntry>> getPurchaseInvoiceItems(String invoiceId) async {
    return (_db.select(_db.purchaseInvoiceItems)..where((p) => p.purchaseInvoiceId.equals(invoiceId))).get();
  }

  /// Submit invoice from Supplier Portal
  Future<String> submitSupplierInvoice({
    required String supplierId,
    String? purchaseOrderId,
    required String invoiceNumber,
    DateTime? invoiceDate,
    DateTime? dueDate,
    String? notes,
    required List<Map<String, dynamic>> items,
  }) async {
    final bizId = await _resolveBusinessId() ?? 'biz';
    final id = _uuid.v4();
    final now = DateTime.now();

    int subtotalPaise = 0;
    int totalTaxPaise = 0;

    for (final it in items) {
      final qty = (it['quantity'] as num).toDouble();
      final unitPrice = it['unitPricePaise'] as int;
      final gstRate = (it['gstRatePercent'] as num?)?.toDouble() ?? 0.0;

      final taxable = (qty * unitPrice).round();
      final tax = (taxable * gstRate / 100.0).round();

      subtotalPaise += taxable;
      totalTaxPaise += tax;
    }

    final grandTotalPaise = subtotalPaise + totalTaxPaise;

    final payload = {
      'id': id,
      'supplierId': supplierId,
      if (purchaseOrderId != null) 'purchaseOrderId': purchaseOrderId,
      'invoiceNumber': invoiceNumber.trim(),
      'invoiceDate': (invoiceDate ?? now).toIso8601String(),
      if (dueDate != null) 'dueDate': dueDate.toIso8601String(),
      if (notes != null) 'notes': notes.trim(),
      'items': items,
    };

    final api = _api;
    bool synced = false;
    if (api != null && api.authToken != null) {
      try {
        await api.post('/supplier/invoices', body: payload);
        synced = true;
      } catch (_) {}
    }

    await _db.into(_db.purchaseInvoices).insert(
      PurchaseInvoicesCompanion.insert(
        id: id,
        businessId: bizId,
        supplierId: supplierId,
        purchaseOrderId: Value(purchaseOrderId),
        invoiceNumber: invoiceNumber.trim(),
        subtotalPaise: subtotalPaise,
        taxPaise: Value(totalTaxPaise),
        grandTotalPaise: grandTotalPaise,
        balanceDuePaise: Value(grandTotalPaise),
        verificationStatus: const Value('PENDING_VERIFICATION'),
        paymentStatus: const Value('PENDING'),
        invoiceDate: invoiceDate ?? now,
        dueDate: Value(dueDate),
        notes: Value(notes?.trim()),
        createdAt: now,
        updatedAt: now,
        syncStatus: Value(synced ? 'synced' : 'pending'),
      ),
    );

    for (final it in items) {
      final qty = (it['quantity'] as num).toDouble();
      final unitPrice = it['unitPricePaise'] as int;
      final gstRate = (it['gstRatePercent'] as num?)?.toDouble() ?? 0.0;
      final taxable = (qty * unitPrice).round();
      final tax = (taxable * gstRate / 100.0).round();

      await _db.into(_db.purchaseInvoiceItems).insert(
        PurchaseInvoiceItemEntry(
          id: it['id']?.toString() ?? _uuid.v4(),
          purchaseInvoiceId: id,
          productId: it['productId']?.toString(),
          productName: it['productName'].toString(),
          productCode: it['productCode']?.toString(),
          quantity: qty,
          unit: it['unit']?.toString() ?? 'unit',
          unitPricePaise: unitPrice,
          gstRatePercent: gstRate,
          taxableAmountPaise: taxable,
          taxAmountPaise: tax,
          totalAmountPaise: taxable + tax,
          createdAt: now,
        ),
      );
    }

    if (!synced) {
      await _sync?.enqueueChange(
        entityName: 'purchase_invoices',
        recordId: id,
        operation: 'INSERT',
        payload: payload,
      );
    }

    return id;
  }

  /// Approve invoice (Admin only)
  Future<void> approvePurchaseInvoice(String id) async {
    final api = _api;
    if (api != null && api.authToken != null) {
      await api.post('/admin/purchase-invoices/$id/approve');
    }

    await (_db.update(_db.purchaseInvoices)..where((p) => p.id.equals(id))).write(
      PurchaseInvoicesCompanion(
        verificationStatus: const Value('APPROVED'),
        verifiedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Reject invoice (Admin only)
  Future<void> rejectPurchaseInvoice(String id, String reason) async {
    final api = _api;
    if (api != null && api.authToken != null) {
      await api.post('/admin/purchase-invoices/$id/reject', body: {'reason': reason});
    }

    await (_db.update(_db.purchaseInvoices)..where((p) => p.id.equals(id))).write(
      PurchaseInvoicesCompanion(
        verificationStatus: const Value('REJECTED'),
        rejectionReason: Value(reason),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SUPPLIER PAYMENTS (Liabilities Disbursement Stream)
  // ---------------------------------------------------------------------------

  Stream<List<SupplierPaymentEntry>> watchSupplierPayments({
    String? supplierId,
    String? purchaseInvoiceId,
  }) {
    final query = _db.select(_db.supplierPayments);

    if (supplierId != null && supplierId.isNotEmpty) {
      query.where((p) => p.supplierId.equals(supplierId));
    }
    if (purchaseInvoiceId != null && purchaseInvoiceId.isNotEmpty) {
      query.where((p) => p.purchaseInvoiceId.equals(purchaseInvoiceId));
    }

    query.orderBy([
      (p) => OrderingTerm(expression: p.paymentDate, mode: OrderingMode.desc),
    ]);

    return query.watch();
  }

  Future<void> recordSupplierPayment({
    required String purchaseInvoiceId,
    required String supplierId,
    required int amountPaise,
    String paymentMethod = 'Bank Transfer',
    String? referenceNumber,
    String? notes,
  }) async {
    final bizId = await _resolveBusinessId() ?? 'biz';
    final id = _uuid.v4();
    final now = DateTime.now();
    final voucherNumber = 'PV-${now.millisecondsSinceEpoch.toString().substring(7)}';
    final idempotencyKey = 'pay-pv-$id';

    final payload = {
      'amountPaise': amountPaise,
      'paymentMethod': paymentMethod,
      if (referenceNumber != null) 'referenceNumber': referenceNumber.trim(),
      if (notes != null) 'notes': notes.trim(),
      'idempotencyKey': idempotencyKey,
    };

    final api = _api;
    if (api != null && api.authToken != null) {
      await api.post('/admin/purchase-invoices/$purchaseInvoiceId/payments', body: payload);
    }

    await _db.into(_db.supplierPayments).insert(
      SupplierPaymentsCompanion.insert(
        id: id,
        businessId: bizId,
        purchaseInvoiceId: purchaseInvoiceId,
        supplierId: supplierId,
        paymentVoucherNumber: voucherNumber,
        amountPaise: amountPaise,
        paymentMethod: Value(paymentMethod),
        paymentDate: now,
        referenceNumber: Value(referenceNumber?.trim()),
        notes: Value(notes?.trim()),
        idempotencyKey: Value(idempotencyKey),
        createdAt: now,
        syncStatus: const Value('synced'),
      ),
    );

    // Update local purchase invoice balance
    final inv = await getPurchaseInvoiceById(purchaseInvoiceId);
    if (inv != null) {
      final newPaid = inv.amountPaidPaise + amountPaise;
      final newDue = inv.grandTotalPaise - newPaid;
      final newStatus = newDue <= 0 ? 'PAID' : 'PARTIALLY_PAID';

      await (_db.update(_db.purchaseInvoices)..where((p) => p.id.equals(purchaseInvoiceId))).write(
        PurchaseInvoicesCompanion(
          amountPaidPaise: Value(newPaid),
          balanceDuePaise: Value(newDue > 0 ? newDue : 0),
          paymentStatus: Value(newStatus),
          updatedAt: Value(now),
        ),
      );
    }
  }

  /// Live Supplier Ledger & Outstanding Balances (Supplier Self-Service)
  Future<Map<String, dynamic>> fetchSupplierLedgerSummary() async {
    final api = _api;
    if (api == null || api.authToken == null) {
      return {
        'totalBilledPaise': 0,
        'totalPaidPaise': 0,
        'outstandingBalancePaise': 0,
        'approvedInvoiceCount': 0,
        'pendingInvoiceCount': 0,
      };
    }

    try {
      final res = await api.get('/supplier/outstanding-balance');
      if (res is Map<String, dynamic>) {
        return res;
      }
    } catch (_) {}

    return {
      'totalBilledPaise': 0,
      'totalPaidPaise': 0,
      'outstandingBalancePaise': 0,
      'approvedInvoiceCount': 0,
      'pendingInvoiceCount': 0,
    };
  }

  /// Sync/Fetch Purchase Orders from Backend API into Drift SQLite
  Future<void> fetchPurchaseOrdersFromApi() async {
    final api = _api;
    if (api == null || api.authToken == null) return;

    try {
      final isSupplier = api.supplierId != null && api.supplierId!.isNotEmpty;
      final endpoint = isSupplier ? '/supplier/orders' : '/admin/purchase-orders';
      final res = await api.get(endpoint);
      final items = res is List ? res : (res is Map && res['data'] is List ? res['data'] : []);

      for (final raw in items) {
        final item = raw as Map<String, dynamic>;
        final id = item['id'].toString();
        final bizId = item['business_id']?.toString() ?? item['businessId']?.toString() ?? 'biz';
        final supplierId = item['supplier_id']?.toString() ?? item['supplierId']?.toString() ?? '';
        final poNumber = item['po_number']?.toString() ?? item['poNumber']?.toString() ?? 'PO';
        final orderStatus = item['order_status']?.toString() ?? item['orderStatus']?.toString() ?? 'DRAFT';
        final subtotal = (item['subtotal_paise'] ?? item['subtotalPaise'] ?? 0) as int;
        final tax = (item['tax_paise'] ?? item['taxPaise'] ?? 0) as int;
        final grandTotal = (item['grand_total_paise'] ?? item['grandTotalPaise'] ?? 0) as int;
        final notes = item['notes']?.toString();
        final expectedDelivery = item['expected_delivery_date'] != null
            ? DateTime.parse(item['expected_delivery_date'])
            : (item['expectedDeliveryDate'] != null ? DateTime.parse(item['expectedDeliveryDate']) : null);
        final orderedAt = item['ordered_at'] != null
            ? DateTime.parse(item['ordered_at'])
            : (item['orderedAt'] != null ? DateTime.parse(item['orderedAt']) : DateTime.now());

        await _db.into(_db.purchaseOrders).insertOnConflictUpdate(
          PurchaseOrdersCompanion.insert(
            id: id,
            businessId: bizId,
            supplierId: supplierId,
            poNumber: poNumber,
            orderStatus: Value(orderStatus),
            subtotalPaise: subtotal,
            taxPaise: Value(tax),
            grandTotalPaise: grandTotal,
            notes: Value(notes),
            expectedDeliveryDate: Value(expectedDelivery),
            orderedAt: orderedAt,
            createdAt: orderedAt,
            updatedAt: DateTime.now(),
            syncStatus: const Value('synced'),
          ),
        );
      }
    } catch (_) {}
  }

  /// Sync/Fetch Purchase Invoices from Backend API into Drift SQLite
  Future<void> fetchPurchaseInvoicesFromApi() async {
    final api = _api;
    if (api == null || api.authToken == null) return;

    try {
      final isSupplier = api.supplierId != null && api.supplierId!.isNotEmpty;
      final endpoint = isSupplier ? '/supplier/invoices' : '/admin/purchase-invoices';
      final res = await api.get(endpoint);
      final items = res is List ? res : (res is Map && res['data'] is List ? res['data'] : []);

      for (final raw in items) {
        final item = raw as Map<String, dynamic>;
        final id = item['id'].toString();
        final bizId = item['business_id']?.toString() ?? item['businessId']?.toString() ?? 'biz';
        final supplierId = item['supplier_id']?.toString() ?? item['supplierId']?.toString() ?? '';
        final poId = item['purchase_order_id']?.toString() ?? item['purchaseOrderId']?.toString();
        final invoiceNum = item['invoice_number']?.toString() ?? item['invoiceNumber']?.toString() ?? 'INV';
        final verStatus = item['verification_status']?.toString() ?? item['verificationStatus']?.toString() ?? 'PENDING_VERIFICATION';
        final payStatus = item['payment_status']?.toString() ?? item['paymentStatus']?.toString() ?? 'PENDING';
        final subtotal = (item['subtotal_paise'] ?? item['subtotalPaise'] ?? 0) as int;
        final tax = (item['tax_paise'] ?? item['taxPaise'] ?? 0) as int;
        final grandTotal = (item['grand_total_paise'] ?? item['grandTotalPaise'] ?? 0) as int;
        final paid = (item['amount_paid_paise'] ?? item['amountPaidPaise'] ?? 0) as int;
        final due = (item['balance_due_paise'] ?? item['balanceDuePaise'] ?? (grandTotal - paid)) as int;
        final notes = item['notes']?.toString();
        final rejReason = item['rejection_reason']?.toString() ?? item['rejectionReason']?.toString();
        final invDate = item['invoice_date'] != null
            ? DateTime.parse(item['invoice_date'])
            : (item['invoiceDate'] != null ? DateTime.parse(item['invoiceDate']) : DateTime.now());
        final dueDate = item['due_date'] != null
            ? DateTime.parse(item['due_date'])
            : (item['dueDate'] != null ? DateTime.parse(item['dueDate']) : null);

        await _db.into(_db.purchaseInvoices).insertOnConflictUpdate(
          PurchaseInvoicesCompanion.insert(
            id: id,
            businessId: bizId,
            supplierId: supplierId,
            purchaseOrderId: Value(poId),
            invoiceNumber: invoiceNum,
            verificationStatus: Value(verStatus),
            paymentStatus: Value(payStatus),
            subtotalPaise: subtotal,
            taxPaise: Value(tax),
            grandTotalPaise: grandTotal,
            amountPaidPaise: Value(paid),
            balanceDuePaise: Value(due),
            notes: Value(notes),
            rejectionReason: Value(rejReason),
            invoiceDate: invDate,
            dueDate: Value(dueDate),
            createdAt: invDate,
            updatedAt: DateTime.now(),
            syncStatus: const Value('synced'),
          ),
        );
      }
    } catch (_) {}
  }

  /// Sync/Fetch Supplier Payments from Backend API into Drift SQLite
  Future<void> fetchSupplierPaymentsFromApi() async {
    final api = _api;
    if (api == null || api.authToken == null) return;

    try {
      final isSupplier = api.supplierId != null && api.supplierId!.isNotEmpty;
      final endpoint = isSupplier ? '/supplier/payment-history' : '/admin/supplier-payments';
      final res = await api.get(endpoint);
      final items = res is List ? res : (res is Map && res['data'] is List ? res['data'] : []);

      for (final raw in items) {
        final item = raw as Map<String, dynamic>;
        final id = item['id'].toString();
        final bizId = item['business_id']?.toString() ?? item['businessId']?.toString() ?? 'biz';
        final supplierId = item['supplier_id']?.toString() ?? item['supplierId']?.toString() ?? '';
        final invId = item['purchase_invoice_id']?.toString() ?? item['purchaseInvoiceId']?.toString() ?? '';
        final voucher = item['payment_voucher_number']?.toString() ?? item['paymentVoucherNumber']?.toString() ?? 'PV';
        final amount = (item['amount_paise'] ?? item['amountPaise'] ?? 0) as int;
        final method = item['payment_method']?.toString() ?? item['paymentMethod']?.toString() ?? 'Bank Transfer';
        final refNum = item['reference_number']?.toString() ?? item['referenceNumber']?.toString();
        final notes = item['notes']?.toString();
        final payDate = item['payment_date'] != null
            ? DateTime.parse(item['payment_date'])
            : (item['paymentDate'] != null ? DateTime.parse(item['paymentDate']) : DateTime.now());

        await _db.into(_db.supplierPayments).insertOnConflictUpdate(
          SupplierPaymentsCompanion.insert(
            id: id,
            businessId: bizId,
            purchaseInvoiceId: invId,
            supplierId: supplierId,
            paymentVoucherNumber: voucher,
            amountPaise: amount,
            paymentMethod: Value(method),
            paymentDate: payDate,
            referenceNumber: Value(refNum),
            notes: Value(notes),
            createdAt: payDate,
            syncStatus: const Value('synced'),
          ),
        );
      }
    } catch (_) {}
  }
}

final purchaseOrdersStreamProvider = StreamProvider<List<PurchaseOrderEntry>>((ref) {
  final repo = ref.watch(purchaseRepositoryProvider);
  return repo.watchPurchaseOrders();
});

final purchaseInvoicesStreamProvider = StreamProvider<List<PurchaseInvoiceEntry>>((ref) {
  final repo = ref.watch(purchaseRepositoryProvider);
  return repo.watchPurchaseInvoices();
});
