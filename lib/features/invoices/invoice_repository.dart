import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';
import '../../core/sync/sync_provider.dart';
import '../../core/sync/sync_service.dart';

final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final sync = ref.watch(syncServiceProvider);
  return InvoiceRepository(db, sync);
});

class InvoiceSummary {
  final InvoiceEntry invoice;
  final int itemCount;
  final bool hasNote;
  final String? notePreview;

  const InvoiceSummary({
    required this.invoice,
    required this.itemCount,
    required this.hasNote,
    this.notePreview,
  });
}

class InvoiceDetails {
  final InvoiceEntry invoice;
  final List<InvoiceItemEntry> items;
  final BillNoteEntry? billNote;
  final List<PaymentEntry> payments;

  const InvoiceDetails({
    required this.invoice,
    required this.items,
    this.billNote,
    required this.payments,
  });

  int get balanceDuePaise => invoice.grandTotalPaise - invoice.paidAmountPaise;
}

class CreateInvoiceParams {
  final InvoicesCompanion invoice;
  final List<InvoiceItemsCompanion> items;
  final String? billNote;
  final bool isNoteCustomerFacing;
  final PaymentsCompanion? payment;

  const CreateInvoiceParams({
    required this.invoice,
    required this.items,
    this.billNote,
    this.isNoteCustomerFacing = true,
    this.payment,
  });
}

class CustomerPendingSummary {
  final String customerName;
  final String? customerPhone;
  final int totalBillsCount;
  final int totalAmountPaise;
  final int paidAmountPaise;
  final int remainingAmountPaise;
  final DateTime lastBillDate;

  const CustomerPendingSummary({
    required this.customerName,
    this.customerPhone,
    required this.totalBillsCount,
    required this.totalAmountPaise,
    required this.paidAmountPaise,
    required this.remainingAmountPaise,
    required this.lastBillDate,
  });
}

class InvoiceRepository {
  final AppDatabase _db;
  final SyncService? _sync;
  final _uuid = const Uuid();

  InvoiceRepository(this._db, [this._sync]);

  /// Generates the next sequential invoice number like "INV-000001" or collision-resistant "INV-D1-00001"
  Future<String> generateNextInvoiceNumber({String prefix = 'INV-', String? deviceCode}) async {
    final effectivePrefix = (deviceCode != null && deviceCode.trim().isNotEmpty)
        ? (prefix.endsWith('-') ? '$prefix${deviceCode.trim()}-' : '$prefix-${deviceCode.trim()}-')
        : prefix;

    final query = _db.select(_db.invoices)
      ..where((t) => t.invoiceNumber.like('$effectivePrefix%'))
      ..orderBy([
        (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
      ])
      ..limit(1);

    final last = await query.getSingleOrNull();
    if (last == null) {
      return (deviceCode != null && deviceCode.trim().isNotEmpty)
          ? '${effectivePrefix}00001'
          : '${effectivePrefix}000001';
    }

    final currentNumStr = last.invoiceNumber.replaceFirst(effectivePrefix, '');
    final currentNum = int.tryParse(currentNumStr) ?? 0;
    final nextNum = currentNum + 1;
    final padLength = (deviceCode != null && deviceCode.trim().isNotEmpty) ? 5 : 6;
    final padded = nextNum.toString().padLeft(padLength, '0');
    return '$effectivePrefix$padded';
  }

  /// Atomically creates an invoice with all its snapshot items,
  /// its dedicated bill note (if provided), and initial payment record.
  Future<String> createInvoice(CreateInvoiceParams params) async {
    final invoiceId = await _db.transaction(() async {
      // 1. Insert Invoice
      await _db.into(_db.invoices).insert(params.invoice);
      final invId = params.invoice.id.value;

      // 2. Insert all Invoice Items (historical snapshots)
      for (final item in params.items) {
        await _db.into(_db.invoiceItems).insert(item);
      }

      // 3. Insert Bill Note if provided
      if (params.billNote != null && params.billNote!.trim().isNotEmpty) {
        final now = DateTime.now();
        await _db.into(_db.billNotes).insert(
              BillNotesCompanion.insert(
                id: _uuid.v4(),
                invoiceId: invId,
                note: params.billNote!.trim(),
                isCustomerFacing: Value(params.isNoteCustomerFacing),
                createdAt: now,
                updatedAt: now,
              ),
            );
      }

      // 4. Insert Payment record if provided
      if (params.payment != null) {
        await _db.into(_db.payments).insert(params.payment!);
      }

      // 5. Update Dining Table occupancy if Dine In
      final orderType = params.invoice.orderType.present ? params.invoice.orderType.value : 'Dine In';
      final tableNum = params.invoice.tableNumber.present ? params.invoice.tableNumber.value : null;
      if (orderType.toLowerCase() == 'dine in' && tableNum != null && tableNum.isNotEmpty) {
        final isCompleted = params.invoice.orderStatus.present
            ? params.invoice.orderStatus.value == AppConstants.orderCompleted
            : false;
        await (_db.update(_db.diningTables)..where((t) => t.name.equals(tableNum.trim()))).write(
          DiningTablesCompanion(
            isOccupied: Value(!isCompleted),
            currentInvoiceId: Value(isCompleted ? null : invId),
          ),
        );
      }

      return invId;
    });

    final sync = _sync;
    if (sync != null) {
      final createdInv = await getInvoiceById(invoiceId);
      if (createdInv != null) {
        await sync.enqueueChange(
          entityName: 'invoices',
          recordId: invoiceId,
          operation: 'INSERT',
          idempotencyKey: invoiceId,
          payload: {
            'id': invoiceId,
            'orderId': createdInv.orderId,
            'idempotencyKey': invoiceId,
            'deviceId': createdInv.deviceId,
            'invoiceNumber': createdInv.invoiceNumber,
            'orderType': createdInv.orderType,
            'orderStatus': createdInv.orderStatus,
            'paymentStatus': createdInv.paymentStatus,
            'paymentMethod': createdInv.paymentMethod,
            'customerName': createdInv.customerName,
            'customerPhone': createdInv.customerPhone,
            'tableNumber': createdInv.tableNumber,
            'deliveryAddress': createdInv.deliveryAddress,
            'subtotalPaise': createdInv.subtotalPaise,
            'itemDiscountTotalPaise': createdInv.itemDiscountTotalPaise,
            'billDiscountPaise': createdInv.billDiscountPaise,
            'taxableAmountPaise': createdInv.taxableAmountPaise,
            'cgstPaise': createdInv.cgstPaise,
            'sgstPaise': createdInv.sgstPaise,
            'igstPaise': createdInv.igstPaise,
            'roundOffPaise': createdInv.roundOffPaise,
            'grandTotalPaise': createdInv.grandTotalPaise,
            'paidAmountPaise': createdInv.paidAmountPaise,
            'billNote': params.billNote,
            'createdAt': createdInv.createdAt.toIso8601String(),
            'items': params.items.map((i) => {
              'id': i.id.value,
              'productId': i.productId.present ? i.productId.value : null,
              'productName': i.productName.value,
              'productCode': i.productCode.present ? i.productCode.value : null,
              'unit': i.unit.present ? i.unit.value : 'plate',
              'unitPricePaise': i.unitPricePaise.value,
              'quantity': i.quantity.value,
              'discountPaise': i.discountPaise.present ? i.discountPaise.value : 0,
              'gstRatePercent': i.gstRatePercent.present ? i.gstRatePercent.value : 0.0,
              'isTaxInclusive': i.isTaxInclusive.present ? i.isTaxInclusive.value : true,
              'taxableAmountPaise': i.taxableAmountPaise.value,
              'taxAmountPaise': i.taxAmountPaise.value,
              'totalAmountPaise': i.totalAmountPaise.value,
            }).toList(),
          },
        );
      }

      if (params.payment != null) {
        final pay = params.payment!;
        await sync.enqueueChange(
          entityName: 'payments',
          recordId: pay.id.value,
          operation: 'INSERT',
          idempotencyKey: pay.id.value,
          payload: {
            'id': pay.id.value,
            'invoiceId': pay.invoiceId.value,
            'amountPaise': pay.amountPaise.value,
            'paymentMethod': pay.paymentMethod.value,
            'referenceNumber': pay.referenceNumber.present ? pay.referenceNumber.value : null,
            'notes': pay.notes.present ? pay.notes.value : null,
            'idempotencyKey': pay.id.value,
          },
        );
      }
    }

    return invoiceId;
  }

  /// Saves a new pending order or updates an existing pending order (when reopening to add items),
  /// ensuring NO duplicate invoices are created and keeping order items synchronized atomically.
  Future<String> saveOrUpdatePendingOrder({
    String? existingInvoiceId,
    String? deviceId,
    required String? invoiceNumber,
    required String? customerName,
    required String? customerPhone,
    required String orderType,
    required String? tableNumber,
    required String? deliveryAddress,
    required int subtotalPaise,
    required int itemDiscountTotalPaise,
    required int billDiscountPaise,
    required int taxableAmountPaise,
    required int cgstPaise,
    required int sgstPaise,
    required int roundOffPaise,
    required int grandTotalPaise,
    required String cashierId,
    required String cashierName,
    String? billNote,
    bool isNoteCustomerFacing = true,
    required List<InvoiceItemsCompanion> items,
  }) async {
    final finalInvoiceId = await _db.transaction(() async {
      final now = DateTime.now();
      String invoiceId;

      if (existingInvoiceId != null) {
        invoiceId = existingInvoiceId;
        // Update existing invoice row
        await (_db.update(_db.invoices)..where((t) => t.id.equals(invoiceId))).write(
          InvoicesCompanion(
            customerName: Value(customerName),
            customerPhone: Value(customerPhone),
            orderType: Value(orderType),
            tableNumber: Value(tableNumber),
            deliveryAddress: Value(deliveryAddress),
            subtotalPaise: Value(subtotalPaise),
            itemDiscountTotalPaise: Value(itemDiscountTotalPaise),
            billDiscountPaise: Value(billDiscountPaise),
            taxableAmountPaise: Value(taxableAmountPaise),
            cgstPaise: Value(cgstPaise),
            sgstPaise: Value(sgstPaise),
            roundOffPaise: Value(roundOffPaise),
            grandTotalPaise: Value(grandTotalPaise),
          ),
        );

        // Delete old items to replace with updated snapshot list
        await (_db.delete(_db.invoiceItems)..where((t) => t.invoiceId.equals(invoiceId))).go();
      } else {
        invoiceId = _uuid.v4();
        // Insert brand new pending invoice
        await _db.into(_db.invoices).insert(
          InvoicesCompanion.insert(
            id: invoiceId,
            invoiceNumber: invoiceNumber ?? 'ORD-000000',
            createdAt: now,
            customerName: Value(customerName),
            customerPhone: Value(customerPhone),
            subtotalPaise: subtotalPaise,
            itemDiscountTotalPaise: Value(itemDiscountTotalPaise),
            billDiscountPaise: Value(billDiscountPaise),
            taxableAmountPaise: taxableAmountPaise,
            cgstPaise: Value(cgstPaise),
            sgstPaise: Value(sgstPaise),
            igstPaise: const Value(0),
            roundOffPaise: Value(roundOffPaise),
            grandTotalPaise: grandTotalPaise,
            paymentMethod: const Value('Pending'),
            paymentStatus: const Value(AppConstants.statusPending),
            paidAmountPaise: 0,
            orderStatus: const Value(AppConstants.orderPending),
            orderType: Value(orderType),
            tableNumber: Value(tableNumber),
            deliveryAddress: Value(deliveryAddress),
            deviceId: Value(deviceId),
            cashierId: Value(cashierId),
            cashierName: Value(cashierName),
          ),
        );

        // If Dine In, mark table occupied
        if (orderType.toLowerCase() == 'dine in' && tableNumber != null && tableNumber.isNotEmpty) {
          await (_db.update(_db.diningTables)..where((t) => t.name.equals(tableNumber.trim()))).write(
            DiningTablesCompanion(
              isOccupied: const Value(true),
              currentInvoiceId: Value(invoiceId),
            ),
          );
        }
      }

      // Insert fresh snapshot items
      for (final item in items) {
        final companion = item.copyWith(invoiceId: Value(invoiceId));
        await _db.into(_db.invoiceItems).insert(companion);
      }

      // Update or insert dedicated bill note
      if (billNote != null && billNote.trim().isNotEmpty) {
        final existingNote = await (_db.select(_db.billNotes)
              ..where((t) => t.invoiceId.equals(invoiceId)))
            .getSingleOrNull();

        if (existingNote != null) {
          await (_db.update(_db.billNotes)..where((t) => t.id.equals(existingNote.id))).write(
            BillNotesCompanion(
              note: Value(billNote.trim()),
              isCustomerFacing: Value(isNoteCustomerFacing),
              updatedAt: Value(now),
            ),
          );
        } else {
          await _db.into(_db.billNotes).insert(
            BillNotesCompanion.insert(
              id: _uuid.v4(),
              invoiceId: invoiceId,
              note: billNote.trim(),
              isCustomerFacing: Value(isNoteCustomerFacing),
              createdAt: now,
              updatedAt: now,
            ),
          );
        }
      }

      return invoiceId;
    });

    final sync = _sync;
    if (sync != null) {
      final createdInv = await getInvoiceById(finalInvoiceId);
      if (createdInv != null) {
        await sync.enqueueChange(
          entityName: 'invoices',
          recordId: finalInvoiceId,
          operation: existingInvoiceId != null ? 'UPDATE' : 'INSERT',
          idempotencyKey: finalInvoiceId,
          payload: {
            'id': finalInvoiceId,
            'idempotencyKey': finalInvoiceId,
            'deviceId': createdInv.deviceId,
            'invoiceNumber': createdInv.invoiceNumber,
            'orderType': createdInv.orderType,
            'orderStatus': createdInv.orderStatus,
            'paymentStatus': createdInv.paymentStatus,
            'customerName': createdInv.customerName,
            'customerPhone': createdInv.customerPhone,
            'tableNumber': createdInv.tableNumber,
            'deliveryAddress': createdInv.deliveryAddress,
            'subtotalPaise': createdInv.subtotalPaise,
            'itemDiscountTotalPaise': createdInv.itemDiscountTotalPaise,
            'billDiscountPaise': createdInv.billDiscountPaise,
            'taxableAmountPaise': createdInv.taxableAmountPaise,
            'cgstPaise': createdInv.cgstPaise,
            'sgstPaise': createdInv.sgstPaise,
            'roundOffPaise': createdInv.roundOffPaise,
            'grandTotalPaise': createdInv.grandTotalPaise,
            'paidAmountPaise': createdInv.paidAmountPaise,
            'billNote': billNote,
            'createdAt': createdInv.createdAt.toIso8601String(),
            'items': items.map((i) => {
              'id': i.id.value,
              'productId': i.productId.present ? i.productId.value : null,
              'productName': i.productName.value,
              'productCode': i.productCode.present ? i.productCode.value : null,
              'unit': i.unit.present ? i.unit.value : 'plate',
              'unitPricePaise': i.unitPricePaise.value,
              'quantity': i.quantity.value,
              'discountPaise': i.discountPaise.present ? i.discountPaise.value : 0,
              'gstRatePercent': i.gstRatePercent.present ? i.gstRatePercent.value : 0.0,
              'isTaxInclusive': i.isTaxInclusive.present ? i.isTaxInclusive.value : true,
              'taxableAmountPaise': i.taxableAmountPaise.value,
              'taxAmountPaise': i.taxAmountPaise.value,
              'totalAmountPaise': i.totalAmountPaise.value,
            }).toList(),
          },
        );
      }
    }

    return finalInvoiceId;
  }

  /// Completes an order (pending or active), records the collected payment, and updates order status.
  Future<void> completeOrder({
    required String invoiceId,
    required int paidAmountPaise,
    required String paymentMethod,
    String? referenceNumber,
    String? note,
  }) async {
    String? paymentId;

    await _db.transaction(() async {
      final invoice = await (_db.select(_db.invoices)..where((t) => t.id.equals(invoiceId))).getSingleOrNull();
      if (invoice == null) throw Exception('Order not found');

      final now = DateTime.now();
      if (paidAmountPaise > 0) {
        paymentId = _uuid.v4();
        await _db.into(_db.payments).insert(
          PaymentsCompanion.insert(
            id: paymentId!,
            invoiceId: invoiceId,
            amountPaise: paidAmountPaise,
            paymentMethod: paymentMethod,
            referenceNumber: Value(referenceNumber),
            notes: Value(note),
            createdAt: now,
          ),
        );
      }

      final newTotalPaid = invoice.paidAmountPaise + paidAmountPaise;
      final newPaymentStatus = newTotalPaid >= invoice.grandTotalPaise
          ? AppConstants.statusPaid
          : (newTotalPaid > 0 ? AppConstants.statusPartial : AppConstants.statusPending);

      await (_db.update(_db.invoices)..where((t) => t.id.equals(invoiceId))).write(
        InvoicesCompanion(
          paidAmountPaise: Value(newTotalPaid),
          paymentMethod: Value(paymentMethod),
          paymentStatus: Value(newPaymentStatus),
          orderStatus: const Value(AppConstants.orderCompleted),
        ),
      );

      // Release dining table
      if (invoice.tableNumber != null && invoice.tableNumber!.isNotEmpty) {
        await (_db.update(_db.diningTables)..where((t) => t.name.equals(invoice.tableNumber!.trim()))).write(
          const DiningTablesCompanion(
            isOccupied: Value(false),
            currentInvoiceId: Value(null),
          ),
        );
      }
    });

    if (paymentId != null) {
      await _sync?.enqueueChange(
        entityName: 'payments',
        recordId: paymentId!,
        operation: 'INSERT',
        idempotencyKey: paymentId!,
        payload: {
          'id': paymentId,
          'invoiceId': invoiceId,
          'amountPaise': paidAmountPaise,
          'paymentMethod': paymentMethod,
          'referenceNumber': referenceNumber,
          'notes': note,
          'idempotencyKey': paymentId,
        },
      );
    }

    await _sync?.enqueueChange(
      entityName: 'invoices',
      recordId: invoiceId,
      operation: 'UPDATE',
      idempotencyKey: 'update-comp-$invoiceId',
      payload: {
        'id': invoiceId,
        'orderStatus': AppConstants.orderCompleted,
        'paymentStatus': paidAmountPaise > 0 ? AppConstants.statusPaid : AppConstants.statusPending,
        'paidAmountPaise': paidAmountPaise,
        'paymentMethod': paymentMethod,
      },
    );
  }

  /// Records an additional payment against an invoice (e.g. collecting remaining due),
  /// without modifying historical payment records, and updates paidAmountPaise & paymentStatus.
  Future<void> recordAdditionalPayment({
    required String invoiceId,
    required int amountPaise,
    required String paymentMethod,
    String? referenceNumber,
    String? notes,
  }) async {
    final paymentId = _uuid.v4();
    final now = DateTime.now();

    await _db.transaction(() async {
      final invoice = await (_db.select(_db.invoices)..where((t) => t.id.equals(invoiceId))).getSingleOrNull();
      if (invoice == null) throw Exception('Invoice not found');

      // 1. Insert new payment record into historical payments table
      await _db.into(_db.payments).insert(
            PaymentsCompanion.insert(
              id: paymentId,
              invoiceId: invoiceId,
              amountPaise: amountPaise,
              paymentMethod: paymentMethod,
              referenceNumber: Value(referenceNumber),
              notes: Value(notes),
              createdAt: now,
            ),
          );

      // 2. Compute new total paid
      final newPaidAmount = invoice.paidAmountPaise + amountPaise;
      final newStatus = newPaidAmount >= invoice.grandTotalPaise
          ? AppConstants.statusPaid
          : AppConstants.statusPartial;

      // 3. Atomically update the invoice totals and payment status
      await (_db.update(_db.invoices)..where((t) => t.id.equals(invoiceId))).write(
            InvoicesCompanion(
              paidAmountPaise: Value(newPaidAmount),
              paymentStatus: Value(newStatus),
            ),
          );
    });

    _sync?.enqueueChange(
      entityName: 'payments',
      recordId: paymentId,
      operation: 'INSERT',
      idempotencyKey: paymentId,
      payload: {
        'id': paymentId,
        'invoiceId': invoiceId,
        'amountPaise': amountPaise,
        'paymentMethod': paymentMethod,
        'referenceNumber': referenceNumber,
        'notes': notes,
        'idempotencyKey': paymentId,
      },
    );
  }

  /// Updates the order status of an invoice (e.g. In Progress, Completed, Cancelled)
  Future<void> updateOrderStatus({
    required String invoiceId,
    required String orderStatus,
  }) async {
    final invoice = await (_db.select(_db.invoices)..where((t) => t.id.equals(invoiceId))).getSingleOrNull();

    await (_db.update(_db.invoices)..where((t) => t.id.equals(invoiceId))).write(
          InvoicesCompanion(
            orderStatus: Value(orderStatus),
          ),
        );

    // If order was cancelled or completed, release table
    if (invoice != null && (orderStatus == AppConstants.orderCompleted || orderStatus == AppConstants.orderCancelled)) {
      if (invoice.tableNumber != null && invoice.tableNumber!.isNotEmpty) {
        await (_db.update(_db.diningTables)..where((t) => t.name.equals(invoice.tableNumber!.trim()))).write(
          const DiningTablesCompanion(
            isOccupied: Value(false),
            currentInvoiceId: Value(null),
          ),
        );
      }
    }
  }

  /// Updates an individual bill's note in the dedicated bill_notes table
  Future<void> updateBillNote({
    required String invoiceId,
    required String noteText,
    bool isCustomerFacing = true,
  }) async {
    final cleanNote = noteText.trim();
    final now = DateTime.now();

    final existing = await (_db.select(_db.billNotes)
          ..where((t) => t.invoiceId.equals(invoiceId)))
        .getSingleOrNull();

    if (existing != null) {
      if (cleanNote.isEmpty) {
        await (_db.delete(_db.billNotes)
              ..where((t) => t.invoiceId.equals(invoiceId)))
            .go();
      } else {
        await (_db.update(_db.billNotes)..where((t) => t.id.equals(existing.id)))
            .write(
          BillNotesCompanion(
            note: Value(cleanNote),
            isCustomerFacing: Value(isCustomerFacing),
            updatedAt: Value(now),
          ),
        );
      }
    } else if (cleanNote.isNotEmpty) {
      final noteId = _uuid.v4();
      await _db.into(_db.billNotes).insert(
            BillNotesCompanion.insert(
              id: noteId,
              invoiceId: invoiceId,
              note: cleanNote,
              isCustomerFacing: Value(isCustomerFacing),
              createdAt: now,
              updatedAt: now,
            ),
          );
    }
  }

  Future<InvoiceEntry?> getInvoiceById(String invoiceId) async {
    return (_db.select(_db.invoices)..where((t) => t.id.equals(invoiceId))).getSingleOrNull();
  }

  Future<List<InvoiceItemEntry>> getInvoiceItems(String invoiceId) async {
    return (_db.select(_db.invoiceItems)..where((t) => t.invoiceId.equals(invoiceId))).get();
  }

  /// Fetches complete invoice details: invoice, items, dedicated note, and payments
  Future<InvoiceDetails?> getInvoiceWithDetails(String invoiceId) async {
    final invoice = await (_db.select(_db.invoices)
          ..where((t) => t.id.equals(invoiceId)))
        .getSingleOrNull();

    if (invoice == null) return null;

    final items = await (_db.select(_db.invoiceItems)
          ..where((t) => t.invoiceId.equals(invoiceId)))
        .get();

    final note = await (_db.select(_db.billNotes)
          ..where((t) => t.invoiceId.equals(invoiceId)))
        .getSingleOrNull();

    final payments = await (_db.select(_db.payments)
          ..where((t) => t.invoiceId.equals(invoiceId))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc)]))
        .get();

    return InvoiceDetails(
      invoice: invoice,
      items: items,
      billNote: note,
      payments: payments,
    );
  }

  /// Streams complete invoice details for reactive UI updates
  Stream<InvoiceDetails?> watchInvoiceWithDetails(String invoiceId) {
    final invoiceStream = (_db.select(_db.invoices)
          ..where((t) => t.id.equals(invoiceId)))
        .watchSingleOrNull();

    return invoiceStream.asyncMap((invoice) async {
      if (invoice == null) return null;

      final items = await (_db.select(_db.invoiceItems)
            ..where((t) => t.invoiceId.equals(invoiceId)))
          .get();

      final note = await (_db.select(_db.billNotes)
            ..where((t) => t.invoiceId.equals(invoiceId)))
          .getSingleOrNull();

      final payments = await (_db.select(_db.payments)
            ..where((t) => t.invoiceId.equals(invoiceId))
            ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc)]))
          .get();

      return InvoiceDetails(
        invoice: invoice,
        items: items,
        billNote: note,
        payments: payments,
      );
    });
  }

  /// Streams list of complete Order details for the Cashier Order History Screen (Ref Image 03)
  Stream<List<InvoiceDetails>> watchOrdersWithDetails({
    String? orderStatus, // 'Pending' or 'Completed'
    String? searchQuery,
  }) {
    final query = _db.select(_db.invoices)
      ..where((t) => t.isCancelled.equals(false));

    if (orderStatus != null && orderStatus.isNotEmpty && orderStatus != 'ALL') {
      query.where((t) => t.orderStatus.equals(orderStatus));
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final term = '%${searchQuery.trim().toLowerCase()}%';
      query.where(
        (t) =>
            t.invoiceNumber.lower().like(term) |
            t.customerName.lower().like(term) |
            t.customerPhone.lower().like(term) |
            t.tableNumber.lower().like(term),
      );
    }

    query.orderBy([
      (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
    ]);

    return query.watch().asyncMap((invoices) async {
      final result = <InvoiceDetails>[];
      for (final inv in invoices) {
        final items = await (_db.select(_db.invoiceItems)
              ..where((t) => t.invoiceId.equals(inv.id)))
            .get();

        final note = await (_db.select(_db.billNotes)
              ..where((t) => t.invoiceId.equals(inv.id)))
            .getSingleOrNull();

        final payments = await (_db.select(_db.payments)
              ..where((t) => t.invoiceId.equals(inv.id))
              ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc)]))
            .get();

        result.add(InvoiceDetails(
          invoice: inv,
          items: items,
          billNote: note,
          payments: payments,
        ));
      }
      return result;
    });
  }

  /// Streams active pending orders count for badge display
  Stream<int> watchPendingOrdersCount() {
    final query = _db.selectOnly(_db.invoices)
      ..addColumns([_db.invoices.id.count()])
      ..where(
        _db.invoices.orderStatus.equals(AppConstants.orderPending) &
        _db.invoices.isCancelled.equals(false),
      );

    return query.watch().map((rows) {
      if (rows.isEmpty) return 0;
      return rows.first.read(_db.invoices.id.count()) ?? 0;
    });
  }

  /// Gets list of table numbers that currently have an active pending order
  Future<List<String>> getOccupiedTables() async {
    final query = _db.select(_db.invoices)
      ..where(
        (t) =>
            t.orderStatus.equals(AppConstants.orderPending) &
            t.isCancelled.equals(false) &
            t.orderType.equals(AppConstants.orderTypeDineIn),
      );
    final rows = await query.get();
    return rows
        .map((r) => r.tableNumber)
        .whereType<String>()
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList();
  }

  /// Streams invoice summaries for the Bills History list with search & filters
  Stream<List<InvoiceSummary>> watchInvoicesSummary({
    String? searchQuery,
    DateTime? fromDate,
    DateTime? toDate,
    String? paymentStatus,
    String? orderStatus,
    bool pendingOnly = false,
    String? cashierId,
  }) {
    final query = _db.select(_db.invoices);

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final term = '%${searchQuery.trim().toLowerCase()}%';
      query.where(
        (t) =>
            t.invoiceNumber.lower().like(term) |
            t.customerName.lower().like(term) |
            t.customerPhone.lower().like(term),
      );
    }

    if (paymentStatus != null && paymentStatus != 'ALL') {
      query.where((t) => t.paymentStatus.equals(paymentStatus));
    }

    if (orderStatus != null && orderStatus != 'ALL') {
      query.where((t) => t.orderStatus.equals(orderStatus));
    }

    if (cashierId != null && cashierId.isNotEmpty) {
      query.where((t) => t.cashierId.equals(cashierId));
    }

    if (fromDate != null) {
      query.where((t) => t.createdAt.isBiggerOrEqualValue(fromDate));
    }

    if (toDate != null) {
      query.where((t) => t.createdAt.isSmallerOrEqualValue(toDate));
    }

    query.orderBy([
      (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
    ]);

    return query.watch().asyncMap((invoices) async {
      final summaries = <InvoiceSummary>[];
      for (final inv in invoices) {
        if (pendingOnly && inv.grandTotalPaise <= inv.paidAmountPaise) {
          continue;
        }

        final itemCountQuery = _db.selectOnly(_db.invoiceItems)
          ..addColumns([_db.invoiceItems.id.count()])
          ..where(_db.invoiceItems.invoiceId.equals(inv.id));
        final itemCount = await itemCountQuery
            .map((row) => row.read(_db.invoiceItems.id.count()) ?? 0)
            .getSingle();

        final note = await (_db.select(_db.billNotes)
              ..where((t) => t.invoiceId.equals(inv.id)))
            .getSingleOrNull();

        summaries.add(InvoiceSummary(
          invoice: inv,
          itemCount: itemCount,
          hasNote: note != null && note.note.isNotEmpty,
          notePreview: note?.note,
        ));
      }
      return summaries;
    });
  }

  /// Cancels an invoice safely without deleting historical records
  Future<void> cancelInvoice(String invoiceId, String reason) async {
    await (_db.update(_db.invoices)..where((t) => t.id.equals(invoiceId))).write(
      InvoicesCompanion(
        isCancelled: const Value(true),
        paymentStatus: const Value(AppConstants.statusCancelled),
        orderStatus: const Value(AppConstants.orderCancelled),
        cancelledAt: Value(DateTime.now()),
        cancelReason: Value(reason),
      ),
    );

    _sync?.enqueueChange(
      entityName: 'invoices',
      recordId: invoiceId,
      operation: 'UPDATE',
      idempotencyKey: 'cancel-$invoiceId',
      payload: {
        'id': invoiceId,
        'isCancelled': true,
        'orderStatus': AppConstants.orderCancelled,
        'paymentStatus': AppConstants.statusCancelled,
        'cancelReason': reason,
      },
    );
  }

  /// Fetches customer-wise outstanding amount breakdown for pending amount management
  Stream<List<CustomerPendingSummary>> watchCustomerPendingSummaries() {
    return _db.select(_db.invoices).watch().asyncMap((_) async {
      final pendingInvoices = await (_db.select(_db.invoices)
            ..where((t) => t.isCancelled.equals(false)))
          .get();

      final Map<String, List<InvoiceEntry>> grouped = {};
      for (final inv in pendingInvoices) {
        if (inv.grandTotalPaise > inv.paidAmountPaise) {
          final custKey = (inv.customerName != null && inv.customerName!.trim().isNotEmpty)
              ? inv.customerName!.trim()
              : 'Walk-in Customer (${inv.invoiceNumber})';
          grouped.putIfAbsent(custKey, () => []).add(inv);
        }
      }

      final list = <CustomerPendingSummary>[];
      for (final entry in grouped.entries) {
        final custInvoices = entry.value;
        final totalAmount = custInvoices.fold<int>(0, (sum, i) => sum + i.grandTotalPaise);
        final paidAmount = custInvoices.fold<int>(0, (sum, i) => sum + i.paidAmountPaise);
        final latestDate = custInvoices.map((i) => i.createdAt).reduce((a, b) => a.isAfter(b) ? a : b);
        final phone = custInvoices.firstWhere((i) => i.customerPhone != null && i.customerPhone!.isNotEmpty, orElse: () => custInvoices.first).customerPhone;

        list.add(CustomerPendingSummary(
          customerName: entry.key,
          customerPhone: phone,
          totalBillsCount: custInvoices.length,
          totalAmountPaise: totalAmount,
          paidAmountPaise: paidAmount,
          remainingAmountPaise: totalAmount - paidAmount,
          lastBillDate: latestDate,
        ));
      }

      list.sort((a, b) => b.remainingAmountPaise.compareTo(a.remainingAmountPaise));
      return list;
    });
  }
}
