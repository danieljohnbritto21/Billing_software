import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/sync/sync_provider.dart';
import '../../core/sync/sync_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../categories/category_repository.dart';
import 'product_repository.dart';

final productSearchProvider = StateProvider<String>((ref) => '');
final selectedCategoryFilterProvider = StateProvider<String>((ref) => 'ALL');

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-sync on screen open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        ref.read(syncServiceProvider).syncNow();
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final search = ref.watch(productSearchProvider);
    final selectedCategory = ref.watch(selectedCategoryFilterProvider);
    final productRepo = ref.watch(productRepositoryProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final syncState = ref.watch(syncStateProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products & Menu'),
        actions: [
          // Live Sync Status Icon & Manual Sync Trigger
          IconButton(
            tooltip: syncState?.status == SyncStatusType.syncing
                ? 'Syncing in progress...'
                : syncState?.status == SyncStatusType.offline
                    ? 'Offline mode (Tap to sync)'
                    : 'Synced with server (Tap to sync)',
            icon: syncState?.status == SyncStatusType.syncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryGreen,
                    ),
                  )
                : Icon(
                    syncState?.status == SyncStatusType.offline
                        ? Icons.cloud_off_outlined
                        : syncState?.status == SyncStatusType.error
                            ? Icons.sync_problem_outlined
                            : Icons.cloud_done_outlined,
                    color: syncState?.status == SyncStatusType.offline
                        ? Colors.amber.shade700
                        : syncState?.status == SyncStatusType.error
                            ? Colors.red.shade600
                            : AppTheme.primaryGreen,
                    size: 22,
                  ),
            onPressed: () => ref.read(syncServiceProvider).syncNow(),
          ),
          IconButton(
            icon: const Icon(Icons.category_outlined),
            tooltip: 'Manage Categories',
            onPressed: () => context.push('/categories'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by food name, code, or SKU...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
                suffixIcon: search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () =>
                            ref.read(productSearchProvider.notifier).state = '',
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
              onChanged: (val) {
                ref.read(productSearchProvider.notifier).state = val;
              },
            ),
          ),

          // Categories Filter Horizontal List
          categoriesAsync.when(
            data: (categories) {
              return SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('All Items'),
                        selected: selectedCategory == 'ALL',
                        onSelected: (_) => ref
                            .read(selectedCategoryFilterProvider.notifier)
                            .state = 'ALL',
                        selectedColor: const Color(0xFFDCFCE7),
                        checkmarkColor: AppTheme.primaryGreen,
                        labelStyle: TextStyle(
                          color: selectedCategory == 'ALL'
                              ? AppTheme.primaryGreen
                              : AppTheme.textDark,
                          fontWeight: selectedCategory == 'ALL'
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    ...categories.map((cat) {
                      final isSelected = selectedCategory == cat.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(cat.name),
                          selected: isSelected,
                          onSelected: (_) => ref
                              .read(selectedCategoryFilterProvider.notifier)
                              .state = cat.id,
                          selectedColor: const Color(0xFFDCFCE7),
                          checkmarkColor: AppTheme.primaryGreen,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? AppTheme.primaryGreen
                                : AppTheme.textDark,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
            loading: () => const SizedBox(height: 48),
            error: (_, __) => const SizedBox(height: 48),
          ),

          const SizedBox(height: 4),

          // Products List with Pull-to-Refresh
          Expanded(
            child: RefreshIndicator(
              color: AppTheme.primaryGreen,
              onRefresh: () => ref.read(syncServiceProvider).syncNow(),
              child: StreamBuilder<List<ProductWithCategory>>(
                stream: productRepo.watchProducts(
                  searchQuery: search,
                  categoryId: selectedCategory,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final items = snapshot.data ?? [];

                  if (items.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(32),
                      children: [
                        const SizedBox(height: 48),
                        Icon(Icons.inventory_2_outlined,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Center(
                          child: Text(
                            'No Products Found',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            search.isNotEmpty
                                ? 'No food items match "$search"'
                                : 'Food items are created and managed by Cashier at the counter.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppTheme.textMuted),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: OutlinedButton.icon(
                            onPressed: () => context.push('/categories'),
                            icon: const Icon(Icons.category_outlined),
                            label: const Text('Manage Categories'),
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final p = item.product;
                      final sellingPriceFormatted =
                          CurrencyFormatter.formatPaise(p.sellingPricePaise);
                      final costPriceFormatted =
                          CurrencyFormatter.formatPaise(p.costPricePaise);

                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(
                              color: AppTheme.borderLight, width: 1),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Product Image Thumbnail or Placeholder
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  color: Colors.green.shade50,
                                  child: item.primaryImage != null
                                      ? Image.memory(
                                          item.primaryImage!.imageBytes,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              _placeholderIcon(),
                                        )
                                      : _placeholderIcon(),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Product Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            p.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: AppTheme.textDark,
                                            ),
                                          ),
                                        ),
                                        if (!p.isAvailable)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.red.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Unavailable',
                                              style: TextStyle(
                                                color: Colors.red.shade700,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      [
                                        if (item.category != null)
                                          item.category!.name,
                                        if (p.code != null &&
                                            p.code!.isNotEmpty)
                                          'Code: ${p.code}',
                                        'GST ${p.gstRatePercent}% ${p.isTaxInclusive ? "(Incl)" : "(Excl)"}',
                                      ].join('  •  '),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        Text(
                                          'Sell: $sellingPriceFormatted / ${p.unit}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primaryGreen,
                                          ),
                                        ),
                                        if (p.costPricePaise > 0)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.blueGrey.shade50,
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: Colors.blueGrey.shade200),
                                            ),
                                            child: Text(
                                              'Cost: $costPriceFormatted',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.blueGrey.shade700,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderIcon() {
    return Center(
      child: Icon(
        Icons.restaurant_menu,
        color: Colors.green.shade400,
        size: 26,
      ),
    );
  }
}
