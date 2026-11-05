import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/sync/sync_provider.dart';
import '../../core/sync/sync_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/server_connection_dialog.dart';
import '../auth/auth_provider.dart';
import '../categories/category_repository.dart';
import '../products/product_repository.dart';
import 'settings_repository.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _businessNameController;
  late TextEditingController _taglineController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _gstinController;
  late TextEditingController _prefixController;
  late TextEditingController _footerController;

  bool _showNoteOnReceipt = true;
  String _printerWidth = '80mm';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _businessNameController = TextEditingController();
    _taglineController = TextEditingController();
    _addressController = TextEditingController();
    _phoneController = TextEditingController();
    _gstinController = TextEditingController();
    _prefixController = TextEditingController();
    _footerController = TextEditingController();

    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings =
        await ref.read(settingsRepositoryProvider).getAllSettings();
    if (mounted) {
      setState(() {
        _businessNameController.text =
            settings[SettingsRepository.keyBusinessName] ?? '';
        _taglineController.text =
            settings[SettingsRepository.keyTagline] ?? '';
        _addressController.text =
            settings[SettingsRepository.keyAddress] ?? '';
        _phoneController.text =
            settings[SettingsRepository.keyPhone] ?? '';
        _gstinController.text =
            settings[SettingsRepository.keyGstin] ?? '';
        _prefixController.text =
            settings[SettingsRepository.keyInvoicePrefix] ?? 'INV-';
        _footerController.text =
            settings[SettingsRepository.keyReceiptFooter] ?? '';
        _showNoteOnReceipt =
            settings[SettingsRepository.keyShowNoteOnReceipt] != 'false';
        _printerWidth =
            settings[SettingsRepository.keyPrinterWidth] ?? '80mm';
      });
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _taglineController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _gstinController.dispose();
    _prefixController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final repo = ref.read(settingsRepositoryProvider);
      await repo.saveSettings({
        SettingsRepository.keyBusinessName:
            _businessNameController.text.trim(),
        SettingsRepository.keyTagline: _taglineController.text.trim(),
        SettingsRepository.keyAddress: _addressController.text.trim(),
        SettingsRepository.keyPhone: _phoneController.text.trim(),
        SettingsRepository.keyGstin: _gstinController.text.trim(),
        SettingsRepository.keyInvoicePrefix: _prefixController.text.trim(),
        SettingsRepository.keyReceiptFooter: _footerController.text.trim(),
        SettingsRepository.keyShowNoteOnReceipt:
            _showNoteOnReceipt ? 'true' : 'false',
        SettingsRepository.keyPrinterWidth: _printerWidth,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error saving settings: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to sign out from the system?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      ref.read(authProvider.notifier).logout();
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final isCashier = currentUser?.role == AppConstants.roleCashier;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isCashier ? AppTheme.posYellowHeader : Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Text(
          isCashier ? 'Cashier Settings' : 'Settings & Business Profile',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      bottomNavigationBar: isCashier
          ? null // Cashier has read-only store info and logout
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Save Settings',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ),
      body: isCashier ? _cashierSettingsView(context, currentUser) : _adminSettingsView(context),
    );
  }

  Widget _cashierSettingsView(BuildContext context, dynamic currentUser) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Cashier Profile Card
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppTheme.posYellowHeader,
                  child: const Icon(Icons.person, size: 30, color: Color(0xFF1E293B)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentUser?.fullName ?? 'Cashier',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${currentUser?.username ?? 'cashier'}  •  Role: Cashier',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Store Details (Read-only for cashier)
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.storefront, size: 20, color: Color(0xFFB45309)),
                    SizedBox(width: 8),
                    Text(
                      'Store Information',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(height: 20),
                _infoTile('Restaurant Name', _businessNameController.text.isNotEmpty ? _businessNameController.text : 'FoodBill Pro'),
                _infoTile('Address', _addressController.text.isNotEmpty ? _addressController.text : 'Store Address'),
                _infoTile('Phone', _phoneController.text.isNotEmpty ? _phoneController.text : 'Not provided'),
                _infoTile('GSTIN', _gstinController.text.isNotEmpty ? _gstinController.text : 'Not configured'),
                _infoTile('Printer Paper Width', _printerWidth),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Sign Out Button
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFDC2626),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.logout),
          label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          onPressed: () => _handleLogout(context),
        ),
      ],
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _adminSettingsView(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Business Details Section
          const Text(
            'Restaurant / Shop Information',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextFormField(
                    controller: _businessNameController,
                    decoration: const InputDecoration(
                      labelText: 'Business / Restaurant Name *',
                      prefixIcon: Icon(Icons.storefront_outlined),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Business name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _taglineController,
                    decoration: const InputDecoration(
                      labelText: 'Tagline / Subtitle',
                      prefixIcon: Icon(Icons.subtitles_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Contact Phone Number',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _gstinController,
                    decoration: const InputDecoration(
                      labelText: 'GSTIN (GST Identification Number)',
                      prefixIcon: Icon(Icons.receipt_outlined),
                      hintText: 'e.g. 29ABCDE1234F1Z5',
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Receipt Configuration
          const Text(
            'Invoice & Receipt Printing Configuration',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextFormField(
                    controller: _prefixController,
                    decoration: const InputDecoration(
                      labelText: 'Invoice Number Prefix',
                      prefixIcon: Icon(Icons.tag),
                      hintText: 'INV-',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _footerController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Receipt Footer Message',
                      prefixIcon: Icon(Icons.chat_bubble_outline),
                      hintText: 'Thank you for your visit!',
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Show Individual Bill Notes on Receipt'),
                    subtitle: const Text('Display note banner under line items if present'),
                    value: _showNoteOnReceipt,
                    activeColor: AppTheme.primaryGreen,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      setState(() => _showNoteOnReceipt = val);
                    },
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Thermal Printer Paper Width',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      DropdownButton<String>(
                        value: _printerWidth,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(
                            value: '80mm',
                            child: Text('80 mm (Standard POS)'),
                          ),
                          DropdownMenuItem(
                            value: '58mm',
                            child: Text('58 mm (Compact)'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _printerWidth = val);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Server & Multi-Device Synchronization
          const Text(
            'Server & Multi-Device Synchronization',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Consumer(
                builder: (context, ref, _) {
                  final syncState = ref.watch(syncServiceProvider).state;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder<String>(
                        future: ref.read(apiClientProvider).getBaseUrl(),
                        builder: (context, snapshot) {
                          final url = snapshot.data ?? 'Loading...';
                          return Row(
                            children: [
                              const Icon(Icons.cloud_done_rounded, color: AppTheme.primaryGreen, size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Backend Server URL',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      url,
                                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.edit_rounded, size: 16),
                                label: const Text('Configure'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                onPressed: () async {
                                  final updated = await ServerConnectionDialog.show(context);
                                  if (updated == true && context.mounted) {
                                    ref.read(syncServiceProvider).syncNow();
                                  }
                                },
                              ),
                            ],
                          );
                        },
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sync Status: ${syncState.status.name.toUpperCase()}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: syncState.status == SyncStatusType.synced
                                      ? AppTheme.primaryGreen
                                      : (syncState.status == SyncStatusType.error ? Colors.red : AppTheme.textMuted),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Pending Queue: ${syncState.pendingCount} item(s)',
                                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                              ),
                              if (syncState.lastSyncAt != null)
                                Text(
                                  'Last Synced: ${syncState.lastSyncAt!.hour.toString().padLeft(2, '0')}:${syncState.lastSyncAt!.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                ),
                            ],
                          ),
                          ElevatedButton.icon(
                            icon: syncState.status == SyncStatusType.syncing
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                                  )
                                : const Icon(Icons.sync_rounded, size: 16),
                            label: const Text('Sync Now'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                            onPressed: syncState.status == SyncStatusType.syncing
                                ? null
                                : () async {
                                    await ref.read(syncServiceProvider).syncNow();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Synchronization finished!'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  },
                          ),
                        ],
                      ),
                      if (syncState.errorMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Sync Error: ${syncState.errorMessage}',
                          style: const TextStyle(fontSize: 11, color: Colors.red),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Offline Local Database Info
          const Text(
            'Offline Storage & App Info',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.wifi_off, color: AppTheme.primaryGreen, size: 20),
                      SizedBox(width: 8),
                      Text(
                        '100% Offline-First Architecture',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'All your menu items, invoices, bill notes, and payment records are saved securely inside your device\'s local SQLite database. No internet or cloud server is required.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Re-seed Sample Food Items'),
                    onPressed: () async {
                      await ref.read(categoryRepositoryProvider).seedDefaultCategoriesIfEmpty();
                      await ref.read(productRepositoryProvider).seedSampleProductsIfEmpty();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Sample categories and food items checked/restored!'),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
