import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/sync/sync_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/server_connection_dialog.dart';
import 'auth_provider.dart';
import 'auth_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSupplierPortal = false;

  @override
  void initState() {
    super.initState();
    // Ensure default initial users (admin and demo supplier) are seeded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authRepositoryProvider).seedInitialUsersIfEmpty();
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    final success = await ref
        .read(authProvider.notifier)
        .login(username, password, isSupplier: _isSupplierPortal);

    if (success && mounted) {
      try {
        ref.read(syncServiceProvider).syncNow();
      } catch (_) {}

      final user = ref.read(authProvider).user;
      final role = user?.role.toLowerCase();
      if (_isSupplierPortal || role == AppConstants.roleSupplier || user?.supplierId != null) {
        context.go('/supplier/dashboard');
      } else if (role == AppConstants.roleAdmin) {
        context.go('/dashboard');
      } else {
        context.go('/billing');
      }
    }
  }

  void _fillCredentials(String username, String password, {bool isSupplier = false}) {
    setState(() {
      _isSupplierPortal = isSupplier;
      _usernameController.text = username;
      _passwordController.text = password;
    });
    ref.read(authProvider.notifier).clearError();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              elevation: 4,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // App Icon / Logo
                      Center(
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _isSupplierPortal
                                  ? [Colors.indigo.shade700, Colors.indigo.shade500]
                                  : [const Color(0xFF2E7D32), const Color(0xFF43A047)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: (_isSupplierPortal ? Colors.indigo : Colors.green).withValues(alpha: 0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Icon(
                            _isSupplierPortal ? Icons.storefront_rounded : Icons.point_of_sale_rounded,
                            size: 38,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Title
                      Center(
                        child: Text(
                          AppConstants.appName,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: Text(
                          _isSupplierPortal
                              ? 'Vendor & Procurement Portal'
                              : 'Fast & Reliable Offline-First Billing',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Portal Toggle Switch (Store Admin vs Supplier Portal)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () {
                                  setState(() {
                                    _isSupplierPortal = false;
                                  });
                                  ref.read(authProvider.notifier).clearError();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: !_isSupplierPortal ? Colors.white : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: !_isSupplierPortal
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.05),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.point_of_sale_rounded,
                                        size: 18,
                                        color: !_isSupplierPortal ? const Color(0xFF2E7D32) : const Color(0xFF64748B),
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          'Store Admin',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: !_isSupplierPortal ? FontWeight.bold : FontWeight.w500,
                                            color: !_isSupplierPortal ? const Color(0xFF1E293B) : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () {
                                  setState(() {
                                    _isSupplierPortal = true;
                                  });
                                  ref.read(authProvider.notifier).clearError();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _isSupplierPortal ? Colors.white : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: _isSupplierPortal
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.05),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.storefront_rounded,
                                        size: 18,
                                        color: _isSupplierPortal ? Colors.indigo : const Color(0xFF64748B),
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          'Supplier Portal',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: _isSupplierPortal ? FontWeight.bold : FontWeight.w500,
                                            color: _isSupplierPortal ? const Color(0xFF1E293B) : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Server Connection Badge / Configurator
                      FutureBuilder<String>(
                        future: ref.watch(apiClientProvider).getBaseUrl(),
                        builder: (context, snapshot) {
                          final currentUrl = snapshot.data ?? 'Checking...';
                          final isRender = currentUrl.contains('onrender.com');

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isRender ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isRender ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.sync_alt_rounded,
                                  size: 16,
                                  color: isRender ? const Color(0xFF059669) : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Server: $currentUrl',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: isRender ? const Color(0xFF065F46) : const Color(0xFF475569),
                                      fontFamily: 'monospace',
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => const ServerConnectionDialog(),
                                    ).then((_) => setState(() {}));
                                  },
                                  borderRadius: BorderRadius.circular(4),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    child: Text(
                                      'Edit',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isRender ? const Color(0xFF059669) : AppTheme.primaryGreen,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // Error Banner
                      if (authState.error != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFCA5A5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: Color(0xFFDC2626),
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  authState.error!,
                                  style: const TextStyle(
                                    color: Color(0xFF991B1B),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Username Field
                      TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: _isSupplierPortal ? 'Supplier Username or Email' : 'Username',
                          hintText: _isSupplierPortal ? 'Enter supplier username' : 'Enter username',
                          prefixIcon: Icon(
                            _isSupplierPortal ? Icons.business_rounded : Icons.person_outline_rounded,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter username';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Enter password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Sign In Button
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: authState.isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isSupplierPortal ? Colors.indigo : AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: authState.isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  _isSupplierPortal ? 'Enter Supplier Portal' : 'Sign In as Admin',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Quick Login Chips for Demo / Testing
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'QUICK DEMO LOGINS',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64748B),
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ActionChip(
                                  avatar: const Icon(
                                    Icons.admin_panel_settings_rounded,
                                    size: 16,
                                    color: Color(0xFF1E293B),
                                  ),
                                  label: const Text('Admin (admin123)'),
                                  backgroundColor: Colors.white,
                                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                                  onPressed: () => _fillCredentials('admin', 'admin123', isSupplier: false),
                                ),
                                ActionChip(
                                  avatar: const Icon(
                                    Icons.storefront_rounded,
                                    size: 16,
                                    color: Colors.indigo,
                                  ),
                                  label: const Text('Supplier (supplier123)'),
                                  backgroundColor: Colors.white,
                                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                                  onPressed: () => _fillCredentials('supplier', 'supplier123', isSupplier: true),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
