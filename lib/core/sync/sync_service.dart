import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../api/api_client.dart';
import '../api/device_service.dart';
import '../database/app_database.dart';

enum SyncStatusType {
  synced,
  syncing,
  offline,
  pending,
  error,
  conflict,
}

class SyncState {
  final SyncStatusType status;
  final int pendingCount;
  final DateTime? lastSyncAt;
  final String? errorMessage;
  final String? serverCursor;

  const SyncState({
    this.status = SyncStatusType.offline,
    this.pendingCount = 0,
    this.lastSyncAt,
    this.errorMessage,
    this.serverCursor,
  });

  SyncState copyWith({
    SyncStatusType? status,
    int? pendingCount,
    DateTime? lastSyncAt,
    String? errorMessage,
    String? serverCursor,
    bool clearError = false,
  }) {
    return SyncState(
      status: status ?? this.status,
      pendingCount: pendingCount ?? this.pendingCount,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      serverCursor: serverCursor ?? this.serverCursor,
    );
  }
}

class SyncService extends ChangeNotifier {
  final AppDatabase _db;
  final ApiClient _api;
  final DeviceService _deviceService;
  final _uuid = const Uuid();

  SyncState _state = const SyncState();
  SyncState get state => _state;

  Timer? _autoSyncTimer;
  bool _isSyncing = false;

  SyncService(this._db, this._api, this._deviceService) {
    _updatePendingCount();
  }

  /// Calculates human-readable sync health status
  String get syncHealth {
    if (_state.status == SyncStatusType.error) return 'Error';
    if (_state.status == SyncStatusType.offline) return 'Offline';
    if (_state.pendingCount > 0) return 'Pending (${_state.pendingCount})';
    return 'Healthy';
  }

  /// Strict dependency ordering rank:
  /// Categories (10) -> Suppliers (20) -> Products (30) -> Customers/Tables (40) ->
  /// Orders/PurchaseOrders (50) -> Invoices/PurchaseInvoices (60) -> Payments/SupplierPayments/KOT (70)
  static int getEntityDependencyRank(String entity) {
    switch (entity.toLowerCase()) {
      case 'categories':
        return 10;
      case 'suppliers':
        return 20;
      case 'products':
        return 30;
      case 'customers':
      case 'dining_tables':
        return 40;
      case 'orders':
      case 'purchase_orders':
        return 50;
      case 'invoices':
      case 'purchase_invoices':
        return 60;
      case 'payments':
      case 'supplier_payments':
      case 'kot_records':
        return 70;
      default:
        return 80;
    }
  }

  void startAutoSync({Duration interval = const Duration(seconds: 30)}) {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(interval, (_) {
      syncNow();
    });
  }

  bool _isDisposed = false;

  void stopAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
  }

  @override
  void dispose() {
    _isDisposed = true;
    stopAutoSync();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  Future<void> _updatePendingCount() async {
    try {
      final count = await _db.syncQueue.count().getSingle();
      _state = _state.copyWith(pendingCount: count);
      notifyListeners();
    } catch (_) {
      // Safely ignore if database is closed or shutting down
    }
  }

  /// Enqueues a local entity creation, update, or deletion for offline synchronization
  Future<void> enqueueChange({
    required String entityName,
    required String recordId,
    required String operation, // 'INSERT', 'UPDATE', 'DELETE'
    required Map<String, dynamic> payload,
    String? idempotencyKey,
    BigInt? clientVersion,
    bool triggerSync = true,
  }) async {
    final bizId = _api.businessId ?? 'default_biz';
    final devId = await _deviceService.getOrGenerateDeviceUid();
    final idemp = idempotencyKey ?? _uuid.v4();

    // Look up existing record's serverVersion if this is an update and no clientVersion was passed
    BigInt? version = clientVersion;
    if (version == null && operation == 'UPDATE') {
      try {
        if (entityName == 'products') {
          final p = await (_db.select(_db.products)..where((t) => t.id.equals(recordId))).getSingleOrNull();
          version = p?.serverVersion;
        } else if (entityName == 'categories') {
          final c = await (_db.select(_db.categories)..where((t) => t.id.equals(recordId))).getSingleOrNull();
          version = c?.serverVersion;
        }
      } catch (_) {}
    }

    await _db.into(_db.syncQueue).insert(
      SyncQueueCompanion.insert(
        id: _uuid.v4(),
        businessId: bizId,
        deviceId: devId,
        syncEntity: entityName,
        recordId: recordId,
        operation: operation,
        payloadJson: jsonEncode(payload),
        idempotencyKey: idemp,
        clientVersion: drift.Value(version),
        createdAt: DateTime.now(),
      ),
    );

    if (triggerSync) {
      await _updatePendingCount();
      unawaited(syncNow());
    }
  }

  /// Triggers pending count recalculation and background sync after atomic outer transactions
  void notifyPendingAndSync() {
    _updatePendingCount();
    unawaited(syncNow());
  }

  /// Main two-way synchronization loop: pushes local changes then pulls remote changes
  Future<bool> syncNow() async {
    if (_isDisposed || _isSyncing) return false;

    if (_api.authToken == null || _api.authToken!.isEmpty) {
      await _api.restoreSavedAuth();
    }
    if (_api.authToken == null || _api.authToken!.isEmpty) {
      _state = _state.copyWith(status: SyncStatusType.offline);
      notifyListeners();
      return false;
    }

    _isSyncing = true;
    _state = _state.copyWith(status: SyncStatusType.syncing, clearError: true);
    notifyListeners();

    try {
      // 1. Upload local queued changes in dependency order
      await _pushLocalChanges();

      // 2. Download remote server changes strictly using commit-safe cursor
      await _pullServerChanges();

      final pending = await _db.syncQueue.count().getSingle();
      _state = _state.copyWith(
        status: pending > 0 ? SyncStatusType.pending : SyncStatusType.synced,
        pendingCount: pending,
        lastSyncAt: DateTime.now(),
        clearError: true,
      );
      _isSyncing = false;
      notifyListeners();
      return true;
    } on NetworkException catch (e) {
      final pending = await _db.syncQueue.count().getSingle();
      _state = _state.copyWith(
        status: SyncStatusType.offline,
        pendingCount: pending,
        errorMessage: e.message,
      );
      _isSyncing = false;
      notifyListeners();
      return false;
    } catch (e) {
      final pending = await _db.syncQueue.count().getSingle();
      _state = _state.copyWith(
        status: SyncStatusType.error,
        pendingCount: pending,
        errorMessage: e.toString(),
      );
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _pushLocalChanges() async {
    final pendingItems = await (_db.select(_db.syncQueue)
      ..where((q) => q.status.equals('pending') | q.status.equals('failed'))
      ..orderBy([(q) => drift.OrderingTerm(expression: q.createdAt, mode: drift.OrderingMode.asc)])
      ..limit(50))
      .get();

    if (pendingItems.isEmpty) return;

    // Strict dependency sorting: categories -> suppliers -> products -> customers -> orders -> invoices -> payments
    pendingItems.sort((a, b) {
      final rankA = getEntityDependencyRank(a.syncEntity);
      final rankB = getEntityDependencyRank(b.syncEntity);
      if (rankA != rankB) return rankA.compareTo(rankB);
      return a.createdAt.compareTo(b.createdAt);
    });

    final devId = await _deviceService.getOrGenerateDeviceUid();
    final itemsPayload = pendingItems.map((item) {
      return {
        'entityName': item.syncEntity,
        'operation': item.operation,
        'recordId': item.recordId,
        'clientVersion': item.clientVersion != null ? item.clientVersion!.toInt() : 0,
        'payload': jsonDecode(item.payloadJson),
      };
    }).toList();

    try {
      final res = await _api.post('/sync/push', body: {
        'deviceId': devId,
        'items': itemsPayload,
      });

      if (res is Map<String, dynamic> && res['results'] is List) {
        final results = res['results'] as List;
        for (var i = 0; i < pendingItems.length && i < results.length; i++) {
          final qItem = pendingItems[i];
          final r = results[i];

          if (r['status'] == 'synced') {
            await (_db.delete(_db.syncQueue)..where((q) => q.id.equals(qItem.id))).go();

            // Mark local record as synced and store serverVersion if available
            final sVer = r['serverVersion'] != null ? BigInt.tryParse(r['serverVersion'].toString()) : null;
            if (qItem.syncEntity == 'products') {
              await (_db.update(_db.products)..where((p) => p.id.equals(qItem.recordId))).write(
                ProductsCompanion(
                  syncStatus: const drift.Value('synced'),
                  serverVersion: sVer != null ? drift.Value(sVer) : const drift.Value.absent(),
                ),
              );
            } else if (qItem.syncEntity == 'categories') {
              await (_db.update(_db.categories)..where((c) => c.id.equals(qItem.recordId))).write(
                CategoriesCompanion(
                  syncStatus: const drift.Value('synced'),
                  serverVersion: sVer != null ? drift.Value(sVer) : const drift.Value.absent(),
                ),
              );
            } else if (qItem.syncEntity == 'invoices') {
              await (_db.update(_db.invoices)..where((i) => i.id.equals(qItem.recordId))).write(
                const InvoicesCompanion(syncStatus: drift.Value('synced')),
              );
            } else if (qItem.syncEntity == 'payments') {
              await (_db.update(_db.payments)..where((p) => p.id.equals(qItem.recordId))).write(
                const PaymentsCompanion(syncStatus: drift.Value('synced')),
              );
            } else if (qItem.syncEntity == 'purchase_orders') {
              await (_db.update(_db.purchaseOrders)..where((p) => p.id.equals(qItem.recordId))).write(
                const PurchaseOrdersCompanion(syncStatus: drift.Value('synced')),
              );
            } else if (qItem.syncEntity == 'purchase_invoices') {
              await (_db.update(_db.purchaseInvoices)..where((p) => p.id.equals(qItem.recordId))).write(
                const PurchaseInvoicesCompanion(syncStatus: drift.Value('synced')),
              );
            } else if (qItem.syncEntity == 'supplier_payments') {
              await (_db.update(_db.supplierPayments)..where((p) => p.id.equals(qItem.recordId))).write(
                const SupplierPaymentsCompanion(syncStatus: drift.Value('synced')),
              );
            }
          } else if (r['status'] == 'conflict') {
            await _db.into(_db.syncConflicts).insert(
              SyncConflictsCompanion.insert(
                id: _uuid.v4(),
                syncEntity: qItem.syncEntity,
                recordId: qItem.recordId,
                clientPayloadJson: qItem.payloadJson,
                serverPayloadJson: jsonEncode(r),
                resolution: const drift.Value('SERVER_WINS'),
                createdAt: DateTime.now(),
              ),
            );
            await (_db.delete(_db.syncQueue)..where((q) => q.id.equals(qItem.id))).go();
          } else {
            await (_db.update(_db.syncQueue)..where((q) => q.id.equals(qItem.id))).write(
              SyncQueueCompanion(
                retryCount: drift.Value(qItem.retryCount + 1),
                lastError: drift.Value(r['error']?.toString() ?? 'Sync rejection'),
                status: const drift.Value('failed'),
              ),
            );
          }
        }
      }
    } catch (_) {
      rethrow;
    }
  }

  Future<void> _pullServerChanges() async {
    final bizId = _api.businessId ?? 'default_biz';

    // Get current local commit cursor
    final existingCursor = await (_db.select(_db.syncCursors)
      ..where((c) => c.syncEntity.equals('global') & c.businessId.equals(bizId)))
      .getSingleOrNull();

    var currentCursor = existingCursor?.lastServerCursor != null
        ? existingCursor!.lastServerCursor!.toInt()
        : 0;

    bool hasMore = true;

    while (hasMore) {
      final res = await _api.get('/sync/pull', queryParams: {
        'cursor': currentCursor.toString(),
        'limit': '50',
      });

      if (res is! Map<String, dynamic>) break;

      final changes = res['changes'] as List? ?? [];
      final nextCursorStr = res['nextCursor']?.toString() ?? currentCursor.toString();
      final nextCursor = int.tryParse(nextCursorStr) ?? currentCursor;
      hasMore = res['hasMore'] == true;

      // Apply changes transactionally
      await _db.transaction(() async {
        for (final item in changes) {
          final entity = item['entityName']?.toString();
          final recordId = item['recordId']?.toString();
          final op = item['operation']?.toString();
          final data = item['data'];
          final version = item['version'] != null ? BigInt.from(item['version']) : null;

          if (entity == null || recordId == null) continue;

          await _applyEntityChange(entity, recordId, op, data, version, bizId);
        }

        // Advance cursor locally only after full page is successfully committed
        await _db.into(_db.syncCursors).insertOnConflictUpdate(
          SyncCursorsCompanion.insert(
            syncEntity: 'global',
            businessId: bizId,
            lastServerCursor: drift.Value(BigInt.from(nextCursor)),
            lastSyncAt: drift.Value(DateTime.now()),
            status: const drift.Value('synced'),
          ),
        );
      });

      currentCursor = nextCursor;
    }
  }

  Future<void> _applyEntityChange(
    String entity,
    String recordId,
    String? op,
    dynamic data,
    BigInt? version,
    String bizId,
  ) async {
    final d = data as Map<String, dynamic>?;
    final isSoftDeleted = d != null && (d['deleted_at'] != null || d['deletedAt'] != null);
    final isDelete = op == 'DELETE' || data == null || isSoftDeleted;

    switch (entity) {
      case 'categories':
        if (isDelete) {
          await (_db.update(_db.categories)..where((c) => c.id.equals(recordId))).write(
            CategoriesCompanion(
              deletedAt: drift.Value(DateTime.now()),
              isActive: const drift.Value(false),
              syncStatus: const drift.Value('synced'),
            ),
          );
        } else {
          final catName = (d!['name'] ?? '').toString();
          // Check if there was an unsynced local placeholder category with the same name
          if (catName.isNotEmpty) {
            final localMatching = await (_db.select(_db.categories)
              ..where((c) => c.name.equals(catName) & c.id.isNotValue(recordId)))
              .get();
            for (final localCat in localMatching) {
              await (_db.update(_db.products)..where((p) => p.categoryId.equals(localCat.id))).write(
                ProductsCompanion(categoryId: drift.Value(recordId)),
              );
              if (localCat.businessId == null || localCat.businessId != bizId) {
                await (_db.delete(_db.categories)..where((c) => c.id.equals(localCat.id))).go();
              }
            }
          }

          await _db.into(_db.categories).insertOnConflictUpdate(
            CategoriesCompanion.insert(
              id: recordId,
              name: catName,
              icon: drift.Value(d['icon'] ?? d['icon']),
              colorValue: drift.Value(d['color_value'] ?? d['colorValue']),
              isActive: drift.Value(d['is_active'] ?? d['isActive'] ?? true),
              displayOrder: drift.Value(d['display_order'] ?? d['displayOrder'] ?? 0),
              createdAt: d['created_at'] != null ? DateTime.parse(d['created_at']) : DateTime.now(),
              businessId: drift.Value(bizId),
              serverVersion: drift.Value(version),
              syncStatus: const drift.Value('synced'),
            ),
          );
        }
        break;

      case 'products':
        if (isDelete) {
          await (_db.update(_db.products)..where((p) => p.id.equals(recordId))).write(
            ProductsCompanion(
              deletedAt: drift.Value(DateTime.now()),
              isAvailable: const drift.Value(false),
              syncStatus: const drift.Value('synced'),
            ),
          );
        } else {
          final costPaise = int.tryParse(d!['cost_price_paise']?.toString() ?? '0') ?? 0;
          final sellPaise = int.tryParse(d['selling_price_paise']?.toString() ?? '0') ?? 0;
          final gstRate = double.tryParse(d['gst_rate_percent']?.toString() ?? '0.0') ?? 0.0;

          // Safe Category foreign-key resolution
          final rawCatId = (d['category_id'] ?? d['categoryId'])?.toString();
          String? resolvedCatId;
          if (rawCatId != null && rawCatId.isNotEmpty) {
            final existingCat = await (_db.select(_db.categories)..where((c) => c.id.equals(rawCatId))).getSingleOrNull();
            if (existingCat != null) {
              resolvedCatId = rawCatId;
            } else {
              // Try matching by category name
              final catName = (d['category_name'] ?? d['categoryName'])?.toString();
              if (catName != null && catName.isNotEmpty) {
                final matchByName = await (_db.select(_db.categories)..where((c) => c.name.equals(catName))).getSingleOrNull();
                if (matchByName != null) {
                  resolvedCatId = matchByName.id;
                }
              }
              // If still not found, insert a placeholder category so SQLite foreign key constraint is satisfied
              if (resolvedCatId == null) {
                final placeholderName = (d['category_name'] ?? d['categoryName'] ?? 'General').toString();
                await _db.into(_db.categories).insertOnConflictUpdate(
                  CategoriesCompanion.insert(
                    id: rawCatId,
                    name: placeholderName,
                    businessId: drift.Value(bizId),
                    isActive: const drift.Value(true),
                    createdAt: DateTime.now(),
                    syncStatus: const drift.Value('synced'),
                  ),
                );
                resolvedCatId = rawCatId;
              }
            }
          }

          // Safe Supplier foreign-key resolution (prevents SQLite PRAGMA foreign_keys = ON failure)
          final rawSupId = (d['supplier_id'] ?? d['supplierId'])?.toString();
          String? resolvedSupId;
          if (rawSupId != null && rawSupId.isNotEmpty) {
            final existingSup = await (_db.select(_db.suppliers)..where((s) => s.id.equals(rawSupId))).getSingleOrNull();
            if (existingSup != null) {
              resolvedSupId = rawSupId;
            } else {
              final placeholderSupName = (d['supplier_name'] ?? d['supplierName'] ?? 'Vendor Supply').toString();
              await _db.into(_db.suppliers).insertOnConflictUpdate(
                SuppliersCompanion.insert(
                  id: rawSupId,
                  businessId: bizId,
                  name: placeholderSupName,
                  isActive: const drift.Value(true),
                  isVerified: const drift.Value(true),
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                  syncStatus: const drift.Value('synced'),
                ),
              );
              resolvedSupId = rawSupId;
            }
          }

          await _db.into(_db.products).insertOnConflictUpdate(
            ProductsCompanion.insert(
              id: recordId,
              name: d['name'] ?? '',
              code: drift.Value(d['code']),
              categoryId: drift.Value(resolvedCatId),
              supplierId: drift.Value(resolvedSupId),
              description: drift.Value(d['description']),
              costPricePaise: drift.Value(costPaise),
              sellingPricePaise: sellPaise,
              gstRatePercent: drift.Value(gstRate),
              isTaxInclusive: drift.Value(d['is_tax_inclusive'] ?? d['isTaxInclusive'] ?? true),
              unit: drift.Value(d['unit'] ?? 'plate'),
              isAvailable: drift.Value(d['is_available'] ?? d['isAvailable'] ?? true),
              imagePath: drift.Value(d['image_path'] ?? d['imagePath']),
              createdAt: d['created_at'] != null ? DateTime.parse(d['created_at']) : DateTime.now(),
              updatedAt: d['updated_at'] != null ? DateTime.parse(d['updated_at']) : DateTime.now(),
              businessId: drift.Value(bizId),
              serverVersion: drift.Value(version),
              syncStatus: const drift.Value('synced'),
            ),
          );
        }
        break;

      case 'dining_tables':
        if (isDelete || d == null) {
          await (_db.update(_db.diningTables)..where((t) => t.id.equals(recordId))).write(
            DiningTablesCompanion(
              deletedAt: drift.Value(DateTime.now()),
              isOccupied: const drift.Value(false),
            ),
          );
        } else {
          await _db.into(_db.diningTables).insertOnConflictUpdate(
            DiningTablesCompanion.insert(
              id: recordId,
              name: d['table_name'] ?? d['tableName'] ?? 'Table',
              seatingCapacity: drift.Value(d['seating_capacity'] ?? d['seatingCapacity'] ?? 4),
              isOccupied: drift.Value(d['is_occupied'] ?? d['isOccupied'] ?? false),
              currentInvoiceId: drift.Value(d['current_invoice_id'] ?? d['currentInvoiceId']),
              updatedAt: d['updated_at'] != null ? DateTime.parse(d['updated_at']) : DateTime.now(),
              businessId: drift.Value(bizId),
              syncStatus: const drift.Value('synced'),
            ),
          );
        }
        break;

      case 'customers':
        if (isDelete || d == null) {
          await (_db.update(_db.customers)..where((c) => c.id.equals(recordId))).write(
            CustomersCompanion(
              deletedAt: drift.Value(DateTime.now()),
            ),
          );
        } else {
          await _db.into(_db.customers).insertOnConflictUpdate(
            CustomersCompanion.insert(
              id: recordId,
              name: d['name'] ?? '',
              phone: drift.Value(d['phone']),
              address: drift.Value(d['address']),
              notes: drift.Value(d['notes']),
              createdAt: d['created_at'] != null ? DateTime.parse(d['created_at']) : DateTime.now(),
              businessId: drift.Value(bizId),
              serverVersion: drift.Value(version),
              syncStatus: const drift.Value('synced'),
            ),
          );
        }
        break;

      case 'invoices':
        if (!isDelete && d != null) {
          await _db.into(_db.invoices).insertOnConflictUpdate(
            InvoicesCompanion.insert(
              id: recordId,
              orderId: drift.Value(d['order_id'] ?? d['orderId']),
              invoiceNumber: d['invoice_number'] ?? d['invoiceNumber'] ?? 'INV-UNKNOWN',
              createdAt: d['created_at'] != null ? DateTime.parse(d['created_at']) : DateTime.now(),
              customerName: drift.Value(d['customer_name'] ?? d['customerName']),
              customerPhone: drift.Value(d['customer_phone'] ?? d['customerPhone']),
              subtotalPaise: int.tryParse(d['subtotal_paise']?.toString() ?? '0') ?? 0,
              itemDiscountTotalPaise: drift.Value(int.tryParse(d['item_discount_total_paise']?.toString() ?? '0') ?? 0),
              billDiscountPaise: drift.Value(int.tryParse(d['bill_discount_paise']?.toString() ?? '0') ?? 0),
              taxableAmountPaise: int.tryParse(d['taxable_amount_paise']?.toString() ?? '0') ?? 0,
              cgstPaise: drift.Value(int.tryParse(d['cgst_paise']?.toString() ?? '0') ?? 0),
              sgstPaise: drift.Value(int.tryParse(d['sgst_paise']?.toString() ?? '0') ?? 0),
              igstPaise: drift.Value(int.tryParse(d['igst_paise']?.toString() ?? '0') ?? 0),
              roundOffPaise: drift.Value(int.tryParse(d['round_off_paise']?.toString() ?? '0') ?? 0),
              grandTotalPaise: int.tryParse(d['grand_total_paise']?.toString() ?? '0') ?? 0,
              paymentMethod: drift.Value(d['payment_method'] ?? d['paymentMethod'] ?? 'Cash'),
              paymentStatus: drift.Value(d['payment_status'] ?? d['paymentStatus'] ?? 'Paid'),
              orderStatus: drift.Value(d['order_status'] ?? d['orderStatus'] ?? 'Completed'),
              orderType: drift.Value(d['order_type'] ?? d['orderType'] ?? 'Dine In'),
              tableNumber: drift.Value(d['table_number'] ?? d['tableNumber']),
              deliveryAddress: drift.Value(d['delivery_address'] ?? d['deliveryAddress']),
              kotNumber: drift.Value(d['kot_number'] ?? d['kotNumber']),
              cashierId: drift.Value(d['cashier_id'] ?? d['cashierId']),
              cashierName: drift.Value(d['cashier_name'] ?? d['cashierName']),
              paidAmountPaise: int.tryParse(d['paid_amount_paise']?.toString() ?? '0') ?? 0,
              isCancelled: drift.Value(d['is_cancelled'] ?? d['isCancelled'] ?? false),
              cancelledAt: drift.Value(d['cancelled_at'] != null ? DateTime.tryParse(d['cancelled_at']) : null),
              cancelReason: drift.Value(d['cancel_reason'] ?? d['cancelReason']),
              businessId: drift.Value(bizId),
              serverVersion: drift.Value(version),
              syncStatus: const drift.Value('synced'),
            ),
          );

          // Sync invoice items if present
          final items = d['invoice_items'] ?? d['items'];
          if (items is List) {
            for (final it in items) {
              if (it is Map<String, dynamic>) {
                final itId = it['id']?.toString() ?? _uuid.v4();
                await _db.into(_db.invoiceItems).insertOnConflictUpdate(
                  InvoiceItemsCompanion.insert(
                    id: itId,
                    invoiceId: recordId,
                    productId: drift.Value(it['product_id'] ?? it['productId']),
                    productName: it['product_name'] ?? it['productName'] ?? '',
                    productCode: drift.Value(it['product_code'] ?? it['productCode']),
                    unit: it['unit'] ?? 'plate',
                    unitPricePaise: int.tryParse(it['unit_price_paise']?.toString() ?? '0') ?? 0,
                    quantity: double.tryParse(it['quantity']?.toString() ?? '1.0') ?? 1.0,
                    discountPaise: drift.Value(int.tryParse(it['discount_paise']?.toString() ?? '0') ?? 0),
                    gstRatePercent: double.tryParse(it['gst_rate_percent']?.toString() ?? '0.0') ?? 0.0,
                    isTaxInclusive: it['is_tax_inclusive'] ?? it['isTaxInclusive'] ?? true,
                    taxableAmountPaise: int.tryParse(it['taxable_amount_paise']?.toString() ?? '0') ?? 0,
                    taxAmountPaise: int.tryParse(it['tax_amount_paise']?.toString() ?? '0') ?? 0,
                    totalAmountPaise: int.tryParse(it['total_amount_paise']?.toString() ?? '0') ?? 0,
                  ),
                );
              }
            }
          }
        }
        break;

      case 'payments':
        if (!isDelete && d != null) {
          await _db.into(_db.payments).insertOnConflictUpdate(
            PaymentsCompanion.insert(
              id: recordId,
              invoiceId: d['invoice_id'] ?? d['invoiceId'] ?? '',
              amountPaise: int.tryParse(d['amount_paise']?.toString() ?? '0') ?? 0,
              paymentMethod: d['payment_method'] ?? d['paymentMethod'] ?? 'Cash',
              referenceNumber: drift.Value(d['reference_number'] ?? d['referenceNumber']),
              notes: drift.Value(d['notes']),
              createdAt: d['created_at'] != null ? DateTime.parse(d['created_at']) : DateTime.now(),
              businessId: drift.Value(bizId),
              serverVersion: drift.Value(version),
              syncStatus: const drift.Value('synced'),
            ),
          );
        }
        break;

      case 'kot_records':
        if (!isDelete && d != null) {
          final fallbackInvId = d['invoice_id'] ?? d['invoiceId'] ?? d['purchase_invoice_id'] ?? d['purchaseInvoiceId'] ?? recordId;
          await _db.into(_db.kotRecords).insertOnConflictUpdate(
            KotRecordsCompanion.insert(
              id: recordId,
              businessId: drift.Value(d['business_id'] ?? d['businessId']),
              invoiceId: drift.Value(fallbackInvId),
              purchaseInvoiceId: drift.Value(d['purchase_invoice_id'] ?? d['purchaseInvoiceId']),
              supplierInvoiceNumber: drift.Value(d['supplier_invoice_number'] ?? d['supplierInvoiceNumber']),
              kotNumber: d['kot_number'] ?? d['kotNumber'] ?? 'KOT-01',
              orderType: d['order_type'] ?? d['orderType'] ?? 'Dine In',
              tableNumber: drift.Value(d['table_number'] ?? d['tableNumber']),
              itemsJson: d['items_json'] is String ? d['items_json'] : jsonEncode(d['items_json'] ?? []),
              reprintCount: drift.Value(d['reprint_count'] ?? d['reprintCount'] ?? 0),
              createdAt: d['created_at'] != null ? DateTime.parse(d['created_at']) : DateTime.now(),
              serverVersion: drift.Value(version),
              syncStatus: const drift.Value('synced'),
            ),
          );
        }
        break;

      case 'kot_items':
        if (!isDelete && d != null) {
          await _db.into(_db.kotItems).insertOnConflictUpdate(
            KotItemsCompanion.insert(
              id: recordId,
              kotId: d['kot_id'] ?? d['kotId'] ?? '',
              productId: drift.Value(d['product_id'] ?? d['productId']),
              orderItemId: drift.Value(d['order_item_id'] ?? d['orderItemId']),
              productNameSnapshot: d['product_name_snapshot'] ?? d['productNameSnapshot'] ?? '',
              quantity: (d['quantity'] as num?)?.toDouble() ?? 1.0,
              unit: drift.Value(d['unit'] ?? 'unit'),
              specialInstructions: drift.Value(d['special_instructions'] ?? d['specialInstructions']),
              itemStatus: drift.Value(d['item_status'] ?? d['itemStatus'] ?? 'PENDING'),
              createdAt: d['created_at'] != null ? DateTime.parse(d['created_at']) : DateTime.now(),
              updatedAt: d['updated_at'] != null ? DateTime.parse(d['updated_at']) : DateTime.now(),
              serverVersion: drift.Value(version),
              syncStatus: const drift.Value('synced'),
            ),
          );
        }
        break;

      case 'suppliers':
        if (isDelete || d == null) {
          await (_db.update(_db.suppliers)..where((s) => s.id.equals(recordId))).write(
            SuppliersCompanion(
              deletedAt: drift.Value(DateTime.now()),
              isActive: const drift.Value(false),
            ),
          );
        } else {
          await _db.into(_db.suppliers).insertOnConflictUpdate(
            SuppliersCompanion.insert(
              id: recordId,
              businessId: bizId,
              name: d['supplier_name'] ?? d['supplierName'] ?? d['name'] ?? 'Supplier',
              contactPerson: drift.Value(d['contact_person'] ?? d['contactPerson']),
              email: drift.Value(d['email']),
              phone: drift.Value(d['phone']),
              address: drift.Value(d['address']),
              gstin: drift.Value(d['gstin']),
              pan: drift.Value(d['pan']),
              paymentTerms: drift.Value(d['payment_terms'] ?? d['paymentTerms']),
              notes: drift.Value(d['notes']),
              isActive: drift.Value(d['is_active'] ?? d['isActive'] ?? true),
              isVerified: drift.Value(d['is_verified'] ?? d['isVerified'] ?? false),
              createdAt: d['created_at'] != null ? DateTime.parse(d['created_at']) : DateTime.now(),
              updatedAt: d['updated_at'] != null ? DateTime.parse(d['updated_at']) : DateTime.now(),
              deletedAt: drift.Value(d['deleted_at'] != null ? DateTime.parse(d['deleted_at']) : null),
              syncStatus: const drift.Value('synced'),
            ),
          );
        }
        break;

      case 'purchase_orders':
        if (isDelete || d == null) {
          await (_db.update(_db.purchaseOrders)..where((p) => p.id.equals(recordId))).write(
            PurchaseOrdersCompanion(
              deletedAt: drift.Value(DateTime.now()),
            ),
          );
        } else {
          await _db.into(_db.purchaseOrders).insertOnConflictUpdate(
            PurchaseOrdersCompanion.insert(
              id: recordId,
              businessId: bizId,
              supplierId: d['supplier_id'] ?? d['supplierId'] ?? '',
              poNumber: d['po_number'] ?? d['poNumber'] ?? 'PO',
              orderStatus: drift.Value(d['order_status'] ?? d['orderStatus'] ?? 'DRAFT'),
              subtotalPaise: int.tryParse(d['subtotal_paise']?.toString() ?? '0') ?? 0,
              taxPaise: drift.Value(int.tryParse(d['tax_paise']?.toString() ?? '0') ?? 0),
              grandTotalPaise: int.tryParse(d['grand_total_paise']?.toString() ?? '0') ?? 0,
              notes: drift.Value(d['notes']),
              expectedDeliveryDate: drift.Value(d['expected_delivery_date'] != null ? DateTime.tryParse(d['expected_delivery_date']) : null),
              orderedAt: d['ordered_at'] != null ? DateTime.parse(d['ordered_at']) : DateTime.now(),
              createdAt: d['created_at'] != null ? DateTime.parse(d['created_at']) : DateTime.now(),
              updatedAt: d['updated_at'] != null ? DateTime.parse(d['updated_at']) : DateTime.now(),
              syncStatus: const drift.Value('synced'),
            ),
          );
        }
        break;

      case 'purchase_invoices':
        if (isDelete || d == null) {
          await (_db.update(_db.purchaseInvoices)..where((p) => p.id.equals(recordId))).write(
            PurchaseInvoicesCompanion(
              deletedAt: drift.Value(DateTime.now()),
            ),
          );
        } else {
          final invoiceNum = d['supplier_invoice_number']?.toString() ??
              d['supplierInvoiceNumber']?.toString() ??
              d['invoice_number']?.toString() ??
              d['invoiceNumber']?.toString() ??
              'INV';
          final subtotal = int.tryParse(d['subtotal_paise']?.toString() ?? '0') ?? 0;
          final tax = int.tryParse(d['tax_paise']?.toString() ?? d['tax_amount_paise']?.toString() ?? '0') ?? 0;
          final grandTotal = int.tryParse(d['grand_total_paise']?.toString() ?? '0') ?? 0;
          final paid = int.tryParse(d['amount_paid_paise']?.toString() ?? '0') ?? 0;
          final due = int.tryParse(d['balance_due_paise']?.toString() ?? '${grandTotal - paid}') ?? (grandTotal - paid);
          final invDate = d['invoice_date'] != null ? DateTime.parse(d['invoice_date']) : DateTime.now();

          await _db.into(_db.purchaseInvoices).insertOnConflictUpdate(
            PurchaseInvoicesCompanion.insert(
              id: recordId,
              businessId: bizId,
              supplierId: d['supplier_id']?.toString() ?? d['supplierId']?.toString() ?? '',
              purchaseOrderId: drift.Value(d['purchase_order_id']?.toString() ?? d['purchaseOrderId']?.toString()),
              invoiceNumber: invoiceNum,
              verificationStatus: drift.Value(d['verification_status']?.toString() ?? d['verificationStatus']?.toString() ?? d['invoice_status']?.toString() ?? 'PENDING_VERIFICATION'),
              paymentStatus: drift.Value(d['payment_status']?.toString() ?? d['paymentStatus']?.toString() ?? 'PENDING'),
              subtotalPaise: subtotal,
              taxPaise: drift.Value(tax),
              grandTotalPaise: grandTotal,
              amountPaidPaise: drift.Value(paid),
              balanceDuePaise: drift.Value(due),
              notes: drift.Value(d['notes']?.toString()),
              rejectionReason: drift.Value(d['rejection_reason']?.toString() ?? d['rejectionReason']?.toString()),
              invoiceDate: invDate,
              dueDate: drift.Value(d['due_date'] != null ? DateTime.tryParse(d['due_date']) : null),
              createdAt: d['created_at'] != null ? DateTime.parse(d['created_at']) : invDate,
              updatedAt: d['updated_at'] != null ? DateTime.parse(d['updated_at']) : DateTime.now(),
              syncStatus: const drift.Value('synced'),
            ),
          );

          final rawItems = d['purchase_invoice_items'] ?? d['purchaseInvoiceItems'];
          if (rawItems is List) {
            for (final rawIt in rawItems) {
              final it = rawIt as Map<String, dynamic>;
              final itId = it['id']?.toString() ?? _uuid.v4();
              final pName = it['product_name_snapshot']?.toString() ?? it['productName']?.toString() ?? 'Item';
              final pCode = it['product_code_snapshot']?.toString() ?? it['productCode']?.toString();
              final pId = it['product_id']?.toString() ?? it['productId']?.toString();
              final qty = (it['quantity'] as num?)?.toDouble() ?? 1.0;
              final uPrice = int.tryParse(it['unit_price_paise']?.toString() ?? it['unitPricePaise']?.toString() ?? '0') ?? 0;
              final gst = (it['gst_percentage_snapshot'] ?? it['gstPercentage'] ?? it['gstRatePercent'] as num?)?.toDouble() ?? 0.0;
              final taxable = (qty * uPrice).round();
              final lineTax = int.tryParse(it['tax_amount_paise']?.toString() ?? it['taxAmountPaise']?.toString() ?? '${(taxable * gst / 100.0).round()}') ?? (taxable * gst / 100.0).round();
              final lineTotal = int.tryParse(it['total_amount_paise']?.toString() ?? it['totalAmountPaise']?.toString() ?? '${taxable + lineTax}') ?? (taxable + lineTax);

              await _db.into(_db.purchaseInvoiceItems).insertOnConflictUpdate(
                PurchaseInvoiceItemEntry(
                  id: itId,
                  purchaseInvoiceId: recordId,
                  productId: pId,
                  productName: pName,
                  productCode: pCode,
                  quantity: qty,
                  unit: it['unit']?.toString() ?? 'unit',
                  unitPricePaise: uPrice,
                  gstRatePercent: gst,
                  taxableAmountPaise: taxable,
                  taxAmountPaise: lineTax,
                  totalAmountPaise: lineTotal,
                  createdAt: invDate,
                ),
              );
            }
          }
        }
        break;

      case 'supplier_payments':
        if (!isDelete && d != null) {
          await _db.into(_db.supplierPayments).insertOnConflictUpdate(
            SupplierPaymentsCompanion.insert(
              id: recordId,
              businessId: bizId,
              purchaseInvoiceId: d['purchase_invoice_id'] ?? d['purchaseInvoiceId'] ?? '',
              supplierId: d['supplier_id'] ?? d['supplierId'] ?? '',
              paymentVoucherNumber: d['payment_voucher_number'] ?? d['paymentVoucherNumber'] ?? 'PV',
              amountPaise: int.tryParse(d['amount_paise']?.toString() ?? '0') ?? 0,
              paymentMethod: drift.Value(d['payment_method'] ?? d['paymentMethod'] ?? 'Bank Transfer'),
              paymentDate: d['payment_date'] != null ? DateTime.parse(d['payment_date']) : DateTime.now(),
              referenceNumber: drift.Value(d['reference_number'] ?? d['referenceNumber']),
              notes: drift.Value(d['notes']),
              createdAt: d['created_at'] != null ? DateTime.parse(d['created_at']) : DateTime.now(),
              syncStatus: const drift.Value('synced'),
            ),
          );
        }
        break;
    }
  }
}
