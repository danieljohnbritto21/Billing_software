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
import '../products/add_edit_product_screen.dart';
import '../products/products_screen.dart';
import '../settings/settings_screen.dart';
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
    return user.role == AppConstants.roleAdmin ? '/dashboard' : '/billing';
  }

  // Admin role route protection: Admin manages categories only; strictly prevent Admin from product creation/editing routes
  if (user.role == AppConstants.roleAdmin) {
    if (location == '/products/add' || location.startsWith('/products/edit')) {
      return '/categories';
    }
  }

  // Cashier role protection: strictly prevent cashier from accessing admin-only pages (dashboard, categories, cashiers)
  // Cashier allowed paths: /billing (Menu), /cart (Cart), /history (History), /settings (Settings), /bills/:id (View bill), /products/add (Add Product), /products/edit/:id (Edit Product)
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

      // Shell Route with Navigation
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
                  // Cashier gets the modern yellow reference POS Menu; Admin can also view or switch
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
    ],
  );
});
