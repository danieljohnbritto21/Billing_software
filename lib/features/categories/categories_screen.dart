import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/sync/sync_provider.dart';
import '../../core/theme/app_theme.dart';
import 'category_repository.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        ref.read(syncServiceProvider).syncNow();
      } catch (_) {}
    });
  }

  void _showAddEditDialog({CategoryEntry? existingCategory}) {
    final nameController =
        TextEditingController(text: existingCategory?.name ?? '');
    final orderController = TextEditingController(
        text: (existingCategory?.displayOrder ?? 0).toString());
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          existingCategory == null ? 'Add Category' : 'Edit Category',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  hintText: 'e.g. Desserts, Soups',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Category name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: orderController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Display Order',
                  hintText: 'e.g. 0, 1, 2',
                  prefixIcon: Icon(Icons.sort_rounded),
                ),
                validator: (v) {
                  if (v != null && v.isNotEmpty && int.tryParse(v) == null) {
                    return 'Must be an integer';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final name = nameController.text.trim();
              final order = int.tryParse(orderController.text.trim()) ?? 0;
              final repo = ref.read(categoryRepositoryProvider);

              if (existingCategory == null) {
                await repo.addCategory(name: name, displayOrder: order);
              } else {
                await repo.updateCategory(
                  existingCategory.copyWith(
                    name: name,
                    displayOrder: order,
                  ),
                );
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDelete(CategoryWithCount item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          item.productCount > 0
              ? 'This category has ${item.productCount} products assigned to it. Deleting it will mark it inactive so existing products remain safe.'
              : 'Are you sure you want to permanently delete "${item.category.name}"?',
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
            child: Text(item.productCount > 0 ? 'Deactivate' : 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final repo = ref.read(categoryRepositoryProvider);
      final permanentlyDeleted = await repo.deleteCategory(item.category.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              permanentlyDeleted
                  ? 'Category deleted permanently'
                  : 'Category deactivated (products preserved)',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesWithCountsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Categories Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Sync categories',
            icon: const Icon(Icons.sync_rounded, color: AppTheme.primaryGreen),
            onPressed: () => ref.read(syncServiceProvider).syncNow(),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            onPressed: () => _showAddEditDialog(),
            icon: const Icon(Icons.add),
            label: const Text('New Category'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search categories...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim().toLowerCase();
                });
              },
            ),
          ),

          // Categories List with Pull to Refresh
          Expanded(
            child: RefreshIndicator(
              color: AppTheme.primaryGreen,
              onRefresh: () => ref.read(syncServiceProvider).syncNow(),
              child: categoriesAsync.when(
                data: (categories) {
                  final filtered = categories.where((c) {
                    if (_searchQuery.isEmpty) return true;
                    return c.category.name.toLowerCase().contains(_searchQuery);
                  }).toList();

                  if (filtered.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 64),
                        Icon(Icons.category_outlined,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            _searchQuery.isEmpty
                                ? 'No categories found'
                                : 'No categories matching "$_searchQuery"',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final cat = item.category;

                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: cat.isActive
                                ? AppTheme.primaryGreen.withValues(alpha: 0.12)
                                : Colors.grey.shade200,
                            child: Icon(
                              Icons.restaurant_menu,
                              color: cat.isActive
                                  ? AppTheme.primaryGreen
                                  : Colors.grey.shade500,
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                cat.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: cat.isActive
                                      ? Colors.black87
                                      : Colors.grey.shade500,
                                  decoration: cat.isActive
                                      ? null
                                      : TextDecoration.lineThrough,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (!cat.isActive)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Inactive',
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.grey),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Text(
                            '${item.productCount} products  •  Display order: ${cat.displayOrder}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Switch for active/inactive
                              Switch(
                                value: cat.isActive,
                                activeColor: AppTheme.primaryGreen,
                                onChanged: (val) async {
                                  await ref
                                      .read(categoryRepositoryProvider)
                                      .setCategoryActive(cat.id, val);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                tooltip: 'Edit Category',
                                onPressed: () =>
                                    _showAddEditDialog(existingCategory: cat),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.red, size: 20),
                                tooltip: 'Delete Category',
                                onPressed: () => _handleDelete(item),
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
            ),
          ),
        ],
      ),
    );
  }
}
