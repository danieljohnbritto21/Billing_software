import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/api/api_client.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';
import '../../core/sync/sync_provider.dart';
import '../../core/sync/sync_service.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final sync = ref.watch(syncServiceProvider);
  final api = ref.watch(apiClientProvider);
  return ProductRepository(db, sync, api);
});

class ProductWithCategory {
  final ProductEntry product;
  final CategoryEntry? category;
  final SupplierEntry? supplier;
  final ProductImageEntry? primaryImage;

  const ProductWithCategory({
    required this.product,
    this.category,
    this.supplier,
    this.primaryImage,
  });
}

class ProductRepository {
  final AppDatabase _db;
  final SyncService? _sync;
  final ApiClient? _api;
  final _uuid = const Uuid();

  ProductRepository(this._db, [this._sync, this._api]);

  Future<String?> _resolveBusinessId() async {
    final apiBizId = _api?.businessId;
    if (apiBizId != null && apiBizId.isNotEmpty) {
      return apiBizId;
    }
    final setting = await (_db.select(_db.appSettings)..where((s) => s.key.equals('business_id'))).getSingleOrNull();
    return setting?.value;
  }

  Stream<List<ProductWithCategory>> watchProducts({
    String? searchQuery,
    String? categoryId,
    String? supplierId,
    bool onlyAvailable = false,
  }) {
    final query = _db.select(_db.products).join([
      leftOuterJoin(
        _db.categories,
        _db.categories.id.equalsExp(_db.products.categoryId),
      ),
      leftOuterJoin(
        _db.suppliers,
        _db.suppliers.id.equalsExp(_db.products.supplierId),
      ),
    ]);

    query.where(_db.products.deletedAt.isNull());

    if (categoryId != null && categoryId.isNotEmpty && categoryId != 'ALL') {
      query.where(_db.products.categoryId.equals(categoryId));
    }

    if (supplierId != null && supplierId.isNotEmpty && supplierId != 'ALL') {
      query.where(_db.products.supplierId.equals(supplierId));
    }

    if (onlyAvailable) {
      query.where(_db.products.isAvailable.equals(true));
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final term = '%${searchQuery.trim().toLowerCase()}%';
      query.where(
        _db.products.name.lower().like(term) |
            _db.products.code.lower().like(term),
      );
    }

    query.orderBy([
      OrderingTerm(expression: _db.products.name, mode: OrderingMode.asc),
    ]);

    return query.watch().asyncMap((rows) async {
      final list = <ProductWithCategory>[];
      for (final row in rows) {
        final product = row.readTable(_db.products);
        final category = row.readTableOrNull(_db.categories);
        final supplier = row.readTableOrNull(_db.suppliers);
        final primaryImage = await getPrimaryImageForProduct(product.id);
        list.add(ProductWithCategory(
          product: product,
          category: category,
          supplier: supplier,
          primaryImage: primaryImage,
        ));
      }
      return list;
    });
  }

  Stream<List<ProductWithCategory>> watchSupplierProducts(String supplierId) {
    return watchProducts(supplierId: supplierId);
  }

  Future<List<ProductWithCategory>> getAllProducts({
    bool onlyAvailable = false,
    String? supplierId,
  }) async {
    final query = _db.select(_db.products).join([
      leftOuterJoin(
        _db.categories,
        _db.categories.id.equalsExp(_db.products.categoryId),
      ),
      leftOuterJoin(
        _db.suppliers,
        _db.suppliers.id.equalsExp(_db.products.supplierId),
      ),
    ]);

    query.where(_db.products.deletedAt.isNull());

    if (supplierId != null && supplierId.isNotEmpty && supplierId != 'ALL') {
      query.where(_db.products.supplierId.equals(supplierId));
    }

    if (onlyAvailable) {
      query.where(_db.products.isAvailable.equals(true));
    }

    query.orderBy([
      OrderingTerm(expression: _db.products.name, mode: OrderingMode.asc),
    ]);

    final rows = await query.get();
    final list = <ProductWithCategory>[];
    for (final row in rows) {
      final product = row.readTable(_db.products);
      final category = row.readTableOrNull(_db.categories);
      final supplier = row.readTableOrNull(_db.suppliers);
      final primaryImage = await getPrimaryImageForProduct(product.id);
      list.add(ProductWithCategory(
        product: product,
        category: category,
        supplier: supplier,
        primaryImage: primaryImage,
      ));
    }
    return list;
  }

  Future<ProductEntry?> getProductById(String id, {bool includeDeleted = true}) {
    if (includeDeleted) {
      return (_db.select(_db.products)..where((t) => t.id.equals(id)))
          .getSingleOrNull();
    }
    return (_db.select(_db.products)..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
          .getSingleOrNull();
  }

  Future<List<ProductImageEntry>> getImagesForProduct(String productId) {
    return (_db.select(_db.productImages)
          ..where((t) => t.productId.equals(productId))
          ..orderBy([
            (t) => OrderingTerm(expression: t.displayOrder, mode: OrderingMode.asc),
          ]))
        .get();
  }

  Future<ProductImageEntry?> getPrimaryImageForProduct(String productId) {
    return (_db.select(_db.productImages)
          ..where((t) => t.productId.equals(productId) & t.isPrimary.equals(true)))
        .getSingleOrNull();
  }

  Future<void> addProductImage({
    required String productId,
    required Uint8List imageBytes,
    bool isPrimary = false,
    int displayOrder = 0,
  }) async {
    if (isPrimary) {
      await (_db.update(_db.productImages)
            ..where((t) => t.productId.equals(productId)))
          .write(const ProductImagesCompanion(isPrimary: Value(false)));
    }

    if (displayOrder == 0) {
      final existing = await getImagesForProduct(productId);
      displayOrder = existing.length;
    }

    final imageId = _uuid.v4();
    final now = DateTime.now();
    await _db.into(_db.productImages).insert(
          ProductImagesCompanion.insert(
            id: imageId,
            productId: productId,
            imageBytes: imageBytes,
            isPrimary: Value(isPrimary),
            displayOrder: Value(displayOrder),
            createdAt: now,
          ),
        );

    // If online, upload image to server
    final api = _api;
    if (api != null && api.authToken != null) {
      try {
        final base64Img = base64Encode(imageBytes);
        await api.post('/products/$productId/images', body: {
          'id': imageId,
          'imageBase64': base64Img,
          'isPrimary': isPrimary,
          'displayOrder': displayOrder,
        });
      } catch (_) {
        // Preserved in local SQLite
      }
    }
  }

  Future<void> addProductImages(String productId, List<Uint8List> imageBytesList) async {
    final existing = await getImagesForProduct(productId);
    bool hasPrimary = existing.any((img) => img.isPrimary);

    for (int i = 0; i < imageBytesList.length; i++) {
      final isPri = !hasPrimary && i == 0;
      await addProductImage(
        productId: productId,
        imageBytes: imageBytesList[i],
        isPrimary: isPri,
        displayOrder: existing.length + i,
      );
      if (isPri) hasPrimary = true;
    }
  }

  Future<void> setPrimaryImage(String imageId, String productId) async {
    await _db.transaction(() async {
      await (_db.update(_db.productImages)
            ..where((t) => t.productId.equals(productId)))
          .write(const ProductImagesCompanion(isPrimary: Value(false)));

      await (_db.update(_db.productImages)
            ..where((t) => t.id.equals(imageId)))
          .write(const ProductImagesCompanion(isPrimary: Value(true)));
    });
  }

  Future<void> deleteProductImage(String imageId) async {
    final img = await (_db.select(_db.productImages)..where((t) => t.id.equals(imageId))).getSingleOrNull();
    if (img == null) return;

    await (_db.delete(_db.productImages)..where((t) => t.id.equals(imageId))).go();

    if (img.isPrimary) {
      final remaining = await getImagesForProduct(img.productId);
      if (remaining.isNotEmpty) {
        await (_db.update(_db.productImages)..where((t) => t.id.equals(remaining.first.id)))
            .write(const ProductImagesCompanion(isPrimary: Value(true)));
      }
    }

    final api = _api;
    if (api != null && api.authToken != null) {
      try {
        await api.delete('/products/${img.productId}/images/$imageId');
      } catch (_) {}
    }
  }

  Future<String> addProduct({
    required String name,
    String? code,
    String? categoryId,
    String? supplierId,
    String? description,
    required int sellingPricePaise,
    int costPricePaise = 0,
    double gstRatePercent = 0.0,
    bool isTaxInclusive = true,
    String unit = 'plate',
    bool isAvailable = true,
    List<Uint8List>? images,
  }) async {
    final now = DateTime.now();
    final productId = _uuid.v4();
    final bizId = await _resolveBusinessId();

    String? categoryName;
    if (categoryId != null && categoryId.isNotEmpty) {
      final cat = await (_db.select(_db.categories)..where((c) => c.id.equals(categoryId))).getSingleOrNull();
      categoryName = cat?.name;
    }

    final productPayload = {
      'id': productId,
      'businessId': bizId,
      'name': name.trim(),
      'code': code?.trim(),
      'categoryId': categoryId,
      'categoryName': categoryName,
      'supplierId': supplierId,
      'description': description?.trim(),
      'sellingPriceRupees': sellingPricePaise / 100.0,
      'costPriceRupees': costPricePaise / 100.0,
      'sellingPricePaise': sellingPricePaise,
      'costPricePaise': costPricePaise,
      'gstRatePercent': gstRatePercent,
      'isTaxInclusive': isTaxInclusive,
      'unit': unit,
      'isAvailable': isAvailable,
    };

    // ATOMIC TRANSACTION: Write product and syncQueue together to local SQLite
    await _db.transaction(() async {
      await _db.into(_db.products).insert(
            ProductsCompanion.insert(
              id: productId,
              businessId: Value(bizId),
              supplierId: Value(supplierId),
              name: name.trim(),
              code: Value(code?.trim()),
              categoryId: Value(categoryId),
              description: Value(description?.trim()),
              sellingPricePaise: sellingPricePaise,
              costPricePaise: Value(costPricePaise),
              gstRatePercent: Value(gstRatePercent),
              isTaxInclusive: Value(isTaxInclusive),
              unit: Value(unit),
              isAvailable: Value(isAvailable),
              createdAt: now,
              updatedAt: now,
              syncStatus: const Value('pending_insert'),
            ),
          );

      if (_sync != null) {
        await _sync.enqueueChange(
          entityName: 'products',
          recordId: productId,
          operation: 'INSERT',
          payload: productPayload,
          triggerSync: false,
        );
      }
    });

    _sync?.notifyPendingAndSync();

    if (images != null && images.isNotEmpty) {
      try {
        await addProductImages(productId, images);
      } catch (_) {
        // Preserved in local SQLite
      }
    }

    return productId;
  }

  Future<void> updateProduct(ProductEntry product, {List<Uint8List>? newImages}) async {
    final now = DateTime.now();
    final bizId = await _resolveBusinessId() ?? product.businessId;

    String? categoryName;
    if (product.categoryId != null && product.categoryId!.isNotEmpty) {
      final cat = await (_db.select(_db.categories)..where((c) => c.id.equals(product.categoryId!))).getSingleOrNull();
      categoryName = cat?.name;
    }

    final productPayload = {
      'id': product.id,
      'businessId': bizId,
      'name': product.name,
      'code': product.code,
      'categoryId': product.categoryId,
      'categoryName': categoryName,
      'supplierId': product.supplierId,
      'description': product.description,
      'sellingPriceRupees': product.sellingPricePaise / 100.0,
      'costPriceRupees': product.costPricePaise / 100.0,
      'sellingPricePaise': product.sellingPricePaise,
      'costPricePaise': product.costPricePaise,
      'gstRatePercent': product.gstRatePercent,
      'isTaxInclusive': product.isTaxInclusive,
      'unit': product.unit,
      'isAvailable': product.isAvailable,
      'imagePath': product.imagePath,
    };

    await _db.transaction(() async {
      await (_db.update(_db.products)..where((t) => t.id.equals(product.id))).write(
        ProductsCompanion(
          name: Value(product.name),
          code: Value(product.code),
          categoryId: Value(product.categoryId),
          supplierId: Value(product.supplierId),
          description: Value(product.description),
          sellingPricePaise: Value(product.sellingPricePaise),
          costPricePaise: Value(product.costPricePaise),
          gstRatePercent: Value(product.gstRatePercent),
          isTaxInclusive: Value(product.isTaxInclusive),
          unit: Value(product.unit),
          isAvailable: Value(product.isAvailable),
          imagePath: Value(product.imagePath),
          updatedAt: Value(now),
          syncStatus: const Value('pending_update'),
        ),
      );

      if (_sync != null) {
        await _sync.enqueueChange(
          entityName: 'products',
          recordId: product.id,
          operation: 'UPDATE',
          payload: productPayload,
          clientVersion: product.serverVersion,
          triggerSync: false,
        );
      }
    });

    _sync?.notifyPendingAndSync();

    if (newImages != null && newImages.isNotEmpty) {
      try {
        await addProductImages(product.id, newImages);
      } catch (_) {}
    }
  }

  Future<void> deleteProduct(String id) async {
    final now = DateTime.now();
    final p = await getProductById(id);
    final bizId = await _resolveBusinessId() ?? p?.businessId;

    await _db.transaction(() async {
      await (_db.update(_db.products)..where((t) => t.id.equals(id))).write(
        ProductsCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
          syncStatus: const Value('pending_delete'),
        ),
      );

      if (_sync != null) {
        await _sync.enqueueChange(
          entityName: 'products',
          recordId: id,
          operation: 'DELETE',
          payload: {
            'id': id,
            'businessId': bizId,
            'deletedAt': now.toIso8601String(),
          },
          clientVersion: p?.serverVersion,
          triggerSync: false,
        );
      }
    });

    _sync?.notifyPendingAndSync();
  }

  Future<bool> deleteProductSafely(String id) async {
    final invoiceItems = await (_db.select(_db.invoiceItems)..where((t) => t.productId.equals(id))).get();
    if (invoiceItems.isNotEmpty) {
      await toggleAvailability(id, false);
      return false;
    }
    await deleteProduct(id);
    return true;
  }

  Future<void> toggleAvailability(String id, bool isAvailable) async {
    final now = DateTime.now();
    final p = await getProductById(id);
    if (p == null) return;

    await updateProduct(p.copyWith(isAvailable: isAvailable, updatedAt: now));
  }

  Future<void> seedSampleProductsIfEmpty() => seedInitialProductsIfEmpty();

  Future<void> seedInitialProductsIfEmpty() async {
    final count = await _db.products.count().getSingle();
    if (count == 0) {
      // Find category IDs
      final cats = await _db.select(_db.categories).get();
      String? fastFoodId = cats.where((c) => c.name.toLowerCase().contains('fast')).firstOrNull?.id;
      String? beveragesId = cats.where((c) => c.name.toLowerCase().contains('bev')).firstOrNull?.id;
      String? mainCourseId = cats.where((c) => c.name.toLowerCase().contains('main')).firstOrNull?.id;
      String? snacksId = cats.where((c) => c.name.toLowerCase().contains('snack')).firstOrNull?.id;

      final samples = [
        {
          'name': 'Crispy Veg Burger',
          'code': 'BUR-01',
          'catId': fastFoodId,
          'price': 7900,
          'unit': 'piece',
          'gst': 5.0,
        },
        {
          'name': 'Veg Supreme Burger',
          'code': 'BUR-02',
          'catId': fastFoodId,
          'price': 9900,
          'unit': 'piece',
          'gst': 5.0,
        },
        {
          'name': 'Peri Peri French Fries',
          'code': 'SNK-01',
          'catId': snacksId ?? fastFoodId,
          'price': 8900,
          'unit': 'plate',
          'gst': 5.0,
        },
        {
          'name': 'Paneer Butter Masala',
          'code': 'MC-01',
          'catId': mainCourseId,
          'price': 22000,
          'unit': 'bowl',
          'gst': 5.0,
        },
        {
          'name': 'Butter Naan',
          'code': 'BRD-01',
          'catId': mainCourseId,
          'price': 4500,
          'unit': 'piece',
          'gst': 5.0,
        },
        {
          'name': 'Cold Coffee with Ice Cream',
          'code': 'BEV-01',
          'catId': beveragesId,
          'price': 11000,
          'unit': 'glass',
          'gst': 5.0,
        },
        {
          'name': 'Fresh Lime Soda',
          'code': 'BEV-02',
          'catId': beveragesId,
          'price': 6000,
          'unit': 'glass',
          'gst': 5.0,
        },
      ];

      final now = DateTime.now();
      for (final s in samples) {
        await _db.into(_db.products).insert(
              ProductsCompanion.insert(
                id: _uuid.v4(),
                name: s['name'] as String,
                code: Value(s['code'] as String?),
                categoryId: Value(s['catId'] as String?),
                sellingPricePaise: s['price'] as int,
                unit: Value(s['unit'] as String),
                gstRatePercent: Value(s['gst'] as double),
                isTaxInclusive: const Value(true),
                createdAt: now,
                updatedAt: now,
              ),
            );
      }
    }
  }
}

final productsStreamProvider = StreamProvider<List<ProductWithCategory>>((ref) {
  final repo = ref.watch(productRepositoryProvider);
  return repo.watchProducts();
});
