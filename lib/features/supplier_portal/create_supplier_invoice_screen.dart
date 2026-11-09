import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/app_database.dart';
import '../../core/sync/sync_provider.dart';
import '../auth/auth_provider.dart';
import '../products/product_repository.dart';
import '../purchases/purchase_repository.dart';

class CreateSupplierInvoiceScreen extends ConsumerStatefulWidget {
  final String? purchaseOrderId;
  final String? initialProductId;
  const CreateSupplierInvoiceScreen({
    super.key,
    this.purchaseOrderId,
    this.initialProductId,
  });

  @override
  ConsumerState<CreateSupplierInvoiceScreen> createState() => _CreateSupplierInvoiceScreenState();
}

class _CreateSupplierInvoiceScreenState extends ConsumerState<CreateSupplierInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceNumberController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _invoiceDate = DateTime.now();
  DateTime? _dueDate;
  final List<_InvoiceLineItemDraft> _items = [];
  bool _isLoading = false;

  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _invoiceNumberController.text = 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    _dueDate = DateTime.now().add(const Duration(days: 15));

    if (widget.purchaseOrderId != null) {
      _prefillFromPurchaseOrder(widget.purchaseOrderId!);
    } else if (widget.initialProductId != null) {
      _prefillFromProductId(widget.initialProductId!);
    } else {
      _addNewItem();
    }
  }

  Future<void> _prefillFromProductId(String pId) async {
    final product = await ref.read(productRepositoryProvider).getProductById(pId);
    if (mounted) {
      if (product != null) {
        _addNewItem(product);
      } else {
        _addNewItem();
      }
    }
  }

  Future<void> _prefillFromPurchaseOrder(String poId) async {
    final poItems = await ref.read(purchaseRepositoryProvider).getPurchaseOrderItems(poId);

    if (mounted && poItems.isNotEmpty) {
      setState(() {
        _items.clear();
        for (final it in poItems) {
          _items.add(
            _InvoiceLineItemDraft(
              productId: it.productId,
              name: it.productName,
              unit: it.unit,
              unitPriceRupees: it.unitPricePaise / 100.0,
              gstRatePercent: it.gstRatePercent,
              quantity: it.quantity,
            ),
          );
        }
      });
    } else if (mounted) {
      _addNewItem();
    }
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _notesController.dispose();
    for (final it in _items) {
      it.dispose();
    }
    super.dispose();
  }

  void _addNewItem([ProductEntry? product]) {
    setState(() {
      final draft = _InvoiceLineItemDraft(
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

  Future<void> _showProductSelectorModal({int? targetIndex}) async {
    final products = await ref.read(productRepositoryProvider).getAllProducts();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = query.trim().isEmpty
                ? products
                : products.where((p) =>
                    p.product.name.toLowerCase().contains(query.toLowerCase()) ||
                    (p.product.code?.toLowerCase().contains(query.toLowerCase()) ?? false)).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (_, scrollController) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          const Icon(Icons.inventory_2_outlined, color: Colors.indigo),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Select Product for Bill',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: TextField(
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Search products by name or code...',
                          prefixIcon: const Icon(Icons.search),
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onChanged: (val) {
                          setModalState(() {
                            query = val;
                          });
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(child: Text('No products available'))
                          : ListView.separated(
                              controller: scrollController,
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final item = filtered[index];
                                final p = item.product;
                                final rate = (p.costPricePaise > 0 ? p.costPricePaise : p.sellingPricePaise) / 100.0;

                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.indigo.shade50,
                                    child: const Icon(Icons.restaurant_menu, color: Colors.indigo, size: 20),
                                  ),
                                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('Unit: ${p.unit} • Rate: ₹${rate.toStringAsFixed(2)}'),
                                  trailing: FilledButton.tonal(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      setState(() {
                                        if (targetIndex != null && targetIndex < _items.length) {
                                          _items[targetIndex].applyProduct(p);
                                        } else {
                                          _addNewItem(p);
                                        }
                                      });
                                    },
                                    child: const Text('Select'),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _removeItem(int index) {
    if (_items.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice must contain at least one line item.')),
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

    final user = ref.read(currentUserProvider);
    final supplierId = ref.read(apiClientProvider).supplierId ?? user?.supplierId;

    if (supplierId == null || supplierId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Supplier authentication invalid. Please re-login.')),
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
          'gstPercentage': it.gstRatePercent,
        };
      }).toList();

      await ref.read(purchaseRepositoryProvider).submitSupplierInvoice(
            supplierId: supplierId,
            purchaseOrderId: widget.purchaseOrderId,
            invoiceNumber: _invoiceNumberController.text.trim(),
            invoiceDate: _invoiceDate,
            dueDate: _dueDate,
            notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
            items: itemsPayload,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invoice submitted! Awaiting Admin verification and approval.'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit invoice: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Bill / Invoice'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Bill Info Card
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Invoice Details', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _invoiceNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Your Bill / Invoice Number *',
                        prefixIcon: Icon(Icons.receipt),
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Invoice number is required' : null,
                    ),
                    if (widget.purchaseOrderId != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Ref PO: ${widget.purchaseOrderId}',
                          style: TextStyle(color: Colors.blue.shade900, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.calendar_today_outlined),
                            title: const Text('Invoice Date', style: TextStyle(fontSize: 12)),
                            subtitle: Text(dateFormat.format(_invoiceDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _invoiceDate,
                                firstDate: DateTime.now().subtract(const Duration(days: 90)),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) setState(() => _invoiceDate = picked);
                            },
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.event_available_outlined),
                            title: const Text('Payment Due Date', style: TextStyle(fontSize: 12)),
                            subtitle: Text(_dueDate != null ? dateFormat.format(_dueDate!) : 'Not set', style: const TextStyle(fontWeight: FontWeight.bold)),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 15)),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 180)),
                              );
                              if (picked != null) setState(() => _dueDate = picked);
                            },
                          ),
                        ),
                      ],
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
                        Text('Billed Items (${_items.length})', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            FilledButton.tonalIcon(
                              onPressed: () => _showProductSelectorModal(),
                              icon: const Icon(Icons.inventory_2_outlined, size: 16),
                              label: const Text('Select Product'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                            const SizedBox(width: 6),
                            TextButton.icon(
                              onPressed: () => _addNewItem(),
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Custom Item'),
                            ),
                          ],
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
                                    decoration: InputDecoration(
                                      labelText: 'Product / Item Name *',
                                      isDense: true,
                                      border: const OutlineInputBorder(),
                                      suffixIcon: IconButton(
                                        icon: const Icon(Icons.search, color: Colors.indigo),
                                        tooltip: 'Select from catalog',
                                        onPressed: () => _showProductSelectorModal(targetIndex: idx),
                                      ),
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
                                      labelText: 'Unit',
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
                                      labelText: 'Rate (₹)',
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

            // Notes
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Notes & Bank Details', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'Enter bank account info or special remarks for the store...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Totals
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
                        const Text('GST Amount:'),
                        Text(_currencyFormat.format(_taxPaise / 100), style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Grand Total Billed:', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
              label: Text(_isLoading ? 'Submitting...' : 'Submit Invoice for Verification', style: const TextStyle(fontSize: 16)),
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

class _InvoiceLineItemDraft {
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

  _InvoiceLineItemDraft({
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

  void applyProduct(ProductEntry product) {
    productId = product.id;
    name = product.name;
    unit = product.unit;
    unitPriceRupees = (product.costPricePaise > 0 ? product.costPricePaise : product.sellingPricePaise) / 100.0;
    gstRatePercent = product.gstRatePercent;

    nameController.text = name;
    unitController.text = unit;
    priceController.text = unitPriceRupees.toStringAsFixed(2);
  }

  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    unitController.dispose();
    priceController.dispose();
  }
}
