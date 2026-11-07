import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/database/app_database.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../products/product_repository.dart';
import '../purchases/purchase_repository.dart';
import 'supplier_repository.dart';

class SupplierDetailScreen extends ConsumerStatefulWidget {
  final String supplierId;

  const SupplierDetailScreen({super.key, required this.supplierId});

  @override
  ConsumerState<SupplierDetailScreen> createState() => _SupplierDetailScreenState();
}

class _SupplierDetailScreenState extends ConsumerState<SupplierDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(supplierRepositoryProvider);
    final productRepo = ref.watch(productRepositoryProvider);
    final purchaseRepo = ref.watch(purchaseRepositoryProvider);

    return FutureBuilder<SupplierEntry?>(
      future: repo.getSupplierById(widget.supplierId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final supplier = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: Text(supplier.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit Supplier',
                onPressed: () async {
                  await context.push('/suppliers/edit/${supplier.id}');
                  if (mounted) setState(() {});
                },
              ),
              PopupMenuButton<String>(
                onSelected: (val) async {
                  if (val == 'toggle_active') {
                    await repo.updateSupplierStatus(
                      id: supplier.id,
                      isActive: !supplier.isActive,
                    );
                    if (mounted) setState(() {});
                  } else if (val == 'toggle_verify') {
                    await repo.updateSupplierStatus(
                      id: supplier.id,
                      isVerified: !supplier.isVerified,
                    );
                    if (mounted) setState(() {});
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'toggle_active',
                    child: Text(supplier.isActive ? 'Deactivate Supplier' : 'Activate Supplier'),
                  ),
                  PopupMenuItem(
                    value: 'toggle_verify',
                    child: Text(supplier.isVerified ? 'Mark as Unverified' : 'Mark as Verified'),
                  ),
                ],
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.info_outline), text: 'Overview'),
                Tab(icon: Icon(Icons.restaurant_menu), text: 'Products'),
                Tab(icon: Icon(Icons.receipt_long), text: 'Purchase Orders'),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Create Purchase Order', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => context.push('/purchases/create?supplierId=${supplier.id}'),
              ),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Overview
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Header Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: AppTheme.primaryGreen.withOpacity(0.12),
                              child: const Icon(Icons.storefront, color: AppTheme.primaryGreen, size: 30),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    supplier.name,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Chip(
                                        label: Text(supplier.isActive ? 'Active' : 'Inactive'),
                                        backgroundColor: supplier.isActive ? Colors.green.shade50 : Colors.red.shade50,
                                        labelStyle: TextStyle(
                                          color: supplier.isActive ? Colors.green.shade800 : Colors.red.shade800,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Chip(
                                        label: Text(supplier.isVerified ? 'Verified' : 'Unverified'),
                                        backgroundColor: supplier.isVerified ? Colors.blue.shade50 : Colors.grey.shade100,
                                        labelStyle: TextStyle(
                                          color: supplier.isVerified ? Colors.blue.shade800 : Colors.grey.shade700,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Info List
                    _buildInfoSection('Contact Information', [
                      _buildInfoRow('Contact Person', supplier.contactPerson ?? 'Not provided'),
                      _buildInfoRow('Phone', supplier.phone ?? 'Not provided'),
                      _buildInfoRow('Email', supplier.email ?? 'Not provided'),
                      _buildInfoRow('Address', supplier.address ?? 'Not provided'),
                    ]),
                    const SizedBox(height: 16),

                    _buildInfoSection('Tax & Business Details', [
                      _buildInfoRow('GSTIN', supplier.gstin ?? 'Unregistered'),
                      _buildInfoRow('PAN', supplier.pan ?? 'Not provided'),
                      _buildInfoRow('Payment Terms', supplier.paymentTerms ?? 'Standard (Net 30)'),
                      if (supplier.notes != null) _buildInfoRow('Notes', supplier.notes!),
                    ]),
                  ],
                ),
              ),

              // Tab 2: Products
              StreamBuilder<List<ProductWithCategory>>(
                stream: productRepo.watchSupplierProducts(supplier.id),
                builder: (context, snap) {
                  final prods = snap.data ?? [];
                  if (prods.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 54, color: Colors.grey),
                          const SizedBox(height: 12),
                          Text('No products assigned to ${supplier.name}',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          const Text('Assign products to this supplier in the Products catalog.',
                              style: TextStyle(color: AppTheme.textMuted)),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: prods.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final p = prods[i].product;
                      return ListTile(
                        tileColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Selling: ${CurrencyFormatter.formatPaise(p.sellingPricePaise)} | Cost: ${CurrencyFormatter.formatPaise(p.costPricePaise)}'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: p.isAvailable ? Colors.green.shade50 : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            p.isAvailable ? 'Available' : 'Unavailable',
                            style: TextStyle(
                              color: p.isAvailable ? Colors.green.shade800 : Colors.red.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),

              // Tab 3: Purchase Orders
              StreamBuilder<List<PurchaseOrderEntry>>(
                stream: purchaseRepo.watchPurchaseOrders(supplierId: supplier.id),
                builder: (context, snap) {
                  final orders = snap.data ?? [];
                  if (orders.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.receipt_long_outlined, size: 54, color: Colors.grey),
                          const SizedBox(height: 12),
                          const Text('No purchase orders issued yet',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => context.push('/purchases/create?supplierId=${supplier.id}'),
                            child: const Text('Create Purchase Order'),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final po = orders[i];
                      return ListTile(
                        tileColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        title: Text(po.poNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Total: ${CurrencyFormatter.formatPaise(po.grandTotalPaise)}'),
                        trailing: Chip(label: Text(po.orderStatus)),
                        onTap: () => context.push('/purchases/order/${po.id}'),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
