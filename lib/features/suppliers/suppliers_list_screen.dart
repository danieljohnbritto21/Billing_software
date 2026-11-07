import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/database/app_database.dart';
import '../../core/theme/app_theme.dart';
import 'supplier_repository.dart';

final supplierSearchQueryProvider = StateProvider<String>((ref) => '');
final supplierFilterActiveProvider = StateProvider<bool?>((ref) => null);

class SuppliersListScreen extends ConsumerStatefulWidget {
  const SuppliersListScreen({super.key});

  @override
  ConsumerState<SuppliersListScreen> createState() => _SuppliersListScreenState();
}

class _SuppliersListScreenState extends ConsumerState<SuppliersListScreen> {
  @override
  void initState() {
    super.initState();
    // Hydrate latest suppliers from backend if online
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(supplierRepositoryProvider).fetchSuppliersFromApi();
    });
  }

  @override
  Widget build(BuildContext context) {
    final search = ref.watch(supplierSearchQueryProvider);
    final onlyActive = ref.watch(supplierFilterActiveProvider);
    final repo = ref.watch(supplierRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suppliers & Vendors'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Suppliers',
            onPressed: () async {
              final count = await repo.fetchSuppliersFromApi();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Refreshed ${count.length} suppliers from server.')),
                );
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add Supplier'),
        onPressed: () => context.push('/suppliers/add'),
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by vendor name, contact, phone, GSTIN...',
                      prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
                      suffixIcon: search.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () =>
                                  ref.read(supplierSearchQueryProvider.notifier).state = '',
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    ),
                    onChanged: (val) {
                      ref.read(supplierSearchQueryProvider.notifier).state = val;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Active Only'),
                  selected: onlyActive == true,
                  onSelected: (selected) {
                    ref.read(supplierFilterActiveProvider.notifier).state =
                        selected ? true : null;
                  },
                ),
              ],
            ),
          ),

          // Suppliers List
          Expanded(
            child: StreamBuilder<List<SupplierEntry>>(
              stream: repo.watchSuppliers(searchQuery: search, onlyActive: onlyActive),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final suppliers = snapshot.data ?? [];

                if (suppliers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.store_mall_directory_outlined,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          search.isNotEmpty
                              ? 'No suppliers match "$search"'
                              : 'No suppliers registered yet',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tap + Add Supplier to register your first product vendor.',
                          style: TextStyle(color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: suppliers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final s = suppliers[index];
                    return _SupplierCard(supplier: s);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SupplierCard extends ConsumerWidget {
  final SupplierEntry supplier;

  const _SupplierCard({required this.supplier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: supplier.isActive ? const Color(0xFFE2E8F0) : Colors.red.shade200,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/suppliers/detail/${supplier.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              CircleAvatar(
                backgroundColor: supplier.isActive
                    ? AppTheme.primaryGreen.withValues(alpha: 0.12)
                    : Colors.grey.shade200,
                radius: 24,
                child: Icon(
                  Icons.storefront_rounded,
                  color: supplier.isActive ? AppTheme.primaryGreen : Colors.grey,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            supplier.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        if (supplier.isVerified)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified, size: 14, color: Colors.blue.shade700),
                                const SizedBox(width: 4),
                                Text(
                                  'Verified',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: supplier.isActive ? Colors.green.shade50 : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            supplier.isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: supplier.isActive ? Colors.green.shade700 : Colors.red.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (supplier.contactPerson != null && supplier.contactPerson!.isNotEmpty)
                      Text(
                        'Contact: ${supplier.contactPerson!}',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                      ),
                    Row(
                      children: [
                        if (supplier.phone != null && supplier.phone!.isNotEmpty) ...[
                          const Icon(Icons.phone_outlined, size: 14, color: AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Text(supplier.phone!, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                          const SizedBox(width: 12),
                        ],
                        if (supplier.gstin != null && supplier.gstin!.isNotEmpty) ...[
                          const Icon(Icons.receipt_outlined, size: 14, color: AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Text('GST: ${supplier.gstin!}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}
