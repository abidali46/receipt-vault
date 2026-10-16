// test/core/storage/app_database_test.dart
//
// Unit tests for the Drift AppDatabase using an in-memory SQLite database.

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_vault/core/storage/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    // Isolated in-memory SQLite database for each test run
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('AppDatabase - Receipts CRUD', () {
    test('starts with an empty receipts table', () async {
      final allReceipts = await db.select(db.receipts).get();
      expect(allReceipts, isEmpty);
    });

    test('can insert and read a receipt with required fields only', () async {
      final purchaseDate = DateTime(2026, 10, 14);
      final id = await db
          .into(db.receipts)
          .insert(
            ReceiptsCompanion.insert(
              productName: 'USB-C Cable',
              purchaseDate: purchaseDate,
              totalAmount: 19.99,
            ),
          );

      expect(id, isPositive);

      final receipt = await (db.select(
        db.receipts,
      )..where((tbl) => tbl.id.equals(id))).getSingle();

      expect(receipt.id, id);
      expect(receipt.productName, 'USB-C Cable');
      expect(receipt.storeName, isNull);
      expect(receipt.category, isNull);
      expect(receipt.purchaseDate, purchaseDate);
      expect(receipt.totalAmount, 19.99);
      expect(receipt.warrantyDurationDays, isNull);
      expect(receipt.notes, isNull);
      expect(receipt.imagePath, isNull);
      expect(receipt.createdAt, isNotNull);
    });

    test(
      'can insert and read a receipt with all optional fields populated',
      () async {
        final purchaseDate = DateTime(2026, 5, 20);
        final id = await db
            .into(db.receipts)
            .insert(
              ReceiptsCompanion.insert(
                productName: 'Samsung Mobile',
                storeName: const Value('Best Buy'),
                category: const Value('Electronics'),
                purchaseDate: purchaseDate,
                totalAmount: 899.00,
                warrantyDurationDays: const Value(365),
                notes: const Value('Purchased with extended protection plan'),
                imagePath: const Value('/data/user/0/receipts/samsung.jpg'),
              ),
            );

        final receipt = await (db.select(
          db.receipts,
        )..where((tbl) => tbl.id.equals(id))).getSingle();

        expect(receipt.id, id);
        expect(receipt.productName, 'Samsung Mobile');
        expect(receipt.storeName, 'Best Buy');
        expect(receipt.category, 'Electronics');
        expect(receipt.purchaseDate, purchaseDate);
        expect(receipt.totalAmount, 899.00);
        expect(receipt.warrantyDurationDays, 365);
        expect(receipt.notes, 'Purchased with extended protection plan');
        expect(receipt.imagePath, '/data/user/0/receipts/samsung.jpg');
      },
    );

    test('can update an existing receipt', () async {
      final id = await db
          .into(db.receipts)
          .insert(
            ReceiptsCompanion.insert(
              productName: 'Coffee Maker',
              storeName: const Value('Target'),
              purchaseDate: DateTime(2026, 8, 1),
              totalAmount: 80.0,
            ),
          );

      // Update total amount, store name, notes, and warranty duration
      final updatedRows =
          await (db.update(
            db.receipts,
          )..where((tbl) => tbl.id.equals(id))).write(
            const ReceiptsCompanion(
              storeName: Value('Target Superstore'),
              totalAmount: Value(75.50),
              notes: Value('Price match applied'),
              warrantyDurationDays: Value(730),
            ),
          );

      expect(updatedRows, 1);

      final updated = await (db.select(
        db.receipts,
      )..where((tbl) => tbl.id.equals(id))).getSingle();

      expect(updated.storeName, 'Target Superstore');
      expect(updated.totalAmount, 75.50);
      expect(updated.notes, 'Price match applied');
      expect(updated.warrantyDurationDays, 730);
      // Product name should remain untouched
      expect(updated.productName, 'Coffee Maker');
    });

    test('can delete a receipt', () async {
      final id = await db
          .into(db.receipts)
          .insert(
            ReceiptsCompanion.insert(
              productName: 'Temporary Item',
              purchaseDate: DateTime(2026, 1, 1),
              totalAmount: 10.0,
            ),
          );

      final countBefore = (await db.select(db.receipts).get()).length;
      expect(countBefore, 1);

      final deletedRows = await (db.delete(
        db.receipts,
      )..where((tbl) => tbl.id.equals(id))).go();
      expect(deletedRows, 1);

      final remaining = await db.select(db.receipts).get();
      expect(remaining, isEmpty);
    });

    test(
      'can query and filter receipts by category and product name',
      () async {
        await db
            .into(db.receipts)
            .insert(
              ReceiptsCompanion.insert(
                productName: 'iPhone 15',
                category: const Value('Electronics'),
                purchaseDate: DateTime(2026, 1, 1),
                totalAmount: 999.0,
              ),
            );
        await db
            .into(db.receipts)
            .insert(
              ReceiptsCompanion.insert(
                productName: 'MacBook Air',
                category: const Value('Electronics'),
                purchaseDate: DateTime(2026, 2, 1),
                totalAmount: 1199.0,
              ),
            );
        await db
            .into(db.receipts)
            .insert(
              ReceiptsCompanion.insert(
                productName: 'Espresso Beans',
                category: const Value('Food'),
                purchaseDate: DateTime(2026, 3, 1),
                totalAmount: 22.0,
              ),
            );

        // Filter by category
        final electronics = await (db.select(
          db.receipts,
        )..where((tbl) => tbl.category.equals('Electronics'))).get();
        expect(electronics.length, 2);

        final food = await (db.select(
          db.receipts,
        )..where((tbl) => tbl.category.equals('Food'))).get();
        expect(food.length, 1);
        expect(food.first.productName, 'Espresso Beans');

        // Filter by product name search
        final searchResult = await (db.select(
          db.receipts,
        )..where((tbl) => tbl.productName.like('%Air%'))).get();
        expect(searchResult.length, 1);
        expect(searchResult.first.productName, 'MacBook Air');
      },
    );

    test('watch table emits stream updates when records change', () async {
      final expectation = expectLater(
        db.select(db.receipts).watch(),
        emitsInOrder([isEmpty, hasLength(1), hasLength(2), hasLength(1)]),
      );

      await pumpEventQueue();

      // Insert 1
      final id1 = await db
          .into(db.receipts)
          .insert(
            ReceiptsCompanion.insert(
              productName: 'Item 1',
              purchaseDate: DateTime(2026, 1, 1),
              totalAmount: 10.0,
            ),
          );

      await pumpEventQueue();

      // Insert 2
      await db
          .into(db.receipts)
          .insert(
            ReceiptsCompanion.insert(
              productName: 'Item 2',
              purchaseDate: DateTime(2026, 1, 2),
              totalAmount: 20.0,
            ),
          );

      await pumpEventQueue();

      // Delete 1
      await (db.delete(db.receipts)..where((tbl) => tbl.id.equals(id1))).go();

      await expectation;
    });
  });
}
