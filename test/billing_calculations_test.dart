import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodbillpro/core/database/app_database.dart';
import 'package:foodbillpro/core/utils/currency_formatter.dart';
import 'package:foodbillpro/features/billing/cart_provider.dart';
import 'package:foodbillpro/features/categories/category_repository.dart';
import 'package:foodbillpro/features/invoices/invoice_repository.dart';
import 'package:foodbillpro/features/products/product_repository.dart';
import 'package:uuid/uuid.dart';

ProductEntry _makeProduct({
  String id = 'p1',
  String name = 'Test Product',
  int sellingPricePaise = 30000,
  double gstRatePercent = 5.0,
  bool isTaxInclusive = false,
  String unit = 'plate',
}) {
  final now = DateTime.now();
  return ProductEntry(
    id: id,
    name: name,
    sellingPricePaise: sellingPricePaise,
    costPricePaise: 0,
    gstRatePercent: gstRatePercent,
    isTaxInclusive: isTaxInclusive,
    unit: unit,
    isAvailable: true,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  // ───────────────────────────────────────────────
  // 1. Tax Calculation Unit Tests
  // ───────────────────────────────────────────────
  group('GST Tax Calculation', () {
    test('Scenario 1: ₹300 tax-exclusive with 5% GST', () {
      final calc = CurrencyFormatter.calculateItemTax(
        unitPricePaise: 30000,
        quantity: 1.0,
        gstRatePercent: 5.0,
        isTaxInclusive: false,
      );
      expect(calc.taxableAmountPaise, equals(30000)); // ₹300.00
      expect(calc.totalTaxPaise, equals(1500)); // ₹15.00
      expect(calc.totalAmountPaise, equals(31500)); // ₹315.00
      expect(calc.cgstPaise + calc.sgstPaise, equals(1500));
    });

    test('Scenario 2: ₹300 tax-inclusive with 5% GST', () {
      final calc = CurrencyFormatter.calculateItemTax(
        unitPricePaise: 30000,
        quantity: 1.0,
        gstRatePercent: 5.0,
        isTaxInclusive: true,
      );
      // Taxable = 30000 * 100 / 105 = 28571 (≈₹285.71)
      expect(calc.taxableAmountPaise, equals(28571));
      expect(calc.totalTaxPaise, equals(30000 - 28571)); // ≈₹14.29
      expect(calc.totalAmountPaise, equals(30000)); // ₹300.00 (unchanged)
    });

    test('Scenario 3: Multiple products with different GST rates', () {
      // Product A: ₹200 exclusive @ 12%
      final calcA = CurrencyFormatter.calculateItemTax(
        unitPricePaise: 20000,
        quantity: 1.0,
        gstRatePercent: 12.0,
        isTaxInclusive: false,
      );
      expect(calcA.taxableAmountPaise, equals(20000));
      expect(calcA.totalTaxPaise, equals(2400)); // ₹24
      expect(calcA.totalAmountPaise, equals(22400)); // ₹224

      // Product B: ₹500 inclusive @ 18%
      final calcB = CurrencyFormatter.calculateItemTax(
        unitPricePaise: 50000,
        quantity: 1.0,
        gstRatePercent: 18.0,
        isTaxInclusive: true,
      );
      // Taxable = 50000 * 100 / 118 = 42373 (≈₹423.73)
      expect(calcB.taxableAmountPaise, equals(42373));
      expect(calcB.totalAmountPaise, equals(50000)); // inclusive stays same
    });

    test('Scenario 4: Quantity > 1 (tax-exclusive)', () {
      final calc = CurrencyFormatter.calculateItemTax(
        unitPricePaise: 30000,
        quantity: 3.0,
        gstRatePercent: 5.0,
        isTaxInclusive: false,
      );
      // 300 * 3 = 900, tax = 45, total = 945
      expect(calc.taxableAmountPaise, equals(90000));
      expect(calc.totalTaxPaise, equals(4500));
      expect(calc.totalAmountPaise, equals(94500));
    });

    test('Scenario 5: Discount applied (tax-exclusive)', () {
      final calc = CurrencyFormatter.calculateItemTax(
        unitPricePaise: 30000,
        quantity: 1.0,
        gstRatePercent: 5.0,
        isTaxInclusive: false,
        discountPaise: 5000, // ₹50 discount
      );
      // Taxable = (300 - 50) = 250 = 25000 paise
      expect(calc.taxableAmountPaise, equals(25000));
      expect(calc.totalTaxPaise, equals(1250)); // ₹12.50
      expect(calc.totalAmountPaise, equals(26250)); // ₹262.50
    });

    test('Scenario 6: Zero-rated GST (0%)', () {
      final calc = CurrencyFormatter.calculateItemTax(
        unitPricePaise: 10000,
        quantity: 2.0,
        gstRatePercent: 0.0,
        isTaxInclusive: false,
      );
      expect(calc.taxableAmountPaise, equals(20000));
      expect(calc.totalTaxPaise, equals(0));
      expect(calc.totalAmountPaise, equals(20000));
    });

    test('Scenario 6b: Zero-rated GST (0%) with inclusive flag', () {
      final calc = CurrencyFormatter.calculateItemTax(
        unitPricePaise: 10000,
        quantity: 1.0,
        gstRatePercent: 0.0,
        isTaxInclusive: true,
      );
      expect(calc.taxableAmountPaise, equals(10000));
      expect(calc.totalTaxPaise, equals(0));
      expect(calc.totalAmountPaise, equals(10000));
    });
  });

  // ───────────────────────────────────────────────
  // 2. Cart Calculation Tests
  // ───────────────────────────────────────────────
  group('Cart & Grand Total Calculations', () {
    test('Tax-exclusive product: grand total includes GST', () {
      final notifier = CartNotifier();
      final p = _makeProduct(
        sellingPricePaise: 30000,
        gstRatePercent: 5.0,
        isTaxInclusive: false,
      );
      notifier.addProduct(p);
      final cart = notifier.state;

      // subtotal = raw selling price sum = ₹300
      expect(cart.subtotalPaise, equals(30000));
      // taxable = ₹300
      expect(cart.taxableAmountPaise, equals(30000));
      // tax = ₹15
      expect(cart.cgstPaise + cart.sgstPaise, equals(1500));
      // finalTotalPaise per item = tax.totalAmountPaise = ₹315
      expect(cart.items.first.finalTotalPaise, equals(31500));
      // grand total = ₹315 (rounded to nearest rupee)
      expect(cart.grandTotalPaise, equals(31500));
    });

    test('Tax-inclusive product: grand total equals selling price', () {
      final notifier = CartNotifier();
      final p = _makeProduct(
        sellingPricePaise: 30000,
        gstRatePercent: 5.0,
        isTaxInclusive: true,
      );
      notifier.addProduct(p);
      final cart = notifier.state;

      expect(cart.subtotalPaise, equals(30000));
      expect(cart.items.first.finalTotalPaise, equals(30000));
      expect(cart.grandTotalPaise, equals(30000));
    });

    test('Mixed inclusive/exclusive products', () {
      final notifier = CartNotifier();
      final pExcl = _makeProduct(
        id: 'p1',
        sellingPricePaise: 10000, // ₹100 exclusive @ 5%
        gstRatePercent: 5.0,
        isTaxInclusive: false,
      );
      final pIncl = _makeProduct(
        id: 'p2',
        sellingPricePaise: 10500, // ₹105 inclusive @ 5%
        gstRatePercent: 5.0,
        isTaxInclusive: true,
      );
      notifier.addProduct(pExcl);
      notifier.addProduct(pIncl);
      final cart = notifier.state;

      // Exclusive: total = 100 + 5 = 105 = 10500 paise
      // Inclusive: total = 105 = 10500 paise
      // Grand total = 10500 + 10500 = 21000 paise = ₹210
      expect(cart.grandTotalPaise, equals(21000));
    });

    test('Bill discount reduces grand total', () {
      final notifier = CartNotifier();
      final p = _makeProduct(
        sellingPricePaise: 30000,
        gstRatePercent: 5.0,
        isTaxInclusive: false,
      );
      notifier.addProduct(p);
      notifier.setBillDiscount(1500); // ₹15 bill discount
      final cart = notifier.state;

      // Item total = 31500 (315 with GST)
      // Bill discount = 1500
      // Raw grand total = 31500 - 1500 = 30000
      expect(cart.rawGrandTotalPaise, equals(30000));
      expect(cart.grandTotalPaise, equals(30000)); // already at rupee boundary
    });

    test('Quantity > 1 with tax-exclusive', () {
      final notifier = CartNotifier();
      final p = _makeProduct(
        sellingPricePaise: 15000, // ₹150 exclusive @ 5%
        gstRatePercent: 5.0,
        isTaxInclusive: false,
      );
      notifier.addProduct(p, quantity: 2.0);
      final cart = notifier.state;

      // 150 * 2 = 300 taxable, tax = 15, total = 315
      expect(cart.items.first.taxCalculation.taxableAmountPaise, equals(30000));
      expect(cart.items.first.taxCalculation.totalAmountPaise, equals(31500));
      expect(cart.items.first.finalTotalPaise, equals(31500));
      expect(cart.grandTotalPaise, equals(31500));
    });
  });

  // ───────────────────────────────────────────────
  // 3. Database Repository Tests
  // ───────────────────────────────────────────────
  group('Product Persistence & POS Visibility', () {
    late AppDatabase db;
    late CategoryRepository categoryRepo;
    late ProductRepository productRepo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      categoryRepo = CategoryRepository(db);
      productRepo = ProductRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('Scenario 7: Saving a new available product and finding it in POS', () async {
      await categoryRepo.addCategory(name: 'Fast Food');
      final cats = await categoryRepo.getAllCategories();
      final catId = cats.first.id;

      final productId = await productRepo.addProduct(
        name: 'Chicken Burger',
        code: 'BUR-01',
        categoryId: catId,
        sellingPricePaise: 14900,
        gstRatePercent: 5.0,
        isTaxInclusive: true,
        unit: 'piece',
        isAvailable: true,
      );

      // Simulate POS query (onlyAvailable: true)
      final products =
          await productRepo.watchProducts(onlyAvailable: true).first;
      expect(products.length, equals(1));
      expect(products.first.product.id, equals(productId));
      expect(products.first.product.name, equals('Chicken Burger'));
      expect(products.first.product.sellingPricePaise, equals(14900));
      expect(products.first.category?.name, equals('Fast Food'));
    });

    test('Scenario 7b: Product without category also appears in POS', () async {
      await productRepo.addProduct(
        name: 'Misc Item',
        sellingPricePaise: 5000,
        isAvailable: true,
      );

      final products =
          await productRepo.watchProducts(onlyAvailable: true).first;
      expect(products.length, equals(1));
      expect(products.first.product.name, equals('Misc Item'));
      expect(products.first.category, isNull);
    });

    test('Scenario 8: Editing a product updates its information', () async {
      final id = await productRepo.addProduct(
        name: 'Old Name',
        sellingPricePaise: 10000,
      );

      var p = await productRepo.getProductById(id);
      expect(p, isNotNull);
      expect(p!.name, equals('Old Name'));

      await productRepo.updateProduct(
        p.copyWith(name: 'New Name', sellingPricePaise: 20000),
      );

      p = await productRepo.getProductById(id);
      expect(p!.name, equals('New Name'));
      expect(p.sellingPricePaise, equals(20000));
    });
  });

  // ───────────────────────────────────────────────
  // 4. Invoice & Receipt Consistency Tests
  // ───────────────────────────────────────────────
  group('Invoice Storage & Receipt Consistency', () {
    late AppDatabase db;
    late InvoiceRepository invoiceRepo;
    const uuid = Uuid();

    setUp(() {
      drift.driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      db = AppDatabase(NativeDatabase.memory());
      invoiceRepo = InvoiceRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('Scenario 9: Saved bill displays same grand total in details and receipt', () async {
      // Simulate a cart with 1 item @ ₹300 tax-exclusive 5% GST
      final tax = CurrencyFormatter.calculateItemTax(
        unitPricePaise: 30000,
        quantity: 1.0,
        gstRatePercent: 5.0,
        isTaxInclusive: false,
      );

      final invoiceId = uuid.v4();
      final now = DateTime.now();

      await invoiceRepo.createInvoice(
        CreateInvoiceParams(
          invoice: InvoicesCompanion.insert(
            id: invoiceId,
            invoiceNumber: 'INV-000001',
            createdAt: now,
            subtotalPaise: 30000,
            taxableAmountPaise: tax.taxableAmountPaise,
            cgstPaise: drift.Value(tax.cgstPaise),
            sgstPaise: drift.Value(tax.sgstPaise),
            grandTotalPaise: tax.totalAmountPaise,
            paidAmountPaise: tax.totalAmountPaise,
          ),
          items: [
            InvoiceItemsCompanion.insert(
              id: uuid.v4(),
              invoiceId: invoiceId,
              productName: 'Test Product',
              unit: 'plate',
              unitPricePaise: 30000,
              quantity: 1.0,
              gstRatePercent: 5.0,
              isTaxInclusive: false,
              taxableAmountPaise: tax.taxableAmountPaise,
              taxAmountPaise: tax.totalTaxPaise,
              totalAmountPaise: tax.totalAmountPaise,
            ),
          ],
        ),
      );

      final details = await invoiceRepo.getInvoiceWithDetails(invoiceId);
      expect(details, isNotNull);
      expect(details!.invoice.grandTotalPaise, equals(31500)); // ₹315
      expect(details.items.first.totalAmountPaise, equals(31500));
      expect(details.items.first.taxAmountPaise, equals(1500)); // ₹15 GST
      expect(details.invoice.paidAmountPaise, equals(31500));

      // Verify the receipt would use the same data (it reads invoice.grandTotalPaise)
      expect(details.invoice.grandTotalPaise, equals(details.items.first.totalAmountPaise));
    });

    test('Scenario 10: Receipt with non-zero totals, taxes, and payment', () async {
      final tax = CurrencyFormatter.calculateItemTax(
        unitPricePaise: 15000,
        quantity: 2.0,
        gstRatePercent: 5.0,
        isTaxInclusive: true,
      );

      final invoiceId = uuid.v4();
      final now = DateTime.now();

      await invoiceRepo.createInvoice(
        CreateInvoiceParams(
          invoice: InvoicesCompanion.insert(
            id: invoiceId,
            invoiceNumber: 'INV-000002',
            createdAt: now,
            subtotalPaise: 30000, // 150 * 2
            taxableAmountPaise: tax.taxableAmountPaise,
            cgstPaise: drift.Value(tax.cgstPaise),
            sgstPaise: drift.Value(tax.sgstPaise),
            grandTotalPaise: tax.totalAmountPaise,
            paymentMethod: const drift.Value('UPI'),
            paidAmountPaise: tax.totalAmountPaise,
          ),
          items: [
            InvoiceItemsCompanion.insert(
              id: uuid.v4(),
              invoiceId: invoiceId,
              productName: 'Burger',
              unit: 'piece',
              unitPricePaise: 15000,
              quantity: 2.0,
              gstRatePercent: 5.0,
              isTaxInclusive: true,
              taxableAmountPaise: tax.taxableAmountPaise,
              taxAmountPaise: tax.totalTaxPaise,
              totalAmountPaise: tax.totalAmountPaise,
            ),
          ],
          payment: PaymentsCompanion.insert(
            id: uuid.v4(),
            invoiceId: invoiceId,
            amountPaise: tax.totalAmountPaise,
            paymentMethod: 'UPI',
            createdAt: now,
          ),
        ),
      );

      final details = await invoiceRepo.getInvoiceWithDetails(invoiceId);
      expect(details, isNotNull);

      // Grand total must NOT be zero
      expect(details!.invoice.grandTotalPaise, greaterThan(0));
      // Tax must NOT be zero (5% GST on ₹300)
      expect(details.invoice.cgstPaise + details.invoice.sgstPaise, greaterThan(0));
      // Paid amount matches grand total
      expect(details.invoice.paidAmountPaise, equals(details.invoice.grandTotalPaise));
      // Payment record exists
      expect(details.payments.length, equals(1));
      expect(details.payments.first.amountPaise, equals(details.invoice.grandTotalPaise));
    });

    test('Scenario 11: Products with and without images (image fields nullable)', () async {
      // This test ensures the image field doesn't block product creation
      final db2 = AppDatabase(NativeDatabase.memory());
      final productRepo = ProductRepository(db2);

      // Product without images
      final id1 = await productRepo.addProduct(
        name: 'No Image Product',
        sellingPricePaise: 10000,
      );

      final p1 = await productRepo.getProductById(id1);
      expect(p1, isNotNull);
      expect(p1!.imagePath, isNull);

      final primaryImg = await productRepo.getPrimaryImageForProduct(id1);
      expect(primaryImg, isNull);

      await db2.close();
    });

    test('Scenario 12: Data persists across simulated app restart (same DB)', () async {
      // Create invoice
      final invoiceId = uuid.v4();
      await invoiceRepo.createInvoice(
        CreateInvoiceParams(
          invoice: InvoicesCompanion.insert(
            id: invoiceId,
            invoiceNumber: 'INV-PERSIST',
            createdAt: DateTime.now(),
            subtotalPaise: 50000,
            taxableAmountPaise: 50000,
            grandTotalPaise: 50000,
            paidAmountPaise: 50000,
          ),
          items: [],
        ),
      );

      // Re-read (simulating restart with same DB)
      final details = await invoiceRepo.getInvoiceWithDetails(invoiceId);
      expect(details, isNotNull);
      expect(details!.invoice.invoiceNumber, equals('INV-PERSIST'));
      expect(details.invoice.grandTotalPaise, equals(50000));
    });
  });

  // ───────────────────────────────────────────────
  // 5. Cart → Invoice Pipeline End-to-End
  // ───────────────────────────────────────────────
  group('Cart-to-Invoice Pipeline', () {
    test('Cart totals match what would be stored in invoice', () {
      final notifier = CartNotifier();

      // Add a tax-exclusive product
      final p = _makeProduct(
        sellingPricePaise: 30000,
        gstRatePercent: 5.0,
        isTaxInclusive: false,
      );
      notifier.addProduct(p);

      final cart = notifier.state;

      // Simulate what billing_screen does when creating invoice
      final ci = cart.items.first;
      final tax = ci.taxCalculation;

      // The invoice would store these values:
      final invoiceGrandTotal = cart.grandTotalPaise;
      final itemTotalAmountPaise = tax.totalAmountPaise;

      // They must be consistent
      expect(invoiceGrandTotal, equals(31500)); // ₹315
      expect(itemTotalAmountPaise, equals(31500)); // ₹315

      // The finalTotalPaise on CartItem must match tax.totalAmountPaise
      expect(ci.finalTotalPaise, equals(tax.totalAmountPaise));
    });

    test('Cart with multiple items produces correct aggregate totals', () {
      final notifier = CartNotifier();

      // Item 1: ₹300 exclusive @ 5%
      notifier.addProduct(_makeProduct(
        id: 'a',
        sellingPricePaise: 30000,
        gstRatePercent: 5.0,
        isTaxInclusive: false,
      ));

      // Item 2: ₹200 inclusive @ 12%
      notifier.addProduct(_makeProduct(
        id: 'b',
        sellingPricePaise: 20000,
        gstRatePercent: 12.0,
        isTaxInclusive: true,
      ));

      final cart = notifier.state;

      // Item 1: taxable 300, tax 15, total 315 (31500 paise)
      // Item 2: taxable ~178.57, tax ~21.43, total 200 (20000 paise)
      // Grand total: 315 + 200 = 515 = 51500 paise
      expect(cart.grandTotalPaise, equals(51500));

      // Verify tax amounts
      expect(cart.items[0].taxCalculation.totalAmountPaise, equals(31500));
      expect(cart.items[1].taxCalculation.totalAmountPaise, equals(20000));
    });
  });
}
