import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodbillpro/core/constants/app_constants.dart';
import 'package:foodbillpro/core/database/app_database.dart';
import 'package:foodbillpro/features/categories/category_repository.dart';
import 'package:foodbillpro/features/invoices/invoice_repository.dart';
import 'package:foodbillpro/features/printer/invoice_pdf_generator.dart';
import 'package:foodbillpro/features/products/product_repository.dart';
import 'package:uuid/uuid.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late CategoryRepository categoryRepo;
  late ProductRepository productRepo;
  late InvoiceRepository invoiceRepo;
  const uuid = Uuid();

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    categoryRepo = CategoryRepository(db);
    productRepo = ProductRepository(db);
    invoiceRepo = InvoiceRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Admin Category to Cashier Synchronization & Product Tests', () {
    test('Category created in Admin immediately appears in category list and can be used to add products', () async {
      // 1. Create a category in Admin
      await categoryRepo.addCategory(name: 'Tandoori Delights', displayOrder: 1);

      // Verify it immediately appears in active categories
      final activeCategories = await categoryRepo.getAllCategories(activeOnly: true);
      expect(activeCategories.any((c) => c.name == 'Tandoori Delights'), isTrue);
      final tandooriCat = activeCategories.firstWhere((c) => c.name == 'Tandoori Delights');

      // 2. Add product using that Admin category
      final pId = await productRepo.addProduct(
        name: 'Tandoori Paneer Tikka Special',
        code: 'TAN-01',
        categoryId: tandooriCat.id,
        sellingPricePaise: 24000, // ₹240.00
        costPricePaise: 11000,
        gstRatePercent: 5.0,
        isTaxInclusive: true,
        unit: 'portion',
      );

      // 3. Verify product appears under the assigned category
      final productsUnderCategory = await productRepo
          .watchProducts(categoryId: tandooriCat.id, onlyAvailable: true)
          .first;
      expect(productsUnderCategory.length, equals(1));
      expect(productsUnderCategory.first.product.id, equals(pId));
      expect(productsUnderCategory.first.product.name, equals('Tandoori Paneer Tikka Special'));
      expect(productsUnderCategory.first.category?.name, equals('Tandoori Delights'));

      // 4. Verify product also appears in 'ALL' products
      final allProducts = await productRepo.watchProducts(onlyAvailable: true).first;
      expect(allProducts.any((p) => p.product.id == pId), isTrue);
    });

    test('Category deletion safely preserves products and handles soft-delete', () async {
      await categoryRepo.addCategory(name: 'Beverages Seasonal');
      final cat = (await categoryRepo.getAllCategories(activeOnly: true))
          .firstWhere((c) => c.name == 'Beverages Seasonal');

      await productRepo.addProduct(
        name: 'Fresh Mango Lassi',
        categoryId: cat.id,
        sellingPricePaise: 8000,
      );

      // Category has 1 product -> deleteCategory soft-deletes (returns false)
      final hardDeleted = await categoryRepo.deleteCategory(cat.id);
      expect(hardDeleted, isFalse);

      // Deactivated category no longer appears in active categories
      final activeCategories = await categoryRepo.getAllCategories(activeOnly: true);
      expect(activeCategories.any((c) => c.id == cat.id), isFalse);

      // Existing product is still preserved in database and retrievable
      final product = await productRepo.getProductById(
        (await productRepo.getAllProducts()).firstWhere((p) => p.product.name == 'Fresh Mango Lassi').product.id,
      );
      expect(product, isNotNull);
      expect(product!.isAvailable, isTrue);
    });
  });

  group('KOT and Final Bill Generation Tests', () {
    test('Dine In order for Table 5 generates KOT and Final Bill with exact values', () async {
      final p1Id = uuid.v4();
      final p2Id = uuid.v4();

      final pendingInvoiceId = await invoiceRepo.saveOrUpdatePendingOrder(
        invoiceNumber: 'INV-000021',
        orderType: AppConstants.orderTypeDineIn,
        tableNumber: 'Table 5',
        deliveryAddress: null,
        customerName: 'Rahul Sharma',
        customerPhone: '9876543210',
        subtotalPaise: 23900, // ₹90.00 Naan (2) + ₹149.00 Burger (1) = ₹239.00
        itemDiscountTotalPaise: 0,
        billDiscountPaise: 0,
        taxableAmountPaise: 22762,
        cgstPaise: 569,
        sgstPaise: 569,
        roundOffPaise: 0,
        grandTotalPaise: 23900,
        items: [
          InvoiceItemsCompanion.insert(
            id: uuid.v4(),
            invoiceId: '',
            productId: drift.Value(p1Id),
            productName: 'Butter Naan',
            unit: 'piece',
            unitPricePaise: 4500,
            quantity: 2.0,
            taxableAmountPaise: 8571,
            gstRatePercent: 5.0,
            isTaxInclusive: true,
            taxAmountPaise: 429,
            totalAmountPaise: 9000,
          ),
          InvoiceItemsCompanion.insert(
            id: uuid.v4(),
            invoiceId: '',
            productId: drift.Value(p2Id),
            productName: 'Chicken Burger',
            unit: 'piece',
            unitPricePaise: 14900,
            quantity: 1.0,
            taxableAmountPaise: 14191,
            gstRatePercent: 5.0,
            isTaxInclusive: true,
            taxAmountPaise: 709,
            totalAmountPaise: 14900,
          ),
        ],
        billNote: 'Less spicy',
        cashierId: 'cashier-1',
        cashierName: 'Ramesh',
      );

      final details = await invoiceRepo.getInvoiceWithDetails(pendingInvoiceId);
      expect(details, isNotNull);

      final settings = {
        'business_name': 'FoodBill Pro Restaurant',
        'business_address': '123 Food Street, MG Road, Bengaluru',
        'business_phone': '9876500000',
        'business_gstin': '29ABCDE1234F1Z5',
        'receipt_footer': 'Thank you for visiting!',
        'printer_width': '80mm',
      };

      // 1. Generate KOT for 80mm
      final kot80Bytes = await InvoicePdfGenerator.generateKot(
        details: details!,
        settings: settings,
        format: ReceiptFormat.thermal80mm,
      );
      expect(kot80Bytes, isNotEmpty);

      // 2. Generate KOT for 58mm
      final kot58Bytes = await InvoicePdfGenerator.generateKot(
        details: details,
        settings: settings,
        format: ReceiptFormat.thermal58mm,
      );
      expect(kot58Bytes, isNotEmpty);

      // 3. Complete order and generate Final Bill
      await invoiceRepo.completeOrder(
        invoiceId: pendingInvoiceId,
        paymentMethod: AppConstants.paymentCash,
        paidAmountPaise: 23900,
      );

      final completedDetails = await invoiceRepo.getInvoiceWithDetails(pendingInvoiceId);
      expect(completedDetails!.invoice.orderStatus, equals(AppConstants.orderCompleted));
      expect(completedDetails.invoice.paidAmountPaise, equals(23900));

      // Final Bill 80mm
      final bill80Bytes = await InvoicePdfGenerator.generate(
        details: completedDetails,
        settings: settings,
        format: ReceiptFormat.thermal80mm,
      );
      expect(bill80Bytes, isNotEmpty);

      // Final Bill 58mm
      final bill58Bytes = await InvoicePdfGenerator.generate(
        details: completedDetails,
        settings: settings,
        format: ReceiptFormat.thermal58mm,
      );
      expect(bill58Bytes, isNotEmpty);

      // Final Bill A4
      final billA4Bytes = await InvoicePdfGenerator.generate(
        details: completedDetails,
        settings: settings,
        format: ReceiptFormat.a4Invoice,
      );
      expect(billA4Bytes, isNotEmpty);
    });

    test('Takeaway order generates KOT and Bill without table number', () async {
      final pId = uuid.v4();
      final invoiceId = await invoiceRepo.saveOrUpdatePendingOrder(
        invoiceNumber: 'INV-000022',
        orderType: AppConstants.orderTypeTakeaway,
        tableNumber: null,
        deliveryAddress: null,
        customerName: 'Pooja V',
        customerPhone: '9123456780',
        subtotalPaise: 15000,
        itemDiscountTotalPaise: 0,
        billDiscountPaise: 0,
        taxableAmountPaise: 14286,
        cgstPaise: 357,
        sgstPaise: 357,
        roundOffPaise: 0,
        grandTotalPaise: 15000,
        items: [
          InvoiceItemsCompanion.insert(
            id: uuid.v4(),
            invoiceId: '',
            productId: drift.Value(pId),
            productName: 'Veg Hakka Noodles with Extra Sauce and Crispy Vegetables',
            unit: 'plate',
            unitPricePaise: 15000,
            quantity: 1.0,
            taxableAmountPaise: 14286,
            gstRatePercent: 5.0,
            isTaxInclusive: true,
            taxAmountPaise: 714,
            totalAmountPaise: 15000,
          ),
        ],
        cashierId: 'c1',
        cashierName: 'Counter',
      );

      final details = await invoiceRepo.getInvoiceWithDetails(invoiceId);
      expect(details!.invoice.orderType, equals(AppConstants.orderTypeTakeaway));
      expect(details.invoice.tableNumber, isNull);

      final settings = {'business_name': 'FoodBill Pro Takeaway', 'printer_width': '58mm'};
      final kotBytes = await InvoicePdfGenerator.generateKot(details: details, settings: settings);
      expect(kotBytes, isNotEmpty);

      final billBytes = await InvoicePdfGenerator.generate(details: details, settings: settings);
      expect(billBytes, isNotEmpty);
    });

    test('Delivery order generates Bill with delivery address and customer info', () async {
      final pId = uuid.v4();
      final invoiceId = await invoiceRepo.saveOrUpdatePendingOrder(
        invoiceNumber: 'INV-000023',
        orderType: AppConstants.orderTypeDelivery,
        tableNumber: null,
        deliveryAddress: 'Flat 302, Green Valley Apartments, 5th Cross',
        customerName: 'Vikram Singh',
        customerPhone: '9888877777',
        subtotalPaise: 50000,
        itemDiscountTotalPaise: 0,
        billDiscountPaise: 0,
        taxableAmountPaise: 47619,
        cgstPaise: 1190,
        sgstPaise: 1191,
        roundOffPaise: 0,
        grandTotalPaise: 50000,
        items: [
          InvoiceItemsCompanion.insert(
            id: uuid.v4(),
            invoiceId: '',
            productId: drift.Value(pId),
            productName: 'Family Feast Combo',
            unit: 'combo',
            unitPricePaise: 50000,
            quantity: 1.0,
            taxableAmountPaise: 47619,
            gstRatePercent: 5.0,
            isTaxInclusive: true,
            taxAmountPaise: 2381,
            totalAmountPaise: 50000,
          ),
        ],
        cashierId: 'c1',
        cashierName: 'Counter',
      );

      final details = await invoiceRepo.getInvoiceWithDetails(invoiceId);
      expect(details!.invoice.orderType, equals(AppConstants.orderTypeDelivery));
      expect(details.invoice.deliveryAddress, equals('Flat 302, Green Valley Apartments, 5th Cross'));

      final settings = {'business_name': 'FoodBill Pro Express'};
      final billBytes = await InvoicePdfGenerator.generate(details: details, settings: settings);
      expect(billBytes, isNotEmpty);
    });
  });
}
