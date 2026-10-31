// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, CategoryEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorValueMeta = const VerificationMeta(
    'colorValue',
  );
  @override
  late final GeneratedColumn<int> colorValue = GeneratedColumn<int>(
    'color_value',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _displayOrderMeta = const VerificationMeta(
    'displayOrder',
  );
  @override
  late final GeneratedColumn<int> displayOrder = GeneratedColumn<int>(
    'display_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _serverVersionMeta = const VerificationMeta(
    'serverVersion',
  );
  @override
  late final GeneratedColumn<BigInt> serverVersion = GeneratedColumn<BigInt>(
    'server_version',
    aliasedName,
    true,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('synced'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    name,
    icon,
    colorValue,
    isActive,
    displayOrder,
    serverVersion,
    createdAt,
    deletedAt,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoryEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('color_value')) {
      context.handle(
        _colorValueMeta,
        colorValue.isAcceptableOrUnknown(data['color_value']!, _colorValueMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('display_order')) {
      context.handle(
        _displayOrderMeta,
        displayOrder.isAcceptableOrUnknown(
          data['display_order']!,
          _displayOrderMeta,
        ),
      );
    }
    if (data.containsKey('server_version')) {
      context.handle(
        _serverVersionMeta,
        serverVersion.isAcceptableOrUnknown(
          data['server_version']!,
          _serverVersionMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoryEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      ),
      colorValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_value'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      displayOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}display_order'],
      )!,
      serverVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}server_version'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      ),
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class CategoryEntry extends DataClass implements Insertable<CategoryEntry> {
  final String id;
  final String? businessId;
  final String name;
  final String? icon;
  final int? colorValue;
  final bool isActive;
  final int displayOrder;
  final BigInt? serverVersion;
  final DateTime createdAt;
  final DateTime? deletedAt;
  final String? syncStatus;
  const CategoryEntry({
    required this.id,
    this.businessId,
    required this.name,
    this.icon,
    this.colorValue,
    required this.isActive,
    required this.displayOrder,
    this.serverVersion,
    required this.createdAt,
    this.deletedAt,
    this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || businessId != null) {
      map['business_id'] = Variable<String>(businessId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    if (!nullToAbsent || colorValue != null) {
      map['color_value'] = Variable<int>(colorValue);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['display_order'] = Variable<int>(displayOrder);
    if (!nullToAbsent || serverVersion != null) {
      map['server_version'] = Variable<BigInt>(serverVersion);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || syncStatus != null) {
      map['sync_status'] = Variable<String>(syncStatus);
    }
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      businessId: businessId == null && nullToAbsent
          ? const Value.absent()
          : Value(businessId),
      name: Value(name),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      colorValue: colorValue == null && nullToAbsent
          ? const Value.absent()
          : Value(colorValue),
      isActive: Value(isActive),
      displayOrder: Value(displayOrder),
      serverVersion: serverVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(serverVersion),
      createdAt: Value(createdAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncStatus: syncStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(syncStatus),
    );
  }

  factory CategoryEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryEntry(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String?>(json['businessId']),
      name: serializer.fromJson<String>(json['name']),
      icon: serializer.fromJson<String?>(json['icon']),
      colorValue: serializer.fromJson<int?>(json['colorValue']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      displayOrder: serializer.fromJson<int>(json['displayOrder']),
      serverVersion: serializer.fromJson<BigInt?>(json['serverVersion']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      syncStatus: serializer.fromJson<String?>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessId': serializer.toJson<String?>(businessId),
      'name': serializer.toJson<String>(name),
      'icon': serializer.toJson<String?>(icon),
      'colorValue': serializer.toJson<int?>(colorValue),
      'isActive': serializer.toJson<bool>(isActive),
      'displayOrder': serializer.toJson<int>(displayOrder),
      'serverVersion': serializer.toJson<BigInt?>(serverVersion),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'syncStatus': serializer.toJson<String?>(syncStatus),
    };
  }

  CategoryEntry copyWith({
    String? id,
    Value<String?> businessId = const Value.absent(),
    String? name,
    Value<String?> icon = const Value.absent(),
    Value<int?> colorValue = const Value.absent(),
    bool? isActive,
    int? displayOrder,
    Value<BigInt?> serverVersion = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<String?> syncStatus = const Value.absent(),
  }) => CategoryEntry(
    id: id ?? this.id,
    businessId: businessId.present ? businessId.value : this.businessId,
    name: name ?? this.name,
    icon: icon.present ? icon.value : this.icon,
    colorValue: colorValue.present ? colorValue.value : this.colorValue,
    isActive: isActive ?? this.isActive,
    displayOrder: displayOrder ?? this.displayOrder,
    serverVersion: serverVersion.present
        ? serverVersion.value
        : this.serverVersion,
    createdAt: createdAt ?? this.createdAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncStatus: syncStatus.present ? syncStatus.value : this.syncStatus,
  );
  CategoryEntry copyWithCompanion(CategoriesCompanion data) {
    return CategoryEntry(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      name: data.name.present ? data.name.value : this.name,
      icon: data.icon.present ? data.icon.value : this.icon,
      colorValue: data.colorValue.present
          ? data.colorValue.value
          : this.colorValue,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      displayOrder: data.displayOrder.present
          ? data.displayOrder.value
          : this.displayOrder,
      serverVersion: data.serverVersion.present
          ? data.serverVersion.value
          : this.serverVersion,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryEntry(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('colorValue: $colorValue, ')
          ..write('isActive: $isActive, ')
          ..write('displayOrder: $displayOrder, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('createdAt: $createdAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    businessId,
    name,
    icon,
    colorValue,
    isActive,
    displayOrder,
    serverVersion,
    createdAt,
    deletedAt,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryEntry &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.name == this.name &&
          other.icon == this.icon &&
          other.colorValue == this.colorValue &&
          other.isActive == this.isActive &&
          other.displayOrder == this.displayOrder &&
          other.serverVersion == this.serverVersion &&
          other.createdAt == this.createdAt &&
          other.deletedAt == this.deletedAt &&
          other.syncStatus == this.syncStatus);
}

class CategoriesCompanion extends UpdateCompanion<CategoryEntry> {
  final Value<String> id;
  final Value<String?> businessId;
  final Value<String> name;
  final Value<String?> icon;
  final Value<int?> colorValue;
  final Value<bool> isActive;
  final Value<int> displayOrder;
  final Value<BigInt?> serverVersion;
  final Value<DateTime> createdAt;
  final Value<DateTime?> deletedAt;
  final Value<String?> syncStatus;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.name = const Value.absent(),
    this.icon = const Value.absent(),
    this.colorValue = const Value.absent(),
    this.isActive = const Value.absent(),
    this.displayOrder = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String id,
    this.businessId = const Value.absent(),
    required String name,
    this.icon = const Value.absent(),
    this.colorValue = const Value.absent(),
    this.isActive = const Value.absent(),
    this.displayOrder = const Value.absent(),
    this.serverVersion = const Value.absent(),
    required DateTime createdAt,
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<CategoryEntry> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? name,
    Expression<String>? icon,
    Expression<int>? colorValue,
    Expression<bool>? isActive,
    Expression<int>? displayOrder,
    Expression<BigInt>? serverVersion,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (name != null) 'name': name,
      if (icon != null) 'icon': icon,
      if (colorValue != null) 'color_value': colorValue,
      if (isActive != null) 'is_active': isActive,
      if (displayOrder != null) 'display_order': displayOrder,
      if (serverVersion != null) 'server_version': serverVersion,
      if (createdAt != null) 'created_at': createdAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith({
    Value<String>? id,
    Value<String?>? businessId,
    Value<String>? name,
    Value<String?>? icon,
    Value<int?>? colorValue,
    Value<bool>? isActive,
    Value<int>? displayOrder,
    Value<BigInt?>? serverVersion,
    Value<DateTime>? createdAt,
    Value<DateTime?>? deletedAt,
    Value<String?>? syncStatus,
    Value<int>? rowid,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      colorValue: colorValue ?? this.colorValue,
      isActive: isActive ?? this.isActive,
      displayOrder: displayOrder ?? this.displayOrder,
      serverVersion: serverVersion ?? this.serverVersion,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (colorValue.present) {
      map['color_value'] = Variable<int>(colorValue.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (displayOrder.present) {
      map['display_order'] = Variable<int>(displayOrder.value);
    }
    if (serverVersion.present) {
      map['server_version'] = Variable<BigInt>(serverVersion.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('colorValue: $colorValue, ')
          ..write('isActive: $isActive, ')
          ..write('displayOrder: $displayOrder, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('createdAt: $createdAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductsTable extends Products
    with TableInfo<$ProductsTable, ProductEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 150,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id)',
    ),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _costPricePaiseMeta = const VerificationMeta(
    'costPricePaise',
  );
  @override
  late final GeneratedColumn<int> costPricePaise = GeneratedColumn<int>(
    'cost_price_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sellingPricePaiseMeta = const VerificationMeta(
    'sellingPricePaise',
  );
  @override
  late final GeneratedColumn<int> sellingPricePaise = GeneratedColumn<int>(
    'selling_price_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gstRatePercentMeta = const VerificationMeta(
    'gstRatePercent',
  );
  @override
  late final GeneratedColumn<double> gstRatePercent = GeneratedColumn<double>(
    'gst_rate_percent',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _isTaxInclusiveMeta = const VerificationMeta(
    'isTaxInclusive',
  );
  @override
  late final GeneratedColumn<bool> isTaxInclusive = GeneratedColumn<bool>(
    'is_tax_inclusive',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_tax_inclusive" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('plate'),
  );
  static const VerificationMeta _isAvailableMeta = const VerificationMeta(
    'isAvailable',
  );
  @override
  late final GeneratedColumn<bool> isAvailable = GeneratedColumn<bool>(
    'is_available',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_available" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverVersionMeta = const VerificationMeta(
    'serverVersion',
  );
  @override
  late final GeneratedColumn<BigInt> serverVersion = GeneratedColumn<BigInt>(
    'server_version',
    aliasedName,
    true,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('synced'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    name,
    code,
    categoryId,
    description,
    costPricePaise,
    sellingPricePaise,
    gstRatePercent,
    isTaxInclusive,
    unit,
    isAvailable,
    imagePath,
    serverVersion,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('cost_price_paise')) {
      context.handle(
        _costPricePaiseMeta,
        costPricePaise.isAcceptableOrUnknown(
          data['cost_price_paise']!,
          _costPricePaiseMeta,
        ),
      );
    }
    if (data.containsKey('selling_price_paise')) {
      context.handle(
        _sellingPricePaiseMeta,
        sellingPricePaise.isAcceptableOrUnknown(
          data['selling_price_paise']!,
          _sellingPricePaiseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sellingPricePaiseMeta);
    }
    if (data.containsKey('gst_rate_percent')) {
      context.handle(
        _gstRatePercentMeta,
        gstRatePercent.isAcceptableOrUnknown(
          data['gst_rate_percent']!,
          _gstRatePercentMeta,
        ),
      );
    }
    if (data.containsKey('is_tax_inclusive')) {
      context.handle(
        _isTaxInclusiveMeta,
        isTaxInclusive.isAcceptableOrUnknown(
          data['is_tax_inclusive']!,
          _isTaxInclusiveMeta,
        ),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('is_available')) {
      context.handle(
        _isAvailableMeta,
        isAvailable.isAcceptableOrUnknown(
          data['is_available']!,
          _isAvailableMeta,
        ),
      );
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    }
    if (data.containsKey('server_version')) {
      context.handle(
        _serverVersionMeta,
        serverVersion.isAcceptableOrUnknown(
          data['server_version']!,
          _serverVersionMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProductEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      costPricePaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cost_price_paise'],
      )!,
      sellingPricePaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}selling_price_paise'],
      )!,
      gstRatePercent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}gst_rate_percent'],
      )!,
      isTaxInclusive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_tax_inclusive'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      isAvailable: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_available'],
      )!,
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      ),
      serverVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}server_version'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      ),
    );
  }

  @override
  $ProductsTable createAlias(String alias) {
    return $ProductsTable(attachedDatabase, alias);
  }
}

class ProductEntry extends DataClass implements Insertable<ProductEntry> {
  final String id;
  final String? businessId;
  final String name;
  final String? code;
  final String? categoryId;
  final String? description;
  final int costPricePaise;
  final int sellingPricePaise;
  final double gstRatePercent;
  final bool isTaxInclusive;
  final String unit;
  final bool isAvailable;
  final String? imagePath;
  final BigInt? serverVersion;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String? syncStatus;
  const ProductEntry({
    required this.id,
    this.businessId,
    required this.name,
    this.code,
    this.categoryId,
    this.description,
    required this.costPricePaise,
    required this.sellingPricePaise,
    required this.gstRatePercent,
    required this.isTaxInclusive,
    required this.unit,
    required this.isAvailable,
    this.imagePath,
    this.serverVersion,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || businessId != null) {
      map['business_id'] = Variable<String>(businessId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || code != null) {
      map['code'] = Variable<String>(code);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['cost_price_paise'] = Variable<int>(costPricePaise);
    map['selling_price_paise'] = Variable<int>(sellingPricePaise);
    map['gst_rate_percent'] = Variable<double>(gstRatePercent);
    map['is_tax_inclusive'] = Variable<bool>(isTaxInclusive);
    map['unit'] = Variable<String>(unit);
    map['is_available'] = Variable<bool>(isAvailable);
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    if (!nullToAbsent || serverVersion != null) {
      map['server_version'] = Variable<BigInt>(serverVersion);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || syncStatus != null) {
      map['sync_status'] = Variable<String>(syncStatus);
    }
    return map;
  }

  ProductsCompanion toCompanion(bool nullToAbsent) {
    return ProductsCompanion(
      id: Value(id),
      businessId: businessId == null && nullToAbsent
          ? const Value.absent()
          : Value(businessId),
      name: Value(name),
      code: code == null && nullToAbsent ? const Value.absent() : Value(code),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      costPricePaise: Value(costPricePaise),
      sellingPricePaise: Value(sellingPricePaise),
      gstRatePercent: Value(gstRatePercent),
      isTaxInclusive: Value(isTaxInclusive),
      unit: Value(unit),
      isAvailable: Value(isAvailable),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      serverVersion: serverVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(serverVersion),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncStatus: syncStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(syncStatus),
    );
  }

  factory ProductEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductEntry(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String?>(json['businessId']),
      name: serializer.fromJson<String>(json['name']),
      code: serializer.fromJson<String?>(json['code']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      description: serializer.fromJson<String?>(json['description']),
      costPricePaise: serializer.fromJson<int>(json['costPricePaise']),
      sellingPricePaise: serializer.fromJson<int>(json['sellingPricePaise']),
      gstRatePercent: serializer.fromJson<double>(json['gstRatePercent']),
      isTaxInclusive: serializer.fromJson<bool>(json['isTaxInclusive']),
      unit: serializer.fromJson<String>(json['unit']),
      isAvailable: serializer.fromJson<bool>(json['isAvailable']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      serverVersion: serializer.fromJson<BigInt?>(json['serverVersion']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      syncStatus: serializer.fromJson<String?>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessId': serializer.toJson<String?>(businessId),
      'name': serializer.toJson<String>(name),
      'code': serializer.toJson<String?>(code),
      'categoryId': serializer.toJson<String?>(categoryId),
      'description': serializer.toJson<String?>(description),
      'costPricePaise': serializer.toJson<int>(costPricePaise),
      'sellingPricePaise': serializer.toJson<int>(sellingPricePaise),
      'gstRatePercent': serializer.toJson<double>(gstRatePercent),
      'isTaxInclusive': serializer.toJson<bool>(isTaxInclusive),
      'unit': serializer.toJson<String>(unit),
      'isAvailable': serializer.toJson<bool>(isAvailable),
      'imagePath': serializer.toJson<String?>(imagePath),
      'serverVersion': serializer.toJson<BigInt?>(serverVersion),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'syncStatus': serializer.toJson<String?>(syncStatus),
    };
  }

  ProductEntry copyWith({
    String? id,
    Value<String?> businessId = const Value.absent(),
    String? name,
    Value<String?> code = const Value.absent(),
    Value<String?> categoryId = const Value.absent(),
    Value<String?> description = const Value.absent(),
    int? costPricePaise,
    int? sellingPricePaise,
    double? gstRatePercent,
    bool? isTaxInclusive,
    String? unit,
    bool? isAvailable,
    Value<String?> imagePath = const Value.absent(),
    Value<BigInt?> serverVersion = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<String?> syncStatus = const Value.absent(),
  }) => ProductEntry(
    id: id ?? this.id,
    businessId: businessId.present ? businessId.value : this.businessId,
    name: name ?? this.name,
    code: code.present ? code.value : this.code,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    description: description.present ? description.value : this.description,
    costPricePaise: costPricePaise ?? this.costPricePaise,
    sellingPricePaise: sellingPricePaise ?? this.sellingPricePaise,
    gstRatePercent: gstRatePercent ?? this.gstRatePercent,
    isTaxInclusive: isTaxInclusive ?? this.isTaxInclusive,
    unit: unit ?? this.unit,
    isAvailable: isAvailable ?? this.isAvailable,
    imagePath: imagePath.present ? imagePath.value : this.imagePath,
    serverVersion: serverVersion.present
        ? serverVersion.value
        : this.serverVersion,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncStatus: syncStatus.present ? syncStatus.value : this.syncStatus,
  );
  ProductEntry copyWithCompanion(ProductsCompanion data) {
    return ProductEntry(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      name: data.name.present ? data.name.value : this.name,
      code: data.code.present ? data.code.value : this.code,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      description: data.description.present
          ? data.description.value
          : this.description,
      costPricePaise: data.costPricePaise.present
          ? data.costPricePaise.value
          : this.costPricePaise,
      sellingPricePaise: data.sellingPricePaise.present
          ? data.sellingPricePaise.value
          : this.sellingPricePaise,
      gstRatePercent: data.gstRatePercent.present
          ? data.gstRatePercent.value
          : this.gstRatePercent,
      isTaxInclusive: data.isTaxInclusive.present
          ? data.isTaxInclusive.value
          : this.isTaxInclusive,
      unit: data.unit.present ? data.unit.value : this.unit,
      isAvailable: data.isAvailable.present
          ? data.isAvailable.value
          : this.isAvailable,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      serverVersion: data.serverVersion.present
          ? data.serverVersion.value
          : this.serverVersion,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductEntry(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('name: $name, ')
          ..write('code: $code, ')
          ..write('categoryId: $categoryId, ')
          ..write('description: $description, ')
          ..write('costPricePaise: $costPricePaise, ')
          ..write('sellingPricePaise: $sellingPricePaise, ')
          ..write('gstRatePercent: $gstRatePercent, ')
          ..write('isTaxInclusive: $isTaxInclusive, ')
          ..write('unit: $unit, ')
          ..write('isAvailable: $isAvailable, ')
          ..write('imagePath: $imagePath, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    businessId,
    name,
    code,
    categoryId,
    description,
    costPricePaise,
    sellingPricePaise,
    gstRatePercent,
    isTaxInclusive,
    unit,
    isAvailable,
    imagePath,
    serverVersion,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductEntry &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.name == this.name &&
          other.code == this.code &&
          other.categoryId == this.categoryId &&
          other.description == this.description &&
          other.costPricePaise == this.costPricePaise &&
          other.sellingPricePaise == this.sellingPricePaise &&
          other.gstRatePercent == this.gstRatePercent &&
          other.isTaxInclusive == this.isTaxInclusive &&
          other.unit == this.unit &&
          other.isAvailable == this.isAvailable &&
          other.imagePath == this.imagePath &&
          other.serverVersion == this.serverVersion &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncStatus == this.syncStatus);
}

class ProductsCompanion extends UpdateCompanion<ProductEntry> {
  final Value<String> id;
  final Value<String?> businessId;
  final Value<String> name;
  final Value<String?> code;
  final Value<String?> categoryId;
  final Value<String?> description;
  final Value<int> costPricePaise;
  final Value<int> sellingPricePaise;
  final Value<double> gstRatePercent;
  final Value<bool> isTaxInclusive;
  final Value<String> unit;
  final Value<bool> isAvailable;
  final Value<String?> imagePath;
  final Value<BigInt?> serverVersion;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String?> syncStatus;
  final Value<int> rowid;
  const ProductsCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.name = const Value.absent(),
    this.code = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.description = const Value.absent(),
    this.costPricePaise = const Value.absent(),
    this.sellingPricePaise = const Value.absent(),
    this.gstRatePercent = const Value.absent(),
    this.isTaxInclusive = const Value.absent(),
    this.unit = const Value.absent(),
    this.isAvailable = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductsCompanion.insert({
    required String id,
    this.businessId = const Value.absent(),
    required String name,
    this.code = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.description = const Value.absent(),
    this.costPricePaise = const Value.absent(),
    required int sellingPricePaise,
    this.gstRatePercent = const Value.absent(),
    this.isTaxInclusive = const Value.absent(),
    this.unit = const Value.absent(),
    this.isAvailable = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.serverVersion = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       sellingPricePaise = Value(sellingPricePaise),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ProductEntry> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? name,
    Expression<String>? code,
    Expression<String>? categoryId,
    Expression<String>? description,
    Expression<int>? costPricePaise,
    Expression<int>? sellingPricePaise,
    Expression<double>? gstRatePercent,
    Expression<bool>? isTaxInclusive,
    Expression<String>? unit,
    Expression<bool>? isAvailable,
    Expression<String>? imagePath,
    Expression<BigInt>? serverVersion,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (name != null) 'name': name,
      if (code != null) 'code': code,
      if (categoryId != null) 'category_id': categoryId,
      if (description != null) 'description': description,
      if (costPricePaise != null) 'cost_price_paise': costPricePaise,
      if (sellingPricePaise != null) 'selling_price_paise': sellingPricePaise,
      if (gstRatePercent != null) 'gst_rate_percent': gstRatePercent,
      if (isTaxInclusive != null) 'is_tax_inclusive': isTaxInclusive,
      if (unit != null) 'unit': unit,
      if (isAvailable != null) 'is_available': isAvailable,
      if (imagePath != null) 'image_path': imagePath,
      if (serverVersion != null) 'server_version': serverVersion,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductsCompanion copyWith({
    Value<String>? id,
    Value<String?>? businessId,
    Value<String>? name,
    Value<String?>? code,
    Value<String?>? categoryId,
    Value<String?>? description,
    Value<int>? costPricePaise,
    Value<int>? sellingPricePaise,
    Value<double>? gstRatePercent,
    Value<bool>? isTaxInclusive,
    Value<String>? unit,
    Value<bool>? isAvailable,
    Value<String?>? imagePath,
    Value<BigInt?>? serverVersion,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String?>? syncStatus,
    Value<int>? rowid,
  }) {
    return ProductsCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      code: code ?? this.code,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      costPricePaise: costPricePaise ?? this.costPricePaise,
      sellingPricePaise: sellingPricePaise ?? this.sellingPricePaise,
      gstRatePercent: gstRatePercent ?? this.gstRatePercent,
      isTaxInclusive: isTaxInclusive ?? this.isTaxInclusive,
      unit: unit ?? this.unit,
      isAvailable: isAvailable ?? this.isAvailable,
      imagePath: imagePath ?? this.imagePath,
      serverVersion: serverVersion ?? this.serverVersion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (costPricePaise.present) {
      map['cost_price_paise'] = Variable<int>(costPricePaise.value);
    }
    if (sellingPricePaise.present) {
      map['selling_price_paise'] = Variable<int>(sellingPricePaise.value);
    }
    if (gstRatePercent.present) {
      map['gst_rate_percent'] = Variable<double>(gstRatePercent.value);
    }
    if (isTaxInclusive.present) {
      map['is_tax_inclusive'] = Variable<bool>(isTaxInclusive.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (isAvailable.present) {
      map['is_available'] = Variable<bool>(isAvailable.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (serverVersion.present) {
      map['server_version'] = Variable<BigInt>(serverVersion.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('name: $name, ')
          ..write('code: $code, ')
          ..write('categoryId: $categoryId, ')
          ..write('description: $description, ')
          ..write('costPricePaise: $costPricePaise, ')
          ..write('sellingPricePaise: $sellingPricePaise, ')
          ..write('gstRatePercent: $gstRatePercent, ')
          ..write('isTaxInclusive: $isTaxInclusive, ')
          ..write('unit: $unit, ')
          ..write('isAvailable: $isAvailable, ')
          ..write('imagePath: $imagePath, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InvoicesTable extends Invoices
    with TableInfo<$InvoicesTable, InvoiceEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InvoicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
    'customer_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _invoiceNumberMeta = const VerificationMeta(
    'invoiceNumber',
  );
  @override
  late final GeneratedColumn<String> invoiceNumber = GeneratedColumn<String>(
    'invoice_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL UNIQUE',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customerNameMeta = const VerificationMeta(
    'customerName',
  );
  @override
  late final GeneratedColumn<String> customerName = GeneratedColumn<String>(
    'customer_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customerPhoneMeta = const VerificationMeta(
    'customerPhone',
  );
  @override
  late final GeneratedColumn<String> customerPhone = GeneratedColumn<String>(
    'customer_phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _subtotalPaiseMeta = const VerificationMeta(
    'subtotalPaise',
  );
  @override
  late final GeneratedColumn<int> subtotalPaise = GeneratedColumn<int>(
    'subtotal_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemDiscountTotalPaiseMeta =
      const VerificationMeta('itemDiscountTotalPaise');
  @override
  late final GeneratedColumn<int> itemDiscountTotalPaise = GeneratedColumn<int>(
    'item_discount_total_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _billDiscountPaiseMeta = const VerificationMeta(
    'billDiscountPaise',
  );
  @override
  late final GeneratedColumn<int> billDiscountPaise = GeneratedColumn<int>(
    'bill_discount_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _taxableAmountPaiseMeta =
      const VerificationMeta('taxableAmountPaise');
  @override
  late final GeneratedColumn<int> taxableAmountPaise = GeneratedColumn<int>(
    'taxable_amount_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cgstPaiseMeta = const VerificationMeta(
    'cgstPaise',
  );
  @override
  late final GeneratedColumn<int> cgstPaise = GeneratedColumn<int>(
    'cgst_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sgstPaiseMeta = const VerificationMeta(
    'sgstPaise',
  );
  @override
  late final GeneratedColumn<int> sgstPaise = GeneratedColumn<int>(
    'sgst_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _igstPaiseMeta = const VerificationMeta(
    'igstPaise',
  );
  @override
  late final GeneratedColumn<int> igstPaise = GeneratedColumn<int>(
    'igst_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _roundOffPaiseMeta = const VerificationMeta(
    'roundOffPaise',
  );
  @override
  late final GeneratedColumn<int> roundOffPaise = GeneratedColumn<int>(
    'round_off_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _grandTotalPaiseMeta = const VerificationMeta(
    'grandTotalPaise',
  );
  @override
  late final GeneratedColumn<int> grandTotalPaise = GeneratedColumn<int>(
    'grand_total_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paymentMethodMeta = const VerificationMeta(
    'paymentMethod',
  );
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
    'payment_method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Cash'),
  );
  static const VerificationMeta _paymentStatusMeta = const VerificationMeta(
    'paymentStatus',
  );
  @override
  late final GeneratedColumn<String> paymentStatus = GeneratedColumn<String>(
    'payment_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Paid'),
  );
  static const VerificationMeta _orderStatusMeta = const VerificationMeta(
    'orderStatus',
  );
  @override
  late final GeneratedColumn<String> orderStatus = GeneratedColumn<String>(
    'order_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Completed'),
  );
  static const VerificationMeta _orderTypeMeta = const VerificationMeta(
    'orderType',
  );
  @override
  late final GeneratedColumn<String> orderType = GeneratedColumn<String>(
    'order_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Dine In'),
  );
  static const VerificationMeta _tableNumberMeta = const VerificationMeta(
    'tableNumber',
  );
  @override
  late final GeneratedColumn<String> tableNumber = GeneratedColumn<String>(
    'table_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deliveryAddressMeta = const VerificationMeta(
    'deliveryAddress',
  );
  @override
  late final GeneratedColumn<String> deliveryAddress = GeneratedColumn<String>(
    'delivery_address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kotNumberMeta = const VerificationMeta(
    'kotNumber',
  );
  @override
  late final GeneratedColumn<String> kotNumber = GeneratedColumn<String>(
    'kot_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cashierIdMeta = const VerificationMeta(
    'cashierId',
  );
  @override
  late final GeneratedColumn<String> cashierId = GeneratedColumn<String>(
    'cashier_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cashierNameMeta = const VerificationMeta(
    'cashierName',
  );
  @override
  late final GeneratedColumn<String> cashierName = GeneratedColumn<String>(
    'cashier_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paidAmountPaiseMeta = const VerificationMeta(
    'paidAmountPaise',
  );
  @override
  late final GeneratedColumn<int> paidAmountPaise = GeneratedColumn<int>(
    'paid_amount_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isCancelledMeta = const VerificationMeta(
    'isCancelled',
  );
  @override
  late final GeneratedColumn<bool> isCancelled = GeneratedColumn<bool>(
    'is_cancelled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_cancelled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _cancelledAtMeta = const VerificationMeta(
    'cancelledAt',
  );
  @override
  late final GeneratedColumn<DateTime> cancelledAt = GeneratedColumn<DateTime>(
    'cancelled_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cancelReasonMeta = const VerificationMeta(
    'cancelReason',
  );
  @override
  late final GeneratedColumn<String> cancelReason = GeneratedColumn<String>(
    'cancel_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverVersionMeta = const VerificationMeta(
    'serverVersion',
  );
  @override
  late final GeneratedColumn<BigInt> serverVersion = GeneratedColumn<BigInt>(
    'server_version',
    aliasedName,
    true,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('synced'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    deviceId,
    customerId,
    invoiceNumber,
    createdAt,
    customerName,
    customerPhone,
    subtotalPaise,
    itemDiscountTotalPaise,
    billDiscountPaise,
    taxableAmountPaise,
    cgstPaise,
    sgstPaise,
    igstPaise,
    roundOffPaise,
    grandTotalPaise,
    paymentMethod,
    paymentStatus,
    orderStatus,
    orderType,
    tableNumber,
    deliveryAddress,
    kotNumber,
    cashierId,
    cashierName,
    paidAmountPaise,
    isCancelled,
    cancelledAt,
    cancelReason,
    idempotencyKey,
    serverVersion,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'invoices';
  @override
  VerificationContext validateIntegrity(
    Insertable<InvoiceEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    }
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    }
    if (data.containsKey('invoice_number')) {
      context.handle(
        _invoiceNumberMeta,
        invoiceNumber.isAcceptableOrUnknown(
          data['invoice_number']!,
          _invoiceNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_invoiceNumberMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('customer_name')) {
      context.handle(
        _customerNameMeta,
        customerName.isAcceptableOrUnknown(
          data['customer_name']!,
          _customerNameMeta,
        ),
      );
    }
    if (data.containsKey('customer_phone')) {
      context.handle(
        _customerPhoneMeta,
        customerPhone.isAcceptableOrUnknown(
          data['customer_phone']!,
          _customerPhoneMeta,
        ),
      );
    }
    if (data.containsKey('subtotal_paise')) {
      context.handle(
        _subtotalPaiseMeta,
        subtotalPaise.isAcceptableOrUnknown(
          data['subtotal_paise']!,
          _subtotalPaiseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_subtotalPaiseMeta);
    }
    if (data.containsKey('item_discount_total_paise')) {
      context.handle(
        _itemDiscountTotalPaiseMeta,
        itemDiscountTotalPaise.isAcceptableOrUnknown(
          data['item_discount_total_paise']!,
          _itemDiscountTotalPaiseMeta,
        ),
      );
    }
    if (data.containsKey('bill_discount_paise')) {
      context.handle(
        _billDiscountPaiseMeta,
        billDiscountPaise.isAcceptableOrUnknown(
          data['bill_discount_paise']!,
          _billDiscountPaiseMeta,
        ),
      );
    }
    if (data.containsKey('taxable_amount_paise')) {
      context.handle(
        _taxableAmountPaiseMeta,
        taxableAmountPaise.isAcceptableOrUnknown(
          data['taxable_amount_paise']!,
          _taxableAmountPaiseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_taxableAmountPaiseMeta);
    }
    if (data.containsKey('cgst_paise')) {
      context.handle(
        _cgstPaiseMeta,
        cgstPaise.isAcceptableOrUnknown(data['cgst_paise']!, _cgstPaiseMeta),
      );
    }
    if (data.containsKey('sgst_paise')) {
      context.handle(
        _sgstPaiseMeta,
        sgstPaise.isAcceptableOrUnknown(data['sgst_paise']!, _sgstPaiseMeta),
      );
    }
    if (data.containsKey('igst_paise')) {
      context.handle(
        _igstPaiseMeta,
        igstPaise.isAcceptableOrUnknown(data['igst_paise']!, _igstPaiseMeta),
      );
    }
    if (data.containsKey('round_off_paise')) {
      context.handle(
        _roundOffPaiseMeta,
        roundOffPaise.isAcceptableOrUnknown(
          data['round_off_paise']!,
          _roundOffPaiseMeta,
        ),
      );
    }
    if (data.containsKey('grand_total_paise')) {
      context.handle(
        _grandTotalPaiseMeta,
        grandTotalPaise.isAcceptableOrUnknown(
          data['grand_total_paise']!,
          _grandTotalPaiseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_grandTotalPaiseMeta);
    }
    if (data.containsKey('payment_method')) {
      context.handle(
        _paymentMethodMeta,
        paymentMethod.isAcceptableOrUnknown(
          data['payment_method']!,
          _paymentMethodMeta,
        ),
      );
    }
    if (data.containsKey('payment_status')) {
      context.handle(
        _paymentStatusMeta,
        paymentStatus.isAcceptableOrUnknown(
          data['payment_status']!,
          _paymentStatusMeta,
        ),
      );
    }
    if (data.containsKey('order_status')) {
      context.handle(
        _orderStatusMeta,
        orderStatus.isAcceptableOrUnknown(
          data['order_status']!,
          _orderStatusMeta,
        ),
      );
    }
    if (data.containsKey('order_type')) {
      context.handle(
        _orderTypeMeta,
        orderType.isAcceptableOrUnknown(data['order_type']!, _orderTypeMeta),
      );
    }
    if (data.containsKey('table_number')) {
      context.handle(
        _tableNumberMeta,
        tableNumber.isAcceptableOrUnknown(
          data['table_number']!,
          _tableNumberMeta,
        ),
      );
    }
    if (data.containsKey('delivery_address')) {
      context.handle(
        _deliveryAddressMeta,
        deliveryAddress.isAcceptableOrUnknown(
          data['delivery_address']!,
          _deliveryAddressMeta,
        ),
      );
    }
    if (data.containsKey('kot_number')) {
      context.handle(
        _kotNumberMeta,
        kotNumber.isAcceptableOrUnknown(data['kot_number']!, _kotNumberMeta),
      );
    }
    if (data.containsKey('cashier_id')) {
      context.handle(
        _cashierIdMeta,
        cashierId.isAcceptableOrUnknown(data['cashier_id']!, _cashierIdMeta),
      );
    }
    if (data.containsKey('cashier_name')) {
      context.handle(
        _cashierNameMeta,
        cashierName.isAcceptableOrUnknown(
          data['cashier_name']!,
          _cashierNameMeta,
        ),
      );
    }
    if (data.containsKey('paid_amount_paise')) {
      context.handle(
        _paidAmountPaiseMeta,
        paidAmountPaise.isAcceptableOrUnknown(
          data['paid_amount_paise']!,
          _paidAmountPaiseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_paidAmountPaiseMeta);
    }
    if (data.containsKey('is_cancelled')) {
      context.handle(
        _isCancelledMeta,
        isCancelled.isAcceptableOrUnknown(
          data['is_cancelled']!,
          _isCancelledMeta,
        ),
      );
    }
    if (data.containsKey('cancelled_at')) {
      context.handle(
        _cancelledAtMeta,
        cancelledAt.isAcceptableOrUnknown(
          data['cancelled_at']!,
          _cancelledAtMeta,
        ),
      );
    }
    if (data.containsKey('cancel_reason')) {
      context.handle(
        _cancelReasonMeta,
        cancelReason.isAcceptableOrUnknown(
          data['cancel_reason']!,
          _cancelReasonMeta,
        ),
      );
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
        _idempotencyKeyMeta,
        idempotencyKey.isAcceptableOrUnknown(
          data['idempotency_key']!,
          _idempotencyKeyMeta,
        ),
      );
    }
    if (data.containsKey('server_version')) {
      context.handle(
        _serverVersionMeta,
        serverVersion.isAcceptableOrUnknown(
          data['server_version']!,
          _serverVersionMeta,
        ),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InvoiceEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InvoiceEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      ),
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_id'],
      ),
      invoiceNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invoice_number'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      customerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_name'],
      ),
      customerPhone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_phone'],
      ),
      subtotalPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}subtotal_paise'],
      )!,
      itemDiscountTotalPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_discount_total_paise'],
      )!,
      billDiscountPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bill_discount_paise'],
      )!,
      taxableAmountPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}taxable_amount_paise'],
      )!,
      cgstPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cgst_paise'],
      )!,
      sgstPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sgst_paise'],
      )!,
      igstPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}igst_paise'],
      )!,
      roundOffPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}round_off_paise'],
      )!,
      grandTotalPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}grand_total_paise'],
      )!,
      paymentMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_method'],
      )!,
      paymentStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_status'],
      )!,
      orderStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_status'],
      )!,
      orderType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_type'],
      )!,
      tableNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}table_number'],
      ),
      deliveryAddress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}delivery_address'],
      ),
      kotNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kot_number'],
      ),
      cashierId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cashier_id'],
      ),
      cashierName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cashier_name'],
      ),
      paidAmountPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}paid_amount_paise'],
      )!,
      isCancelled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_cancelled'],
      )!,
      cancelledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cancelled_at'],
      ),
      cancelReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cancel_reason'],
      ),
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      ),
      serverVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}server_version'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      ),
    );
  }

  @override
  $InvoicesTable createAlias(String alias) {
    return $InvoicesTable(attachedDatabase, alias);
  }
}

class InvoiceEntry extends DataClass implements Insertable<InvoiceEntry> {
  final String id;
  final String? businessId;
  final String? deviceId;
  final String? customerId;
  final String invoiceNumber;
  final DateTime createdAt;
  final String? customerName;
  final String? customerPhone;
  final int subtotalPaise;
  final int itemDiscountTotalPaise;
  final int billDiscountPaise;
  final int taxableAmountPaise;
  final int cgstPaise;
  final int sgstPaise;
  final int igstPaise;
  final int roundOffPaise;
  final int grandTotalPaise;
  final String paymentMethod;
  final String paymentStatus;
  final String orderStatus;
  final String orderType;
  final String? tableNumber;
  final String? deliveryAddress;
  final String? kotNumber;
  final String? cashierId;
  final String? cashierName;
  final int paidAmountPaise;
  final bool isCancelled;
  final DateTime? cancelledAt;
  final String? cancelReason;
  final String? idempotencyKey;
  final BigInt? serverVersion;
  final String? syncStatus;
  const InvoiceEntry({
    required this.id,
    this.businessId,
    this.deviceId,
    this.customerId,
    required this.invoiceNumber,
    required this.createdAt,
    this.customerName,
    this.customerPhone,
    required this.subtotalPaise,
    required this.itemDiscountTotalPaise,
    required this.billDiscountPaise,
    required this.taxableAmountPaise,
    required this.cgstPaise,
    required this.sgstPaise,
    required this.igstPaise,
    required this.roundOffPaise,
    required this.grandTotalPaise,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.orderStatus,
    required this.orderType,
    this.tableNumber,
    this.deliveryAddress,
    this.kotNumber,
    this.cashierId,
    this.cashierName,
    required this.paidAmountPaise,
    required this.isCancelled,
    this.cancelledAt,
    this.cancelReason,
    this.idempotencyKey,
    this.serverVersion,
    this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || businessId != null) {
      map['business_id'] = Variable<String>(businessId);
    }
    if (!nullToAbsent || deviceId != null) {
      map['device_id'] = Variable<String>(deviceId);
    }
    if (!nullToAbsent || customerId != null) {
      map['customer_id'] = Variable<String>(customerId);
    }
    map['invoice_number'] = Variable<String>(invoiceNumber);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || customerName != null) {
      map['customer_name'] = Variable<String>(customerName);
    }
    if (!nullToAbsent || customerPhone != null) {
      map['customer_phone'] = Variable<String>(customerPhone);
    }
    map['subtotal_paise'] = Variable<int>(subtotalPaise);
    map['item_discount_total_paise'] = Variable<int>(itemDiscountTotalPaise);
    map['bill_discount_paise'] = Variable<int>(billDiscountPaise);
    map['taxable_amount_paise'] = Variable<int>(taxableAmountPaise);
    map['cgst_paise'] = Variable<int>(cgstPaise);
    map['sgst_paise'] = Variable<int>(sgstPaise);
    map['igst_paise'] = Variable<int>(igstPaise);
    map['round_off_paise'] = Variable<int>(roundOffPaise);
    map['grand_total_paise'] = Variable<int>(grandTotalPaise);
    map['payment_method'] = Variable<String>(paymentMethod);
    map['payment_status'] = Variable<String>(paymentStatus);
    map['order_status'] = Variable<String>(orderStatus);
    map['order_type'] = Variable<String>(orderType);
    if (!nullToAbsent || tableNumber != null) {
      map['table_number'] = Variable<String>(tableNumber);
    }
    if (!nullToAbsent || deliveryAddress != null) {
      map['delivery_address'] = Variable<String>(deliveryAddress);
    }
    if (!nullToAbsent || kotNumber != null) {
      map['kot_number'] = Variable<String>(kotNumber);
    }
    if (!nullToAbsent || cashierId != null) {
      map['cashier_id'] = Variable<String>(cashierId);
    }
    if (!nullToAbsent || cashierName != null) {
      map['cashier_name'] = Variable<String>(cashierName);
    }
    map['paid_amount_paise'] = Variable<int>(paidAmountPaise);
    map['is_cancelled'] = Variable<bool>(isCancelled);
    if (!nullToAbsent || cancelledAt != null) {
      map['cancelled_at'] = Variable<DateTime>(cancelledAt);
    }
    if (!nullToAbsent || cancelReason != null) {
      map['cancel_reason'] = Variable<String>(cancelReason);
    }
    if (!nullToAbsent || idempotencyKey != null) {
      map['idempotency_key'] = Variable<String>(idempotencyKey);
    }
    if (!nullToAbsent || serverVersion != null) {
      map['server_version'] = Variable<BigInt>(serverVersion);
    }
    if (!nullToAbsent || syncStatus != null) {
      map['sync_status'] = Variable<String>(syncStatus);
    }
    return map;
  }

  InvoicesCompanion toCompanion(bool nullToAbsent) {
    return InvoicesCompanion(
      id: Value(id),
      businessId: businessId == null && nullToAbsent
          ? const Value.absent()
          : Value(businessId),
      deviceId: deviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceId),
      customerId: customerId == null && nullToAbsent
          ? const Value.absent()
          : Value(customerId),
      invoiceNumber: Value(invoiceNumber),
      createdAt: Value(createdAt),
      customerName: customerName == null && nullToAbsent
          ? const Value.absent()
          : Value(customerName),
      customerPhone: customerPhone == null && nullToAbsent
          ? const Value.absent()
          : Value(customerPhone),
      subtotalPaise: Value(subtotalPaise),
      itemDiscountTotalPaise: Value(itemDiscountTotalPaise),
      billDiscountPaise: Value(billDiscountPaise),
      taxableAmountPaise: Value(taxableAmountPaise),
      cgstPaise: Value(cgstPaise),
      sgstPaise: Value(sgstPaise),
      igstPaise: Value(igstPaise),
      roundOffPaise: Value(roundOffPaise),
      grandTotalPaise: Value(grandTotalPaise),
      paymentMethod: Value(paymentMethod),
      paymentStatus: Value(paymentStatus),
      orderStatus: Value(orderStatus),
      orderType: Value(orderType),
      tableNumber: tableNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(tableNumber),
      deliveryAddress: deliveryAddress == null && nullToAbsent
          ? const Value.absent()
          : Value(deliveryAddress),
      kotNumber: kotNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(kotNumber),
      cashierId: cashierId == null && nullToAbsent
          ? const Value.absent()
          : Value(cashierId),
      cashierName: cashierName == null && nullToAbsent
          ? const Value.absent()
          : Value(cashierName),
      paidAmountPaise: Value(paidAmountPaise),
      isCancelled: Value(isCancelled),
      cancelledAt: cancelledAt == null && nullToAbsent
          ? const Value.absent()
          : Value(cancelledAt),
      cancelReason: cancelReason == null && nullToAbsent
          ? const Value.absent()
          : Value(cancelReason),
      idempotencyKey: idempotencyKey == null && nullToAbsent
          ? const Value.absent()
          : Value(idempotencyKey),
      serverVersion: serverVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(serverVersion),
      syncStatus: syncStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(syncStatus),
    );
  }

  factory InvoiceEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InvoiceEntry(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String?>(json['businessId']),
      deviceId: serializer.fromJson<String?>(json['deviceId']),
      customerId: serializer.fromJson<String?>(json['customerId']),
      invoiceNumber: serializer.fromJson<String>(json['invoiceNumber']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      customerName: serializer.fromJson<String?>(json['customerName']),
      customerPhone: serializer.fromJson<String?>(json['customerPhone']),
      subtotalPaise: serializer.fromJson<int>(json['subtotalPaise']),
      itemDiscountTotalPaise: serializer.fromJson<int>(
        json['itemDiscountTotalPaise'],
      ),
      billDiscountPaise: serializer.fromJson<int>(json['billDiscountPaise']),
      taxableAmountPaise: serializer.fromJson<int>(json['taxableAmountPaise']),
      cgstPaise: serializer.fromJson<int>(json['cgstPaise']),
      sgstPaise: serializer.fromJson<int>(json['sgstPaise']),
      igstPaise: serializer.fromJson<int>(json['igstPaise']),
      roundOffPaise: serializer.fromJson<int>(json['roundOffPaise']),
      grandTotalPaise: serializer.fromJson<int>(json['grandTotalPaise']),
      paymentMethod: serializer.fromJson<String>(json['paymentMethod']),
      paymentStatus: serializer.fromJson<String>(json['paymentStatus']),
      orderStatus: serializer.fromJson<String>(json['orderStatus']),
      orderType: serializer.fromJson<String>(json['orderType']),
      tableNumber: serializer.fromJson<String?>(json['tableNumber']),
      deliveryAddress: serializer.fromJson<String?>(json['deliveryAddress']),
      kotNumber: serializer.fromJson<String?>(json['kotNumber']),
      cashierId: serializer.fromJson<String?>(json['cashierId']),
      cashierName: serializer.fromJson<String?>(json['cashierName']),
      paidAmountPaise: serializer.fromJson<int>(json['paidAmountPaise']),
      isCancelled: serializer.fromJson<bool>(json['isCancelled']),
      cancelledAt: serializer.fromJson<DateTime?>(json['cancelledAt']),
      cancelReason: serializer.fromJson<String?>(json['cancelReason']),
      idempotencyKey: serializer.fromJson<String?>(json['idempotencyKey']),
      serverVersion: serializer.fromJson<BigInt?>(json['serverVersion']),
      syncStatus: serializer.fromJson<String?>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessId': serializer.toJson<String?>(businessId),
      'deviceId': serializer.toJson<String?>(deviceId),
      'customerId': serializer.toJson<String?>(customerId),
      'invoiceNumber': serializer.toJson<String>(invoiceNumber),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'customerName': serializer.toJson<String?>(customerName),
      'customerPhone': serializer.toJson<String?>(customerPhone),
      'subtotalPaise': serializer.toJson<int>(subtotalPaise),
      'itemDiscountTotalPaise': serializer.toJson<int>(itemDiscountTotalPaise),
      'billDiscountPaise': serializer.toJson<int>(billDiscountPaise),
      'taxableAmountPaise': serializer.toJson<int>(taxableAmountPaise),
      'cgstPaise': serializer.toJson<int>(cgstPaise),
      'sgstPaise': serializer.toJson<int>(sgstPaise),
      'igstPaise': serializer.toJson<int>(igstPaise),
      'roundOffPaise': serializer.toJson<int>(roundOffPaise),
      'grandTotalPaise': serializer.toJson<int>(grandTotalPaise),
      'paymentMethod': serializer.toJson<String>(paymentMethod),
      'paymentStatus': serializer.toJson<String>(paymentStatus),
      'orderStatus': serializer.toJson<String>(orderStatus),
      'orderType': serializer.toJson<String>(orderType),
      'tableNumber': serializer.toJson<String?>(tableNumber),
      'deliveryAddress': serializer.toJson<String?>(deliveryAddress),
      'kotNumber': serializer.toJson<String?>(kotNumber),
      'cashierId': serializer.toJson<String?>(cashierId),
      'cashierName': serializer.toJson<String?>(cashierName),
      'paidAmountPaise': serializer.toJson<int>(paidAmountPaise),
      'isCancelled': serializer.toJson<bool>(isCancelled),
      'cancelledAt': serializer.toJson<DateTime?>(cancelledAt),
      'cancelReason': serializer.toJson<String?>(cancelReason),
      'idempotencyKey': serializer.toJson<String?>(idempotencyKey),
      'serverVersion': serializer.toJson<BigInt?>(serverVersion),
      'syncStatus': serializer.toJson<String?>(syncStatus),
    };
  }

  InvoiceEntry copyWith({
    String? id,
    Value<String?> businessId = const Value.absent(),
    Value<String?> deviceId = const Value.absent(),
    Value<String?> customerId = const Value.absent(),
    String? invoiceNumber,
    DateTime? createdAt,
    Value<String?> customerName = const Value.absent(),
    Value<String?> customerPhone = const Value.absent(),
    int? subtotalPaise,
    int? itemDiscountTotalPaise,
    int? billDiscountPaise,
    int? taxableAmountPaise,
    int? cgstPaise,
    int? sgstPaise,
    int? igstPaise,
    int? roundOffPaise,
    int? grandTotalPaise,
    String? paymentMethod,
    String? paymentStatus,
    String? orderStatus,
    String? orderType,
    Value<String?> tableNumber = const Value.absent(),
    Value<String?> deliveryAddress = const Value.absent(),
    Value<String?> kotNumber = const Value.absent(),
    Value<String?> cashierId = const Value.absent(),
    Value<String?> cashierName = const Value.absent(),
    int? paidAmountPaise,
    bool? isCancelled,
    Value<DateTime?> cancelledAt = const Value.absent(),
    Value<String?> cancelReason = const Value.absent(),
    Value<String?> idempotencyKey = const Value.absent(),
    Value<BigInt?> serverVersion = const Value.absent(),
    Value<String?> syncStatus = const Value.absent(),
  }) => InvoiceEntry(
    id: id ?? this.id,
    businessId: businessId.present ? businessId.value : this.businessId,
    deviceId: deviceId.present ? deviceId.value : this.deviceId,
    customerId: customerId.present ? customerId.value : this.customerId,
    invoiceNumber: invoiceNumber ?? this.invoiceNumber,
    createdAt: createdAt ?? this.createdAt,
    customerName: customerName.present ? customerName.value : this.customerName,
    customerPhone: customerPhone.present
        ? customerPhone.value
        : this.customerPhone,
    subtotalPaise: subtotalPaise ?? this.subtotalPaise,
    itemDiscountTotalPaise:
        itemDiscountTotalPaise ?? this.itemDiscountTotalPaise,
    billDiscountPaise: billDiscountPaise ?? this.billDiscountPaise,
    taxableAmountPaise: taxableAmountPaise ?? this.taxableAmountPaise,
    cgstPaise: cgstPaise ?? this.cgstPaise,
    sgstPaise: sgstPaise ?? this.sgstPaise,
    igstPaise: igstPaise ?? this.igstPaise,
    roundOffPaise: roundOffPaise ?? this.roundOffPaise,
    grandTotalPaise: grandTotalPaise ?? this.grandTotalPaise,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    paymentStatus: paymentStatus ?? this.paymentStatus,
    orderStatus: orderStatus ?? this.orderStatus,
    orderType: orderType ?? this.orderType,
    tableNumber: tableNumber.present ? tableNumber.value : this.tableNumber,
    deliveryAddress: deliveryAddress.present
        ? deliveryAddress.value
        : this.deliveryAddress,
    kotNumber: kotNumber.present ? kotNumber.value : this.kotNumber,
    cashierId: cashierId.present ? cashierId.value : this.cashierId,
    cashierName: cashierName.present ? cashierName.value : this.cashierName,
    paidAmountPaise: paidAmountPaise ?? this.paidAmountPaise,
    isCancelled: isCancelled ?? this.isCancelled,
    cancelledAt: cancelledAt.present ? cancelledAt.value : this.cancelledAt,
    cancelReason: cancelReason.present ? cancelReason.value : this.cancelReason,
    idempotencyKey: idempotencyKey.present
        ? idempotencyKey.value
        : this.idempotencyKey,
    serverVersion: serverVersion.present
        ? serverVersion.value
        : this.serverVersion,
    syncStatus: syncStatus.present ? syncStatus.value : this.syncStatus,
  );
  InvoiceEntry copyWithCompanion(InvoicesCompanion data) {
    return InvoiceEntry(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      invoiceNumber: data.invoiceNumber.present
          ? data.invoiceNumber.value
          : this.invoiceNumber,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      customerName: data.customerName.present
          ? data.customerName.value
          : this.customerName,
      customerPhone: data.customerPhone.present
          ? data.customerPhone.value
          : this.customerPhone,
      subtotalPaise: data.subtotalPaise.present
          ? data.subtotalPaise.value
          : this.subtotalPaise,
      itemDiscountTotalPaise: data.itemDiscountTotalPaise.present
          ? data.itemDiscountTotalPaise.value
          : this.itemDiscountTotalPaise,
      billDiscountPaise: data.billDiscountPaise.present
          ? data.billDiscountPaise.value
          : this.billDiscountPaise,
      taxableAmountPaise: data.taxableAmountPaise.present
          ? data.taxableAmountPaise.value
          : this.taxableAmountPaise,
      cgstPaise: data.cgstPaise.present ? data.cgstPaise.value : this.cgstPaise,
      sgstPaise: data.sgstPaise.present ? data.sgstPaise.value : this.sgstPaise,
      igstPaise: data.igstPaise.present ? data.igstPaise.value : this.igstPaise,
      roundOffPaise: data.roundOffPaise.present
          ? data.roundOffPaise.value
          : this.roundOffPaise,
      grandTotalPaise: data.grandTotalPaise.present
          ? data.grandTotalPaise.value
          : this.grandTotalPaise,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      paymentStatus: data.paymentStatus.present
          ? data.paymentStatus.value
          : this.paymentStatus,
      orderStatus: data.orderStatus.present
          ? data.orderStatus.value
          : this.orderStatus,
      orderType: data.orderType.present ? data.orderType.value : this.orderType,
      tableNumber: data.tableNumber.present
          ? data.tableNumber.value
          : this.tableNumber,
      deliveryAddress: data.deliveryAddress.present
          ? data.deliveryAddress.value
          : this.deliveryAddress,
      kotNumber: data.kotNumber.present ? data.kotNumber.value : this.kotNumber,
      cashierId: data.cashierId.present ? data.cashierId.value : this.cashierId,
      cashierName: data.cashierName.present
          ? data.cashierName.value
          : this.cashierName,
      paidAmountPaise: data.paidAmountPaise.present
          ? data.paidAmountPaise.value
          : this.paidAmountPaise,
      isCancelled: data.isCancelled.present
          ? data.isCancelled.value
          : this.isCancelled,
      cancelledAt: data.cancelledAt.present
          ? data.cancelledAt.value
          : this.cancelledAt,
      cancelReason: data.cancelReason.present
          ? data.cancelReason.value
          : this.cancelReason,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      serverVersion: data.serverVersion.present
          ? data.serverVersion.value
          : this.serverVersion,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InvoiceEntry(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('deviceId: $deviceId, ')
          ..write('customerId: $customerId, ')
          ..write('invoiceNumber: $invoiceNumber, ')
          ..write('createdAt: $createdAt, ')
          ..write('customerName: $customerName, ')
          ..write('customerPhone: $customerPhone, ')
          ..write('subtotalPaise: $subtotalPaise, ')
          ..write('itemDiscountTotalPaise: $itemDiscountTotalPaise, ')
          ..write('billDiscountPaise: $billDiscountPaise, ')
          ..write('taxableAmountPaise: $taxableAmountPaise, ')
          ..write('cgstPaise: $cgstPaise, ')
          ..write('sgstPaise: $sgstPaise, ')
          ..write('igstPaise: $igstPaise, ')
          ..write('roundOffPaise: $roundOffPaise, ')
          ..write('grandTotalPaise: $grandTotalPaise, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('paymentStatus: $paymentStatus, ')
          ..write('orderStatus: $orderStatus, ')
          ..write('orderType: $orderType, ')
          ..write('tableNumber: $tableNumber, ')
          ..write('deliveryAddress: $deliveryAddress, ')
          ..write('kotNumber: $kotNumber, ')
          ..write('cashierId: $cashierId, ')
          ..write('cashierName: $cashierName, ')
          ..write('paidAmountPaise: $paidAmountPaise, ')
          ..write('isCancelled: $isCancelled, ')
          ..write('cancelledAt: $cancelledAt, ')
          ..write('cancelReason: $cancelReason, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    businessId,
    deviceId,
    customerId,
    invoiceNumber,
    createdAt,
    customerName,
    customerPhone,
    subtotalPaise,
    itemDiscountTotalPaise,
    billDiscountPaise,
    taxableAmountPaise,
    cgstPaise,
    sgstPaise,
    igstPaise,
    roundOffPaise,
    grandTotalPaise,
    paymentMethod,
    paymentStatus,
    orderStatus,
    orderType,
    tableNumber,
    deliveryAddress,
    kotNumber,
    cashierId,
    cashierName,
    paidAmountPaise,
    isCancelled,
    cancelledAt,
    cancelReason,
    idempotencyKey,
    serverVersion,
    syncStatus,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InvoiceEntry &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.deviceId == this.deviceId &&
          other.customerId == this.customerId &&
          other.invoiceNumber == this.invoiceNumber &&
          other.createdAt == this.createdAt &&
          other.customerName == this.customerName &&
          other.customerPhone == this.customerPhone &&
          other.subtotalPaise == this.subtotalPaise &&
          other.itemDiscountTotalPaise == this.itemDiscountTotalPaise &&
          other.billDiscountPaise == this.billDiscountPaise &&
          other.taxableAmountPaise == this.taxableAmountPaise &&
          other.cgstPaise == this.cgstPaise &&
          other.sgstPaise == this.sgstPaise &&
          other.igstPaise == this.igstPaise &&
          other.roundOffPaise == this.roundOffPaise &&
          other.grandTotalPaise == this.grandTotalPaise &&
          other.paymentMethod == this.paymentMethod &&
          other.paymentStatus == this.paymentStatus &&
          other.orderStatus == this.orderStatus &&
          other.orderType == this.orderType &&
          other.tableNumber == this.tableNumber &&
          other.deliveryAddress == this.deliveryAddress &&
          other.kotNumber == this.kotNumber &&
          other.cashierId == this.cashierId &&
          other.cashierName == this.cashierName &&
          other.paidAmountPaise == this.paidAmountPaise &&
          other.isCancelled == this.isCancelled &&
          other.cancelledAt == this.cancelledAt &&
          other.cancelReason == this.cancelReason &&
          other.idempotencyKey == this.idempotencyKey &&
          other.serverVersion == this.serverVersion &&
          other.syncStatus == this.syncStatus);
}

class InvoicesCompanion extends UpdateCompanion<InvoiceEntry> {
  final Value<String> id;
  final Value<String?> businessId;
  final Value<String?> deviceId;
  final Value<String?> customerId;
  final Value<String> invoiceNumber;
  final Value<DateTime> createdAt;
  final Value<String?> customerName;
  final Value<String?> customerPhone;
  final Value<int> subtotalPaise;
  final Value<int> itemDiscountTotalPaise;
  final Value<int> billDiscountPaise;
  final Value<int> taxableAmountPaise;
  final Value<int> cgstPaise;
  final Value<int> sgstPaise;
  final Value<int> igstPaise;
  final Value<int> roundOffPaise;
  final Value<int> grandTotalPaise;
  final Value<String> paymentMethod;
  final Value<String> paymentStatus;
  final Value<String> orderStatus;
  final Value<String> orderType;
  final Value<String?> tableNumber;
  final Value<String?> deliveryAddress;
  final Value<String?> kotNumber;
  final Value<String?> cashierId;
  final Value<String?> cashierName;
  final Value<int> paidAmountPaise;
  final Value<bool> isCancelled;
  final Value<DateTime?> cancelledAt;
  final Value<String?> cancelReason;
  final Value<String?> idempotencyKey;
  final Value<BigInt?> serverVersion;
  final Value<String?> syncStatus;
  final Value<int> rowid;
  const InvoicesCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.customerId = const Value.absent(),
    this.invoiceNumber = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.customerName = const Value.absent(),
    this.customerPhone = const Value.absent(),
    this.subtotalPaise = const Value.absent(),
    this.itemDiscountTotalPaise = const Value.absent(),
    this.billDiscountPaise = const Value.absent(),
    this.taxableAmountPaise = const Value.absent(),
    this.cgstPaise = const Value.absent(),
    this.sgstPaise = const Value.absent(),
    this.igstPaise = const Value.absent(),
    this.roundOffPaise = const Value.absent(),
    this.grandTotalPaise = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.paymentStatus = const Value.absent(),
    this.orderStatus = const Value.absent(),
    this.orderType = const Value.absent(),
    this.tableNumber = const Value.absent(),
    this.deliveryAddress = const Value.absent(),
    this.kotNumber = const Value.absent(),
    this.cashierId = const Value.absent(),
    this.cashierName = const Value.absent(),
    this.paidAmountPaise = const Value.absent(),
    this.isCancelled = const Value.absent(),
    this.cancelledAt = const Value.absent(),
    this.cancelReason = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InvoicesCompanion.insert({
    required String id,
    this.businessId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.customerId = const Value.absent(),
    required String invoiceNumber,
    required DateTime createdAt,
    this.customerName = const Value.absent(),
    this.customerPhone = const Value.absent(),
    required int subtotalPaise,
    this.itemDiscountTotalPaise = const Value.absent(),
    this.billDiscountPaise = const Value.absent(),
    required int taxableAmountPaise,
    this.cgstPaise = const Value.absent(),
    this.sgstPaise = const Value.absent(),
    this.igstPaise = const Value.absent(),
    this.roundOffPaise = const Value.absent(),
    required int grandTotalPaise,
    this.paymentMethod = const Value.absent(),
    this.paymentStatus = const Value.absent(),
    this.orderStatus = const Value.absent(),
    this.orderType = const Value.absent(),
    this.tableNumber = const Value.absent(),
    this.deliveryAddress = const Value.absent(),
    this.kotNumber = const Value.absent(),
    this.cashierId = const Value.absent(),
    this.cashierName = const Value.absent(),
    required int paidAmountPaise,
    this.isCancelled = const Value.absent(),
    this.cancelledAt = const Value.absent(),
    this.cancelReason = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       invoiceNumber = Value(invoiceNumber),
       createdAt = Value(createdAt),
       subtotalPaise = Value(subtotalPaise),
       taxableAmountPaise = Value(taxableAmountPaise),
       grandTotalPaise = Value(grandTotalPaise),
       paidAmountPaise = Value(paidAmountPaise);
  static Insertable<InvoiceEntry> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? deviceId,
    Expression<String>? customerId,
    Expression<String>? invoiceNumber,
    Expression<DateTime>? createdAt,
    Expression<String>? customerName,
    Expression<String>? customerPhone,
    Expression<int>? subtotalPaise,
    Expression<int>? itemDiscountTotalPaise,
    Expression<int>? billDiscountPaise,
    Expression<int>? taxableAmountPaise,
    Expression<int>? cgstPaise,
    Expression<int>? sgstPaise,
    Expression<int>? igstPaise,
    Expression<int>? roundOffPaise,
    Expression<int>? grandTotalPaise,
    Expression<String>? paymentMethod,
    Expression<String>? paymentStatus,
    Expression<String>? orderStatus,
    Expression<String>? orderType,
    Expression<String>? tableNumber,
    Expression<String>? deliveryAddress,
    Expression<String>? kotNumber,
    Expression<String>? cashierId,
    Expression<String>? cashierName,
    Expression<int>? paidAmountPaise,
    Expression<bool>? isCancelled,
    Expression<DateTime>? cancelledAt,
    Expression<String>? cancelReason,
    Expression<String>? idempotencyKey,
    Expression<BigInt>? serverVersion,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (deviceId != null) 'device_id': deviceId,
      if (customerId != null) 'customer_id': customerId,
      if (invoiceNumber != null) 'invoice_number': invoiceNumber,
      if (createdAt != null) 'created_at': createdAt,
      if (customerName != null) 'customer_name': customerName,
      if (customerPhone != null) 'customer_phone': customerPhone,
      if (subtotalPaise != null) 'subtotal_paise': subtotalPaise,
      if (itemDiscountTotalPaise != null)
        'item_discount_total_paise': itemDiscountTotalPaise,
      if (billDiscountPaise != null) 'bill_discount_paise': billDiscountPaise,
      if (taxableAmountPaise != null)
        'taxable_amount_paise': taxableAmountPaise,
      if (cgstPaise != null) 'cgst_paise': cgstPaise,
      if (sgstPaise != null) 'sgst_paise': sgstPaise,
      if (igstPaise != null) 'igst_paise': igstPaise,
      if (roundOffPaise != null) 'round_off_paise': roundOffPaise,
      if (grandTotalPaise != null) 'grand_total_paise': grandTotalPaise,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (paymentStatus != null) 'payment_status': paymentStatus,
      if (orderStatus != null) 'order_status': orderStatus,
      if (orderType != null) 'order_type': orderType,
      if (tableNumber != null) 'table_number': tableNumber,
      if (deliveryAddress != null) 'delivery_address': deliveryAddress,
      if (kotNumber != null) 'kot_number': kotNumber,
      if (cashierId != null) 'cashier_id': cashierId,
      if (cashierName != null) 'cashier_name': cashierName,
      if (paidAmountPaise != null) 'paid_amount_paise': paidAmountPaise,
      if (isCancelled != null) 'is_cancelled': isCancelled,
      if (cancelledAt != null) 'cancelled_at': cancelledAt,
      if (cancelReason != null) 'cancel_reason': cancelReason,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (serverVersion != null) 'server_version': serverVersion,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InvoicesCompanion copyWith({
    Value<String>? id,
    Value<String?>? businessId,
    Value<String?>? deviceId,
    Value<String?>? customerId,
    Value<String>? invoiceNumber,
    Value<DateTime>? createdAt,
    Value<String?>? customerName,
    Value<String?>? customerPhone,
    Value<int>? subtotalPaise,
    Value<int>? itemDiscountTotalPaise,
    Value<int>? billDiscountPaise,
    Value<int>? taxableAmountPaise,
    Value<int>? cgstPaise,
    Value<int>? sgstPaise,
    Value<int>? igstPaise,
    Value<int>? roundOffPaise,
    Value<int>? grandTotalPaise,
    Value<String>? paymentMethod,
    Value<String>? paymentStatus,
    Value<String>? orderStatus,
    Value<String>? orderType,
    Value<String?>? tableNumber,
    Value<String?>? deliveryAddress,
    Value<String?>? kotNumber,
    Value<String?>? cashierId,
    Value<String?>? cashierName,
    Value<int>? paidAmountPaise,
    Value<bool>? isCancelled,
    Value<DateTime?>? cancelledAt,
    Value<String?>? cancelReason,
    Value<String?>? idempotencyKey,
    Value<BigInt?>? serverVersion,
    Value<String?>? syncStatus,
    Value<int>? rowid,
  }) {
    return InvoicesCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      deviceId: deviceId ?? this.deviceId,
      customerId: customerId ?? this.customerId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      createdAt: createdAt ?? this.createdAt,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      subtotalPaise: subtotalPaise ?? this.subtotalPaise,
      itemDiscountTotalPaise:
          itemDiscountTotalPaise ?? this.itemDiscountTotalPaise,
      billDiscountPaise: billDiscountPaise ?? this.billDiscountPaise,
      taxableAmountPaise: taxableAmountPaise ?? this.taxableAmountPaise,
      cgstPaise: cgstPaise ?? this.cgstPaise,
      sgstPaise: sgstPaise ?? this.sgstPaise,
      igstPaise: igstPaise ?? this.igstPaise,
      roundOffPaise: roundOffPaise ?? this.roundOffPaise,
      grandTotalPaise: grandTotalPaise ?? this.grandTotalPaise,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      orderStatus: orderStatus ?? this.orderStatus,
      orderType: orderType ?? this.orderType,
      tableNumber: tableNumber ?? this.tableNumber,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      kotNumber: kotNumber ?? this.kotNumber,
      cashierId: cashierId ?? this.cashierId,
      cashierName: cashierName ?? this.cashierName,
      paidAmountPaise: paidAmountPaise ?? this.paidAmountPaise,
      isCancelled: isCancelled ?? this.isCancelled,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancelReason: cancelReason ?? this.cancelReason,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      serverVersion: serverVersion ?? this.serverVersion,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (invoiceNumber.present) {
      map['invoice_number'] = Variable<String>(invoiceNumber.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (customerName.present) {
      map['customer_name'] = Variable<String>(customerName.value);
    }
    if (customerPhone.present) {
      map['customer_phone'] = Variable<String>(customerPhone.value);
    }
    if (subtotalPaise.present) {
      map['subtotal_paise'] = Variable<int>(subtotalPaise.value);
    }
    if (itemDiscountTotalPaise.present) {
      map['item_discount_total_paise'] = Variable<int>(
        itemDiscountTotalPaise.value,
      );
    }
    if (billDiscountPaise.present) {
      map['bill_discount_paise'] = Variable<int>(billDiscountPaise.value);
    }
    if (taxableAmountPaise.present) {
      map['taxable_amount_paise'] = Variable<int>(taxableAmountPaise.value);
    }
    if (cgstPaise.present) {
      map['cgst_paise'] = Variable<int>(cgstPaise.value);
    }
    if (sgstPaise.present) {
      map['sgst_paise'] = Variable<int>(sgstPaise.value);
    }
    if (igstPaise.present) {
      map['igst_paise'] = Variable<int>(igstPaise.value);
    }
    if (roundOffPaise.present) {
      map['round_off_paise'] = Variable<int>(roundOffPaise.value);
    }
    if (grandTotalPaise.present) {
      map['grand_total_paise'] = Variable<int>(grandTotalPaise.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (paymentStatus.present) {
      map['payment_status'] = Variable<String>(paymentStatus.value);
    }
    if (orderStatus.present) {
      map['order_status'] = Variable<String>(orderStatus.value);
    }
    if (orderType.present) {
      map['order_type'] = Variable<String>(orderType.value);
    }
    if (tableNumber.present) {
      map['table_number'] = Variable<String>(tableNumber.value);
    }
    if (deliveryAddress.present) {
      map['delivery_address'] = Variable<String>(deliveryAddress.value);
    }
    if (kotNumber.present) {
      map['kot_number'] = Variable<String>(kotNumber.value);
    }
    if (cashierId.present) {
      map['cashier_id'] = Variable<String>(cashierId.value);
    }
    if (cashierName.present) {
      map['cashier_name'] = Variable<String>(cashierName.value);
    }
    if (paidAmountPaise.present) {
      map['paid_amount_paise'] = Variable<int>(paidAmountPaise.value);
    }
    if (isCancelled.present) {
      map['is_cancelled'] = Variable<bool>(isCancelled.value);
    }
    if (cancelledAt.present) {
      map['cancelled_at'] = Variable<DateTime>(cancelledAt.value);
    }
    if (cancelReason.present) {
      map['cancel_reason'] = Variable<String>(cancelReason.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (serverVersion.present) {
      map['server_version'] = Variable<BigInt>(serverVersion.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InvoicesCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('deviceId: $deviceId, ')
          ..write('customerId: $customerId, ')
          ..write('invoiceNumber: $invoiceNumber, ')
          ..write('createdAt: $createdAt, ')
          ..write('customerName: $customerName, ')
          ..write('customerPhone: $customerPhone, ')
          ..write('subtotalPaise: $subtotalPaise, ')
          ..write('itemDiscountTotalPaise: $itemDiscountTotalPaise, ')
          ..write('billDiscountPaise: $billDiscountPaise, ')
          ..write('taxableAmountPaise: $taxableAmountPaise, ')
          ..write('cgstPaise: $cgstPaise, ')
          ..write('sgstPaise: $sgstPaise, ')
          ..write('igstPaise: $igstPaise, ')
          ..write('roundOffPaise: $roundOffPaise, ')
          ..write('grandTotalPaise: $grandTotalPaise, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('paymentStatus: $paymentStatus, ')
          ..write('orderStatus: $orderStatus, ')
          ..write('orderType: $orderType, ')
          ..write('tableNumber: $tableNumber, ')
          ..write('deliveryAddress: $deliveryAddress, ')
          ..write('kotNumber: $kotNumber, ')
          ..write('cashierId: $cashierId, ')
          ..write('cashierName: $cashierName, ')
          ..write('paidAmountPaise: $paidAmountPaise, ')
          ..write('isCancelled: $isCancelled, ')
          ..write('cancelledAt: $cancelledAt, ')
          ..write('cancelReason: $cancelReason, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InvoiceItemsTable extends InvoiceItems
    with TableInfo<$InvoiceItemsTable, InvoiceItemEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InvoiceItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _invoiceIdMeta = const VerificationMeta(
    'invoiceId',
  );
  @override
  late final GeneratedColumn<String> invoiceId = GeneratedColumn<String>(
    'invoice_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES invoices (id)',
    ),
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _productNameMeta = const VerificationMeta(
    'productName',
  );
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
    'product_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productCodeMeta = const VerificationMeta(
    'productCode',
  );
  @override
  late final GeneratedColumn<String> productCode = GeneratedColumn<String>(
    'product_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitPricePaiseMeta = const VerificationMeta(
    'unitPricePaise',
  );
  @override
  late final GeneratedColumn<int> unitPricePaise = GeneratedColumn<int>(
    'unit_price_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _discountPaiseMeta = const VerificationMeta(
    'discountPaise',
  );
  @override
  late final GeneratedColumn<int> discountPaise = GeneratedColumn<int>(
    'discount_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _gstRatePercentMeta = const VerificationMeta(
    'gstRatePercent',
  );
  @override
  late final GeneratedColumn<double> gstRatePercent = GeneratedColumn<double>(
    'gst_rate_percent',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isTaxInclusiveMeta = const VerificationMeta(
    'isTaxInclusive',
  );
  @override
  late final GeneratedColumn<bool> isTaxInclusive = GeneratedColumn<bool>(
    'is_tax_inclusive',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_tax_inclusive" IN (0, 1))',
    ),
  );
  static const VerificationMeta _taxableAmountPaiseMeta =
      const VerificationMeta('taxableAmountPaise');
  @override
  late final GeneratedColumn<int> taxableAmountPaise = GeneratedColumn<int>(
    'taxable_amount_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taxAmountPaiseMeta = const VerificationMeta(
    'taxAmountPaise',
  );
  @override
  late final GeneratedColumn<int> taxAmountPaise = GeneratedColumn<int>(
    'tax_amount_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalAmountPaiseMeta = const VerificationMeta(
    'totalAmountPaise',
  );
  @override
  late final GeneratedColumn<int> totalAmountPaise = GeneratedColumn<int>(
    'total_amount_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    invoiceId,
    productId,
    productName,
    productCode,
    unit,
    unitPricePaise,
    quantity,
    discountPaise,
    gstRatePercent,
    isTaxInclusive,
    taxableAmountPaise,
    taxAmountPaise,
    totalAmountPaise,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'invoice_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<InvoiceItemEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('invoice_id')) {
      context.handle(
        _invoiceIdMeta,
        invoiceId.isAcceptableOrUnknown(data['invoice_id']!, _invoiceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_invoiceIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    }
    if (data.containsKey('product_name')) {
      context.handle(
        _productNameMeta,
        productName.isAcceptableOrUnknown(
          data['product_name']!,
          _productNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productNameMeta);
    }
    if (data.containsKey('product_code')) {
      context.handle(
        _productCodeMeta,
        productCode.isAcceptableOrUnknown(
          data['product_code']!,
          _productCodeMeta,
        ),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('unit_price_paise')) {
      context.handle(
        _unitPricePaiseMeta,
        unitPricePaise.isAcceptableOrUnknown(
          data['unit_price_paise']!,
          _unitPricePaiseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_unitPricePaiseMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('discount_paise')) {
      context.handle(
        _discountPaiseMeta,
        discountPaise.isAcceptableOrUnknown(
          data['discount_paise']!,
          _discountPaiseMeta,
        ),
      );
    }
    if (data.containsKey('gst_rate_percent')) {
      context.handle(
        _gstRatePercentMeta,
        gstRatePercent.isAcceptableOrUnknown(
          data['gst_rate_percent']!,
          _gstRatePercentMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_gstRatePercentMeta);
    }
    if (data.containsKey('is_tax_inclusive')) {
      context.handle(
        _isTaxInclusiveMeta,
        isTaxInclusive.isAcceptableOrUnknown(
          data['is_tax_inclusive']!,
          _isTaxInclusiveMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_isTaxInclusiveMeta);
    }
    if (data.containsKey('taxable_amount_paise')) {
      context.handle(
        _taxableAmountPaiseMeta,
        taxableAmountPaise.isAcceptableOrUnknown(
          data['taxable_amount_paise']!,
          _taxableAmountPaiseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_taxableAmountPaiseMeta);
    }
    if (data.containsKey('tax_amount_paise')) {
      context.handle(
        _taxAmountPaiseMeta,
        taxAmountPaise.isAcceptableOrUnknown(
          data['tax_amount_paise']!,
          _taxAmountPaiseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_taxAmountPaiseMeta);
    }
    if (data.containsKey('total_amount_paise')) {
      context.handle(
        _totalAmountPaiseMeta,
        totalAmountPaise.isAcceptableOrUnknown(
          data['total_amount_paise']!,
          _totalAmountPaiseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalAmountPaiseMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InvoiceItemEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InvoiceItemEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      invoiceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invoice_id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      ),
      productName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_name'],
      )!,
      productCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_code'],
      ),
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      unitPricePaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unit_price_paise'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity'],
      )!,
      discountPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}discount_paise'],
      )!,
      gstRatePercent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}gst_rate_percent'],
      )!,
      isTaxInclusive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_tax_inclusive'],
      )!,
      taxableAmountPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}taxable_amount_paise'],
      )!,
      taxAmountPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tax_amount_paise'],
      )!,
      totalAmountPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_amount_paise'],
      )!,
    );
  }

  @override
  $InvoiceItemsTable createAlias(String alias) {
    return $InvoiceItemsTable(attachedDatabase, alias);
  }
}

class InvoiceItemEntry extends DataClass
    implements Insertable<InvoiceItemEntry> {
  final String id;
  final String invoiceId;
  final String? productId;
  final String productName;
  final String? productCode;
  final String unit;
  final int unitPricePaise;
  final double quantity;
  final int discountPaise;
  final double gstRatePercent;
  final bool isTaxInclusive;
  final int taxableAmountPaise;
  final int taxAmountPaise;
  final int totalAmountPaise;
  const InvoiceItemEntry({
    required this.id,
    required this.invoiceId,
    this.productId,
    required this.productName,
    this.productCode,
    required this.unit,
    required this.unitPricePaise,
    required this.quantity,
    required this.discountPaise,
    required this.gstRatePercent,
    required this.isTaxInclusive,
    required this.taxableAmountPaise,
    required this.taxAmountPaise,
    required this.totalAmountPaise,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['invoice_id'] = Variable<String>(invoiceId);
    if (!nullToAbsent || productId != null) {
      map['product_id'] = Variable<String>(productId);
    }
    map['product_name'] = Variable<String>(productName);
    if (!nullToAbsent || productCode != null) {
      map['product_code'] = Variable<String>(productCode);
    }
    map['unit'] = Variable<String>(unit);
    map['unit_price_paise'] = Variable<int>(unitPricePaise);
    map['quantity'] = Variable<double>(quantity);
    map['discount_paise'] = Variable<int>(discountPaise);
    map['gst_rate_percent'] = Variable<double>(gstRatePercent);
    map['is_tax_inclusive'] = Variable<bool>(isTaxInclusive);
    map['taxable_amount_paise'] = Variable<int>(taxableAmountPaise);
    map['tax_amount_paise'] = Variable<int>(taxAmountPaise);
    map['total_amount_paise'] = Variable<int>(totalAmountPaise);
    return map;
  }

  InvoiceItemsCompanion toCompanion(bool nullToAbsent) {
    return InvoiceItemsCompanion(
      id: Value(id),
      invoiceId: Value(invoiceId),
      productId: productId == null && nullToAbsent
          ? const Value.absent()
          : Value(productId),
      productName: Value(productName),
      productCode: productCode == null && nullToAbsent
          ? const Value.absent()
          : Value(productCode),
      unit: Value(unit),
      unitPricePaise: Value(unitPricePaise),
      quantity: Value(quantity),
      discountPaise: Value(discountPaise),
      gstRatePercent: Value(gstRatePercent),
      isTaxInclusive: Value(isTaxInclusive),
      taxableAmountPaise: Value(taxableAmountPaise),
      taxAmountPaise: Value(taxAmountPaise),
      totalAmountPaise: Value(totalAmountPaise),
    );
  }

  factory InvoiceItemEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InvoiceItemEntry(
      id: serializer.fromJson<String>(json['id']),
      invoiceId: serializer.fromJson<String>(json['invoiceId']),
      productId: serializer.fromJson<String?>(json['productId']),
      productName: serializer.fromJson<String>(json['productName']),
      productCode: serializer.fromJson<String?>(json['productCode']),
      unit: serializer.fromJson<String>(json['unit']),
      unitPricePaise: serializer.fromJson<int>(json['unitPricePaise']),
      quantity: serializer.fromJson<double>(json['quantity']),
      discountPaise: serializer.fromJson<int>(json['discountPaise']),
      gstRatePercent: serializer.fromJson<double>(json['gstRatePercent']),
      isTaxInclusive: serializer.fromJson<bool>(json['isTaxInclusive']),
      taxableAmountPaise: serializer.fromJson<int>(json['taxableAmountPaise']),
      taxAmountPaise: serializer.fromJson<int>(json['taxAmountPaise']),
      totalAmountPaise: serializer.fromJson<int>(json['totalAmountPaise']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'invoiceId': serializer.toJson<String>(invoiceId),
      'productId': serializer.toJson<String?>(productId),
      'productName': serializer.toJson<String>(productName),
      'productCode': serializer.toJson<String?>(productCode),
      'unit': serializer.toJson<String>(unit),
      'unitPricePaise': serializer.toJson<int>(unitPricePaise),
      'quantity': serializer.toJson<double>(quantity),
      'discountPaise': serializer.toJson<int>(discountPaise),
      'gstRatePercent': serializer.toJson<double>(gstRatePercent),
      'isTaxInclusive': serializer.toJson<bool>(isTaxInclusive),
      'taxableAmountPaise': serializer.toJson<int>(taxableAmountPaise),
      'taxAmountPaise': serializer.toJson<int>(taxAmountPaise),
      'totalAmountPaise': serializer.toJson<int>(totalAmountPaise),
    };
  }

  InvoiceItemEntry copyWith({
    String? id,
    String? invoiceId,
    Value<String?> productId = const Value.absent(),
    String? productName,
    Value<String?> productCode = const Value.absent(),
    String? unit,
    int? unitPricePaise,
    double? quantity,
    int? discountPaise,
    double? gstRatePercent,
    bool? isTaxInclusive,
    int? taxableAmountPaise,
    int? taxAmountPaise,
    int? totalAmountPaise,
  }) => InvoiceItemEntry(
    id: id ?? this.id,
    invoiceId: invoiceId ?? this.invoiceId,
    productId: productId.present ? productId.value : this.productId,
    productName: productName ?? this.productName,
    productCode: productCode.present ? productCode.value : this.productCode,
    unit: unit ?? this.unit,
    unitPricePaise: unitPricePaise ?? this.unitPricePaise,
    quantity: quantity ?? this.quantity,
    discountPaise: discountPaise ?? this.discountPaise,
    gstRatePercent: gstRatePercent ?? this.gstRatePercent,
    isTaxInclusive: isTaxInclusive ?? this.isTaxInclusive,
    taxableAmountPaise: taxableAmountPaise ?? this.taxableAmountPaise,
    taxAmountPaise: taxAmountPaise ?? this.taxAmountPaise,
    totalAmountPaise: totalAmountPaise ?? this.totalAmountPaise,
  );
  InvoiceItemEntry copyWithCompanion(InvoiceItemsCompanion data) {
    return InvoiceItemEntry(
      id: data.id.present ? data.id.value : this.id,
      invoiceId: data.invoiceId.present ? data.invoiceId.value : this.invoiceId,
      productId: data.productId.present ? data.productId.value : this.productId,
      productName: data.productName.present
          ? data.productName.value
          : this.productName,
      productCode: data.productCode.present
          ? data.productCode.value
          : this.productCode,
      unit: data.unit.present ? data.unit.value : this.unit,
      unitPricePaise: data.unitPricePaise.present
          ? data.unitPricePaise.value
          : this.unitPricePaise,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      discountPaise: data.discountPaise.present
          ? data.discountPaise.value
          : this.discountPaise,
      gstRatePercent: data.gstRatePercent.present
          ? data.gstRatePercent.value
          : this.gstRatePercent,
      isTaxInclusive: data.isTaxInclusive.present
          ? data.isTaxInclusive.value
          : this.isTaxInclusive,
      taxableAmountPaise: data.taxableAmountPaise.present
          ? data.taxableAmountPaise.value
          : this.taxableAmountPaise,
      taxAmountPaise: data.taxAmountPaise.present
          ? data.taxAmountPaise.value
          : this.taxAmountPaise,
      totalAmountPaise: data.totalAmountPaise.present
          ? data.totalAmountPaise.value
          : this.totalAmountPaise,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InvoiceItemEntry(')
          ..write('id: $id, ')
          ..write('invoiceId: $invoiceId, ')
          ..write('productId: $productId, ')
          ..write('productName: $productName, ')
          ..write('productCode: $productCode, ')
          ..write('unit: $unit, ')
          ..write('unitPricePaise: $unitPricePaise, ')
          ..write('quantity: $quantity, ')
          ..write('discountPaise: $discountPaise, ')
          ..write('gstRatePercent: $gstRatePercent, ')
          ..write('isTaxInclusive: $isTaxInclusive, ')
          ..write('taxableAmountPaise: $taxableAmountPaise, ')
          ..write('taxAmountPaise: $taxAmountPaise, ')
          ..write('totalAmountPaise: $totalAmountPaise')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    invoiceId,
    productId,
    productName,
    productCode,
    unit,
    unitPricePaise,
    quantity,
    discountPaise,
    gstRatePercent,
    isTaxInclusive,
    taxableAmountPaise,
    taxAmountPaise,
    totalAmountPaise,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InvoiceItemEntry &&
          other.id == this.id &&
          other.invoiceId == this.invoiceId &&
          other.productId == this.productId &&
          other.productName == this.productName &&
          other.productCode == this.productCode &&
          other.unit == this.unit &&
          other.unitPricePaise == this.unitPricePaise &&
          other.quantity == this.quantity &&
          other.discountPaise == this.discountPaise &&
          other.gstRatePercent == this.gstRatePercent &&
          other.isTaxInclusive == this.isTaxInclusive &&
          other.taxableAmountPaise == this.taxableAmountPaise &&
          other.taxAmountPaise == this.taxAmountPaise &&
          other.totalAmountPaise == this.totalAmountPaise);
}

class InvoiceItemsCompanion extends UpdateCompanion<InvoiceItemEntry> {
  final Value<String> id;
  final Value<String> invoiceId;
  final Value<String?> productId;
  final Value<String> productName;
  final Value<String?> productCode;
  final Value<String> unit;
  final Value<int> unitPricePaise;
  final Value<double> quantity;
  final Value<int> discountPaise;
  final Value<double> gstRatePercent;
  final Value<bool> isTaxInclusive;
  final Value<int> taxableAmountPaise;
  final Value<int> taxAmountPaise;
  final Value<int> totalAmountPaise;
  final Value<int> rowid;
  const InvoiceItemsCompanion({
    this.id = const Value.absent(),
    this.invoiceId = const Value.absent(),
    this.productId = const Value.absent(),
    this.productName = const Value.absent(),
    this.productCode = const Value.absent(),
    this.unit = const Value.absent(),
    this.unitPricePaise = const Value.absent(),
    this.quantity = const Value.absent(),
    this.discountPaise = const Value.absent(),
    this.gstRatePercent = const Value.absent(),
    this.isTaxInclusive = const Value.absent(),
    this.taxableAmountPaise = const Value.absent(),
    this.taxAmountPaise = const Value.absent(),
    this.totalAmountPaise = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InvoiceItemsCompanion.insert({
    required String id,
    required String invoiceId,
    this.productId = const Value.absent(),
    required String productName,
    this.productCode = const Value.absent(),
    required String unit,
    required int unitPricePaise,
    required double quantity,
    this.discountPaise = const Value.absent(),
    required double gstRatePercent,
    required bool isTaxInclusive,
    required int taxableAmountPaise,
    required int taxAmountPaise,
    required int totalAmountPaise,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       invoiceId = Value(invoiceId),
       productName = Value(productName),
       unit = Value(unit),
       unitPricePaise = Value(unitPricePaise),
       quantity = Value(quantity),
       gstRatePercent = Value(gstRatePercent),
       isTaxInclusive = Value(isTaxInclusive),
       taxableAmountPaise = Value(taxableAmountPaise),
       taxAmountPaise = Value(taxAmountPaise),
       totalAmountPaise = Value(totalAmountPaise);
  static Insertable<InvoiceItemEntry> custom({
    Expression<String>? id,
    Expression<String>? invoiceId,
    Expression<String>? productId,
    Expression<String>? productName,
    Expression<String>? productCode,
    Expression<String>? unit,
    Expression<int>? unitPricePaise,
    Expression<double>? quantity,
    Expression<int>? discountPaise,
    Expression<double>? gstRatePercent,
    Expression<bool>? isTaxInclusive,
    Expression<int>? taxableAmountPaise,
    Expression<int>? taxAmountPaise,
    Expression<int>? totalAmountPaise,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (invoiceId != null) 'invoice_id': invoiceId,
      if (productId != null) 'product_id': productId,
      if (productName != null) 'product_name': productName,
      if (productCode != null) 'product_code': productCode,
      if (unit != null) 'unit': unit,
      if (unitPricePaise != null) 'unit_price_paise': unitPricePaise,
      if (quantity != null) 'quantity': quantity,
      if (discountPaise != null) 'discount_paise': discountPaise,
      if (gstRatePercent != null) 'gst_rate_percent': gstRatePercent,
      if (isTaxInclusive != null) 'is_tax_inclusive': isTaxInclusive,
      if (taxableAmountPaise != null)
        'taxable_amount_paise': taxableAmountPaise,
      if (taxAmountPaise != null) 'tax_amount_paise': taxAmountPaise,
      if (totalAmountPaise != null) 'total_amount_paise': totalAmountPaise,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InvoiceItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? invoiceId,
    Value<String?>? productId,
    Value<String>? productName,
    Value<String?>? productCode,
    Value<String>? unit,
    Value<int>? unitPricePaise,
    Value<double>? quantity,
    Value<int>? discountPaise,
    Value<double>? gstRatePercent,
    Value<bool>? isTaxInclusive,
    Value<int>? taxableAmountPaise,
    Value<int>? taxAmountPaise,
    Value<int>? totalAmountPaise,
    Value<int>? rowid,
  }) {
    return InvoiceItemsCompanion(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productCode: productCode ?? this.productCode,
      unit: unit ?? this.unit,
      unitPricePaise: unitPricePaise ?? this.unitPricePaise,
      quantity: quantity ?? this.quantity,
      discountPaise: discountPaise ?? this.discountPaise,
      gstRatePercent: gstRatePercent ?? this.gstRatePercent,
      isTaxInclusive: isTaxInclusive ?? this.isTaxInclusive,
      taxableAmountPaise: taxableAmountPaise ?? this.taxableAmountPaise,
      taxAmountPaise: taxAmountPaise ?? this.taxAmountPaise,
      totalAmountPaise: totalAmountPaise ?? this.totalAmountPaise,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (invoiceId.present) {
      map['invoice_id'] = Variable<String>(invoiceId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (productCode.present) {
      map['product_code'] = Variable<String>(productCode.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (unitPricePaise.present) {
      map['unit_price_paise'] = Variable<int>(unitPricePaise.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (discountPaise.present) {
      map['discount_paise'] = Variable<int>(discountPaise.value);
    }
    if (gstRatePercent.present) {
      map['gst_rate_percent'] = Variable<double>(gstRatePercent.value);
    }
    if (isTaxInclusive.present) {
      map['is_tax_inclusive'] = Variable<bool>(isTaxInclusive.value);
    }
    if (taxableAmountPaise.present) {
      map['taxable_amount_paise'] = Variable<int>(taxableAmountPaise.value);
    }
    if (taxAmountPaise.present) {
      map['tax_amount_paise'] = Variable<int>(taxAmountPaise.value);
    }
    if (totalAmountPaise.present) {
      map['total_amount_paise'] = Variable<int>(totalAmountPaise.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InvoiceItemsCompanion(')
          ..write('id: $id, ')
          ..write('invoiceId: $invoiceId, ')
          ..write('productId: $productId, ')
          ..write('productName: $productName, ')
          ..write('productCode: $productCode, ')
          ..write('unit: $unit, ')
          ..write('unitPricePaise: $unitPricePaise, ')
          ..write('quantity: $quantity, ')
          ..write('discountPaise: $discountPaise, ')
          ..write('gstRatePercent: $gstRatePercent, ')
          ..write('isTaxInclusive: $isTaxInclusive, ')
          ..write('taxableAmountPaise: $taxableAmountPaise, ')
          ..write('taxAmountPaise: $taxAmountPaise, ')
          ..write('totalAmountPaise: $totalAmountPaise, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BillNotesTable extends BillNotes
    with TableInfo<$BillNotesTable, BillNoteEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BillNotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _invoiceIdMeta = const VerificationMeta(
    'invoiceId',
  );
  @override
  late final GeneratedColumn<String> invoiceId = GeneratedColumn<String>(
    'invoice_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL UNIQUE REFERENCES invoices(id)',
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isCustomerFacingMeta = const VerificationMeta(
    'isCustomerFacing',
  );
  @override
  late final GeneratedColumn<bool> isCustomerFacing = GeneratedColumn<bool>(
    'is_customer_facing',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_customer_facing" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    invoiceId,
    note,
    isCustomerFacing,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bill_notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<BillNoteEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('invoice_id')) {
      context.handle(
        _invoiceIdMeta,
        invoiceId.isAcceptableOrUnknown(data['invoice_id']!, _invoiceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_invoiceIdMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    } else if (isInserting) {
      context.missing(_noteMeta);
    }
    if (data.containsKey('is_customer_facing')) {
      context.handle(
        _isCustomerFacingMeta,
        isCustomerFacing.isAcceptableOrUnknown(
          data['is_customer_facing']!,
          _isCustomerFacingMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BillNoteEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BillNoteEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      invoiceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invoice_id'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      isCustomerFacing: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_customer_facing'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $BillNotesTable createAlias(String alias) {
    return $BillNotesTable(attachedDatabase, alias);
  }
}

class BillNoteEntry extends DataClass implements Insertable<BillNoteEntry> {
  final String id;
  final String invoiceId;
  final String note;
  final bool isCustomerFacing;
  final DateTime createdAt;
  final DateTime updatedAt;
  const BillNoteEntry({
    required this.id,
    required this.invoiceId,
    required this.note,
    required this.isCustomerFacing,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['invoice_id'] = Variable<String>(invoiceId);
    map['note'] = Variable<String>(note);
    map['is_customer_facing'] = Variable<bool>(isCustomerFacing);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BillNotesCompanion toCompanion(bool nullToAbsent) {
    return BillNotesCompanion(
      id: Value(id),
      invoiceId: Value(invoiceId),
      note: Value(note),
      isCustomerFacing: Value(isCustomerFacing),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory BillNoteEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BillNoteEntry(
      id: serializer.fromJson<String>(json['id']),
      invoiceId: serializer.fromJson<String>(json['invoiceId']),
      note: serializer.fromJson<String>(json['note']),
      isCustomerFacing: serializer.fromJson<bool>(json['isCustomerFacing']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'invoiceId': serializer.toJson<String>(invoiceId),
      'note': serializer.toJson<String>(note),
      'isCustomerFacing': serializer.toJson<bool>(isCustomerFacing),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  BillNoteEntry copyWith({
    String? id,
    String? invoiceId,
    String? note,
    bool? isCustomerFacing,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => BillNoteEntry(
    id: id ?? this.id,
    invoiceId: invoiceId ?? this.invoiceId,
    note: note ?? this.note,
    isCustomerFacing: isCustomerFacing ?? this.isCustomerFacing,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  BillNoteEntry copyWithCompanion(BillNotesCompanion data) {
    return BillNoteEntry(
      id: data.id.present ? data.id.value : this.id,
      invoiceId: data.invoiceId.present ? data.invoiceId.value : this.invoiceId,
      note: data.note.present ? data.note.value : this.note,
      isCustomerFacing: data.isCustomerFacing.present
          ? data.isCustomerFacing.value
          : this.isCustomerFacing,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BillNoteEntry(')
          ..write('id: $id, ')
          ..write('invoiceId: $invoiceId, ')
          ..write('note: $note, ')
          ..write('isCustomerFacing: $isCustomerFacing, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, invoiceId, note, isCustomerFacing, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BillNoteEntry &&
          other.id == this.id &&
          other.invoiceId == this.invoiceId &&
          other.note == this.note &&
          other.isCustomerFacing == this.isCustomerFacing &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BillNotesCompanion extends UpdateCompanion<BillNoteEntry> {
  final Value<String> id;
  final Value<String> invoiceId;
  final Value<String> note;
  final Value<bool> isCustomerFacing;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const BillNotesCompanion({
    this.id = const Value.absent(),
    this.invoiceId = const Value.absent(),
    this.note = const Value.absent(),
    this.isCustomerFacing = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BillNotesCompanion.insert({
    required String id,
    required String invoiceId,
    required String note,
    this.isCustomerFacing = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       invoiceId = Value(invoiceId),
       note = Value(note),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<BillNoteEntry> custom({
    Expression<String>? id,
    Expression<String>? invoiceId,
    Expression<String>? note,
    Expression<bool>? isCustomerFacing,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (invoiceId != null) 'invoice_id': invoiceId,
      if (note != null) 'note': note,
      if (isCustomerFacing != null) 'is_customer_facing': isCustomerFacing,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BillNotesCompanion copyWith({
    Value<String>? id,
    Value<String>? invoiceId,
    Value<String>? note,
    Value<bool>? isCustomerFacing,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return BillNotesCompanion(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      note: note ?? this.note,
      isCustomerFacing: isCustomerFacing ?? this.isCustomerFacing,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (invoiceId.present) {
      map['invoice_id'] = Variable<String>(invoiceId.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (isCustomerFacing.present) {
      map['is_customer_facing'] = Variable<bool>(isCustomerFacing.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BillNotesCompanion(')
          ..write('id: $id, ')
          ..write('invoiceId: $invoiceId, ')
          ..write('note: $note, ')
          ..write('isCustomerFacing: $isCustomerFacing, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PaymentsTable extends Payments
    with TableInfo<$PaymentsTable, PaymentEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PaymentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _invoiceIdMeta = const VerificationMeta(
    'invoiceId',
  );
  @override
  late final GeneratedColumn<String> invoiceId = GeneratedColumn<String>(
    'invoice_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES invoices (id)',
    ),
  );
  static const VerificationMeta _amountPaiseMeta = const VerificationMeta(
    'amountPaise',
  );
  @override
  late final GeneratedColumn<int> amountPaise = GeneratedColumn<int>(
    'amount_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paymentMethodMeta = const VerificationMeta(
    'paymentMethod',
  );
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
    'payment_method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _referenceNumberMeta = const VerificationMeta(
    'referenceNumber',
  );
  @override
  late final GeneratedColumn<String> referenceNumber = GeneratedColumn<String>(
    'reference_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverVersionMeta = const VerificationMeta(
    'serverVersion',
  );
  @override
  late final GeneratedColumn<BigInt> serverVersion = GeneratedColumn<BigInt>(
    'server_version',
    aliasedName,
    true,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('synced'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    invoiceId,
    amountPaise,
    paymentMethod,
    referenceNumber,
    notes,
    createdAt,
    idempotencyKey,
    serverVersion,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'payments';
  @override
  VerificationContext validateIntegrity(
    Insertable<PaymentEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    }
    if (data.containsKey('invoice_id')) {
      context.handle(
        _invoiceIdMeta,
        invoiceId.isAcceptableOrUnknown(data['invoice_id']!, _invoiceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_invoiceIdMeta);
    }
    if (data.containsKey('amount_paise')) {
      context.handle(
        _amountPaiseMeta,
        amountPaise.isAcceptableOrUnknown(
          data['amount_paise']!,
          _amountPaiseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountPaiseMeta);
    }
    if (data.containsKey('payment_method')) {
      context.handle(
        _paymentMethodMeta,
        paymentMethod.isAcceptableOrUnknown(
          data['payment_method']!,
          _paymentMethodMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_paymentMethodMeta);
    }
    if (data.containsKey('reference_number')) {
      context.handle(
        _referenceNumberMeta,
        referenceNumber.isAcceptableOrUnknown(
          data['reference_number']!,
          _referenceNumberMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
        _idempotencyKeyMeta,
        idempotencyKey.isAcceptableOrUnknown(
          data['idempotency_key']!,
          _idempotencyKeyMeta,
        ),
      );
    }
    if (data.containsKey('server_version')) {
      context.handle(
        _serverVersionMeta,
        serverVersion.isAcceptableOrUnknown(
          data['server_version']!,
          _serverVersionMeta,
        ),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PaymentEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PaymentEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      ),
      invoiceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invoice_id'],
      )!,
      amountPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_paise'],
      )!,
      paymentMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_method'],
      )!,
      referenceNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference_number'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      ),
      serverVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}server_version'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      ),
    );
  }

  @override
  $PaymentsTable createAlias(String alias) {
    return $PaymentsTable(attachedDatabase, alias);
  }
}

class PaymentEntry extends DataClass implements Insertable<PaymentEntry> {
  final String id;
  final String? businessId;
  final String invoiceId;
  final int amountPaise;
  final String paymentMethod;
  final String? referenceNumber;
  final String? notes;
  final DateTime createdAt;
  final String? idempotencyKey;
  final BigInt? serverVersion;
  final String? syncStatus;
  const PaymentEntry({
    required this.id,
    this.businessId,
    required this.invoiceId,
    required this.amountPaise,
    required this.paymentMethod,
    this.referenceNumber,
    this.notes,
    required this.createdAt,
    this.idempotencyKey,
    this.serverVersion,
    this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || businessId != null) {
      map['business_id'] = Variable<String>(businessId);
    }
    map['invoice_id'] = Variable<String>(invoiceId);
    map['amount_paise'] = Variable<int>(amountPaise);
    map['payment_method'] = Variable<String>(paymentMethod);
    if (!nullToAbsent || referenceNumber != null) {
      map['reference_number'] = Variable<String>(referenceNumber);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || idempotencyKey != null) {
      map['idempotency_key'] = Variable<String>(idempotencyKey);
    }
    if (!nullToAbsent || serverVersion != null) {
      map['server_version'] = Variable<BigInt>(serverVersion);
    }
    if (!nullToAbsent || syncStatus != null) {
      map['sync_status'] = Variable<String>(syncStatus);
    }
    return map;
  }

  PaymentsCompanion toCompanion(bool nullToAbsent) {
    return PaymentsCompanion(
      id: Value(id),
      businessId: businessId == null && nullToAbsent
          ? const Value.absent()
          : Value(businessId),
      invoiceId: Value(invoiceId),
      amountPaise: Value(amountPaise),
      paymentMethod: Value(paymentMethod),
      referenceNumber: referenceNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(referenceNumber),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
      idempotencyKey: idempotencyKey == null && nullToAbsent
          ? const Value.absent()
          : Value(idempotencyKey),
      serverVersion: serverVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(serverVersion),
      syncStatus: syncStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(syncStatus),
    );
  }

  factory PaymentEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PaymentEntry(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String?>(json['businessId']),
      invoiceId: serializer.fromJson<String>(json['invoiceId']),
      amountPaise: serializer.fromJson<int>(json['amountPaise']),
      paymentMethod: serializer.fromJson<String>(json['paymentMethod']),
      referenceNumber: serializer.fromJson<String?>(json['referenceNumber']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      idempotencyKey: serializer.fromJson<String?>(json['idempotencyKey']),
      serverVersion: serializer.fromJson<BigInt?>(json['serverVersion']),
      syncStatus: serializer.fromJson<String?>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessId': serializer.toJson<String?>(businessId),
      'invoiceId': serializer.toJson<String>(invoiceId),
      'amountPaise': serializer.toJson<int>(amountPaise),
      'paymentMethod': serializer.toJson<String>(paymentMethod),
      'referenceNumber': serializer.toJson<String?>(referenceNumber),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'idempotencyKey': serializer.toJson<String?>(idempotencyKey),
      'serverVersion': serializer.toJson<BigInt?>(serverVersion),
      'syncStatus': serializer.toJson<String?>(syncStatus),
    };
  }

  PaymentEntry copyWith({
    String? id,
    Value<String?> businessId = const Value.absent(),
    String? invoiceId,
    int? amountPaise,
    String? paymentMethod,
    Value<String?> referenceNumber = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
    Value<String?> idempotencyKey = const Value.absent(),
    Value<BigInt?> serverVersion = const Value.absent(),
    Value<String?> syncStatus = const Value.absent(),
  }) => PaymentEntry(
    id: id ?? this.id,
    businessId: businessId.present ? businessId.value : this.businessId,
    invoiceId: invoiceId ?? this.invoiceId,
    amountPaise: amountPaise ?? this.amountPaise,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    referenceNumber: referenceNumber.present
        ? referenceNumber.value
        : this.referenceNumber,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
    idempotencyKey: idempotencyKey.present
        ? idempotencyKey.value
        : this.idempotencyKey,
    serverVersion: serverVersion.present
        ? serverVersion.value
        : this.serverVersion,
    syncStatus: syncStatus.present ? syncStatus.value : this.syncStatus,
  );
  PaymentEntry copyWithCompanion(PaymentsCompanion data) {
    return PaymentEntry(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      invoiceId: data.invoiceId.present ? data.invoiceId.value : this.invoiceId,
      amountPaise: data.amountPaise.present
          ? data.amountPaise.value
          : this.amountPaise,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      referenceNumber: data.referenceNumber.present
          ? data.referenceNumber.value
          : this.referenceNumber,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      serverVersion: data.serverVersion.present
          ? data.serverVersion.value
          : this.serverVersion,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PaymentEntry(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('invoiceId: $invoiceId, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('referenceNumber: $referenceNumber, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    businessId,
    invoiceId,
    amountPaise,
    paymentMethod,
    referenceNumber,
    notes,
    createdAt,
    idempotencyKey,
    serverVersion,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PaymentEntry &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.invoiceId == this.invoiceId &&
          other.amountPaise == this.amountPaise &&
          other.paymentMethod == this.paymentMethod &&
          other.referenceNumber == this.referenceNumber &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.idempotencyKey == this.idempotencyKey &&
          other.serverVersion == this.serverVersion &&
          other.syncStatus == this.syncStatus);
}

class PaymentsCompanion extends UpdateCompanion<PaymentEntry> {
  final Value<String> id;
  final Value<String?> businessId;
  final Value<String> invoiceId;
  final Value<int> amountPaise;
  final Value<String> paymentMethod;
  final Value<String?> referenceNumber;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<String?> idempotencyKey;
  final Value<BigInt?> serverVersion;
  final Value<String?> syncStatus;
  final Value<int> rowid;
  const PaymentsCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.invoiceId = const Value.absent(),
    this.amountPaise = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.referenceNumber = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PaymentsCompanion.insert({
    required String id,
    this.businessId = const Value.absent(),
    required String invoiceId,
    required int amountPaise,
    required String paymentMethod,
    this.referenceNumber = const Value.absent(),
    this.notes = const Value.absent(),
    required DateTime createdAt,
    this.idempotencyKey = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       invoiceId = Value(invoiceId),
       amountPaise = Value(amountPaise),
       paymentMethod = Value(paymentMethod),
       createdAt = Value(createdAt);
  static Insertable<PaymentEntry> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? invoiceId,
    Expression<int>? amountPaise,
    Expression<String>? paymentMethod,
    Expression<String>? referenceNumber,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<String>? idempotencyKey,
    Expression<BigInt>? serverVersion,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (invoiceId != null) 'invoice_id': invoiceId,
      if (amountPaise != null) 'amount_paise': amountPaise,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (referenceNumber != null) 'reference_number': referenceNumber,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (serverVersion != null) 'server_version': serverVersion,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PaymentsCompanion copyWith({
    Value<String>? id,
    Value<String?>? businessId,
    Value<String>? invoiceId,
    Value<int>? amountPaise,
    Value<String>? paymentMethod,
    Value<String?>? referenceNumber,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
    Value<String?>? idempotencyKey,
    Value<BigInt?>? serverVersion,
    Value<String?>? syncStatus,
    Value<int>? rowid,
  }) {
    return PaymentsCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      invoiceId: invoiceId ?? this.invoiceId,
      amountPaise: amountPaise ?? this.amountPaise,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      serverVersion: serverVersion ?? this.serverVersion,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (invoiceId.present) {
      map['invoice_id'] = Variable<String>(invoiceId.value);
    }
    if (amountPaise.present) {
      map['amount_paise'] = Variable<int>(amountPaise.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (referenceNumber.present) {
      map['reference_number'] = Variable<String>(referenceNumber.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (serverVersion.present) {
      map['server_version'] = Variable<BigInt>(serverVersion.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PaymentsCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('invoiceId: $invoiceId, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('referenceNumber: $referenceNumber, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CustomersTable extends Customers
    with TableInfo<$CustomersTable, CustomerEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverVersionMeta = const VerificationMeta(
    'serverVersion',
  );
  @override
  late final GeneratedColumn<BigInt> serverVersion = GeneratedColumn<BigInt>(
    'server_version',
    aliasedName,
    true,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('synced'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    name,
    phone,
    address,
    notes,
    createdAt,
    deletedAt,
    serverVersion,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'customers';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomerEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('server_version')) {
      context.handle(
        _serverVersionMeta,
        serverVersion.isAcceptableOrUnknown(
          data['server_version']!,
          _serverVersionMeta,
        ),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomerEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomerEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      serverVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}server_version'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      ),
    );
  }

  @override
  $CustomersTable createAlias(String alias) {
    return $CustomersTable(attachedDatabase, alias);
  }
}

class CustomerEntry extends DataClass implements Insertable<CustomerEntry> {
  final String id;
  final String? businessId;
  final String name;
  final String? phone;
  final String? address;
  final String? notes;
  final DateTime createdAt;
  final DateTime? deletedAt;
  final BigInt? serverVersion;
  final String? syncStatus;
  const CustomerEntry({
    required this.id,
    this.businessId,
    required this.name,
    this.phone,
    this.address,
    this.notes,
    required this.createdAt,
    this.deletedAt,
    this.serverVersion,
    this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || businessId != null) {
      map['business_id'] = Variable<String>(businessId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || serverVersion != null) {
      map['server_version'] = Variable<BigInt>(serverVersion);
    }
    if (!nullToAbsent || syncStatus != null) {
      map['sync_status'] = Variable<String>(syncStatus);
    }
    return map;
  }

  CustomersCompanion toCompanion(bool nullToAbsent) {
    return CustomersCompanion(
      id: Value(id),
      businessId: businessId == null && nullToAbsent
          ? const Value.absent()
          : Value(businessId),
      name: Value(name),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      serverVersion: serverVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(serverVersion),
      syncStatus: syncStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(syncStatus),
    );
  }

  factory CustomerEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomerEntry(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String?>(json['businessId']),
      name: serializer.fromJson<String>(json['name']),
      phone: serializer.fromJson<String?>(json['phone']),
      address: serializer.fromJson<String?>(json['address']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      serverVersion: serializer.fromJson<BigInt?>(json['serverVersion']),
      syncStatus: serializer.fromJson<String?>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessId': serializer.toJson<String?>(businessId),
      'name': serializer.toJson<String>(name),
      'phone': serializer.toJson<String?>(phone),
      'address': serializer.toJson<String?>(address),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'serverVersion': serializer.toJson<BigInt?>(serverVersion),
      'syncStatus': serializer.toJson<String?>(syncStatus),
    };
  }

  CustomerEntry copyWith({
    String? id,
    Value<String?> businessId = const Value.absent(),
    String? name,
    Value<String?> phone = const Value.absent(),
    Value<String?> address = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<BigInt?> serverVersion = const Value.absent(),
    Value<String?> syncStatus = const Value.absent(),
  }) => CustomerEntry(
    id: id ?? this.id,
    businessId: businessId.present ? businessId.value : this.businessId,
    name: name ?? this.name,
    phone: phone.present ? phone.value : this.phone,
    address: address.present ? address.value : this.address,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    serverVersion: serverVersion.present
        ? serverVersion.value
        : this.serverVersion,
    syncStatus: syncStatus.present ? syncStatus.value : this.syncStatus,
  );
  CustomerEntry copyWithCompanion(CustomersCompanion data) {
    return CustomerEntry(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      name: data.name.present ? data.name.value : this.name,
      phone: data.phone.present ? data.phone.value : this.phone,
      address: data.address.present ? data.address.value : this.address,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      serverVersion: data.serverVersion.present
          ? data.serverVersion.value
          : this.serverVersion,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomerEntry(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('address: $address, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    businessId,
    name,
    phone,
    address,
    notes,
    createdAt,
    deletedAt,
    serverVersion,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomerEntry &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.name == this.name &&
          other.phone == this.phone &&
          other.address == this.address &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.deletedAt == this.deletedAt &&
          other.serverVersion == this.serverVersion &&
          other.syncStatus == this.syncStatus);
}

class CustomersCompanion extends UpdateCompanion<CustomerEntry> {
  final Value<String> id;
  final Value<String?> businessId;
  final Value<String> name;
  final Value<String?> phone;
  final Value<String?> address;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime?> deletedAt;
  final Value<BigInt?> serverVersion;
  final Value<String?> syncStatus;
  final Value<int> rowid;
  const CustomersCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
    this.address = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomersCompanion.insert({
    required String id,
    this.businessId = const Value.absent(),
    required String name,
    this.phone = const Value.absent(),
    this.address = const Value.absent(),
    this.notes = const Value.absent(),
    required DateTime createdAt,
    this.deletedAt = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<CustomerEntry> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? name,
    Expression<String>? phone,
    Expression<String>? address,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? deletedAt,
    Expression<BigInt>? serverVersion,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (serverVersion != null) 'server_version': serverVersion,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomersCompanion copyWith({
    Value<String>? id,
    Value<String?>? businessId,
    Value<String>? name,
    Value<String?>? phone,
    Value<String?>? address,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
    Value<DateTime?>? deletedAt,
    Value<BigInt?>? serverVersion,
    Value<String?>? syncStatus,
    Value<int>? rowid,
  }) {
    return CustomersCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
      serverVersion: serverVersion ?? this.serverVersion,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (serverVersion.present) {
      map['server_version'] = Variable<BigInt>(serverVersion.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomersCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('address: $address, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSettingEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSettingEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSettingEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSettingEntry(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSettingEntry extends DataClass implements Insertable<AppSettingEntry> {
  final String key;
  final String value;
  const AppSettingEntry({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory AppSettingEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSettingEntry(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppSettingEntry copyWith({String? key, String? value}) =>
      AppSettingEntry(key: key ?? this.key, value: value ?? this.value);
  AppSettingEntry copyWithCompanion(AppSettingsCompanion data) {
    return AppSettingEntry(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingEntry(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettingEntry &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<AppSettingEntry> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppSettingEntry> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductImagesTable extends ProductImages
    with TableInfo<$ProductImagesTable, ProductImageEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductImagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES products (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _imageBytesMeta = const VerificationMeta(
    'imageBytes',
  );
  @override
  late final GeneratedColumn<Uint8List> imageBytes = GeneratedColumn<Uint8List>(
    'image_bytes',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isPrimaryMeta = const VerificationMeta(
    'isPrimary',
  );
  @override
  late final GeneratedColumn<bool> isPrimary = GeneratedColumn<bool>(
    'is_primary',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_primary" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _displayOrderMeta = const VerificationMeta(
    'displayOrder',
  );
  @override
  late final GeneratedColumn<int> displayOrder = GeneratedColumn<int>(
    'display_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    productId,
    imageBytes,
    isPrimary,
    displayOrder,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'product_images';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductImageEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('image_bytes')) {
      context.handle(
        _imageBytesMeta,
        imageBytes.isAcceptableOrUnknown(data['image_bytes']!, _imageBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_imageBytesMeta);
    }
    if (data.containsKey('is_primary')) {
      context.handle(
        _isPrimaryMeta,
        isPrimary.isAcceptableOrUnknown(data['is_primary']!, _isPrimaryMeta),
      );
    }
    if (data.containsKey('display_order')) {
      context.handle(
        _displayOrderMeta,
        displayOrder.isAcceptableOrUnknown(
          data['display_order']!,
          _displayOrderMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProductImageEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductImageEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      imageBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}image_bytes'],
      )!,
      isPrimary: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_primary'],
      )!,
      displayOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}display_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ProductImagesTable createAlias(String alias) {
    return $ProductImagesTable(attachedDatabase, alias);
  }
}

class ProductImageEntry extends DataClass
    implements Insertable<ProductImageEntry> {
  final String id;
  final String productId;
  final Uint8List imageBytes;
  final bool isPrimary;
  final int displayOrder;
  final DateTime createdAt;
  const ProductImageEntry({
    required this.id,
    required this.productId,
    required this.imageBytes,
    required this.isPrimary,
    required this.displayOrder,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['product_id'] = Variable<String>(productId);
    map['image_bytes'] = Variable<Uint8List>(imageBytes);
    map['is_primary'] = Variable<bool>(isPrimary);
    map['display_order'] = Variable<int>(displayOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ProductImagesCompanion toCompanion(bool nullToAbsent) {
    return ProductImagesCompanion(
      id: Value(id),
      productId: Value(productId),
      imageBytes: Value(imageBytes),
      isPrimary: Value(isPrimary),
      displayOrder: Value(displayOrder),
      createdAt: Value(createdAt),
    );
  }

  factory ProductImageEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductImageEntry(
      id: serializer.fromJson<String>(json['id']),
      productId: serializer.fromJson<String>(json['productId']),
      imageBytes: serializer.fromJson<Uint8List>(json['imageBytes']),
      isPrimary: serializer.fromJson<bool>(json['isPrimary']),
      displayOrder: serializer.fromJson<int>(json['displayOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'productId': serializer.toJson<String>(productId),
      'imageBytes': serializer.toJson<Uint8List>(imageBytes),
      'isPrimary': serializer.toJson<bool>(isPrimary),
      'displayOrder': serializer.toJson<int>(displayOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ProductImageEntry copyWith({
    String? id,
    String? productId,
    Uint8List? imageBytes,
    bool? isPrimary,
    int? displayOrder,
    DateTime? createdAt,
  }) => ProductImageEntry(
    id: id ?? this.id,
    productId: productId ?? this.productId,
    imageBytes: imageBytes ?? this.imageBytes,
    isPrimary: isPrimary ?? this.isPrimary,
    displayOrder: displayOrder ?? this.displayOrder,
    createdAt: createdAt ?? this.createdAt,
  );
  ProductImageEntry copyWithCompanion(ProductImagesCompanion data) {
    return ProductImageEntry(
      id: data.id.present ? data.id.value : this.id,
      productId: data.productId.present ? data.productId.value : this.productId,
      imageBytes: data.imageBytes.present
          ? data.imageBytes.value
          : this.imageBytes,
      isPrimary: data.isPrimary.present ? data.isPrimary.value : this.isPrimary,
      displayOrder: data.displayOrder.present
          ? data.displayOrder.value
          : this.displayOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductImageEntry(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('imageBytes: $imageBytes, ')
          ..write('isPrimary: $isPrimary, ')
          ..write('displayOrder: $displayOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    productId,
    $driftBlobEquality.hash(imageBytes),
    isPrimary,
    displayOrder,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductImageEntry &&
          other.id == this.id &&
          other.productId == this.productId &&
          $driftBlobEquality.equals(other.imageBytes, this.imageBytes) &&
          other.isPrimary == this.isPrimary &&
          other.displayOrder == this.displayOrder &&
          other.createdAt == this.createdAt);
}

class ProductImagesCompanion extends UpdateCompanion<ProductImageEntry> {
  final Value<String> id;
  final Value<String> productId;
  final Value<Uint8List> imageBytes;
  final Value<bool> isPrimary;
  final Value<int> displayOrder;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ProductImagesCompanion({
    this.id = const Value.absent(),
    this.productId = const Value.absent(),
    this.imageBytes = const Value.absent(),
    this.isPrimary = const Value.absent(),
    this.displayOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductImagesCompanion.insert({
    required String id,
    required String productId,
    required Uint8List imageBytes,
    this.isPrimary = const Value.absent(),
    this.displayOrder = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       productId = Value(productId),
       imageBytes = Value(imageBytes),
       createdAt = Value(createdAt);
  static Insertable<ProductImageEntry> custom({
    Expression<String>? id,
    Expression<String>? productId,
    Expression<Uint8List>? imageBytes,
    Expression<bool>? isPrimary,
    Expression<int>? displayOrder,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      if (imageBytes != null) 'image_bytes': imageBytes,
      if (isPrimary != null) 'is_primary': isPrimary,
      if (displayOrder != null) 'display_order': displayOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductImagesCompanion copyWith({
    Value<String>? id,
    Value<String>? productId,
    Value<Uint8List>? imageBytes,
    Value<bool>? isPrimary,
    Value<int>? displayOrder,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ProductImagesCompanion(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      imageBytes: imageBytes ?? this.imageBytes,
      isPrimary: isPrimary ?? this.isPrimary,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (imageBytes.present) {
      map['image_bytes'] = Variable<Uint8List>(imageBytes.value);
    }
    if (isPrimary.present) {
      map['is_primary'] = Variable<bool>(isPrimary.value);
    }
    if (displayOrder.present) {
      map['display_order'] = Variable<int>(displayOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductImagesCompanion(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('imageBytes: $imageBytes, ')
          ..write('isPrimary: $isPrimary, ')
          ..write('displayOrder: $displayOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UsersTable extends Users with TableInfo<$UsersTable, UserEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL UNIQUE',
  );
  static const VerificationMeta _fullNameMeta = const VerificationMeta(
    'fullName',
  );
  @override
  late final GeneratedColumn<String> fullName = GeneratedColumn<String>(
    'full_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _passwordHashMeta = const VerificationMeta(
    'passwordHash',
  );
  @override
  late final GeneratedColumn<String> passwordHash = GeneratedColumn<String>(
    'password_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _saltMeta = const VerificationMeta('salt');
  @override
  late final GeneratedColumn<String> salt = GeneratedColumn<String>(
    'salt',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    username,
    fullName,
    role,
    passwordHash,
    salt,
    isActive,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('full_name')) {
      context.handle(
        _fullNameMeta,
        fullName.isAcceptableOrUnknown(data['full_name']!, _fullNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fullNameMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('password_hash')) {
      context.handle(
        _passwordHashMeta,
        passwordHash.isAcceptableOrUnknown(
          data['password_hash']!,
          _passwordHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_passwordHashMeta);
    }
    if (data.containsKey('salt')) {
      context.handle(
        _saltMeta,
        salt.isAcceptableOrUnknown(data['salt']!, _saltMeta),
      );
    } else if (isInserting) {
      context.missing(_saltMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      ),
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
      )!,
      fullName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}full_name'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      passwordHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}password_hash'],
      )!,
      salt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}salt'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class UserEntry extends DataClass implements Insertable<UserEntry> {
  final String id;
  final String? businessId;
  final String username;
  final String fullName;
  final String role;
  final String passwordHash;
  final String salt;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  const UserEntry({
    required this.id,
    this.businessId,
    required this.username,
    required this.fullName,
    required this.role,
    required this.passwordHash,
    required this.salt,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || businessId != null) {
      map['business_id'] = Variable<String>(businessId);
    }
    map['username'] = Variable<String>(username);
    map['full_name'] = Variable<String>(fullName);
    map['role'] = Variable<String>(role);
    map['password_hash'] = Variable<String>(passwordHash);
    map['salt'] = Variable<String>(salt);
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      businessId: businessId == null && nullToAbsent
          ? const Value.absent()
          : Value(businessId),
      username: Value(username),
      fullName: Value(fullName),
      role: Value(role),
      passwordHash: Value(passwordHash),
      salt: Value(salt),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory UserEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserEntry(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String?>(json['businessId']),
      username: serializer.fromJson<String>(json['username']),
      fullName: serializer.fromJson<String>(json['fullName']),
      role: serializer.fromJson<String>(json['role']),
      passwordHash: serializer.fromJson<String>(json['passwordHash']),
      salt: serializer.fromJson<String>(json['salt']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessId': serializer.toJson<String?>(businessId),
      'username': serializer.toJson<String>(username),
      'fullName': serializer.toJson<String>(fullName),
      'role': serializer.toJson<String>(role),
      'passwordHash': serializer.toJson<String>(passwordHash),
      'salt': serializer.toJson<String>(salt),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  UserEntry copyWith({
    String? id,
    Value<String?> businessId = const Value.absent(),
    String? username,
    String? fullName,
    String? role,
    String? passwordHash,
    String? salt,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => UserEntry(
    id: id ?? this.id,
    businessId: businessId.present ? businessId.value : this.businessId,
    username: username ?? this.username,
    fullName: fullName ?? this.fullName,
    role: role ?? this.role,
    passwordHash: passwordHash ?? this.passwordHash,
    salt: salt ?? this.salt,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  UserEntry copyWithCompanion(UsersCompanion data) {
    return UserEntry(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      username: data.username.present ? data.username.value : this.username,
      fullName: data.fullName.present ? data.fullName.value : this.fullName,
      role: data.role.present ? data.role.value : this.role,
      passwordHash: data.passwordHash.present
          ? data.passwordHash.value
          : this.passwordHash,
      salt: data.salt.present ? data.salt.value : this.salt,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserEntry(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('username: $username, ')
          ..write('fullName: $fullName, ')
          ..write('role: $role, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('salt: $salt, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    businessId,
    username,
    fullName,
    role,
    passwordHash,
    salt,
    isActive,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserEntry &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.username == this.username &&
          other.fullName == this.fullName &&
          other.role == this.role &&
          other.passwordHash == this.passwordHash &&
          other.salt == this.salt &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class UsersCompanion extends UpdateCompanion<UserEntry> {
  final Value<String> id;
  final Value<String?> businessId;
  final Value<String> username;
  final Value<String> fullName;
  final Value<String> role;
  final Value<String> passwordHash;
  final Value<String> salt;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.username = const Value.absent(),
    this.fullName = const Value.absent(),
    this.role = const Value.absent(),
    this.passwordHash = const Value.absent(),
    this.salt = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsersCompanion.insert({
    required String id,
    this.businessId = const Value.absent(),
    required String username,
    required String fullName,
    required String role,
    required String passwordHash,
    required String salt,
    this.isActive = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       username = Value(username),
       fullName = Value(fullName),
       role = Value(role),
       passwordHash = Value(passwordHash),
       salt = Value(salt),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<UserEntry> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? username,
    Expression<String>? fullName,
    Expression<String>? role,
    Expression<String>? passwordHash,
    Expression<String>? salt,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (username != null) 'username': username,
      if (fullName != null) 'full_name': fullName,
      if (role != null) 'role': role,
      if (passwordHash != null) 'password_hash': passwordHash,
      if (salt != null) 'salt': salt,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsersCompanion copyWith({
    Value<String>? id,
    Value<String?>? businessId,
    Value<String>? username,
    Value<String>? fullName,
    Value<String>? role,
    Value<String>? passwordHash,
    Value<String>? salt,
    Value<bool>? isActive,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return UsersCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      passwordHash: passwordHash ?? this.passwordHash,
      salt: salt ?? this.salt,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (fullName.present) {
      map['full_name'] = Variable<String>(fullName.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (passwordHash.present) {
      map['password_hash'] = Variable<String>(passwordHash.value);
    }
    if (salt.present) {
      map['salt'] = Variable<String>(salt.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('username: $username, ')
          ..write('fullName: $fullName, ')
          ..write('role: $role, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('salt: $salt, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DiningTablesTable extends DiningTables
    with TableInfo<$DiningTablesTable, DiningTableEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DiningTablesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seatingCapacityMeta = const VerificationMeta(
    'seatingCapacity',
  );
  @override
  late final GeneratedColumn<int> seatingCapacity = GeneratedColumn<int>(
    'seating_capacity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(4),
  );
  static const VerificationMeta _isOccupiedMeta = const VerificationMeta(
    'isOccupied',
  );
  @override
  late final GeneratedColumn<bool> isOccupied = GeneratedColumn<bool>(
    'is_occupied',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_occupied" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _currentInvoiceIdMeta = const VerificationMeta(
    'currentInvoiceId',
  );
  @override
  late final GeneratedColumn<String> currentInvoiceId = GeneratedColumn<String>(
    'current_invoice_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('synced'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    name,
    seatingCapacity,
    isOccupied,
    currentInvoiceId,
    updatedAt,
    deletedAt,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dining_tables';
  @override
  VerificationContext validateIntegrity(
    Insertable<DiningTableEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('seating_capacity')) {
      context.handle(
        _seatingCapacityMeta,
        seatingCapacity.isAcceptableOrUnknown(
          data['seating_capacity']!,
          _seatingCapacityMeta,
        ),
      );
    }
    if (data.containsKey('is_occupied')) {
      context.handle(
        _isOccupiedMeta,
        isOccupied.isAcceptableOrUnknown(data['is_occupied']!, _isOccupiedMeta),
      );
    }
    if (data.containsKey('current_invoice_id')) {
      context.handle(
        _currentInvoiceIdMeta,
        currentInvoiceId.isAcceptableOrUnknown(
          data['current_invoice_id']!,
          _currentInvoiceIdMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DiningTableEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DiningTableEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      seatingCapacity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seating_capacity'],
      )!,
      isOccupied: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_occupied'],
      )!,
      currentInvoiceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}current_invoice_id'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      ),
    );
  }

  @override
  $DiningTablesTable createAlias(String alias) {
    return $DiningTablesTable(attachedDatabase, alias);
  }
}

class DiningTableEntry extends DataClass
    implements Insertable<DiningTableEntry> {
  final String id;
  final String? businessId;
  final String name;
  final int seatingCapacity;
  final bool isOccupied;
  final String? currentInvoiceId;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String? syncStatus;
  const DiningTableEntry({
    required this.id,
    this.businessId,
    required this.name,
    required this.seatingCapacity,
    required this.isOccupied,
    this.currentInvoiceId,
    required this.updatedAt,
    this.deletedAt,
    this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || businessId != null) {
      map['business_id'] = Variable<String>(businessId);
    }
    map['name'] = Variable<String>(name);
    map['seating_capacity'] = Variable<int>(seatingCapacity);
    map['is_occupied'] = Variable<bool>(isOccupied);
    if (!nullToAbsent || currentInvoiceId != null) {
      map['current_invoice_id'] = Variable<String>(currentInvoiceId);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || syncStatus != null) {
      map['sync_status'] = Variable<String>(syncStatus);
    }
    return map;
  }

  DiningTablesCompanion toCompanion(bool nullToAbsent) {
    return DiningTablesCompanion(
      id: Value(id),
      businessId: businessId == null && nullToAbsent
          ? const Value.absent()
          : Value(businessId),
      name: Value(name),
      seatingCapacity: Value(seatingCapacity),
      isOccupied: Value(isOccupied),
      currentInvoiceId: currentInvoiceId == null && nullToAbsent
          ? const Value.absent()
          : Value(currentInvoiceId),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncStatus: syncStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(syncStatus),
    );
  }

  factory DiningTableEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DiningTableEntry(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String?>(json['businessId']),
      name: serializer.fromJson<String>(json['name']),
      seatingCapacity: serializer.fromJson<int>(json['seatingCapacity']),
      isOccupied: serializer.fromJson<bool>(json['isOccupied']),
      currentInvoiceId: serializer.fromJson<String?>(json['currentInvoiceId']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      syncStatus: serializer.fromJson<String?>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessId': serializer.toJson<String?>(businessId),
      'name': serializer.toJson<String>(name),
      'seatingCapacity': serializer.toJson<int>(seatingCapacity),
      'isOccupied': serializer.toJson<bool>(isOccupied),
      'currentInvoiceId': serializer.toJson<String?>(currentInvoiceId),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'syncStatus': serializer.toJson<String?>(syncStatus),
    };
  }

  DiningTableEntry copyWith({
    String? id,
    Value<String?> businessId = const Value.absent(),
    String? name,
    int? seatingCapacity,
    bool? isOccupied,
    Value<String?> currentInvoiceId = const Value.absent(),
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<String?> syncStatus = const Value.absent(),
  }) => DiningTableEntry(
    id: id ?? this.id,
    businessId: businessId.present ? businessId.value : this.businessId,
    name: name ?? this.name,
    seatingCapacity: seatingCapacity ?? this.seatingCapacity,
    isOccupied: isOccupied ?? this.isOccupied,
    currentInvoiceId: currentInvoiceId.present
        ? currentInvoiceId.value
        : this.currentInvoiceId,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncStatus: syncStatus.present ? syncStatus.value : this.syncStatus,
  );
  DiningTableEntry copyWithCompanion(DiningTablesCompanion data) {
    return DiningTableEntry(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      name: data.name.present ? data.name.value : this.name,
      seatingCapacity: data.seatingCapacity.present
          ? data.seatingCapacity.value
          : this.seatingCapacity,
      isOccupied: data.isOccupied.present
          ? data.isOccupied.value
          : this.isOccupied,
      currentInvoiceId: data.currentInvoiceId.present
          ? data.currentInvoiceId.value
          : this.currentInvoiceId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DiningTableEntry(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('name: $name, ')
          ..write('seatingCapacity: $seatingCapacity, ')
          ..write('isOccupied: $isOccupied, ')
          ..write('currentInvoiceId: $currentInvoiceId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    businessId,
    name,
    seatingCapacity,
    isOccupied,
    currentInvoiceId,
    updatedAt,
    deletedAt,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DiningTableEntry &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.name == this.name &&
          other.seatingCapacity == this.seatingCapacity &&
          other.isOccupied == this.isOccupied &&
          other.currentInvoiceId == this.currentInvoiceId &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncStatus == this.syncStatus);
}

class DiningTablesCompanion extends UpdateCompanion<DiningTableEntry> {
  final Value<String> id;
  final Value<String?> businessId;
  final Value<String> name;
  final Value<int> seatingCapacity;
  final Value<bool> isOccupied;
  final Value<String?> currentInvoiceId;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String?> syncStatus;
  final Value<int> rowid;
  const DiningTablesCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.name = const Value.absent(),
    this.seatingCapacity = const Value.absent(),
    this.isOccupied = const Value.absent(),
    this.currentInvoiceId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DiningTablesCompanion.insert({
    required String id,
    this.businessId = const Value.absent(),
    required String name,
    this.seatingCapacity = const Value.absent(),
    this.isOccupied = const Value.absent(),
    this.currentInvoiceId = const Value.absent(),
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       updatedAt = Value(updatedAt);
  static Insertable<DiningTableEntry> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? name,
    Expression<int>? seatingCapacity,
    Expression<bool>? isOccupied,
    Expression<String>? currentInvoiceId,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (name != null) 'name': name,
      if (seatingCapacity != null) 'seating_capacity': seatingCapacity,
      if (isOccupied != null) 'is_occupied': isOccupied,
      if (currentInvoiceId != null) 'current_invoice_id': currentInvoiceId,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DiningTablesCompanion copyWith({
    Value<String>? id,
    Value<String?>? businessId,
    Value<String>? name,
    Value<int>? seatingCapacity,
    Value<bool>? isOccupied,
    Value<String?>? currentInvoiceId,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String?>? syncStatus,
    Value<int>? rowid,
  }) {
    return DiningTablesCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      seatingCapacity: seatingCapacity ?? this.seatingCapacity,
      isOccupied: isOccupied ?? this.isOccupied,
      currentInvoiceId: currentInvoiceId ?? this.currentInvoiceId,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (seatingCapacity.present) {
      map['seating_capacity'] = Variable<int>(seatingCapacity.value);
    }
    if (isOccupied.present) {
      map['is_occupied'] = Variable<bool>(isOccupied.value);
    }
    if (currentInvoiceId.present) {
      map['current_invoice_id'] = Variable<String>(currentInvoiceId.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DiningTablesCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('name: $name, ')
          ..write('seatingCapacity: $seatingCapacity, ')
          ..write('isOccupied: $isOccupied, ')
          ..write('currentInvoiceId: $currentInvoiceId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $KotRecordsTable extends KotRecords
    with TableInfo<$KotRecordsTable, KotRecordEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KotRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _invoiceIdMeta = const VerificationMeta(
    'invoiceId',
  );
  @override
  late final GeneratedColumn<String> invoiceId = GeneratedColumn<String>(
    'invoice_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kotNumberMeta = const VerificationMeta(
    'kotNumber',
  );
  @override
  late final GeneratedColumn<String> kotNumber = GeneratedColumn<String>(
    'kot_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderTypeMeta = const VerificationMeta(
    'orderType',
  );
  @override
  late final GeneratedColumn<String> orderType = GeneratedColumn<String>(
    'order_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tableNumberMeta = const VerificationMeta(
    'tableNumber',
  );
  @override
  late final GeneratedColumn<String> tableNumber = GeneratedColumn<String>(
    'table_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _itemsJsonMeta = const VerificationMeta(
    'itemsJson',
  );
  @override
  late final GeneratedColumn<String> itemsJson = GeneratedColumn<String>(
    'items_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reprintCountMeta = const VerificationMeta(
    'reprintCount',
  );
  @override
  late final GeneratedColumn<int> reprintCount = GeneratedColumn<int>(
    'reprint_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverVersionMeta = const VerificationMeta(
    'serverVersion',
  );
  @override
  late final GeneratedColumn<BigInt> serverVersion = GeneratedColumn<BigInt>(
    'server_version',
    aliasedName,
    true,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('synced'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    invoiceId,
    kotNumber,
    orderType,
    tableNumber,
    itemsJson,
    reprintCount,
    createdAt,
    serverVersion,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'kot_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<KotRecordEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('invoice_id')) {
      context.handle(
        _invoiceIdMeta,
        invoiceId.isAcceptableOrUnknown(data['invoice_id']!, _invoiceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_invoiceIdMeta);
    }
    if (data.containsKey('kot_number')) {
      context.handle(
        _kotNumberMeta,
        kotNumber.isAcceptableOrUnknown(data['kot_number']!, _kotNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_kotNumberMeta);
    }
    if (data.containsKey('order_type')) {
      context.handle(
        _orderTypeMeta,
        orderType.isAcceptableOrUnknown(data['order_type']!, _orderTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_orderTypeMeta);
    }
    if (data.containsKey('table_number')) {
      context.handle(
        _tableNumberMeta,
        tableNumber.isAcceptableOrUnknown(
          data['table_number']!,
          _tableNumberMeta,
        ),
      );
    }
    if (data.containsKey('items_json')) {
      context.handle(
        _itemsJsonMeta,
        itemsJson.isAcceptableOrUnknown(data['items_json']!, _itemsJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_itemsJsonMeta);
    }
    if (data.containsKey('reprint_count')) {
      context.handle(
        _reprintCountMeta,
        reprintCount.isAcceptableOrUnknown(
          data['reprint_count']!,
          _reprintCountMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('server_version')) {
      context.handle(
        _serverVersionMeta,
        serverVersion.isAcceptableOrUnknown(
          data['server_version']!,
          _serverVersionMeta,
        ),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  KotRecordEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KotRecordEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      invoiceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invoice_id'],
      )!,
      kotNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kot_number'],
      )!,
      orderType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_type'],
      )!,
      tableNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}table_number'],
      ),
      itemsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}items_json'],
      )!,
      reprintCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reprint_count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      serverVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}server_version'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      ),
    );
  }

  @override
  $KotRecordsTable createAlias(String alias) {
    return $KotRecordsTable(attachedDatabase, alias);
  }
}

class KotRecordEntry extends DataClass implements Insertable<KotRecordEntry> {
  final String id;
  final String invoiceId;
  final String kotNumber;
  final String orderType;
  final String? tableNumber;
  final String itemsJson;
  final int reprintCount;
  final DateTime createdAt;
  final BigInt? serverVersion;
  final String? syncStatus;
  const KotRecordEntry({
    required this.id,
    required this.invoiceId,
    required this.kotNumber,
    required this.orderType,
    this.tableNumber,
    required this.itemsJson,
    required this.reprintCount,
    required this.createdAt,
    this.serverVersion,
    this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['invoice_id'] = Variable<String>(invoiceId);
    map['kot_number'] = Variable<String>(kotNumber);
    map['order_type'] = Variable<String>(orderType);
    if (!nullToAbsent || tableNumber != null) {
      map['table_number'] = Variable<String>(tableNumber);
    }
    map['items_json'] = Variable<String>(itemsJson);
    map['reprint_count'] = Variable<int>(reprintCount);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || serverVersion != null) {
      map['server_version'] = Variable<BigInt>(serverVersion);
    }
    if (!nullToAbsent || syncStatus != null) {
      map['sync_status'] = Variable<String>(syncStatus);
    }
    return map;
  }

  KotRecordsCompanion toCompanion(bool nullToAbsent) {
    return KotRecordsCompanion(
      id: Value(id),
      invoiceId: Value(invoiceId),
      kotNumber: Value(kotNumber),
      orderType: Value(orderType),
      tableNumber: tableNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(tableNumber),
      itemsJson: Value(itemsJson),
      reprintCount: Value(reprintCount),
      createdAt: Value(createdAt),
      serverVersion: serverVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(serverVersion),
      syncStatus: syncStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(syncStatus),
    );
  }

  factory KotRecordEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KotRecordEntry(
      id: serializer.fromJson<String>(json['id']),
      invoiceId: serializer.fromJson<String>(json['invoiceId']),
      kotNumber: serializer.fromJson<String>(json['kotNumber']),
      orderType: serializer.fromJson<String>(json['orderType']),
      tableNumber: serializer.fromJson<String?>(json['tableNumber']),
      itemsJson: serializer.fromJson<String>(json['itemsJson']),
      reprintCount: serializer.fromJson<int>(json['reprintCount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      serverVersion: serializer.fromJson<BigInt?>(json['serverVersion']),
      syncStatus: serializer.fromJson<String?>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'invoiceId': serializer.toJson<String>(invoiceId),
      'kotNumber': serializer.toJson<String>(kotNumber),
      'orderType': serializer.toJson<String>(orderType),
      'tableNumber': serializer.toJson<String?>(tableNumber),
      'itemsJson': serializer.toJson<String>(itemsJson),
      'reprintCount': serializer.toJson<int>(reprintCount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'serverVersion': serializer.toJson<BigInt?>(serverVersion),
      'syncStatus': serializer.toJson<String?>(syncStatus),
    };
  }

  KotRecordEntry copyWith({
    String? id,
    String? invoiceId,
    String? kotNumber,
    String? orderType,
    Value<String?> tableNumber = const Value.absent(),
    String? itemsJson,
    int? reprintCount,
    DateTime? createdAt,
    Value<BigInt?> serverVersion = const Value.absent(),
    Value<String?> syncStatus = const Value.absent(),
  }) => KotRecordEntry(
    id: id ?? this.id,
    invoiceId: invoiceId ?? this.invoiceId,
    kotNumber: kotNumber ?? this.kotNumber,
    orderType: orderType ?? this.orderType,
    tableNumber: tableNumber.present ? tableNumber.value : this.tableNumber,
    itemsJson: itemsJson ?? this.itemsJson,
    reprintCount: reprintCount ?? this.reprintCount,
    createdAt: createdAt ?? this.createdAt,
    serverVersion: serverVersion.present
        ? serverVersion.value
        : this.serverVersion,
    syncStatus: syncStatus.present ? syncStatus.value : this.syncStatus,
  );
  KotRecordEntry copyWithCompanion(KotRecordsCompanion data) {
    return KotRecordEntry(
      id: data.id.present ? data.id.value : this.id,
      invoiceId: data.invoiceId.present ? data.invoiceId.value : this.invoiceId,
      kotNumber: data.kotNumber.present ? data.kotNumber.value : this.kotNumber,
      orderType: data.orderType.present ? data.orderType.value : this.orderType,
      tableNumber: data.tableNumber.present
          ? data.tableNumber.value
          : this.tableNumber,
      itemsJson: data.itemsJson.present ? data.itemsJson.value : this.itemsJson,
      reprintCount: data.reprintCount.present
          ? data.reprintCount.value
          : this.reprintCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      serverVersion: data.serverVersion.present
          ? data.serverVersion.value
          : this.serverVersion,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KotRecordEntry(')
          ..write('id: $id, ')
          ..write('invoiceId: $invoiceId, ')
          ..write('kotNumber: $kotNumber, ')
          ..write('orderType: $orderType, ')
          ..write('tableNumber: $tableNumber, ')
          ..write('itemsJson: $itemsJson, ')
          ..write('reprintCount: $reprintCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    invoiceId,
    kotNumber,
    orderType,
    tableNumber,
    itemsJson,
    reprintCount,
    createdAt,
    serverVersion,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KotRecordEntry &&
          other.id == this.id &&
          other.invoiceId == this.invoiceId &&
          other.kotNumber == this.kotNumber &&
          other.orderType == this.orderType &&
          other.tableNumber == this.tableNumber &&
          other.itemsJson == this.itemsJson &&
          other.reprintCount == this.reprintCount &&
          other.createdAt == this.createdAt &&
          other.serverVersion == this.serverVersion &&
          other.syncStatus == this.syncStatus);
}

class KotRecordsCompanion extends UpdateCompanion<KotRecordEntry> {
  final Value<String> id;
  final Value<String> invoiceId;
  final Value<String> kotNumber;
  final Value<String> orderType;
  final Value<String?> tableNumber;
  final Value<String> itemsJson;
  final Value<int> reprintCount;
  final Value<DateTime> createdAt;
  final Value<BigInt?> serverVersion;
  final Value<String?> syncStatus;
  final Value<int> rowid;
  const KotRecordsCompanion({
    this.id = const Value.absent(),
    this.invoiceId = const Value.absent(),
    this.kotNumber = const Value.absent(),
    this.orderType = const Value.absent(),
    this.tableNumber = const Value.absent(),
    this.itemsJson = const Value.absent(),
    this.reprintCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KotRecordsCompanion.insert({
    required String id,
    required String invoiceId,
    required String kotNumber,
    required String orderType,
    this.tableNumber = const Value.absent(),
    required String itemsJson,
    this.reprintCount = const Value.absent(),
    required DateTime createdAt,
    this.serverVersion = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       invoiceId = Value(invoiceId),
       kotNumber = Value(kotNumber),
       orderType = Value(orderType),
       itemsJson = Value(itemsJson),
       createdAt = Value(createdAt);
  static Insertable<KotRecordEntry> custom({
    Expression<String>? id,
    Expression<String>? invoiceId,
    Expression<String>? kotNumber,
    Expression<String>? orderType,
    Expression<String>? tableNumber,
    Expression<String>? itemsJson,
    Expression<int>? reprintCount,
    Expression<DateTime>? createdAt,
    Expression<BigInt>? serverVersion,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (invoiceId != null) 'invoice_id': invoiceId,
      if (kotNumber != null) 'kot_number': kotNumber,
      if (orderType != null) 'order_type': orderType,
      if (tableNumber != null) 'table_number': tableNumber,
      if (itemsJson != null) 'items_json': itemsJson,
      if (reprintCount != null) 'reprint_count': reprintCount,
      if (createdAt != null) 'created_at': createdAt,
      if (serverVersion != null) 'server_version': serverVersion,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KotRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? invoiceId,
    Value<String>? kotNumber,
    Value<String>? orderType,
    Value<String?>? tableNumber,
    Value<String>? itemsJson,
    Value<int>? reprintCount,
    Value<DateTime>? createdAt,
    Value<BigInt?>? serverVersion,
    Value<String?>? syncStatus,
    Value<int>? rowid,
  }) {
    return KotRecordsCompanion(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      kotNumber: kotNumber ?? this.kotNumber,
      orderType: orderType ?? this.orderType,
      tableNumber: tableNumber ?? this.tableNumber,
      itemsJson: itemsJson ?? this.itemsJson,
      reprintCount: reprintCount ?? this.reprintCount,
      createdAt: createdAt ?? this.createdAt,
      serverVersion: serverVersion ?? this.serverVersion,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (invoiceId.present) {
      map['invoice_id'] = Variable<String>(invoiceId.value);
    }
    if (kotNumber.present) {
      map['kot_number'] = Variable<String>(kotNumber.value);
    }
    if (orderType.present) {
      map['order_type'] = Variable<String>(orderType.value);
    }
    if (tableNumber.present) {
      map['table_number'] = Variable<String>(tableNumber.value);
    }
    if (itemsJson.present) {
      map['items_json'] = Variable<String>(itemsJson.value);
    }
    if (reprintCount.present) {
      map['reprint_count'] = Variable<int>(reprintCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (serverVersion.present) {
      map['server_version'] = Variable<BigInt>(serverVersion.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KotRecordsCompanion(')
          ..write('id: $id, ')
          ..write('invoiceId: $invoiceId, ')
          ..write('kotNumber: $kotNumber, ')
          ..write('orderType: $orderType, ')
          ..write('tableNumber: $tableNumber, ')
          ..write('itemsJson: $itemsJson, ')
          ..write('reprintCount: $reprintCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncCursorsTable extends SyncCursors
    with TableInfo<$SyncCursorsTable, SyncCursorEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncCursorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _syncEntityMeta = const VerificationMeta(
    'syncEntity',
  );
  @override
  late final GeneratedColumn<String> syncEntity = GeneratedColumn<String>(
    'sync_entity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastServerCursorMeta = const VerificationMeta(
    'lastServerCursor',
  );
  @override
  late final GeneratedColumn<BigInt> lastServerCursor = GeneratedColumn<BigInt>(
    'last_server_cursor',
    aliasedName,
    true,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncAtMeta = const VerificationMeta(
    'lastSyncAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncAt = GeneratedColumn<DateTime>(
    'last_sync_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('idle'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    syncEntity,
    businessId,
    lastServerCursor,
    lastSyncAt,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_cursors';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncCursorEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('sync_entity')) {
      context.handle(
        _syncEntityMeta,
        syncEntity.isAcceptableOrUnknown(data['sync_entity']!, _syncEntityMeta),
      );
    } else if (isInserting) {
      context.missing(_syncEntityMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('last_server_cursor')) {
      context.handle(
        _lastServerCursorMeta,
        lastServerCursor.isAcceptableOrUnknown(
          data['last_server_cursor']!,
          _lastServerCursorMeta,
        ),
      );
    }
    if (data.containsKey('last_sync_at')) {
      context.handle(
        _lastSyncAtMeta,
        lastSyncAt.isAcceptableOrUnknown(
          data['last_sync_at']!,
          _lastSyncAtMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {syncEntity, businessId};
  @override
  SyncCursorEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncCursorEntry(
      syncEntity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_entity'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      lastServerCursor: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}last_server_cursor'],
      ),
      lastSyncAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_sync_at'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $SyncCursorsTable createAlias(String alias) {
    return $SyncCursorsTable(attachedDatabase, alias);
  }
}

class SyncCursorEntry extends DataClass implements Insertable<SyncCursorEntry> {
  final String syncEntity;
  final String businessId;
  final BigInt? lastServerCursor;
  final DateTime? lastSyncAt;
  final String status;
  const SyncCursorEntry({
    required this.syncEntity,
    required this.businessId,
    this.lastServerCursor,
    this.lastSyncAt,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['sync_entity'] = Variable<String>(syncEntity);
    map['business_id'] = Variable<String>(businessId);
    if (!nullToAbsent || lastServerCursor != null) {
      map['last_server_cursor'] = Variable<BigInt>(lastServerCursor);
    }
    if (!nullToAbsent || lastSyncAt != null) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt);
    }
    map['status'] = Variable<String>(status);
    return map;
  }

  SyncCursorsCompanion toCompanion(bool nullToAbsent) {
    return SyncCursorsCompanion(
      syncEntity: Value(syncEntity),
      businessId: Value(businessId),
      lastServerCursor: lastServerCursor == null && nullToAbsent
          ? const Value.absent()
          : Value(lastServerCursor),
      lastSyncAt: lastSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAt),
      status: Value(status),
    );
  }

  factory SyncCursorEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncCursorEntry(
      syncEntity: serializer.fromJson<String>(json['syncEntity']),
      businessId: serializer.fromJson<String>(json['businessId']),
      lastServerCursor: serializer.fromJson<BigInt?>(json['lastServerCursor']),
      lastSyncAt: serializer.fromJson<DateTime?>(json['lastSyncAt']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'syncEntity': serializer.toJson<String>(syncEntity),
      'businessId': serializer.toJson<String>(businessId),
      'lastServerCursor': serializer.toJson<BigInt?>(lastServerCursor),
      'lastSyncAt': serializer.toJson<DateTime?>(lastSyncAt),
      'status': serializer.toJson<String>(status),
    };
  }

  SyncCursorEntry copyWith({
    String? syncEntity,
    String? businessId,
    Value<BigInt?> lastServerCursor = const Value.absent(),
    Value<DateTime?> lastSyncAt = const Value.absent(),
    String? status,
  }) => SyncCursorEntry(
    syncEntity: syncEntity ?? this.syncEntity,
    businessId: businessId ?? this.businessId,
    lastServerCursor: lastServerCursor.present
        ? lastServerCursor.value
        : this.lastServerCursor,
    lastSyncAt: lastSyncAt.present ? lastSyncAt.value : this.lastSyncAt,
    status: status ?? this.status,
  );
  SyncCursorEntry copyWithCompanion(SyncCursorsCompanion data) {
    return SyncCursorEntry(
      syncEntity: data.syncEntity.present
          ? data.syncEntity.value
          : this.syncEntity,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      lastServerCursor: data.lastServerCursor.present
          ? data.lastServerCursor.value
          : this.lastServerCursor,
      lastSyncAt: data.lastSyncAt.present
          ? data.lastSyncAt.value
          : this.lastSyncAt,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncCursorEntry(')
          ..write('syncEntity: $syncEntity, ')
          ..write('businessId: $businessId, ')
          ..write('lastServerCursor: $lastServerCursor, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(syncEntity, businessId, lastServerCursor, lastSyncAt, status);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncCursorEntry &&
          other.syncEntity == this.syncEntity &&
          other.businessId == this.businessId &&
          other.lastServerCursor == this.lastServerCursor &&
          other.lastSyncAt == this.lastSyncAt &&
          other.status == this.status);
}

class SyncCursorsCompanion extends UpdateCompanion<SyncCursorEntry> {
  final Value<String> syncEntity;
  final Value<String> businessId;
  final Value<BigInt?> lastServerCursor;
  final Value<DateTime?> lastSyncAt;
  final Value<String> status;
  final Value<int> rowid;
  const SyncCursorsCompanion({
    this.syncEntity = const Value.absent(),
    this.businessId = const Value.absent(),
    this.lastServerCursor = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncCursorsCompanion.insert({
    required String syncEntity,
    required String businessId,
    this.lastServerCursor = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : syncEntity = Value(syncEntity),
       businessId = Value(businessId);
  static Insertable<SyncCursorEntry> custom({
    Expression<String>? syncEntity,
    Expression<String>? businessId,
    Expression<BigInt>? lastServerCursor,
    Expression<DateTime>? lastSyncAt,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (syncEntity != null) 'sync_entity': syncEntity,
      if (businessId != null) 'business_id': businessId,
      if (lastServerCursor != null) 'last_server_cursor': lastServerCursor,
      if (lastSyncAt != null) 'last_sync_at': lastSyncAt,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncCursorsCompanion copyWith({
    Value<String>? syncEntity,
    Value<String>? businessId,
    Value<BigInt?>? lastServerCursor,
    Value<DateTime?>? lastSyncAt,
    Value<String>? status,
    Value<int>? rowid,
  }) {
    return SyncCursorsCompanion(
      syncEntity: syncEntity ?? this.syncEntity,
      businessId: businessId ?? this.businessId,
      lastServerCursor: lastServerCursor ?? this.lastServerCursor,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (syncEntity.present) {
      map['sync_entity'] = Variable<String>(syncEntity.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (lastServerCursor.present) {
      map['last_server_cursor'] = Variable<BigInt>(lastServerCursor.value);
    }
    if (lastSyncAt.present) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncCursorsCompanion(')
          ..write('syncEntity: $syncEntity, ')
          ..write('businessId: $businessId, ')
          ..write('lastServerCursor: $lastServerCursor, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncQueueEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncEntityMeta = const VerificationMeta(
    'syncEntity',
  );
  @override
  late final GeneratedColumn<String> syncEntity = GeneratedColumn<String>(
    'sync_entity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordIdMeta = const VerificationMeta(
    'recordId',
  );
  @override
  late final GeneratedColumn<String> recordId = GeneratedColumn<String>(
    'record_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationMeta = const VerificationMeta(
    'operation',
  );
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
    'operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientVersionMeta = const VerificationMeta(
    'clientVersion',
  );
  @override
  late final GeneratedColumn<BigInt> clientVersion = GeneratedColumn<BigInt>(
    'client_version',
    aliasedName,
    true,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    deviceId,
    syncEntity,
    recordId,
    operation,
    clientVersion,
    payloadJson,
    idempotencyKey,
    createdAt,
    retryCount,
    lastError,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQueueEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('sync_entity')) {
      context.handle(
        _syncEntityMeta,
        syncEntity.isAcceptableOrUnknown(data['sync_entity']!, _syncEntityMeta),
      );
    } else if (isInserting) {
      context.missing(_syncEntityMeta);
    }
    if (data.containsKey('record_id')) {
      context.handle(
        _recordIdMeta,
        recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(
        _operationMeta,
        operation.isAcceptableOrUnknown(data['operation']!, _operationMeta),
      );
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('client_version')) {
      context.handle(
        _clientVersionMeta,
        clientVersion.isAcceptableOrUnknown(
          data['client_version']!,
          _clientVersionMeta,
        ),
      );
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
        _idempotencyKeyMeta,
        idempotencyKey.isAcceptableOrUnknown(
          data['idempotency_key']!,
          _idempotencyKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_idempotencyKeyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      syncEntity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_entity'],
      )!,
      recordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_id'],
      )!,
      operation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation'],
      )!,
      clientVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}client_version'],
      ),
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class SyncQueueEntry extends DataClass implements Insertable<SyncQueueEntry> {
  final String id;
  final String businessId;
  final String deviceId;
  final String syncEntity;
  final String recordId;
  final String operation;
  final BigInt? clientVersion;
  final String payloadJson;
  final String idempotencyKey;
  final DateTime createdAt;
  final int retryCount;
  final String? lastError;
  final String status;
  const SyncQueueEntry({
    required this.id,
    required this.businessId,
    required this.deviceId,
    required this.syncEntity,
    required this.recordId,
    required this.operation,
    this.clientVersion,
    required this.payloadJson,
    required this.idempotencyKey,
    required this.createdAt,
    required this.retryCount,
    this.lastError,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['business_id'] = Variable<String>(businessId);
    map['device_id'] = Variable<String>(deviceId);
    map['sync_entity'] = Variable<String>(syncEntity);
    map['record_id'] = Variable<String>(recordId);
    map['operation'] = Variable<String>(operation);
    if (!nullToAbsent || clientVersion != null) {
      map['client_version'] = Variable<BigInt>(clientVersion);
    }
    map['payload_json'] = Variable<String>(payloadJson);
    map['idempotency_key'] = Variable<String>(idempotencyKey);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['status'] = Variable<String>(status);
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      id: Value(id),
      businessId: Value(businessId),
      deviceId: Value(deviceId),
      syncEntity: Value(syncEntity),
      recordId: Value(recordId),
      operation: Value(operation),
      clientVersion: clientVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(clientVersion),
      payloadJson: Value(payloadJson),
      idempotencyKey: Value(idempotencyKey),
      createdAt: Value(createdAt),
      retryCount: Value(retryCount),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      status: Value(status),
    );
  }

  factory SyncQueueEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueEntry(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String>(json['businessId']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      syncEntity: serializer.fromJson<String>(json['syncEntity']),
      recordId: serializer.fromJson<String>(json['recordId']),
      operation: serializer.fromJson<String>(json['operation']),
      clientVersion: serializer.fromJson<BigInt?>(json['clientVersion']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      idempotencyKey: serializer.fromJson<String>(json['idempotencyKey']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessId': serializer.toJson<String>(businessId),
      'deviceId': serializer.toJson<String>(deviceId),
      'syncEntity': serializer.toJson<String>(syncEntity),
      'recordId': serializer.toJson<String>(recordId),
      'operation': serializer.toJson<String>(operation),
      'clientVersion': serializer.toJson<BigInt?>(clientVersion),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'idempotencyKey': serializer.toJson<String>(idempotencyKey),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'retryCount': serializer.toJson<int>(retryCount),
      'lastError': serializer.toJson<String?>(lastError),
      'status': serializer.toJson<String>(status),
    };
  }

  SyncQueueEntry copyWith({
    String? id,
    String? businessId,
    String? deviceId,
    String? syncEntity,
    String? recordId,
    String? operation,
    Value<BigInt?> clientVersion = const Value.absent(),
    String? payloadJson,
    String? idempotencyKey,
    DateTime? createdAt,
    int? retryCount,
    Value<String?> lastError = const Value.absent(),
    String? status,
  }) => SyncQueueEntry(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    deviceId: deviceId ?? this.deviceId,
    syncEntity: syncEntity ?? this.syncEntity,
    recordId: recordId ?? this.recordId,
    operation: operation ?? this.operation,
    clientVersion: clientVersion.present
        ? clientVersion.value
        : this.clientVersion,
    payloadJson: payloadJson ?? this.payloadJson,
    idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    createdAt: createdAt ?? this.createdAt,
    retryCount: retryCount ?? this.retryCount,
    lastError: lastError.present ? lastError.value : this.lastError,
    status: status ?? this.status,
  );
  SyncQueueEntry copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueEntry(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      syncEntity: data.syncEntity.present
          ? data.syncEntity.value
          : this.syncEntity,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      operation: data.operation.present ? data.operation.value : this.operation,
      clientVersion: data.clientVersion.present
          ? data.clientVersion.value
          : this.clientVersion,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueEntry(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('deviceId: $deviceId, ')
          ..write('syncEntity: $syncEntity, ')
          ..write('recordId: $recordId, ')
          ..write('operation: $operation, ')
          ..write('clientVersion: $clientVersion, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastError: $lastError, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    businessId,
    deviceId,
    syncEntity,
    recordId,
    operation,
    clientVersion,
    payloadJson,
    idempotencyKey,
    createdAt,
    retryCount,
    lastError,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueEntry &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.deviceId == this.deviceId &&
          other.syncEntity == this.syncEntity &&
          other.recordId == this.recordId &&
          other.operation == this.operation &&
          other.clientVersion == this.clientVersion &&
          other.payloadJson == this.payloadJson &&
          other.idempotencyKey == this.idempotencyKey &&
          other.createdAt == this.createdAt &&
          other.retryCount == this.retryCount &&
          other.lastError == this.lastError &&
          other.status == this.status);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueEntry> {
  final Value<String> id;
  final Value<String> businessId;
  final Value<String> deviceId;
  final Value<String> syncEntity;
  final Value<String> recordId;
  final Value<String> operation;
  final Value<BigInt?> clientVersion;
  final Value<String> payloadJson;
  final Value<String> idempotencyKey;
  final Value<DateTime> createdAt;
  final Value<int> retryCount;
  final Value<String?> lastError;
  final Value<String> status;
  final Value<int> rowid;
  const SyncQueueCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.syncEntity = const Value.absent(),
    this.recordId = const Value.absent(),
    this.operation = const Value.absent(),
    this.clientVersion = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    required String id,
    required String businessId,
    required String deviceId,
    required String syncEntity,
    required String recordId,
    required String operation,
    this.clientVersion = const Value.absent(),
    required String payloadJson,
    required String idempotencyKey,
    required DateTime createdAt,
    this.retryCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       businessId = Value(businessId),
       deviceId = Value(deviceId),
       syncEntity = Value(syncEntity),
       recordId = Value(recordId),
       operation = Value(operation),
       payloadJson = Value(payloadJson),
       idempotencyKey = Value(idempotencyKey),
       createdAt = Value(createdAt);
  static Insertable<SyncQueueEntry> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? deviceId,
    Expression<String>? syncEntity,
    Expression<String>? recordId,
    Expression<String>? operation,
    Expression<BigInt>? clientVersion,
    Expression<String>? payloadJson,
    Expression<String>? idempotencyKey,
    Expression<DateTime>? createdAt,
    Expression<int>? retryCount,
    Expression<String>? lastError,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (deviceId != null) 'device_id': deviceId,
      if (syncEntity != null) 'sync_entity': syncEntity,
      if (recordId != null) 'record_id': recordId,
      if (operation != null) 'operation': operation,
      if (clientVersion != null) 'client_version': clientVersion,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (createdAt != null) 'created_at': createdAt,
      if (retryCount != null) 'retry_count': retryCount,
      if (lastError != null) 'last_error': lastError,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncQueueCompanion copyWith({
    Value<String>? id,
    Value<String>? businessId,
    Value<String>? deviceId,
    Value<String>? syncEntity,
    Value<String>? recordId,
    Value<String>? operation,
    Value<BigInt?>? clientVersion,
    Value<String>? payloadJson,
    Value<String>? idempotencyKey,
    Value<DateTime>? createdAt,
    Value<int>? retryCount,
    Value<String?>? lastError,
    Value<String>? status,
    Value<int>? rowid,
  }) {
    return SyncQueueCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      deviceId: deviceId ?? this.deviceId,
      syncEntity: syncEntity ?? this.syncEntity,
      recordId: recordId ?? this.recordId,
      operation: operation ?? this.operation,
      clientVersion: clientVersion ?? this.clientVersion,
      payloadJson: payloadJson ?? this.payloadJson,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (syncEntity.present) {
      map['sync_entity'] = Variable<String>(syncEntity.value);
    }
    if (recordId.present) {
      map['record_id'] = Variable<String>(recordId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (clientVersion.present) {
      map['client_version'] = Variable<BigInt>(clientVersion.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('deviceId: $deviceId, ')
          ..write('syncEntity: $syncEntity, ')
          ..write('recordId: $recordId, ')
          ..write('operation: $operation, ')
          ..write('clientVersion: $clientVersion, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastError: $lastError, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncConflictsTable extends SyncConflicts
    with TableInfo<$SyncConflictsTable, SyncConflictEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncConflictsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncEntityMeta = const VerificationMeta(
    'syncEntity',
  );
  @override
  late final GeneratedColumn<String> syncEntity = GeneratedColumn<String>(
    'sync_entity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordIdMeta = const VerificationMeta(
    'recordId',
  );
  @override
  late final GeneratedColumn<String> recordId = GeneratedColumn<String>(
    'record_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientPayloadJsonMeta = const VerificationMeta(
    'clientPayloadJson',
  );
  @override
  late final GeneratedColumn<String> clientPayloadJson =
      GeneratedColumn<String>(
        'client_payload_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _serverPayloadJsonMeta = const VerificationMeta(
    'serverPayloadJson',
  );
  @override
  late final GeneratedColumn<String> serverPayloadJson =
      GeneratedColumn<String>(
        'server_payload_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _resolutionMeta = const VerificationMeta(
    'resolution',
  );
  @override
  late final GeneratedColumn<String> resolution = GeneratedColumn<String>(
    'resolution',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('SERVER_WINS'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    syncEntity,
    recordId,
    clientPayloadJson,
    serverPayloadJson,
    resolution,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_conflicts';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncConflictEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sync_entity')) {
      context.handle(
        _syncEntityMeta,
        syncEntity.isAcceptableOrUnknown(data['sync_entity']!, _syncEntityMeta),
      );
    } else if (isInserting) {
      context.missing(_syncEntityMeta);
    }
    if (data.containsKey('record_id')) {
      context.handle(
        _recordIdMeta,
        recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    if (data.containsKey('client_payload_json')) {
      context.handle(
        _clientPayloadJsonMeta,
        clientPayloadJson.isAcceptableOrUnknown(
          data['client_payload_json']!,
          _clientPayloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientPayloadJsonMeta);
    }
    if (data.containsKey('server_payload_json')) {
      context.handle(
        _serverPayloadJsonMeta,
        serverPayloadJson.isAcceptableOrUnknown(
          data['server_payload_json']!,
          _serverPayloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_serverPayloadJsonMeta);
    }
    if (data.containsKey('resolution')) {
      context.handle(
        _resolutionMeta,
        resolution.isAcceptableOrUnknown(data['resolution']!, _resolutionMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncConflictEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncConflictEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      syncEntity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_entity'],
      )!,
      recordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_id'],
      )!,
      clientPayloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_payload_json'],
      )!,
      serverPayloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_payload_json'],
      )!,
      resolution: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resolution'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SyncConflictsTable createAlias(String alias) {
    return $SyncConflictsTable(attachedDatabase, alias);
  }
}

class SyncConflictEntry extends DataClass
    implements Insertable<SyncConflictEntry> {
  final String id;
  final String syncEntity;
  final String recordId;
  final String clientPayloadJson;
  final String serverPayloadJson;
  final String resolution;
  final DateTime createdAt;
  const SyncConflictEntry({
    required this.id,
    required this.syncEntity,
    required this.recordId,
    required this.clientPayloadJson,
    required this.serverPayloadJson,
    required this.resolution,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['sync_entity'] = Variable<String>(syncEntity);
    map['record_id'] = Variable<String>(recordId);
    map['client_payload_json'] = Variable<String>(clientPayloadJson);
    map['server_payload_json'] = Variable<String>(serverPayloadJson);
    map['resolution'] = Variable<String>(resolution);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SyncConflictsCompanion toCompanion(bool nullToAbsent) {
    return SyncConflictsCompanion(
      id: Value(id),
      syncEntity: Value(syncEntity),
      recordId: Value(recordId),
      clientPayloadJson: Value(clientPayloadJson),
      serverPayloadJson: Value(serverPayloadJson),
      resolution: Value(resolution),
      createdAt: Value(createdAt),
    );
  }

  factory SyncConflictEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncConflictEntry(
      id: serializer.fromJson<String>(json['id']),
      syncEntity: serializer.fromJson<String>(json['syncEntity']),
      recordId: serializer.fromJson<String>(json['recordId']),
      clientPayloadJson: serializer.fromJson<String>(json['clientPayloadJson']),
      serverPayloadJson: serializer.fromJson<String>(json['serverPayloadJson']),
      resolution: serializer.fromJson<String>(json['resolution']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'syncEntity': serializer.toJson<String>(syncEntity),
      'recordId': serializer.toJson<String>(recordId),
      'clientPayloadJson': serializer.toJson<String>(clientPayloadJson),
      'serverPayloadJson': serializer.toJson<String>(serverPayloadJson),
      'resolution': serializer.toJson<String>(resolution),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SyncConflictEntry copyWith({
    String? id,
    String? syncEntity,
    String? recordId,
    String? clientPayloadJson,
    String? serverPayloadJson,
    String? resolution,
    DateTime? createdAt,
  }) => SyncConflictEntry(
    id: id ?? this.id,
    syncEntity: syncEntity ?? this.syncEntity,
    recordId: recordId ?? this.recordId,
    clientPayloadJson: clientPayloadJson ?? this.clientPayloadJson,
    serverPayloadJson: serverPayloadJson ?? this.serverPayloadJson,
    resolution: resolution ?? this.resolution,
    createdAt: createdAt ?? this.createdAt,
  );
  SyncConflictEntry copyWithCompanion(SyncConflictsCompanion data) {
    return SyncConflictEntry(
      id: data.id.present ? data.id.value : this.id,
      syncEntity: data.syncEntity.present
          ? data.syncEntity.value
          : this.syncEntity,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      clientPayloadJson: data.clientPayloadJson.present
          ? data.clientPayloadJson.value
          : this.clientPayloadJson,
      serverPayloadJson: data.serverPayloadJson.present
          ? data.serverPayloadJson.value
          : this.serverPayloadJson,
      resolution: data.resolution.present
          ? data.resolution.value
          : this.resolution,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncConflictEntry(')
          ..write('id: $id, ')
          ..write('syncEntity: $syncEntity, ')
          ..write('recordId: $recordId, ')
          ..write('clientPayloadJson: $clientPayloadJson, ')
          ..write('serverPayloadJson: $serverPayloadJson, ')
          ..write('resolution: $resolution, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    syncEntity,
    recordId,
    clientPayloadJson,
    serverPayloadJson,
    resolution,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncConflictEntry &&
          other.id == this.id &&
          other.syncEntity == this.syncEntity &&
          other.recordId == this.recordId &&
          other.clientPayloadJson == this.clientPayloadJson &&
          other.serverPayloadJson == this.serverPayloadJson &&
          other.resolution == this.resolution &&
          other.createdAt == this.createdAt);
}

class SyncConflictsCompanion extends UpdateCompanion<SyncConflictEntry> {
  final Value<String> id;
  final Value<String> syncEntity;
  final Value<String> recordId;
  final Value<String> clientPayloadJson;
  final Value<String> serverPayloadJson;
  final Value<String> resolution;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const SyncConflictsCompanion({
    this.id = const Value.absent(),
    this.syncEntity = const Value.absent(),
    this.recordId = const Value.absent(),
    this.clientPayloadJson = const Value.absent(),
    this.serverPayloadJson = const Value.absent(),
    this.resolution = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncConflictsCompanion.insert({
    required String id,
    required String syncEntity,
    required String recordId,
    required String clientPayloadJson,
    required String serverPayloadJson,
    this.resolution = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       syncEntity = Value(syncEntity),
       recordId = Value(recordId),
       clientPayloadJson = Value(clientPayloadJson),
       serverPayloadJson = Value(serverPayloadJson),
       createdAt = Value(createdAt);
  static Insertable<SyncConflictEntry> custom({
    Expression<String>? id,
    Expression<String>? syncEntity,
    Expression<String>? recordId,
    Expression<String>? clientPayloadJson,
    Expression<String>? serverPayloadJson,
    Expression<String>? resolution,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (syncEntity != null) 'sync_entity': syncEntity,
      if (recordId != null) 'record_id': recordId,
      if (clientPayloadJson != null) 'client_payload_json': clientPayloadJson,
      if (serverPayloadJson != null) 'server_payload_json': serverPayloadJson,
      if (resolution != null) 'resolution': resolution,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncConflictsCompanion copyWith({
    Value<String>? id,
    Value<String>? syncEntity,
    Value<String>? recordId,
    Value<String>? clientPayloadJson,
    Value<String>? serverPayloadJson,
    Value<String>? resolution,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return SyncConflictsCompanion(
      id: id ?? this.id,
      syncEntity: syncEntity ?? this.syncEntity,
      recordId: recordId ?? this.recordId,
      clientPayloadJson: clientPayloadJson ?? this.clientPayloadJson,
      serverPayloadJson: serverPayloadJson ?? this.serverPayloadJson,
      resolution: resolution ?? this.resolution,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (syncEntity.present) {
      map['sync_entity'] = Variable<String>(syncEntity.value);
    }
    if (recordId.present) {
      map['record_id'] = Variable<String>(recordId.value);
    }
    if (clientPayloadJson.present) {
      map['client_payload_json'] = Variable<String>(clientPayloadJson.value);
    }
    if (serverPayloadJson.present) {
      map['server_payload_json'] = Variable<String>(serverPayloadJson.value);
    }
    if (resolution.present) {
      map['resolution'] = Variable<String>(resolution.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncConflictsCompanion(')
          ..write('id: $id, ')
          ..write('syncEntity: $syncEntity, ')
          ..write('recordId: $recordId, ')
          ..write('clientPayloadJson: $clientPayloadJson, ')
          ..write('serverPayloadJson: $serverPayloadJson, ')
          ..write('resolution: $resolution, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $ProductsTable products = $ProductsTable(this);
  late final $InvoicesTable invoices = $InvoicesTable(this);
  late final $InvoiceItemsTable invoiceItems = $InvoiceItemsTable(this);
  late final $BillNotesTable billNotes = $BillNotesTable(this);
  late final $PaymentsTable payments = $PaymentsTable(this);
  late final $CustomersTable customers = $CustomersTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $ProductImagesTable productImages = $ProductImagesTable(this);
  late final $UsersTable users = $UsersTable(this);
  late final $DiningTablesTable diningTables = $DiningTablesTable(this);
  late final $KotRecordsTable kotRecords = $KotRecordsTable(this);
  late final $SyncCursorsTable syncCursors = $SyncCursorsTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  late final $SyncConflictsTable syncConflicts = $SyncConflictsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    categories,
    products,
    invoices,
    invoiceItems,
    billNotes,
    payments,
    customers,
    appSettings,
    productImages,
    users,
    diningTables,
    kotRecords,
    syncCursors,
    syncQueue,
    syncConflicts,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'products',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('product_images', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$CategoriesTableCreateCompanionBuilder =
    CategoriesCompanion Function({
      required String id,
      Value<String?> businessId,
      required String name,
      Value<String?> icon,
      Value<int?> colorValue,
      Value<bool> isActive,
      Value<int> displayOrder,
      Value<BigInt?> serverVersion,
      required DateTime createdAt,
      Value<DateTime?> deletedAt,
      Value<String?> syncStatus,
      Value<int> rowid,
    });
typedef $$CategoriesTableUpdateCompanionBuilder =
    CategoriesCompanion Function({
      Value<String> id,
      Value<String?> businessId,
      Value<String> name,
      Value<String?> icon,
      Value<int?> colorValue,
      Value<bool> isActive,
      Value<int> displayOrder,
      Value<BigInt?> serverVersion,
      Value<DateTime> createdAt,
      Value<DateTime?> deletedAt,
      Value<String?> syncStatus,
      Value<int> rowid,
    });

final class $$CategoriesTableReferences
    extends BaseReferences<_$AppDatabase, $CategoriesTable, CategoryEntry> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ProductsTable, List<ProductEntry>>
  _productsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.products,
    aliasName: $_aliasNameGenerator(db.categories.id, db.products.categoryId),
  );

  $$ProductsTableProcessedTableManager get productsRefs {
    final manager = $$ProductsTableTableManager(
      $_db,
      $_db.products,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_productsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> productsRefs(
    Expression<bool> Function($$ProductsTableFilterComposer f) f,
  ) {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableFilterComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => column,
  );

  GeneratedColumn<BigInt> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  Expression<T> productsRefs<T extends Object>(
    Expression<T> Function($$ProductsTableAnnotationComposer a) f,
  ) {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableAnnotationComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          CategoryEntry,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (CategoryEntry, $$CategoriesTableReferences),
          CategoryEntry,
          PrefetchHooks Function({bool productsRefs})
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> businessId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<int?> colorValue = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> displayOrder = const Value.absent(),
                Value<BigInt?> serverVersion = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                businessId: businessId,
                name: name,
                icon: icon,
                colorValue: colorValue,
                isActive: isActive,
                displayOrder: displayOrder,
                serverVersion: serverVersion,
                createdAt: createdAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> businessId = const Value.absent(),
                required String name,
                Value<String?> icon = const Value.absent(),
                Value<int?> colorValue = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> displayOrder = const Value.absent(),
                Value<BigInt?> serverVersion = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                businessId: businessId,
                name: name,
                icon: icon,
                colorValue: colorValue,
                isActive: isActive,
                displayOrder: displayOrder,
                serverVersion: serverVersion,
                createdAt: createdAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({productsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (productsRefs) db.products],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (productsRefs)
                    await $_getPrefetchedData<
                      CategoryEntry,
                      $CategoriesTable,
                      ProductEntry
                    >(
                      currentTable: table,
                      referencedTable: $$CategoriesTableReferences
                          ._productsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CategoriesTableReferences(
                            db,
                            table,
                            p0,
                          ).productsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.categoryId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      CategoryEntry,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (CategoryEntry, $$CategoriesTableReferences),
      CategoryEntry,
      PrefetchHooks Function({bool productsRefs})
    >;
typedef $$ProductsTableCreateCompanionBuilder =
    ProductsCompanion Function({
      required String id,
      Value<String?> businessId,
      required String name,
      Value<String?> code,
      Value<String?> categoryId,
      Value<String?> description,
      Value<int> costPricePaise,
      required int sellingPricePaise,
      Value<double> gstRatePercent,
      Value<bool> isTaxInclusive,
      Value<String> unit,
      Value<bool> isAvailable,
      Value<String?> imagePath,
      Value<BigInt?> serverVersion,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<String?> syncStatus,
      Value<int> rowid,
    });
typedef $$ProductsTableUpdateCompanionBuilder =
    ProductsCompanion Function({
      Value<String> id,
      Value<String?> businessId,
      Value<String> name,
      Value<String?> code,
      Value<String?> categoryId,
      Value<String?> description,
      Value<int> costPricePaise,
      Value<int> sellingPricePaise,
      Value<double> gstRatePercent,
      Value<bool> isTaxInclusive,
      Value<String> unit,
      Value<bool> isAvailable,
      Value<String?> imagePath,
      Value<BigInt?> serverVersion,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String?> syncStatus,
      Value<int> rowid,
    });

final class $$ProductsTableReferences
    extends BaseReferences<_$AppDatabase, $ProductsTable, ProductEntry> {
  $$ProductsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias(
        $_aliasNameGenerator(db.products.categoryId, db.categories.id),
      );

  $$CategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<String>('category_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ProductImagesTable, List<ProductImageEntry>>
  _productImagesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.productImages,
    aliasName: $_aliasNameGenerator(db.products.id, db.productImages.productId),
  );

  $$ProductImagesTableProcessedTableManager get productImagesRefs {
    final manager = $$ProductImagesTableTableManager(
      $_db,
      $_db.productImages,
    ).filter((f) => f.productId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_productImagesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProductsTableFilterComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get costPricePaise => $composableBuilder(
    column: $table.costPricePaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sellingPricePaise => $composableBuilder(
    column: $table.sellingPricePaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get gstRatePercent => $composableBuilder(
    column: $table.gstRatePercent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isTaxInclusive => $composableBuilder(
    column: $table.isTaxInclusive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAvailable => $composableBuilder(
    column: $table.isAvailable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> productImagesRefs(
    Expression<bool> Function($$ProductImagesTableFilterComposer f) f,
  ) {
    final $$ProductImagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.productImages,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductImagesTableFilterComposer(
            $db: $db,
            $table: $db.productImages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProductsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get costPricePaise => $composableBuilder(
    column: $table.costPricePaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sellingPricePaise => $composableBuilder(
    column: $table.sellingPricePaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get gstRatePercent => $composableBuilder(
    column: $table.gstRatePercent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isTaxInclusive => $composableBuilder(
    column: $table.isTaxInclusive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAvailable => $composableBuilder(
    column: $table.isAvailable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProductsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get costPricePaise => $composableBuilder(
    column: $table.costPricePaise,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sellingPricePaise => $composableBuilder(
    column: $table.sellingPricePaise,
    builder: (column) => column,
  );

  GeneratedColumn<double> get gstRatePercent => $composableBuilder(
    column: $table.gstRatePercent,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isTaxInclusive => $composableBuilder(
    column: $table.isTaxInclusive,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<bool> get isAvailable => $composableBuilder(
    column: $table.isAvailable,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<BigInt> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> productImagesRefs<T extends Object>(
    Expression<T> Function($$ProductImagesTableAnnotationComposer a) f,
  ) {
    final $$ProductImagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.productImages,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductImagesTableAnnotationComposer(
            $db: $db,
            $table: $db.productImages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProductsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductsTable,
          ProductEntry,
          $$ProductsTableFilterComposer,
          $$ProductsTableOrderingComposer,
          $$ProductsTableAnnotationComposer,
          $$ProductsTableCreateCompanionBuilder,
          $$ProductsTableUpdateCompanionBuilder,
          (ProductEntry, $$ProductsTableReferences),
          ProductEntry,
          PrefetchHooks Function({bool categoryId, bool productImagesRefs})
        > {
  $$ProductsTableTableManager(_$AppDatabase db, $ProductsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> businessId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> code = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int> costPricePaise = const Value.absent(),
                Value<int> sellingPricePaise = const Value.absent(),
                Value<double> gstRatePercent = const Value.absent(),
                Value<bool> isTaxInclusive = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<bool> isAvailable = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<BigInt?> serverVersion = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductsCompanion(
                id: id,
                businessId: businessId,
                name: name,
                code: code,
                categoryId: categoryId,
                description: description,
                costPricePaise: costPricePaise,
                sellingPricePaise: sellingPricePaise,
                gstRatePercent: gstRatePercent,
                isTaxInclusive: isTaxInclusive,
                unit: unit,
                isAvailable: isAvailable,
                imagePath: imagePath,
                serverVersion: serverVersion,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> businessId = const Value.absent(),
                required String name,
                Value<String?> code = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int> costPricePaise = const Value.absent(),
                required int sellingPricePaise,
                Value<double> gstRatePercent = const Value.absent(),
                Value<bool> isTaxInclusive = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<bool> isAvailable = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<BigInt?> serverVersion = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductsCompanion.insert(
                id: id,
                businessId: businessId,
                name: name,
                code: code,
                categoryId: categoryId,
                description: description,
                costPricePaise: costPricePaise,
                sellingPricePaise: sellingPricePaise,
                gstRatePercent: gstRatePercent,
                isTaxInclusive: isTaxInclusive,
                unit: unit,
                isAvailable: isAvailable,
                imagePath: imagePath,
                serverVersion: serverVersion,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProductsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({categoryId = false, productImagesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (productImagesRefs) db.productImages,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (categoryId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.categoryId,
                                    referencedTable: $$ProductsTableReferences
                                        ._categoryIdTable(db),
                                    referencedColumn: $$ProductsTableReferences
                                        ._categoryIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (productImagesRefs)
                        await $_getPrefetchedData<
                          ProductEntry,
                          $ProductsTable,
                          ProductImageEntry
                        >(
                          currentTable: table,
                          referencedTable: $$ProductsTableReferences
                              ._productImagesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProductsTableReferences(
                                db,
                                table,
                                p0,
                              ).productImagesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.productId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ProductsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductsTable,
      ProductEntry,
      $$ProductsTableFilterComposer,
      $$ProductsTableOrderingComposer,
      $$ProductsTableAnnotationComposer,
      $$ProductsTableCreateCompanionBuilder,
      $$ProductsTableUpdateCompanionBuilder,
      (ProductEntry, $$ProductsTableReferences),
      ProductEntry,
      PrefetchHooks Function({bool categoryId, bool productImagesRefs})
    >;
typedef $$InvoicesTableCreateCompanionBuilder =
    InvoicesCompanion Function({
      required String id,
      Value<String?> businessId,
      Value<String?> deviceId,
      Value<String?> customerId,
      required String invoiceNumber,
      required DateTime createdAt,
      Value<String?> customerName,
      Value<String?> customerPhone,
      required int subtotalPaise,
      Value<int> itemDiscountTotalPaise,
      Value<int> billDiscountPaise,
      required int taxableAmountPaise,
      Value<int> cgstPaise,
      Value<int> sgstPaise,
      Value<int> igstPaise,
      Value<int> roundOffPaise,
      required int grandTotalPaise,
      Value<String> paymentMethod,
      Value<String> paymentStatus,
      Value<String> orderStatus,
      Value<String> orderType,
      Value<String?> tableNumber,
      Value<String?> deliveryAddress,
      Value<String?> kotNumber,
      Value<String?> cashierId,
      Value<String?> cashierName,
      required int paidAmountPaise,
      Value<bool> isCancelled,
      Value<DateTime?> cancelledAt,
      Value<String?> cancelReason,
      Value<String?> idempotencyKey,
      Value<BigInt?> serverVersion,
      Value<String?> syncStatus,
      Value<int> rowid,
    });
typedef $$InvoicesTableUpdateCompanionBuilder =
    InvoicesCompanion Function({
      Value<String> id,
      Value<String?> businessId,
      Value<String?> deviceId,
      Value<String?> customerId,
      Value<String> invoiceNumber,
      Value<DateTime> createdAt,
      Value<String?> customerName,
      Value<String?> customerPhone,
      Value<int> subtotalPaise,
      Value<int> itemDiscountTotalPaise,
      Value<int> billDiscountPaise,
      Value<int> taxableAmountPaise,
      Value<int> cgstPaise,
      Value<int> sgstPaise,
      Value<int> igstPaise,
      Value<int> roundOffPaise,
      Value<int> grandTotalPaise,
      Value<String> paymentMethod,
      Value<String> paymentStatus,
      Value<String> orderStatus,
      Value<String> orderType,
      Value<String?> tableNumber,
      Value<String?> deliveryAddress,
      Value<String?> kotNumber,
      Value<String?> cashierId,
      Value<String?> cashierName,
      Value<int> paidAmountPaise,
      Value<bool> isCancelled,
      Value<DateTime?> cancelledAt,
      Value<String?> cancelReason,
      Value<String?> idempotencyKey,
      Value<BigInt?> serverVersion,
      Value<String?> syncStatus,
      Value<int> rowid,
    });

final class $$InvoicesTableReferences
    extends BaseReferences<_$AppDatabase, $InvoicesTable, InvoiceEntry> {
  $$InvoicesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$InvoiceItemsTable, List<InvoiceItemEntry>>
  _invoiceItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.invoiceItems,
    aliasName: $_aliasNameGenerator(db.invoices.id, db.invoiceItems.invoiceId),
  );

  $$InvoiceItemsTableProcessedTableManager get invoiceItemsRefs {
    final manager = $$InvoiceItemsTableTableManager(
      $_db,
      $_db.invoiceItems,
    ).filter((f) => f.invoiceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_invoiceItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BillNotesTable, List<BillNoteEntry>>
  _billNotesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.billNotes,
    aliasName: $_aliasNameGenerator(db.invoices.id, db.billNotes.invoiceId),
  );

  $$BillNotesTableProcessedTableManager get billNotesRefs {
    final manager = $$BillNotesTableTableManager(
      $_db,
      $_db.billNotes,
    ).filter((f) => f.invoiceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_billNotesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PaymentsTable, List<PaymentEntry>>
  _paymentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.payments,
    aliasName: $_aliasNameGenerator(db.invoices.id, db.payments.invoiceId),
  );

  $$PaymentsTableProcessedTableManager get paymentsRefs {
    final manager = $$PaymentsTableTableManager(
      $_db,
      $_db.payments,
    ).filter((f) => f.invoiceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_paymentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$InvoicesTableFilterComposer
    extends Composer<_$AppDatabase, $InvoicesTable> {
  $$InvoicesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get invoiceNumber => $composableBuilder(
    column: $table.invoiceNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerPhone => $composableBuilder(
    column: $table.customerPhone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get subtotalPaise => $composableBuilder(
    column: $table.subtotalPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get itemDiscountTotalPaise => $composableBuilder(
    column: $table.itemDiscountTotalPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get billDiscountPaise => $composableBuilder(
    column: $table.billDiscountPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get taxableAmountPaise => $composableBuilder(
    column: $table.taxableAmountPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cgstPaise => $composableBuilder(
    column: $table.cgstPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sgstPaise => $composableBuilder(
    column: $table.sgstPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get igstPaise => $composableBuilder(
    column: $table.igstPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get roundOffPaise => $composableBuilder(
    column: $table.roundOffPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get grandTotalPaise => $composableBuilder(
    column: $table.grandTotalPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentStatus => $composableBuilder(
    column: $table.paymentStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get orderStatus => $composableBuilder(
    column: $table.orderStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get orderType => $composableBuilder(
    column: $table.orderType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tableNumber => $composableBuilder(
    column: $table.tableNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deliveryAddress => $composableBuilder(
    column: $table.deliveryAddress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kotNumber => $composableBuilder(
    column: $table.kotNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cashierId => $composableBuilder(
    column: $table.cashierId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cashierName => $composableBuilder(
    column: $table.cashierName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get paidAmountPaise => $composableBuilder(
    column: $table.paidAmountPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCancelled => $composableBuilder(
    column: $table.isCancelled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cancelledAt => $composableBuilder(
    column: $table.cancelledAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cancelReason => $composableBuilder(
    column: $table.cancelReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> invoiceItemsRefs(
    Expression<bool> Function($$InvoiceItemsTableFilterComposer f) f,
  ) {
    final $$InvoiceItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.invoiceItems,
      getReferencedColumn: (t) => t.invoiceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoiceItemsTableFilterComposer(
            $db: $db,
            $table: $db.invoiceItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> billNotesRefs(
    Expression<bool> Function($$BillNotesTableFilterComposer f) f,
  ) {
    final $$BillNotesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.billNotes,
      getReferencedColumn: (t) => t.invoiceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BillNotesTableFilterComposer(
            $db: $db,
            $table: $db.billNotes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> paymentsRefs(
    Expression<bool> Function($$PaymentsTableFilterComposer f) f,
  ) {
    final $$PaymentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.payments,
      getReferencedColumn: (t) => t.invoiceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PaymentsTableFilterComposer(
            $db: $db,
            $table: $db.payments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$InvoicesTableOrderingComposer
    extends Composer<_$AppDatabase, $InvoicesTable> {
  $$InvoicesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get invoiceNumber => $composableBuilder(
    column: $table.invoiceNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerPhone => $composableBuilder(
    column: $table.customerPhone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get subtotalPaise => $composableBuilder(
    column: $table.subtotalPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get itemDiscountTotalPaise => $composableBuilder(
    column: $table.itemDiscountTotalPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get billDiscountPaise => $composableBuilder(
    column: $table.billDiscountPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get taxableAmountPaise => $composableBuilder(
    column: $table.taxableAmountPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cgstPaise => $composableBuilder(
    column: $table.cgstPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sgstPaise => $composableBuilder(
    column: $table.sgstPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get igstPaise => $composableBuilder(
    column: $table.igstPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get roundOffPaise => $composableBuilder(
    column: $table.roundOffPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get grandTotalPaise => $composableBuilder(
    column: $table.grandTotalPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentStatus => $composableBuilder(
    column: $table.paymentStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get orderStatus => $composableBuilder(
    column: $table.orderStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get orderType => $composableBuilder(
    column: $table.orderType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tableNumber => $composableBuilder(
    column: $table.tableNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deliveryAddress => $composableBuilder(
    column: $table.deliveryAddress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kotNumber => $composableBuilder(
    column: $table.kotNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cashierId => $composableBuilder(
    column: $table.cashierId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cashierName => $composableBuilder(
    column: $table.cashierName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get paidAmountPaise => $composableBuilder(
    column: $table.paidAmountPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCancelled => $composableBuilder(
    column: $table.isCancelled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cancelledAt => $composableBuilder(
    column: $table.cancelledAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cancelReason => $composableBuilder(
    column: $table.cancelReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InvoicesTableAnnotationComposer
    extends Composer<_$AppDatabase, $InvoicesTable> {
  $$InvoicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get invoiceNumber => $composableBuilder(
    column: $table.invoiceNumber,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerPhone => $composableBuilder(
    column: $table.customerPhone,
    builder: (column) => column,
  );

  GeneratedColumn<int> get subtotalPaise => $composableBuilder(
    column: $table.subtotalPaise,
    builder: (column) => column,
  );

  GeneratedColumn<int> get itemDiscountTotalPaise => $composableBuilder(
    column: $table.itemDiscountTotalPaise,
    builder: (column) => column,
  );

  GeneratedColumn<int> get billDiscountPaise => $composableBuilder(
    column: $table.billDiscountPaise,
    builder: (column) => column,
  );

  GeneratedColumn<int> get taxableAmountPaise => $composableBuilder(
    column: $table.taxableAmountPaise,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cgstPaise =>
      $composableBuilder(column: $table.cgstPaise, builder: (column) => column);

  GeneratedColumn<int> get sgstPaise =>
      $composableBuilder(column: $table.sgstPaise, builder: (column) => column);

  GeneratedColumn<int> get igstPaise =>
      $composableBuilder(column: $table.igstPaise, builder: (column) => column);

  GeneratedColumn<int> get roundOffPaise => $composableBuilder(
    column: $table.roundOffPaise,
    builder: (column) => column,
  );

  GeneratedColumn<int> get grandTotalPaise => $composableBuilder(
    column: $table.grandTotalPaise,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentStatus => $composableBuilder(
    column: $table.paymentStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get orderStatus => $composableBuilder(
    column: $table.orderStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get orderType =>
      $composableBuilder(column: $table.orderType, builder: (column) => column);

  GeneratedColumn<String> get tableNumber => $composableBuilder(
    column: $table.tableNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deliveryAddress => $composableBuilder(
    column: $table.deliveryAddress,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kotNumber =>
      $composableBuilder(column: $table.kotNumber, builder: (column) => column);

  GeneratedColumn<String> get cashierId =>
      $composableBuilder(column: $table.cashierId, builder: (column) => column);

  GeneratedColumn<String> get cashierName => $composableBuilder(
    column: $table.cashierName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get paidAmountPaise => $composableBuilder(
    column: $table.paidAmountPaise,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isCancelled => $composableBuilder(
    column: $table.isCancelled,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get cancelledAt => $composableBuilder(
    column: $table.cancelledAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cancelReason => $composableBuilder(
    column: $table.cancelReason,
    builder: (column) => column,
  );

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );

  GeneratedColumn<BigInt> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  Expression<T> invoiceItemsRefs<T extends Object>(
    Expression<T> Function($$InvoiceItemsTableAnnotationComposer a) f,
  ) {
    final $$InvoiceItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.invoiceItems,
      getReferencedColumn: (t) => t.invoiceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoiceItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.invoiceItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> billNotesRefs<T extends Object>(
    Expression<T> Function($$BillNotesTableAnnotationComposer a) f,
  ) {
    final $$BillNotesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.billNotes,
      getReferencedColumn: (t) => t.invoiceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BillNotesTableAnnotationComposer(
            $db: $db,
            $table: $db.billNotes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> paymentsRefs<T extends Object>(
    Expression<T> Function($$PaymentsTableAnnotationComposer a) f,
  ) {
    final $$PaymentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.payments,
      getReferencedColumn: (t) => t.invoiceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PaymentsTableAnnotationComposer(
            $db: $db,
            $table: $db.payments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$InvoicesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InvoicesTable,
          InvoiceEntry,
          $$InvoicesTableFilterComposer,
          $$InvoicesTableOrderingComposer,
          $$InvoicesTableAnnotationComposer,
          $$InvoicesTableCreateCompanionBuilder,
          $$InvoicesTableUpdateCompanionBuilder,
          (InvoiceEntry, $$InvoicesTableReferences),
          InvoiceEntry,
          PrefetchHooks Function({
            bool invoiceItemsRefs,
            bool billNotesRefs,
            bool paymentsRefs,
          })
        > {
  $$InvoicesTableTableManager(_$AppDatabase db, $InvoicesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InvoicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InvoicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InvoicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> businessId = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<String?> customerId = const Value.absent(),
                Value<String> invoiceNumber = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> customerName = const Value.absent(),
                Value<String?> customerPhone = const Value.absent(),
                Value<int> subtotalPaise = const Value.absent(),
                Value<int> itemDiscountTotalPaise = const Value.absent(),
                Value<int> billDiscountPaise = const Value.absent(),
                Value<int> taxableAmountPaise = const Value.absent(),
                Value<int> cgstPaise = const Value.absent(),
                Value<int> sgstPaise = const Value.absent(),
                Value<int> igstPaise = const Value.absent(),
                Value<int> roundOffPaise = const Value.absent(),
                Value<int> grandTotalPaise = const Value.absent(),
                Value<String> paymentMethod = const Value.absent(),
                Value<String> paymentStatus = const Value.absent(),
                Value<String> orderStatus = const Value.absent(),
                Value<String> orderType = const Value.absent(),
                Value<String?> tableNumber = const Value.absent(),
                Value<String?> deliveryAddress = const Value.absent(),
                Value<String?> kotNumber = const Value.absent(),
                Value<String?> cashierId = const Value.absent(),
                Value<String?> cashierName = const Value.absent(),
                Value<int> paidAmountPaise = const Value.absent(),
                Value<bool> isCancelled = const Value.absent(),
                Value<DateTime?> cancelledAt = const Value.absent(),
                Value<String?> cancelReason = const Value.absent(),
                Value<String?> idempotencyKey = const Value.absent(),
                Value<BigInt?> serverVersion = const Value.absent(),
                Value<String?> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InvoicesCompanion(
                id: id,
                businessId: businessId,
                deviceId: deviceId,
                customerId: customerId,
                invoiceNumber: invoiceNumber,
                createdAt: createdAt,
                customerName: customerName,
                customerPhone: customerPhone,
                subtotalPaise: subtotalPaise,
                itemDiscountTotalPaise: itemDiscountTotalPaise,
                billDiscountPaise: billDiscountPaise,
                taxableAmountPaise: taxableAmountPaise,
                cgstPaise: cgstPaise,
                sgstPaise: sgstPaise,
                igstPaise: igstPaise,
                roundOffPaise: roundOffPaise,
                grandTotalPaise: grandTotalPaise,
                paymentMethod: paymentMethod,
                paymentStatus: paymentStatus,
                orderStatus: orderStatus,
                orderType: orderType,
                tableNumber: tableNumber,
                deliveryAddress: deliveryAddress,
                kotNumber: kotNumber,
                cashierId: cashierId,
                cashierName: cashierName,
                paidAmountPaise: paidAmountPaise,
                isCancelled: isCancelled,
                cancelledAt: cancelledAt,
                cancelReason: cancelReason,
                idempotencyKey: idempotencyKey,
                serverVersion: serverVersion,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> businessId = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<String?> customerId = const Value.absent(),
                required String invoiceNumber,
                required DateTime createdAt,
                Value<String?> customerName = const Value.absent(),
                Value<String?> customerPhone = const Value.absent(),
                required int subtotalPaise,
                Value<int> itemDiscountTotalPaise = const Value.absent(),
                Value<int> billDiscountPaise = const Value.absent(),
                required int taxableAmountPaise,
                Value<int> cgstPaise = const Value.absent(),
                Value<int> sgstPaise = const Value.absent(),
                Value<int> igstPaise = const Value.absent(),
                Value<int> roundOffPaise = const Value.absent(),
                required int grandTotalPaise,
                Value<String> paymentMethod = const Value.absent(),
                Value<String> paymentStatus = const Value.absent(),
                Value<String> orderStatus = const Value.absent(),
                Value<String> orderType = const Value.absent(),
                Value<String?> tableNumber = const Value.absent(),
                Value<String?> deliveryAddress = const Value.absent(),
                Value<String?> kotNumber = const Value.absent(),
                Value<String?> cashierId = const Value.absent(),
                Value<String?> cashierName = const Value.absent(),
                required int paidAmountPaise,
                Value<bool> isCancelled = const Value.absent(),
                Value<DateTime?> cancelledAt = const Value.absent(),
                Value<String?> cancelReason = const Value.absent(),
                Value<String?> idempotencyKey = const Value.absent(),
                Value<BigInt?> serverVersion = const Value.absent(),
                Value<String?> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InvoicesCompanion.insert(
                id: id,
                businessId: businessId,
                deviceId: deviceId,
                customerId: customerId,
                invoiceNumber: invoiceNumber,
                createdAt: createdAt,
                customerName: customerName,
                customerPhone: customerPhone,
                subtotalPaise: subtotalPaise,
                itemDiscountTotalPaise: itemDiscountTotalPaise,
                billDiscountPaise: billDiscountPaise,
                taxableAmountPaise: taxableAmountPaise,
                cgstPaise: cgstPaise,
                sgstPaise: sgstPaise,
                igstPaise: igstPaise,
                roundOffPaise: roundOffPaise,
                grandTotalPaise: grandTotalPaise,
                paymentMethod: paymentMethod,
                paymentStatus: paymentStatus,
                orderStatus: orderStatus,
                orderType: orderType,
                tableNumber: tableNumber,
                deliveryAddress: deliveryAddress,
                kotNumber: kotNumber,
                cashierId: cashierId,
                cashierName: cashierName,
                paidAmountPaise: paidAmountPaise,
                isCancelled: isCancelled,
                cancelledAt: cancelledAt,
                cancelReason: cancelReason,
                idempotencyKey: idempotencyKey,
                serverVersion: serverVersion,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$InvoicesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                invoiceItemsRefs = false,
                billNotesRefs = false,
                paymentsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (invoiceItemsRefs) db.invoiceItems,
                    if (billNotesRefs) db.billNotes,
                    if (paymentsRefs) db.payments,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (invoiceItemsRefs)
                        await $_getPrefetchedData<
                          InvoiceEntry,
                          $InvoicesTable,
                          InvoiceItemEntry
                        >(
                          currentTable: table,
                          referencedTable: $$InvoicesTableReferences
                              ._invoiceItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$InvoicesTableReferences(
                                db,
                                table,
                                p0,
                              ).invoiceItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.invoiceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (billNotesRefs)
                        await $_getPrefetchedData<
                          InvoiceEntry,
                          $InvoicesTable,
                          BillNoteEntry
                        >(
                          currentTable: table,
                          referencedTable: $$InvoicesTableReferences
                              ._billNotesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$InvoicesTableReferences(
                                db,
                                table,
                                p0,
                              ).billNotesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.invoiceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (paymentsRefs)
                        await $_getPrefetchedData<
                          InvoiceEntry,
                          $InvoicesTable,
                          PaymentEntry
                        >(
                          currentTable: table,
                          referencedTable: $$InvoicesTableReferences
                              ._paymentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$InvoicesTableReferences(
                                db,
                                table,
                                p0,
                              ).paymentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.invoiceId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$InvoicesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InvoicesTable,
      InvoiceEntry,
      $$InvoicesTableFilterComposer,
      $$InvoicesTableOrderingComposer,
      $$InvoicesTableAnnotationComposer,
      $$InvoicesTableCreateCompanionBuilder,
      $$InvoicesTableUpdateCompanionBuilder,
      (InvoiceEntry, $$InvoicesTableReferences),
      InvoiceEntry,
      PrefetchHooks Function({
        bool invoiceItemsRefs,
        bool billNotesRefs,
        bool paymentsRefs,
      })
    >;
typedef $$InvoiceItemsTableCreateCompanionBuilder =
    InvoiceItemsCompanion Function({
      required String id,
      required String invoiceId,
      Value<String?> productId,
      required String productName,
      Value<String?> productCode,
      required String unit,
      required int unitPricePaise,
      required double quantity,
      Value<int> discountPaise,
      required double gstRatePercent,
      required bool isTaxInclusive,
      required int taxableAmountPaise,
      required int taxAmountPaise,
      required int totalAmountPaise,
      Value<int> rowid,
    });
typedef $$InvoiceItemsTableUpdateCompanionBuilder =
    InvoiceItemsCompanion Function({
      Value<String> id,
      Value<String> invoiceId,
      Value<String?> productId,
      Value<String> productName,
      Value<String?> productCode,
      Value<String> unit,
      Value<int> unitPricePaise,
      Value<double> quantity,
      Value<int> discountPaise,
      Value<double> gstRatePercent,
      Value<bool> isTaxInclusive,
      Value<int> taxableAmountPaise,
      Value<int> taxAmountPaise,
      Value<int> totalAmountPaise,
      Value<int> rowid,
    });

final class $$InvoiceItemsTableReferences
    extends
        BaseReferences<_$AppDatabase, $InvoiceItemsTable, InvoiceItemEntry> {
  $$InvoiceItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $InvoicesTable _invoiceIdTable(_$AppDatabase db) =>
      db.invoices.createAlias(
        $_aliasNameGenerator(db.invoiceItems.invoiceId, db.invoices.id),
      );

  $$InvoicesTableProcessedTableManager get invoiceId {
    final $_column = $_itemColumn<String>('invoice_id')!;

    final manager = $$InvoicesTableTableManager(
      $_db,
      $_db.invoices,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_invoiceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$InvoiceItemsTableFilterComposer
    extends Composer<_$AppDatabase, $InvoiceItemsTable> {
  $$InvoiceItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productCode => $composableBuilder(
    column: $table.productCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unitPricePaise => $composableBuilder(
    column: $table.unitPricePaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get discountPaise => $composableBuilder(
    column: $table.discountPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get gstRatePercent => $composableBuilder(
    column: $table.gstRatePercent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isTaxInclusive => $composableBuilder(
    column: $table.isTaxInclusive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get taxableAmountPaise => $composableBuilder(
    column: $table.taxableAmountPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get taxAmountPaise => $composableBuilder(
    column: $table.taxAmountPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalAmountPaise => $composableBuilder(
    column: $table.totalAmountPaise,
    builder: (column) => ColumnFilters(column),
  );

  $$InvoicesTableFilterComposer get invoiceId {
    final $$InvoicesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.invoiceId,
      referencedTable: $db.invoices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoicesTableFilterComposer(
            $db: $db,
            $table: $db.invoices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InvoiceItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $InvoiceItemsTable> {
  $$InvoiceItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productCode => $composableBuilder(
    column: $table.productCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unitPricePaise => $composableBuilder(
    column: $table.unitPricePaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get discountPaise => $composableBuilder(
    column: $table.discountPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get gstRatePercent => $composableBuilder(
    column: $table.gstRatePercent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isTaxInclusive => $composableBuilder(
    column: $table.isTaxInclusive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get taxableAmountPaise => $composableBuilder(
    column: $table.taxableAmountPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get taxAmountPaise => $composableBuilder(
    column: $table.taxAmountPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalAmountPaise => $composableBuilder(
    column: $table.totalAmountPaise,
    builder: (column) => ColumnOrderings(column),
  );

  $$InvoicesTableOrderingComposer get invoiceId {
    final $$InvoicesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.invoiceId,
      referencedTable: $db.invoices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoicesTableOrderingComposer(
            $db: $db,
            $table: $db.invoices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InvoiceItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InvoiceItemsTable> {
  $$InvoiceItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get productCode => $composableBuilder(
    column: $table.productCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<int> get unitPricePaise => $composableBuilder(
    column: $table.unitPricePaise,
    builder: (column) => column,
  );

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<int> get discountPaise => $composableBuilder(
    column: $table.discountPaise,
    builder: (column) => column,
  );

  GeneratedColumn<double> get gstRatePercent => $composableBuilder(
    column: $table.gstRatePercent,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isTaxInclusive => $composableBuilder(
    column: $table.isTaxInclusive,
    builder: (column) => column,
  );

  GeneratedColumn<int> get taxableAmountPaise => $composableBuilder(
    column: $table.taxableAmountPaise,
    builder: (column) => column,
  );

  GeneratedColumn<int> get taxAmountPaise => $composableBuilder(
    column: $table.taxAmountPaise,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalAmountPaise => $composableBuilder(
    column: $table.totalAmountPaise,
    builder: (column) => column,
  );

  $$InvoicesTableAnnotationComposer get invoiceId {
    final $$InvoicesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.invoiceId,
      referencedTable: $db.invoices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoicesTableAnnotationComposer(
            $db: $db,
            $table: $db.invoices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InvoiceItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InvoiceItemsTable,
          InvoiceItemEntry,
          $$InvoiceItemsTableFilterComposer,
          $$InvoiceItemsTableOrderingComposer,
          $$InvoiceItemsTableAnnotationComposer,
          $$InvoiceItemsTableCreateCompanionBuilder,
          $$InvoiceItemsTableUpdateCompanionBuilder,
          (InvoiceItemEntry, $$InvoiceItemsTableReferences),
          InvoiceItemEntry,
          PrefetchHooks Function({bool invoiceId})
        > {
  $$InvoiceItemsTableTableManager(_$AppDatabase db, $InvoiceItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InvoiceItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InvoiceItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InvoiceItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> invoiceId = const Value.absent(),
                Value<String?> productId = const Value.absent(),
                Value<String> productName = const Value.absent(),
                Value<String?> productCode = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<int> unitPricePaise = const Value.absent(),
                Value<double> quantity = const Value.absent(),
                Value<int> discountPaise = const Value.absent(),
                Value<double> gstRatePercent = const Value.absent(),
                Value<bool> isTaxInclusive = const Value.absent(),
                Value<int> taxableAmountPaise = const Value.absent(),
                Value<int> taxAmountPaise = const Value.absent(),
                Value<int> totalAmountPaise = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InvoiceItemsCompanion(
                id: id,
                invoiceId: invoiceId,
                productId: productId,
                productName: productName,
                productCode: productCode,
                unit: unit,
                unitPricePaise: unitPricePaise,
                quantity: quantity,
                discountPaise: discountPaise,
                gstRatePercent: gstRatePercent,
                isTaxInclusive: isTaxInclusive,
                taxableAmountPaise: taxableAmountPaise,
                taxAmountPaise: taxAmountPaise,
                totalAmountPaise: totalAmountPaise,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String invoiceId,
                Value<String?> productId = const Value.absent(),
                required String productName,
                Value<String?> productCode = const Value.absent(),
                required String unit,
                required int unitPricePaise,
                required double quantity,
                Value<int> discountPaise = const Value.absent(),
                required double gstRatePercent,
                required bool isTaxInclusive,
                required int taxableAmountPaise,
                required int taxAmountPaise,
                required int totalAmountPaise,
                Value<int> rowid = const Value.absent(),
              }) => InvoiceItemsCompanion.insert(
                id: id,
                invoiceId: invoiceId,
                productId: productId,
                productName: productName,
                productCode: productCode,
                unit: unit,
                unitPricePaise: unitPricePaise,
                quantity: quantity,
                discountPaise: discountPaise,
                gstRatePercent: gstRatePercent,
                isTaxInclusive: isTaxInclusive,
                taxableAmountPaise: taxableAmountPaise,
                taxAmountPaise: taxAmountPaise,
                totalAmountPaise: totalAmountPaise,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$InvoiceItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({invoiceId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (invoiceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.invoiceId,
                                referencedTable: $$InvoiceItemsTableReferences
                                    ._invoiceIdTable(db),
                                referencedColumn: $$InvoiceItemsTableReferences
                                    ._invoiceIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$InvoiceItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InvoiceItemsTable,
      InvoiceItemEntry,
      $$InvoiceItemsTableFilterComposer,
      $$InvoiceItemsTableOrderingComposer,
      $$InvoiceItemsTableAnnotationComposer,
      $$InvoiceItemsTableCreateCompanionBuilder,
      $$InvoiceItemsTableUpdateCompanionBuilder,
      (InvoiceItemEntry, $$InvoiceItemsTableReferences),
      InvoiceItemEntry,
      PrefetchHooks Function({bool invoiceId})
    >;
typedef $$BillNotesTableCreateCompanionBuilder =
    BillNotesCompanion Function({
      required String id,
      required String invoiceId,
      required String note,
      Value<bool> isCustomerFacing,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$BillNotesTableUpdateCompanionBuilder =
    BillNotesCompanion Function({
      Value<String> id,
      Value<String> invoiceId,
      Value<String> note,
      Value<bool> isCustomerFacing,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$BillNotesTableReferences
    extends BaseReferences<_$AppDatabase, $BillNotesTable, BillNoteEntry> {
  $$BillNotesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $InvoicesTable _invoiceIdTable(_$AppDatabase db) =>
      db.invoices.createAlias(
        $_aliasNameGenerator(db.billNotes.invoiceId, db.invoices.id),
      );

  $$InvoicesTableProcessedTableManager get invoiceId {
    final $_column = $_itemColumn<String>('invoice_id')!;

    final manager = $$InvoicesTableTableManager(
      $_db,
      $_db.invoices,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_invoiceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BillNotesTableFilterComposer
    extends Composer<_$AppDatabase, $BillNotesTable> {
  $$BillNotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCustomerFacing => $composableBuilder(
    column: $table.isCustomerFacing,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$InvoicesTableFilterComposer get invoiceId {
    final $$InvoicesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.invoiceId,
      referencedTable: $db.invoices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoicesTableFilterComposer(
            $db: $db,
            $table: $db.invoices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BillNotesTableOrderingComposer
    extends Composer<_$AppDatabase, $BillNotesTable> {
  $$BillNotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCustomerFacing => $composableBuilder(
    column: $table.isCustomerFacing,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$InvoicesTableOrderingComposer get invoiceId {
    final $$InvoicesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.invoiceId,
      referencedTable: $db.invoices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoicesTableOrderingComposer(
            $db: $db,
            $table: $db.invoices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BillNotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BillNotesTable> {
  $$BillNotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<bool> get isCustomerFacing => $composableBuilder(
    column: $table.isCustomerFacing,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$InvoicesTableAnnotationComposer get invoiceId {
    final $$InvoicesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.invoiceId,
      referencedTable: $db.invoices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoicesTableAnnotationComposer(
            $db: $db,
            $table: $db.invoices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BillNotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BillNotesTable,
          BillNoteEntry,
          $$BillNotesTableFilterComposer,
          $$BillNotesTableOrderingComposer,
          $$BillNotesTableAnnotationComposer,
          $$BillNotesTableCreateCompanionBuilder,
          $$BillNotesTableUpdateCompanionBuilder,
          (BillNoteEntry, $$BillNotesTableReferences),
          BillNoteEntry,
          PrefetchHooks Function({bool invoiceId})
        > {
  $$BillNotesTableTableManager(_$AppDatabase db, $BillNotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BillNotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BillNotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BillNotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> invoiceId = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<bool> isCustomerFacing = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BillNotesCompanion(
                id: id,
                invoiceId: invoiceId,
                note: note,
                isCustomerFacing: isCustomerFacing,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String invoiceId,
                required String note,
                Value<bool> isCustomerFacing = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => BillNotesCompanion.insert(
                id: id,
                invoiceId: invoiceId,
                note: note,
                isCustomerFacing: isCustomerFacing,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BillNotesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({invoiceId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (invoiceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.invoiceId,
                                referencedTable: $$BillNotesTableReferences
                                    ._invoiceIdTable(db),
                                referencedColumn: $$BillNotesTableReferences
                                    ._invoiceIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$BillNotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BillNotesTable,
      BillNoteEntry,
      $$BillNotesTableFilterComposer,
      $$BillNotesTableOrderingComposer,
      $$BillNotesTableAnnotationComposer,
      $$BillNotesTableCreateCompanionBuilder,
      $$BillNotesTableUpdateCompanionBuilder,
      (BillNoteEntry, $$BillNotesTableReferences),
      BillNoteEntry,
      PrefetchHooks Function({bool invoiceId})
    >;
typedef $$PaymentsTableCreateCompanionBuilder =
    PaymentsCompanion Function({
      required String id,
      Value<String?> businessId,
      required String invoiceId,
      required int amountPaise,
      required String paymentMethod,
      Value<String?> referenceNumber,
      Value<String?> notes,
      required DateTime createdAt,
      Value<String?> idempotencyKey,
      Value<BigInt?> serverVersion,
      Value<String?> syncStatus,
      Value<int> rowid,
    });
typedef $$PaymentsTableUpdateCompanionBuilder =
    PaymentsCompanion Function({
      Value<String> id,
      Value<String?> businessId,
      Value<String> invoiceId,
      Value<int> amountPaise,
      Value<String> paymentMethod,
      Value<String?> referenceNumber,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<String?> idempotencyKey,
      Value<BigInt?> serverVersion,
      Value<String?> syncStatus,
      Value<int> rowid,
    });

final class $$PaymentsTableReferences
    extends BaseReferences<_$AppDatabase, $PaymentsTable, PaymentEntry> {
  $$PaymentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $InvoicesTable _invoiceIdTable(_$AppDatabase db) => db.invoices
      .createAlias($_aliasNameGenerator(db.payments.invoiceId, db.invoices.id));

  $$InvoicesTableProcessedTableManager get invoiceId {
    final $_column = $_itemColumn<String>('invoice_id')!;

    final manager = $$InvoicesTableTableManager(
      $_db,
      $_db.invoices,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_invoiceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PaymentsTableFilterComposer
    extends Composer<_$AppDatabase, $PaymentsTable> {
  $$PaymentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get referenceNumber => $composableBuilder(
    column: $table.referenceNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  $$InvoicesTableFilterComposer get invoiceId {
    final $$InvoicesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.invoiceId,
      referencedTable: $db.invoices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoicesTableFilterComposer(
            $db: $db,
            $table: $db.invoices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PaymentsTableOrderingComposer
    extends Composer<_$AppDatabase, $PaymentsTable> {
  $$PaymentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get referenceNumber => $composableBuilder(
    column: $table.referenceNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  $$InvoicesTableOrderingComposer get invoiceId {
    final $$InvoicesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.invoiceId,
      referencedTable: $db.invoices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoicesTableOrderingComposer(
            $db: $db,
            $table: $db.invoices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PaymentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PaymentsTable> {
  $$PaymentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get referenceNumber => $composableBuilder(
    column: $table.referenceNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );

  GeneratedColumn<BigInt> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  $$InvoicesTableAnnotationComposer get invoiceId {
    final $$InvoicesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.invoiceId,
      referencedTable: $db.invoices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoicesTableAnnotationComposer(
            $db: $db,
            $table: $db.invoices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PaymentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PaymentsTable,
          PaymentEntry,
          $$PaymentsTableFilterComposer,
          $$PaymentsTableOrderingComposer,
          $$PaymentsTableAnnotationComposer,
          $$PaymentsTableCreateCompanionBuilder,
          $$PaymentsTableUpdateCompanionBuilder,
          (PaymentEntry, $$PaymentsTableReferences),
          PaymentEntry,
          PrefetchHooks Function({bool invoiceId})
        > {
  $$PaymentsTableTableManager(_$AppDatabase db, $PaymentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PaymentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PaymentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PaymentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> businessId = const Value.absent(),
                Value<String> invoiceId = const Value.absent(),
                Value<int> amountPaise = const Value.absent(),
                Value<String> paymentMethod = const Value.absent(),
                Value<String?> referenceNumber = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> idempotencyKey = const Value.absent(),
                Value<BigInt?> serverVersion = const Value.absent(),
                Value<String?> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PaymentsCompanion(
                id: id,
                businessId: businessId,
                invoiceId: invoiceId,
                amountPaise: amountPaise,
                paymentMethod: paymentMethod,
                referenceNumber: referenceNumber,
                notes: notes,
                createdAt: createdAt,
                idempotencyKey: idempotencyKey,
                serverVersion: serverVersion,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> businessId = const Value.absent(),
                required String invoiceId,
                required int amountPaise,
                required String paymentMethod,
                Value<String?> referenceNumber = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                required DateTime createdAt,
                Value<String?> idempotencyKey = const Value.absent(),
                Value<BigInt?> serverVersion = const Value.absent(),
                Value<String?> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PaymentsCompanion.insert(
                id: id,
                businessId: businessId,
                invoiceId: invoiceId,
                amountPaise: amountPaise,
                paymentMethod: paymentMethod,
                referenceNumber: referenceNumber,
                notes: notes,
                createdAt: createdAt,
                idempotencyKey: idempotencyKey,
                serverVersion: serverVersion,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PaymentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({invoiceId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (invoiceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.invoiceId,
                                referencedTable: $$PaymentsTableReferences
                                    ._invoiceIdTable(db),
                                referencedColumn: $$PaymentsTableReferences
                                    ._invoiceIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PaymentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PaymentsTable,
      PaymentEntry,
      $$PaymentsTableFilterComposer,
      $$PaymentsTableOrderingComposer,
      $$PaymentsTableAnnotationComposer,
      $$PaymentsTableCreateCompanionBuilder,
      $$PaymentsTableUpdateCompanionBuilder,
      (PaymentEntry, $$PaymentsTableReferences),
      PaymentEntry,
      PrefetchHooks Function({bool invoiceId})
    >;
typedef $$CustomersTableCreateCompanionBuilder =
    CustomersCompanion Function({
      required String id,
      Value<String?> businessId,
      required String name,
      Value<String?> phone,
      Value<String?> address,
      Value<String?> notes,
      required DateTime createdAt,
      Value<DateTime?> deletedAt,
      Value<BigInt?> serverVersion,
      Value<String?> syncStatus,
      Value<int> rowid,
    });
typedef $$CustomersTableUpdateCompanionBuilder =
    CustomersCompanion Function({
      Value<String> id,
      Value<String?> businessId,
      Value<String> name,
      Value<String?> phone,
      Value<String?> address,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<DateTime?> deletedAt,
      Value<BigInt?> serverVersion,
      Value<String?> syncStatus,
      Value<int> rowid,
    });

class $$CustomersTableFilterComposer
    extends Composer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CustomersTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CustomersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<BigInt> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );
}

class $$CustomersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomersTable,
          CustomerEntry,
          $$CustomersTableFilterComposer,
          $$CustomersTableOrderingComposer,
          $$CustomersTableAnnotationComposer,
          $$CustomersTableCreateCompanionBuilder,
          $$CustomersTableUpdateCompanionBuilder,
          (
            CustomerEntry,
            BaseReferences<_$AppDatabase, $CustomersTable, CustomerEntry>,
          ),
          CustomerEntry,
          PrefetchHooks Function()
        > {
  $$CustomersTableTableManager(_$AppDatabase db, $CustomersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> businessId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<BigInt?> serverVersion = const Value.absent(),
                Value<String?> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomersCompanion(
                id: id,
                businessId: businessId,
                name: name,
                phone: phone,
                address: address,
                notes: notes,
                createdAt: createdAt,
                deletedAt: deletedAt,
                serverVersion: serverVersion,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> businessId = const Value.absent(),
                required String name,
                Value<String?> phone = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<BigInt?> serverVersion = const Value.absent(),
                Value<String?> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomersCompanion.insert(
                id: id,
                businessId: businessId,
                name: name,
                phone: phone,
                address: address,
                notes: notes,
                createdAt: createdAt,
                deletedAt: deletedAt,
                serverVersion: serverVersion,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CustomersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomersTable,
      CustomerEntry,
      $$CustomersTableFilterComposer,
      $$CustomersTableOrderingComposer,
      $$CustomersTableAnnotationComposer,
      $$CustomersTableCreateCompanionBuilder,
      $$CustomersTableUpdateCompanionBuilder,
      (
        CustomerEntry,
        BaseReferences<_$AppDatabase, $CustomersTable, CustomerEntry>,
      ),
      CustomerEntry,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSettingEntry,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSettingEntry,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSettingEntry>,
          ),
          AppSettingEntry,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSettingEntry,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSettingEntry,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSettingEntry>,
      ),
      AppSettingEntry,
      PrefetchHooks Function()
    >;
typedef $$ProductImagesTableCreateCompanionBuilder =
    ProductImagesCompanion Function({
      required String id,
      required String productId,
      required Uint8List imageBytes,
      Value<bool> isPrimary,
      Value<int> displayOrder,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$ProductImagesTableUpdateCompanionBuilder =
    ProductImagesCompanion Function({
      Value<String> id,
      Value<String> productId,
      Value<Uint8List> imageBytes,
      Value<bool> isPrimary,
      Value<int> displayOrder,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$ProductImagesTableReferences
    extends
        BaseReferences<_$AppDatabase, $ProductImagesTable, ProductImageEntry> {
  $$ProductImagesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProductsTable _productIdTable(_$AppDatabase db) =>
      db.products.createAlias(
        $_aliasNameGenerator(db.productImages.productId, db.products.id),
      );

  $$ProductsTableProcessedTableManager get productId {
    final $_column = $_itemColumn<String>('product_id')!;

    final manager = $$ProductsTableTableManager(
      $_db,
      $_db.products,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ProductImagesTableFilterComposer
    extends Composer<_$AppDatabase, $ProductImagesTable> {
  $$ProductImagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get imageBytes => $composableBuilder(
    column: $table.imageBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPrimary => $composableBuilder(
    column: $table.isPrimary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableFilterComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProductImagesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductImagesTable> {
  $$ProductImagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get imageBytes => $composableBuilder(
    column: $table.imageBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPrimary => $composableBuilder(
    column: $table.isPrimary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableOrderingComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProductImagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductImagesTable> {
  $$ProductImagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<Uint8List> get imageBytes => $composableBuilder(
    column: $table.imageBytes,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPrimary =>
      $composableBuilder(column: $table.isPrimary, builder: (column) => column);

  GeneratedColumn<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableAnnotationComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProductImagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductImagesTable,
          ProductImageEntry,
          $$ProductImagesTableFilterComposer,
          $$ProductImagesTableOrderingComposer,
          $$ProductImagesTableAnnotationComposer,
          $$ProductImagesTableCreateCompanionBuilder,
          $$ProductImagesTableUpdateCompanionBuilder,
          (ProductImageEntry, $$ProductImagesTableReferences),
          ProductImageEntry,
          PrefetchHooks Function({bool productId})
        > {
  $$ProductImagesTableTableManager(_$AppDatabase db, $ProductImagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductImagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductImagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductImagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<Uint8List> imageBytes = const Value.absent(),
                Value<bool> isPrimary = const Value.absent(),
                Value<int> displayOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductImagesCompanion(
                id: id,
                productId: productId,
                imageBytes: imageBytes,
                isPrimary: isPrimary,
                displayOrder: displayOrder,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String productId,
                required Uint8List imageBytes,
                Value<bool> isPrimary = const Value.absent(),
                Value<int> displayOrder = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ProductImagesCompanion.insert(
                id: id,
                productId: productId,
                imageBytes: imageBytes,
                isPrimary: isPrimary,
                displayOrder: displayOrder,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProductImagesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({productId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (productId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.productId,
                                referencedTable: $$ProductImagesTableReferences
                                    ._productIdTable(db),
                                referencedColumn: $$ProductImagesTableReferences
                                    ._productIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ProductImagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductImagesTable,
      ProductImageEntry,
      $$ProductImagesTableFilterComposer,
      $$ProductImagesTableOrderingComposer,
      $$ProductImagesTableAnnotationComposer,
      $$ProductImagesTableCreateCompanionBuilder,
      $$ProductImagesTableUpdateCompanionBuilder,
      (ProductImageEntry, $$ProductImagesTableReferences),
      ProductImageEntry,
      PrefetchHooks Function({bool productId})
    >;
typedef $$UsersTableCreateCompanionBuilder =
    UsersCompanion Function({
      required String id,
      Value<String?> businessId,
      required String username,
      required String fullName,
      required String role,
      required String passwordHash,
      required String salt,
      Value<bool> isActive,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$UsersTableUpdateCompanionBuilder =
    UsersCompanion Function({
      Value<String> id,
      Value<String?> businessId,
      Value<String> username,
      Value<String> fullName,
      Value<String> role,
      Value<String> passwordHash,
      Value<String> salt,
      Value<bool> isActive,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$UsersTableFilterComposer extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get salt => $composableBuilder(
    column: $table.salt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UsersTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get salt => $composableBuilder(
    column: $table.salt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get fullName =>
      $composableBuilder(column: $table.fullName, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get salt =>
      $composableBuilder(column: $table.salt, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$UsersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UsersTable,
          UserEntry,
          $$UsersTableFilterComposer,
          $$UsersTableOrderingComposer,
          $$UsersTableAnnotationComposer,
          $$UsersTableCreateCompanionBuilder,
          $$UsersTableUpdateCompanionBuilder,
          (UserEntry, BaseReferences<_$AppDatabase, $UsersTable, UserEntry>),
          UserEntry,
          PrefetchHooks Function()
        > {
  $$UsersTableTableManager(_$AppDatabase db, $UsersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> businessId = const Value.absent(),
                Value<String> username = const Value.absent(),
                Value<String> fullName = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> passwordHash = const Value.absent(),
                Value<String> salt = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsersCompanion(
                id: id,
                businessId: businessId,
                username: username,
                fullName: fullName,
                role: role,
                passwordHash: passwordHash,
                salt: salt,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> businessId = const Value.absent(),
                required String username,
                required String fullName,
                required String role,
                required String passwordHash,
                required String salt,
                Value<bool> isActive = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => UsersCompanion.insert(
                id: id,
                businessId: businessId,
                username: username,
                fullName: fullName,
                role: role,
                passwordHash: passwordHash,
                salt: salt,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UsersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UsersTable,
      UserEntry,
      $$UsersTableFilterComposer,
      $$UsersTableOrderingComposer,
      $$UsersTableAnnotationComposer,
      $$UsersTableCreateCompanionBuilder,
      $$UsersTableUpdateCompanionBuilder,
      (UserEntry, BaseReferences<_$AppDatabase, $UsersTable, UserEntry>),
      UserEntry,
      PrefetchHooks Function()
    >;
typedef $$DiningTablesTableCreateCompanionBuilder =
    DiningTablesCompanion Function({
      required String id,
      Value<String?> businessId,
      required String name,
      Value<int> seatingCapacity,
      Value<bool> isOccupied,
      Value<String?> currentInvoiceId,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<String?> syncStatus,
      Value<int> rowid,
    });
typedef $$DiningTablesTableUpdateCompanionBuilder =
    DiningTablesCompanion Function({
      Value<String> id,
      Value<String?> businessId,
      Value<String> name,
      Value<int> seatingCapacity,
      Value<bool> isOccupied,
      Value<String?> currentInvoiceId,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String?> syncStatus,
      Value<int> rowid,
    });

class $$DiningTablesTableFilterComposer
    extends Composer<_$AppDatabase, $DiningTablesTable> {
  $$DiningTablesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seatingCapacity => $composableBuilder(
    column: $table.seatingCapacity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isOccupied => $composableBuilder(
    column: $table.isOccupied,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currentInvoiceId => $composableBuilder(
    column: $table.currentInvoiceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DiningTablesTableOrderingComposer
    extends Composer<_$AppDatabase, $DiningTablesTable> {
  $$DiningTablesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seatingCapacity => $composableBuilder(
    column: $table.seatingCapacity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isOccupied => $composableBuilder(
    column: $table.isOccupied,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currentInvoiceId => $composableBuilder(
    column: $table.currentInvoiceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DiningTablesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DiningTablesTable> {
  $$DiningTablesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get seatingCapacity => $composableBuilder(
    column: $table.seatingCapacity,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isOccupied => $composableBuilder(
    column: $table.isOccupied,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currentInvoiceId => $composableBuilder(
    column: $table.currentInvoiceId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );
}

class $$DiningTablesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DiningTablesTable,
          DiningTableEntry,
          $$DiningTablesTableFilterComposer,
          $$DiningTablesTableOrderingComposer,
          $$DiningTablesTableAnnotationComposer,
          $$DiningTablesTableCreateCompanionBuilder,
          $$DiningTablesTableUpdateCompanionBuilder,
          (
            DiningTableEntry,
            BaseReferences<_$AppDatabase, $DiningTablesTable, DiningTableEntry>,
          ),
          DiningTableEntry,
          PrefetchHooks Function()
        > {
  $$DiningTablesTableTableManager(_$AppDatabase db, $DiningTablesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DiningTablesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DiningTablesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DiningTablesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> businessId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> seatingCapacity = const Value.absent(),
                Value<bool> isOccupied = const Value.absent(),
                Value<String?> currentInvoiceId = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DiningTablesCompanion(
                id: id,
                businessId: businessId,
                name: name,
                seatingCapacity: seatingCapacity,
                isOccupied: isOccupied,
                currentInvoiceId: currentInvoiceId,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> businessId = const Value.absent(),
                required String name,
                Value<int> seatingCapacity = const Value.absent(),
                Value<bool> isOccupied = const Value.absent(),
                Value<String?> currentInvoiceId = const Value.absent(),
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DiningTablesCompanion.insert(
                id: id,
                businessId: businessId,
                name: name,
                seatingCapacity: seatingCapacity,
                isOccupied: isOccupied,
                currentInvoiceId: currentInvoiceId,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DiningTablesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DiningTablesTable,
      DiningTableEntry,
      $$DiningTablesTableFilterComposer,
      $$DiningTablesTableOrderingComposer,
      $$DiningTablesTableAnnotationComposer,
      $$DiningTablesTableCreateCompanionBuilder,
      $$DiningTablesTableUpdateCompanionBuilder,
      (
        DiningTableEntry,
        BaseReferences<_$AppDatabase, $DiningTablesTable, DiningTableEntry>,
      ),
      DiningTableEntry,
      PrefetchHooks Function()
    >;
typedef $$KotRecordsTableCreateCompanionBuilder =
    KotRecordsCompanion Function({
      required String id,
      required String invoiceId,
      required String kotNumber,
      required String orderType,
      Value<String?> tableNumber,
      required String itemsJson,
      Value<int> reprintCount,
      required DateTime createdAt,
      Value<BigInt?> serverVersion,
      Value<String?> syncStatus,
      Value<int> rowid,
    });
typedef $$KotRecordsTableUpdateCompanionBuilder =
    KotRecordsCompanion Function({
      Value<String> id,
      Value<String> invoiceId,
      Value<String> kotNumber,
      Value<String> orderType,
      Value<String?> tableNumber,
      Value<String> itemsJson,
      Value<int> reprintCount,
      Value<DateTime> createdAt,
      Value<BigInt?> serverVersion,
      Value<String?> syncStatus,
      Value<int> rowid,
    });

class $$KotRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $KotRecordsTable> {
  $$KotRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get invoiceId => $composableBuilder(
    column: $table.invoiceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kotNumber => $composableBuilder(
    column: $table.kotNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get orderType => $composableBuilder(
    column: $table.orderType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tableNumber => $composableBuilder(
    column: $table.tableNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemsJson => $composableBuilder(
    column: $table.itemsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reprintCount => $composableBuilder(
    column: $table.reprintCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );
}

class $$KotRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $KotRecordsTable> {
  $$KotRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get invoiceId => $composableBuilder(
    column: $table.invoiceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kotNumber => $composableBuilder(
    column: $table.kotNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get orderType => $composableBuilder(
    column: $table.orderType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tableNumber => $composableBuilder(
    column: $table.tableNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemsJson => $composableBuilder(
    column: $table.itemsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reprintCount => $composableBuilder(
    column: $table.reprintCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KotRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $KotRecordsTable> {
  $$KotRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get invoiceId =>
      $composableBuilder(column: $table.invoiceId, builder: (column) => column);

  GeneratedColumn<String> get kotNumber =>
      $composableBuilder(column: $table.kotNumber, builder: (column) => column);

  GeneratedColumn<String> get orderType =>
      $composableBuilder(column: $table.orderType, builder: (column) => column);

  GeneratedColumn<String> get tableNumber => $composableBuilder(
    column: $table.tableNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get itemsJson =>
      $composableBuilder(column: $table.itemsJson, builder: (column) => column);

  GeneratedColumn<int> get reprintCount => $composableBuilder(
    column: $table.reprintCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<BigInt> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );
}

class $$KotRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $KotRecordsTable,
          KotRecordEntry,
          $$KotRecordsTableFilterComposer,
          $$KotRecordsTableOrderingComposer,
          $$KotRecordsTableAnnotationComposer,
          $$KotRecordsTableCreateCompanionBuilder,
          $$KotRecordsTableUpdateCompanionBuilder,
          (
            KotRecordEntry,
            BaseReferences<_$AppDatabase, $KotRecordsTable, KotRecordEntry>,
          ),
          KotRecordEntry,
          PrefetchHooks Function()
        > {
  $$KotRecordsTableTableManager(_$AppDatabase db, $KotRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KotRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KotRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KotRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> invoiceId = const Value.absent(),
                Value<String> kotNumber = const Value.absent(),
                Value<String> orderType = const Value.absent(),
                Value<String?> tableNumber = const Value.absent(),
                Value<String> itemsJson = const Value.absent(),
                Value<int> reprintCount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<BigInt?> serverVersion = const Value.absent(),
                Value<String?> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KotRecordsCompanion(
                id: id,
                invoiceId: invoiceId,
                kotNumber: kotNumber,
                orderType: orderType,
                tableNumber: tableNumber,
                itemsJson: itemsJson,
                reprintCount: reprintCount,
                createdAt: createdAt,
                serverVersion: serverVersion,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String invoiceId,
                required String kotNumber,
                required String orderType,
                Value<String?> tableNumber = const Value.absent(),
                required String itemsJson,
                Value<int> reprintCount = const Value.absent(),
                required DateTime createdAt,
                Value<BigInt?> serverVersion = const Value.absent(),
                Value<String?> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KotRecordsCompanion.insert(
                id: id,
                invoiceId: invoiceId,
                kotNumber: kotNumber,
                orderType: orderType,
                tableNumber: tableNumber,
                itemsJson: itemsJson,
                reprintCount: reprintCount,
                createdAt: createdAt,
                serverVersion: serverVersion,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$KotRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $KotRecordsTable,
      KotRecordEntry,
      $$KotRecordsTableFilterComposer,
      $$KotRecordsTableOrderingComposer,
      $$KotRecordsTableAnnotationComposer,
      $$KotRecordsTableCreateCompanionBuilder,
      $$KotRecordsTableUpdateCompanionBuilder,
      (
        KotRecordEntry,
        BaseReferences<_$AppDatabase, $KotRecordsTable, KotRecordEntry>,
      ),
      KotRecordEntry,
      PrefetchHooks Function()
    >;
typedef $$SyncCursorsTableCreateCompanionBuilder =
    SyncCursorsCompanion Function({
      required String syncEntity,
      required String businessId,
      Value<BigInt?> lastServerCursor,
      Value<DateTime?> lastSyncAt,
      Value<String> status,
      Value<int> rowid,
    });
typedef $$SyncCursorsTableUpdateCompanionBuilder =
    SyncCursorsCompanion Function({
      Value<String> syncEntity,
      Value<String> businessId,
      Value<BigInt?> lastServerCursor,
      Value<DateTime?> lastSyncAt,
      Value<String> status,
      Value<int> rowid,
    });

class $$SyncCursorsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncCursorsTable> {
  $$SyncCursorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get syncEntity => $composableBuilder(
    column: $table.syncEntity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get lastServerCursor => $composableBuilder(
    column: $table.lastServerCursor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncCursorsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncCursorsTable> {
  $$SyncCursorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get syncEntity => $composableBuilder(
    column: $table.syncEntity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get lastServerCursor => $composableBuilder(
    column: $table.lastServerCursor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncCursorsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncCursorsTable> {
  $$SyncCursorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get syncEntity => $composableBuilder(
    column: $table.syncEntity,
    builder: (column) => column,
  );

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<BigInt> get lastServerCursor => $composableBuilder(
    column: $table.lastServerCursor,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$SyncCursorsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncCursorsTable,
          SyncCursorEntry,
          $$SyncCursorsTableFilterComposer,
          $$SyncCursorsTableOrderingComposer,
          $$SyncCursorsTableAnnotationComposer,
          $$SyncCursorsTableCreateCompanionBuilder,
          $$SyncCursorsTableUpdateCompanionBuilder,
          (
            SyncCursorEntry,
            BaseReferences<_$AppDatabase, $SyncCursorsTable, SyncCursorEntry>,
          ),
          SyncCursorEntry,
          PrefetchHooks Function()
        > {
  $$SyncCursorsTableTableManager(_$AppDatabase db, $SyncCursorsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncCursorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncCursorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncCursorsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> syncEntity = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<BigInt?> lastServerCursor = const Value.absent(),
                Value<DateTime?> lastSyncAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncCursorsCompanion(
                syncEntity: syncEntity,
                businessId: businessId,
                lastServerCursor: lastServerCursor,
                lastSyncAt: lastSyncAt,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String syncEntity,
                required String businessId,
                Value<BigInt?> lastServerCursor = const Value.absent(),
                Value<DateTime?> lastSyncAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncCursorsCompanion.insert(
                syncEntity: syncEntity,
                businessId: businessId,
                lastServerCursor: lastServerCursor,
                lastSyncAt: lastSyncAt,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncCursorsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncCursorsTable,
      SyncCursorEntry,
      $$SyncCursorsTableFilterComposer,
      $$SyncCursorsTableOrderingComposer,
      $$SyncCursorsTableAnnotationComposer,
      $$SyncCursorsTableCreateCompanionBuilder,
      $$SyncCursorsTableUpdateCompanionBuilder,
      (
        SyncCursorEntry,
        BaseReferences<_$AppDatabase, $SyncCursorsTable, SyncCursorEntry>,
      ),
      SyncCursorEntry,
      PrefetchHooks Function()
    >;
typedef $$SyncQueueTableCreateCompanionBuilder =
    SyncQueueCompanion Function({
      required String id,
      required String businessId,
      required String deviceId,
      required String syncEntity,
      required String recordId,
      required String operation,
      Value<BigInt?> clientVersion,
      required String payloadJson,
      required String idempotencyKey,
      required DateTime createdAt,
      Value<int> retryCount,
      Value<String?> lastError,
      Value<String> status,
      Value<int> rowid,
    });
typedef $$SyncQueueTableUpdateCompanionBuilder =
    SyncQueueCompanion Function({
      Value<String> id,
      Value<String> businessId,
      Value<String> deviceId,
      Value<String> syncEntity,
      Value<String> recordId,
      Value<String> operation,
      Value<BigInt?> clientVersion,
      Value<String> payloadJson,
      Value<String> idempotencyKey,
      Value<DateTime> createdAt,
      Value<int> retryCount,
      Value<String?> lastError,
      Value<String> status,
      Value<int> rowid,
    });

class $$SyncQueueTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncEntity => $composableBuilder(
    column: $table.syncEntity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get clientVersion => $composableBuilder(
    column: $table.clientVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncEntity => $composableBuilder(
    column: $table.syncEntity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get clientVersion => $composableBuilder(
    column: $table.clientVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get syncEntity => $composableBuilder(
    column: $table.syncEntity,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recordId =>
      $composableBuilder(column: $table.recordId, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<BigInt> get clientVersion => $composableBuilder(
    column: $table.clientVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$SyncQueueTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncQueueTable,
          SyncQueueEntry,
          $$SyncQueueTableFilterComposer,
          $$SyncQueueTableOrderingComposer,
          $$SyncQueueTableAnnotationComposer,
          $$SyncQueueTableCreateCompanionBuilder,
          $$SyncQueueTableUpdateCompanionBuilder,
          (
            SyncQueueEntry,
            BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueEntry>,
          ),
          SyncQueueEntry,
          PrefetchHooks Function()
        > {
  $$SyncQueueTableTableManager(_$AppDatabase db, $SyncQueueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<String> syncEntity = const Value.absent(),
                Value<String> recordId = const Value.absent(),
                Value<String> operation = const Value.absent(),
                Value<BigInt?> clientVersion = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<String> idempotencyKey = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncQueueCompanion(
                id: id,
                businessId: businessId,
                deviceId: deviceId,
                syncEntity: syncEntity,
                recordId: recordId,
                operation: operation,
                clientVersion: clientVersion,
                payloadJson: payloadJson,
                idempotencyKey: idempotencyKey,
                createdAt: createdAt,
                retryCount: retryCount,
                lastError: lastError,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String businessId,
                required String deviceId,
                required String syncEntity,
                required String recordId,
                required String operation,
                Value<BigInt?> clientVersion = const Value.absent(),
                required String payloadJson,
                required String idempotencyKey,
                required DateTime createdAt,
                Value<int> retryCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncQueueCompanion.insert(
                id: id,
                businessId: businessId,
                deviceId: deviceId,
                syncEntity: syncEntity,
                recordId: recordId,
                operation: operation,
                clientVersion: clientVersion,
                payloadJson: payloadJson,
                idempotencyKey: idempotencyKey,
                createdAt: createdAt,
                retryCount: retryCount,
                lastError: lastError,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncQueueTable,
      SyncQueueEntry,
      $$SyncQueueTableFilterComposer,
      $$SyncQueueTableOrderingComposer,
      $$SyncQueueTableAnnotationComposer,
      $$SyncQueueTableCreateCompanionBuilder,
      $$SyncQueueTableUpdateCompanionBuilder,
      (
        SyncQueueEntry,
        BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueEntry>,
      ),
      SyncQueueEntry,
      PrefetchHooks Function()
    >;
typedef $$SyncConflictsTableCreateCompanionBuilder =
    SyncConflictsCompanion Function({
      required String id,
      required String syncEntity,
      required String recordId,
      required String clientPayloadJson,
      required String serverPayloadJson,
      Value<String> resolution,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$SyncConflictsTableUpdateCompanionBuilder =
    SyncConflictsCompanion Function({
      Value<String> id,
      Value<String> syncEntity,
      Value<String> recordId,
      Value<String> clientPayloadJson,
      Value<String> serverPayloadJson,
      Value<String> resolution,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$SyncConflictsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncConflictsTable> {
  $$SyncConflictsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncEntity => $composableBuilder(
    column: $table.syncEntity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientPayloadJson => $composableBuilder(
    column: $table.clientPayloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverPayloadJson => $composableBuilder(
    column: $table.serverPayloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resolution => $composableBuilder(
    column: $table.resolution,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncConflictsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncConflictsTable> {
  $$SyncConflictsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncEntity => $composableBuilder(
    column: $table.syncEntity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientPayloadJson => $composableBuilder(
    column: $table.clientPayloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverPayloadJson => $composableBuilder(
    column: $table.serverPayloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resolution => $composableBuilder(
    column: $table.resolution,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncConflictsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncConflictsTable> {
  $$SyncConflictsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get syncEntity => $composableBuilder(
    column: $table.syncEntity,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recordId =>
      $composableBuilder(column: $table.recordId, builder: (column) => column);

  GeneratedColumn<String> get clientPayloadJson => $composableBuilder(
    column: $table.clientPayloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get serverPayloadJson => $composableBuilder(
    column: $table.serverPayloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get resolution => $composableBuilder(
    column: $table.resolution,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SyncConflictsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncConflictsTable,
          SyncConflictEntry,
          $$SyncConflictsTableFilterComposer,
          $$SyncConflictsTableOrderingComposer,
          $$SyncConflictsTableAnnotationComposer,
          $$SyncConflictsTableCreateCompanionBuilder,
          $$SyncConflictsTableUpdateCompanionBuilder,
          (
            SyncConflictEntry,
            BaseReferences<
              _$AppDatabase,
              $SyncConflictsTable,
              SyncConflictEntry
            >,
          ),
          SyncConflictEntry,
          PrefetchHooks Function()
        > {
  $$SyncConflictsTableTableManager(_$AppDatabase db, $SyncConflictsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncConflictsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncConflictsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncConflictsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> syncEntity = const Value.absent(),
                Value<String> recordId = const Value.absent(),
                Value<String> clientPayloadJson = const Value.absent(),
                Value<String> serverPayloadJson = const Value.absent(),
                Value<String> resolution = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncConflictsCompanion(
                id: id,
                syncEntity: syncEntity,
                recordId: recordId,
                clientPayloadJson: clientPayloadJson,
                serverPayloadJson: serverPayloadJson,
                resolution: resolution,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String syncEntity,
                required String recordId,
                required String clientPayloadJson,
                required String serverPayloadJson,
                Value<String> resolution = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => SyncConflictsCompanion.insert(
                id: id,
                syncEntity: syncEntity,
                recordId: recordId,
                clientPayloadJson: clientPayloadJson,
                serverPayloadJson: serverPayloadJson,
                resolution: resolution,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncConflictsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncConflictsTable,
      SyncConflictEntry,
      $$SyncConflictsTableFilterComposer,
      $$SyncConflictsTableOrderingComposer,
      $$SyncConflictsTableAnnotationComposer,
      $$SyncConflictsTableCreateCompanionBuilder,
      $$SyncConflictsTableUpdateCompanionBuilder,
      (
        SyncConflictEntry,
        BaseReferences<_$AppDatabase, $SyncConflictsTable, SyncConflictEntry>,
      ),
      SyncConflictEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db, _db.products);
  $$InvoicesTableTableManager get invoices =>
      $$InvoicesTableTableManager(_db, _db.invoices);
  $$InvoiceItemsTableTableManager get invoiceItems =>
      $$InvoiceItemsTableTableManager(_db, _db.invoiceItems);
  $$BillNotesTableTableManager get billNotes =>
      $$BillNotesTableTableManager(_db, _db.billNotes);
  $$PaymentsTableTableManager get payments =>
      $$PaymentsTableTableManager(_db, _db.payments);
  $$CustomersTableTableManager get customers =>
      $$CustomersTableTableManager(_db, _db.customers);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$ProductImagesTableTableManager get productImages =>
      $$ProductImagesTableTableManager(_db, _db.productImages);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$DiningTablesTableTableManager get diningTables =>
      $$DiningTablesTableTableManager(_db, _db.diningTables);
  $$KotRecordsTableTableManager get kotRecords =>
      $$KotRecordsTableTableManager(_db, _db.kotRecords);
  $$SyncCursorsTableTableManager get syncCursors =>
      $$SyncCursorsTableTableManager(_db, _db.syncCursors);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
  $$SyncConflictsTableTableManager get syncConflicts =>
      $$SyncConflictsTableTableManager(_db, _db.syncConflicts);
}
