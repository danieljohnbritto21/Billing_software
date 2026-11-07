import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/app_database.dart';
import '../suppliers/supplier_repository.dart';
import 'purchase_repository.dart';

class CreatePurchaseOrderScreen extends ConsumerStatefulWidget {
  final String? initialSupplierId;
  const CreatePurchaseOrderScreen({super.key, this.initialSupplierId});

  @override
  ConsumerState<CreatePurchaseOrderScreen> createState() => _CreatePurchaseOrderScreenState();
}

class _CreatePurchaseOrderScreenState extends ConsumerState<CreatePurchaseOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedSupplierId;
  DateTime? _expectedDeliveryDate;
  final _notesController = TextEditingController();
  final List<_POLineItemDraft> _items = [];
  bool _isLoading = false;

  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _selectedSupplierId = widget.initialSupplierId;
    _addNewItem();
  }

  @override
  void dispose() {
    _notesController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _addNewItem([ProductEntry? product]) {
    setState(() {
      final draft = _POLineItemDraft(
        productId: product?.id,
        name: product?.name ?? '',
        unit: product?.unit ?? 'pcs',
        unitPriceRupees: (product?.costPricePaise != null && product!.costPricePaise > 0
                ? product.costPricePaise
                : (product?.sellingPricePaise ?? 0)) /
            100.0,
        gstRatePercent: 0.0,
        quantity: 1.0,
      );
      _items.add(draft);
    });
  }

  void _removeItem(int index) {
    if (_items.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchase order must have at least one item.')),
      );
      return;
    }
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  int get _subtotalPaise {
    int subtotal = 0;
    for (final it in _items) {
      final taxable = (it.quantity * (it.unitPriceRupees * 100).round()).round();
      subtotal += taxable;
    }
    return subtotal;
  }

  int get _taxPaise {
    int tax = 0;
    for (final it in _items) {
      final taxable = (it.quantity * (it.unitPriceRupees * 100).round()).round();
      tax += (taxable * it.gstRatePercent / 100.0).round();
    }
    return tax;
  }

  int get _grandTotalPaise => _subtotalPaise + _taxPaise;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSupplierId == null || _selectedSupplierId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a supplier.')),
      );
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one line item.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final itemsPayload = _items.map((it) {
        final unitPricePaise = (it.unitPriceRupees * 100).round();
        return {
          'id': const Uuid().v4(),
          'productId': it.productId,
          'productName': it.name.trim(),
          'productCode': it.productId != null ? it.name.trim().toLowerCase().replaceAll(' ', '_') : null,
          'quantity': it.quantity,
          'unit': it.unit.trim().isNotEmpty ? it.unit.trim() : 'unit',
          'unitPricePaise': unitPricePaise,
          'gstRatePercent': it.gstRatePercent,
        };
      }).toList();

      await ref.read(purchaseRepositoryProvider).createPurchaseOrder(
            supplierId: _selectedSupplierId!,
            items: itemsPayload,
            notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
            expectedDeliveryDate: _expectedDeliveryDate,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase Order created successfully!'), backgroundColor: Colors.green),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create order: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final suppliersAsync = ref.watch(activeSuppliersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Purchase Order'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Vendor Selection Card
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Supplier & Delivery Details', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    suppliersAsync.when(
                      data: (suppliers) => DropdownButtonFormField<String>(
                        value: _selectedSupplierId,
                        decoration: const InputDecoration(
                          labelText: 'Select Supplier *',
                          prefixIcon: Icon(Icons.business),
                          border: OutlineInputBorder(),
                        ),
                        isExpanded: true,
                        items: suppliers
                            .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name, overflow: TextOverflow.ellipsis)))
                            .toList(),
                        validator: (val) => val == null || val.isEmpty ? 'Supplier is required' : null,
                        onChanged: (val) => setState(() => _selectedSupplierId = val),
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (err, _) => Text('Error loading suppliers: $err'),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.event_outlined),
                      title: Text(
                        _expectedDeliveryDate == null
                            ? 'Set Expected Delivery Date (Optional)'
                            : 'Expected: ${DateFormat('dd MMMM yyyy').format(_expectedDeliveryDate!)}',
                      ),
                      trailing: _expectedDeliveryDate != null
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => setState(() => _expectedDeliveryDate = null),
                            )
                          : const Icon(Icons.chevron_right),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 3)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() => _expectedDeliveryDate = picked);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Line Items Card
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Line Items (${_items.length})', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        TextButton.icon(
                          onPressed: () => _addNewItem(),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Item'),
                        ),
                      ],
                    ),
                    const Divider(),
                    ..._items.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(radius: 12, child: Text('${idx + 1}', style: const TextStyle(fontSize: 12))),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: item.nameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Product / Item Name *',
                                      isDense: true,
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (val) => val == null || val.trim().isEmpty ? 'Name required' : null,
                                    onChanged: (val) => item.name = val,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () => _removeItem(idx),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: item.quantityController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: const InputDecoration(
                                      labelText: 'Qty',
                                      isDense: true,
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (val) {
                                      final n = double.tryParse(val ?? '');
                                      if (n == null || n <= 0) return 'Invalid';
                                      return null;
                                    },
                                    onChanged: (val) {
                                      setState(() {
                                        item.quantity = double.tryParse(val) ?? 1.0;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: item.unitController,
                                    decoration: const InputDecoration(
                                      labelText: 'Unit (kg, pcs)',
                                      isDense: true,
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (val) => item.unit = val,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    controller: item.priceController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: const InputDecoration(
                                      labelText: 'Price (₹)',
                                      isDense: true,
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (val) {
                                      final n = double.tryParse(val ?? '');
                                      if (n == null || n < 0) return 'Invalid';
                                      return null;
                                    },
                                    onChanged: (val) {
                                      setState(() {
                                        item.unitPriceRupees = double.tryParse(val) ?? 0.0;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: DropdownButtonFormField<double>(
                                    value: item.gstRatePercent,
                                    decoration: const InputDecoration(
                                      labelText: 'GST %',
                                      isDense: true,
                                      border: OutlineInputBorder(),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 0.0, child: Text('0%')),
                                      DropdownMenuItem(value: 5.0, child: Text('5%')),
                                      DropdownMenuItem(value: 12.0, child: Text('12%')),
                                      DropdownMenuItem(value: 18.0, child: Text('18%')),
                                      DropdownMenuItem(value: 28.0, child: Text('28%')),
                                    ],
                                    onChanged: (val) {
                                      setState(() {
                                        item.gstRatePercent = val ?? 0.0;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Order Notes Card
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Procurement Notes', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'Enter internal terms, delivery instructions, or notes...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Summary Card
            Card(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal:'),
                        Text(_currencyFormat.format(_subtotalPaise / 100), style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('GST / Tax:'),
                        Text(_currencyFormat.format(_taxPaise / 100), style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Grand Total:', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        Text(
                          _currencyFormat.format(_grandTotalPaise / 100),
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.green.shade800),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            FilledButton.icon(
              onPressed: _isLoading ? null : _submit,
              icon: _isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send),
              label: Text(_isLoading ? 'Submitting Order...' : 'Create Purchase Order', style: const TextStyle(fontSize: 16)),
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

class _POLineItemDraft {
  String? productId;
  String name;
  String unit;
  double unitPriceRupees;
  double gstRatePercent;
  double quantity;

  late final TextEditingController nameController;
  late final TextEditingController quantityController;
  late final TextEditingController unitController;
  late final TextEditingController priceController;

  _POLineItemDraft({
    this.productId,
    required this.name,
    required this.unit,
    required this.unitPriceRupees,
    required this.gstRatePercent,
    required this.quantity,
  }) {
    nameController = TextEditingController(text: name);
    quantityController = TextEditingController(text: quantity.toString());
    unitController = TextEditingController(text: unit);
    priceController = TextEditingController(text: unitPriceRupees.toStringAsFixed(2));
  }

  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    unitController.dispose();
    priceController.dispose();
  }
}
