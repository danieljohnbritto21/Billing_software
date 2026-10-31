import 'package:drift/drift.dart';

@DataClassName('CategoryEntry')
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text().nullable()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get icon => text().nullable()();
  IntColumn get colorValue => integer().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get displayOrder => integer().withDefault(const Constant(0))();
  Int64Column get serverVersion => int64().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text().nullable().withDefault(const Constant('synced'))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ProductEntry')
class Products extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text().nullable()();
  TextColumn get name => text().withLength(min: 1, max: 150)();
  TextColumn get code => text().nullable()(); // SKU or barcode
  TextColumn get categoryId => text().nullable().references(Categories, #id)();
  TextColumn get description => text().nullable()();
  IntColumn get costPricePaise => integer().withDefault(const Constant(0))();
  IntColumn get sellingPricePaise => integer()();
  RealColumn get gstRatePercent => real().withDefault(const Constant(0.0))();
  BoolColumn get isTaxInclusive => boolean().withDefault(const Constant(true))();
  TextColumn get unit => text().withDefault(const Constant('plate'))();
  BoolColumn get isAvailable => boolean().withDefault(const Constant(true))();
  TextColumn get imagePath => text().nullable()();
  Int64Column get serverVersion => int64().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text().nullable().withDefault(const Constant('synced'))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('InvoiceEntry')
class Invoices extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text().nullable()();
  TextColumn get deviceId => text().nullable()();
  TextColumn get customerId => text().nullable()();
  TextColumn get invoiceNumber => text().customConstraint('NOT NULL UNIQUE')();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get customerName => text().nullable()();
  TextColumn get customerPhone => text().nullable()();
  IntColumn get subtotalPaise => integer()();
  IntColumn get itemDiscountTotalPaise => integer().withDefault(const Constant(0))();
  IntColumn get billDiscountPaise => integer().withDefault(const Constant(0))();
  IntColumn get taxableAmountPaise => integer()();
  IntColumn get cgstPaise => integer().withDefault(const Constant(0))();
  IntColumn get sgstPaise => integer().withDefault(const Constant(0))();
  IntColumn get igstPaise => integer().withDefault(const Constant(0))();
  IntColumn get roundOffPaise => integer().withDefault(const Constant(0))();
  IntColumn get grandTotalPaise => integer()();
  TextColumn get paymentMethod => text().withDefault(const Constant('Cash'))();
  TextColumn get paymentStatus => text().withDefault(const Constant('Paid'))();
  TextColumn get orderStatus => text().withDefault(const Constant('Completed'))();
  TextColumn get orderType => text().withDefault(const Constant('Dine In'))();
  TextColumn get tableNumber => text().nullable()();
  TextColumn get deliveryAddress => text().nullable()();
  TextColumn get kotNumber => text().nullable()();
  TextColumn get cashierId => text().nullable()();
  TextColumn get cashierName => text().nullable()();
  IntColumn get paidAmountPaise => integer()();
  BoolColumn get isCancelled => boolean().withDefault(const Constant(false))();
  DateTimeColumn get cancelledAt => dateTime().nullable()();
  TextColumn get cancelReason => text().nullable()();
  TextColumn get idempotencyKey => text().nullable()();
  Int64Column get serverVersion => int64().nullable()();
  TextColumn get syncStatus => text().nullable().withDefault(const Constant('synced'))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('InvoiceItemEntry')
class InvoiceItems extends Table {
  TextColumn get id => text()();
  TextColumn get invoiceId => text().references(Invoices, #id)();
  TextColumn get productId => text().nullable()();
  TextColumn get productName => text()();
  TextColumn get productCode => text().nullable()();
  TextColumn get unit => text()();
  IntColumn get unitPricePaise => integer()();
  RealColumn get quantity => real()();
  IntColumn get discountPaise => integer().withDefault(const Constant(0))();
  RealColumn get gstRatePercent => real()();
  BoolColumn get isTaxInclusive => boolean()();
  IntColumn get taxableAmountPaise => integer()();
  IntColumn get taxAmountPaise => integer()();
  IntColumn get totalAmountPaise => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Dedicated Bill Notes table ensuring each note is independently
/// linked to a specific invoice, fully editable without touching financial data.
@DataClassName('BillNoteEntry')
class BillNotes extends Table {
  TextColumn get id => text()();
  TextColumn get invoiceId => text().customConstraint('NOT NULL UNIQUE REFERENCES invoices(id)')();
  TextColumn get note => text()();
  BoolColumn get isCustomerFacing => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PaymentEntry')
class Payments extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text().nullable()();
  TextColumn get invoiceId => text().references(Invoices, #id)();
  IntColumn get amountPaise => integer()();
  TextColumn get paymentMethod => text()();
  TextColumn get referenceNumber => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get idempotencyKey => text().nullable()();
  Int64Column get serverVersion => int64().nullable()();
  TextColumn get syncStatus => text().nullable().withDefault(const Constant('synced'))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CustomerEntry')
class Customers extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  Int64Column get serverVersion => int64().nullable()();
  TextColumn get syncStatus => text().nullable().withDefault(const Constant('synced'))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AppSettingEntry')
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DataClassName('ProductImageEntry')
class ProductImages extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().references(Products, #id, onDelete: KeyAction.cascade)();
  BlobColumn get imageBytes => blob()();
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();
  IntColumn get displayOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('UserEntry')
class Users extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text().nullable()();
  TextColumn get username => text().customConstraint('NOT NULL UNIQUE')();
  TextColumn get fullName => text()();
  TextColumn get role => text()(); // 'admin' or 'cashier'
  TextColumn get passwordHash => text()();
  TextColumn get salt => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('DiningTableEntry')
class DiningTables extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text().nullable()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  IntColumn get seatingCapacity => integer().withDefault(const Constant(4))();
  BoolColumn get isOccupied => boolean().withDefault(const Constant(false))();
  TextColumn get currentInvoiceId => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text().nullable().withDefault(const Constant('synced'))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('KotRecordEntry')
class KotRecords extends Table {
  TextColumn get id => text()();
  TextColumn get invoiceId => text()();
  TextColumn get kotNumber => text()();
  TextColumn get orderType => text()();
  TextColumn get tableNumber => text().nullable()();
  TextColumn get itemsJson => text()();
  IntColumn get reprintCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  Int64Column get serverVersion => int64().nullable()();
  TextColumn get syncStatus => text().nullable().withDefault(const Constant('synced'))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SyncCursorEntry')
class SyncCursors extends Table {
  TextColumn get syncEntity => text()(); // e.g. 'global'
  TextColumn get businessId => text()();
  Int64Column get lastServerCursor => int64().nullable()();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();
  TextColumn get status => text().withDefault(const Constant('idle'))();

  @override
  Set<Column> get primaryKey => {syncEntity, businessId};
}

@DataClassName('SyncQueueEntry')
class SyncQueue extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get deviceId => text()();
  TextColumn get syncEntity => text()(); // 'categories', 'products', 'invoices', etc.
  TextColumn get recordId => text()();
  TextColumn get operation => text()(); // 'INSERT', 'UPDATE', 'DELETE'
  Int64Column get clientVersion => int64().nullable()();
  TextColumn get payloadJson => text()();
  TextColumn get idempotencyKey => text()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('pending'))(); // 'pending', 'syncing', 'synced', 'failed'

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SyncConflictEntry')
class SyncConflicts extends Table {
  TextColumn get id => text()();
  TextColumn get syncEntity => text()();
  TextColumn get recordId => text()();
  TextColumn get clientPayloadJson => text()();
  TextColumn get serverPayloadJson => text()();
  TextColumn get resolution => text().withDefault(const Constant('SERVER_WINS'))(); // 'SERVER_WINS', 'CLIENT_WINS', 'MANUAL_REQUIRED'
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
