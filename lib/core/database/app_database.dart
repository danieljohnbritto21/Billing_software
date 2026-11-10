import 'dart:io';
import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables.dart';
export 'tables.dart';
export 'package:drift/drift.dart' show Value;

import 'app_database_connection_native.dart'
    if (dart.library.js_interop) 'app_database_connection_web.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Categories,
  Suppliers,
  Products,
  Orders,
  OrderItems,
  Invoices,
  InvoiceItems,
  BillNotes,
  Payments,
  PurchaseOrders,
  PurchaseOrderItems,
  PurchaseInvoices,
  PurchaseInvoiceItems,
  SupplierPayments,
  Customers,
  AppSettings,
  ProductImages,
  Users,
  DiningTables,
  KotRecords,
  KotItems,
  SyncCursors,
  SyncQueue,
  SyncConflicts,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e])
      : super(e ?? openConnection());

  @override
  int get schemaVersion => 8;

  /// Creates a backup file of the SQLite database before running migrations
  static Future<void> backupDatabaseBeforeMigration() async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final dbFile = File(p.join(docDir.path, 'foodbillpro.sqlite'));
      if (await dbFile.exists()) {
        final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
        final backupFile = File(p.join(docDir.path, 'foodbillpro_backup_$timestamp.sqlite'));
        await dbFile.copy(backupFile.path);
      }
    } catch (_) {
      // Non-fatal if running in test environment without native filesystem
    }
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.createTable(productImages);
          }
          if (from < 3) {
            await m.createTable(users);
            await m.addColumn(invoices, invoices.orderStatus);
            await m.addColumn(invoices, invoices.cashierId);
            await m.addColumn(invoices, invoices.cashierName);
          }
          if (from < 4) {
            await m.addColumn(invoices, invoices.orderType);
            await m.addColumn(invoices, invoices.tableNumber);
            await m.addColumn(invoices, invoices.deliveryAddress);
            await m.addColumn(invoices, invoices.kotNumber);
          }
          if (from < 6) {
            await backupDatabaseBeforeMigration();

            // 1. Create new sync and domain tables
            await m.createTable(diningTables);
            await m.createTable(kotRecords);
            await m.createTable(syncCursors);
            await m.createTable(syncQueue);
            await m.createTable(syncConflicts);

            // 2. Add sync & soft delete columns to existing tables
            await m.addColumn(categories, categories.businessId);
            await m.addColumn(categories, categories.serverVersion);
            await m.addColumn(categories, categories.deletedAt);
            await m.addColumn(categories, categories.syncStatus);

            await m.addColumn(products, products.businessId);
            await m.addColumn(products, products.serverVersion);
            await m.addColumn(products, products.deletedAt);
            await m.addColumn(products, products.syncStatus);

            await m.addColumn(invoices, invoices.businessId);
            await m.addColumn(invoices, invoices.deviceId);
            await m.addColumn(invoices, invoices.customerId);
            await m.addColumn(invoices, invoices.idempotencyKey);
            await m.addColumn(invoices, invoices.serverVersion);
            await m.addColumn(invoices, invoices.syncStatus);

            await m.addColumn(payments, payments.businessId);
            await m.addColumn(payments, payments.idempotencyKey);
            await m.addColumn(payments, payments.serverVersion);
            await m.addColumn(payments, payments.syncStatus);

            await m.addColumn(customers, customers.businessId);
            await m.addColumn(customers, customers.serverVersion);
            await m.addColumn(customers, customers.deletedAt);
            await m.addColumn(customers, customers.syncStatus);

            await m.addColumn(users, users.businessId);
          }
          if (from < 7) {
            await backupDatabaseBeforeMigration();

            // 1. Create new Admin + Supplier tables
            await m.createTable(suppliers);
            await m.createTable(orders);
            await m.createTable(orderItems);
            await m.createTable(purchaseOrders);
            await m.createTable(purchaseOrderItems);
            await m.createTable(purchaseInvoices);
            await m.createTable(purchaseInvoiceItems);
            await m.createTable(supplierPayments);

            // 2. Add new columns to existing tables
            await m.addColumn(products, products.supplierId);
            await m.addColumn(invoices, invoices.orderId);
            await m.addColumn(users, users.supplierId);
          }
          if (from < 8) {
            await backupDatabaseBeforeMigration();

            // 1. Create new kotItems table
            await m.createTable(kotItems);

            // 2. Add columns to kotRecords
            await m.addColumn(kotRecords, kotRecords.businessId);
            await m.addColumn(kotRecords, kotRecords.purchaseInvoiceId);
            await m.addColumn(kotRecords, kotRecords.supplierInvoiceNumber);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');

          // Ensure kot_records.invoice_id is nullable on existing SQLite databases
          try {
            final tableInfo = await customSelect('PRAGMA table_info(kot_records)').get();
            final invoiceIdCol = tableInfo.cast<dynamic>().firstWhere(
              (row) => row.data['name'] == 'invoice_id',
              orElse: () => null,
            );
            if (invoiceIdCol != null && invoiceIdCol.data['notnull'] == 1) {
              await customStatement('PRAGMA foreign_keys = OFF');
              await customStatement('''
                CREATE TABLE IF NOT EXISTS kot_records_temp_fix (
                  id TEXT NOT NULL PRIMARY KEY,
                  business_id TEXT,
                  invoice_id TEXT,
                  purchase_invoice_id TEXT,
                  supplier_invoice_number TEXT,
                  kot_number TEXT NOT NULL,
                  order_type TEXT NOT NULL,
                  table_number TEXT,
                  items_json TEXT NOT NULL,
                  reprint_count INTEGER NOT NULL DEFAULT 0,
                  created_at INTEGER NOT NULL,
                  server_version INTEGER,
                  sync_status TEXT DEFAULT 'synced'
                )
              ''');
              final colNames = tableInfo.map((r) => r.data['name'] as String).toSet();
              final colsToSelect = [
                'id',
                'kot_number',
                'order_type',
                'table_number',
                'items_json',
                'reprint_count',
                'created_at',
                if (colNames.contains('business_id')) 'business_id' else 'NULL AS business_id',
                if (colNames.contains('invoice_id')) 'invoice_id' else 'NULL AS invoice_id',
                if (colNames.contains('purchase_invoice_id')) 'purchase_invoice_id' else 'NULL AS purchase_invoice_id',
                if (colNames.contains('supplier_invoice_number')) 'supplier_invoice_number' else 'NULL AS supplier_invoice_number',
                if (colNames.contains('server_version')) 'server_version' else 'NULL AS server_version',
                if (colNames.contains('sync_status')) 'sync_status' else "'synced' AS sync_status",
              ].join(', ');

              await customStatement('''
                INSERT INTO kot_records_temp_fix (
                  id, kot_number, order_type, table_number, items_json, reprint_count, created_at,
                  business_id, invoice_id, purchase_invoice_id, supplier_invoice_number,
                  server_version, sync_status
                )
                SELECT $colsToSelect FROM kot_records
              ''');
              await customStatement('DROP TABLE kot_records');
              await customStatement('ALTER TABLE kot_records_temp_fix RENAME TO kot_records');
              await customStatement('PRAGMA foreign_keys = ON');
            }
          } catch (_) {}
        },
      );
}
