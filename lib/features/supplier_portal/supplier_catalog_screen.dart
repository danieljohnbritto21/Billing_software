import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../products/product_repository.dart';

class SupplierCatalogScreen extends ConsumerStatefulWidget {
  const SupplierCatalogScreen({super.key});

  @override
  ConsumerState<SupplierCatalogScreen> createState() => _SupplierCatalogScreenState();
}

class _SupplierCatalogScreenState extends ConsumerState<SupplierCatalogScreen> {
  final _searchController = TextEditingController();
  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productRepo = ref.watch(productRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products & Catalog'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'Put Bill / Create Invoice',
            onPressed: () => context.push('/supplier/invoices/create'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/supplier/invoices/create'),
        icon: const Icon(Icons.receipt_long),
        label: const Text('Put Bill'),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products by name...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
          ),
          // Product Stream (shows all products for billing and selection)
          Expanded(
            child: StreamBuilder<List<ProductWithCategory>>(
              stream: productRepo.watchProducts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                var items = snapshot.data ?? [];
                if (_searchQuery.isNotEmpty) {
                  items = items.where((it) => it.product.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
                }

                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty ? 'No products match "$_searchQuery"' : 'No products available',
                          style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 8),
                        const Text('Products added by Admin will show here automatically.'),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 80),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final p = items[index].product;
                    final price = (p.costPricePaise > 0 ? p.costPricePaise : p.sellingPricePaise) / 100.0;

                    return Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                            child: Icon(Icons.inventory, color: theme.colorScheme.primary),
                          ),
                          title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Unit: ${p.unit} • Rate: ${_currencyFormat.format(price)}${p.costPricePaise > 0 && p.costPricePaise != p.sellingPricePaise ? " (Cost: ${_currencyFormat.format(p.costPricePaise / 100.0)})" : ""}',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                p.isAvailable ? 'Available' : 'Unavailable',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: p.isAvailable ? Colors.green.shade700 : Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FilledButton.tonalIcon(
                                icon: const Icon(Icons.receipt_long, size: 16),
                                label: const Text('Put Bill'),
                                style: FilledButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                ),
                                onPressed: () => context.push('/supplier/invoices/create?productId=${p.id}'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                tooltip: 'Edit',
                                onPressed: () => context.push('/supplier/catalog/edit/${p.id}'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
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
