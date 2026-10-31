import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/database/app_database.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../auth/auth_provider.dart';
import '../invoices/invoice_repository.dart';
import '../printer/invoice_pdf_generator.dart';
import '../settings/settings_repository.dart';
import 'cart_provider.dart';

class CashierCartScreen extends ConsumerStatefulWidget {
  const CashierCartScreen({super.key});

  @override
  ConsumerState<CashierCartScreen> createState() => _CashierCartScreenState();
}

class _CashierCartScreenState extends ConsumerState<CashierCartScreen> {
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _deliveryAddressController = TextEditingController();
  final _noteController = TextEditingController();
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    final cart = ref.read(cartProvider);
    _customerNameController.text = cart.customerName;
    _customerPhoneController.text = cart.customerPhone;
    _deliveryAddressController.text = cart.deliveryAddress ?? '';
    _noteController.text = cart.billNote;
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _deliveryAddressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _syncInputsToCart() {
    final notifier = ref.read(cartProvider.notifier);
    notifier.setCustomer(
      name: _customerNameController.text.trim(),
      phone: _customerPhoneController.text.trim(),
    );
    notifier.setDeliveryAddress(_deliveryAddressController.text.trim());
    notifier.setBillNote(_noteController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppTheme.posYellowHeader,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              cart.isEditingPending
                  ? 'Editing ${cart.existingInvoiceNumber ?? 'Order'}'
                  : 'Order Cart (${cart.items.length} items)',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            Text(
              '${cart.orderType.toUpperCase()}${cart.tableNumber != null ? ' • ${cart.tableNumber}' : ''}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF78350F)),
            ),
          ],
        ),
        actions: [
          if (cart.isNotEmpty)
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF991B1B)),
              icon: const Icon(Icons.delete_sweep_outlined, size: 20),
              label: const Text('Clear', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => _confirmClearCart(context),
            ),
        ],
      ),
      body: cart.isEmpty
          ? _emptyCartView(context)
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Order Type & Table Information Bar
                      _orderTypeHeader(context, cart),
                      const SizedBox(height: 12),

                      // Customer Details Section
                      _customerDetailsCard(context, cart),
                      const SizedBox(height: 12),

                      // Order Items List
                      _orderItemsList(context, cart),
                      const SizedBox(height: 12),

                      // Bill Note Card
                      _billNoteCard(context, cart),
                      const SizedBox(height: 12),

                      // Totals & GST Breakdown
                      _priceBreakdownCard(context, cart),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),

                // Bottom Sticky Dual-Action Bar (Save as Pending & Proceed to Bill)
                _bottomActionBar(context, cart),
              ],
            ),
    );
  }

  Widget _emptyCartView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.remove_shopping_cart_outlined,
                size: 64,
                color: Color(0xFFB45309),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Your Cart is Empty',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add delicious dishes from the Menu to start billing.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.posYellowHeader,
                foregroundColor: const Color(0xFF1E293B),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              icon: const Icon(Icons.restaurant_menu),
              label: const Text('Browse Menu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              onPressed: () => context.go('/billing'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orderTypeHeader(BuildContext context, CartState cart) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.posYellowLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              cart.orderType == AppConstants.orderTypeDineIn
                  ? Icons.table_restaurant
                  : (cart.orderType == AppConstants.orderTypeDelivery
                      ? Icons.delivery_dining
                      : Icons.takeout_dining),
              color: const Color(0xFFB45309),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Type: ${cart.orderType}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                if (cart.orderType == AppConstants.orderTypeDineIn)
                  Text(
                    cart.tableNumber != null ? 'Assigned to ${cart.tableNumber}' : 'No Table Selected (Required)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: cart.tableNumber != null ? const Color(0xFF16A34A) : Colors.red.shade700,
                    ),
                  ),
              ],
            ),
          ),
          if (cart.orderType == AppConstants.orderTypeDineIn)
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFB45309),
                side: const BorderSide(color: Color(0xFFF59E0B)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
              onPressed: () => _showTablePickerModal(context),
              child: Text(cart.tableNumber != null ? 'Change' : 'Select'),
            ),
        ],
      ),
    );
  }

  Widget _customerDetailsCard(BuildContext context, CartState cart) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person_outline, size: 18, color: Color(0xFF64748B)),
              SizedBox(width: 6),
              Text(
                'Customer Details',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customerNameController,
                  decoration: const InputDecoration(
                    labelText: 'Customer Name',
                    hintText: 'e.g. John Doe',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) => ref.read(cartProvider.notifier).setCustomer(name: val),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _customerPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '10-digit mobile',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) => ref.read(cartProvider.notifier).setCustomer(phone: val),
                ),
              ),
            ],
          ),
          if (cart.orderType == AppConstants.orderTypeDelivery) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _deliveryAddressController,
              decoration: const InputDecoration(
                labelText: 'Delivery Address',
                hintText: 'Apartment, Street, Landmark',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => ref.read(cartProvider.notifier).setDeliveryAddress(val),
            ),
          ],
        ],
      ),
    );
  }

  Widget _orderItemsList(BuildContext context, CartState cart) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Order Items',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
              ),
              Text(
                '${cart.items.length} items',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const Divider(height: 20),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cart.items.length,
            separatorBuilder: (_, __) => const Divider(height: 16),
            itemBuilder: (context, index) {
              final ci = cart.items[index];
              final p = ci.product;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Item Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${CurrencyFormatter.formatPaise(p.sellingPricePaise)} / ${p.unit}  •  ${p.gstRatePercent}% GST',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),

                  // Stepper controls
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 22),
                        color: Colors.grey.shade700,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          ref.read(cartProvider.notifier).updateQuantity(p.id, ci.quantity - 1);
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          ci.quantity % 1 == 0 ? ci.quantity.toInt().toString() : ci.quantity.toString(),
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle, size: 22),
                        color: const Color(0xFFF59E0B),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          ref.read(cartProvider.notifier).addProduct(p);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(width: 14),

                  // Item Total
                  SizedBox(
                    width: 75,
                    child: Text(
                      CurrencyFormatter.formatPaise(ci.finalTotalPaise),
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _billNoteCard(BuildContext context, CartState cart) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.edit_note, size: 18, color: Color(0xFFB45309)),
              SizedBox(width: 6),
              Text(
                'Kitchen / Bill Notes',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF92400E)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _noteController,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'e.g. Less spicy, extra sauce, delivery on 2nd floor...',
              hintStyle: TextStyle(fontSize: 12),
              isDense: true,
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(),
            ),
            onChanged: (val) => ref.read(cartProvider.notifier).setBillNote(val),
          ),
        ],
      ),
    );
  }

  Widget _priceBreakdownCard(BuildContext context, CartState cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          _summaryRow('Subtotal', cart.subtotalPaise),
          if (cart.totalDiscountPaise > 0)
            _summaryRow('Total Discount', -cart.totalDiscountPaise, isDiscount: true),
          _summaryRow('Taxable Value', cart.taxableAmountPaise),
          if (cart.cgstPaise > 0)
            _summaryRow('CGST', cart.cgstPaise),
          if (cart.sgstPaise > 0)
            _summaryRow('SGST', cart.sgstPaise),
          if (cart.roundOffPaise != 0)
            _summaryRow('Round Off', cart.roundOffPaise),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Grand Total',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
              Text(
                CurrencyFormatter.formatPaise(cart.grandTotalPaise),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF15803D)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, int paise, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          Text(
            CurrencyFormatter.formatPaise(paise),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDiscount ? const Color(0xFFDC2626) : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomActionBar(BuildContext context, CartState cart) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -3)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Action A: "Save as Pending"
            Expanded(
              flex: 5,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFB45309),
                  backgroundColor: const Color(0xFFFFFBEB),
                  side: const BorderSide(color: Color(0xFFF59E0B), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.bookmark_add_outlined, size: 20),
                label: const Text(
                  'Save as Pending',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                onPressed: () => _handleSaveAsPending(context, cart),
              ),
            ),
            const SizedBox(width: 12),
            // Action B: "Proceed to Bill"
            Expanded(
              flex: 6,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.posYellowHeader,
                  foregroundColor: const Color(0xFF1E293B),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.receipt_long, size: 20),
                label: const Text(
                  'Proceed to Bill',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                ),
                onPressed: () => _handleProceedToBill(context, cart),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClearCart(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Cart?'),
        content: const Text('Are you sure you want to remove all items from the current cart?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              ref.read(cartProvider.notifier).clear();
              _customerNameController.clear();
              _customerPhoneController.clear();
              _deliveryAddressController.clear();
              _noteController.clear();
              Navigator.pop(ctx);
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showTablePickerModal(BuildContext context) async {
    final invoiceRepo = ref.read(invoiceRepositoryProvider);
    final occupiedTables = await invoiceRepo.getOccupiedTables();
    final currentTable = ref.read(cartProvider).tableNumber;

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Select Table for Dine In', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 12),
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
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 75,
                      height: 65,
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.posYellowHeader : (isOccupied ? const Color(0xFFFEF2F2) : Colors.white),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? const Color(0xFFB45309) : (isOccupied ? Colors.red.shade300 : Colors.grey.shade300),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.table_restaurant,
                            size: 20,
                            color: isSelected ? const Color(0xFF1E293B) : (isOccupied ? Colors.red.shade700 : const Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            tbl,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? const Color(0xFF1E293B) : (isOccupied ? Colors.red.shade800 : const Color(0xFF1E293B)),
                            ),
                          ),
                          if (isOccupied)
                            Text('Occupied', style: TextStyle(fontSize: 8, color: Colors.red.shade700, fontWeight: FontWeight.bold)),
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
  }

  /// Action A: Saves order as Pending without completing billing
  Future<void> _handleSaveAsPending(BuildContext context, CartState cart) async {
    _syncInputsToCart();

    // Validation: Dine In requires table number
    if (cart.orderType == AppConstants.orderTypeDineIn && (cart.tableNumber == null || cart.tableNumber!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a table number for Dine In orders!'),
          backgroundColor: Colors.red,
        ),
      );
      _showTablePickerModal(context);
      return;
    }

    // Validation: Delivery requires customer name, phone, and delivery address
    if (cart.orderType == AppConstants.orderTypeDelivery) {
      if (cart.customerName.trim().isEmpty ||
          cart.customerPhone.trim().isEmpty ||
          (cart.deliveryAddress == null || cart.deliveryAddress!.trim().isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Delivery orders require customer name, phone number, and delivery address!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    try {
      final invoiceRepo = ref.read(invoiceRepositoryProvider);
      final currentUser = ref.read(currentUserProvider);

      final itemsCompanions = cart.items.map((ci) {
        final tax = ci.taxCalculation;
        return InvoiceItemsCompanion.insert(
          id: _uuid.v4(),
          invoiceId: '', // bound by repo in transaction
          productId: drift.Value(ci.product.id),
          productName: ci.product.name,
          productCode: drift.Value(ci.product.code),
          unit: ci.product.unit,
          unitPricePaise: ci.product.sellingPricePaise,
          quantity: ci.quantity,
          discountPaise: drift.Value(ci.discountPaise),
          taxableAmountPaise: tax.taxableAmountPaise,
          gstRatePercent: ci.product.gstRatePercent,
          isTaxInclusive: ci.product.isTaxInclusive,
          taxAmountPaise: tax.totalTaxPaise,
          totalAmountPaise: tax.totalAmountPaise,
        );
      }).toList();

      final savedInvoiceId = await invoiceRepo.saveOrUpdatePendingOrder(
        existingInvoiceId: cart.pendingInvoiceId,
        invoiceNumber: cart.existingInvoiceNumber,
        customerName: _customerNameController.text.trim().isEmpty ? null : _customerNameController.text.trim(),
        customerPhone: _customerPhoneController.text.trim().isEmpty ? null : _customerPhoneController.text.trim(),
        orderType: cart.orderType,
        tableNumber: cart.tableNumber,
        deliveryAddress: _deliveryAddressController.text.trim().isEmpty ? null : _deliveryAddressController.text.trim(),
        subtotalPaise: cart.subtotalPaise,
        itemDiscountTotalPaise: cart.itemDiscountTotalPaise,
        billDiscountPaise: cart.billDiscountPaise,
        taxableAmountPaise: cart.taxableAmountPaise,
        cgstPaise: cart.cgstPaise,
        sgstPaise: cart.sgstPaise,
        roundOffPaise: cart.roundOffPaise,
        grandTotalPaise: cart.grandTotalPaise,
        cashierId: currentUser?.id ?? 'cashier',
        cashierName: currentUser?.fullName ?? 'Cashier',
        billNote: _noteController.text.trim(),
        items: itemsCompanions,
      );

      // Clear the active cart only after successful saving
      ref.read(cartProvider.notifier).clear();
      _customerNameController.clear();
      _customerPhoneController.clear();
      _deliveryAddressController.clear();
      _noteController.clear();

      if (!context.mounted) return;

      // Show success modal with KOT printing option & navigation
      _showPendingSavedDialog(context, savedInvoiceId);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save pending order: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showPendingSavedDialog(BuildContext context, String invoiceId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 28),
              SizedBox(width: 8),
              Text('Order Saved as Pending', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: const Text(
            'The order has been safely saved with status PENDING. You can reopen it anytime from Order History to add more items or collect payment.',
            style: TextStyle(fontSize: 13, color: Color(0xFF334155)),
          ),
          actions: [
            OutlinedButton.icon(
              icon: const Icon(Icons.print, size: 18),
              label: const Text('Print KOT'),
              onPressed: () async {
                final repo = ref.read(invoiceRepositoryProvider);
                final settings = await ref.read(settingsRepositoryProvider).getAllSettings();
                final details = await repo.getInvoiceWithDetails(invoiceId);
                if (details != null && dialogCtx.mounted) {
                  await InvoicePdfGenerator.printKot(details: details, settings: settings);
                }
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.posYellowHeader,
                foregroundColor: const Color(0xFF1E293B),
              ),
              onPressed: () {
                Navigator.pop(dialogCtx);
                context.go('/history');
              },
              child: const Text('View in History', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  /// Action B: Proceed to bill generation & payment workflow
  Future<void> _handleProceedToBill(BuildContext context, CartState cart) async {
    _syncInputsToCart();

    // Validation: Dine In requires table number
    if (cart.orderType == AppConstants.orderTypeDineIn && (cart.tableNumber == null || cart.tableNumber!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a table number for Dine In orders!'),
          backgroundColor: Colors.red,
        ),
      );
      _showTablePickerModal(context);
      return;
    }

    // Validation: Delivery requires customer name, phone, and delivery address
    if (cart.orderType == AppConstants.orderTypeDelivery) {
      if (cart.customerName.trim().isEmpty ||
          cart.customerPhone.trim().isEmpty ||
          (cart.deliveryAddress == null || cart.deliveryAddress!.trim().isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Delivery orders require customer name, phone number, and delivery address!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    _showCheckoutPaymentDialog(context, cart);
  }

  void _showCheckoutPaymentDialog(BuildContext context, CartState cart) {
    String selectedPaymentMethod = AppConstants.paymentCash;
    int amountPaidPaise = cart.grandTotalPaise;
    final paidController = TextEditingController(text: CurrencyFormatter.paiseToRupees(amountPaidPaise).toStringAsFixed(2));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final double enteredRupees = double.tryParse(paidController.text) ?? 0.0;
            final int currentPaidPaise = CurrencyFormatter.rupeesToPaise(enteredRupees);
            final int balanceDuePaise = cart.grandTotalPaise > currentPaidPaise ? cart.grandTotalPaise - currentPaidPaise : 0;
            final int changePaise = currentPaidPaise > cart.grandTotalPaise ? currentPaidPaise - cart.grandTotalPaise : 0;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Complete Billing & Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(dialogCtx),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Grand Total Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Bill Amount:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(
                            CurrencyFormatter.formatPaise(cart.grandTotalPaise),
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF92400E)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Payment Method selector
                    const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        AppConstants.paymentCash,
                        AppConstants.paymentUpi,
                        AppConstants.paymentCard,
                        AppConstants.paymentDue,
                      ].map((method) {
                        final isSelected = selectedPaymentMethod == method;
                        return ChoiceChip(
                          label: Text(method),
                          selected: isSelected,
                          selectedColor: AppTheme.posYellowHeader,
                          labelStyle: TextStyle(
                            color: isSelected ? const Color(0xFF1E293B) : Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          onSelected: (val) {
                            if (val) setDialogState(() => selectedPaymentMethod = method);
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 14),

                    // Amount Paid Input
                    TextField(
                      controller: paidController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Amount Paid (₹)',
                        prefixText: '₹ ',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),

                    const SizedBox(height: 8),

                    // Quick Cash Chips
                    Wrap(
                      spacing: 6,
                      children: [
                        ActionChip(
                          label: const Text('Exact', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          onPressed: () {
                            setDialogState(() {
                              paidController.text = CurrencyFormatter.paiseToRupees(cart.grandTotalPaise).toStringAsFixed(2);
                            });
                          },
                        ),
                        ...[100, 200, 500, 1000, 2000].map((rupees) {
                          return ActionChip(
                            label: Text('₹$rupees', style: const TextStyle(fontSize: 11)),
                            onPressed: () {
                              setDialogState(() {
                                paidController.text = rupees.toDouble().toStringAsFixed(2);
                              });
                            },
                          );
                        }),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Balance / Change indicators
                    if (changePaise > 0)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Change to return:', style: TextStyle(color: Color(0xFF15803D), fontWeight: FontWeight.bold)),
                            Text(CurrencyFormatter.formatPaise(changePaise), style: const TextStyle(color: Color(0xFF15803D), fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
                    if (balanceDuePaise > 0)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(6)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Balance Due / Credit:', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
                            Text(CurrencyFormatter.formatPaise(balanceDuePaise), style: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                // Option to Print KOT before finishing
                TextButton.icon(
                  icon: const Icon(Icons.print_outlined, size: 16),
                  label: const Text('Print KOT'),
                  onPressed: () async {
                    final settings = await ref.read(settingsRepositoryProvider).getAllSettings();
                    // Generate draft KOT details for preview
                    final draftDetails = _createDraftInvoiceDetails(cart);
                    await InvoicePdfGenerator.printKot(details: draftDetails, settings: settings);
                  },
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.posYellowHeader,
                    foregroundColor: const Color(0xFF1E293B),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Complete & Print Bill', style: TextStyle(fontWeight: FontWeight.w900)),
                  onPressed: () async {
                    Navigator.pop(dialogCtx);
                    await _finalizeOrderAndPrintBill(
                      context,
                      cart,
                      selectedPaymentMethod,
                      currentPaidPaise,
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  InvoiceDetails _createDraftInvoiceDetails(CartState cart) {
    final now = DateTime.now();
    final invoice = InvoiceEntry(
      id: cart.pendingInvoiceId ?? _uuid.v4(),
      invoiceNumber: cart.existingInvoiceNumber ?? 'DRAFT',
      createdAt: now,
      subtotalPaise: cart.subtotalPaise,
      itemDiscountTotalPaise: cart.itemDiscountTotalPaise,
      billDiscountPaise: cart.billDiscountPaise,
      taxableAmountPaise: cart.taxableAmountPaise,
      cgstPaise: cart.cgstPaise,
      sgstPaise: cart.sgstPaise,
      igstPaise: 0,
      roundOffPaise: cart.roundOffPaise,
      grandTotalPaise: cart.grandTotalPaise,
      paidAmountPaise: 0,
      paymentMethod: cart.paymentMethod,
      paymentStatus: AppConstants.statusPending,
      orderStatus: AppConstants.orderPending,
      orderType: cart.orderType,
      tableNumber: cart.tableNumber,
      customerName: cart.customerName,
      customerPhone: cart.customerPhone,
      deliveryAddress: cart.deliveryAddress,
      isCancelled: false,
    );

    final items = cart.items.map((ci) {
      final tax = ci.taxCalculation;
      return InvoiceItemEntry(
        id: _uuid.v4(),
        invoiceId: invoice.id,
        productId: ci.product.id,
        productName: ci.product.name,
        productCode: ci.product.code,
        unit: ci.product.unit,
        unitPricePaise: ci.product.sellingPricePaise,
        quantity: ci.quantity,
        discountPaise: ci.discountPaise,
        taxableAmountPaise: tax.taxableAmountPaise,
        gstRatePercent: ci.product.gstRatePercent,
        isTaxInclusive: ci.product.isTaxInclusive,
        taxAmountPaise: tax.totalTaxPaise,
        totalAmountPaise: tax.totalAmountPaise,
      );
    }).toList();

    return InvoiceDetails(
      invoice: invoice,
      items: items,
      billNote: cart.billNote.isNotEmpty
          ? BillNoteEntry(
              id: 'note',
              invoiceId: invoice.id,
              note: cart.billNote,
              isCustomerFacing: true,
              createdAt: now,
              updatedAt: now,
            )
          : null,
      payments: const [],
    );
  }

  Future<void> _finalizeOrderAndPrintBill(
    BuildContext context,
    CartState cart,
    String paymentMethod,
    int paidAmountPaise,
  ) async {
    try {
      final invoiceRepo = ref.read(invoiceRepositoryProvider);
      final currentUser = ref.read(currentUserProvider);
      final settings = await ref.read(settingsRepositoryProvider).getAllSettings();
      final now = DateTime.now();

      final paymentStatus = paidAmountPaise >= cart.grandTotalPaise
          ? AppConstants.statusPaid
          : (paidAmountPaise > 0 ? AppConstants.statusPartial : AppConstants.statusPending);

      final invoiceId = cart.pendingInvoiceId ?? _uuid.v4();
      final invoiceNumber = cart.existingInvoiceNumber ?? await invoiceRepo.generateNextInvoiceNumber();

      final itemsCompanions = cart.items.map((ci) {
        final tax = ci.taxCalculation;
        return InvoiceItemsCompanion.insert(
          id: _uuid.v4(),
          invoiceId: invoiceId,
          productId: drift.Value(ci.product.id),
          productName: ci.product.name,
          productCode: drift.Value(ci.product.code),
          unit: ci.product.unit,
          unitPricePaise: ci.product.sellingPricePaise,
          quantity: ci.quantity,
          discountPaise: drift.Value(ci.discountPaise),
          taxableAmountPaise: tax.taxableAmountPaise,
          gstRatePercent: ci.product.gstRatePercent,
          isTaxInclusive: ci.product.isTaxInclusive,
          taxAmountPaise: tax.totalTaxPaise,
          totalAmountPaise: tax.totalAmountPaise,
        );
      }).toList();

      final paymentCompanion = paidAmountPaise > 0
          ? PaymentsCompanion.insert(
              id: _uuid.v4(),
              invoiceId: invoiceId,
              amountPaise: paidAmountPaise,
              paymentMethod: paymentMethod,
              createdAt: now,
            )
          : null;

      if (cart.pendingInvoiceId != null) {
        // Complete the existing pending order
        await invoiceRepo.saveOrUpdatePendingOrder(
          existingInvoiceId: cart.pendingInvoiceId,
          invoiceNumber: invoiceNumber,
          customerName: cart.customerName.isEmpty ? null : cart.customerName,
          customerPhone: cart.customerPhone.isEmpty ? null : cart.customerPhone,
          orderType: cart.orderType,
          tableNumber: cart.tableNumber,
          deliveryAddress: cart.deliveryAddress,
          subtotalPaise: cart.subtotalPaise,
          itemDiscountTotalPaise: cart.itemDiscountTotalPaise,
          billDiscountPaise: cart.billDiscountPaise,
          taxableAmountPaise: cart.taxableAmountPaise,
          cgstPaise: cart.cgstPaise,
          sgstPaise: cart.sgstPaise,
          roundOffPaise: cart.roundOffPaise,
          grandTotalPaise: cart.grandTotalPaise,
          cashierId: currentUser?.id ?? 'cashier',
          cashierName: currentUser?.fullName ?? 'Cashier',
          billNote: cart.billNote,
          items: itemsCompanions,
        );

        await invoiceRepo.completeOrder(
          invoiceId: invoiceId,
          paidAmountPaise: paidAmountPaise,
          paymentMethod: paymentMethod,
        );
      } else {
        // Brand new completed invoice
        await invoiceRepo.createInvoice(
          CreateInvoiceParams(
            invoice: InvoicesCompanion.insert(
              id: invoiceId,
              invoiceNumber: invoiceNumber,
              createdAt: now,
              customerName: drift.Value(cart.customerName.isEmpty ? null : cart.customerName),
              customerPhone: drift.Value(cart.customerPhone.isEmpty ? null : cart.customerPhone),
              orderType: drift.Value(cart.orderType),
              tableNumber: drift.Value(cart.tableNumber),
              deliveryAddress: drift.Value(cart.deliveryAddress),
              subtotalPaise: cart.subtotalPaise,
              itemDiscountTotalPaise: drift.Value(cart.itemDiscountTotalPaise),
              billDiscountPaise: drift.Value(cart.billDiscountPaise),
              taxableAmountPaise: cart.taxableAmountPaise,
              cgstPaise: drift.Value(cart.cgstPaise),
              sgstPaise: drift.Value(cart.sgstPaise),
              roundOffPaise: drift.Value(cart.roundOffPaise),
              grandTotalPaise: cart.grandTotalPaise,
              paidAmountPaise: paidAmountPaise,
              paymentMethod: drift.Value(paymentMethod),
              paymentStatus: drift.Value(paymentStatus),
              orderStatus: const drift.Value(AppConstants.orderCompleted),
              cashierId: drift.Value(currentUser?.id),
              cashierName: drift.Value(currentUser?.fullName),
            ),
            items: itemsCompanions,
            billNote: cart.billNote,
            payment: paymentCompanion,
          ),
        );
      }

      // Fetch saved invoice for printing
      final details = await invoiceRepo.getInvoiceWithDetails(invoiceId);

      // Clear active cart
      ref.read(cartProvider.notifier).clear();
      _customerNameController.clear();
      _customerPhoneController.clear();
      _deliveryAddressController.clear();
      _noteController.clear();

      if (!context.mounted) return;

      // Offer instant receipt print
      if (details != null) {
        await InvoicePdfGenerator.printInvoice(details: details, settings: settings);
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order $invoiceNumber completed and bill generated!'),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );
      context.go('/history');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Billing error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
