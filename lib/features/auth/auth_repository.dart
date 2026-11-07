import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/api/api_client.dart';
import '../../core/api/device_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';
import '../../core/sync/sync_provider.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final api = ref.watch(apiClientProvider);
  final deviceService = ref.watch(deviceServiceProvider);
  return AuthRepository(db, api, deviceService);
});

class AuthRepository {
  final AppDatabase _db;
  final ApiClient? _api;
  final DeviceService? _deviceService;
  final _uuid = const Uuid();

  AuthRepository(this._db, [this._api, this._deviceService]);

  /// Generates a secure random 16-byte salt represented as a hex string
  String _generateSalt() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    return values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Hashes password with salt using SHA-256
  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verifies password against stored hash and salt
  bool _verifyPassword(String password, String hash, String salt) {
    return _hashPassword(password, salt) == hash;
  }

  /// Authenticates user against the remote REST API when connected,
  /// supporting both Admin (/auth/login) and Supplier (/auth/supplier-login) workflows.
  Future<UserEntry?> authenticate(
    String username,
    String password, {
    bool isSupplier = false,
  }) async {
    final cleanUsername = username.trim().toLowerCase();

    // 1. Try remote API authentication if client is available
    final api = _api;
    if (api != null) {
      try {
        final devUid = await _deviceService?.getOrGenerateDeviceUid();
        final devName = await _deviceService?.getDeviceName();

        final endpoint = isSupplier ? '/auth/supplier-login' : '/auth/login';
        final res = await api.post(endpoint, body: {
          'username': cleanUsername,
          'password': password,
          if (devUid != null) 'deviceUid': devUid,
          if (devName != null) 'deviceName': devName,
        });

        if (res is Map<String, dynamic> && res['token'] != null) {
          final token = res['token'].toString();
          final userJson = res['user'] as Map<String, dynamic>;
          final bizJson = res['business'] as Map<String, dynamic>?;
          final bizId = bizJson?['id']?.toString() ??
              userJson['businessId']?.toString() ??
              userJson['business_id']?.toString();
          final devId = res['deviceId']?.toString();
          final suppId = res['supplierId']?.toString() ??
              userJson['supplierId']?.toString() ??
              userJson['supplier_id']?.toString();

          final rawRole = (userJson['role'] ?? (isSupplier ? 'SUPPLIER' : 'ADMIN')).toString().toLowerCase();

          // Reject legacy cashier or inactive accounts
          if (rawRole == AppConstants.roleCashier || rawRole == 'cashier_legacy') {
            throw ApiException(403, 'Cashier access is deactivated. Please contact your administrator.');
          }

          final normalizedRole = isSupplier || rawRole == 'supplier'
              ? AppConstants.roleSupplier
              : AppConstants.roleAdmin;

          api.setAuthToken(token);
          if (bizId != null) api.setBusinessId(bizId);
          if (devId != null) api.setDeviceId(devId);
          if (suppId != null) api.setSupplierId(suppId);

          // Save auth settings locally
          await _db.into(_db.appSettings).insertOnConflictUpdate(
            AppSettingsCompanion.insert(key: 'auth_token', value: token),
          );
          if (bizId != null) {
            await _db.into(_db.appSettings).insertOnConflictUpdate(
              AppSettingsCompanion.insert(key: 'business_id', value: bizId),
            );
          }
          if (devId != null) {
            await _db.into(_db.appSettings).insertOnConflictUpdate(
              AppSettingsCompanion.insert(key: 'device_id', value: devId),
            );
          }
          if (suppId != null) {
            await _db.into(_db.appSettings).insertOnConflictUpdate(
              AppSettingsCompanion.insert(key: 'supplier_id', value: suppId),
            );
          }

          // Register physical device with backend
          final devService = _deviceService;
          if (devService != null) {
            await devService.registerDevice();
          }

          // Sync credentials locally for offline continuity
          final salt = _generateSalt();
          final hash = _hashPassword(password, salt);
          final now = DateTime.now();

          final localUser = UserEntry(
            id: userJson['id'] ?? _uuid.v4(),
            businessId: bizId?.toString(),
            supplierId: suppId,
            username: cleanUsername,
            fullName: userJson['fullName'] ?? userJson['full_name'] ?? cleanUsername,
            role: normalizedRole,
            passwordHash: hash,
            salt: salt,
            isActive: true,
            createdAt: now,
            updatedAt: now,
          );

          await _db.into(_db.users).insertOnConflictUpdate(
            UsersCompanion.insert(
              id: localUser.id,
              username: localUser.username,
              fullName: localUser.fullName,
              role: localUser.role,
              passwordHash: localUser.passwordHash,
              salt: localUser.salt,
              isActive: const Value(true),
              createdAt: localUser.createdAt,
              updatedAt: localUser.updatedAt,
              businessId: Value(localUser.businessId),
              supplierId: Value(localUser.supplierId),
            ),
          );

          return localUser;
        }
      } on ApiException catch (e) {
        if (e.statusCode == 401 || e.statusCode == 400 || e.statusCode == 403) {
          // Explicitly rejected by server
          return null;
        }
      } on NetworkException {
        // Offline: continue to local authentication
      } catch (_) {
        // Other network errors: fallback to local
      }
    }

    // 2. Offline fallback: Authenticate against local Users table
    final query = _db.select(_db.users)
      ..where((u) {
        final baseFilter = u.username.lower().equals(cleanUsername) & u.isActive.equals(true);
        if (isSupplier) {
          return baseFilter & (u.role.lower().equals(AppConstants.roleSupplier) | u.supplierId.isNotNull());
        } else {
          return baseFilter & u.role.equals(AppConstants.roleSupplier).not() & u.role.equals('cashier_legacy').not();
        }
      });
    final user = await query.getSingleOrNull();

    if (user == null) return null;

    if (_verifyPassword(password, user.passwordHash, user.salt)) {
      if (api != null) {
        await api.restoreSavedAuth();
        if (user.supplierId != null) {
          api.setSupplierId(user.supplierId);
          await _db.into(_db.appSettings).insertOnConflictUpdate(
            AppSettingsCompanion.insert(key: 'supplier_id', value: user.supplierId!),
          );
        }
      }
      return user;
    }
    return null;
  }

  /// Restores active session from backend using stored token
  Future<UserEntry?> restoreSession() async {
    final api = _api;
    if (api == null) return null;

    await api.restoreSavedAuth();
    if (api.authToken == null || api.authToken!.isEmpty) return null;

    try {
      final res = await api.get('/auth/me');
      if (res is Map<String, dynamic> && res['user'] != null) {
        final userJson = res['user'] as Map<String, dynamic>;
        final rawRole = (userJson['role'] ?? 'ADMIN').toString().toLowerCase();

        if (rawRole == AppConstants.roleCashier || rawRole == 'cashier_legacy') {
          await clearSession();
          return null;
        }

        final suppId = res['supplierId']?.toString() ??
            userJson['supplierId']?.toString() ??
            userJson['supplier_id']?.toString();

        final localUser = await (_db.select(_db.users)
              ..where((u) => u.username.lower().equals(userJson['username'].toString().toLowerCase())))
            .getSingleOrNull();

        if (localUser != null) {
          return localUser;
        }

        final now = DateTime.now();
        return UserEntry(
          id: userJson['id'] ?? _uuid.v4(),
          businessId: userJson['businessId'] ?? userJson['business_id'],
          supplierId: suppId,
          username: userJson['username'],
          fullName: userJson['fullName'] ?? userJson['full_name'] ?? userJson['username'],
          role: rawRole == 'supplier' ? AppConstants.roleSupplier : AppConstants.roleAdmin,
          passwordHash: '',
          salt: '',
          isActive: true,
          createdAt: now,
          updatedAt: now,
        );
      }
    } catch (_) {}

    return null;
  }

  /// Clears stored user session and tokens on logout
  Future<void> clearSession() async {
    try {
      if (_api?.authToken != null) {
        await _api?.post('/auth/logout').catchError((_) => null);
      }
    } catch (_) {}

    _api?.setAuthToken(null);
    _api?.setBusinessId(null);
    _api?.setDeviceId(null);
    _api?.setSupplierId(null);

    await (_db.delete(_db.appSettings)
          ..where((s) => s.key.isIn(['auth_token', 'business_id', 'device_id', 'supplier_id'])))
        .go();
  }

  /// Seeds initial default Admin and Demo Supplier accounts if no users exist locally
  Future<void> seedInitialUsersIfEmpty() async {
    final now = DateTime.now();

    // 1. Ensure default Admin user exists
    final adminUser = await (_db.select(_db.users)..where((u) => u.username.equals('admin'))).getSingleOrNull();
    if (adminUser == null) {
      final adminSalt = _generateSalt();
      final adminHash = _hashPassword('admin123', adminSalt);
      await _db.into(_db.users).insert(
            UsersCompanion.insert(
              id: _uuid.v4(),
              username: 'admin',
              fullName: 'Store Administrator',
              role: AppConstants.roleAdmin,
              passwordHash: adminHash,
              salt: adminSalt,
              isActive: const Value(true),
              createdAt: now,
              updatedAt: now,
            ),
          );
    }

    // 2. Ensure demo Supplier profile & user account exists for offline portal access
    const demoSupplierId = 'demo-supplier-01';
    final existingSupplier = await (_db.select(_db.suppliers)..where((s) => s.id.equals(demoSupplierId))).getSingleOrNull();
    if (existingSupplier == null) {
      await _db.into(_db.suppliers).insert(
            SuppliersCompanion.insert(
              id: demoSupplierId,
              businessId: 'demo-biz-01',
              name: 'Apex Quality Foods & Beverages',
              contactPerson: const Value('Rajesh Kumar'),
              phone: const Value('+91 98765 43210'),
              email: const Value('supplier@apexfoods.in'),
              isActive: const Value(true),
              isVerified: const Value(true),
              createdAt: now,
              updatedAt: now,
            ),
          );
    } else if (!existingSupplier.isActive || !existingSupplier.isVerified) {
      await (_db.update(_db.suppliers)..where((s) => s.id.equals(demoSupplierId))).write(
        const SuppliersCompanion(
          isActive: Value(true),
          isVerified: Value(true),
        ),
      );
    }

    final supplierUser = await (_db.select(_db.users)..where((u) => u.username.equals('supplier'))).getSingleOrNull();
    if (supplierUser == null) {
      final supplierSalt = _generateSalt();
      final supplierHash = _hashPassword('supplier123', supplierSalt);
      await _db.into(_db.users).insert(
            UsersCompanion.insert(
              id: _uuid.v4(),
              username: 'supplier',
              fullName: 'Rajesh Kumar (Apex Foods)',
              role: AppConstants.roleSupplier,
              supplierId: const Value(demoSupplierId),
              passwordHash: supplierHash,
              salt: supplierSalt,
              isActive: const Value(true),
              createdAt: now,
              updatedAt: now,
            ),
          );
    } else if (supplierUser.role != AppConstants.roleSupplier ||
               supplierUser.supplierId != demoSupplierId ||
               !supplierUser.isActive ||
               !_verifyPassword('supplier123', supplierUser.passwordHash, supplierUser.salt)) {
      final supplierSalt = _generateSalt();
      final supplierHash = _hashPassword('supplier123', supplierSalt);
      await (_db.update(_db.users)..where((u) => u.id.equals(supplierUser.id))).write(
        UsersCompanion(
          role: const Value(AppConstants.roleSupplier),
          supplierId: const Value(demoSupplierId),
          isActive: const Value(true),
          salt: Value(supplierSalt),
          passwordHash: Value(supplierHash),
        ),
      );
    }

    // 3. Ensure default Cashier user exists (legacy continuity)
    final cashierUser = await (_db.select(_db.users)..where((u) => u.username.equals('cashier'))).getSingleOrNull();
    if (cashierUser == null) {
      final cashierSalt = _generateSalt();
      final cashierHash = _hashPassword('cashier123', cashierSalt);
      await _db.into(_db.users).insert(
            UsersCompanion.insert(
              id: _uuid.v4(),
              username: 'cashier',
              fullName: 'Store Cashier',
              role: AppConstants.roleCashier,
              passwordHash: cashierHash,
              salt: cashierSalt,
              isActive: const Value(true),
              createdAt: now,
              updatedAt: now,
            ),
          );
    }
  }

  /// Watch all users (admin only)
  Stream<List<UserEntry>> watchUsers() {
    return (_db.select(_db.users)
          ..orderBy([
            (u) => OrderingTerm(expression: u.role, mode: OrderingMode.asc),
            (u) => OrderingTerm(expression: u.fullName, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  /// Create user account locally
  Future<String> createUser({
    required String username,
    required String fullName,
    required String password,
    required String role,
  }) async {
    final salt = _generateSalt();
    final hash = _hashPassword(password, salt);
    final id = _uuid.v4();
    final now = DateTime.now();

    await _db.into(_db.users).insert(
      UsersCompanion.insert(
        id: id,
        username: username.trim().toLowerCase(),
        fullName: fullName.trim(),
        role: role,
        passwordHash: hash,
        salt: salt,
        isActive: const Value(true),
        createdAt: now,
        updatedAt: now,
      ),
    );
    return id;
  }

  /// Update user account locally
  Future<void> updateUser({
    required String id,
    String? fullName,
    String? password,
    String? newPassword,
    bool? isActive,
  }) async {
    final user = await (_db.select(_db.users)..where((u) => u.id.equals(id))).getSingleOrNull();
    if (user == null) return;

    final now = DateTime.now();
    UsersCompanion companion = UsersCompanion(updatedAt: Value(now));

    if (fullName != null) {
      companion = companion.copyWith(fullName: Value(fullName.trim()));
    }
    if (isActive != null) {
      companion = companion.copyWith(isActive: Value(isActive));
    }
    final effectivePassword = newPassword ?? password;
    if (effectivePassword != null && effectivePassword.isNotEmpty) {
      final salt = _generateSalt();
      final hash = _hashPassword(effectivePassword, salt);
      companion = companion.copyWith(
        salt: Value(salt),
        passwordHash: Value(hash),
      );
    }

    await (_db.update(_db.users)..where((u) => u.id.equals(id))).write(companion);
  }

  /// Delete user account locally
  Future<void> deleteUser(String id) async {
    final user = await (_db.select(_db.users)..where((u) => u.id.equals(id))).getSingleOrNull();
    if (user != null && user.role == AppConstants.roleAdmin) {
      throw Exception('Cannot delete primary Admin account');
    }
    await (_db.delete(_db.users)..where((u) => u.id.equals(id))).go();
  }
}
