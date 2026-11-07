import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/sync/sync_provider.dart';
import '../auth/auth_provider.dart';
import '../categories/category_repository.dart';
import '../products/product_repository.dart';

class AddEditSupplierProductScreen extends ConsumerStatefulWidget {
  final String? productId;
  const AddEditSupplierProductScreen({super.key, this.productId});

  @override
  ConsumerState<AddEditSupplierProductScreen> createState() => _AddEditSupplierProductScreenState();
}

class _AddEditSupplierProductScreenState extends ConsumerState<AddEditSupplierProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _unitController = TextEditingController(text: 'pcs');
  String? _categoryId;
  bool _isAvailable = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.productId != null) {
      _loadProduct();
    }
  }

  Future<void> _loadProduct() async {
    final p = await ref.read(productRepositoryProvider).getProductById(widget.productId!);
    if (p != null && mounted) {
      setState(() {
        _nameController.text = p.name;
        final price = p.costPricePaise > 0 ? p.costPricePaise : p.sellingPricePaise;
        _priceController.text = (price / 100.0).toStringAsFixed(2);
        _unitController.text = p.unit;
        _categoryId = p.categoryId;
        _isAvailable = p.isAvailable;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider);
    final supplierId = ref.read(apiClientProvider).supplierId ?? user?.supplierId;

    if (supplierId == null || supplierId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Supplier session invalid. Please log in again.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final priceRupees = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final pricePaise = (priceRupees * 100).round();

    try {
      final repo = ref.read(productRepositoryProvider);

      if (widget.productId != null) {
        final existing = await repo.getProductById(widget.productId!);
        if (existing != null) {
          await repo.updateProduct(
            existing.copyWith(
              name: _nameController.text.trim(),
              categoryId: drift.Value(_categoryId),
              supplierId: drift.Value(supplierId),
              sellingPricePaise: pricePaise,
              costPricePaise: pricePaise,
              unit: _unitController.text.trim().isNotEmpty ? _unitController.text.trim() : 'pcs',
              isAvailable: _isAvailable,
              updatedAt: DateTime.now(),
            ),
          );
        }
      } else {
        await repo.addProduct(
          name: _nameController.text.trim(),
          categoryId: _categoryId,
          supplierId: supplierId,
          sellingPricePaise: pricePaise,
          costPricePaise: pricePaise,
          unit: _unitController.text.trim().isNotEmpty ? _unitController.text.trim() : 'pcs',
          isAvailable: _isAvailable,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.productId != null ? 'Product updated' : 'Product added to catalog'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save product: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.productId != null ? 'Edit Product' : 'Add Catalog Product'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Product Information', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Product Name *',
                        prefixIcon: Icon(Icons.fastfood_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Product name is required' : null,
                    ),
                    const SizedBox(height: 16),
                    categoriesAsync.when(
                      data: (categories) => DropdownButtonFormField<String>(
                        value: _categoryId,
                        decoration: const InputDecoration(
                          labelText: 'Category (Optional)',
                          prefixIcon: Icon(Icons.category_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('No Category')),
                          ...categories.map(
                            (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                          ),
                        ],
                        onChanged: (val) => setState(() => _categoryId = val),
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _priceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Supply Price (₹) *',
                              prefixIcon: Icon(Icons.currency_rupee),
                              border: OutlineInputBorder(),
                            ),
                            validator: (val) {
                              final n = double.tryParse(val ?? '');
                              if (n == null || n < 0) return 'Invalid price';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _unitController,
                            decoration: const InputDecoration(
                              labelText: 'Unit *',
                              hintText: 'kg, pcs, box',
                              border: OutlineInputBorder(),
                            ),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Available for Supply'),
                      subtitle: const Text('Mark if currently available to be ordered'),
                      value: _isAvailable,
                      onChanged: (val) => setState(() => _isAvailable = val),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isLoading ? null : _save,
              icon: _isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check),
              label: Text(_isLoading ? 'Saving...' : 'Save Product', style: const TextStyle(fontSize: 16)),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
