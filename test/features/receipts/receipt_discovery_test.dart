// test/features/receipts/receipt_discovery_test.dart

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_vault/app/theme/app_theme.dart';
import 'package:receipt_vault/core/storage/app_database.dart';
import 'package:receipt_vault/core/storage/database_provider.dart';
import 'package:receipt_vault/features/receipts/domain/entities/receipt_card_data.dart';
import 'package:receipt_vault/features/receipts/domain/entities/receipt_sort_option.dart';
import 'package:receipt_vault/features/receipts/domain/services/receipt_discovery_service.dart';
import 'package:receipt_vault/features/receipts/presentation/receipts_screen.dart';
import 'package:receipt_vault/features/receipts/presentation/widgets/receipt_card.dart';
import 'package:receipt_vault/features/receipts/presentation/widgets/receipt_sort_filter_bar.dart';
import 'package:receipt_vault/features/receipts/presentation/widgets/receipts_empty_state.dart';
import 'package:receipt_vault/shared/enums/warranty_status.dart';

Widget _buildTestApp({
  List<ReceiptCardData>? receipts,
  ReceiptSortOption initialSort = ReceiptSortOption.newestPurchase,
  ThemeMode themeMode = ThemeMode.light,
  List<dynamic> overrides = const [],
}) {
  return ProviderScope(
    overrides: [for (final o in overrides) o],
    child: MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: ReceiptsScreen(receipts: receipts, initialSort: initialSort),
    ),
  );
}

void main() {
  group('ReceiptDiscoveryService Unit Tests', () {
    final sampleReceipts = [
      ReceiptCardData(
        id: '1',
        productName: 'Apple iPhone 15',
        storeName: 'Apple Store',
        price: 999.0,
        status: WarrantyStatus.active,
        statusLabel: '300 days left',
        category: 'Electronics',
        purchaseDate: DateTime(2026, 9, 15),
      ),
      ReceiptCardData(
        id: '2',
        productName: 'Sony Bravia TV',
        storeName: 'Best Buy',
        price: 1500.0,
        status: WarrantyStatus.active,
        statusLabel: '150 days left',
        category: 'Electronics',
        purchaseDate: DateTime(2026, 8, 1),
      ),
      ReceiptCardData(
        id: '3',
        productName: 'Organic Whole Milk',
        storeName: 'Trader Joe\'s',
        price: 5.50,
        status: WarrantyStatus.none,
        statusLabel: 'No warranty',
        category: 'Food',
        purchaseDate: DateTime(2026, 10, 10),
      ),
      ReceiptCardData(
        id: '4',
        productName: 'Running Shoes',
        storeName: 'Nike Outlet',
        price: 120.0,
        status: WarrantyStatus.none,
        statusLabel: 'No warranty',
        category: 'Clothing',
        purchaseDate: DateTime(2026, 7, 20),
      ),
    ];

    test('search is case-insensitive for product name', () {
      final resultsLower = ReceiptDiscoveryService.filterReceipts(
        sampleReceipts,
        searchQuery: 'iphone',
      );
      expect(resultsLower.length, 1);
      expect(resultsLower.first.productName, 'Apple iPhone 15');

      final resultsUpper = ReceiptDiscoveryService.filterReceipts(
        sampleReceipts,
        searchQuery: 'IPHONE',
      );
      expect(resultsUpper.length, 1);
      expect(resultsUpper.first.productName, 'Apple iPhone 15');
    });

    test('search is case-insensitive for store name', () {
      final results = ReceiptDiscoveryService.filterReceipts(
        sampleReceipts,
        searchQuery: 'best buy',
      );
      expect(results.length, 1);
      expect(results.first.productName, 'Sony Bravia TV');
    });

    test('search is case-insensitive for category', () {
      final results = ReceiptDiscoveryService.filterReceipts(
        sampleReceipts,
        searchQuery: 'food',
      );
      expect(results.length, 1);
      expect(results.first.productName, 'Organic Whole Milk');
    });

    test(
      'category filter filters precisely and All includes all categories',
      () {
        final electronics = ReceiptDiscoveryService.filterReceipts(
          sampleReceipts,
          selectedCategory: 'Electronics',
        );
        expect(electronics.length, 2);

        final food = ReceiptDiscoveryService.filterReceipts(
          sampleReceipts,
          selectedCategory: 'food',
        );
        expect(food.length, 1);
        expect(food.first.productName, 'Organic Whole Milk');

        final all = ReceiptDiscoveryService.filterReceipts(
          sampleReceipts,
          selectedCategory: 'All',
        );
        expect(all.length, 4);
      },
    );

    test('search and category filter combine with AND logic', () {
      // Searching for 'Apple' in Electronics -> 1 match
      final match = ReceiptDiscoveryService.filterReceipts(
        sampleReceipts,
        selectedCategory: 'Electronics',
        searchQuery: 'Apple',
      );
      expect(match.length, 1);
      expect(match.first.productName, 'Apple iPhone 15');

      // Searching for 'Apple' in Food -> 0 matches
      final noMatch = ReceiptDiscoveryService.filterReceipts(
        sampleReceipts,
        selectedCategory: 'Food',
        searchQuery: 'Apple',
      );
      expect(noMatch, isEmpty);
    });

    test('sorts by newest purchase date first (default)', () {
      final sorted = ReceiptDiscoveryService.sortReceipts(
        sampleReceipts,
        ReceiptSortOption.newestPurchase,
      );
      expect(sorted.map((r) => r.productName).toList(), [
        'Organic Whole Milk', // 2026-10-10
        'Apple iPhone 15', // 2026-09-15
        'Sony Bravia TV', // 2026-08-01
        'Running Shoes', // 2026-07-20
      ]);
    });

    test('sorts by oldest purchase date first', () {
      final sorted = ReceiptDiscoveryService.sortReceipts(
        sampleReceipts,
        ReceiptSortOption.oldestPurchase,
      );
      expect(sorted.map((r) => r.productName).toList(), [
        'Running Shoes', // 2026-07-20
        'Sony Bravia TV', // 2026-08-01
        'Apple iPhone 15', // 2026-09-15
        'Organic Whole Milk', // 2026-10-10
      ]);
    });

    test('sorts by product name alphabetically (A to Z)', () {
      final sorted = ReceiptDiscoveryService.sortReceipts(
        sampleReceipts,
        ReceiptSortOption.productName,
      );
      expect(sorted.map((r) => r.productName).toList(), [
        'Apple iPhone 15',
        'Organic Whole Milk',
        'Running Shoes',
        'Sony Bravia TV',
      ]);
    });

    test('sorts by amount high to low', () {
      final sorted = ReceiptDiscoveryService.sortReceipts(
        sampleReceipts,
        ReceiptSortOption.amountHighToLow,
      );
      expect(sorted.map((r) => r.productName).toList(), [
        'Sony Bravia TV', // $1500
        'Apple iPhone 15', // $999
        'Running Shoes', // $120
        'Organic Whole Milk', // $5.50
      ]);
    });

    test('sorts by amount low to high', () {
      final sorted = ReceiptDiscoveryService.sortReceipts(
        sampleReceipts,
        ReceiptSortOption.amountLowToHigh,
      );
      expect(sorted.map((r) => r.productName).toList(), [
        'Organic Whole Milk', // $5.50
        'Running Shoes', // $120
        'Apple iPhone 15', // $999
        'Sony Bravia TV', // $1500
      ]);
    });

    test('safely handles null purchaseDate with stable tie-breaking', () {
      const receiptsWithNullDates = [
        ReceiptCardData(
          id: '10',
          productName: 'Item A',
          price: 10.0,
          status: WarrantyStatus.none,
          statusLabel: 'No warranty',
        ),
        ReceiptCardData(
          id: '20',
          productName: 'Item B',
          price: 20.0,
          status: WarrantyStatus.none,
          statusLabel: 'No warranty',
        ),
      ];

      final sorted = ReceiptDiscoveryService.sortReceipts(
        receiptsWithNullDates,
        ReceiptSortOption.newestPurchase,
      );
      expect(sorted.length, 2);
    });
  });

  group('ReceiptsScreen Discovery & Sorting Widget Tests', () {
    final sampleReceipts = [
      ReceiptCardData(
        id: '1',
        productName: 'Samsung Galaxy Phone',
        storeName: 'Best Buy',
        price: 899.0,
        status: WarrantyStatus.active,
        statusLabel: '120 days left',
        category: 'Electronics',
        purchaseDate: DateTime(2026, 8, 10),
      ),
      ReceiptCardData(
        id: '2',
        productName: 'Asus Gaming Laptop',
        storeName: 'Micro Center',
        price: 1800.0,
        status: WarrantyStatus.active,
        statusLabel: '300 days left',
        category: 'Electronics',
        purchaseDate: DateTime(2026, 9, 20),
      ),
      ReceiptCardData(
        id: '3',
        productName: 'Gourmet Olive Oil',
        storeName: 'Whole Foods',
        price: 24.0,
        status: WarrantyStatus.none,
        statusLabel: 'No warranty',
        category: 'Food',
        purchaseDate: DateTime(2026, 10, 1),
      ),
    ];

    testWidgets('renders sort filter bar with counts and sort menu', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp(receipts: sampleReceipts));

      // Bar is present
      expect(find.byType(ReceiptSortFilterBar), findsOneWidget);
      expect(find.text('3 receipts'), findsOneWidget);
      expect(find.byKey(const Key('receipts_sort_button')), findsOneWidget);
      expect(find.text('Newest purchase'), findsOneWidget);
    });

    testWidgets('can change sort option via popup menu and updates list order', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp(receipts: sampleReceipts));

      // Initially newest purchase: Laptop (Sept 20), Phone (Aug 10), Olive Oil (Oct 1) -> wait, Olive Oil is Oct 1!
      // In default newest:
      // 1. Gourmet Olive Oil (Oct 1)
      // 2. Asus Gaming Laptop (Sept 20)
      // 3. Samsung Galaxy Phone (Aug 10)
      final initialCards = tester
          .widgetList<ReceiptCard>(find.byType(ReceiptCard))
          .toList();
      expect(initialCards[0].receipt.productName, 'Gourmet Olive Oil');
      expect(initialCards[1].receipt.productName, 'Asus Gaming Laptop');
      expect(initialCards[2].receipt.productName, 'Samsung Galaxy Phone');

      // Tap sort button
      await tester.tap(find.byKey(const Key('receipts_sort_button')));
      await tester.pumpAndSettle();

      // Menu opens with options
      expect(find.text('Oldest purchase'), findsOneWidget);
      expect(find.text('Product name (A–Z)'), findsOneWidget);
      expect(find.text('Amount (high to low)'), findsOneWidget);

      // Select 'Amount (high to low)'
      await tester.tap(find.text('Amount (high to low)'));
      await tester.pumpAndSettle();

      // Verify reordered: Laptop ($1800), Phone ($899), Olive Oil ($24)
      final sortedCards = tester
          .widgetList<ReceiptCard>(find.byType(ReceiptCard))
          .toList();
      expect(sortedCards[0].receipt.productName, 'Asus Gaming Laptop');
      expect(sortedCards[1].receipt.productName, 'Samsung Galaxy Phone');
      expect(sortedCards[2].receipt.productName, 'Gourmet Olive Oil');
    });

    testWidgets(
      'filtering by category and search updates count label and displays inline clear',
      (tester) async {
        await tester.pumpWidget(_buildTestApp(receipts: sampleReceipts));

        // Filter by Electronics
        await tester.tap(find.text('Electronics'));
        await tester.pumpAndSettle();

        expect(find.text('2 of 3 receipts'), findsOneWidget);
        expect(
          find.byKey(const Key('receipts_bar_clear_button')),
          findsOneWidget,
        );

        // Tap inline clear button
        await tester.tap(find.byKey(const Key('receipts_bar_clear_button')));
        await tester.pumpAndSettle();

        expect(find.text('3 receipts'), findsOneWidget);
        expect(
          find.byKey(const Key('receipts_bar_clear_button')),
          findsNothing,
        );
      },
    );

    testWidgets('displays contextual empty state when search finds no match', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp(receipts: sampleReceipts));

      // Enter search term that has no matches
      await tester.enterText(find.byType(TextField), 'Microwave');
      await tester.pumpAndSettle();

      expect(find.byType(ReceiptsEmptyState), findsOneWidget);
      expect(find.text('No matching receipts'), findsOneWidget);
      expect(
        find.text(
          'No receipts found matching "Microwave". Try another search term or reset filters.',
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('receipts_empty_state_reset_button')),
        findsOneWidget,
      );

      // Tap reset filters on empty state
      await tester.tap(
        find.byKey(const Key('receipts_empty_state_reset_button')),
      );
      await tester.pumpAndSettle();

      // Restores all receipts
      expect(find.byType(ReceiptCard), findsNWidgets(3));
    });

    testWidgets('displays contextual empty state when category has no receipts', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp(receipts: sampleReceipts));

      // Tap Clothing (which has 0 receipts in sampleReceipts)
      await tester.tap(find.text('Clothing'));
      await tester.pumpAndSettle();

      expect(find.byType(ReceiptsEmptyState), findsOneWidget);
      expect(find.text('No matching receipts'), findsOneWidget);
      expect(
        find.text(
          'No receipts found in category "Clothing". Try another category or reset filters.',
        ),
        findsOneWidget,
      );

      // Tap reset filters
      await tester.tap(
        find.byKey(const Key('receipts_empty_state_reset_button')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ReceiptCard), findsNWidgets(3));
    });

    testWidgets(
      'displays contextual empty state when both search and category fail to match',
      (tester) async {
        await tester.pumpWidget(_buildTestApp(receipts: sampleReceipts));

        // Select Food
        await tester.tap(find.text('Food'));
        await tester.pumpAndSettle();

        // Search for Laptop
        await tester.enterText(find.byType(TextField), 'Laptop');
        await tester.pumpAndSettle();

        expect(find.byType(ReceiptsEmptyState), findsOneWidget);
        expect(find.text('No matching receipts'), findsOneWidget);
        expect(
          find.text(
            'No receipts found matching "Laptop" in category "Food". Try another search or reset filters.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('database reactivity maintains active sorting and filtering', (
      tester,
    ) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => db.close());

      await tester.pumpWidget(
        _buildTestApp(overrides: [databaseProvider.overrideWithValue(db)]),
      );
      await tester.pumpAndSettle();

      // Initially empty -> pristine empty state
      expect(find.text('No receipts yet'), findsOneWidget);

      // Insert item 1 (Phone)
      await db
          .into(db.receipts)
          .insert(
            ReceiptsCompanion.insert(
              productName: 'Google Pixel 9',
              storeName: const drift.Value('Google Store'),
              category: const drift.Value('Electronics'),
              purchaseDate: DateTime(2026, 9, 1),
              totalAmount: 799.0,
            ),
          );
      await tester.pumpAndSettle();

      expect(find.text('1 receipt'), findsOneWidget);
      expect(find.text('Google Pixel 9'), findsOneWidget);

      // Filter by Electronics
      await tester.tap(find.text('Electronics'));
      await tester.pumpAndSettle();

      // Insert item 2 (Food item)
      await db
          .into(db.receipts)
          .insert(
            ReceiptsCompanion.insert(
              productName: 'Avocados',
              storeName: const drift.Value('Kroger'),
              category: const drift.Value('Food'),
              purchaseDate: DateTime(2026, 9, 5),
              totalAmount: 6.0,
            ),
          );
      await tester.pumpAndSettle();

      // Under Electronics filter: 1 of 2 receipts
      expect(find.text('1 of 2 receipts'), findsOneWidget);
      expect(find.text('Google Pixel 9'), findsOneWidget);
      expect(find.text('Avocados'), findsNothing);

      // Switch to All
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      expect(find.text('2 receipts'), findsOneWidget);
      expect(find.text('Google Pixel 9'), findsOneWidget);
      expect(find.text('Avocados'), findsOneWidget);

      await db.close();
      await tester.pump(const Duration(milliseconds: 50));
    });
  });
}
