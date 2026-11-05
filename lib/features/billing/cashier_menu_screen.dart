import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/database/app_database.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../auth/auth_provider.dart';
import '../categories/category_repository.dart';
import '../invoices/invoice_repository.dart';
import '../products/product_repository.dart';
import '../settings/settings_repository.dart';
import '../../core/sync/sync_provider.dart';
import '../../core/sync/sync_service.dart';
import 'cart_provider.dart';

final selectedPosCategoryProvider = StateProvider<String>((ref) => 'ALL');
final posSearchQueryProvider = StateProvider<String>((ref) => '');

class CashierMenuScreen extends ConsumerStatefulWidget {
  const CashierMenuScreen({super.key});

  @override
  ConsumerState<CashierMenuScreen> createState() => _CashierMenuScreenState();
}

class _CashierMenuScreenState extends ConsumerState<CashierMenuScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        ref.read(syncServiceProvider).syncNow();
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsStreamProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final selectedCategory = ref.watch(selectedPosCategoryProvider);
    final searchQuery = ref.watch(posSearchQueryProvider);
    final cart = ref.watch(cartProvider);
    final currentUser = ref.watch(currentUserProvider);
    final syncState = ref.watch(syncStateProvider).value;

    final restaurantName = settingsAsync.value?['business_name'] ?? 'FoodBill Pro';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // 1. YELLOW HEADER (Reference Image 01)
            Container(
              decoration: const BoxDecoration(
                color: AppTheme.posYellowHeader,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Logo, Restaurant Name & Cart Icon
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.restaurant_rounded,
                            color: Color(0xFFB45309),
                            size: 26,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              restaurantName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E293B),
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Cashier: ${currentUser?.fullName ?? 'Counter'}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF78350F),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Clearly visible + Add Product Button for Cashier
                      ElevatedButton.icon(
                        onPressed: () => context.push('/products/add'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B),
                          foregroundColor: Colors.white,
                          elevation: 1,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.add, size: 16, color: AppTheme.posYellowHeader),
                        label: const Text(
                          '+ Add Product',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Live Sync Status Button
                      IconButton(
                        tooltip: syncState?.status == SyncStatusType.syncing
                            ? 'Syncing in progress...'
                            : syncState?.status == SyncStatusType.offline
                                ? 'Offline mode (Tap to sync)'
                                : 'Synced with server (Tap to sync)',
                        icon: syncState?.status == SyncStatusType.syncing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF78350F),
                                ),
                              )
                            : Icon(
                                syncState?.status == SyncStatusType.offline
                                    ? Icons.cloud_off_outlined
                                    : syncState?.status == SyncStatusType.error
                                        ? Icons.sync_problem_outlined
                                        : Icons.cloud_done_outlined,
                                color: syncState?.status == SyncStatusType.offline
                                    ? Colors.amber.shade900
                                    : syncState?.status == SyncStatusType.error
                                        ? Colors.red.shade700
                                        : const Color(0xFF166534),
                                size: 20,
                              ),
                        onPressed: () => ref.read(syncServiceProvider).syncNow(),
                      ),
                      const SizedBox(width: 4),
                      // Cart Quick Button
                      InkWell(
                        onTap: () => context.go('/cart'),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.shopping_bag_outlined,
                                color: Color(0xFFB45309),
                                size: 20,
                              ),
                              if (cart.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDC2626),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${cart.items.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Order Type Selector Row: Dine In / Takeaway / Delivery
                  Row(
                    children: [
                      _orderTypeChip(
                        ref: ref,
                        label: AppConstants.orderTypeDineIn,
                        icon: Icons.table_restaurant_outlined,
                        isSelected: cart.orderType == AppConstants.orderTypeDineIn,
                        onTap: () {
                          ref.read(cartProvider.notifier).setOrderType(AppConstants.orderTypeDineIn);
                          if (cart.tableNumber == null) {
                            _showTablePicker(context, ref);
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      _orderTypeChip(
                        ref: ref,
                        label: AppConstants.orderTypeTakeaway,
                        icon: Icons.takeout_dining_outlined,
                        isSelected: cart.orderType == AppConstants.orderTypeTakeaway,
                        onTap: () {
                          ref.read(cartProvider.notifier).setOrderType(AppConstants.orderTypeTakeaway);
                        },
                      ),
                      const SizedBox(width: 8),
                      _orderTypeChip(
                        ref: ref,
                        label: AppConstants.orderTypeDelivery,
                        icon: Icons.delivery_dining_outlined,
                        isSelected: cart.orderType == AppConstants.orderTypeDelivery,
                        onTap: () {
                          ref.read(cartProvider.notifier).setOrderType(AppConstants.orderTypeDelivery);
                        },
                      ),
                    ],
                  ),

                  // Dine In Table Indicator / Selector Chip
                  if (cart.orderType == AppConstants.orderTypeDineIn) ...[
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _showTablePicker(context, ref),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: cart.tableNumber == null ? Colors.red.shade400 : Colors.black12,
                            width: cart.tableNumber == null ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.pin_drop_rounded,
                              size: 16,
                              color: cart.tableNumber == null ? Colors.red.shade700 : const Color(0xFFB45309),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              cart.tableNumber != null ? 'Selected: ${cart.tableNumber}' : 'Tap to Select Table (Required)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: cart.tableNumber == null ? Colors.red.shade800 : const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_drop_down, size: 16, color: Color(0xFF1E293B)),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),

                  // Search Menu Bar
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search menu items by name or code...',
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                        prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () => ref.read(posSearchQueryProvider.notifier).state = '',
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: (val) => ref.read(posSearchQueryProvider.notifier).state = val,
                    ),
                  ),
                ],
              ),
            ),

            // 2. CATEGORY HORIZONTAL FILTER CHIPS (Reference Image 01)
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: categoriesAsync.when(
                data: (categories) {
                  final activeCategories = categories.where((c) => c.isActive).toList();
                  // If selected category was deleted/deactivated by admin, safely reset to ALL
                  if (selectedCategory != 'ALL' && !activeCategories.any((c) => c.id == selectedCategory)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      ref.read(selectedPosCategoryProvider.notifier).state = 'ALL';
                    });
                  }
                  return ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _categoryChip(
                        ref: ref,
                        id: 'ALL',
                        name: 'All',
                        isSelected: selectedCategory == 'ALL',
                      ),
                      ...activeCategories.map(
                        (c) => _categoryChip(
                          ref: ref,
                          id: c.id,
                          name: c.name,
                          isSelected: selectedCategory == c.id,
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            // 3. PRODUCT CATALOG GRID
            Expanded(
              child: Consumer(
                builder: (context, ref, child) {
                  final productsStream = ref.watch(productRepositoryProvider).watchProducts(
                        searchQuery: searchQuery,
                        categoryId: selectedCategory == 'ALL' ? null : selectedCategory,
                        onlyAvailable: true,
                      );

                  return StreamBuilder<List<ProductWithCategory>>(
                    stream: productsStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final products = snapshot.data ?? [];

                      if (products.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off_rounded, size: 56, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text(
                                  searchQuery.isNotEmpty ? 'No products match "$searchQuery"' : 'No products found in this category',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1E293B),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () => context.push('/products/add'),
                                  icon: const Icon(Icons.add, size: 18, color: AppTheme.posYellowHeader),
                                  label: const Text('+ Add Product', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          // Adaptive columns: 2 on mobile phones, 3 on tablets, 4 on desktop/web
                          int crossAxisCount = 2;
                          if (constraints.maxWidth > 900) {
                            crossAxisCount = 4;
                          } else if (constraints.maxWidth > 600) {
                            crossAxisCount = 3;
                          }

                          return CustomScrollView(
                            slivers: [
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Text(
                                            'Popular Items',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '(${products.length} items)',
                                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                          ),
                                        ],
                                      ),
                                      TextButton.icon(
                                        onPressed: () => context.push('/products/add'),
                                        icon: const Icon(Icons.add_circle_outline, size: 16, color: Color(0xFFB45309)),
                                        label: const Text(
                                          '+ Add Product',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFB45309),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SliverPadding(
                                padding: EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  cart.isNotEmpty ? 90 : 20,
                                ),
                                sliver: SliverGrid(
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    childAspectRatio: 0.76,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                  ),
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      final item = products[index];
                                      final p = item.product;
                                      final primaryImg = item.primaryImage;

                                      final matching = cart.items.where((ci) => ci.product.id == p.id);
                                      final qtyInCart = matching.isNotEmpty ? matching.first.quantity : 0.0;

                                      return _productCard(
                                        context: context,
                                        ref: ref,
                                        product: p,
                                        categoryName: item.category?.name,
                                        imageEntry: primaryImg,
                                        qtyInCart: qtyInCart,
                                      );
                                    },
                                    childCount: products.length,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),

            // 4. FLOATING BOTTOM CART BAR (Reference Image 01/02)
            if (cart.isNotEmpty)
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF1E293B),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, -3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.posYellowHeader,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${cart.items.length} items',
                          style: const TextStyle(
                            color: Color(0xFF1E293B),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'TOTAL',
                              style: TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              CurrencyFormatter.formatPaise(cart.grandTotalPaise),
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.posYellowHeader,
                          foregroundColor: const Color(0xFF1E293B),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.arrow_forward, size: 18),
                        label: const Text(
                          'View Cart',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        onPressed: () => context.go('/cart'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _orderTypeChip({
    required WidgetRef ref,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1E293B) : Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF1E293B) : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : const Color(0xFF1E293B),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryChip({
    required WidgetRef ref,
    required String id,
    required String name,
    required bool isSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(name),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          color: isSelected ? const Color(0xFF1E293B) : const Color(0xFF475569),
        ),
        backgroundColor: Colors.white,
        selectedColor: AppTheme.posYellowHeader,
        side: BorderSide(
          color: isSelected ? const Color(0xFFB45309) : const Color(0xFFCBD5E1),
          width: isSelected ? 1.5 : 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        showCheckmark: false,
        onSelected: (_) => ref.read(selectedPosCategoryProvider.notifier).state = id,
      ),
    );
  }

  Widget _productCard({
    required BuildContext context,
    required WidgetRef ref,
    required ProductEntry product,
    required String? categoryName,
    required ProductImageEntry? imageEntry,
    required double qtyInCart,
  }) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: qtyInCart > 0 ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0),
          width: qtyInCart > 0 ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          ref.read(cartProvider.notifier).addProduct(product);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Product Image / Placeholder
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  imageEntry != null
                      ? Image.memory(
                          imageEntry.imageBytes,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _foodPlaceholder(),
                        )
                      : _foodPlaceholder(),
                  // Edit Product affordance for Cashier
                  Positioned(
                    top: 8,
                    left: 8,
                    child: InkWell(
                      onTap: () => context.push('/products/edit/${product.id}'),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 3),
                          ],
                        ),
                        child: const Icon(
                          Icons.edit_outlined,
                          size: 14,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ),
                  if (qtyInCart > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 3),
                          ],
                        ),
                        child: Text(
                          '${qtyInCart.toInt()} in cart',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Bottom Product Details & Add button
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (categoryName != null)
                          Text(
                            categoryName.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF94A3B8),
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 2),
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              CurrencyFormatter.formatPaise(product.sellingPricePaise),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              '/${product.unit}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        // Circular Add (+) button or Stepper
                        if (qtyInCart == 0)
                          Material(
                            color: AppTheme.posYellowHeader,
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                ref.read(cartProvider.notifier).addProduct(product);
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(
                                  Icons.add,
                                  size: 20,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                          )
                        else
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () {
                                  ref.read(cartProvider.notifier).updateQuantity(product.id, qtyInCart - 1);
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.remove, size: 14),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Text(
                                  '${qtyInCart.toInt()}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  ref.read(cartProvider.notifier).addProduct(product);
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: AppTheme.posYellowHeader,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.add, size: 14, color: Color(0xFF1E293B)),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _foodPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.fastfood_rounded,
          size: 36,
          color: Color(0xFFB45309),
        ),
      ),
    );
  }

  /// Dialog to pick restaurant table for Dine In orders
  void _showTablePicker(BuildContext context, WidgetRef ref) async {
    final invoiceRepo = ref.read(invoiceRepositoryProvider);
    final occupiedTables = await invoiceRepo.getOccupiedTables();
    final currentTable = ref.read(cartProvider).tableNumber;

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Table for Dine In',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Text(
                    'Tap a table number to assign it to this order.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: AppConstants.defaultTables.map((tbl) {
                      final isSelected = currentTable == tbl;
                      final isOccupied = occupiedTables.contains(tbl);

                      return InkWell(
                        onTap: () {
                          ref.read(cartProvider.notifier).setTableNumber(tbl);
                          Navigator.pop(ctx);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 80,
                          height: 70,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.posYellowHeader
                                : (isOccupied ? const Color(0xFFFEF2F2) : Colors.white),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFB45309)
                                  : (isOccupied ? Colors.red.shade300 : Colors.grey.shade300),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.table_restaurant,
                                size: 22,
                                color: isSelected
                                    ? const Color(0xFF1E293B)
                                    : (isOccupied ? Colors.red.shade700 : const Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                tbl,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? const Color(0xFF1E293B)
                                      : (isOccupied ? Colors.red.shade800 : const Color(0xFF1E293B)),
                                ),
                              ),
                              if (isOccupied)
                                Text(
                                  'Occupied',
                                  style: TextStyle(fontSize: 9, color: Colors.red.shade700, fontWeight: FontWeight.bold),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

}


