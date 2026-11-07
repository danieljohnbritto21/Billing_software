import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/app_constants.dart';
import '../../core/database/app_database.dart';
import '../../core/sync/sync_provider.dart';
import '../../core/sync/sync_service.dart';
import 'auth_repository.dart';

class AuthState {
  final UserEntry? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null;
  bool get isAdmin =>
      user != null && (user!.role.toLowerCase() == AppConstants.roleAdmin || user!.role == 'ADMIN');
  bool get isSupplier =>
      user != null &&
      (user!.role.toLowerCase() == AppConstants.roleSupplier ||
          user!.role == 'SUPPLIER' ||
          user!.supplierId != null);
  bool get isCashier =>
      user != null && user!.role.toLowerCase() == AppConstants.roleCashier;

  AuthState copyWith({
    UserEntry? user,
    bool clearUser = false,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;
  final SyncService? _sync;

  AuthNotifier(this._repo, [ApiClient? api, this._sync]) : super(const AuthState()) {
    // Attempt session restoration on startup
    _tryRestoreSession();
  }

  Future<void> _tryRestoreSession() async {
    try {
      final user = await _repo.restoreSession();
      if (user != null) {
        state = state.copyWith(user: user);
        _sync?.syncNow();
      }
    } catch (_) {}
  }

  Future<bool> login(
    String username,
    String password, {
    bool isSupplier = false,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repo.authenticate(
        username,
        password,
        isSupplier: isSupplier,
      );
      if (user != null) {
        state = state.copyWith(user: user, isLoading: false, clearError: true);
        // Automatically trigger sync on login
        _sync?.syncNow();
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: isSupplier
              ? 'Invalid supplier credentials, or supplier account is inactive/unverified.'
              : 'Invalid administrator credentials, or account is disabled.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Login failed: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await _repo.clearSession();
    state = const AuthState();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final api = ref.watch(apiClientProvider);
  final sync = ref.watch(syncServiceProvider);
  return AuthNotifier(repo, api, sync);
});

final currentUserProvider = Provider<UserEntry?>((ref) {
  return ref.watch(authProvider).user;
});

final usersStreamProvider = StreamProvider<List<UserEntry>>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.watchUsers();
});
