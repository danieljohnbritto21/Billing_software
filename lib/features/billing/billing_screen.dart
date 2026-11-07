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
import '../categories/category_repository.dart';
import '../invoices/invoice_repository.dart';
import '../printer/invoice_pdf_generator.dart';
import '../products/product_repository.dart';
import '../settings/settings_repository.dart';
import '../../core/sync/sync_provider.dart';
import 'cart_provider.dart';

final billingSearchProvider = StateProvider<String>((ref) => '');
final billingCategoryProvider = StateProvider<String>((ref) => 'ALL');

class BillingScreen extends ConsumerStatefulWidget {
  const BillingScreen({super.key});

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final search = ref.watch(billingSearchProvider);
    final selectedCategory = ref.watch(billingCategoryProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final productRepo = ref.watch(productRepositoryProvider);
    final cart = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('POS Billing'),
        actions: [
          if (cart.isNotEmpty)
            TextButton.icon(
              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
              label: const Text('Clear', style: TextStyle(color: Colors.red)),
              onPressed: () {
                ref.read(cartProvider.notifier).clear();
              },
            ),
        ],
      ),
      bottomNavigationBar: cart.isNotEmpty
          ? _FloatingCartBar(
              cart: cart,
              onTap: () => _openCheckoutBottomSheet(context),
            )
          : null,
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search menu item to add...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
                suffixIcon: search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () =>
                            ref.read(billingSearchProvider.notifier).state = '',
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
              onChanged: (val) {
                ref.read(billingSearchProvider.notifier).state = val;
              },
            ),
          ),

          // Categories Filter
          categoriesAsync.when(
            data: (categories) {
              return SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('All'),
                        selected: selectedCategory == 'ALL',
                        onSelected: (_) =>
                            ref.read(billingCategoryProvider.notifier).state = 'ALL',
                        selectedColor: const Color(0xFFDCFCE7),
                        checkmarkColor: AppTheme.primaryGreen,
                        labelStyle: TextStyle(
                          color: selectedCategory == 'ALL'
                              ? AppTheme.primaryGreen
                              : AppTheme.textDark,
                          fontWeight: selectedCategory == 'ALL'
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 12,
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
                              .read(billingCategoryProvider.notifier)
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
                            fontSize: 12,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
            loading: () => const SizedBox(height: 44),
            error: (_, __) => const SizedBox(height: 44),
          ),

          const SizedBox(height: 4),

          // Menu Items Grid
          Expanded(
            child: StreamBuilder<List<ProductWithCategory>>(
              stream: productRepo.watchProducts(
                searchQuery: search,
                categoryId: selectedCategory,
                onlyAvailable: true,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final products = snapshot.data ?? [];

                if (products.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.no_meals_outlined,
                              size: 56, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'No Available Items',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Add items in the Products section to start billing.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textMuted),
                          ),
                          const Text(
                            'No products available in the menu yet. Cashiers can add products from the Cashier POS Menu.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    int crossAxisCount = 2;
                    double childAspectRatio = 0.95;
                    if (width > 1200) {
                      crossAxisCount = 5;
                      childAspectRatio = 1.15;
                    } else if (width > 900) {
                      crossAxisCount = 4;
                      childAspectRatio = 1.1;
                    } else if (width > 600) {
                      crossAxisCount = 3;
                      childAspectRatio = 1.0;
                    }

                    return GridView.builder(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        8,
                        16,
                        cart.isNotEmpty ? 100 : 24,
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: childAspectRatio,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final item = products[index];
                        final p = item.product;
                        final primaryImg = item.primaryImage;

                        final matching =
                            cart.items.where((ci) => ci.product.id == p.id);
                        final qtyInCart =
                            matching.isNotEmpty ? matching.first.quantity : 0.0;

                        return Card(
                          elevation: 0,
                          clipBehavior: Clip.antiAlias,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: qtyInCart > 0
                                  ? AppTheme.primaryGreen
                                  : AppTheme.borderLight,
                              width: qtyInCart > 0 ? 2 : 1,
                            ),
                          ),
                          child: InkWell(
                            onTap: () {
                              ref.read(cartProvider.notifier).addProduct(p);
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top Image / Placeholder Banner
                                Expanded(
                                  flex: 5,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      primaryImg != null
                                          ? Image.memory(
                                              primaryImg.imageBytes,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) =>
                                                  _buildCardPlaceholder(),
                                            )
                                          : _buildCardPlaceholder(),
                                      if (qtyInCart > 0)
                                        Positioned(
                                          top: 6,
                                          right: 6,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryGreen,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              '${qtyInCart.toInt()} in cart',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                // Product info area
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
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (item.category != null)
                                              Padding(
                                                padding: const EdgeInsets.only(bottom: 2),
                                                child: Text(
                                                  item.category!.name.toUpperCase(),
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.grey.shade500,
                                                    letterSpacing: 0.5,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            Text(
                                              p.name,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.textDark,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment: CrossAxisAlignment.baseline,
                                          textBaseline: TextBaseline.alphabetic,
                                          children: [
                                            Text(
                                              CurrencyFormatter.formatPaise(
                                                  p.sellingPricePaise),
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                                color: AppTheme.primaryGreen,
                                              ),
                                            ),
                                            Text(
                                              '/${p.unit}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppTheme.textMuted,
                                              ),
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
                      },
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

  Widget _buildCardPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8F5E9), Color(0xFFF1F8E9)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.restaurant_menu,
          color: Colors.green.shade400,
          size: 28,
        ),
      ),
    );
  }

  void _openCheckoutBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CheckoutModal(
        onFinalize: (printDirectly) =>
            _handleCheckout(context, ctx, printDirectly),
        isSaving: _isSaving,
      ),
    );
  }

  Future<void> _handleCheckout(
    BuildContext rootContext,
    BuildContext sheetContext,
    bool printDirectly,
  ) async {
    if (_isSaving) return; // Prevent duplicate clicks
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final invoiceRepo = ref.read(invoiceRepositoryProvider);
      final devService = ref.read(deviceServiceProvider);
      final deviceCode = await devService.getDeviceCode();
      final deviceId = await devService.getDeviceId();
      final settings = await ref.read(settingsRepositoryProvider).getAllSettings();
      final prefix = settings['invoice_prefix'] ?? 'INV-';
      final invoiceNumber =
          await invoiceRepo.generateNextInvoiceNumber(prefix: prefix, deviceCode: deviceCode);

      final uuid = const Uuid();
      final invoiceId = uuid.v4();
      final now = DateTime.now();

      final currentUser = ref.read(currentUserProvider);
      final paymentStatus = cart.paidAmountPaise >= cart.grandTotalPaise
          ? AppConstants.statusPaid
          : (cart.paidAmountPaise > 0
              ? AppConstants.statusPartial
              : AppConstants.statusPending);

      // Build InvoicesCompanion
      final invoice = InvoicesCompanion.insert(
        id: invoiceId,
        invoiceNumber: invoiceNumber,
        createdAt: now,
        customerName: drift.Value(
            cart.customerName.trim().isEmpty ? null : cart.customerName.trim()),
        customerPhone: drift.Value(
            cart.customerPhone.trim().isEmpty ? null : cart.customerPhone.trim()),
        subtotalPaise: cart.subtotalPaise,
        itemDiscountTotalPaise: drift.Value(cart.itemDiscountTotalPaise),
        billDiscountPaise: drift.Value(cart.billDiscountPaise),
        taxableAmountPaise: cart.taxableAmountPaise,
        cgstPaise: drift.Value(cart.cgstPaise),
        sgstPaise: drift.Value(cart.sgstPaise),
        igstPaise: const drift.Value(0),
        roundOffPaise: drift.Value(cart.roundOffPaise),
        grandTotalPaise: cart.grandTotalPaise,
        paymentMethod: drift.Value(cart.paymentMethod),
        paymentStatus: drift.Value(paymentStatus),
        paidAmountPaise: cart.paidAmountPaise,
        orderStatus: const drift.Value(AppConstants.orderCompleted),
        deviceId: drift.Value(deviceId),
        cashierId: drift.Value(currentUser?.id),
        cashierName: drift.Value(currentUser?.fullName ?? currentUser?.username ?? 'Cashier'),
      );

      // Build InvoiceItemsCompanion list
      // Use tax.totalAmountPaise as the authoritative line-item total.
      // For tax-inclusive items this equals the discounted selling price.
      // For tax-exclusive items this equals taxable + GST.
      final items = cart.items.map((ci) {
        final tax = ci.taxCalculation;
        return InvoiceItemsCompanion.insert(
          id: uuid.v4(),
          invoiceId: invoiceId,
          productId: drift.Value(ci.product.id),
          productName: ci.product.name,
          productCode: drift.Value(ci.product.code),
          unit: ci.product.unit,
          unitPricePaise: ci.product.sellingPricePaise,
          quantity: ci.quantity,
          discountPaise: drift.Value(ci.discountPaise),
          gstRatePercent: ci.product.gstRatePercent,
          isTaxInclusive: ci.product.isTaxInclusive,
          taxableAmountPaise: tax.taxableAmountPaise,
          taxAmountPaise: tax.totalTaxPaise,
          totalAmountPaise: tax.totalAmountPaise,
        );
      }).toList();

      // Initial Payment record if customer paid anything
      final payment = cart.paidAmountPaise > 0
          ? PaymentsCompanion.insert(
              id: uuid.v4(),
              invoiceId: invoiceId,
              amountPaise: cart.paidAmountPaise,
              paymentMethod: cart.paymentMethod,
              createdAt: now,
            )
          : null;

      // ATOMIC TRANSACTION: Saves invoice + items + bill note + payment
      await invoiceRepo.createInvoice(
        CreateInvoiceParams(
          invoice: invoice,
          items: items,
          billNote: cart.billNote.trim(),
          isNoteCustomerFacing: cart.isNoteCustomerFacing,
          payment: payment,
        ),
      );

      // Clear cart
      ref.read(cartProvider.notifier).clear();

      if (sheetContext.mounted) Navigator.pop(sheetContext);

      // If print directly requested
      if (printDirectly) {
        final details = await invoiceRepo.getInvoiceWithDetails(invoiceId);
        if (details != null) {
          await InvoicePdfGenerator.printInvoice(
            details: details,
            settings: settings,
          );
        }
      }

      // Show Success Dialog
      if (rootContext.mounted) {
        _showSuccessDialog(rootContext, invoiceId, invoiceNumber, cart.grandTotalPaise);
      }
    } catch (e) {
      if (rootContext.mounted) {
        ScaffoldMessenger.of(rootContext).showSnackBar(
          SnackBar(
            content: Text('Error saving invoice: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSuccessDialog(
    BuildContext context,
    String invoiceId,
    String invoiceNumber,
    int grandTotalPaise,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppTheme.primaryGreen,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Bill Saved Successfully!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                invoiceNumber,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                CurrencyFormatter.formatPaise(grandTotalPaise),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.print_outlined),
                      label: const Text('Print Bill'),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final repo = ref.read(invoiceRepositoryProvider);
                        final settings = await ref
                            .read(settingsRepositoryProvider)
                            .getAllSettings();
                        final details =
                            await repo.getInvoiceWithDetails(invoiceId);
                        if (details != null) {
                          await InvoicePdfGenerator.printInvoice(
                            details: details,
                            settings: settings,
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.receipt_long),
                      label: const Text('View Bill'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.push('/bills/$invoiceId');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Start New Bill'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FloatingCartBar extends StatelessWidget {
  final CartState cart;
  final VoidCallback onTap;

  const _FloatingCartBar({
    required this.cart,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                // Item counter badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${cart.itemCount} items',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (cart.billNote.trim().isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentAmber,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_note, size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Note',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'TOTAL',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.formatPaise(cart.grandTotalPaise),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckoutModal extends ConsumerStatefulWidget {
  final Function(bool printDirectly) onFinalize;
  final bool isSaving;

  const _CheckoutModal({
    required this.onFinalize,
    required this.isSaving,
  });

  @override
  ConsumerState<_CheckoutModal> createState() => _CheckoutModalState();
}

class _CheckoutModalState extends ConsumerState<_CheckoutModal> {
  late TextEditingController _noteController;
  late TextEditingController _discountController;
  late TextEditingController _customerNameController;
  late TextEditingController _customerPhoneController;

  final List<String> _quickNoteChips = [
    'Less spicy',
    'Extra spicy',
    'No onions / garlic',
    'Pack separately',
    'Parcel / Takeaway',
    'Second floor table',
    'Customer will collect later',
    'Advance payment received',
  ];

  @override
  void initState() {
    super.initState();
    final cart = ref.read(cartProvider);
    _noteController = TextEditingController(text: cart.billNote);
    _discountController = TextEditingController(
      text: cart.billDiscountPaise > 0
          ? CurrencyFormatter.paiseToRupees(cart.billDiscountPaise).toStringAsFixed(0)
          : '',
    );
    _customerNameController =
        TextEditingController(text: cart.customerName);
    _customerPhoneController =
        TextEditingController(text: cart.customerPhone);
  }

  @override
  void dispose() {
    _noteController.dispose();
    _discountController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Cart Summary (${cart.itemCount} items)',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),

              // Scrollable Cart Items and Details
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Items List
                    const Text(
                      'Order Items',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    ...cart.items.map((ci) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ci.product.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    '${CurrencyFormatter.formatPaise(ci.product.sellingPricePaise)} / ${ci.product.unit}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Qty Stepper
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline,
                                      size: 22),
                                  color: Colors.grey.shade600,
                                  onPressed: () {
                                    ref
                                        .read(cartProvider.notifier)
                                        .updateQuantity(
                                            ci.product.id, ci.quantity - 1);
                                  },
                                ),
                                Text(
                                  ci.quantity.truncateToDouble() == ci.quantity
                                      ? ci.quantity.toInt().toString()
                                      : ci.quantity.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline,
                                      size: 22),
                                  color: AppTheme.primaryGreen,
                                  onPressed: () {
                                    ref
                                        .read(cartProvider.notifier)
                                        .updateQuantity(
                                            ci.product.id, ci.quantity + 1);
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            // Item Total
                            Text(
                              CurrencyFormatter.formatPaise(ci.finalTotalPaise),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    const Divider(height: 24),

                    // INDIVIDUAL BILL NOTE SECTION (HIGHEST PRIORITY FEATURE)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.noteBannerBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppTheme.noteBannerBorder, width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.edit_note,
                                  color: AppTheme.noteBannerText, size: 20),
                              SizedBox(width: 6),
                              Text(
                                'INDIVIDUAL BILL NOTE',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: AppTheme.noteBannerText,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'This note is permanently saved to this specific invoice only. Can be viewed and edited later.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF78350F),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _noteController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText:
                                  'e.g. Less spicy, Deliver to 2nd floor, Advance paid ₹100',
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.all(10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                    color: AppTheme.noteBannerBorder),
                              ),
                            ),
                            onChanged: (val) {
                              ref.read(cartProvider.notifier).setBillNote(val);
                            },
                          ),
                          const SizedBox(height: 8),
                          // Quick note suggestion chips
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: _quickNoteChips.map((chipText) {
                              return ActionChip(
                                label: Text(chipText,
                                    style: const TextStyle(fontSize: 11)),
                                backgroundColor: Colors.white,
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  final current = _noteController.text.trim();
                                  final updated = current.isEmpty
                                      ? chipText
                                      : '$current, $chipText';
                                  _noteController.text = updated;
                                  ref
                                      .read(cartProvider.notifier)
                                      .setBillNote(updated);
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Customer & Payment Method
                    ExpansionTile(
                      title: const Text(
                        'Customer & Discount (Optional)',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      childrenPadding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _customerNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Customer Name',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                onChanged: (val) {
                                  ref
                                      .read(cartProvider.notifier)
                                      .setCustomer(name: val);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _customerPhoneController,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'Phone',
                                  prefixIcon: Icon(Icons.phone_outlined),
                                ),
                                onChanged: (val) {
                                  ref
                                      .read(cartProvider.notifier)
                                      .setCustomer(phone: val);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _discountController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Bill-Level Discount (₹)',
                            prefixIcon: Icon(Icons.discount_outlined),
                            hintText: '0.00',
                          ),
                          onChanged: (val) {
                            final rupees = double.tryParse(val.trim()) ?? 0.0;
                            ref
                                .read(cartProvider.notifier)
                                .setBillDiscount(CurrencyFormatter.rupeesToPaise(rupees));
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Payment Method Selection
                    const Text(
                      'Payment Method',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: AppConstants.paymentMethods.map((method) {
                        final isSelected = cart.paymentMethod == method;
                        return ChoiceChip(
                          label: Text(method),
                          selected: isSelected,
                          selectedColor: const Color(0xFFDCFCE7),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? AppTheme.primaryGreen
                                : AppTheme.textDark,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          onSelected: (_) {
                            ref
                                .read(cartProvider.notifier)
                                .setPaymentMethod(method);
                          },
                        );
                      }).toList(),
                    ),

                    const Divider(height: 24),

                    // Totals Breakdown
                    _summaryLine('Subtotal', cart.subtotalPaise),
                    if (cart.totalDiscountPaise > 0)
                      _summaryLine('Total Discount', -cart.totalDiscountPaise),
                    _summaryLine('Taxable Value', cart.taxableAmountPaise),
                    if (cart.cgstPaise > 0)
                      _summaryLine('CGST', cart.cgstPaise),
                    if (cart.sgstPaise > 0)
                      _summaryLine('SGST', cart.sgstPaise),
                    if (cart.roundOffPaise != 0)
                      _summaryLine('Round Off', cart.roundOffPaise),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Grand Total',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.formatPaise(cart.grandTotalPaise),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Bottom Action Buttons (Save vs Save & Print)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Save Only Button
                      Expanded(
                        child: OutlinedButton(
                          onPressed: widget.isSaving
                              ? null
                              : () => widget.onFinalize(false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Save Bill'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Save & Print Button
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.print),
                          label: widget.isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : const Text('Save & Print',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: widget.isSaving
                              ? null
                              : () => widget.onFinalize(true),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryLine(String label, int amountPaise) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
          Text(
            CurrencyFormatter.formatPaise(amountPaise),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
