import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/api/api_client.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';
import '../../core/sync/sync_provider.dart';
import '../../core/sync/sync_service.dart';

final supplierRepositoryProvider = Provider<SupplierRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final api = ref.watch(apiClientProvider);
  final sync = ref.watch(syncServiceProvider);
  return SupplierRepository(db, api, sync);
});

class SupplierRepository {
  final AppDatabase _db;
  final ApiClient? _api;
  final SyncService? _sync;
  final _uuid = const Uuid();

  SupplierRepository(this._db, [this._api, this._sync]);

  Future<String?> _resolveBusinessId() async {
    final apiBizId = _api?.businessId;
    if (apiBizId != null && apiBizId.isNotEmpty) {
      return apiBizId;
    }
    final setting = await (_db.select(_db.appSettings)
          ..where((s) => s.key.equals('business_id')))
        .getSingleOrNull();
    return setting?.value;
  }

  /// Watch all suppliers for current business
  Stream<List<SupplierEntry>> watchSuppliers({String? searchQuery, bool? onlyActive}) {
    final query = _db.select(_db.suppliers);
    query.where((s) => s.deletedAt.isNull());

    if (onlyActive == true) {
      query.where((s) => s.isActive.equals(true));
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final term = '%${searchQuery.trim().toLowerCase()}%';
      query.where(
        (s) =>
            s.name.lower().like(term) |
            s.contactPerson.lower().like(term) |
            s.phone.lower().like(term) |
            s.email.lower().like(term),
      );
    }

    query.orderBy([
      (s) => OrderingTerm(expression: s.name, mode: OrderingMode.asc),
    ]);

    return query.watch();
  }

  /// Get supplier by ID
  Future<SupplierEntry?> getSupplierById(String id) async {
    return (_db.select(_db.suppliers)..where((s) => s.id.equals(id))).getSingleOrNull();
  }

  /// Fetch suppliers from backend API and hydrate local database
  Future<List<SupplierEntry>> fetchSuppliersFromApi() async {
    final api = _api;
    if (api == null) return [];

    try {
      final res = await api.get('/admin/suppliers');
      final items = res is List ? res : (res is Map && res['data'] is List ? res['data'] : []);
      final list = <SupplierEntry>[];

      for (final raw in items) {
        final item = raw as Map<String, dynamic>;
        final id = item['id'].toString();
        final bizId = item['business_id']?.toString() ?? item['businessId']?.toString() ?? 'biz';

        final entry = SupplierEntry(
          id: id,
          businessId: bizId,
          name: item['name'] ?? '',
          contactPerson: item['contact_person'] ?? item['contactPerson'],
          email: item['email'],
          phone: item['phone'],
          address: item['address'],
          gstin: item['gstin'],
          pan: item['pan'],
          paymentTerms: item['payment_terms'] ?? item['paymentTerms'],
          notes: item['notes'],
          isActive: item['is_active'] ?? item['isActive'] ?? true,
          isVerified: item['is_verified'] ?? item['isVerified'] ?? false,
          createdAt: item['created_at'] != null ? DateTime.parse(item['created_at']) : DateTime.now(),
          updatedAt: item['updated_at'] != null ? DateTime.parse(item['updated_at']) : DateTime.now(),
          deletedAt: item['deleted_at'] != null ? DateTime.parse(item['deleted_at']) : null,
          serverVersion: item['server_version'] != null ? BigInt.tryParse(item['server_version'].toString()) : null,
          syncStatus: 'synced',
        );

        await _db.into(_db.suppliers).insertOnConflictUpdate(
          SuppliersCompanion.insert(
            id: entry.id,
            businessId: entry.businessId,
            name: entry.name,
            contactPerson: Value(entry.contactPerson),
            email: Value(entry.email),
            phone: Value(entry.phone),
            address: Value(entry.address),
            gstin: Value(entry.gstin),
            pan: Value(entry.pan),
            paymentTerms: Value(entry.paymentTerms),
            notes: Value(entry.notes),
            isActive: Value(entry.isActive),
            isVerified: Value(entry.isVerified),
            createdAt: entry.createdAt,
            updatedAt: entry.updatedAt,
            deletedAt: Value(entry.deletedAt),
            serverVersion: Value(entry.serverVersion),
            syncStatus: const Value('synced'),
          ),
        );
        list.add(entry);
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  /// Create new supplier
  Future<String> createSupplier({
    required String name,
    String? contactPerson,
    String? email,
    String? phone,
    String? address,
    String? gstin,
    String? pan,
    String? paymentTerms,
    String? notes,
    String? username,
    String? password,
  }) async {
    final bizId = await _resolveBusinessId() ?? 'biz';
    final id = _uuid.v4();
    final now = DateTime.now();

    final payload = {
      'id': id,
      'name': name.trim(),
      if (contactPerson != null && contactPerson.trim().isNotEmpty) 'contactPerson': contactPerson.trim(),
      if (email != null && email.trim().isNotEmpty) 'email': email.trim().toLowerCase(),
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      if (address != null && address.trim().isNotEmpty) 'address': address.trim(),
      if (gstin != null && gstin.trim().isNotEmpty) 'gstin': gstin.trim().toUpperCase(),
      if (pan != null && pan.trim().isNotEmpty) 'pan': pan.trim().toUpperCase(),
      if (paymentTerms != null && paymentTerms.trim().isNotEmpty) 'paymentTerms': paymentTerms.trim(),
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      if (username != null && username.trim().isNotEmpty) 'username': username.trim().toLowerCase(),
      if (password != null && password.isNotEmpty) 'password': password,
    };

    // If online, post to backend
    final api = _api;
    bool synced = false;
    if (api != null && api.authToken != null) {
      try {
        await api.post('/admin/suppliers', body: payload);
        synced = true;
      } catch (_) {}
    }

    await _db.into(_db.suppliers).insert(
      SuppliersCompanion.insert(
        id: id,
        businessId: bizId,
        name: name.trim(),
        contactPerson: Value(contactPerson?.trim()),
        email: Value(email?.trim().toLowerCase()),
        phone: Value(phone?.trim()),
        address: Value(address?.trim()),
        gstin: Value(gstin?.trim().toUpperCase()),
        pan: Value(pan?.trim().toUpperCase()),
        paymentTerms: Value(paymentTerms?.trim()),
        notes: Value(notes?.trim()),
        isActive: const Value(true),
        isVerified: const Value(false),
        createdAt: now,
        updatedAt: now,
        syncStatus: Value(synced ? 'synced' : 'pending'),
      ),
    );

    if (!synced) {
      await _sync?.enqueueChange(
        entityName: 'suppliers',
        recordId: id,
        operation: 'INSERT',
        payload: payload,
      );
    }

    return id;
  }

  /// Update supplier details
  Future<void> updateSupplier({
    required String id,
    required String name,
    String? contactPerson,
    String? email,
    String? phone,
    String? address,
    String? gstin,
    String? pan,
    String? paymentTerms,
    String? notes,
  }) async {
    final now = DateTime.now();

    final payload = {
      'name': name.trim(),
      if (contactPerson != null) 'contactPerson': contactPerson.trim(),
      if (email != null) 'email': email.trim().toLowerCase(),
      if (phone != null) 'phone': phone.trim(),
      if (address != null) 'address': address.trim(),
      if (gstin != null) 'gstin': gstin.trim().toUpperCase(),
      if (pan != null) 'pan': pan.trim().toUpperCase(),
      if (paymentTerms != null) 'paymentTerms': paymentTerms.trim(),
      if (notes != null) 'notes': notes.trim(),
    };

    final api = _api;
    bool synced = false;
    if (api != null && api.authToken != null) {
      try {
        await api.put('/admin/suppliers/$id', body: payload);
        synced = true;
      } catch (_) {}
    }

    await (_db.update(_db.suppliers)..where((s) => s.id.equals(id))).write(
      SuppliersCompanion(
        name: Value(name.trim()),
        contactPerson: Value(contactPerson?.trim()),
        email: Value(email?.trim().toLowerCase()),
        phone: Value(phone?.trim()),
        address: Value(address?.trim()),
        gstin: Value(gstin?.trim().toUpperCase()),
        pan: Value(pan?.trim().toUpperCase()),
        paymentTerms: Value(paymentTerms?.trim()),
        notes: Value(notes?.trim()),
        updatedAt: Value(now),
        syncStatus: Value(synced ? 'synced' : 'pending'),
      ),
    );

    if (!synced) {
      await _sync?.enqueueChange(
        entityName: 'suppliers',
        recordId: id,
        operation: 'UPDATE',
        payload: payload,
      );
    }
  }

  /// Update supplier activation or verification status
  Future<void> updateSupplierStatus({
    required String id,
    bool? isActive,
    bool? isVerified,
  }) async {
    final payload = {
      if (isActive != null) 'isActive': isActive,
      if (isVerified != null) 'isVerified': isVerified,
    };

    final api = _api;
    if (api != null && api.authToken != null) {
      try {
        await api.patch('/admin/suppliers/$id/status', body: payload);
      } catch (_) {}
    }

    await (_db.update(_db.suppliers)..where((s) => s.id.equals(id))).write(
      SuppliersCompanion(
        isActive: isActive != null ? Value(isActive) : const Value.absent(),
        isVerified: isVerified != null ? Value(isVerified) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Supplier self-service: Get profile
  Future<Map<String, dynamic>?> getSupplierProfile() async {
    final api = _api;
    if (api == null || api.authToken == null) return null;
    try {
      final res = await api.get('/supplier/profile');
      if (res is Map<String, dynamic>) {
        return res;
      }
    } catch (_) {}
    return null;
  }

  /// Supplier self-service: Update profile
  Future<void> updateSupplierProfile({
    required String name,
    String? contactPerson,
    String? phone,
    String? address,
  }) async {
    final api = _api;
    if (api == null || api.authToken == null) return;
    await api.put('/supplier/profile', body: {
      'name': name.trim(),
      if (contactPerson != null) 'contactPerson': contactPerson.trim(),
      if (phone != null) 'phone': phone.trim(),
      if (address != null) 'address': address.trim(),
    });
  }
}

final suppliersStreamProvider = StreamProvider<List<SupplierEntry>>((ref) {
  final repo = ref.watch(supplierRepositoryProvider);
  return repo.watchSuppliers(onlyActive: false);
});

final activeSuppliersProvider = StreamProvider<List<SupplierEntry>>((ref) {
  final repo = ref.watch(supplierRepositoryProvider);
  return repo.watchSuppliers(onlyActive: true);
});
