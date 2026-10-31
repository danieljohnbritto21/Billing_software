import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';
import '../../core/sync/sync_provider.dart';
import '../../core/sync/sync_service.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final sync = ref.watch(syncServiceProvider);
  return CategoryRepository(db, sync);
});

final categoriesStreamProvider = StreamProvider<List<CategoryEntry>>((ref) {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.watchCategories();
});

class CategoryWithCount {
  final CategoryEntry category;
  final int productCount;

  const CategoryWithCount({
    required this.category,
    required this.productCount,
  });
}

final categoriesWithCountsStreamProvider =
    StreamProvider<List<CategoryWithCount>>((ref) {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.watchCategoriesWithCounts();
});

class CategoryRepository {
  final AppDatabase _db;
  final SyncService? _sync;
  final _uuid = const Uuid();

  CategoryRepository(this._db, [this._sync]);

  Stream<List<CategoryEntry>> watchCategories({bool activeOnly = false}) {
    var query = _db.select(_db.categories)
      ..where((t) => t.deletedAt.isNull());
    if (activeOnly) {
      query = query..where((t) => t.isActive.equals(true));
    }
    return (query
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.displayOrder, mode: OrderingMode.asc),
            (t) => OrderingTerm(expression: t.name, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  Stream<List<CategoryWithCount>> watchCategoriesWithCounts() {
    return (_db.select(_db.categories)..where((t) => t.deletedAt.isNull()))
        .watch()
        .asyncMap((categories) async {
      final list = <CategoryWithCount>[];
      for (final cat in categories) {
        final count = await getProductCountForCategory(cat.id);
        list.add(CategoryWithCount(category: cat, productCount: count));
      }
      list.sort((a, b) {
        final orderComp = a.category.displayOrder.compareTo(b.category.displayOrder);
        if (orderComp != 0) return orderComp;
        return a.category.name.compareTo(b.category.name);
      });
      return list;
    });
  }

  Future<int> getProductCountForCategory(String categoryId) async {
    final countExp = _db.products.id.count();
    final query = _db.selectOnly(_db.products)
      ..addColumns([countExp])
      ..where(_db.products.categoryId.equals(categoryId) & _db.products.deletedAt.isNull());

    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  Future<List<CategoryEntry>> getAllCategories({bool activeOnly = true}) {
    var query = _db.select(_db.categories)
      ..where((t) => t.deletedAt.isNull());
    if (activeOnly) {
      query = query..where((t) => t.isActive.equals(true));
    }
    return (query
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.displayOrder, mode: OrderingMode.asc),
            (t) => OrderingTerm(expression: t.name, mode: OrderingMode.asc),
          ]))
        .get();
  }

  Future<CategoryEntry?> getCategoryById(String id) {
    return (_db.select(_db.categories)..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
        .getSingleOrNull();
  }

  Future<void> addCategory({
    required String name,
    String? icon,
    int? colorValue,
    int displayOrder = 0,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    await _db.into(_db.categories).insert(
          CategoriesCompanion.insert(
            id: id,
            name: name.trim(),
            icon: Value(icon),
            colorValue: Value(colorValue),
            displayOrder: Value(displayOrder),
            createdAt: now,
            syncStatus: const Value('pending_insert'),
          ),
        );

    _sync?.enqueueChange(
      entityName: 'categories',
      recordId: id,
      operation: 'INSERT',
      payload: {
        'name': name.trim(),
        'icon': icon,
        'colorValue': colorValue,
        'displayOrder': displayOrder,
        'isActive': true,
      },
    );
  }

  Future<void> updateCategory(CategoryEntry category) async {
    await _db.update(_db.categories).replace(
      category.copyWith(syncStatus: const Value('pending_update')),
    );

    _sync?.enqueueChange(
      entityName: 'categories',
      recordId: category.id,
      operation: 'UPDATE',
      payload: {
        'name': category.name,
        'icon': category.icon,
        'colorValue': category.colorValue,
        'displayOrder': category.displayOrder,
        'isActive': category.isActive,
      },
    );
  }

  Future<void> setCategoryActive(String id, bool isActive) async {
    await (_db.update(_db.categories)..where((t) => t.id.equals(id))).write(
      CategoriesCompanion(
        isActive: Value(isActive),
        syncStatus: const Value('pending_update'),
      ),
    );

    _sync?.enqueueChange(
      entityName: 'categories',
      recordId: id,
      operation: 'UPDATE',
      payload: {'isActive': isActive},
    );
  }

  Future<bool> deleteCategory(String id) async {
    final productCount = await getProductCountForCategory(id);
    if (productCount > 0) {
      await setCategoryActive(id, false);
      return false;
    } else {
      await (_db.update(_db.categories)..where((t) => t.id.equals(id))).write(
        CategoriesCompanion(
          deletedAt: Value(DateTime.now()),
          isActive: const Value(false),
          syncStatus: const Value('pending_delete'),
        ),
      );

      _sync?.enqueueChange(
        entityName: 'categories',
        recordId: id,
        operation: 'DELETE',
        payload: {},
      );
      return true;
    }
  }

  Future<void> seedDefaultCategoriesIfEmpty() async {
    final count = await _db.categories.count().getSingle();
    if (count == 0) {
      final defaults = [
        'Fast Food',
        'Beverages',
        'Main Course',
        'Snacks',
        'Bakery',
        'Desserts',
        'Combos',
      ];
      for (var i = 0; i < defaults.length; i++) {
        await _db.into(_db.categories).insert(
              CategoriesCompanion.insert(
                id: _uuid.v4(),
                name: defaults[i],
                displayOrder: Value(i),
                createdAt: DateTime.now(),
              ),
            );
      }
    }
  }
}
