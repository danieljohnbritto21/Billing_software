import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_constants.dart';
import '../../core/database/app_database.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../categories/category_repository.dart';
import 'product_repository.dart';

class AddEditProductScreen extends ConsumerStatefulWidget {
  final String? productId; // If null, creating new; if non-null, editing existing

  const AddEditProductScreen({super.key, this.productId});

  @override
  ConsumerState<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends ConsumerState<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late TextEditingController _sellingPriceController;
  late TextEditingController _costPriceController;
  late TextEditingController _descriptionController;

  String? _selectedCategoryId;
  String _selectedUnit = 'plate';
  double _selectedGstRate = 5.0;
  bool _isTaxInclusive = true;
  bool _isAvailable = true;
  bool _isLoading = false;
  ProductEntry? _existingProduct;

  // Images state
  final List<Uint8List> _newSelectedImages = [];
  List<ProductImageEntry> _existingImages = [];
  final ImagePicker _imagePicker = ImagePicker();
  static const int _maxImages = 10;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _codeController = TextEditingController();
    _sellingPriceController = TextEditingController();
    _costPriceController = TextEditingController();
    _descriptionController = TextEditingController();

    if (widget.productId != null) {
      _loadProduct(widget.productId!);
    }
  }

  Future<void> _loadProduct(String id) async {
    setState(() => _isLoading = true);
    final repo = ref.read(productRepositoryProvider);
    final p = await repo.getProductById(id);
    final images = await repo.getImagesForProduct(id);

    if (p != null && mounted) {
      setState(() {
        _existingProduct = p;
        _nameController.text = p.name;
        _codeController.text = p.code ?? '';
        _sellingPriceController.text =
            CurrencyFormatter.paiseToRupees(p.sellingPricePaise).toStringAsFixed(2);
        if (p.costPricePaise > 0) {
          _costPriceController.text =
              CurrencyFormatter.paiseToRupees(p.costPricePaise).toStringAsFixed(2);
        }
        _descriptionController.text = p.description ?? '';
        _selectedCategoryId = p.categoryId;
        _selectedUnit = p.unit;
        _selectedGstRate = p.gstRatePercent;
        _isTaxInclusive = p.isTaxInclusive;
        _isAvailable = p.isAvailable;
        _existingImages = images;
        _isLoading = false;
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _sellingPriceController.dispose();
    _costPriceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final totalCount = _existingImages.length + _newSelectedImages.length;
    if (totalCount >= _maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum limit of 10 images reached per product.')),
      );
      return;
    }

    try {
      final pickedFiles = await _imagePicker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFiles.isNotEmpty) {
        final remainingSlots = _maxImages - totalCount;
        final filesToAdd = pickedFiles.take(remainingSlots);

        for (final file in filesToAdd) {
          final bytes = await file.readAsBytes();
          setState(() {
            _newSelectedImages.add(bytes);
          });
        }

        if (pickedFiles.length > remainingSlots && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Only added up to the maximum limit of $_maxImages images.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking images: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _removeNewImage(int index) {
    setState(() {
      _newSelectedImages.removeAt(index);
    });
  }

  Future<void> _removeExistingImage(String imageId) async {
    try {
      await ref.read(productRepositoryProvider).deleteProductImage(imageId);
      if (widget.productId != null) {
        final images = await ref.read(productRepositoryProvider).getImagesForProduct(widget.productId!);
        setState(() {
          _existingImages = images;
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting image: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _setExistingImagePrimary(String imageId) async {
    if (widget.productId == null) return;
    try {
      await ref.read(productRepositoryProvider).setPrimaryImage(imageId, widget.productId!);
      final images = await ref.read(productRepositoryProvider).getImagesForProduct(widget.productId!);
      setState(() {
        _existingImages = images;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Primary image updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error setting primary image: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final sellingRupees = double.tryParse(_sellingPriceController.text.trim()) ?? 0.0;
    final costRupees = double.tryParse(_costPriceController.text.trim()) ?? 0.0;

    final sellingPaise = CurrencyFormatter.rupeesToPaise(sellingRupees);
    final costPaise = CurrencyFormatter.rupeesToPaise(costRupees);

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(productRepositoryProvider);

      if (_existingProduct != null) {
        final updated = _existingProduct!.copyWith(
          name: _nameController.text.trim(),
          code: Value(_codeController.text.trim().isEmpty ? null : _codeController.text.trim()),
          categoryId: Value(_selectedCategoryId),
          description: Value(_descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim()),
          sellingPricePaise: sellingPaise,
          costPricePaise: costPaise,
          gstRatePercent: _selectedGstRate,
          isTaxInclusive: _isTaxInclusive,
          unit: _selectedUnit,
          isAvailable: _isAvailable,
        );
        await repo.updateProduct(updated, newImages: _newSelectedImages.isNotEmpty ? _newSelectedImages : null);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product updated successfully!')),
          );
          context.pop();
        }
      } else {
        await repo.addProduct(
          name: _nameController.text.trim(),
          code: _codeController.text.trim().isEmpty ? null : _codeController.text.trim(),
          categoryId: _selectedCategoryId,
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          sellingPricePaise: sellingPaise,
          costPricePaise: costPaise,
          gstRatePercent: _selectedGstRate,
          isTaxInclusive: _isTaxInclusive,
          unit: _selectedUnit,
          isAvailable: _isAvailable,
          images: _newSelectedImages.isNotEmpty ? _newSelectedImages : null,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product saved and added to menu!')),
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving product: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.productId != null;
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final totalImagesCount = _existingImages.length + _newSelectedImages.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Product' : 'Add New Product'),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : () => context.pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          isEditing ? 'Save Changes' : 'Save Product',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading && isEditing
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Product Name
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Product / Dish Name *',
                      hintText: 'e.g. Chicken Biryani, Paneer Tikka',
                      prefixIcon: Icon(Icons.fastfood_outlined),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter a product name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Code / SKU & Category Row
                  Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: TextFormField(
                          controller: _codeController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'Code / SKU',
                            hintText: 'BUR-01',
                            prefixIcon: Icon(Icons.qr_code),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 6,
                        child: categoriesAsync.when(
                          data: (categories) {
                            final activeCats = categories.where((c) => c.isActive || c.id == _selectedCategoryId).toList();
                            final effectiveValue = activeCats.any((cat) => cat.id == _selectedCategoryId)
                                ? _selectedCategoryId
                                : null;
                            return DropdownButtonFormField<String?>(
                              value: effectiveValue,
                              decoration: const InputDecoration(
                                labelText: 'Category',
                                prefixIcon: Icon(Icons.category_outlined),
                              ),
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('None (Uncategorized)'),
                                ),
                                ...activeCats.map((cat) {
                                  return DropdownMenuItem<String?>(
                                    value: cat.id,
                                    child: Text(cat.name, overflow: TextOverflow.ellipsis),
                                  );
                                }),
                              ],
                              onChanged: (val) {
                                setState(() => _selectedCategoryId = val);
                              },
                            );
                          },
                          loading: () => const LinearProgressIndicator(),
                          error: (_, __) => const SizedBox(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Product Images Section
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: AppTheme.borderLight),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.image_outlined, color: AppTheme.primaryGreen),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Product Images ($totalImagesCount/$_maxImages)',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                              ElevatedButton.icon(
                                onPressed: totalImagesCount >= _maxImages ? null : _pickImages,
                                icon: const Icon(Icons.add_photo_alternate, size: 18),
                                label: const Text('Add Images'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryGreen,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Select up to 10 photos. First photo or marked star is the primary image displayed in POS billing.',
                            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                          const SizedBox(height: 16),

                          if (totalImagesCount == 0)
                            Container(
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.photo_library_outlined, size: 36, color: Colors.grey.shade400),
                                    const SizedBox(height: 4),
                                    const Text('No images added yet', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                                  ],
                                ),
                              ),
                            )
                          else
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                // Existing Images (when editing)
                                ..._existingImages.map((img) {
                                  return Stack(
                                    children: [
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: img.isPrimary ? AppTheme.primaryGreen : Colors.grey.shade300,
                                            width: img.isPrimary ? 2.5 : 1,
                                          ),
                                          image: DecorationImage(
                                            image: MemoryImage(img.imageBytes),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      if (img.isPrimary)
                                        Positioned(
                                          top: 4,
                                          left: 4,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryGreen,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text('Primary', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                      Positioned(
                                        top: 2,
                                        right: 2,
                                        child: GestureDetector(
                                          onTap: () => _removeExistingImage(img.id),
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.close, size: 14, color: Colors.white),
                                          ),
                                        ),
                                      ),
                                      if (!img.isPrimary && widget.productId != null)
                                        Positioned(
                                          bottom: 2,
                                          left: 2,
                                          right: 2,
                                          child: GestureDetector(
                                            onTap: () => _setExistingImagePrimary(img.id),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.black54,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Text('Make Primary', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 8)),
                                            ),
                                          ),
                                        ),
                                    ],
                                  );
                                }),

                                // Newly Selected Images
                                ..._newSelectedImages.asMap().entries.map((entry) {
                                  final idx = entry.key;
                                  final bytes = entry.value;
                                  final isPrimaryNew = _existingImages.isEmpty && idx == 0;

                                  return Stack(
                                    children: [
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: isPrimaryNew ? AppTheme.primaryGreen : Colors.grey.shade300,
                                            width: isPrimaryNew ? 2.5 : 1,
                                          ),
                                          image: DecorationImage(
                                            image: MemoryImage(bytes),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      if (isPrimaryNew)
                                        Positioned(
                                          top: 4,
                                          left: 4,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryGreen,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text('Primary', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                      Positioned(
                                        top: 2,
                                        right: 2,
                                        child: GestureDetector(
                                          onTap: () => _removeNewImage(idx),
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.close, size: 14, color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Selling Price & Unit
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _sellingPriceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Selling Price (₹) *',
                            hintText: '149.00',
                            prefixIcon: Icon(Icons.currency_rupee),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Enter selling price';
                            }
                            final num = double.tryParse(val.trim());
                            if (num == null || num <= 0) {
                              return 'Must be greater than 0';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedUnit,
                          decoration: const InputDecoration(
                            labelText: 'Unit *',
                            prefixIcon: Icon(Icons.straighten),
                          ),
                          items: AppConstants.standardUnits.map((u) {
                            return DropdownMenuItem(
                              value: u,
                              child: Text(u),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedUnit = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // GST Rate & Tax Treatment
                  Card(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tax & GST Configuration',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<double>(
                                  value: _selectedGstRate,
                                  decoration: const InputDecoration(
                                    labelText: 'GST Rate',
                                    prefixIcon: Icon(Icons.percent),
                                  ),
                                  items: AppConstants.standardGstRates.map((rate) {
                                    return DropdownMenuItem(
                                      value: rate,
                                      child: Text('${rate.toStringAsFixed(0)}% GST'),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedGstRate = val);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SwitchListTile(
                            title: const Text('Tax Inclusive Price',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              _isTaxInclusive
                                  ? 'Selling price already includes $_selectedGstRate% GST'
                                  : 'GST will be added on top of selling price during billing',
                              style: const TextStyle(fontSize: 12),
                            ),
                            value: _isTaxInclusive,
                            activeColor: AppTheme.primaryGreen,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (val) => setState(() => _isTaxInclusive = val),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Cost Price & Status
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _costPriceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Cost / Purchase Price (₹)',
                            hintText: 'Optional',
                            prefixIcon: Icon(Icons.money_off_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SwitchListTile(
                          title: const Text('Available', style: TextStyle(fontWeight: FontWeight.w600)),
                          value: _isAvailable,
                          activeColor: AppTheme.primaryGreen,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (val) => setState(() => _isAvailable = val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Description / Recipe Notes (Optional)',
                      hintText: 'e.g. Served with green chutney and onions',
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
