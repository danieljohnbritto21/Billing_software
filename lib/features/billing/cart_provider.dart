import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/database/app_database.dart';
import '../../core/utils/currency_formatter.dart';
import '../invoices/invoice_repository.dart';

class CartItem {
  final ProductEntry product;
  final double quantity;
  final int discountPaise; // Item level discount

  const CartItem({
    required this.product,
    this.quantity = 1.0,
    this.discountPaise = 0,
  });

  CartItem copyWith({
    ProductEntry? product,
    double? quantity,
    int? discountPaise,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      discountPaise: discountPaise ?? this.discountPaise,
    );
  }

  int get rawTotalPaise => (product.sellingPricePaise * quantity).round();

  TaxCalculation get taxCalculation => CurrencyFormatter.calculateItemTax(
        unitPricePaise: product.sellingPricePaise,
        quantity: quantity,
        gstRatePercent: product.gstRatePercent,
        isTaxInclusive: product.isTaxInclusive,
        discountPaise: discountPaise,
      );

  /// The final line-item total including tax (for tax-exclusive) or equal to
  /// discounted selling price (for tax-inclusive). This is the authoritative
  /// per-item amount used for cart totals, invoice storage, and receipts.
  int get finalTotalPaise => taxCalculation.totalAmountPaise;
}

class CartState {
  final List<CartItem> items;
  final int billDiscountPaise;
  final String billNote;
  final bool isNoteCustomerFacing;
  final String customerName;
  final String customerPhone;
  final String paymentMethod;
  final int? manualPaidAmountPaise;

  // Restaurant POS Extensions (Reference UI)
  final String orderType; // 'Dine In', 'Takeaway', 'Delivery'
  final String? tableNumber; // e.g. 'Table 5' (required for Dine In)
  final String? deliveryAddress; // for Delivery
  final String? pendingInvoiceId; // Non-null if editing an existing pending order
  final String? existingInvoiceNumber;

  const CartState({
    this.items = const [],
    this.billDiscountPaise = 0,
    this.billNote = '',
    this.isNoteCustomerFacing = true,
    this.customerName = '',
    this.customerPhone = '',
    this.paymentMethod = AppConstants.paymentCash,
    this.manualPaidAmountPaise,
    this.orderType = AppConstants.orderTypeDineIn,
    this.tableNumber,
    this.deliveryAddress,
    this.pendingInvoiceId,
    this.existingInvoiceNumber,
  });

  CartState copyWith({
    List<CartItem>? items,
    int? billDiscountPaise,
    String? billNote,
    bool? isNoteCustomerFacing,
    String? customerName,
    String? customerPhone,
    String? paymentMethod,
    int? manualPaidAmountPaise,
    String? orderType,
    String? tableNumber,
    bool clearTable = false,
    String? deliveryAddress,
    String? pendingInvoiceId,
    bool clearPendingInvoice = false,
    String? existingInvoiceNumber,
  }) {
    return CartState(
      items: items ?? this.items,
      billDiscountPaise: billDiscountPaise ?? this.billDiscountPaise,
      billNote: billNote ?? this.billNote,
      isNoteCustomerFacing: isNoteCustomerFacing ?? this.isNoteCustomerFacing,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      manualPaidAmountPaise: manualPaidAmountPaise ?? this.manualPaidAmountPaise,
      orderType: orderType ?? this.orderType,
      tableNumber: clearTable ? null : (tableNumber ?? this.tableNumber),
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      pendingInvoiceId: clearPendingInvoice ? null : (pendingInvoiceId ?? this.pendingInvoiceId),
      existingInvoiceNumber: clearPendingInvoice ? null : (existingInvoiceNumber ?? this.existingInvoiceNumber),
    );
  }

  int get itemCount => items.length;
  double get totalQuantity => items.fold(0.0, (sum, i) => sum + i.quantity);

  int get subtotalPaise => items.fold(0, (sum, i) => sum + i.rawTotalPaise);

  int get itemDiscountTotalPaise =>
      items.fold(0, (sum, i) => sum + i.discountPaise);

  int get totalDiscountPaise => itemDiscountTotalPaise + billDiscountPaise;

  int get taxableAmountPaise =>
      items.fold(0, (sum, i) => sum + i.taxCalculation.taxableAmountPaise);

  int get cgstPaise =>
      items.fold(0, (sum, i) => sum + i.taxCalculation.cgstPaise);

  int get sgstPaise =>
      items.fold(0, (sum, i) => sum + i.taxCalculation.sgstPaise);

  int get totalTaxPaise => cgstPaise + sgstPaise;

  int get rawGrandTotalPaise {
    // Sum of all line-item totals (each already includes tax for exclusive items
    // and is the discounted amount for inclusive items) minus bill-level discount.
    final itemTotal = items.fold(0, (sum, i) => sum + i.finalTotalPaise);
    final net = itemTotal - billDiscountPaise;
    return net > 0 ? net : 0;
  }

  // Automatic round-off to nearest Rupee
  int get roundOffPaise {
    final raw = rawGrandTotalPaise;
    final nearestRupeePaise = (raw / 100.0).round() * 100;
    return nearestRupeePaise - raw;
  }

  int get grandTotalPaise => rawGrandTotalPaise + roundOffPaise;

  int get paidAmountPaise => manualPaidAmountPaise ?? grandTotalPaise;

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  bool get isEditingPending => pendingInvoiceId != null;
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  void addProduct(ProductEntry product, {double quantity = 1.0}) {
    final index = state.items.indexWhere((i) => i.product.id == product.id);
    if (index >= 0) {
      final current = state.items[index];
      final updated = current.copyWith(quantity: current.quantity + quantity);
      final newItems = List<CartItem>.from(state.items);
      newItems[index] = updated;
      state = state.copyWith(items: newItems);
    } else {
      state = state.copyWith(
        items: [...state.items, CartItem(product: product, quantity: quantity)],
      );
    }
  }

  void updateQuantity(String productId, double quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }
    final index = state.items.indexWhere((i) => i.product.id == productId);
    if (index >= 0) {
      final newItems = List<CartItem>.from(state.items);
      newItems[index] = newItems[index].copyWith(quantity: quantity);
      state = state.copyWith(items: newItems);
    }
  }

  void updateItemDiscount(String productId, int discountPaise) {
    final index = state.items.indexWhere((i) => i.product.id == productId);
    if (index >= 0) {
      final newItems = List<CartItem>.from(state.items);
      newItems[index] = newItems[index].copyWith(discountPaise: discountPaise);
      state = state.copyWith(items: newItems);
    }
  }

  void removeItem(String productId) {
    state = state.copyWith(
      items: state.items.where((i) => i.product.id != productId).toList(),
    );
  }

  void setBillDiscount(int discountPaise) {
    state = state.copyWith(billDiscountPaise: discountPaise);
  }

  void setBillNote(String note, {bool? isCustomerFacing}) {
    state = state.copyWith(
      billNote: note,
      isNoteCustomerFacing: isCustomerFacing ?? state.isNoteCustomerFacing,
    );
  }

  void setCustomer({String? name, String? phone}) {
    state = state.copyWith(
      customerName: name ?? state.customerName,
      customerPhone: phone ?? state.customerPhone,
    );
  }

  void setPaymentMethod(String method) {
    state = state.copyWith(paymentMethod: method);
  }

  void setPaidAmount(int amountPaise) {
    state = state.copyWith(manualPaidAmountPaise: amountPaise);
  }

  void setOrderType(String orderType) {
    state = state.copyWith(
      orderType: orderType,
      clearTable: orderType != AppConstants.orderTypeDineIn,
    );
  }

  void setTableNumber(String? table) {
    state = state.copyWith(tableNumber: table);
  }

  void setDeliveryAddress(String? address) {
    state = state.copyWith(deliveryAddress: address);
  }

  /// Reopens an existing pending order for editing / adding more items
  void loadPendingOrder({
    required InvoiceDetails details,
    required List<ProductEntry> availableProducts,
  }) {
    final cartItems = <CartItem>[];
    for (final invItem in details.items) {
      final match = availableProducts.firstWhere(
        (p) => p.id == (invItem.productId ?? ''),
        orElse: () => ProductEntry(
          id: invItem.productId ?? invItem.id,
          name: invItem.productName,
          code: invItem.productCode,
          sellingPricePaise: invItem.unitPricePaise,
          costPricePaise: 0,
          gstRatePercent: invItem.gstRatePercent,
          isTaxInclusive: invItem.isTaxInclusive,
          unit: invItem.unit,
          isAvailable: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      cartItems.add(
        CartItem(
          product: match,
          quantity: invItem.quantity,
          discountPaise: invItem.discountPaise,
        ),
      );
    }

    state = CartState(
      items: cartItems,
      billDiscountPaise: details.invoice.billDiscountPaise,
      billNote: details.billNote?.note ?? '',
      isNoteCustomerFacing: details.billNote?.isCustomerFacing ?? true,
      customerName: details.invoice.customerName ?? '',
      customerPhone: details.invoice.customerPhone ?? '',
      paymentMethod: details.invoice.paymentMethod,
      orderType: details.invoice.orderType,
      tableNumber: details.invoice.tableNumber,
      deliveryAddress: details.invoice.deliveryAddress,
      pendingInvoiceId: details.invoice.id,
      existingInvoiceNumber: details.invoice.invoiceNumber,
    );
  }

  void clear() {
    state = const CartState();
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
