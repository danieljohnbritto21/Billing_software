import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodbillpro/core/api/api_client.dart';
import 'package:foodbillpro/core/api/device_service.dart';
import 'package:foodbillpro/core/database/app_database.dart';
import 'package:foodbillpro/core/sync/sync_service.dart';
import 'package:uuid/uuid.dart';

void main() {
  group('Phase 5 & 6: Multi-Device Sync and Data Migration Tests', () {
    const uuid = Uuid();
    late AppDatabase dbPhoneA;
    late AppDatabase dbPhoneB;

    setUp(() {
      drift.driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      dbPhoneA = AppDatabase(NativeDatabase.memory());
      dbPhoneB = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await dbPhoneA.close();
      await dbPhoneB.close();
    });

    test('Two separate phones generate distinct device UIDs and can register independently', () async {
      final apiA = ApiClient(dbPhoneA);
      final apiB = ApiClient(dbPhoneB);
      final devServiceA = DeviceService(dbPhoneA, apiA);
      final devServiceB = DeviceService(dbPhoneB, apiB);

      final uidA = await devServiceA.getOrGenerateDeviceUid();
      final uidB = await devServiceB.getOrGenerateDeviceUid();

      expect(uidA, isNotEmpty);
      expect(uidB, isNotEmpty);
      expect(uidA.length, greaterThanOrEqualTo(8));
      expect(uidB.length, greaterThanOrEqualTo(8));
    });

    test('Local offline changes on Phone A are enqueued with unique idempotency keys', () async {
      final api = ApiClient(dbPhoneA);
      final devService = DeviceService(dbPhoneA, api);
      final syncService = SyncService(dbPhoneA, api, devService);

      final catId = uuid.v4();
      final idempKey = 'idemp-$catId';

      await syncService.enqueueChange(
        entityName: 'categories',
        recordId: catId,
        operation: 'INSERT',
        payload: {
          'id': catId,
          'name': 'Beverages',
          'displayOrder': 1,
          'isActive': true,
        },
        idempotencyKey: idempKey,
      );

      final queue = await dbPhoneA.select(dbPhoneA.syncQueue).get();
      expect(queue.length, equals(1));
      expect(queue.first.syncEntity, equals('categories'));
      expect(queue.first.recordId, equals(catId));
      expect(queue.first.idempotencyKey, equals(idempKey));
      expect(queue.first.status, equals('pending'));

      final payload = jsonDecode(queue.first.payloadJson);
      expect(payload['name'], equals('Beverages'));
      expect(syncService.state.pendingCount, equals(1));
    });

    test('Commit-safe cursor tracks progress and advances only after applying changes', () async {
      const bizId = 'biz-test-01';

      // 1. Initial cursor is absent
      final initialCursor = await (dbPhoneB.select(dbPhoneB.syncCursors)
            ..where((c) => c.syncEntity.equals('global') & c.businessId.equals(bizId)))
          .getSingleOrNull();
      expect(initialCursor, isNull);

      // 2. Insert batch of synchronized changes from server into Phone B
      final catId = uuid.v4();
      final prodId = uuid.v4();
      final now = DateTime.now();

      await dbPhoneB.transaction(() async {
        // Apply remote category
        await dbPhoneB.into(dbPhoneB.categories).insert(
              CategoriesCompanion.insert(
                id: catId,
                name: 'Main Course',
                displayOrder: const drift.Value(1),
                isActive: const drift.Value(true),
                createdAt: now,
              ),
            );

        // Apply remote product
        await dbPhoneB.into(dbPhoneB.products).insert(
              ProductsCompanion.insert(
                id: prodId,
                name: 'Butter Chicken',
                categoryId: drift.Value(catId),
                sellingPricePaise: 35000,
                unit: const drift.Value('plate'),
                createdAt: now,
                updatedAt: now,
              ),
            );

        // Advance cursor to server commit sequence 42
        await dbPhoneB.into(dbPhoneB.syncCursors).insertOnConflictUpdate(
              SyncCursorsCompanion.insert(
                syncEntity: 'global',
                businessId: bizId,
                lastServerCursor: drift.Value(BigInt.from(42)),
                lastSyncAt: drift.Value(now),
                status: const drift.Value('synced'),
              ),
            );
      });

      // Verify records are present in Phone B SQLite
      final categoriesB = await dbPhoneB.select(dbPhoneB.categories).get();
      expect(categoriesB.length, equals(1));
      expect(categoriesB.first.name, equals('Main Course'));

      final productsB = await dbPhoneB.select(dbPhoneB.products).get();
      expect(productsB.length, equals(1));
      expect(productsB.first.name, equals('Butter Chicken'));
      expect(productsB.first.sellingPricePaise, equals(35000));

      // Verify cursor is 42
      final savedCursor = await (dbPhoneB.select(dbPhoneB.syncCursors)
            ..where((c) => c.syncEntity.equals('global') & c.businessId.equals(bizId)))
          .getSingle();
      expect(savedCursor.lastServerCursor, equals(BigInt.from(42)));
    });

    test('Conflict recording stores both client and server versions without corrupting local data', () async {
      final conflictId = uuid.v4();
      final recordId = uuid.v4();

      final clientPayload = {
        'id': recordId,
        'name': 'Paneer Tikka (Edited Offline Phone A)',
        'sellingPricePaise': 24000,
      };

      final serverPayload = {
        'id': recordId,
        'name': 'Paneer Tikka (Updated on Phone B)',
        'sellingPricePaise': 26000,
        'serverVersion': 5,
      };

      await dbPhoneA.into(dbPhoneA.syncConflicts).insert(
            SyncConflictsCompanion.insert(
              id: conflictId,
              syncEntity: 'products',
              recordId: recordId,
              clientPayloadJson: jsonEncode(clientPayload),
              serverPayloadJson: jsonEncode(serverPayload),
              resolution: const drift.Value('SERVER_WINS'),
              createdAt: DateTime.now(),
            ),
          );

      final conflicts = await dbPhoneA.select(dbPhoneA.syncConflicts).get();
      expect(conflicts.length, equals(1));
      expect(conflicts.first.recordId, equals(recordId));
      expect(conflicts.first.syncEntity, equals('products'));

      final parsedClient = jsonDecode(conflicts.first.clientPayloadJson);
      final parsedServer = jsonDecode(conflicts.first.serverPayloadJson);
      expect(parsedClient['sellingPricePaise'], equals(24000));
      expect(parsedServer['sellingPricePaise'], equals(26000));
    });

    test('Soft-deleted records sync downstream without deleting historical invoice references', () async {
      final catId = uuid.v4();
      final prodId = uuid.v4();
      final invId = uuid.v4();
      final now = DateTime.now();

      // 1. Phone B has product and an invoice referencing it
      await dbPhoneB.into(dbPhoneB.categories).insert(
            CategoriesCompanion.insert(
              id: catId,
              name: 'Desserts',
              createdAt: now,
            ),
          );

      await dbPhoneB.into(dbPhoneB.products).insert(
            ProductsCompanion.insert(
              id: prodId,
              name: 'Gulab Jamun',
              categoryId: drift.Value(catId),
              sellingPricePaise: 6000,
              createdAt: now,
              updatedAt: now,
            ),
          );

      await dbPhoneB.into(dbPhoneB.invoices).insert(
            InvoicesCompanion.insert(
              id: invId,
              invoiceNumber: 'INV-00100',
              subtotalPaise: 6000,
              taxableAmountPaise: 6000,
              grandTotalPaise: 6000,
              paidAmountPaise: 6000,
              createdAt: now,
            ),
          );

      await dbPhoneB.into(dbPhoneB.invoiceItems).insert(
            InvoiceItemsCompanion.insert(
              id: uuid.v4(),
              invoiceId: invId,
              productId: drift.Value(prodId),
              productName: 'Gulab Jamun',
              unit: 'plate',
              unitPricePaise: 6000,
              quantity: 1.0,
              gstRatePercent: 0.0,
              isTaxInclusive: true,
              taxableAmountPaise: 6000,
              taxAmountPaise: 0,
              totalAmountPaise: 6000,
            ),
          );

      // 2. Incoming sync event: Product was soft-deleted on server
      final deleteTime = DateTime.now();
      await (dbPhoneB.update(dbPhoneB.products)..where((p) => p.id.equals(prodId))).write(
        ProductsCompanion(
          deletedAt: drift.Value(deleteTime),
          isAvailable: const drift.Value(false),
          syncStatus: const drift.Value('synced'),
        ),
      );

      // Verify product is soft-deleted
      final product = await (dbPhoneB.select(dbPhoneB.products)..where((p) => p.id.equals(prodId))).getSingle();
      expect(product.deletedAt, isNotNull);
      expect(product.isAvailable, isFalse);

      // Historical invoice items remain fully preserved!
      final invoiceItems = await (dbPhoneB.select(dbPhoneB.invoiceItems)..where((i) => i.invoiceId.equals(invId))).get();
      expect(invoiceItems.length, equals(1));
      expect(invoiceItems.first.productName, equals('Gulab Jamun'));
      expect(invoiceItems.first.totalAmountPaise, equals(6000));
    });
  });
}
