import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodbillpro/core/constants/app_constants.dart';
import 'package:foodbillpro/core/database/app_database.dart';
import 'package:foodbillpro/features/auth/auth_repository.dart';
import 'package:foodbillpro/features/categories/category_repository.dart';
import 'package:foodbillpro/features/invoices/invoice_repository.dart';
import 'package:foodbillpro/features/products/product_repository.dart';
import 'package:foodbillpro/features/routing/app_router.dart';
import 'package:uuid/uuid.dart';

void main() {
  late AppDatabase db;
  late AuthRepository authRepo;
  late CategoryRepository categoryRepo;
  late ProductRepository productRepo;
  late InvoiceRepository invoiceRepo;
  const uuid = Uuid();

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    authRepo = AuthRepository(db);
    categoryRepo = CategoryRepository(db);
    productRepo = ProductRepository(db);
    invoiceRepo = InvoiceRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Role-Based Authentication & User Management Tests', () {
    test('Default users are seeded with correct roles and credentials', () async {
      await authRepo.seedInitialUsersIfEmpty();

      final admin = await authRepo.authenticate('admin', 'admin123');
      expect(admin, isNotNull);
      expect(admin!.role, equals(AppConstants.roleAdmin));
      expect(admin.username, equals('admin'));
      expect(admin.isActive, isTrue);

      final cashier = await authRepo.authenticate('cashier', 'cashier123');
      expect(cashier, isNotNull);
      expect(cashier!.role, equals(AppConstants.roleCashier));
      expect(cashier.username, equals('cashier'));
      expect(cashier.isActive, isTrue);

      final supplier = await authRepo.authenticate('supplier', 'supplier123', isSupplier: true);
      expect(supplier, isNotNull);
      expect(supplier!.role, equals(AppConstants.roleSupplier));
      expect(supplier.username, equals('supplier'));
      expect(supplier.supplierId, equals('demo-supplier-01'));
      expect(supplier.isActive, isTrue);
    });

    test('Login fails for invalid password and non-existent username', () async {
      await authRepo.seedInitialUsersIfEmpty();

      final wrongPass = await authRepo.authenticate('admin', 'wrong_password');
      expect(wrongPass, isNull);

      final nonexistent = await authRepo.authenticate('unknown_user', 'any_password');
      expect(nonexistent, isNull);
    });

    test('Admin can create, deactivate, and reset passwords for cashiers', () async {
      await authRepo.seedInitialUsersIfEmpty();

      final newCashierId = await authRepo.createUser(
        username: 'john_cashier',
        fullName: 'John Doe',
        password: 'johnpassword123',
        role: AppConstants.roleCashier,
      );

      final loggedIn = await authRepo.authenticate('john_cashier', 'johnpassword123');
      expect(loggedIn, isNotNull);
      expect(loggedIn!.id, equals(newCashierId));
      expect(loggedIn.role, equals(AppConstants.roleCashier));

      // Deactivate cashier
      await authRepo.updateUser(id: newCashierId, isActive: false);
      final inactiveLogin = await authRepo.authenticate('john_cashier', 'johnpassword123');
      expect(inactiveLogin, isNull); // Inactive accounts cannot log in

      // Reactivate cashier and reset password
      await authRepo.updateUser(
        id: newCashierId,
        isActive: true,
        newPassword: 'newpassword456',
      );

      final oldPassLogin = await authRepo.authenticate('john_cashier', 'johnpassword123');
      expect(oldPassLogin, isNull);

      final newPassLogin = await authRepo.authenticate('john_cashier', 'newpassword456');
      expect(newPassLogin, isNotNull);
      expect(newPassLogin!.fullName, equals('John Doe'));
    });

    test('Admin cannot delete the last active admin', () async {
      await authRepo.seedInitialUsersIfEmpty();
      final users = await authRepo.watchUsers().first;
      final admin = users.firstWhere((u) => u.username == 'admin');

      // Attempting to delete the only admin throws an Exception
      expect(
        () async => await authRepo.deleteUser(admin.id),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('Category Safe Deletion & Count Tests', () {
    test('Categories show correct product counts and prevent destructive deletion', () async {
      await categoryRepo.addCategory(name: 'Desserts');
      final allCats = await categoryRepo.getAllCategories(activeOnly: false);
      final cat = allCats.firstWhere((c) => c.name == 'Desserts');
      final catId = cat.id;

      // 0 products initially
      final initialCount = await categoryRepo.getProductCountForCategory(catId);
      expect(initialCount, equals(0));

      // Add product in this category
      await productRepo.addProduct(
        name: 'Chocolate Lava Cake',
        code: 'DES-01',
        categoryId: catId,
        sellingPricePaise: 18000,
        costPricePaise: 8000,
        gstRatePercent: 5.0,
        isTaxInclusive: true,
      );

      // Count is now 1
      final countWithProducts = await categoryRepo.getProductCountForCategory(catId);
      expect(countWithProducts, equals(1));

      // Deleting category with assigned products soft-deletes (returns false)
      final deletedPermanently = await categoryRepo.deleteCategory(catId);
      expect(deletedPermanently, isFalse);

      // Verify category is deactivated rather than removed from database
      final updatedCat = await categoryRepo.getCategoryById(catId);
      expect(updatedCat, isNotNull);
      expect(updatedCat!.isActive, isFalse);
    });
  });

  group('Invoicing with Cashier Tracking & Partial Payments', () {
    test('Invoices store cashier info, order status, and track partial payments', () async {
      final invoiceId = uuid.v4();
      final now = DateTime.now();

      await invoiceRepo.createInvoice(
        CreateInvoiceParams(
          invoice: InvoicesCompanion.insert(
            id: invoiceId,
            invoiceNumber: 'INV-2026-TEST01',
            customerName: const drift.Value('Aarav Patel'),
            customerPhone: const drift.Value('9876543210'),
            subtotalPaise: 50000, // ₹500.00
            taxableAmountPaise: 47619,
            cgstPaise: const drift.Value(1190),
            sgstPaise: const drift.Value(1191),
            grandTotalPaise: 50000, // ₹500.00
            paidAmountPaise: 20000, // ₹200.00 paid upfront (Partially Paid)
            paymentMethod: const drift.Value(AppConstants.paymentCash),
            paymentStatus: const drift.Value(AppConstants.statusPartial),
            orderStatus: const drift.Value(AppConstants.orderCompleted),
            cashierId: const drift.Value('cashier-uuid-001'),
            cashierName: const drift.Value('Ramesh (Cashier)'),
            createdAt: now,
          ),
          items: [
            InvoiceItemsCompanion.insert(
              id: uuid.v4(),
              invoiceId: invoiceId,
              productId: const drift.Value('prod-001'),
              productName: 'Special Thali',
              productCode: const drift.Value('THALI-01'),
              unit: 'plate',
              unitPricePaise: 25000,
              quantity: 2.0,
              discountPaise: const drift.Value(0),
              taxableAmountPaise: 47619,
              gstRatePercent: 5.0,
              isTaxInclusive: true,
              taxAmountPaise: 2381,
              totalAmountPaise: 50000,
            ),
          ],
          billNote: 'Partial advance collected',
          payment: PaymentsCompanion.insert(
            id: uuid.v4(),
            invoiceId: invoiceId,
            amountPaise: 20000,
            paymentMethod: AppConstants.paymentCash,
            createdAt: now,
          ),
        ),
      );

      final details = await invoiceRepo.getInvoiceWithDetails(invoiceId);
      expect(details, isNotNull);
      expect(details!.invoice.cashierId, equals('cashier-uuid-001'));
      expect(details.invoice.cashierName, equals('Ramesh (Cashier)'));
      expect(details.invoice.orderStatus, equals(AppConstants.orderCompleted));
      expect(details.invoice.paymentStatus, equals(AppConstants.statusPartial));
      expect(details.invoice.paidAmountPaise, equals(20000));
      final balanceDue = details.invoice.grandTotalPaise - details.invoice.paidAmountPaise;
      expect(balanceDue, equals(30000)); // ₹300.00 due

      // Customer pending debts summary
      final pendingSummaries = await invoiceRepo.watchCustomerPendingSummaries().first;
      expect(pendingSummaries, isNotEmpty);
      final debtor = pendingSummaries.firstWhere((d) => d.customerPhone == '9876543210');
      expect(debtor.customerName, equals('Aarav Patel'));
      expect(debtor.remainingAmountPaise, equals(30000));

      // Record subsequent payment of remaining ₹300.00
      await invoiceRepo.recordAdditionalPayment(
        invoiceId: invoiceId,
        amountPaise: 30000,
        paymentMethod: AppConstants.paymentUpi,
        notes: 'UPI balance settlement',
      );

      final updatedDetails = await invoiceRepo.getInvoiceWithDetails(invoiceId);
      expect(updatedDetails!.invoice.paidAmountPaise, equals(50000));
      expect(updatedDetails.invoice.paymentStatus, equals(AppConstants.statusPaid));
      final updatedBalanceDue = updatedDetails.invoice.grandTotalPaise - updatedDetails.invoice.paidAmountPaise;
      expect(updatedBalanceDue, equals(0));
      expect(updatedDetails.payments.length, equals(2)); // initial + additional payment
    });
  });

  group('Route Guard Role Isolation Tests', () {
    test('Cashier is strictly restricted from admin routes', () {
      final cashier = UserEntry(
        id: 'c1',
        username: 'cashier',
        fullName: 'Counter Staff',
        role: AppConstants.roleCashier,
        passwordHash: 'hash',
        salt: 'salt',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Check admin routes redirect Cashier to /billing
      expect(checkRouteAccess(user: cashier, location: '/dashboard'), equals('/billing'));
      expect(checkRouteAccess(user: cashier, location: '/products'), equals('/billing'));
      expect(checkRouteAccess(user: cashier, location: '/categories'), equals('/billing'));
      expect(checkRouteAccess(user: cashier, location: '/cashiers'), equals('/billing'));

      // Check permitted routes for Cashier (Menu, Cart, History, Settings, Bills)
      expect(checkRouteAccess(user: cashier, location: '/billing'), isNull);
      expect(checkRouteAccess(user: cashier, location: '/cart'), isNull);
      expect(checkRouteAccess(user: cashier, location: '/history'), isNull);
      expect(checkRouteAccess(user: cashier, location: '/settings'), isNull);
      expect(checkRouteAccess(user: cashier, location: '/bills'), isNull);
      expect(checkRouteAccess(user: cashier, location: '/bills/INV-001'), isNull);
    });

    test('Admin has access to all routes', () {
      final admin = UserEntry(
        id: 'a1',
        username: 'admin',
        fullName: 'Store Admin',
        role: AppConstants.roleAdmin,
        passwordHash: 'hash',
        salt: 'salt',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(checkRouteAccess(user: admin, location: '/dashboard'), isNull);
      expect(checkRouteAccess(user: admin, location: '/products'), isNull);
      expect(checkRouteAccess(user: admin, location: '/categories'), isNull);
      expect(checkRouteAccess(user: admin, location: '/cashiers'), isNull);
      expect(checkRouteAccess(user: admin, location: '/billing'), isNull);
      expect(checkRouteAccess(user: admin, location: '/cart'), isNull);
      expect(checkRouteAccess(user: admin, location: '/history'), isNull);
      expect(checkRouteAccess(user: admin, location: '/bills'), isNull);
      expect(checkRouteAccess(user: admin, location: '/settings'), isNull);
    });

    test('Unauthenticated user is always redirected to /login', () {
      expect(checkRouteAccess(user: null, location: '/dashboard'), equals('/login'));
      expect(checkRouteAccess(user: null, location: '/billing'), equals('/login'));
      expect(checkRouteAccess(user: null, location: '/products'), equals('/login'));
      expect(checkRouteAccess(user: null, location: '/login'), isNull);
    });
  });

  group('Cashier Order Workflow & Pending Order Lifecycle Tests', () {
    test('Save as Pending order, add items, and complete order without duplicate invoices', () async {
      // 1. Initial save as Pending order for Table 4 (Dine In)
      final p1Id = uuid.v4();
      final pendingInvoiceId = await invoiceRepo.saveOrUpdatePendingOrder(
        invoiceNumber: 'ORD-TEST-001',
        orderType: AppConstants.orderTypeDineIn,
        tableNumber: 'Table 4',
        deliveryAddress: null,
        customerName: 'Karan Mehra',
        customerPhone: '9876501234',
        subtotalPaise: 30000,
        itemDiscountTotalPaise: 0,
        billDiscountPaise: 0,
        taxableAmountPaise: 28571,
        cgstPaise: 714,
        sgstPaise: 715,
        roundOffPaise: 0,
        grandTotalPaise: 30000,
        items: [
          InvoiceItemsCompanion.insert(
            id: uuid.v4(),
            invoiceId: '', // populated in transaction
            productId: drift.Value(p1Id),
            productName: 'Paneer Butter Masala',
            productCode: const drift.Value('CUR-01'),
            unit: 'portion',
            unitPricePaise: 30000,
            quantity: 1.0,
            discountPaise: const drift.Value(0),
            taxableAmountPaise: 28571,
            gstRatePercent: 5.0,
            isTaxInclusive: true,
            taxAmountPaise: 1429,
            totalAmountPaise: 30000,
          ),
        ],
        billNote: 'Less spicy',
        cashierId: 'c-01',
        cashierName: 'John (Cashier)',
      );

      final pendingDetails = await invoiceRepo.getInvoiceWithDetails(pendingInvoiceId);
      expect(pendingDetails, isNotNull);
      expect(pendingDetails!.invoice.orderStatus, equals(AppConstants.orderPending));
      expect(pendingDetails.invoice.paymentStatus, equals(AppConstants.statusPending));
      expect(pendingDetails.invoice.tableNumber, equals('Table 4'));
      expect(pendingDetails.invoice.orderType, equals(AppConstants.orderTypeDineIn));
      expect(pendingDetails.invoice.paidAmountPaise, equals(0));

      // Table 4 should now be in occupied tables
      final occupiedTables = await invoiceRepo.getOccupiedTables();
      expect(occupiedTables, contains('Table 4'));

      // Pending orders count should be 1
      final pendingCount = await invoiceRepo.watchPendingOrdersCount().first;
      expect(pendingCount, equals(1));

      // 2. Add More: Reopen pending order and add an extra item
      final p2Id = uuid.v4();
      final updatedInvoiceId = await invoiceRepo.saveOrUpdatePendingOrder(
        existingInvoiceId: pendingInvoiceId,
        invoiceNumber: 'ORD-TEST-001',
        orderType: AppConstants.orderTypeDineIn,
        tableNumber: 'Table 4',
        deliveryAddress: null,
        customerName: 'Karan Mehra',
        customerPhone: '9876501234',
        subtotalPaise: 42000, // + ₹120.00 Naan
        itemDiscountTotalPaise: 0,
        billDiscountPaise: 0,
        taxableAmountPaise: 40000,
        cgstPaise: 1000,
        sgstPaise: 1000,
        roundOffPaise: 0,
        grandTotalPaise: 42000,
        items: [
          InvoiceItemsCompanion.insert(
            id: uuid.v4(),
            invoiceId: pendingInvoiceId,
            productId: drift.Value(p1Id),
            productName: 'Paneer Butter Masala',
            unit: 'portion',
            unitPricePaise: 30000,
            quantity: 1.0,
            taxableAmountPaise: 28571,
            gstRatePercent: 5.0,
            isTaxInclusive: true,
            taxAmountPaise: 1429,
            totalAmountPaise: 30000,
          ),
          InvoiceItemsCompanion.insert(
            id: uuid.v4(),
            invoiceId: pendingInvoiceId,
            productId: drift.Value(p2Id),
            productName: 'Butter Naan',
            unit: 'piece',
            unitPricePaise: 6000,
            quantity: 2.0,
            taxableAmountPaise: 11429,
            gstRatePercent: 5.0,
            isTaxInclusive: true,
            taxAmountPaise: 571,
            totalAmountPaise: 12000,
          ),
        ],
        billNote: 'Less spicy, serve hot',
        cashierId: 'c-01',
        cashierName: 'John (Cashier)',
      );

      // Verify same invoice ID, no duplicate invoice created
      expect(updatedInvoiceId, equals(pendingInvoiceId));

      final detailsAfterAdd = await invoiceRepo.getInvoiceWithDetails(pendingInvoiceId);
      expect(detailsAfterAdd!.invoice.grandTotalPaise, equals(42000));
      expect(detailsAfterAdd.items.length, equals(2));
      expect(detailsAfterAdd.billNote?.note, equals('Less spicy, serve hot'));

      // 3. Complete Order with payment
      await invoiceRepo.completeOrder(
        invoiceId: pendingInvoiceId,
        paymentMethod: AppConstants.paymentUpi,
        paidAmountPaise: 42000,
      );

      final completedDetails = await invoiceRepo.getInvoiceWithDetails(pendingInvoiceId);
      expect(completedDetails!.invoice.orderStatus, equals(AppConstants.orderCompleted));
      expect(completedDetails.invoice.paymentStatus, equals(AppConstants.statusPaid));
      expect(completedDetails.invoice.paidAmountPaise, equals(42000));

      // Table 4 is now freed up
      final occupiedTablesAfterComplete = await invoiceRepo.getOccupiedTables();
      expect(occupiedTablesAfterComplete, isNot(contains('Table 4')));

      // Pending count should now be 0
      final pendingCountAfterComplete = await invoiceRepo.watchPendingOrdersCount().first;
      expect(pendingCountAfterComplete, equals(0));
    });
  });
}
