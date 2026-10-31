import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodbillpro/core/database/app_database.dart';
import 'package:foodbillpro/features/categories/category_repository.dart';
import 'package:foodbillpro/features/invoices/invoice_repository.dart';
import 'package:foodbillpro/features/products/product_repository.dart';
import 'package:uuid/uuid.dart';

void main() {
  late AppDatabase db;
  late CategoryRepository categoryRepo;
  late ProductRepository productRepo;
  late InvoiceRepository invoiceRepo;
  const uuid = Uuid();

  setUp(() {
    // In-memory SQLite database for isolated, fast testing
    db = AppDatabase(NativeDatabase.memory());
    categoryRepo = CategoryRepository(db);
    productRepo = ProductRepository(db);
    invoiceRepo = InvoiceRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Category and Product Repository Tests', () {
    test('Can seed and retrieve categories', () async {
      await categoryRepo.seedDefaultCategoriesIfEmpty();
      final categories = await categoryRepo.getAllCategories();
      expect(categories, isNotEmpty);
      expect(categories.any((c) => c.name == 'Fast Food'), isTrue);
    });

    test('Products persist in database and can be retrieved by category and search', () async {
      await categoryRepo.addCategory(name: 'Beverages');
      final categories = await categoryRepo.getAllCategories();
      final bevCat = categories.firstWhere((c) => c.name == 'Beverages');

      await productRepo.addProduct(
        name: 'Cold Coffee',
        code: 'BEV-01',
        categoryId: bevCat.id,
        sellingPricePaise: 12000, // ₹120.00
        costPricePaise: 5000,
        unit: 'glass',
        gstRatePercent: 5.0,
      );

      final list = await productRepo.getAllProducts();
      expect(list.length, equals(1));
      expect(list.first.product.name, equals('Cold Coffee'));
      expect(list.first.product.sellingPricePaise, equals(12000));
      expect(list.first.category?.name, equals('Beverages'));

      // Test searching
      final streamResults = await productRepo.watchProducts(searchQuery: 'coffee').first;
      expect(streamResults.length, equals(1));
      expect(streamResults.first.product.code, equals('BEV-01'));
    });

    test('Safe product deactivation when historical records exist', () async {
      // 1. Add product
      await productRepo.addProduct(
        name: 'Veg Burger',
        sellingPricePaise: 9900,
      );
      final products = await productRepo.getAllProducts();
      final burger = products.first.product;

      // 2. Create invoice with this product
      final invoiceId = uuid.v4();
      final now = DateTime.now();

      await invoiceRepo.createInvoice(
        CreateInvoiceParams(
          invoice: InvoicesCompanion.insert(
            id: invoiceId,
            invoiceNumber: 'INV-000001',
            createdAt: now,
            subtotalPaise: 9900,
            taxableAmountPaise: 9900,
            grandTotalPaise: 9900,
            paidAmountPaise: 9900,
          ),
          items: [
            InvoiceItemsCompanion.insert(
              id: uuid.v4(),
              invoiceId: invoiceId,
              productId: drift.Value(burger.id),
              productName: burger.name,
              unit: burger.unit,
              unitPricePaise: burger.sellingPricePaise,
              quantity: 1.0,
              gstRatePercent: 0.0,
              isTaxInclusive: true,
              taxableAmountPaise: 9900,
              taxAmountPaise: 0,
              totalAmountPaise: 9900,
            ),
          ],
        ),
      );

      // 3. Try to delete the product - should deactivate instead of hard delete
      final deleted = await productRepo.deleteProductSafely(burger.id);
      expect(deleted, isFalse, reason: 'Must not hard delete referenced product');

      final updated = await productRepo.getProductById(burger.id);
      expect(updated, isNotNull);
      expect(updated!.isAvailable, isFalse, reason: 'Product is now deactivated');
    });
  });

  group('Invoice and Individual Bill Notes Tests (Highest Priority)', () {
    test('Sequential invoice numbering works accurately', () async {
      final num1 = await invoiceRepo.generateNextInvoiceNumber(prefix: 'INV-');
      expect(num1, equals('INV-000001'));

      final now = DateTime.now();
      await db.into(db.invoices).insert(
            InvoicesCompanion.insert(
              id: uuid.v4(),
              invoiceNumber: num1,
              createdAt: now,
              subtotalPaise: 10000,
              taxableAmountPaise: 10000,
              grandTotalPaise: 10000,
              paidAmountPaise: 10000,
            ),
          );

      final num2 = await invoiceRepo.generateNextInvoiceNumber(prefix: 'INV-');
      expect(num2, equals('INV-000002'));
    });

    test('Creating invoice with note saves atomically to dedicated bill_notes table', () async {
      final invoiceId = uuid.v4();
      final now = DateTime.now();
      const testNote = 'Customer requested less spicy, extra chutney on the side';

      await invoiceRepo.createInvoice(
        CreateInvoiceParams(
          invoice: InvoicesCompanion.insert(
            id: invoiceId,
            invoiceNumber: 'INV-000001',
            createdAt: now,
            subtotalPaise: 25000,
            taxableAmountPaise: 25000,
            grandTotalPaise: 25000,
            paidAmountPaise: 25000,
          ),
          items: [
            InvoiceItemsCompanion.insert(
              id: uuid.v4(),
              invoiceId: invoiceId,
              productName: 'Paneer Butter Masala',
              unit: 'bowl',
              unitPricePaise: 25000,
              quantity: 1.0,
              gstRatePercent: 5.0,
              isTaxInclusive: true,
              taxableAmountPaise: 23810,
              taxAmountPaise: 1190,
              totalAmountPaise: 25000,
            ),
          ],
          billNote: testNote,
        ),
      );

      // Verify invoice details
      final details = await invoiceRepo.getInvoiceWithDetails(invoiceId);
      expect(details, isNotNull);
      expect(details!.invoice.invoiceNumber, equals('INV-000001'));
      expect(details.items.length, equals(1));
      expect(details.billNote, isNotNull);
      expect(details.billNote!.note, equals(testNote));
    });

    test('Bill note can be edited independently without changing invoice financials', () async {
      final invoiceId = uuid.v4();
      final now = DateTime.now();

      await invoiceRepo.createInvoice(
        CreateInvoiceParams(
          invoice: InvoicesCompanion.insert(
            id: invoiceId,
            invoiceNumber: 'INV-000001',
            createdAt: now,
            subtotalPaise: 50000,
            taxableAmountPaise: 50000,
            grandTotalPaise: 50000,
            paidAmountPaise: 50000,
          ),
          items: [],
          billNote: 'Original note: Table 4',
        ),
      );

      // Update the note
      const updatedNote = 'Updated note: Table 4 moved to AC Hall, advance paid ₹200';
      await invoiceRepo.updateBillNote(
        invoiceId: invoiceId,
        noteText: updatedNote,
      );

      final details = await invoiceRepo.getInvoiceWithDetails(invoiceId);
      expect(details!.billNote!.note, equals(updatedNote));
      // Financial amounts must remain 100% untouched
      expect(details.invoice.grandTotalPaise, equals(50000));
      expect(details.invoice.paidAmountPaise, equals(50000));
    });

    test('Note isolation: Editing Invoice A note never affects Invoice B note', () async {
      final idA = uuid.v4();
      final idB = uuid.v4();
      final now = DateTime.now();

      await invoiceRepo.createInvoice(
        CreateInvoiceParams(
          invoice: InvoicesCompanion.insert(
            id: idA,
            invoiceNumber: 'INV-000001',
            createdAt: now,
            subtotalPaise: 10000,
            taxableAmountPaise: 10000,
            grandTotalPaise: 10000,
            paidAmountPaise: 10000,
          ),
          items: [],
          billNote: 'Note for Bill A',
        ),
      );

      await invoiceRepo.createInvoice(
        CreateInvoiceParams(
          invoice: InvoicesCompanion.insert(
            id: idB,
            invoiceNumber: 'INV-000002',
            createdAt: now,
            subtotalPaise: 20000,
            taxableAmountPaise: 20000,
            grandTotalPaise: 20000,
            paidAmountPaise: 20000,
          ),
          items: [],
          billNote: 'Note for Bill B',
        ),
      );

      // Edit Note A
      await invoiceRepo.updateBillNote(
        invoiceId: idA,
        noteText: 'MODIFIED Note for Bill A',
      );

      // Verify Note B is completely untouched
      final detailsB = await invoiceRepo.getInvoiceWithDetails(idB);
      expect(detailsB!.billNote!.note, equals('Note for Bill B'));

      final detailsA = await invoiceRepo.getInvoiceWithDetails(idA);
      expect(detailsA!.billNote!.note, equals('MODIFIED Note for Bill A'));
    });

    test('Historical snapshot preservation: Editing product does not alter old invoice items', () async {
      // 1. Add product at ₹100
      await productRepo.addProduct(
        name: 'Special Biryani',
        sellingPricePaise: 10000,
      );
      final p = (await productRepo.getAllProducts()).first.product;

      // 2. Create bill at ₹100
      final invoiceId = uuid.v4();
      await invoiceRepo.createInvoice(
        CreateInvoiceParams(
          invoice: InvoicesCompanion.insert(
            id: invoiceId,
            invoiceNumber: 'INV-000001',
            createdAt: DateTime.now(),
            subtotalPaise: 10000,
            taxableAmountPaise: 10000,
            grandTotalPaise: 10000,
            paidAmountPaise: 10000,
          ),
          items: [
            InvoiceItemsCompanion.insert(
              id: uuid.v4(),
              invoiceId: invoiceId,
              productId: drift.Value(p.id),
              productName: p.name,
              unit: p.unit,
              unitPricePaise: p.sellingPricePaise,
              quantity: 1.0,
              gstRatePercent: 0.0,
              isTaxInclusive: true,
              taxableAmountPaise: 10000,
              taxAmountPaise: 0,
              totalAmountPaise: 10000,
            ),
          ],
        ),
      );

      // 3. Edit product price to ₹250
      await productRepo.updateProduct(p.copyWith(sellingPricePaise: 25000));

      // 4. Verify old invoice still has ₹100 unit price and ₹100 total
      final details = await invoiceRepo.getInvoiceWithDetails(invoiceId);
      expect(details!.items.first.unitPricePaise, equals(10000),
          reason: 'Historical invoice item price must remain immutable');
      expect(details.items.first.totalAmountPaise, equals(10000));
    });
  });
}
