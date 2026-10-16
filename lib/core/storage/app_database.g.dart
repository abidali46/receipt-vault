// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ReceiptsTable extends Receipts with TableInfo<$ReceiptsTable, Receipt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReceiptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
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
  static const VerificationMeta _storeNameMeta = const VerificationMeta(
    'storeName',
  );
  @override
  late final GeneratedColumn<String> storeName = GeneratedColumn<String>(
    'store_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _purchaseDateMeta = const VerificationMeta(
    'purchaseDate',
  );
  @override
  late final GeneratedColumn<DateTime> purchaseDate = GeneratedColumn<DateTime>(
    'purchase_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalAmountMeta = const VerificationMeta(
    'totalAmount',
  );
  @override
  late final GeneratedColumn<double> totalAmount = GeneratedColumn<double>(
    'total_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _warrantyDurationDaysMeta =
      const VerificationMeta('warrantyDurationDays');
  @override
  late final GeneratedColumn<int> warrantyDurationDays = GeneratedColumn<int>(
    'warranty_duration_days',
    aliasedName,
    true,
    type: DriftSqlType.int,
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
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    productName,
    storeName,
    category,
    purchaseDate,
    totalAmount,
    warrantyDurationDays,
    notes,
    imagePath,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'receipts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Receipt> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
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
    if (data.containsKey('store_name')) {
      context.handle(
        _storeNameMeta,
        storeName.isAcceptableOrUnknown(data['store_name']!, _storeNameMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('purchase_date')) {
      context.handle(
        _purchaseDateMeta,
        purchaseDate.isAcceptableOrUnknown(
          data['purchase_date']!,
          _purchaseDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_purchaseDateMeta);
    }
    if (data.containsKey('total_amount')) {
      context.handle(
        _totalAmountMeta,
        totalAmount.isAcceptableOrUnknown(
          data['total_amount']!,
          _totalAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalAmountMeta);
    }
    if (data.containsKey('warranty_duration_days')) {
      context.handle(
        _warrantyDurationDaysMeta,
        warrantyDurationDays.isAcceptableOrUnknown(
          data['warranty_duration_days']!,
          _warrantyDurationDaysMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Receipt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Receipt(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      productName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_name'],
      )!,
      storeName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_name'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      purchaseDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}purchase_date'],
      )!,
      totalAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_amount'],
      )!,
      warrantyDurationDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}warranty_duration_days'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ReceiptsTable createAlias(String alias) {
    return $ReceiptsTable(attachedDatabase, alias);
  }
}

class Receipt extends DataClass implements Insertable<Receipt> {
  final int id;
  final String productName;
  final String? storeName;
  final String? category;
  final DateTime purchaseDate;
  final double totalAmount;
  final int? warrantyDurationDays;
  final String? notes;
  final String? imagePath;
  final DateTime createdAt;
  const Receipt({
    required this.id,
    required this.productName,
    this.storeName,
    this.category,
    required this.purchaseDate,
    required this.totalAmount,
    this.warrantyDurationDays,
    this.notes,
    this.imagePath,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['product_name'] = Variable<String>(productName);
    if (!nullToAbsent || storeName != null) {
      map['store_name'] = Variable<String>(storeName);
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    map['purchase_date'] = Variable<DateTime>(purchaseDate);
    map['total_amount'] = Variable<double>(totalAmount);
    if (!nullToAbsent || warrantyDurationDays != null) {
      map['warranty_duration_days'] = Variable<int>(warrantyDurationDays);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ReceiptsCompanion toCompanion(bool nullToAbsent) {
    return ReceiptsCompanion(
      id: Value(id),
      productName: Value(productName),
      storeName: storeName == null && nullToAbsent
          ? const Value.absent()
          : Value(storeName),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      purchaseDate: Value(purchaseDate),
      totalAmount: Value(totalAmount),
      warrantyDurationDays: warrantyDurationDays == null && nullToAbsent
          ? const Value.absent()
          : Value(warrantyDurationDays),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      createdAt: Value(createdAt),
    );
  }

  factory Receipt.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Receipt(
      id: serializer.fromJson<int>(json['id']),
      productName: serializer.fromJson<String>(json['productName']),
      storeName: serializer.fromJson<String?>(json['storeName']),
      category: serializer.fromJson<String?>(json['category']),
      purchaseDate: serializer.fromJson<DateTime>(json['purchaseDate']),
      totalAmount: serializer.fromJson<double>(json['totalAmount']),
      warrantyDurationDays: serializer.fromJson<int?>(
        json['warrantyDurationDays'],
      ),
      notes: serializer.fromJson<String?>(json['notes']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'productName': serializer.toJson<String>(productName),
      'storeName': serializer.toJson<String?>(storeName),
      'category': serializer.toJson<String?>(category),
      'purchaseDate': serializer.toJson<DateTime>(purchaseDate),
      'totalAmount': serializer.toJson<double>(totalAmount),
      'warrantyDurationDays': serializer.toJson<int?>(warrantyDurationDays),
      'notes': serializer.toJson<String?>(notes),
      'imagePath': serializer.toJson<String?>(imagePath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Receipt copyWith({
    int? id,
    String? productName,
    Value<String?> storeName = const Value.absent(),
    Value<String?> category = const Value.absent(),
    DateTime? purchaseDate,
    double? totalAmount,
    Value<int?> warrantyDurationDays = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<String?> imagePath = const Value.absent(),
    DateTime? createdAt,
  }) => Receipt(
    id: id ?? this.id,
    productName: productName ?? this.productName,
    storeName: storeName.present ? storeName.value : this.storeName,
    category: category.present ? category.value : this.category,
    purchaseDate: purchaseDate ?? this.purchaseDate,
    totalAmount: totalAmount ?? this.totalAmount,
    warrantyDurationDays: warrantyDurationDays.present
        ? warrantyDurationDays.value
        : this.warrantyDurationDays,
    notes: notes.present ? notes.value : this.notes,
    imagePath: imagePath.present ? imagePath.value : this.imagePath,
    createdAt: createdAt ?? this.createdAt,
  );
  Receipt copyWithCompanion(ReceiptsCompanion data) {
    return Receipt(
      id: data.id.present ? data.id.value : this.id,
      productName: data.productName.present
          ? data.productName.value
          : this.productName,
      storeName: data.storeName.present ? data.storeName.value : this.storeName,
      category: data.category.present ? data.category.value : this.category,
      purchaseDate: data.purchaseDate.present
          ? data.purchaseDate.value
          : this.purchaseDate,
      totalAmount: data.totalAmount.present
          ? data.totalAmount.value
          : this.totalAmount,
      warrantyDurationDays: data.warrantyDurationDays.present
          ? data.warrantyDurationDays.value
          : this.warrantyDurationDays,
      notes: data.notes.present ? data.notes.value : this.notes,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Receipt(')
          ..write('id: $id, ')
          ..write('productName: $productName, ')
          ..write('storeName: $storeName, ')
          ..write('category: $category, ')
          ..write('purchaseDate: $purchaseDate, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('warrantyDurationDays: $warrantyDurationDays, ')
          ..write('notes: $notes, ')
          ..write('imagePath: $imagePath, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    productName,
    storeName,
    category,
    purchaseDate,
    totalAmount,
    warrantyDurationDays,
    notes,
    imagePath,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Receipt &&
          other.id == this.id &&
          other.productName == this.productName &&
          other.storeName == this.storeName &&
          other.category == this.category &&
          other.purchaseDate == this.purchaseDate &&
          other.totalAmount == this.totalAmount &&
          other.warrantyDurationDays == this.warrantyDurationDays &&
          other.notes == this.notes &&
          other.imagePath == this.imagePath &&
          other.createdAt == this.createdAt);
}

class ReceiptsCompanion extends UpdateCompanion<Receipt> {
  final Value<int> id;
  final Value<String> productName;
  final Value<String?> storeName;
  final Value<String?> category;
  final Value<DateTime> purchaseDate;
  final Value<double> totalAmount;
  final Value<int?> warrantyDurationDays;
  final Value<String?> notes;
  final Value<String?> imagePath;
  final Value<DateTime> createdAt;
  const ReceiptsCompanion({
    this.id = const Value.absent(),
    this.productName = const Value.absent(),
    this.storeName = const Value.absent(),
    this.category = const Value.absent(),
    this.purchaseDate = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.warrantyDurationDays = const Value.absent(),
    this.notes = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ReceiptsCompanion.insert({
    this.id = const Value.absent(),
    required String productName,
    this.storeName = const Value.absent(),
    this.category = const Value.absent(),
    required DateTime purchaseDate,
    required double totalAmount,
    this.warrantyDurationDays = const Value.absent(),
    this.notes = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : productName = Value(productName),
       purchaseDate = Value(purchaseDate),
       totalAmount = Value(totalAmount);
  static Insertable<Receipt> custom({
    Expression<int>? id,
    Expression<String>? productName,
    Expression<String>? storeName,
    Expression<String>? category,
    Expression<DateTime>? purchaseDate,
    Expression<double>? totalAmount,
    Expression<int>? warrantyDurationDays,
    Expression<String>? notes,
    Expression<String>? imagePath,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productName != null) 'product_name': productName,
      if (storeName != null) 'store_name': storeName,
      if (category != null) 'category': category,
      if (purchaseDate != null) 'purchase_date': purchaseDate,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (warrantyDurationDays != null)
        'warranty_duration_days': warrantyDurationDays,
      if (notes != null) 'notes': notes,
      if (imagePath != null) 'image_path': imagePath,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ReceiptsCompanion copyWith({
    Value<int>? id,
    Value<String>? productName,
    Value<String?>? storeName,
    Value<String?>? category,
    Value<DateTime>? purchaseDate,
    Value<double>? totalAmount,
    Value<int?>? warrantyDurationDays,
    Value<String?>? notes,
    Value<String?>? imagePath,
    Value<DateTime>? createdAt,
  }) {
    return ReceiptsCompanion(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      storeName: storeName ?? this.storeName,
      category: category ?? this.category,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      totalAmount: totalAmount ?? this.totalAmount,
      warrantyDurationDays: warrantyDurationDays ?? this.warrantyDurationDays,
      notes: notes ?? this.notes,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (storeName.present) {
      map['store_name'] = Variable<String>(storeName.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (purchaseDate.present) {
      map['purchase_date'] = Variable<DateTime>(purchaseDate.value);
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<double>(totalAmount.value);
    }
    if (warrantyDurationDays.present) {
      map['warranty_duration_days'] = Variable<int>(warrantyDurationDays.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReceiptsCompanion(')
          ..write('id: $id, ')
          ..write('productName: $productName, ')
          ..write('storeName: $storeName, ')
          ..write('category: $category, ')
          ..write('purchaseDate: $purchaseDate, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('warrantyDurationDays: $warrantyDurationDays, ')
          ..write('notes: $notes, ')
          ..write('imagePath: $imagePath, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ReceiptsTable receipts = $ReceiptsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [receipts];
}

typedef $$ReceiptsTableCreateCompanionBuilder =
    ReceiptsCompanion Function({
      Value<int> id,
      required String productName,
      Value<String?> storeName,
      Value<String?> category,
      required DateTime purchaseDate,
      required double totalAmount,
      Value<int?> warrantyDurationDays,
      Value<String?> notes,
      Value<String?> imagePath,
      Value<DateTime> createdAt,
    });
typedef $$ReceiptsTableUpdateCompanionBuilder =
    ReceiptsCompanion Function({
      Value<int> id,
      Value<String> productName,
      Value<String?> storeName,
      Value<String?> category,
      Value<DateTime> purchaseDate,
      Value<double> totalAmount,
      Value<int?> warrantyDurationDays,
      Value<String?> notes,
      Value<String?> imagePath,
      Value<DateTime> createdAt,
    });

class $$ReceiptsTableFilterComposer
    extends Composer<_$AppDatabase, $ReceiptsTable> {
  $$ReceiptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storeName => $composableBuilder(
    column: $table.storeName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get warrantyDurationDays => $composableBuilder(
    column: $table.warrantyDurationDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReceiptsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReceiptsTable> {
  $$ReceiptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storeName => $composableBuilder(
    column: $table.storeName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get warrantyDurationDays => $composableBuilder(
    column: $table.warrantyDurationDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReceiptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReceiptsTable> {
  $$ReceiptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get storeName =>
      $composableBuilder(column: $table.storeName, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<DateTime> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get warrantyDurationDays => $composableBuilder(
    column: $table.warrantyDurationDays,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ReceiptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReceiptsTable,
          Receipt,
          $$ReceiptsTableFilterComposer,
          $$ReceiptsTableOrderingComposer,
          $$ReceiptsTableAnnotationComposer,
          $$ReceiptsTableCreateCompanionBuilder,
          $$ReceiptsTableUpdateCompanionBuilder,
          (Receipt, BaseReferences<_$AppDatabase, $ReceiptsTable, Receipt>),
          Receipt,
          PrefetchHooks Function()
        > {
  $$ReceiptsTableTableManager(_$AppDatabase db, $ReceiptsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReceiptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReceiptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReceiptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> productName = const Value.absent(),
                Value<String?> storeName = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<DateTime> purchaseDate = const Value.absent(),
                Value<double> totalAmount = const Value.absent(),
                Value<int?> warrantyDurationDays = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ReceiptsCompanion(
                id: id,
                productName: productName,
                storeName: storeName,
                category: category,
                purchaseDate: purchaseDate,
                totalAmount: totalAmount,
                warrantyDurationDays: warrantyDurationDays,
                notes: notes,
                imagePath: imagePath,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String productName,
                Value<String?> storeName = const Value.absent(),
                Value<String?> category = const Value.absent(),
                required DateTime purchaseDate,
                required double totalAmount,
                Value<int?> warrantyDurationDays = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ReceiptsCompanion.insert(
                id: id,
                productName: productName,
                storeName: storeName,
                category: category,
                purchaseDate: purchaseDate,
                totalAmount: totalAmount,
                warrantyDurationDays: warrantyDurationDays,
                notes: notes,
                imagePath: imagePath,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReceiptsTable, Receipt>(table),
                  BaseReferences<_$AppDatabase, $ReceiptsTable, Receipt>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReceiptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReceiptsTable,
      Receipt,
      $$ReceiptsTableFilterComposer,
      $$ReceiptsTableOrderingComposer,
      $$ReceiptsTableAnnotationComposer,
      $$ReceiptsTableCreateCompanionBuilder,
      $$ReceiptsTableUpdateCompanionBuilder,
      (Receipt, BaseReferences<_$AppDatabase, $ReceiptsTable, Receipt>),
      Receipt,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ReceiptsTableTableManager get receipts =>
      $$ReceiptsTableTableManager(_db, _db.receipts);
}
