import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodbillpro/core/database/app_database.dart';
import 'package:drift/drift.dart' as drift;

void main() {
  group('Phase 4: SQLite Database Schema & Migration Tests', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('Schema version is 6 and all 15 tables are initialized', () async {
      expect(db.schemaVersion, 6);

      // Verify all tables exist and can be queried without error
      final categories = await db.select(db.categories).get();
      expect(categories, isEmpty);

      final products = await db.select(db.products).get();
      expect(products, isEmpty);

      final invoices = await db.select(db.invoices).get();
      expect(invoices, isEmpty);

      final invoiceItems = await db.select(db.invoiceItems).get();
      expect(invoiceItems, isEmpty);

      final billNotes = await db.select(db.billNotes).get();
      expect(billNotes, isEmpty);

      final payments = await db.select(db.payments).get();
      expect(payments, isEmpty);

      final customers = await db.select(db.customers).get();
      expect(customers, isEmpty);

      final appSettings = await db.select(db.appSettings).get();
      expect(appSettings, isEmpty);

      final productImages = await db.select(db.productImages).get();
      expect(productImages, isEmpty);

      final users = await db.select(db.users).get();
      expect(users, isEmpty);

      final diningTables = await db.select(db.diningTables).get();
      expect(diningTables, isEmpty);

      final kotRecords = await db.select(db.kotRecords).get();
      expect(kotRecords, isEmpty);

      final syncCursors = await db.select(db.syncCursors).get();
      expect(syncCursors, isEmpty);

      final syncQueue = await db.select(db.syncQueue).get();
      expect(syncQueue, isEmpty);

      final syncConflicts = await db.select(db.syncConflicts).get();
      expect(syncConflicts, isEmpty);
    });

    test('Sync metadata, device ID, business ID and soft-deletion columns can be written and read', () async {
      final now = DateTime.now();

      // Insert Category with sync metadata
      await db.into(db.categories).insert(
        CategoriesCompanion.insert(
          id: 'cat-test-01',
          name: 'South Indian',
          createdAt: now,
          businessId: const drift.Value('biz-01'),
          serverVersion: drift.Value(BigInt.from(12)),
          syncStatus: const drift.Value('synced'),
        ),
      );

      final cat = await (db.select(db.categories)..where((c) => c.id.equals('cat-test-01'))).getSingle();
      expect(cat.businessId, 'biz-01');
      expect(cat.serverVersion, BigInt.from(12));
      expect(cat.syncStatus, 'synced');
      expect(cat.deletedAt, isNull);

      // Insert Product with sync metadata
      await db.into(db.products).insert(
        ProductsCompanion.insert(
          id: 'prod-test-01',
          name: 'Idli Vada Combo',
          sellingPricePaise: 8000,
          createdAt: now,
          updatedAt: now,
          businessId: const drift.Value('biz-01'),
          serverVersion: drift.Value(BigInt.from(15)),
          syncStatus: const drift.Value('synced'),
        ),
      );

      final prod = await (db.select(db.products)..where((p) => p.id.equals('prod-test-01'))).getSingle();
      expect(prod.businessId, 'biz-01');
      expect(prod.serverVersion, BigInt.from(15));
      expect(prod.syncStatus, 'synced');

      // Insert Dining Table
      await db.into(db.diningTables).insert(
        DiningTablesCompanion.insert(
          id: 'table-01',
          name: 'Table 1',
          updatedAt: now,
          businessId: const drift.Value('biz-01'),
          seatingCapacity: const drift.Value(4),
          isOccupied: const drift.Value(true),
        ),
      );

      final table = await (db.select(db.diningTables)..where((t) => t.id.equals('table-01'))).getSingle();
      expect(table.name, 'Table 1');
      expect(table.seatingCapacity, 4);
      expect(table.isOccupied, isTrue);

      // Insert Sync Queue entry
      await db.into(db.syncQueue).insert(
        SyncQueueCompanion.insert(
          id: 'queue-01',
          businessId: 'biz-01',
          deviceId: 'dev-phone-a',
          syncEntity: 'invoices',
          recordId: 'inv-test-01',
          operation: 'INSERT',
          payloadJson: '{"grandTotalPaise": 8000}',
          idempotencyKey: 'idemp-inv-01',
          createdAt: now,
        ),
      );

      final queue = await (db.select(db.syncQueue)..where((q) => q.id.equals('queue-01'))).getSingle();
      expect(queue.syncEntity, 'invoices');
      expect(queue.idempotencyKey, 'idemp-inv-01');
      expect(queue.status, 'pending');

      // Insert Sync Cursor entry
      await db.into(db.syncCursors).insert(
        SyncCursorsCompanion.insert(
          syncEntity: 'global',
          businessId: 'biz-01',
          lastServerCursor: drift.Value(BigInt.from(42)),
          lastSyncAt: drift.Value(now),
        ),
      );

      final cursor = await (db.select(db.syncCursors)
        ..where((c) => c.syncEntity.equals('global') & c.businessId.equals('biz-01'))).getSingle();
      expect(cursor.lastServerCursor, BigInt.from(42));

      // Insert Sync Conflict entry
      await db.into(db.syncConflicts).insert(
        SyncConflictsCompanion.insert(
          id: 'conf-01',
          syncEntity: 'products',
          recordId: 'prod-test-01',
          clientPayloadJson: '{"name": "Local Edit"}',
          serverPayloadJson: '{"name": "Server Edit"}',
          resolution: const drift.Value('SERVER_WINS'),
          createdAt: now,
        ),
      );

      final conflict = await (db.select(db.syncConflicts)..where((c) => c.id.equals('conf-01'))).getSingle();
      expect(conflict.resolution, 'SERVER_WINS');
    });

    test('Historical financial integrity is strictly preserved', () async {
      final now = DateTime.now();

      await db.into(db.invoices).insert(
        InvoicesCompanion.insert(
          id: 'hist-inv-01',
          invoiceNumber: 'INV-HIST-0001',
          createdAt: now,
          subtotalPaise: 10000,
          taxableAmountPaise: 10000,
          cgstPaise: const drift.Value(250),
          sgstPaise: const drift.Value(250),
          grandTotalPaise: 10500,
          paidAmountPaise: 10500,
          businessId: const drift.Value('biz-01'),
          deviceId: const drift.Value('dev-01'),
          idempotencyKey: const drift.Value('idemp-hist-01'),
        ),
      );

      final inv = await (db.select(db.invoices)..where((i) => i.id.equals('hist-inv-01'))).getSingle();
      expect(inv.invoiceNumber, 'INV-HIST-0001');
      expect(inv.subtotalPaise, 10000);
      expect(inv.taxableAmountPaise, 10000);
      expect(inv.cgstPaise, 250);
      expect(inv.sgstPaise, 250);
      expect(inv.grandTotalPaise, 10500);
      expect(inv.paidAmountPaise, 10500);
    });
  });
}
