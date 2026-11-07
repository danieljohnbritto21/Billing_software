import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodbillpro/core/api/api_client.dart';
import 'package:foodbillpro/core/api/device_service.dart';
import 'package:foodbillpro/core/constants/app_constants.dart';
import 'package:foodbillpro/core/database/app_database.dart';
import 'package:foodbillpro/core/sync/sync_service.dart';
import 'package:foodbillpro/features/invoices/invoice_repository.dart';
import 'package:foodbillpro/features/printer/invoice_pdf_generator.dart';
import 'package:foodbillpro/features/printer/procurement_pdf_generator.dart';
import 'package:foodbillpro/features/printer/thermal_esc_pos_generator.dart';
import 'package:foodbillpro/features/purchases/purchase_repository.dart';
import 'package:foodbillpro/features/suppliers/supplier_repository.dart';
import 'package:uuid/uuid.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late SyncService syncService;
  late InvoiceRepository invoiceRepo;
  late SupplierRepository supplierRepo;
  late PurchaseRepository purchaseRepo;
  const uuid = Uuid();

  setUp(() {
    drift.driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
    final api = ApiClient(db);
    final devService = DeviceService(db, api);
    syncService = SyncService(db, api, devService);
    invoiceRepo = InvoiceRepository(db, syncService);
    supplierRepo = SupplierRepository(db);
    purchaseRepo = PurchaseRepository(db);
  });

  tearDown(() async {
    syncService.dispose();
    await db.close();
  });

  group('Phase 8.1 - Multi-Device Collision-Resistant Invoice & Order Numbering', () {
    test('Device-specific invoice numbering generates distinct, collision-free sequences', () async {
      // Simulate Device 1 (Code: D1)
      final d1Inv1 = await invoiceRepo.generateNextInvoiceNumber(prefix: 'INV-', deviceCode: 'D1');
      expect(d1Inv1, equals('INV-D1-00001'));

      // Insert invoice for D1 so DB has it recorded
      final now = DateTime.now();
      await invoiceRepo.createInvoice(
        CreateInvoiceParams(
          invoice: InvoicesCompanion.insert(
            id: uuid.v4(),
            invoiceNumber: d1Inv1,
            createdAt: now,
            subtotalPaise: 10000,
            taxableAmountPaise: 10000,
            grandTotalPaise: 10000,
            paidAmountPaise: 10000,
            deviceId: const drift.Value('device-uuid-1'),
          ),
          items: [],
        ),
      );

      final d1Inv2 = await invoiceRepo.generateNextInvoiceNumber(prefix: 'INV-', deviceCode: 'D1');
      expect(d1Inv2, equals('INV-D1-00002'));

      // Simulate Device 2 (Code: D2) in the same database or multi-device environment
      final d2Inv1 = await invoiceRepo.generateNextInvoiceNumber(prefix: 'INV-', deviceCode: 'D2');
      expect(d2Inv1, equals('INV-D2-00001'));

      // Insert invoice for D2
      await invoiceRepo.createInvoice(
        CreateInvoiceParams(
          invoice: InvoicesCompanion.insert(
            id: uuid.v4(),
            invoiceNumber: d2Inv1,
            createdAt: now,
            subtotalPaise: 25000,
            taxableAmountPaise: 25000,
            grandTotalPaise: 25000,
            paidAmountPaise: 25000,
            deviceId: const drift.Value('device-uuid-2'),
          ),
          items: [],
        ),
      );

      final d2Inv2 = await invoiceRepo.generateNextInvoiceNumber(prefix: 'INV-', deviceCode: 'D2');
      expect(d2Inv2, equals('INV-D2-00002'));

      // Verify cross-device non-collision
      expect(d1Inv1, isNot(equals(d2Inv1)));
      expect(d1Inv2, isNot(equals(d2Inv2)));
    });

    test('Fallback invoice numbering without deviceCode produces standard sequence', () async {
      final inv1 = await invoiceRepo.generateNextInvoiceNumber(prefix: 'INV-');
      expect(inv1, equals('INV-000001'));

      await invoiceRepo.createInvoice(
        CreateInvoiceParams(
          invoice: InvoicesCompanion.insert(
            id: uuid.v4(),
            invoiceNumber: inv1,
            createdAt: DateTime.now(),
            subtotalPaise: 5000,
            taxableAmountPaise: 5000,
            grandTotalPaise: 5000,
            paidAmountPaise: 5000,
          ),
          items: [],
        ),
      );

      final inv2 = await invoiceRepo.generateNextInvoiceNumber(prefix: 'INV-');
      expect(inv2, equals('INV-000002'));
    });

    test('Order prefix supports device code formatting for pending/KOT orders', () async {
      final ord1 = await invoiceRepo.generateNextInvoiceNumber(prefix: 'ORD-', deviceCode: 'POS1');
      expect(ord1, equals('ORD-POS1-00001'));

      final ord2 = await invoiceRepo.generateNextInvoiceNumber(prefix: 'ORD-', deviceCode: 'POS2');
      expect(ord2, equals('ORD-POS2-00001'));
    });
  });

  group('Phase 8.2 - Offline Billing & Sync Queue Atomicity', () {
    test('Offline invoice creation atomically writes invoice, items, payment and sync queue', () async {
      final now = DateTime.now();
      final invoiceId = uuid.v4();
      final paymentId = uuid.v4();
      const invoiceNumber = 'INV-D1-00010';

      final items = [
        InvoiceItemsCompanion.insert(
          id: uuid.v4(),
          invoiceId: invoiceId,
          productId: const drift.Value('prod-1'),
          productName: 'Paneer Butter Masala',
          productCode: const drift.Value('PBM-01'),
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
      ];

      final payment = PaymentsCompanion.insert(
        id: paymentId,
        invoiceId: invoiceId,
        amountPaise: 50000,
        paymentMethod: 'UPI',
        createdAt: now,
        syncStatus: const drift.Value('pending'),
      );

      await invoiceRepo.createInvoice(
        CreateInvoiceParams(
          invoice: InvoicesCompanion.insert(
            id: invoiceId,
            invoiceNumber: invoiceNumber,
            createdAt: now,
            customerName: const drift.Value('Rohan Sharma'),
            customerPhone: const drift.Value('9876543210'),
            subtotalPaise: 50000,
            taxableAmountPaise: 47619,
            cgstPaise: const drift.Value(1190),
            sgstPaise: const drift.Value(1191),
            grandTotalPaise: 50000,
            paidAmountPaise: 50000,
            paymentMethod: const drift.Value('UPI'),
            paymentStatus: const drift.Value(AppConstants.statusPaid),
            orderStatus: const drift.Value(AppConstants.orderCompleted),
            deviceId: const drift.Value('dev-1'),
            syncStatus: const drift.Value('pending'),
          ),
          items: items,
          payment: payment,
          billNote: 'Extra spicy',
        ),
      );

      // Verify invoice stored locally with sync_status = pending
      final storedInvoice = await (db.select(db.invoices)..where((t) => t.id.equals(invoiceId))).getSingle();
      expect(storedInvoice.syncStatus, equals('pending'));
      expect(storedInvoice.invoiceNumber, equals(invoiceNumber));
      expect(storedInvoice.grandTotalPaise, equals(50000));
      expect(storedInvoice.deviceId, equals('dev-1'));

      // Verify line items stored locally
      final storedItems = await (db.select(db.invoiceItems)..where((t) => t.invoiceId.equals(invoiceId))).get();
      expect(storedItems.length, equals(1));
      expect(storedItems.first.productName, equals('Paneer Butter Masala'));
      expect(storedItems.first.totalAmountPaise, equals(50000));

      // Verify payment stored locally
      final storedPayment = await (db.select(db.payments)..where((t) => t.id.equals(paymentId))).getSingle();
      expect(storedPayment.syncStatus, equals('pending'));
      expect(storedPayment.amountPaise, equals(50000));
      expect(storedPayment.paymentMethod, equals('UPI'));

      // Verify sync queue entries created
      final queueItems = await db.select(db.syncQueue).get();
      expect(queueItems.length, greaterThanOrEqualTo(2));
      final invoiceQueueItem = queueItems.firstWhere((q) => q.syncEntity == 'invoices' && q.recordId == invoiceId);
      expect(invoiceQueueItem.operation, equals('INSERT'));
      expect(invoiceQueueItem.payloadJson, contains('Paneer Butter Masala'));
      expect(invoiceQueueItem.payloadJson, contains('items'));

      final paymentQueueItem = queueItems.firstWhere((q) => q.syncEntity == 'payments' && q.recordId == paymentId);
      expect(paymentQueueItem.operation, equals('INSERT'));
      expect(paymentQueueItem.payloadJson, contains('50000'));
    });

    test('Pending order save and subsequent completion atomically enqueues updates', () async {
      const invoiceNum = 'ORD-D1-00001';

      final items = [
        InvoiceItemsCompanion.insert(
          id: uuid.v4(),
          invoiceId: '',
          productId: const drift.Value('prod-dal'),
          productName: 'Dal Tadka',
          unit: 'portion',
          unitPricePaise: 18000,
          quantity: 1,
          taxableAmountPaise: 17143,
          gstRatePercent: 5.0,
          isTaxInclusive: true,
          taxAmountPaise: 857,
          totalAmountPaise: 18000,
        ),
      ];

      // 1. Save pending order (KOT stage)
      final invoiceId = await invoiceRepo.saveOrUpdatePendingOrder(
        invoiceNumber: invoiceNum,
        customerName: 'Table 5 Guest',
        customerPhone: null,
        orderType: 'Dine In',
        tableNumber: 'T5',
        deliveryAddress: null,
        subtotalPaise: 18000,
        itemDiscountTotalPaise: 0,
        billDiscountPaise: 0,
        taxableAmountPaise: 17143,
        cgstPaise: 428,
        sgstPaise: 429,
        roundOffPaise: 0,
        grandTotalPaise: 18000,
        cashierId: 'cashier-1',
        cashierName: 'Admin Cashier',
        deviceId: 'dev-1',
        items: items,
      );

      final pendingInvoice = await (db.select(db.invoices)..where((t) => t.id.equals(invoiceId))).getSingle();
      expect(pendingInvoice.orderStatus, equals(AppConstants.orderPending));
      expect(pendingInvoice.paymentStatus, equals(AppConstants.statusPending));
      expect(pendingInvoice.deviceId, equals('dev-1'));

      // Check sync queue has pending order
      final queue1 = await db.select(db.syncQueue).get();
      expect(queue1.any((q) => q.recordId == invoiceId && q.syncEntity == 'invoices'), isTrue);

      // 2. Complete order with cash payment
      await invoiceRepo.completeOrder(
        invoiceId: invoiceId,
        paidAmountPaise: 18000,
        paymentMethod: 'Cash',
      );

      final completedInvoice = await (db.select(db.invoices)..where((t) => t.id.equals(invoiceId))).getSingle();
      expect(completedInvoice.orderStatus, equals(AppConstants.orderCompleted));
      expect(completedInvoice.paymentStatus, equals(AppConstants.statusPaid));
      expect(completedInvoice.paidAmountPaise, equals(18000));

      // Check sync queue has payment and updated invoice
      final queue2 = await db.select(db.syncQueue).get();
      expect(queue2.any((q) => q.syncEntity == 'payments' && q.payloadJson.contains('18000')), isTrue);
    });
  });

  group('Phase 8.3 - Sync Queue Dependency Ordering & Idempotency', () {
    test('Entity dependency ranking guarantees relational hierarchy', () {
      final rankCategory = SyncService.getEntityDependencyRank('categories');
      final rankSupplier = SyncService.getEntityDependencyRank('suppliers');
      final rankProduct = SyncService.getEntityDependencyRank('products');
      final rankCustomer = SyncService.getEntityDependencyRank('customers');
      final rankOrder = SyncService.getEntityDependencyRank('orders');
      final rankPO = SyncService.getEntityDependencyRank('purchase_orders');
      final rankInvoice = SyncService.getEntityDependencyRank('invoices');
      final rankPI = SyncService.getEntityDependencyRank('purchase_invoices');
      final rankPayment = SyncService.getEntityDependencyRank('payments');
      final rankSupplierPayment = SyncService.getEntityDependencyRank('supplier_payments');

      // Master entities must have lower rank (pushed first)
      expect(rankCategory, lessThan(rankProduct));
      expect(rankSupplier, lessThan(rankProduct));
      expect(rankProduct, lessThan(rankInvoice));
      expect(rankCustomer, lessThan(rankInvoice));
      expect(rankOrder, lessThan(rankInvoice));

      // Invoices must precede payments
      expect(rankInvoice, lessThan(rankPayment));

      // Purchase orders and invoices must precede supplier payments
      expect(rankPO, lessThan(rankSupplierPayment));
      expect(rankPI, lessThan(rankSupplierPayment));
    });
  });

  group('Phase 8.4 - ESC/POS Thermal Printing (58mm, 80mm & KOT)', () {
    test('58mm and 80mm receipt byte generation produces valid ESC/POS byte sequence', () async {
      final now = DateTime.now();
      final invoice = InvoiceEntry(
        id: 'inv-test-1',
        invoiceNumber: 'INV-D1-00001',
        createdAt: now,
        customerName: 'Rajesh Kumar',
        customerPhone: '9876543210',
        orderType: 'Dine In',
        tableNumber: 'Table 4',
        subtotalPaise: 30000,
        itemDiscountTotalPaise: 0,
        billDiscountPaise: 0,
        taxableAmountPaise: 28571,
        cgstPaise: 714,
        sgstPaise: 715,
        igstPaise: 0,
        roundOffPaise: 0,
        grandTotalPaise: 30000,
        paidAmountPaise: 30000,
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
          id: 'item-1',
          invoiceId: 'inv-test-1',
          productName: 'Paneer Butter Masala',
          unit: 'portion',
          unitPricePaise: 25000,
          quantity: 1,
          discountPaise: 0,
          gstRatePercent: 5.0,
          isTaxInclusive: true,
          taxableAmountPaise: 23810,
          taxAmountPaise: 1190,
          totalAmountPaise: 25000,
        ),
        InvoiceItemEntry(
          id: 'item-2',
          invoiceId: 'inv-test-1',
          productName: 'Butter Naan',
          unit: 'piece',
          unitPricePaise: 5000,
          quantity: 1,
          discountPaise: 0,
          gstRatePercent: 5.0,
          isTaxInclusive: true,
          taxableAmountPaise: 4761,
          taxAmountPaise: 239,
          totalAmountPaise: 5000,
        ),
      ];

      final details = InvoiceDetails(
        invoice: invoice,
        items: items,
        billNote: null,
        payments: [],
      );

      final settings = {
        'business_name': 'Royal Spice Kitchen',
        'business_address': '123 MG Road, Bengaluru',
        'business_gstin': '29ABCDE1234F1Z5',
        'business_phone': '9876543210',
      };

      // Test 80mm
      final bytes80 = await ThermalEscPosGenerator.generateBytes(
        details: details,
        settings: settings,
        paperSize: PaperSize.mm80,
      );
      expect(bytes80, isNotEmpty);
      expect(bytes80.length, greaterThan(50));

      // Test 58mm
      final bytes58 = await ThermalEscPosGenerator.generateBytes(
        details: details,
        settings: settings,
        paperSize: PaperSize.mm58,
      );
      expect(bytes58, isNotEmpty);
      expect(bytes58.length, greaterThan(50));
    });

    test('KOT generation strictly EXCLUDES financial amounts and prices', () async {
      final now = DateTime.now();
      final invoice = InvoiceEntry(
        id: 'inv-kot-1',
        invoiceNumber: 'ORD-D1-00005',
        createdAt: now,
        customerName: 'VIP Guest',
        orderType: 'Dine In',
        tableNumber: 'Table 7',
        subtotalPaise: 50000,
        itemDiscountTotalPaise: 0,
        billDiscountPaise: 0,
        taxableAmountPaise: 47619,
        cgstPaise: 1190,
        sgstPaise: 1191,
        igstPaise: 0,
        roundOffPaise: 0,
        grandTotalPaise: 50000,
        paidAmountPaise: 0,
        paymentMethod: 'Pending',
        paymentStatus: AppConstants.statusPending,
        orderStatus: AppConstants.orderPending,
        deviceId: 'D1',
        cashierName: 'Admin Cashier',
        kotNumber: 'KOT-00005',
        syncStatus: 'synced',
        isCancelled: false,
      );

      final items = [
        InvoiceItemEntry(
          id: 'item-k1',
          invoiceId: 'inv-kot-1',
          productName: 'Masala Dosa',
          unit: 'piece',
          unitPricePaise: 15000,
          quantity: 2,
          discountPaise: 0,
          gstRatePercent: 5.0,
          isTaxInclusive: true,
          taxableAmountPaise: 28571,
          taxAmountPaise: 1429,
          totalAmountPaise: 30000,
        ),
      ];

      final details = InvoiceDetails(
        invoice: invoice,
        items: items,
        billNote: BillNoteEntry(
          id: 'note-1',
          invoiceId: 'inv-kot-1',
          note: 'Crispy, less oil, serve hot',
          isCustomerFacing: true,
          createdAt: now,
          updatedAt: now,
        ),
        payments: [],
      );

      final settings = {
        'business_name': 'Royal Spice Kitchen',
      };

      final kotBytes = await ThermalEscPosGenerator.generateKotBytes(
        details: details,
        settings: settings,
        paperSize: PaperSize.mm80,
      );

      expect(kotBytes, isNotEmpty);
      final textRepresentation = String.fromCharCodes(kotBytes);

      // Verify kitchen operational details are present
      expect(textRepresentation, contains('KITCHEN ORDER TICKET'));
      expect(textRepresentation, contains('Table 7'));
      expect(textRepresentation, contains('Masala Dosa'));
      expect(textRepresentation, contains('Crispy, less oil'));

      // STRICT RULE: Financial amounts, currency symbols, and prices MUST NOT exist on KOT
      expect(textRepresentation, isNot(contains('₹')));
      expect(textRepresentation, isNot(contains('Rs')));
      expect(textRepresentation, isNot(contains('CGST')));
      expect(textRepresentation, isNot(contains('SGST')));
      expect(textRepresentation, isNot(contains('Grand Total')));
    });
  });

  group('Phase 8.5 - Professional PDF Generation Suite', () {
    final now = DateTime.now();

    final testInvoice = InvoiceEntry(
      id: 'inv-pdf-1',
      invoiceNumber: 'INV-D1-00099',
      createdAt: now,
      customerName: 'Ananya Verma',
      customerPhone: '9123456789',
      orderType: 'Dine In',
      tableNumber: 'Table 3',
      subtotalPaise: 40000,
      itemDiscountTotalPaise: 0,
      billDiscountPaise: 0,
      taxableAmountPaise: 38095,
      cgstPaise: 952,
      sgstPaise: 953,
      igstPaise: 0,
      roundOffPaise: 0,
      grandTotalPaise: 40000,
      paymentMethod: 'UPI',
      paymentStatus: AppConstants.statusPaid,
      paidAmountPaise: 40000,
      orderStatus: AppConstants.orderCompleted,
      deviceId: 'D1',
      cashierName: 'Admin Cashier',
      syncStatus: 'synced',
      isCancelled: false,
    );

    final testItems = [
      InvoiceItemEntry(
        id: 'item-pdf-1',
        invoiceId: 'inv-pdf-1',
        productName: 'Veg Thali',
        unit: 'plate',
        unitPricePaise: 20000,
        quantity: 2,
        discountPaise: 0,
        gstRatePercent: 5.0,
        isTaxInclusive: true,
        taxableAmountPaise: 38095,
        taxAmountPaise: 1905,
        totalAmountPaise: 40000,
      ),
    ];

    final testPayment = PaymentEntry(
      id: 'pay-pdf-1',
      invoiceId: 'inv-pdf-1',
      amountPaise: 40000,
      paymentMethod: 'UPI',
      referenceNumber: 'UPI-REF-998811',
      createdAt: now,
    );

    final testDetails = InvoiceDetails(
      invoice: testInvoice,
      items: testItems,
      billNote: null,
      payments: [testPayment],
    );

    final testSettings = {
      'business_name': 'Royal Spice Kitchen',
      'business_address': 'Brigade Road, Bengaluru',
      'business_gst': '29AAAAA0000A1Z5',
      'business_phone': '080-22223333',
    };

    final testSupplier = SupplierEntry(
      id: 'sup-1',
      businessId: 'biz-1',
      name: 'Fresh Farms Dairy Ltd',
      phone: '9845012345',
      address: 'Electronic City, Bengaluru',
      gstin: '29BBBBB1111B1Z2',
      isActive: true,
      isVerified: true,
      createdAt: now,
      updatedAt: now,
    );

    test('Sales invoice PDF generation produces valid PDF bytes', () async {
      final pdfBytes = await InvoicePdfGenerator.generate(
        details: testDetails,
        settings: testSettings,
      );

      expect(pdfBytes, isNotEmpty);
      final header = String.fromCharCodes(pdfBytes.take(5));
      expect(header, equals('%PDF-'));
    });

    test('Kitchen Order Ticket (KOT) PDF generation produces valid PDF bytes', () async {
      final kotPdf = await InvoicePdfGenerator.generateKot(
        details: testDetails,
        settings: testSettings,
      );

      expect(kotPdf, isNotEmpty);
      final header = String.fromCharCodes(kotPdf.take(5));
      expect(header, equals('%PDF-'));
    });

    test('Purchase Order PDF generation produces valid supplier procurement document', () async {
      final po = PurchaseOrderEntry(
        id: 'po-1',
        businessId: 'biz-1',
        supplierId: 'sup-1',
        poNumber: 'PO-2026-001',
        orderStatus: 'CONFIRMED',
        subtotalPaise: 1200000,
        discountPaise: 0,
        taxPaise: 57143,
        grandTotalPaise: 1200000,
        notes: 'Delivery strictly before 7:00 AM',
        orderedAt: now,
        expectedDeliveryDate: now.add(const Duration(days: 3)),
        createdAt: now,
        updatedAt: now,
      );

      final poItems = <PurchaseOrderItemEntry>[
        PurchaseOrderItemEntry(
          id: 'poi-1',
          purchaseOrderId: 'po-1',
          productName: 'Full Cream Milk (50L Can)',
          unit: 'can',
          quantity: 4,
          receivedQuantity: 0.0,
          unitPricePaise: 300000,
          gstRatePercent: 5.0,
          taxableAmountPaise: 1142857,
          taxAmountPaise: 57143,
          totalAmountPaise: 1200000,
          createdAt: now,
        ),
      ];

      final poPdf = await ProcurementPdfGenerator.generatePurchaseOrderPdf(
        order: po,
        items: poItems,
        supplier: testSupplier,
        settings: testSettings,
      );

      expect(poPdf, isNotEmpty);
      final header = String.fromCharCodes(poPdf.take(5));
      expect(header, equals('%PDF-'));
    });

    test('Purchase Invoice PDF generation produces valid invoice record', () async {
      final pi = PurchaseInvoiceEntry(
        id: 'pi-1',
        businessId: 'biz-1',
        supplierId: 'sup-1',
        invoiceNumber: 'INV-FFD-9812',
        verificationStatus: 'VERIFIED',
        paymentStatus: 'PARTIAL',
        subtotalPaise: 700000,
        discountPaise: 0,
        taxPaise: 33333,
        grandTotalPaise: 700000,
        amountPaidPaise: 300000,
        balanceDuePaise: 400000,
        invoiceDate: now,
        createdAt: now,
        updatedAt: now,
      );

      final piItems = <PurchaseInvoiceItemEntry>[
        PurchaseInvoiceItemEntry(
          id: 'pii-1',
          purchaseInvoiceId: 'pi-1',
          productName: 'Paneer Bulk Pack',
          unit: 'kg',
          quantity: 20,
          unitPricePaise: 35000,
          gstRatePercent: 5.0,
          taxableAmountPaise: 666667,
          taxAmountPaise: 33333,
          totalAmountPaise: 700000,
          createdAt: now,
        ),
      ];

      final piPdf = await ProcurementPdfGenerator.generatePurchaseInvoicePdf(
        invoice: pi,
        items: piItems,
        supplier: testSupplier,
        settings: testSettings,
      );

      expect(piPdf, isNotEmpty);
      final header = String.fromCharCodes(piPdf.take(5));
      expect(header, equals('%PDF-'));
    });

    test('Supplier Payment Voucher PDF generation produces valid disbursement receipt', () async {
      final pi = PurchaseInvoiceEntry(
        id: 'pi-1',
        businessId: 'biz-1',
        supplierId: 'sup-1',
        invoiceNumber: 'INV-FFD-9812',
        verificationStatus: 'VERIFIED',
        paymentStatus: 'PAID',
        subtotalPaise: 450000,
        discountPaise: 0,
        taxPaise: 21428,
        grandTotalPaise: 450000,
        amountPaidPaise: 450000,
        balanceDuePaise: 0,
        invoiceDate: now,
        createdAt: now,
        updatedAt: now,
      );

      final payment = SupplierPaymentEntry(
        id: 'sp-1',
        businessId: 'biz-1',
        supplierId: 'sup-1',
        purchaseInvoiceId: 'pi-1',
        paymentVoucherNumber: 'SPV-2026-00015',
        amountPaise: 450000,
        paymentMethod: 'Bank Transfer',
        referenceNumber: 'UTR-HDFC-99128374',
        paymentDate: now,
        notes: 'Final settlement for October batch',
        createdAt: now,
      );

      final voucherPdf = await ProcurementPdfGenerator.generateSupplierPaymentVoucherPdf(
        payment: payment,
        supplier: testSupplier,
        invoice: pi,
        settings: testSettings,
      );

      expect(voucherPdf, isNotEmpty);
      final header = String.fromCharCodes(voucherPdf.take(5));
      expect(header, equals('%PDF-'));
    });

    test('Supplier Account Statement PDF generation produces comprehensive ledger statement', () async {
      final ledgerEntries = [
        {
          'date': DateTime(2026, 10, 5),
          'reference': 'PI-2026-0030',
          'description': 'Purchase Invoice - Dairy Supplies',
          'debit_paise': 800000,
          'credit_paise': 0,
          'running_balance_paise': 900000,
        },
        {
          'date': DateTime(2026, 10, 15),
          'reference': 'SPV-2026-0010',
          'description': 'Bank Transfer Settlement (HDFC-9921)',
          'debit_paise': 0,
          'credit_paise': 800000,
          'running_balance_paise': 100000,
        },
      ];

      final statementPdf = await ProcurementPdfGenerator.generateSupplierAccountStatementPdf(
        supplier: testSupplier,
        ledgerEntries: ledgerEntries,
        totalInvoicedPaise: 1500000,
        totalPaidPaise: 1200000,
        balanceDuePaise: 400000,
        settings: testSettings,
        fromDate: DateTime(2026, 10, 1),
        toDate: DateTime(2026, 11, 7),
      );

      expect(statementPdf, isNotEmpty);
      final header = String.fromCharCodes(statementPdf.take(5));
      expect(header, equals('%PDF-'));
    });

    test('Customer Payment Receipt PDF generation produces valid sales settlement receipt', () async {
      final receiptPdf = await ProcurementPdfGenerator.generateCustomerPaymentReceiptPdf(
        invoice: testInvoice,
        payment: testPayment,
        settings: testSettings,
      );

      expect(receiptPdf, isNotEmpty);
      final header = String.fromCharCodes(receiptPdf.take(5));
      expect(header, equals('%PDF-'));
    });
  });

  group('Phase 8.6 - Dual Financial Streams & Ledger Integrity', () {
    test('Sales payments and supplier payments remain in strictly isolated tables and streams', () async {
      final now = DateTime.now();

      // 1. Create a customer sales invoice
      final salesInvoiceId = uuid.v4();
      final salesPaymentId = uuid.v4();
      await invoiceRepo.createInvoice(
        CreateInvoiceParams(
          invoice: InvoicesCompanion.insert(
            id: salesInvoiceId,
            invoiceNumber: 'INV-D1-00100',
            createdAt: now,
            customerName: const drift.Value('Deepak Joshi'),
            subtotalPaise: 15000,
            taxableAmountPaise: 15000,
            grandTotalPaise: 15000,
            paidAmountPaise: 15000,
            paymentStatus: const drift.Value(AppConstants.statusPaid),
            orderStatus: const drift.Value(AppConstants.orderCompleted),
          ),
          items: [],
          payment: PaymentsCompanion.insert(
            id: salesPaymentId,
            invoiceId: salesInvoiceId,
            amountPaise: 15000,
            paymentMethod: 'Cash',
            createdAt: now,
          ),
        ),
      );

      // 2. Create a supplier and supplier purchase flow
      final supplierId = await supplierRepo.createSupplier(
        name: 'Quality Spices Wholesaler',
        phone: '9876500000',
      );

      final poId = await purchaseRepo.createPurchaseOrder(
        supplierId: supplierId,
        notes: 'Monthly bulk spices',
        items: [
          {
            'productName': 'Turmeric Powder Bulk',
            'unit': 'kg',
            'quantity': 10,
            'unitPricePaise': 5000,
            'gstRatePercent': 5.0,
          },
        ],
      );

      final piId = await purchaseRepo.submitSupplierInvoice(
        supplierId: supplierId,
        purchaseOrderId: poId,
        invoiceNumber: 'PI-D1-00001',
        items: [
          {
            'productName': 'Turmeric Powder Bulk',
            'unit': 'kg',
            'quantity': 10,
            'unitPricePaise': 5000,
            'gstRatePercent': 5.0,
          },
        ],
      );

      await purchaseRepo.recordSupplierPayment(
        supplierId: supplierId,
        purchaseInvoiceId: piId,
        amountPaise: 52500,
        paymentMethod: 'Bank Transfer',
        referenceNumber: 'NEFT-883311',
      );

      // Assert Sales Stream
      final customerPayments = await db.select(db.payments).get();
      expect(customerPayments.length, equals(1));
      expect(customerPayments.first.id, equals(salesPaymentId));
      expect(customerPayments.first.invoiceId, equals(salesInvoiceId));
      expect(customerPayments.first.amountPaise, equals(15000));

      // Assert Procurement Stream
      final supplierPayments = await db.select(db.supplierPayments).get();
      expect(supplierPayments.length, equals(1));
      expect(supplierPayments.first.supplierId, equals(supplierId));
      expect(supplierPayments.first.purchaseInvoiceId, equals(piId));
      expect(supplierPayments.first.amountPaise, equals(52500));

      // Strict stream isolation verification:
      expect(customerPayments.any((cp) => cp.invoiceId == piId), isFalse);
      expect(supplierPayments.any((sp) => sp.purchaseInvoiceId == salesInvoiceId), isFalse);
    });
  });
}
