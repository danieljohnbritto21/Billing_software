import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/database/app_database.dart';
import '../auth/auth_provider.dart';
import '../auth/cashiers_screen.dart';
import '../auth/login_screen.dart';
import '../billing/billing_screen.dart';
import '../billing/cashier_cart_screen.dart';
import '../billing/cashier_menu_screen.dart';
import '../categories/categories_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../invoices/bill_details_screen.dart';
import '../invoices/bills_history_screen.dart';
import '../invoices/cashier_history_screen.dart';
import '../printer/printer_management_screen.dart';
import '../products/add_edit_product_screen.dart';
import '../products/products_screen.dart';
import '../purchases/create_purchase_order_screen.dart';
import '../purchases/purchase_invoice_detail_screen.dart';
import '../purchases/purchase_invoices_screen.dart';
import '../purchases/purchase_order_detail_screen.dart';
import '../purchases/purchase_orders_screen.dart';
import '../purchases/supplier_payment_screen.dart';
import '../settings/settings_screen.dart';
import '../supplier_portal/add_edit_supplier_product_screen.dart';
import '../supplier_portal/create_supplier_invoice_screen.dart';
import '../supplier_portal/supplier_catalog_screen.dart';
import '../supplier_portal/supplier_dashboard_screen.dart';
import '../supplier_portal/supplier_invoice_detail_screen.dart';
import '../supplier_portal/supplier_invoices_screen.dart';
import '../supplier_portal/supplier_ledger_screen.dart';
import '../supplier_portal/supplier_profile_screen.dart';
import '../supplier_portal/supplier_purchase_order_detail_screen.dart';
import '../supplier_portal/supplier_purchase_orders_screen.dart';
import '../supplier_portal/supplier_scaffold_with_nav.dart';
import '../suppliers/add_edit_supplier_screen.dart';
import '../suppliers/supplier_detail_screen.dart';
import '../suppliers/suppliers_list_screen.dart';
import 'scaffold_with_nav_bar.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorDashboardKey = GlobalKey<NavigatorState>();
final _shellNavigatorBillingKey = GlobalKey<NavigatorState>();
final _shellNavigatorCartKey = GlobalKey<NavigatorState>();
final _shellNavigatorHistoryKey = GlobalKey<NavigatorState>();
final _shellNavigatorProductsKey = GlobalKey<NavigatorState>();
final _shellNavigatorBillsKey = GlobalKey<NavigatorState>();
final _shellNavigatorCategoriesKey = GlobalKey<NavigatorState>();
final _shellNavigatorCashiersKey = GlobalKey<NavigatorState>();
final _shellNavigatorSettingsKey = GlobalKey<NavigatorState>();

// Supplier Shell Navigator Keys
final _supplierNavigatorDashboardKey = GlobalKey<NavigatorState>();
final _supplierNavigatorCatalogKey = GlobalKey<NavigatorState>();
final _supplierNavigatorOrdersKey = GlobalKey<NavigatorState>();
final _supplierNavigatorInvoicesKey = GlobalKey<NavigatorState>();
final _supplierNavigatorLedgerKey = GlobalKey<NavigatorState>();

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  RouterNotifier(this._ref) {
    _ref.listen(authProvider, (_, __) => notifyListeners());
  }
}

/// Pure routing access policy logic, exported for testability and route guarding
String? checkRouteAccess({required UserEntry? user, required String location}) {
  final isLoggingIn = location == '/login';

  if (user == null || !user.isActive) {
    return isLoggingIn ? null : '/login';
  }

  // If user is authenticated and attempts to visit login screen
  if (isLoggingIn) {
    if (user.role == AppConstants.roleSupplier) {
      return '/supplier/dashboard';
    }
    return user.role == AppConstants.roleAdmin ? '/dashboard' : '/billing';
  }

  // Supplier role route protection: suppliers can ONLY access /supplier/*
  if (user.role == AppConstants.roleSupplier) {
    if (!location.startsWith('/supplier')) {
      return '/supplier/dashboard';
    }
    return null;
  }

  // Admin role route protection: cannot directly browse /supplier/* (use admin /suppliers and /purchases instead)
  if (user.role == AppConstants.roleAdmin) {
    if (location.startsWith('/supplier')) {
      return '/dashboard';
    }
  }

  // Cashier role protection: strictly prevent cashier from accessing admin-only pages
  if (user.role == AppConstants.roleCashier) {
    final isCashierAllowed = location.startsWith('/billing') ||
        location.startsWith('/cart') ||
        location.startsWith('/history') ||
        location.startsWith('/settings') ||
        location.startsWith('/bills') ||
        location == '/products/add' ||
        location.startsWith('/products/edit');
    if (!isCashierAllowed) {
      return '/billing';
    }
  }

  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      return checkRouteAccess(user: authState.user, location: state.matchedLocation);
    },
    routes: [
      // Standalone Login Route
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // =======================================================================
      // ADMIN & POS SHELL NAVIGATION
      // =======================================================================
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Dashboard (Admin)
          StatefulShellBranch(
            navigatorKey: _shellNavigatorDashboardKey,
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),

          // Branch 1: Menu / POS Billing (Cashier & Admin)
          StatefulShellBranch(
            navigatorKey: _shellNavigatorBillingKey,
            routes: [
              GoRoute(
                path: '/billing',
                builder: (context, state) {
                  final user = ref.watch(currentUserProvider);
                  if (user?.role == AppConstants.roleCashier) {
                    return const CashierMenuScreen();
                  }
                  return const BillingScreen();
                },
              ),
            ],
          ),

          // Branch 2: Products (Admin)
          StatefulShellBranch(
            navigatorKey: _shellNavigatorProductsKey,
            routes: [
              GoRoute(
                path: '/products',
                builder: (context, state) => const ProductsScreen(),
                routes: [
                  GoRoute(
                    path: 'add',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const AddEditProductScreen(),
                  ),
                  GoRoute(
                    path: 'edit/:id',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final id = state.pathParameters['id'];
                      return AddEditProductScreen(productId: id);
                    },
                  ),
                ],
              ),
            ],
          ),

          // Branch 3: Bills & Orders (Admin view)
          StatefulShellBranch(
            navigatorKey: _shellNavigatorBillsKey,
            routes: [
              GoRoute(
                path: '/bills',
                builder: (context, state) => const BillsHistoryScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return BillDetailsScreen(invoiceId: id);
                    },
                  ),
                ],
              ),
            ],
          ),

          // Branch 4: Categories (Admin)
          StatefulShellBranch(
            navigatorKey: _shellNavigatorCategoriesKey,
            routes: [
              GoRoute(
                path: '/categories',
                builder: (context, state) => const CategoriesScreen(),
              ),
            ],
          ),

          // Branch 5: Cashiers / Staff (Admin)
          StatefulShellBranch(
            navigatorKey: _shellNavigatorCashiersKey,
            routes: [
              GoRoute(
                path: '/cashiers',
                builder: (context, state) => const CashiersScreen(),
              ),
            ],
          ),

          // Branch 6: Settings (Admin & Cashier)
          StatefulShellBranch(
            navigatorKey: _shellNavigatorSettingsKey,
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'printer',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const PrinterManagementScreen(),
                  ),
                ],
              ),
            ],
          ),

          // Branch 7: Cart Screen (Cashier POS)
          StatefulShellBranch(
            navigatorKey: _shellNavigatorCartKey,
            routes: [
              GoRoute(
                path: '/cart',
                builder: (context, state) => const CashierCartScreen(),
              ),
            ],
          ),

          // Branch 8: Order History Screen (Cashier POS)
          StatefulShellBranch(
            navigatorKey: _shellNavigatorHistoryKey,
            routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) => const CashierHistoryScreen(),
              ),
            ],
          ),
        ],
      ),

      // =======================================================================
      // ADMIN SUPPLIERS & PROCUREMENT ROUTES (Root Navigator)
      // =======================================================================
      GoRoute(
        path: '/suppliers',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SuppliersListScreen(),
        routes: [
          GoRoute(
            path: 'add',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const AddEditSupplierScreen(),
          ),
          GoRoute(
            path: ':id',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return SupplierDetailScreen(supplierId: id);
            },
            routes: [
              GoRoute(
                path: 'edit',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return AddEditSupplierScreen(supplierId: id);
                },
              ),
            ],
          ),
        ],
      ),

      // Admin Purchase Orders Routes
      GoRoute(
        path: '/purchases/orders',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PurchaseOrdersScreen(),
        routes: [
          GoRoute(
            path: 'create',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) {
              final supplierId = state.uri.queryParameters['supplierId'];
              return CreatePurchaseOrderScreen(initialSupplierId: supplierId);
            },
          ),
          GoRoute(
            path: ':id',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return PurchaseOrderDetailScreen(orderId: id);
            },
          ),
        ],
      ),

      // Admin Purchase Invoices Routes
      GoRoute(
        path: '/purchases/invoices',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PurchaseInvoicesScreen(),
        routes: [
          GoRoute(
            path: ':id',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return PurchaseInvoiceDetailScreen(invoiceId: id);
            },
            routes: [
              GoRoute(
                path: 'pay',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return SupplierPaymentScreen(invoiceId: id);
                },
              ),
            ],
          ),
        ],
      ),

      // =======================================================================
      // SUPPLIER PORTAL SHELL & ROUTES
      // =======================================================================
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return SupplierScaffoldWithNav(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Supplier Dashboard
          StatefulShellBranch(
            navigatorKey: _supplierNavigatorDashboardKey,
            routes: [
              GoRoute(
                path: '/supplier/dashboard',
                builder: (context, state) => const SupplierDashboardScreen(),
              ),
            ],
          ),

          // Branch 1: Supplier Catalog
          StatefulShellBranch(
            navigatorKey: _supplierNavigatorCatalogKey,
            routes: [
              GoRoute(
                path: '/supplier/catalog',
                builder: (context, state) => const SupplierCatalogScreen(),
                routes: [
                  GoRoute(
                    path: 'add',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const AddEditSupplierProductScreen(),
                  ),
                  GoRoute(
                    path: 'edit/:id',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return AddEditSupplierProductScreen(productId: id);
                    },
                  ),
                ],
              ),
            ],
          ),

          // Branch 2: Supplier Purchase Orders
          StatefulShellBranch(
            navigatorKey: _supplierNavigatorOrdersKey,
            routes: [
              GoRoute(
                path: '/supplier/orders',
                builder: (context, state) => const SupplierPurchaseOrdersScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return SupplierPurchaseOrderDetailScreen(orderId: id);
                    },
                  ),
                ],
              ),
            ],
          ),

          // Branch 3: Supplier Invoices
          StatefulShellBranch(
            navigatorKey: _supplierNavigatorInvoicesKey,
            routes: [
              GoRoute(
                path: '/supplier/invoices',
                builder: (context, state) => const SupplierInvoicesScreen(),
                routes: [
                  GoRoute(
                    path: 'create',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final poId = state.uri.queryParameters['purchaseOrderId'];
                      final prodId = state.uri.queryParameters['productId'];
                      return CreateSupplierInvoiceScreen(
                        purchaseOrderId: poId,
                        initialProductId: prodId,
                      );
                    },
                  ),
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return SupplierInvoiceDetailScreen(invoiceId: id);
                    },
                  ),
                ],
              ),
            ],
          ),

          // Branch 4: Supplier Ledger
          StatefulShellBranch(
            navigatorKey: _supplierNavigatorLedgerKey,
            routes: [
              GoRoute(
                path: '/supplier/ledger',
                builder: (context, state) => const SupplierLedgerScreen(),
              ),
            ],
          ),
        ],
      ),

      // Standalone Supplier Profile Route
      GoRoute(
        path: '/supplier/profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SupplierProfileScreen(),
      ),
    ],
  );
});
