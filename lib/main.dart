import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_constants.dart';
import 'core/database/database_provider.dart';
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

class _FoodBillProAppState extends ConsumerState<FoodBillProApp> {
  @override
  void initState() {
    super.initState();
    _seedDatabase();
  }

  Future<void> _seedDatabase() async {
    try {
      final db = ref.read(databaseProvider);
      final authRepo = AuthRepository(db);
      final categoryRepo = CategoryRepository(db);
      final productRepo = ProductRepository(db);
      await authRepo.seedInitialUsersIfEmpty();
      await categoryRepo.seedDefaultCategoriesIfEmpty();
      await productRepo.seedSampleProductsIfEmpty();
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
