import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/database/app_database.dart';
import '../../core/theme/app_theme.dart';
import 'auth_provider.dart';
import 'auth_repository.dart';

class CashiersScreen extends ConsumerStatefulWidget {
  const CashiersScreen({super.key});

  @override
  ConsumerState<CashiersScreen> createState() => _CashiersScreenState();
}

class _CashiersScreenState extends ConsumerState<CashiersScreen> {
  void _showAddCashierDialog() {
    final formKey = GlobalKey<FormState>();
    final usernameController = TextEditingController();
    final fullNameController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedRole = AppConstants.roleCashier;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text(
            'Create User Account',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      hintText: 'e.g. john_pos',
                      prefixIcon: Icon(Icons.account_circle_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Username is required';
                      }
                      if (v.trim().length < 3) {
                        return 'Username must be at least 3 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'e.g. John Doe',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Full name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Initial Password',
                      hintText: 'At least 6 characters',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Password is required';
                      }
                      if (v.length < 4) {
                        return 'Password must be at least 4 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      prefixIcon: Icon(Icons.security_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: AppConstants.roleCashier,
                        child: Text('Cashier (POS Only)'),
                      ),
                      DropdownMenuItem(
                        value: AppConstants.roleAdmin,
                        child: Text('Admin (Full Access)'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedRole = val);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final repo = ref.read(authRepositoryProvider);
                final scaffold = ScaffoldMessenger.of(context);
                try {
                  await repo.createUser(
                    username: usernameController.text.trim(),
                    fullName: fullNameController.text.trim(),
                    password: passwordController.text,
                    role: selectedRole,
                  );
                  if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                  scaffold.showSnackBar(
                    const SnackBar(
                        content: Text('User account created successfully!')),
                  );
                } catch (e) {
                  scaffold.showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditUserDialog(UserEntry user) {
    final formKey = GlobalKey<FormState>();
    final fullNameController = TextEditingController(text: user.fullName);
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(
          'Edit ${user.username}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Full name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Reset Password (optional)',
                  hintText: 'Leave blank to keep current password',
                  prefixIcon: Icon(Icons.lock_reset),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final repo = ref.read(authRepositoryProvider);
              final scaffold = ScaffoldMessenger.of(context);
              try {
                await repo.updateUser(
                  id: user.id,
                  fullName: fullNameController.text.trim(),
                  newPassword: passwordController.text.trim().isEmpty
                      ? null
                      : passwordController.text.trim(),
                );
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                scaffold.showSnackBar(
                  const SnackBar(content: Text('User updated successfully!')),
                );
              } catch (e) {
                scaffold.showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDelete(UserEntry user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: Text(
          'Are you sure you want to delete "${user.fullName} (${user.username})"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final scaffold = ScaffoldMessenger.of(context);
      try {
        await ref.read(authRepositoryProvider).deleteUser(user.id);
        scaffold.showSnackBar(
          const SnackBar(content: Text('User deleted successfully')),
        );
      } catch (e) {
        scaffold.showSnackBar(
          SnackBar(content: Text('Cannot delete: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersStreamProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Staff & Cashier Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            onPressed: _showAddCashierDialog,
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Add Staff'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: usersAsync.when(
        data: (users) {
          if (users.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final u = users[index];
              final isAdmin = u.role == AppConstants.roleAdmin;
              final isCurrent = currentUser?.id == u.id;

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: isCurrent
                        ? AppTheme.primaryGreen
                        : Colors.grey.shade200,
                    width: isCurrent ? 2 : 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: isAdmin
                            ? const Color(0xFF6366F1).withValues(alpha: 0.15)
                            : AppTheme.primaryGreen.withValues(alpha: 0.15),
                        child: Icon(
                          isAdmin
                              ? Icons.admin_panel_settings_rounded
                              : Icons.badge_rounded,
                          color: isAdmin
                              ? const Color(0xFF4F46E5)
                              : AppTheme.primaryGreen,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // User Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  u.fullName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: u.isActive
                                        ? const Color(0xFF1E293B)
                                        : Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (isCurrent)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                          color: Colors.green.shade200),
                                    ),
                                    child: const Text(
                                      'You',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  '@${u.username}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isAdmin
                                        ? const Color(0xFFEEF2FF)
                                        : const Color(0xFFF0FDF4),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    u.role.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isAdmin
                                        ? const Color(0xFF4F46E5)
                                        : AppTheme.primaryGreen,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Active Switch
                      Tooltip(
                        message: u.isActive
                            ? 'Account is active'
                            : 'Account is disabled',
                        child: Switch(
                          value: u.isActive,
                          activeColor: AppTheme.primaryGreen,
                          onChanged: isCurrent
                              ? null // Cannot disable yourself
                              : (val) async {
                                  await ref
                                      .read(authRepositoryProvider)
                                      .updateUser(id: u.id, isActive: val);
                                },
                        ),
                      ),

                      // Actions
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        tooltip: 'Edit details / Reset password',
                        onPressed: () => _showEditUserDialog(u),
                      ),
                      if (!isCurrent)
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red, size: 20),
                          tooltip: 'Delete user',
                          onPressed: () => _handleDelete(u),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
