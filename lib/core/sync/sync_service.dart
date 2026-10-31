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

  void startAutoSync({Duration interval = const Duration(seconds: 30)}) {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(interval, (_) {
      syncNow();
    });
  }

  void stopAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
  }

  @override
  void dispose() {
    stopAutoSync();
    super.dispose();
  }

  Future<void> _updatePendingCount() async {
    final count = await _db.syncQueue.count().getSingle();
    _state = _state.copyWith(pendingCount: count);
    notifyListeners();
  }

  /// Enqueues a local entity creation, update, or deletion for offline synchronization
  Future<void> enqueueChange({
    required String entityName,
    required String recordId,
    required String operation, // 'INSERT', 'UPDATE', 'DELETE'
    required Map<String, dynamic> payload,
    String? idempotencyKey,
  }) async {
    final bizId = _api.businessId ?? 'default_biz';
    final devId = await _deviceService.getOrGenerateDeviceUid();
    final idemp = idempotencyKey ?? _uuid.v4();

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
        createdAt: DateTime.now(),
      ),
    );

    await _updatePendingCount();
    // Trigger sync immediately in background
    unawaited(syncNow());
  }

  /// Main two-way synchronization loop: pushes local changes then pulls remote changes
  Future<bool> syncNow() async {
    if (_isSyncing) return false;
    if (_api.authToken == null || _api.authToken!.isEmpty) {
      _state = _state.copyWith(status: SyncStatusType.offline);
      notifyListeners();
      return false;
    }

    _isSyncing = true;
    _state = _state.copyWith(status: SyncStatusType.syncing, clearError: true);
    notifyListeners();

    try {
      // 1. Upload local queued changes
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
    final isDelete = op == 'DELETE' || data == null;

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
          final d = data as Map<String, dynamic>;
          await _db.into(_db.categories).insertOnConflictUpdate(
            CategoriesCompanion.insert(
              id: recordId,
              name: d['name'] ?? '',
              icon: drift.Value(d['icon']),
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
          final d = data as Map<String, dynamic>;
          final costPaise = int.tryParse(d['cost_price_paise']?.toString() ?? '0') ?? 0;
          final sellPaise = int.tryParse(d['selling_price_paise']?.toString() ?? '0') ?? 0;
          final gstRate = double.tryParse(d['gst_rate_percent']?.toString() ?? '0.0') ?? 0.0;

          await _db.into(_db.products).insertOnConflictUpdate(
            ProductsCompanion.insert(
              id: recordId,
              name: d['name'] ?? '',
              code: drift.Value(d['code']),
              categoryId: drift.Value(d['category_id'] ?? d['categoryId']),
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
        if (isDelete) {
          await (_db.update(_db.diningTables)..where((t) => t.id.equals(recordId))).write(
            DiningTablesCompanion(
              deletedAt: drift.Value(DateTime.now()),
              isOccupied: const drift.Value(false),
            ),
          );
        } else {
          final d = data as Map<String, dynamic>;
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
        if (isDelete) {
          await (_db.update(_db.customers)..where((c) => c.id.equals(recordId))).write(
            CustomersCompanion(
              deletedAt: drift.Value(DateTime.now()),
            ),
          );
        } else {
          final d = data as Map<String, dynamic>;
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
        if (!isDelete && data is Map<String, dynamic>) {
          final d = data;
          await _db.into(_db.invoices).insertOnConflictUpdate(
            InvoicesCompanion.insert(
              id: recordId,
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
        if (!isDelete && data is Map<String, dynamic>) {
          final d = data;
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
        if (!isDelete && data is Map<String, dynamic>) {
          final d = data;
          await _db.into(_db.kotRecords).insertOnConflictUpdate(
            KotRecordsCompanion.insert(
              id: recordId,
              invoiceId: d['invoice_id'] ?? d['invoiceId'] ?? '',
              kotNumber: d['kot_number'] ?? d['kotNumber'] ?? 'KOT-01',
              orderType: d['order_type'] ?? d['orderType'] ?? 'Dine In',
              tableNumber: drift.Value(d['table_number'] ?? d['tableNumber']),
              itemsJson: d['items_json'] ?? d['itemsJson'] ?? '[]',
              reprintCount: drift.Value(d['reprint_count'] ?? d['reprintCount'] ?? 0),
              createdAt: d['created_at'] != null ? DateTime.parse(d['created_at']) : DateTime.now(),
              serverVersion: drift.Value(version),
              syncStatus: const drift.Value('synced'),
            ),
          );
        }
        break;
    }
  }
}
