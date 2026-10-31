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
  /// with seamless offline fallback against local SQLite Users table.
  Future<UserEntry?> authenticate(String username, String password) async {
    final cleanUsername = username.trim().toLowerCase();

    // 1. Try remote API authentication if client is available
    final api = _api;
    if (api != null) {
      try {
        final res = await api.post('/auth/login', body: {
          'username': cleanUsername,
          'password': password,
        });

        if (res is Map<String, dynamic> && res['token'] != null) {
          final token = res['token'].toString();
          final userJson = res['user'] as Map<String, dynamic>;
          final bizId = userJson['businessId'] ?? userJson['business_id'];

          api.setAuthToken(token);
          api.setBusinessId(bizId?.toString());

          // Save auth settings locally
          await _db.into(_db.appSettings).insertOnConflictUpdate(
            AppSettingsCompanion.insert(key: 'auth_token', value: token),
          );
          if (bizId != null) {
            await _db.into(_db.appSettings).insertOnConflictUpdate(
              AppSettingsCompanion.insert(key: 'business_id', value: bizId.toString()),
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
            username: cleanUsername,
            fullName: userJson['fullName'] ?? userJson['full_name'] ?? cleanUsername,
            role: userJson['role'] ?? AppConstants.roleCashier,
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
    final user = await (_db.select(_db.users)
          ..where((u) => u.username.lower().equals(cleanUsername) & u.isActive.equals(true)))
        .getSingleOrNull();

    if (user == null) return null;

    if (_verifyPassword(password, user.passwordHash, user.salt)) {
      return user;
    }
    return null;
  }

  /// Seeds initial default Admin and Cashier accounts if no users exist locally
  Future<void> seedInitialUsersIfEmpty() async {
    final count = await _db.users.count().getSingle();
    if (count == 0) {
      final now = DateTime.now();

      // Default Admin
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

      // Default Cashier
      final cashierSalt = _generateSalt();
      final cashierHash = _hashPassword('cashier123', cashierSalt);
      await _db.into(_db.users).insert(
            UsersCompanion.insert(
              id: _uuid.v4(),
              username: 'cashier',
              fullName: 'Main Cashier',
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

  /// Get all active cashiers
  Future<List<UserEntry>> getActiveCashiers() {
    return (_db.select(_db.users)
          ..where((u) => u.role.equals(AppConstants.roleCashier) & u.isActive.equals(true)))
        .get();
  }

  /// Creates a new user account (Cashier or Admin)
  Future<String> createUser({
    required String username,
    required String fullName,
    required String password,
    required String role,
  }) async {
    final cleanUsername = username.trim().toLowerCase();
    // Check existing
    final existing = await (_db.select(_db.users)
          ..where((u) => u.username.lower().equals(cleanUsername)))
        .getSingleOrNull();

    if (existing != null) {
      throw Exception('Username "$cleanUsername" already exists.');
    }

    final salt = _generateSalt();
    final hash = _hashPassword(password, salt);
    final now = DateTime.now();
    final id = _uuid.v4();

    // If online, also register staff on backend
    final api = _api;
    if (api != null && api.authToken != null) {
      try {
        await api.post('/users', body: {
          'username': cleanUsername,
          'fullName': fullName.trim(),
          'password': password,
          'role': role,
        });
      } catch (_) {
        // Continue local creation
      }
    }

    await _db.into(_db.users).insert(
          UsersCompanion.insert(
            id: id,
            username: cleanUsername,
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

  /// Updates user details or resets password
  Future<void> updateUser({
    required String id,
    String? fullName,
    String? newPassword,
    bool? isActive,
  }) async {
    final user = await (_db.select(_db.users)..where((u) => u.id.equals(id))).getSingleOrNull();
    if (user == null) throw Exception('User not found');

    String? newHash;
    String? newSalt;
    if (newPassword != null && newPassword.trim().isNotEmpty) {
      newSalt = _generateSalt();
      newHash = _hashPassword(newPassword.trim(), newSalt);
    }

    final api = _api;
    if (api != null && api.authToken != null && isActive != null) {
      try {
        await api.put('/users/$id/status', body: {'isActive': isActive});
      } catch (_) {}
    }

    await (_db.update(_db.users)..where((u) => u.id.equals(id))).write(
      UsersCompanion(
        fullName: fullName != null ? Value(fullName.trim()) : const Value.absent(),
        passwordHash: newHash != null ? Value(newHash) : const Value.absent(),
        salt: newSalt != null ? Value(newSalt) : const Value.absent(),
        isActive: isActive != null ? Value(isActive) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Deletes a cashier account safely (ensures at least 1 active admin remains)
  Future<void> deleteUser(String id) async {
    final user = await (_db.select(_db.users)..where((u) => u.id.equals(id))).getSingleOrNull();
    if (user == null) return;

    if (user.role == AppConstants.roleAdmin) {
      final activeAdmins = await (_db.select(_db.users)
            ..where((u) => u.role.equals(AppConstants.roleAdmin) & u.isActive.equals(true)))
          .get();
      if (activeAdmins.length <= 1) {
        throw Exception('Cannot delete the last active administrator.');
      }
    }

    await (_db.delete(_db.users)..where((u) => u.id.equals(id))).go();
  }
}
