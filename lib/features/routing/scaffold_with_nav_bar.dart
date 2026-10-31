import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_provider.dart';
import '../billing/cart_provider.dart';

class ScaffoldWithNavBar extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({
    super.key,
    required this.navigationShell,
  });

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(authProvider.notifier).logout();
      if (context.mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final isAdmin = currentUser?.role == AppConstants.roleAdmin;
    final cart = ref.watch(cartProvider);

    // Branches in app_router:
    // 0: Dashboard (Admin)
    // 1: Billing / Menu (Admin & Cashier)
    // 2: Products (Admin)
    // 3: Bills (Admin)
    // 4: Categories (Admin)
    // 5: Cashiers (Admin)
    // 6: Settings (Admin & Cashier)
    // 7: Cart (Cashier)
    // 8: History (Cashier)
    final adminBranchMapping = [0, 1, 2, 4, 5, 3, 6];
    // Cashier navigation has exactly 4 tabs: 1. Menu (/billing), 2. Cart (/cart), 3. History (/history), 4. Settings (/settings)
    final cashierBranchMapping = [1, 7, 8, 6];

    final branchMapping = isAdmin ? adminBranchMapping : cashierBranchMapping;

    int selectedNavIndex = branchMapping.indexOf(navigationShell.currentIndex);
    if (selectedNavIndex == -1) {
      selectedNavIndex = 0;
    }

    final adminDestinations = const [
      NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      NavigationDestination(
        icon: Icon(Icons.point_of_sale_outlined),
        selectedIcon: Icon(Icons.point_of_sale),
        label: 'Billing',
      ),
      NavigationDestination(
        icon: Icon(Icons.restaurant_menu_outlined),
        selectedIcon: Icon(Icons.restaurant_menu),
        label: 'Products',
      ),
      NavigationDestination(
        icon: Icon(Icons.category_outlined),
        selectedIcon: Icon(Icons.category),
        label: 'Categories',
      ),
      NavigationDestination(
        icon: Icon(Icons.people_outline),
        selectedIcon: Icon(Icons.people),
        label: 'Staff',
      ),
      NavigationDestination(
        icon: Icon(Icons.receipt_long_outlined),
        selectedIcon: Icon(Icons.receipt_long),
        label: 'Bills',
      ),
      NavigationDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings),
        label: 'Settings',
      ),
    ];

    final cashierDestinations = [
      const NavigationDestination(
        icon: Icon(Icons.restaurant_menu_outlined),
        selectedIcon: Icon(Icons.restaurant_menu),
        label: 'Menu',
      ),
      NavigationDestination(
        icon: Badge(
          isLabelVisible: cart.isNotEmpty,
          label: Text('${cart.items.length}'),
          backgroundColor: const Color(0xFFDC2626),
          child: const Icon(Icons.shopping_cart_outlined),
        ),
        selectedIcon: Badge(
          isLabelVisible: cart.isNotEmpty,
          label: Text('${cart.items.length}'),
          backgroundColor: const Color(0xFFDC2626),
          child: const Icon(Icons.shopping_cart),
        ),
        label: 'Cart',
      ),
      const NavigationDestination(
        icon: Icon(Icons.history_outlined),
        selectedIcon: Icon(Icons.history),
        label: 'History',
      ),
      const NavigationDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings),
        label: 'Settings',
      ),
    ];

    return Scaffold(
      // Top Admin App Bar (only shown for Admin; Cashier has custom dedicated yellow top header on Menu & Cart)
      appBar: isAdmin
          ? PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SafeArea(
                  child: Row(
                    children: [
                      // Logo & App Name
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.point_of_sale_rounded,
                          color: AppTheme.primaryGreen,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'FoodBill Pro',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textDark,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const Spacer(),
                      // Active User Profile & Role Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified_user,
                              size: 14,
                              color: Color(0xFF15803D),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              currentUser?.fullName ?? 'Admin',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF15803D),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '• Admin',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Logout action button
                      IconButton(
                        icon: const Icon(Icons.logout, size: 20, color: AppTheme.textMuted),
                        tooltip: 'Logout',
                        onPressed: () => _handleLogout(context, ref),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedNavIndex,
        onDestinationSelected: (index) {
          final targetBranch = branchMapping[index];
          navigationShell.goBranch(
            targetBranch,
            initialLocation: targetBranch == navigationShell.currentIndex,
          );
        },
        destinations: isAdmin ? adminDestinations : cashierDestinations,
        elevation: 3,
        height: 65,
        backgroundColor: Colors.white,
        indicatorColor: isAdmin ? AppTheme.primaryGreen.withValues(alpha: 0.15) : AppTheme.posYellowHeader,
      ),
    );
  }
}
