import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodbillpro/core/api/api_client.dart';
import 'package:foodbillpro/core/api/device_service.dart';
import 'package:foodbillpro/core/constants/app_constants.dart';
import 'package:foodbillpro/core/database/app_database.dart';
import 'package:foodbillpro/core/sync/sync_service.dart';
import 'package:foodbillpro/features/auth/auth_repository.dart';
import 'package:foodbillpro/features/invoices/invoice_repository.dart';
import 'package:foodbillpro/features/printer/invoice_pdf_generator.dart';
import 'package:foodbillpro/features/printer/procurement_pdf_generator.dart';
import 'package:foodbillpro/features/printer/thermal_esc_pos_generator.dart';
import 'package:foodbillpro/features/purchases/purchase_repository.dart';
import 'package:foodbillpro/features/suppliers/supplier_repository.dart';
import 'package:uuid/uuid.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  drift.driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late ApiClient api;
  late DeviceService deviceService;
  late SyncService syncService;
  late InvoiceRepository invoiceRepo;
  late SupplierRepository supplierRepo;
  late PurchaseRepository purchaseRepo;
  late AuthRepository authRepo;
  const uuid = Uuid();

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    api = ApiClient(db);
    deviceService = DeviceService(db, api);
    syncService = SyncService(db, api, deviceService);
    invoiceRepo = InvoiceRepository(db, syncService);
    supplierRepo = SupplierRepository(db);
    purchaseRepo = PurchaseRepository(db);
    authRepo = AuthRepository(db);
  });

  tearDown(() async {
    syncService.dispose();
    await db.close();
  });

  // =========================================================================
  // GROUP 1: ROLE-BASED ACCESS CONTROL & LEGACY CASHIER DEPRECATION AUDIT
  // =========================================================================
  group('Phase 9.1 - Security & Role-Based Access Control Audit', () {
    test('1.1 Admin account can authenticate and access administrative privileges', () async {
      await authRepo.seedInitialUsersIfEmpty();

      final user = await authRepo.authenticate('admin', 'admin123');
      expect(user, isNotNull);
      expect(user!.role, equals(AppConstants.roleAdmin));
      expect(user.isActive, isTrue);
    });

    test('1.2 Supplier account can authenticate and receives isolated supplierId', () async {
      final now = DateTime.now();
      // SHA-256 hash of 'supplier123' with salt 'salt_sup_123'
      // password + salt = 'supplier123salt_sup_123'
      // sha256 = e97bec3292b3eed4deb59035054c7a66fe2e4abcb7046e94e33a7e944db02966
      await db.into(db.users).insert(
        UsersCompanion.insert(
          id: 'user-sup-01',
          username: 'dairy_supplier',
          fullName: 'Dairy Supplier Rep',
          role: AppConstants.roleSupplier,
          passwordHash: 'e97bec3292b3eed4deb59035054c7a66fe2e4abcb7046e94e33a7e944db02966',
          salt: 'salt_sup_123',
          supplierId: const drift.Value('sup-dairy-1'),
          isActive: const drift.Value(true),
          createdAt: now,
          updatedAt: now,
        ),
      );

      final user = await authRepo.authenticate('dairy_supplier', 'supplier123', isSupplier: true);
      expect(user, isNotNull);
      expect(user!.role, equals(AppConstants.roleSupplier));
      expect(user.supplierId, equals('sup-dairy-1'));
    });

    test('1.3 Legacy cashier accounts are permanently rejected and unable to log in', () async {
      final now = DateTime.now();
      await db.into(db.users).insert(
        UsersCompanion.insert(
          id: 'cashier-old',
          username: 'cashier_legacy',
          fullName: 'Old Cashier Staff',
          role: 'cashier_legacy',
          passwordHash: '8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918',
          salt: 'salt123',
          isActive: const drift.Value(false),
          createdAt: now,
          updatedAt: now,
        ),
      );

      // Attempt login as general admin/billing staff
      final result1 = await authRepo.authenticate('cashier_legacy', 'admin123', isSupplier: false);
      expect(result1, isNull);

      // Attempt login via supplier portal
      final result2 = await authRepo.authenticate('cashier_legacy', 'admin123', isSupplier: true);
      expect(result2, isNull);
    });

    test('1.4 Inactive or deleted accounts are blocked from authentication', () async {
      final now = DateTime.now();
      await db.into(db.users).insert(
        UsersCompanion.insert(
          id: 'admin-deactivated',
          username: 'former_admin',
          fullName: 'Ex Admin',
          role: AppConstants.roleAdmin,
          passwordHash: '8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918',
          salt: 'salt123',
          isActive: const drift.Value(false), // Deactivated
          createdAt: now,
          updatedAt: now,
        ),
      );

      final result = await authRepo.authenticate('former_admin', 'admin123');
      expect(result, isNull);
    });
  });

  // =========================================================================
  // GROUP 2: SALES BILLING END-TO-END WORKFLOW (ORDER -> INVOICE -> PAYMENTS)
  // =========================================================================
  group('Phase 9.2 - Complete Sales Billing End-to-End Workflow', () {
    test('2.1 Full Sales Billing Lifecycle: Order -> Items -> Invoice -> Multi-Payment -> Settlement', () async {
      final now = DateTime.now();
      final invoiceId = uuid.v4();
      final payment1Id = uuid.v4();
      const invoiceNumber = 'INV-D1-00050';

      final items = [
        InvoiceItemsCompanion.insert(
          id: uuid.v4(),
          invoiceId: invoiceId,
          productId: const drift.Value('prod-p-tikka'),
          productName: 'Paneer Tikka',
          productCode: const drift.Value('PT-01'),
          unit: 'portion',
          unitPricePaise: 25000,
          quantity: 2,
          discountPaise: const drift.Value(0),
          gstRatePercent: 5.0,
          isTaxInclusive: true,
          taxableAmountPaise: 47619,
          taxAmountPaise: 2381,
          totalAmountPaise: 50000,
        ),
        InvoiceItemsCompanion.insert(
          id: uuid.v4(),
          invoiceId: invoiceId,
          productId: const drift.Value('prod-naan'),
          productName: 'Butter Naan',
          productCode: const drift.Value('BN-01'),
          unit: 'piece',
          unitPricePaise: 5000,
          quantity: 4,
          discountPaise: const drift.Value(0),
          gstRatePercent: 5.0,
          isTaxInclusive: true,
          taxableAmountPaise: 19048,
          taxAmountPaise: 952,
          totalAmountPaise: 20000,
        ),
      ];

      final initialPayment = PaymentsCompanion.insert(
        id: payment1Id,
        invoiceId: invoiceId,
        amountPaise: 40000,
        paymentMethod: 'Cash',
        createdAt: now,
      );

      await invoiceRepo.createInvoice(
        CreateInvoiceParams(
          invoice: InvoicesCompanion.insert(
            id: invoiceId,
            invoiceNumber: invoiceNumber,
            createdAt: now,
            customerName: const drift.Value('Vikram Malhotra'),
            customerPhone: const drift.Value('9876543210'),
            orderType: const drift.Value('Dine In'),
            tableNumber: const drift.Value('T4'),
            subtotalPaise: 70000,
            itemDiscountTotalPaise: const drift.Value(0),
            billDiscountPaise: const drift.Value(0),
            taxableAmountPaise: 66667,
            cgstPaise: const drift.Value(1666),
            sgstPaise: const drift.Value(1667),
            grandTotalPaise: 70000,
            paidAmountPaise: 40000,
            paymentMethod: const drift.Value('Cash'),
            paymentStatus: const drift.Value(AppConstants.statusPartial),
            orderStatus: const drift.Value(AppConstants.orderCompleted),
            deviceId: const drift.Value('D1'),
          ),
          items: items,
          payment: initialPayment,
          billNote: 'Less butter on Naan',
        ),
      );

      final invoiceMid = await invoiceRepo.getInvoiceById(invoiceId);
      expect(invoiceMid, isNotNull);
      expect(invoiceMid!.grandTotalPaise, equals(70000));
      expect(invoiceMid.paidAmountPaise, equals(40000));
      expect(invoiceMid.paymentStatus, equals(AppConstants.statusPartial));
      expect(invoiceMid.grandTotalPaise - invoiceMid.paidAmountPaise, equals(30000));

      // Customer settles remaining ₹300.00 balance via UPI
      await invoiceRepo.recordAdditionalPayment(
        invoiceId: invoiceId,
        amountPaise: 30000,
        paymentMethod: 'UPI',
        referenceNumber: 'UPI-REF-992211',
        notes: 'Final settlement',
      );

      final invoiceFinal = await invoiceRepo.getInvoiceById(invoiceId);
      expect(invoiceFinal!.paidAmountPaise, equals(70000));
      expect(invoiceFinal.paymentStatus, equals(AppConstants.statusPaid));
      expect(invoiceFinal.grandTotalPaise - invoiceFinal.paidAmountPaise, equals(0));

      final payments = await (db.select(db.payments)..where((p) => p.invoiceId.equals(invoiceId))).get();
      expect(payments.length, equals(2));
      expect(payments.first.amountPaise, equals(40000));
      expect(payments.first.paymentMethod, equals('Cash'));
      expect(payments.last.amountPaise, equals(30000));
      expect(payments.last.paymentMethod, equals('UPI'));
      expect(payments.last.referenceNumber, equals('UPI-REF-992211'));
    });

    test('2.2 Historical invoice snapshots remain immutable when catalog product prices change', () async {
      final now = DateTime.now();
      final catId = uuid.v4();
      final prodId = uuid.v4();

      await db.into(db.categories).insert(
        CategoriesCompanion.insert(id: catId, name: 'Beverages', createdAt: now),
      );
      await db.into(db.products).insert(
        ProductsCompanion.insert(
          id: prodId,
          categoryId: drift.Value(catId),
          name: 'Mango Lassi',
          costPricePaise: const drift.Value(5000),
          sellingPricePaise: 15000,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final invId = uuid.v4();
      await invoiceRepo.createInvoice(
        CreateInvoiceParams(
          invoice: InvoicesCompanion.insert(
            id: invId,
            invoiceNumber: 'INV-D1-00051',
            createdAt: now,
            subtotalPaise: 30000,
            taxableAmountPaise: 28571,
            grandTotalPaise: 30000,
            paidAmountPaise: 30000,
          ),
          items: [
            InvoiceItemsCompanion.insert(
              id: uuid.v4(),
              invoiceId: invId,
              productId: drift.Value(prodId),
              productName: 'Mango Lassi',
              unit: 'glass',
              unitPricePaise: 15000,
              quantity: 2,
              taxableAmountPaise: 28571,
              gstRatePercent: 5.0,
              isTaxInclusive: true,
              taxAmountPaise: 1429,
              totalAmountPaise: 30000,
            ),
          ],
        ),
      );

      // Inflate catalog price to ₹220.00
      await (db.update(db.products)..where((p) => p.id.equals(prodId))).write(
        const ProductsCompanion(
          sellingPricePaise: drift.Value(22000),
          name: drift.Value('Mango Lassi Special'),
        ),
      );

      // Verify historical invoice snapshot remains 100% intact
      final historicalDetails = await invoiceRepo.getInvoiceWithDetails(invId);
      expect(historicalDetails, isNotNull);
      expect(historicalDetails!.invoice.grandTotalPaise, equals(30000));
      expect(historicalDetails.items.first.unitPricePaise, equals(15000));
      expect(historicalDetails.items.first.totalAmountPaise, equals(30000));
      expect(historicalDetails.items.first.productName, equals('Mango Lassi'));
    });
  });

  // =========================================================================
  // GROUP 3: PROCUREMENT END-TO-END WORKFLOW (PO -> PI -> APPROVAL -> PAYMENT)
  // =========================================================================
  group('Phase 9.3 - Complete Procurement End-to-End Workflow', () {
    test('3.1 Full Procurement Lifecycle: PO -> PI Submission -> Admin Approval -> Supplier Payment', () async {
      final supplierId = await supplierRepo.createSupplier(
        name: 'Apex Poultry & Dairy',
        phone: '9845011223',
        address: 'Whitefield Industrial Area',
        gstin: '29AAAAA0000A1Z5',
      );

      final poId = await purchaseRepo.createPurchaseOrder(
        supplierId: supplierId,
        notes: 'Cold chain delivery required',
        items: [
          {
            'productName': 'Fresh Paneer Block',
            'unit': 'kg',
            'quantity': 50,
            'unitPricePaise': 35000,
            'gstRatePercent': 0.0,
          },
        ],
      );

      final po = await purchaseRepo.getPurchaseOrderById(poId);
      expect(po, isNotNull);
      expect(po!.orderStatus, equals('DRAFT'));
      expect(po.grandTotalPaise, equals(1750000));

      final piId = await purchaseRepo.submitSupplierInvoice(
        supplierId: supplierId,
        purchaseOrderId: poId,
        invoiceNumber: 'INV-APEX-8821',
        items: [
          {
            'productName': 'Fresh Paneer Block',
            'unit': 'kg',
            'quantity': 50,
            'unitPricePaise': 35000,
            'gstRatePercent': 0.0,
          },
        ],
      );

      final piInitial = await purchaseRepo.getPurchaseInvoiceById(piId);
      expect(piInitial, isNotNull);
      expect(piInitial!.verificationStatus, equals('PENDING_VERIFICATION'));
      expect(piInitial.paymentStatus, equals('PENDING'));
      expect(piInitial.grandTotalPaise, equals(1750000));
      expect(piInitial.balanceDuePaise, equals(1750000));

      // Admin verifies goods upon delivery and approves invoice
      await purchaseRepo.approvePurchaseInvoice(piId);

      final piApproved = await purchaseRepo.getPurchaseInvoiceById(piId);
      expect(piApproved!.verificationStatus, equals('APPROVED'));

      // Admin records partial payment of ₹10,000.00 (1000000 paise)
      await purchaseRepo.recordSupplierPayment(
        supplierId: supplierId,
        purchaseInvoiceId: piId,
        amountPaise: 1000000,
        paymentMethod: 'Bank Transfer',
        referenceNumber: 'NEFT-HDFC-009911',
      );

      final piPartial = await purchaseRepo.getPurchaseInvoiceById(piId);
      expect(piPartial!.paymentStatus, equals('PARTIALLY_PAID'));
      expect(piPartial.amountPaidPaise, equals(1000000));
      expect(piPartial.balanceDuePaise, equals(750000));

      // Admin records final settlement payment of ₹7,500.00 (750000 paise)
      await purchaseRepo.recordSupplierPayment(
        supplierId: supplierId,
        purchaseInvoiceId: piId,
        amountPaise: 750000,
        paymentMethod: 'Bank Transfer',
        referenceNumber: 'NEFT-HDFC-009922',
      );

      final piFullyPaid = await purchaseRepo.getPurchaseInvoiceById(piId);
      expect(piFullyPaid!.paymentStatus, equals('PAID'));
      expect(piFullyPaid.amountPaidPaise, equals(1750000));
      expect(piFullyPaid.balanceDuePaise, equals(0));

      final supPayments = await (db.select(db.supplierPayments)..where((p) => p.supplierId.equals(supplierId))).get();
      expect(supPayments.length, equals(2));
      expect(supPayments.first.amountPaise, equals(1000000));
      expect(supPayments.last.amountPaise, equals(750000));
    });

    test('3.2 Rejection workflow: Admin can reject non-compliant supplier invoices', () async {
      final supplierId = await supplierRepo.createSupplier(
        name: 'Organic Veggies Ltd',
        phone: '9845099887',
      );

      final piId = await purchaseRepo.submitSupplierInvoice(
        supplierId: supplierId,
        invoiceNumber: 'INV-ORG-001',
        items: [
          {
            'productName': 'Spoiled Tomatoes',
            'unit': 'crate',
            'quantity': 10,
            'unitPricePaise': 100000,
            'gstRatePercent': 0.0,
          },
        ],
      );

      await purchaseRepo.rejectPurchaseInvoice(piId, 'Damaged and rotten during transport');

      final pi = await purchaseRepo.getPurchaseInvoiceById(piId);
      expect(pi!.verificationStatus, equals('REJECTED'));
      expect(pi.paymentStatus, equals('PENDING'));
    });
  });

  // =========================================================================
  // GROUP 4: STRICT FINANCIAL STREAM SEPARATION & LEDGER INTEGRITY
  // =========================================================================
  group('Phase 9.4 - Dual Financial Stream Isolation & Ledger Integrity', () {
    test('4.1 Customer sales payments and supplier disbursements remain strictly partitioned', () async {
      final now = DateTime.now();

      final salesInvId = uuid.v4();
      final salesPayId = uuid.v4();
      await db.into(db.invoices).insert(
        InvoicesCompanion.insert(
          id: salesInvId,
          invoiceNumber: 'INV-D1-00099',
          createdAt: now,
          subtotalPaise: 50000,
          taxableAmountPaise: 50000,
          grandTotalPaise: 50000,
          paidAmountPaise: 50000,
        ),
      );
      await db.into(db.payments).insert(
        PaymentsCompanion.insert(
          id: salesPayId,
          invoiceId: salesInvId,
          amountPaise: 50000,
          paymentMethod: 'UPI',
          createdAt: now,
        ),
      );

      final supId = await supplierRepo.createSupplier(name: 'Fresh Dairy', phone: '9988776655');
      final piId = await purchaseRepo.submitSupplierInvoice(
        supplierId: supId,
        invoiceNumber: 'PI-FD-01',
        items: [
          {
            'productName': 'Milk Cans',
            'unit': 'can',
            'quantity': 8,
            'unitPricePaise': 100000,
            'gstRatePercent': 0.0,
          },
        ],
      );
      await purchaseRepo.approvePurchaseInvoice(piId);
      await purchaseRepo.recordSupplierPayment(
        supplierId: supId,
        purchaseInvoiceId: piId,
        amountPaise: 800000,
        paymentMethod: 'Bank Transfer',
        referenceNumber: 'UTR-991122',
      );

      final customerPayments = await db.select(db.payments).get();
      expect(customerPayments.length, equals(1));
      expect(customerPayments.first.id, equals(salesPayId));
      expect(customerPayments.first.invoiceId, equals(salesInvId));
      expect(customerPayments.first.amountPaise, equals(50000));

      final supplierPayments = await db.select(db.supplierPayments).get();
      expect(supplierPayments.length, equals(1));
      expect(supplierPayments.first.supplierId, equals(supId));
      expect(supplierPayments.first.purchaseInvoiceId, equals(piId));
      expect(supplierPayments.first.amountPaise, equals(800000));

      expect(customerPayments.any((p) => p.invoiceId == piId), isFalse);
      expect(supplierPayments.any((sp) => sp.purchaseInvoiceId == salesInvId), isFalse);
    });
  });

  // =========================================================================
  // GROUP 5: MULTI-DEVICE COLLISION-RESISTANT INVOICE NUMBERING
  // =========================================================================
  group('Phase 9.5 - Multi-Device Collision-Resistant Invoice Numbering', () {
    test('5.1 Two offline terminals generate completely distinct, collision-free invoice sequences', () async {
      final pos1Inv1 = await invoiceRepo.generateNextInvoiceNumber(prefix: 'INV-', deviceCode: 'POS1');
      expect(pos1Inv1, equals('INV-POS1-00001'));

      final now = DateTime.now();
      await db.into(db.invoices).insert(
        InvoicesCompanion.insert(
          id: uuid.v4(),
          invoiceNumber: pos1Inv1,
          createdAt: now,
          subtotalPaise: 10000,
          taxableAmountPaise: 10000,
          grandTotalPaise: 10000,
          paidAmountPaise: 10000,
          deviceId: const drift.Value('dev-pos-1'),
        ),
      );

      final pos1Inv2 = await invoiceRepo.generateNextInvoiceNumber(prefix: 'INV-', deviceCode: 'POS1');
      expect(pos1Inv2, equals('INV-POS1-00002'));

      final pos2Inv1 = await invoiceRepo.generateNextInvoiceNumber(prefix: 'INV-', deviceCode: 'POS2');
      expect(pos2Inv1, equals('INV-POS2-00001'));

      await db.into(db.invoices).insert(
        InvoicesCompanion.insert(
          id: uuid.v4(),
          invoiceNumber: pos2Inv1,
          createdAt: now,
          subtotalPaise: 20000,
          taxableAmountPaise: 20000,
          grandTotalPaise: 20000,
          paidAmountPaise: 20000,
          deviceId: const drift.Value('dev-pos-2'),
        ),
      );

      final pos2Inv2 = await invoiceRepo.generateNextInvoiceNumber(prefix: 'INV-', deviceCode: 'POS2');
      expect(pos2Inv2, equals('INV-POS2-00002'));

      expect(pos1Inv1, isNot(equals(pos2Inv1)));
      expect(pos1Inv2, isNot(equals(pos2Inv2)));
    });

    test('5.2 Database uniquely enforces invoice number constraint against duplicate writes', () async {
      final now = DateTime.now();
      const uniqueNum = 'INV-D1-00099';

      await db.into(db.invoices).insert(
        InvoicesCompanion.insert(
          id: uuid.v4(),
          invoiceNumber: uniqueNum,
          createdAt: now,
          subtotalPaise: 1000,
          taxableAmountPaise: 1000,
          grandTotalPaise: 1000,
          paidAmountPaise: 1000,
        ),
      );

      expect(
        () async => await db.into(db.invoices).insert(
          InvoicesCompanion.insert(
            id: uuid.v4(),
            invoiceNumber: uniqueNum,
            createdAt: now,
            subtotalPaise: 2000,
            taxableAmountPaise: 2000,
            grandTotalPaise: 2000,
            paidAmountPaise: 2000,
          ),
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  // =========================================================================
  // GROUP 6: OFFLINE SYNC QUEUE DEPENDENCY & IDEMPOTENCY
  // =========================================================================
  group('Phase 9.6 - Offline Synchronization & Queue Idempotency', () {
    test('6.1 Dependency rank hierarchy preserves relational integrity', () {
      final rankCat = SyncService.getEntityDependencyRank('categories');
      final rankSup = SyncService.getEntityDependencyRank('suppliers');
      final rankProd = SyncService.getEntityDependencyRank('products');
      final rankCust = SyncService.getEntityDependencyRank('customers');
      final rankOrd = SyncService.getEntityDependencyRank('orders');
      final rankPO = SyncService.getEntityDependencyRank('purchase_orders');
      final rankInv = SyncService.getEntityDependencyRank('invoices');
      final rankPI = SyncService.getEntityDependencyRank('purchase_invoices');
      final rankPay = SyncService.getEntityDependencyRank('payments');
      final rankSpay = SyncService.getEntityDependencyRank('supplier_payments');

      expect(rankCat, lessThan(rankProd));
      expect(rankSup, lessThan(rankProd));
      expect(rankProd, lessThan(rankOrd));
      expect(rankOrd, lessThan(rankInv));
      expect(rankCust, lessThan(rankInv));
      expect(rankInv, lessThan(rankPay));
      expect(rankPO, lessThan(rankSpay));
      expect(rankPI, lessThan(rankSpay));
    });

    test('6.2 Sync queue enqueues complete atomic snapshot payloads', () async {
      final invId = uuid.v4();
      final payId = uuid.v4();
      final now = DateTime.now();

      await invoiceRepo.createInvoice(
        CreateInvoiceParams(
          invoice: InvoicesCompanion.insert(
            id: invId,
            invoiceNumber: 'INV-D1-00150',
            createdAt: now,
            subtotalPaise: 45000,
            taxableAmountPaise: 45000,
            grandTotalPaise: 45000,
            paidAmountPaise: 45000,
          ),
          items: [
            InvoiceItemsCompanion.insert(
              id: uuid.v4(),
              invoiceId: invId,
              productName: 'Chicken Biryani',
              unit: 'portion',
              unitPricePaise: 45000,
              quantity: 1,
              taxableAmountPaise: 42857,
              gstRatePercent: 5.0,
              isTaxInclusive: true,
              taxAmountPaise: 2143,
              totalAmountPaise: 45000,
            ),
          ],
          payment: PaymentsCompanion.insert(
            id: payId,
            invoiceId: invId,
            amountPaise: 45000,
            paymentMethod: 'Card',
            createdAt: now,
          ),
        ),
      );

      final queue = await db.select(db.syncQueue).get();
      expect(queue.length, greaterThanOrEqualTo(2));

      final invQueue = queue.firstWhere((q) => q.syncEntity == 'invoices' && q.recordId == invId);
      final invPayload = jsonDecode(invQueue.payloadJson);
      expect(invPayload['invoiceNumber'], equals('INV-D1-00150'));
      expect(invPayload['items'], isNotEmpty);
      expect(invPayload['items'][0]['productName'], equals('Chicken Biryani'));

      final payQueue = queue.firstWhere((q) => q.syncEntity == 'payments' && q.recordId == payId);
      final payPayload = jsonDecode(payQueue.payloadJson);
      expect(payPayload['amountPaise'], equals(45000));
      expect(payPayload['paymentMethod'], equals('Card'));
    });
  });

  // =========================================================================
  // GROUP 7: ESC/POS THERMAL PRINTING & KOT NON-FINANCIAL GUARANTEE
  // =========================================================================
  group('Phase 9.7 - ESC/POS Thermal Printing & KOT Verification', () {
    test('7.1 Thermal receipt bytes generate valid ESC/POS commands for 58mm and 80mm', () async {
      final now = DateTime.now();
      final invoice = InvoiceEntry(
        id: 'inv-pr-1',
        invoiceNumber: 'INV-D1-00200',
        createdAt: now,
        customerName: 'Suresh Raina',
        customerPhone: '9845011111',
        orderType: 'Dine In',
        tableNumber: 'Table 9',
        subtotalPaise: 25000,
        itemDiscountTotalPaise: 0,
        billDiscountPaise: 0,
        taxableAmountPaise: 23810,
        cgstPaise: 595,
        sgstPaise: 595,
        igstPaise: 0,
        roundOffPaise: 0,
        grandTotalPaise: 25000,
        paidAmountPaise: 25000,
        paymentMethod: 'UPI',
        paymentStatus: AppConstants.statusPaid,
        orderStatus: AppConstants.orderCompleted,
        deviceId: 'D1',
        cashierName: 'Admin Cashier',
        syncStatus: 'synced',
        isCancelled: false,
      );

      final items = [
        InvoiceItemEntry(
          id: 'item-pr-1',
          invoiceId: 'inv-pr-1',
          productName: 'Cold Coffee',
          unit: 'glass',
          unitPricePaise: 25000,
          quantity: 1,
          discountPaise: 0,
          gstRatePercent: 5.0,
          isTaxInclusive: true,
          taxableAmountPaise: 23810,
          taxAmountPaise: 1190,
          totalAmountPaise: 25000,
        ),
      ];

      final details = InvoiceDetails(
        invoice: invoice,
        items: items,
        billNote: null,
        payments: [],
      );

      final settings = {
        'business_name': 'Cafe Royale',
        'business_gstin': '29ABCDE1234F1Z5',
      };

      final bytes80 = await ThermalEscPosGenerator.generateBytes(
        details: details,
        settings: settings,
        paperSize: PaperSize.mm80,
      );
      expect(bytes80, isNotEmpty);
      expect(bytes80.length, greaterThan(30));

      final bytes58 = await ThermalEscPosGenerator.generateBytes(
        details: details,
        settings: settings,
        paperSize: PaperSize.mm58,
      );
      expect(bytes58, isNotEmpty);
      expect(bytes58.length, greaterThan(30));
    });

    test('7.2 KOT strictly excludes prices, currency symbols, and taxes', () async {
      final now = DateTime.now();
      final invoice = InvoiceEntry(
        id: 'inv-kot-test',
        invoiceNumber: 'ORD-D1-00077',
        createdAt: now,
        customerName: 'VIP Table 3',
        orderType: 'Dine In',
        tableNumber: 'Table 3',
        subtotalPaise: 60000,
        itemDiscountTotalPaise: 0,
        billDiscountPaise: 0,
        taxableAmountPaise: 57143,
        cgstPaise: 1428,
        sgstPaise: 1429,
        igstPaise: 0,
        roundOffPaise: 0,
        grandTotalPaise: 60000,
        paidAmountPaise: 0,
        paymentMethod: 'Pending',
        paymentStatus: AppConstants.statusPending,
        orderStatus: AppConstants.orderPending,
        deviceId: 'D1',
        cashierName: 'Admin Cashier',
        kotNumber: 'KOT-00077',
        syncStatus: 'synced',
        isCancelled: false,
      );

      final items = [
        InvoiceItemEntry(
          id: 'k-item-1',
          invoiceId: 'inv-kot-test',
          productName: 'Dum Biryani',
          unit: 'pot',
          unitPricePaise: 60000,
          quantity: 1,
          discountPaise: 0,
          gstRatePercent: 5.0,
          isTaxInclusive: true,
          taxableAmountPaise: 57143,
          taxAmountPaise: 2857,
          totalAmountPaise: 60000,
        ),
      ];

      final details = InvoiceDetails(
        invoice: invoice,
        items: items,
        billNote: BillNoteEntry(
          id: 'bn-1',
          invoiceId: 'inv-kot-test',
          note: 'Spicy, extra raita',
          isCustomerFacing: true,
          createdAt: now,
          updatedAt: now,
        ),
        payments: [],
      );

      final kotBytes = await ThermalEscPosGenerator.generateKotBytes(
        details: details,
        settings: {'business_name': 'Biryani Palace'},
        paperSize: PaperSize.mm80,
      );

      final kotText = String.fromCharCodes(kotBytes);

      expect(kotText, contains('KITCHEN ORDER TICKET'));
      expect(kotText, contains('Dum Biryani'));
      expect(kotText, contains('Spicy, extra raita'));
      expect(kotText, contains('Table 3'));

      expect(kotText, isNot(contains('₹')));
      expect(kotText, isNot(contains('Rs')));
      expect(kotText, isNot(contains('CGST')));
      expect(kotText, isNot(contains('SGST')));
      expect(kotText, isNot(contains('Grand Total')));
    });
  });

  // =========================================================================
  // GROUP 8: COMPREHENSIVE PDF GENERATION SUITE
  // =========================================================================
  group('Phase 9.8 - Complete PDF Document Suite Verification', () {
    final now = DateTime.now();

    final testInvoice = InvoiceEntry(
      id: 'inv-pdf-doc',
      invoiceNumber: 'INV-D1-00999',
      createdAt: now,
      customerName: 'Priya Sundaram',
      customerPhone: '9988771122',
      orderType: 'Dine In',
      tableNumber: 'Table 1',
      subtotalPaise: 35000,
      itemDiscountTotalPaise: 0,
      billDiscountPaise: 0,
      taxableAmountPaise: 33333,
      cgstPaise: 833,
      sgstPaise: 834,
      igstPaise: 0,
      roundOffPaise: 0,
      grandTotalPaise: 35000,
      paymentMethod: 'UPI',
      paymentStatus: AppConstants.statusPaid,
      paidAmountPaise: 35000,
      orderStatus: AppConstants.orderCompleted,
      deviceId: 'D1',
      cashierName: 'Admin Cashier',
      syncStatus: 'synced',
      isCancelled: false,
    );

    final testItems = [
      InvoiceItemEntry(
        id: 'item-pdf-doc',
        invoiceId: 'inv-pdf-doc',
        productName: 'Special South Indian Thali',
        unit: 'meal',
        unitPricePaise: 35000,
        quantity: 1,
        discountPaise: 0,
        gstRatePercent: 5.0,
        isTaxInclusive: true,
        taxableAmountPaise: 33333,
        taxAmountPaise: 1667,
        totalAmountPaise: 35000,
      ),
    ];

    final testPayment = PaymentEntry(
      id: 'pay-pdf-doc',
      invoiceId: 'inv-pdf-doc',
      amountPaise: 35000,
      paymentMethod: 'UPI',
      referenceNumber: 'UPI-REF-554433',
      createdAt: now,
    );

    final testDetails = InvoiceDetails(
      invoice: testInvoice,
      items: testItems,
      billNote: null,
      payments: [testPayment],
    );

    final testSettings = {
      'business_name': 'Royal Cuisine Restaurant',
      'business_address': 'Indiranagar 100ft Road, Bengaluru',
      'business_gst': '29AAAAA0000A1Z5',
      'business_phone': '080-25253535',
    };

    final testSupplier = SupplierEntry(
      id: 'sup-grain-1',
      businessId: 'biz-1',
      name: 'Southern Grain Wholesalers',
      phone: '9845000111',
      address: 'APMC Yard, Yeshwanthpur, Bengaluru',
      gstin: '29CCCCC2222C1Z3',
      isActive: true,
      isVerified: true,
      createdAt: now,
      updatedAt: now,
    );

    test('8.1 Sales tax invoice PDF produces valid %PDF document', () async {
      final bytes = await InvoicePdfGenerator.generate(details: testDetails, settings: testSettings);
      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(5)), equals('%PDF-'));
    });

    test('8.2 Kitchen Order Ticket PDF produces valid %PDF document', () async {
      final bytes = await InvoicePdfGenerator.generateKot(details: testDetails, settings: testSettings);
      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(5)), equals('%PDF-'));
    });

    test('8.3 Purchase Order PDF produces valid supplier document', () async {
      final po = PurchaseOrderEntry(
        id: 'po-test-1',
        businessId: 'biz-1',
        supplierId: 'sup-grain-1',
        poNumber: 'PO-2026-009',
        orderStatus: 'CONFIRMED',
        subtotalPaise: 5000000,
        discountPaise: 0,
        taxPaise: 238095,
        grandTotalPaise: 5000000,
        notes: 'Delivery by Monday 8 AM',
        orderedAt: now,
        expectedDeliveryDate: now.add(const Duration(days: 2)),
        createdAt: now,
        updatedAt: now,
      );

      final poItems = <PurchaseOrderItemEntry>[
        PurchaseOrderItemEntry(
          id: 'poi-test-1',
          purchaseOrderId: 'po-test-1',
          productName: 'Sona Masoori Rice (50kg Bag)',
          unit: 'bag',
          quantity: 20,
          receivedQuantity: 0.0,
          unitPricePaise: 250000,
          gstRatePercent: 5.0,
          taxableAmountPaise: 4761905,
          taxAmountPaise: 238095,
          totalAmountPaise: 5000000,
          createdAt: now,
        ),
      ];

      final bytes = await ProcurementPdfGenerator.generatePurchaseOrderPdf(
        order: po,
        items: poItems,
        supplier: testSupplier,
        settings: testSettings,
      );
      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(5)), equals('%PDF-'));
    });

    test('8.4 Purchase Invoice PDF produces valid procurement invoice', () async {
      final pi = PurchaseInvoiceEntry(
        id: 'pi-test-1',
        businessId: 'biz-1',
        supplierId: 'sup-grain-1',
        invoiceNumber: 'INV-SGW-9912',
        verificationStatus: 'VERIFIED',
        paymentStatus: 'PAID',
        subtotalPaise: 2500000,
        discountPaise: 0,
        taxPaise: 119048,
        grandTotalPaise: 2500000,
        amountPaidPaise: 2500000,
        balanceDuePaise: 0,
        invoiceDate: now,
        createdAt: now,
        updatedAt: now,
      );

      final piItems = <PurchaseInvoiceItemEntry>[
        PurchaseInvoiceItemEntry(
          id: 'pii-test-1',
          purchaseInvoiceId: 'pi-test-1',
          productName: 'Toor Dal Premium (25kg Bag)',
          unit: 'bag',
          quantity: 10,
          unitPricePaise: 250000,
          gstRatePercent: 5.0,
          taxableAmountPaise: 2380952,
          taxAmountPaise: 119048,
          totalAmountPaise: 2500000,
          createdAt: now,
        ),
      ];

      final bytes = await ProcurementPdfGenerator.generatePurchaseInvoicePdf(
        invoice: pi,
        items: piItems,
        supplier: testSupplier,
        settings: testSettings,
      );
      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(5)), equals('%PDF-'));
    });

    test('8.5 Supplier Payment Voucher PDF produces valid settlement receipt', () async {
      final pi = PurchaseInvoiceEntry(
        id: 'pi-test-1',
        businessId: 'biz-1',
        supplierId: 'sup-grain-1',
        invoiceNumber: 'INV-SGW-9912',
        verificationStatus: 'VERIFIED',
        paymentStatus: 'PAID',
        subtotalPaise: 2500000,
        discountPaise: 0,
        taxPaise: 119048,
        grandTotalPaise: 2500000,
        amountPaidPaise: 2500000,
        balanceDuePaise: 0,
        invoiceDate: now,
        createdAt: now,
        updatedAt: now,
      );

      final payment = SupplierPaymentEntry(
        id: 'sp-test-1',
        businessId: 'biz-1',
        supplierId: 'sup-grain-1',
        purchaseInvoiceId: 'pi-test-1',
        paymentVoucherNumber: 'SPV-2026-00088',
        amountPaise: 2500000,
        paymentMethod: 'Bank Transfer',
        referenceNumber: 'UTR-SBIN-88990011',
        paymentDate: now,
        notes: 'Full payment for Toor Dal supply',
        createdAt: now,
      );

      final bytes = await ProcurementPdfGenerator.generateSupplierPaymentVoucherPdf(
        payment: payment,
        supplier: testSupplier,
        invoice: pi,
        settings: testSettings,
      );
      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(5)), equals('%PDF-'));
    });

    test('8.6 Supplier Account Statement PDF produces structured ledger document', () async {
      final ledgerEntries = [
        {
          'date': DateTime(2026, 10, 1),
          'reference': 'INV-SGW-9912',
          'description': 'Purchase Invoice - Grain Supplies',
          'debit_paise': 2500000,
          'credit_paise': 0,
          'running_balance_paise': 2500000,
        },
        {
          'date': DateTime(2026, 10, 10),
          'reference': 'SPV-2026-00088',
          'description': 'Bank Transfer (UTR-SBIN-88990011)',
          'debit_paise': 0,
          'credit_paise': 2500000,
          'running_balance_paise': 0,
        },
      ];

      final bytes = await ProcurementPdfGenerator.generateSupplierAccountStatementPdf(
        supplier: testSupplier,
        ledgerEntries: ledgerEntries,
        totalInvoicedPaise: 2500000,
        totalPaidPaise: 2500000,
        balanceDuePaise: 0,
        settings: testSettings,
        fromDate: DateTime(2026, 10, 1),
        toDate: DateTime(2026, 11, 7),
      );
      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(5)), equals('%PDF-'));
    });

    test('8.7 Customer Payment Receipt PDF produces valid customer sales receipt', () async {
      final bytes = await ProcurementPdfGenerator.generateCustomerPaymentReceiptPdf(
        invoice: testInvoice,
        payment: testPayment,
        settings: testSettings,
      );
      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(5)), equals('%PDF-'));
    });
  });
}
