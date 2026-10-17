// test/features/receipts/receipts_repository_test.dart

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_vault/core/storage/app_database.dart';
import 'package:receipt_vault/features/receipts/data/repositories/drift_receipts_repository.dart';
import 'package:receipt_vault/features/receipts/domain/entities/receipt_card_data.dart';
import 'package:receipt_vault/features/receipts/domain/services/warranty_calculator.dart';
import 'package:receipt_vault/shared/enums/warranty_status.dart';

void main() {
  group('WarrantyCalculator', () {
    final fixedNow = DateTime(2026, 10, 16);

    test('returns none status when warrantyDurationDays is null or <= 0', () {
      final nullWarranty = WarrantyCalculator.calculate(
        purchaseDate: DateTime(2026, 10, 1),
        warrantyDurationDays: null,
        now: fixedNow,
      );
      expect(nullWarranty.status, WarrantyStatus.none);
      expect(nullWarranty.statusLabel, 'No warranty');
      expect(nullWarranty.remainingDays, isNull);
      expect(nullWarranty.expiryDate, isNull);

      final zeroWarranty = WarrantyCalculator.calculate(
        purchaseDate: DateTime(2026, 10, 1),
        warrantyDurationDays: 0,
        now: fixedNow,
      );
      expect(zeroWarranty.status, WarrantyStatus.none);
      expect(zeroWarranty.statusLabel, 'No warranty');

      final negativeWarranty = WarrantyCalculator.calculate(
        purchaseDate: DateTime(2026, 10, 1),
        warrantyDurationDays: -10,
        now: fixedNow,
      );
      expect(negativeWarranty.status, WarrantyStatus.none);
      expect(negativeWarranty.statusLabel, 'No warranty');
    });

    test('returns expired when expiry date is in the past', () {
      final expired = WarrantyCalculator.calculate(
        purchaseDate: DateTime(2026, 1, 1),
        warrantyDurationDays: 100, // Expires 2026-04-11
        now: fixedNow,
      );
      expect(expired.status, WarrantyStatus.expired);
      expect(expired.statusLabel, 'Expired');
      expect(expired.remainingDays, isNegative);
    });

    test('returns expiringSoon with Expires today when 0 days remain', () {
      final todayExpiry = WarrantyCalculator.calculate(
        purchaseDate: DateTime(2026, 10, 1),
        warrantyDurationDays: 15, // Expires 2026-10-16
        now: fixedNow,
      );
      expect(todayExpiry.status, WarrantyStatus.expiringSoon);
      expect(todayExpiry.statusLabel, 'Expires today');
      expect(todayExpiry.remainingDays, 0);
    });

    test('returns expiringSoon with singular day when 1 day remains', () {
      final oneDay = WarrantyCalculator.calculate(
        purchaseDate: DateTime(2026, 10, 1),
        warrantyDurationDays: 16, // Expires 2026-10-17
        now: fixedNow,
      );
      expect(oneDay.status, WarrantyStatus.expiringSoon);
      expect(oneDay.statusLabel, '1 day left');
      expect(oneDay.remainingDays, 1);
    });

    test('returns expiringSoon for <= 30 days', () {
      final fifteenDays = WarrantyCalculator.calculate(
        purchaseDate: DateTime(2026, 10, 1),
        warrantyDurationDays: 30, // Expires 2026-10-31
        now: fixedNow,
      );
      expect(fifteenDays.status, WarrantyStatus.expiringSoon);
      expect(fifteenDays.statusLabel, '15 days left');
      expect(fifteenDays.remainingDays, 15);

      final thirtyDays = WarrantyCalculator.calculate(
        purchaseDate: DateTime(2026, 10, 1),
        warrantyDurationDays: 45, // Expires 2026-11-15
        now: fixedNow,
      );
      expect(thirtyDays.status, WarrantyStatus.expiringSoon);
      expect(thirtyDays.statusLabel, '30 days left');
      expect(thirtyDays.remainingDays, 30);
    });

    test('returns active with days left when > 30 days and < 365 days', () {
      final thirtyOneDays = WarrantyCalculator.calculate(
        purchaseDate: DateTime(2026, 10, 1),
        warrantyDurationDays: 46, // Expires 2026-11-16
        now: fixedNow,
      );
      expect(thirtyOneDays.status, WarrantyStatus.active);
      expect(thirtyOneDays.statusLabel, '31 days left');
      expect(thirtyOneDays.remainingDays, 31);

      final oneHundredTwentyDays = WarrantyCalculator.calculate(
        purchaseDate: DateTime(2026, 6, 18),
        warrantyDurationDays: 240, // Expires 2027-02-13
        now: fixedNow,
      );
      expect(oneHundredTwentyDays.status, WarrantyStatus.active);
      expect(oneHundredTwentyDays.statusLabel, '120 days left');
      expect(oneHundredTwentyDays.remainingDays, 120);
    });

    test('returns active with years left when >= 365 days', () {
      final oneYear = WarrantyCalculator.calculate(
        purchaseDate: fixedNow,
        warrantyDurationDays: 365,
        now: fixedNow,
      );
      expect(oneYear.status, WarrantyStatus.active);
      expect(oneYear.statusLabel, '1 year left');

      final twoYears = WarrantyCalculator.calculate(
        purchaseDate: fixedNow,
        warrantyDurationDays: 730,
        now: fixedNow,
      );
      expect(twoYears.status, WarrantyStatus.active);
      expect(twoYears.statusLabel, '2 years left');
    });

    test('maps category strings to appropriate icons', () {
      expect(
        WarrantyCalculator.iconForCategory('Electronics'),
        Icons.devices_outlined,
      );
      expect(
        WarrantyCalculator.iconForCategory('Food'),
        Icons.restaurant_outlined,
      );
      expect(
        WarrantyCalculator.iconForCategory('Clothing'),
        Icons.checkroom_outlined,
      );
      expect(
        WarrantyCalculator.iconForCategory('Appliances'),
        Icons.home_outlined,
      );
      expect(
        WarrantyCalculator.iconForCategory('UnknownCategory'),
        Icons.receipt_long_outlined,
      );
      expect(
        WarrantyCalculator.iconForCategory(null),
        Icons.receipt_long_outlined,
      );
    });
  });

  group('ReceiptCardData.fromReceipt', () {
    test('correctly maps database Receipt to presentation model', () {
      final now = DateTime(2026, 10, 16);
      final receipt = Receipt(
        id: 42,
        productName: 'Samsung Mobile',
        storeName: 'Best Buy',
        category: 'Electronics',
        purchaseDate: DateTime(2026, 6, 18),
        totalAmount: 899.0,
        warrantyDurationDays: 240,
        createdAt: DateTime(2026, 6, 18),
      );

      final cardData = ReceiptCardData.fromReceipt(receipt, now: now);

      expect(cardData.id, '42');
      expect(cardData.productName, 'Samsung Mobile');
      expect(cardData.storeName, 'Best Buy');
      expect(cardData.price, 899.0);
      expect(cardData.formattedPrice, '\$899');
      expect(cardData.category, 'Electronics');
      expect(cardData.icon, Icons.devices_outlined);
      expect(cardData.status, WarrantyStatus.active);
      expect(cardData.statusLabel, '120 days left');
    });

    test('defaults missing category to Others and formats float price', () {
      final receipt = Receipt(
        id: 1,
        productName: 'Paper Towels',
        storeName: null,
        category: null,
        purchaseDate: DateTime(2026, 10, 1),
        totalAmount: 14.50,
        warrantyDurationDays: null,
        createdAt: DateTime(2026, 10, 1),
      );

      final cardData = ReceiptCardData.fromReceipt(receipt);

      expect(cardData.category, 'Others');
      expect(cardData.icon, Icons.receipt_long_outlined);
      expect(cardData.formattedPrice, '\$14.50');
      expect(cardData.status, WarrantyStatus.none);
      expect(cardData.statusLabel, 'No warranty');
    });
  });

  group('DriftReceiptsRepository', () {
    late AppDatabase db;
    late DriftReceiptsRepository repository;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repository = DriftReceiptsRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('getAllReceipts returns empty list on fresh database', () async {
      final receipts = await repository.getAllReceipts();
      expect(receipts, isEmpty);
    });

    test(
      'insertReceipt creates record and getReceiptById retrieves it',
      () async {
        final purchaseDate = DateTime(2026, 10, 1);
        final id = await repository.insertReceipt(
          ReceiptsCompanion.insert(
            productName: 'Pixel 9',
            storeName: const Value('Google Store'),
            category: const Value('Electronics'),
            purchaseDate: purchaseDate,
            totalAmount: 799.0,
            warrantyDurationDays: const Value(365),
          ),
        );

        expect(id, isPositive);

        final receipt = await repository.getReceiptById(id);
        expect(receipt, isNotNull);
        expect(receipt!.productName, 'Pixel 9');
        expect(receipt.storeName, 'Google Store');
        expect(receipt.category, 'Electronics');
        expect(receipt.totalAmount, 799.0);
        expect(receipt.warrantyDurationDays, 365);
      },
    );

    test('updateReceipt updates existing record', () async {
      final id = await repository.insertReceipt(
        ReceiptsCompanion.insert(
          productName: 'Original Name',
          purchaseDate: DateTime(2026, 1, 1),
          totalAmount: 50.0,
        ),
      );

      final original = (await repository.getReceiptById(id))!;
      final updated = original.copyWith(
        productName: 'Updated Name',
        totalAmount: 60.0,
      );

      final success = await repository.updateReceipt(updated);
      expect(success, isTrue);

      final fetched = await repository.getReceiptById(id);
      expect(fetched!.productName, 'Updated Name');
      expect(fetched.totalAmount, 60.0);
    });

    test('deleteReceipt removes record from database', () async {
      final id = await repository.insertReceipt(
        ReceiptsCompanion.insert(
          productName: 'To Be Deleted',
          purchaseDate: DateTime(2026, 1, 1),
          totalAmount: 10.0,
        ),
      );

      final count = await repository.deleteReceipt(id);
      expect(count, 1);

      final fetched = await repository.getReceiptById(id);
      expect(fetched, isNull);
    });

    test(
      'watchReceipts and watchReceiptCards emit updates in real time',
      () async {
        final expectation = expectLater(
          repository.watchReceiptCards(),
          emitsInOrder([isEmpty, hasLength(1), hasLength(2), hasLength(1)]),
        );

        await pumpEventQueue();

        // Insert 1
        final id1 = await repository.insertReceipt(
          ReceiptsCompanion.insert(
            productName: 'Item 1',
            purchaseDate: DateTime(2026, 1, 1),
            totalAmount: 20.0,
          ),
        );

        await pumpEventQueue();

        // Insert 2
        await repository.insertReceipt(
          ReceiptsCompanion.insert(
            productName: 'Item 2',
            purchaseDate: DateTime(2026, 2, 1),
            totalAmount: 30.0,
          ),
        );

        await pumpEventQueue();

        // Delete 1
        await repository.deleteReceipt(id1);

        await expectation;
      },
    );

    test('orders receipts by purchaseDate descending', () async {
      await repository.insertReceipt(
        ReceiptsCompanion.insert(
          productName: 'Older Purchase',
          purchaseDate: DateTime(2026, 1, 1),
          totalAmount: 10.0,
        ),
      );

      await repository.insertReceipt(
        ReceiptsCompanion.insert(
          productName: 'Newer Purchase',
          purchaseDate: DateTime(2026, 5, 1),
          totalAmount: 20.0,
        ),
      );

      final list = await repository.getAllReceipts();
      expect(list.first.productName, 'Newer Purchase');
      expect(list.last.productName, 'Older Purchase');
    });

    test('watchReceiptById emits updates reactively on mutations', () async {
      final insertedId = await repository.insertReceipt(
        ReceiptsCompanion.insert(
          productName: 'Original Laptop',
          purchaseDate: DateTime(2026, 1, 1),
          totalAmount: 1000.0,
        ),
      );

      final expectation = expectLater(
        repository.watchReceiptById(insertedId),
        emitsInOrder([
          predicate<Receipt?>((r) => r?.productName == 'Original Laptop'),
          predicate<Receipt?>(
            (r) =>
                r?.productName == 'Updated Laptop' && r?.totalAmount == 1200.0,
          ),
        ]),
      );

      await pumpEventQueue();

      final existing = await repository.getReceiptById(insertedId);
      await repository.updateReceipt(
        existing!.copyWith(productName: 'Updated Laptop', totalAmount: 1200.0),
      );

      await expectation;
    });
  });
}
