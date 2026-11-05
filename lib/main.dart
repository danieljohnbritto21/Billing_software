import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_constants.dart';
import 'core/database/database_provider.dart';
import 'core/sync/sync_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_repository.dart';
import 'features/categories/category_repository.dart';
import 'features/products/product_repository.dart';
import 'features/routing/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style for seamless edge-to-edge feel
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    const ProviderScope(
      child: FoodBillProApp(),
    ),
  );
}

class FoodBillProApp extends ConsumerStatefulWidget {
  const FoodBillProApp({super.key});

  @override
  ConsumerState<FoodBillProApp> createState() => _FoodBillProAppState();
}

class _FoodBillProAppState extends ConsumerState<FoodBillProApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _seedDatabase();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Whenever app is resumed/unlocked/brought to foreground, trigger sync immediately
      try {
        ref.read(syncServiceProvider).syncNow();
      } catch (_) {}
    }
  }

  Future<void> _seedDatabase() async {
    try {
      final db = ref.read(databaseProvider);
      final api = ref.read(apiClientProvider);
      await api.restoreSavedAuth();

      final authRepo = AuthRepository(db, api);
      final categoryRepo = CategoryRepository(db);
      final productRepo = ProductRepository(db);
      await authRepo.seedInitialUsersIfEmpty();
      await categoryRepo.seedDefaultCategoriesIfEmpty();
      await productRepo.seedSampleProductsIfEmpty();

      // Trigger initial sync if authorized
      final sync = ref.read(syncServiceProvider);
      sync.syncNow();
    } catch (_) {
      // Seeding is best-effort; the app is functional without it
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
