import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../sync/sync_provider.dart';
import '../theme/app_theme.dart';

class ServerConnectionDialog extends ConsumerStatefulWidget {
  const ServerConnectionDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const ServerConnectionDialog(),
    );
  }

  @override
  ConsumerState<ServerConnectionDialog> createState() =>
      _ServerConnectionDialogState();
}

class _ServerConnectionDialogState
    extends ConsumerState<ServerConnectionDialog> {
  late final TextEditingController _urlController;
  bool _isLoading = true;
  bool _isTesting = false;
  Map<String, dynamic>? _testResult;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
    _loadCurrentUrl();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUrl() async {
    final api = ref.read(apiClientProvider);
    final configured = await api.getConfiguredBaseUrl();
    final effective = await api.getBaseUrl();

    if (mounted) {
      setState(() {
        _urlController.text = configured ?? effective;
        _isLoading = false;
      });
    }
  }

  Future<void> _testConnection() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _testResult = {
          'success': false,
          'error': 'Please enter a server URL to test.',
        };
      });
      return;
    }

    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    final api = ref.read(apiClientProvider);
    final result = await api.testConnection(url);

    if (mounted) {
      setState(() {
        _isTesting = false;
        _testResult = result;
      });
    }
  }

  Future<void> _saveUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Server URL cannot be empty.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final api = ref.read(apiClientProvider);
    await api.setBaseUrl(url);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Server URL saved: $url'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _resetToDefault() async {
    final api = ref.read(apiClientProvider);
    final def = ApiClient.defaultBaseUrl;
    await api.setBaseUrl(def);

    if (mounted) {
      setState(() {
        _urlController.text = def;
        _testResult = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reset to default: $def'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(syncServiceProvider).state;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.cloud_sync_rounded,
                      color: AppTheme.primaryGreen,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Server Connection',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Configure FoodBill Pro backend endpoint',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else ...[
                // Input Field
                TextField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    labelText: 'Backend Base URL',
                    hintText: 'https://demo-api.yourdomain.com/api/v1',
                    prefixIcon: const Icon(Icons.link_rounded),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () => _urlController.clear(),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    helperText: 'For remote testing, use your secure HTTPS URL.',
                  ),
                ),
                const SizedBox(height: 16),

                // Test Connection Button & Result
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: _isTesting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.network_check_rounded, size: 18),
                        label: Text(_isTesting ? 'Testing...' : 'Test Connection'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _isTesting ? null : _testConnection,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _resetToDefault,
                      child: const Text('Reset'),
                    ),
                  ],
                ),

                // Test Result Card
                if (_testResult != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _testResult!['success'] == true
                          ? const Color(0xFFF0FDF4)
                          : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _testResult!['success'] == true
                            ? const Color(0xFF86EFAC)
                            : const Color(0xFFFECACA),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _testResult!['success'] == true
                              ? Icons.check_circle_rounded
                              : Icons.error_outline_rounded,
                          color: _testResult!['success'] == true
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFDC2626),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _testResult!['success'] == true
                                    ? 'Connected Successfully'
                                    : 'Connection Failed',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: _testResult!['success'] == true
                                      ? const Color(0xFF15803D)
                                      : const Color(0xFF991B1B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _testResult!['success'] == true
                                    ? 'Status: ${_testResult!['status']} • DB: ${_testResult!['database']} • Latency: ${_testResult!['latencyMs']}ms'
                                    : '${_testResult!['error']}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),

                // Synchronization Status Summary
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pending Queue: ${syncState.pendingCount} item(s)',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    Text(
                      syncState.lastSyncAt != null
                          ? 'Last Sync: ${_formatTime(syncState.lastSyncAt!)}'
                          : 'Last Sync: Never',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _saveUrl,
                      child: const Text(
                        'Save & Apply',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
