import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodbillpro/core/database/app_database.dart';
import 'package:drift/drift.dart' as drift;

void main() {
  group('Phase 7: SQLite Database Schema & Migration Tests', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('Schema version is 7 and all 23 tables are initialized', () async {
      expect(db.schemaVersion, 7);

      // Verify all tables exist and can be queried without error
      final categories = await db.select(db.categories).get();
      expect(categories, isEmpty);

      final suppliers = await db.select(db.suppliers).get();
      expect(suppliers, isEmpty);

      final products = await db.select(db.products).get();
      expect(products, isEmpty);

      final orders = await db.select(db.orders).get();
      expect(orders, isEmpty);

      final orderItems = await db.select(db.orderItems).get();
      expect(orderItems, isEmpty);

      final invoices = await db.select(db.invoices).get();
      expect(invoices, isEmpty);

      final invoiceItems = await db.select(db.invoiceItems).get();
      expect(invoiceItems, isEmpty);

      final billNotes = await db.select(db.billNotes).get();
      expect(billNotes, isEmpty);

      final payments = await db.select(db.payments).get();
      expect(payments, isEmpty);

      final purchaseOrders = await db.select(db.purchaseOrders).get();
      expect(purchaseOrders, isEmpty);

      final purchaseOrderItems = await db.select(db.purchaseOrderItems).get();
      expect(purchaseOrderItems, isEmpty);

      final purchaseInvoices = await db.select(db.purchaseInvoices).get();
      expect(purchaseInvoices, isEmpty);

      final purchaseInvoiceItems = await db.select(db.purchaseInvoiceItems).get();
      expect(purchaseInvoiceItems, isEmpty);

      final supplierPayments = await db.select(db.supplierPayments).get();
      expect(supplierPayments, isEmpty);

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

    test('Supplier and Product with supplierId can be written and read', () async {
      final now = DateTime.now();

      // 1. Insert Supplier
      await db.into(db.suppliers).insert(
        SuppliersCompanion.insert(
          id: 'supp-test-01',
          businessId: 'biz-01',
          name: 'Supreme Dairy Supplies',
          contactPerson: const drift.Value('Ramesh Kumar'),
          phone: const drift.Value('+91 9876543210'),
          gstin: const drift.Value('29AAAAA0000A1Z5'),
          createdAt: now,
          updatedAt: now,
          isVerified: const drift.Value(true),
        ),
      );

      final supp = await (db.select(db.suppliers)..where((s) => s.id.equals('supp-test-01'))).getSingle();
      expect(supp.name, 'Supreme Dairy Supplies');
      expect(supp.contactPerson, 'Ramesh Kumar');
      expect(supp.isVerified, isTrue);

      // 2. Insert Product linked to supplier
      await db.into(db.products).insert(
        ProductsCompanion.insert(
          id: 'prod-test-01',
          businessId: const drift.Value('biz-01'),
          supplierId: const drift.Value('supp-test-01'),
          name: 'Fresh Paneer 1kg',
          sellingPricePaise: 35000,
          costPricePaise: const drift.Value(28000),
          createdAt: now,
          updatedAt: now,
        ),
      );

      final prod = await (db.select(db.products)..where((p) => p.id.equals('prod-test-01'))).getSingle();
      expect(prod.name, 'Fresh Paneer 1kg');
      expect(prod.supplierId, 'supp-test-01');
      expect(prod.sellingPricePaise, 35000);
      expect(prod.costPricePaise, 28000);
    });

    test('Purchase Order, Invoice, and Supplier Payment lifecycle', () async {
      final now = DateTime.now();

      // Insert Supplier
      await db.into(db.suppliers).insert(
        SuppliersCompanion.insert(
          id: 'supp-02',
          businessId: 'biz-01',
          name: 'Grain & Spice Traders',
          createdAt: now,
          updatedAt: now,
        ),
      );

      // Insert Purchase Order
      await db.into(db.purchaseOrders).insert(
        PurchaseOrdersCompanion.insert(
          id: 'po-01',
          businessId: 'biz-01',
          supplierId: 'supp-02',
          poNumber: 'PO-0001',
          subtotalPaise: 50000,
          grandTotalPaise: 52500,
          taxPaise: const drift.Value(2500),
          orderedAt: now,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final po = await (db.select(db.purchaseOrders)..where((p) => p.id.equals('po-01'))).getSingle();
      expect(po.poNumber, 'PO-0001');
      expect(po.grandTotalPaise, 52500);

      // Insert Purchase Invoice
      await db.into(db.purchaseInvoices).insert(
        PurchaseInvoicesCompanion.insert(
          id: 'pi-01',
          businessId: 'biz-01',
          supplierId: 'supp-02',
          purchaseOrderId: const drift.Value('po-01'),
          invoiceNumber: 'SINV-001',
          subtotalPaise: 50000,
          grandTotalPaise: 52500,
          balanceDuePaise: const drift.Value(52500),
          verificationStatus: const drift.Value('APPROVED'),
          invoiceDate: now,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final pi = await (db.select(db.purchaseInvoices)..where((i) => i.id.equals('pi-01'))).getSingle();
      expect(pi.invoiceNumber, 'SINV-001');
      expect(pi.verificationStatus, 'APPROVED');

      // Insert Supplier Payment
      await db.into(db.supplierPayments).insert(
        SupplierPaymentsCompanion.insert(
          id: 'spay-01',
          businessId: 'biz-01',
          purchaseInvoiceId: 'pi-01',
          supplierId: 'supp-02',
          paymentVoucherNumber: 'PV-0001',
          amountPaise: 52500,
          paymentDate: now,
          createdAt: now,
          paymentMethod: const drift.Value('NEFT'),
        ),
      );

      final spay = await (db.select(db.supplierPayments)..where((p) => p.id.equals('spay-01'))).getSingle();
      expect(spay.paymentVoucherNumber, 'PV-0001');
      expect(spay.amountPaise, 52500);
      expect(spay.paymentMethod, 'NEFT');
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
          orderId: const drift.Value('order-hist-01'),
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
      expect(inv.orderId, 'order-hist-01');
    });
  });
}
