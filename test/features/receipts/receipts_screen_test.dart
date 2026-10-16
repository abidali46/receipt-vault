// test/features/receipts/receipts_screen_test.dart

import 'dart:async';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_vault/app/theme/app_theme.dart';
import 'package:receipt_vault/core/storage/app_database.dart';
import 'package:receipt_vault/core/storage/database_provider.dart';
import 'package:receipt_vault/features/receipts/domain/entities/receipt_card_data.dart';
import 'package:receipt_vault/features/receipts/presentation/providers/receipts_providers.dart';
import 'package:receipt_vault/features/receipts/presentation/receipts_screen.dart';
import 'package:receipt_vault/features/receipts/presentation/widgets/category_filter_row.dart';
import 'package:receipt_vault/features/receipts/presentation/widgets/receipt_card.dart';
import 'package:receipt_vault/features/receipts/presentation/widgets/receipt_search_bar.dart';
import 'package:receipt_vault/features/receipts/presentation/widgets/receipts_empty_state.dart';
import 'package:receipt_vault/shared/enums/warranty_status.dart';

final class _TestErrorObserver extends ProviderObserver {
  @override
  void providerDidFail(Object provider, Object error, StackTrace stackTrace) {
    // Absorbs error so it doesn't propagate as uncaught zone error in flutter_test
  }
}

Widget _buildTestApp({
  List<ReceiptCardData>? receipts,
  ValueChanged<ReceiptCardData>? onReceiptTap,
  ThemeMode themeMode = ThemeMode.light,
  List<dynamic> overrides = const [],
  List<ProviderObserver>? observers,
}) {
  return ProviderScope(
    overrides: [for (final o in overrides) o],
    observers: observers,
    child: MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: ReceiptsScreen(receipts: receipts, onReceiptTap: onReceiptTap),
    ),
  );
}

void main() {
  group('ReceiptsScreen', () {
    testWidgets(
      'renders header, search bar, category filters, and default empty state',
      (tester) async {
        await tester.pumpWidget(_buildTestApp(receipts: const []));

        // Header
        expect(find.text('My Receipts'), findsOneWidget);
        expect(find.byIcon(Icons.receipt_long_outlined), findsWidgets);
        expect(find.byIcon(Icons.more_vert), findsOneWidget);

        // Search Bar
        expect(find.byType(ReceiptSearchBar), findsOneWidget);
        expect(
          find.text('Search receipts, items, or stores...'),
          findsOneWidget,
        );

        // Category filter chips
        expect(find.byType(CategoryFilterRow), findsOneWidget);
        expect(find.text('All'), findsOneWidget);
        expect(find.text('Electronics'), findsOneWidget);
        expect(find.text('Food'), findsOneWidget);
        expect(find.text('Others'), findsOneWidget);

        // Empty state (since default receipts list is empty)
        expect(find.byType(ReceiptsEmptyState), findsOneWidget);
        expect(find.text('No receipts yet'), findsOneWidget);
        expect(
          find.text(
            'Receipts you capture will appear here. Tap + to add your first receipt.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('displays receipt cards when receipts are provided', (
      tester,
    ) async {
      const sampleReceipts = [
        ReceiptCardData(
          id: '1',
          productName: 'Samsung Mobile',
          storeName: 'Best Buy',
          price: 899.0,
          status: WarrantyStatus.active,
          statusLabel: '120 days left',
          category: 'Electronics',
          icon: Icons.smartphone_outlined,
        ),
        ReceiptCardData(
          id: '2',
          productName: 'Sony Headphones',
          storeName: 'Walmart',
          price: 250.0,
          status: WarrantyStatus.expired,
          statusLabel: 'Expired',
          category: 'Electronics',
          icon: Icons.headphones_outlined,
        ),
      ];

      await tester.pumpWidget(_buildTestApp(receipts: sampleReceipts));

      // Receipt cards should be displayed
      expect(find.byType(ReceiptCard), findsNWidgets(2));
      expect(find.text('Samsung Mobile'), findsOneWidget);
      expect(find.text('Best Buy'), findsOneWidget);
      expect(find.text('\$899'), findsOneWidget);
      expect(find.text('120 days left'), findsOneWidget);

      expect(find.text('Sony Headphones'), findsOneWidget);
      expect(find.text('Walmart'), findsOneWidget);
      expect(find.text('\$250'), findsOneWidget);
      expect(find.text('Expired'), findsOneWidget);

      // Empty state should not be visible
      expect(find.byType(ReceiptsEmptyState), findsNothing);
    });

    testWidgets('filters receipts when category chip is tapped', (
      tester,
    ) async {
      const sampleReceipts = [
        ReceiptCardData(
          id: '1',
          productName: 'HP Laptop',
          storeName: 'Amazon',
          price: 1200.0,
          status: WarrantyStatus.active,
          statusLabel: '2 years left',
          category: 'Electronics',
        ),
        ReceiptCardData(
          id: '2',
          productName: 'Organic Coffee Beans',
          storeName: 'Whole Foods',
          price: 18.0,
          status: WarrantyStatus.none,
          statusLabel: 'No warranty',
          category: 'Food',
        ),
      ];

      await tester.pumpWidget(_buildTestApp(receipts: sampleReceipts));

      // Both receipts shown under "All"
      expect(find.text('HP Laptop'), findsOneWidget);
      expect(find.text('Organic Coffee Beans'), findsOneWidget);

      // Tap "Food"
      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();

      // Only Food receipt shown
      expect(find.text('HP Laptop'), findsNothing);
      expect(find.text('Organic Coffee Beans'), findsOneWidget);

      // Tap "Others" -> zero matching, shows filtered empty state
      await tester.tap(find.text('Others'));
      await tester.pumpAndSettle();

      expect(find.text('No matching receipts'), findsOneWidget);
      expect(find.text('Reset filters'), findsOneWidget);

      // Tap "Reset filters"
      await tester.tap(find.text('Reset filters'));
      await tester.pumpAndSettle();

      // Restored back to "All"
      expect(find.text('HP Laptop'), findsOneWidget);
      expect(find.text('Organic Coffee Beans'), findsOneWidget);
    });

    testWidgets('filters receipts by search query', (tester) async {
      const sampleReceipts = [
        ReceiptCardData(
          id: '1',
          productName: 'Samsung Mobile',
          storeName: 'Best Buy',
          price: 899.0,
          status: WarrantyStatus.active,
          statusLabel: '120 days left',
        ),
        ReceiptCardData(
          id: '2',
          productName: 'Coffee Maker',
          storeName: 'Target',
          price: 80.0,
          status: WarrantyStatus.expiringSoon,
          statusLabel: '15 days left',
        ),
      ];

      await tester.pumpWidget(_buildTestApp(receipts: sampleReceipts));

      // Enter search term
      await tester.enterText(find.byType(TextField), 'Samsung');
      await tester.pumpAndSettle();

      expect(find.text('Samsung Mobile'), findsOneWidget);
      expect(find.text('Coffee Maker'), findsNothing);

      // Clear search via clear icon
      expect(find.byIcon(Icons.close), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Samsung Mobile'), findsOneWidget);
      expect(find.text('Coffee Maker'), findsOneWidget);
    });

    testWidgets('tapping receipt card triggers onReceiptTap callback', (
      tester,
    ) async {
      ReceiptCardData? tappedReceipt;

      const sampleReceipts = [
        ReceiptCardData(
          id: '1',
          productName: 'Samsung Mobile',
          price: 899.0,
          status: WarrantyStatus.active,
          statusLabel: '120 days left',
        ),
      ];

      await tester.pumpWidget(
        _buildTestApp(
          receipts: sampleReceipts,
          onReceiptTap: (receipt) => tappedReceipt = receipt,
        ),
      );

      await tester.tap(find.text('Samsung Mobile'));
      await tester.pumpAndSettle();

      expect(tappedReceipt, isNotNull);
      expect(tappedReceipt?.id, '1');
    });

    testWidgets(
      'functions correctly in dark mode with search, category filter, and reset',
      (tester) async {
        const sampleReceipts = [
          ReceiptCardData(
            id: '1',
            productName: 'Samsung Mobile',
            storeName: 'Best Buy',
            price: 899.0,
            status: WarrantyStatus.active,
            statusLabel: '120 days left',
            category: 'Electronics',
          ),
          ReceiptCardData(
            id: '2',
            productName: 'Organic Coffee Beans',
            storeName: 'Whole Foods',
            price: 18.0,
            status: WarrantyStatus.none,
            statusLabel: 'No warranty',
            category: 'Food',
          ),
        ];

        await tester.pumpWidget(
          _buildTestApp(receipts: sampleReceipts, themeMode: ThemeMode.dark),
        );

        // Verify initial render under dark theme
        expect(find.text('My Receipts'), findsOneWidget);
        expect(find.text('Samsung Mobile'), findsOneWidget);
        expect(find.text('Organic Coffee Beans'), findsOneWidget);

        // Filter by category in dark mode
        await tester.tap(find.text('Food'));
        await tester.pumpAndSettle();
        expect(find.text('Samsung Mobile'), findsNothing);
        expect(find.text('Organic Coffee Beans'), findsOneWidget);

        // Filter by search query in dark mode
        await tester.enterText(find.byType(TextField), 'Beans');
        await tester.pumpAndSettle();
        expect(find.text('Organic Coffee Beans'), findsOneWidget);

        // Search non-existent item in dark mode -> shows filtered empty state
        await tester.enterText(find.byType(TextField), 'NonExistent');
        await tester.pumpAndSettle();
        expect(find.text('No matching receipts'), findsOneWidget);
        expect(find.text('Reset filters'), findsOneWidget);

        // Reset filters restores all items in dark mode
        await tester.tap(find.text('Reset filters'));
        await tester.pumpAndSettle();
        expect(find.text('Samsung Mobile'), findsOneWidget);
        expect(find.text('Organic Coffee Beans'), findsOneWidget);
      },
    );

    testWidgets(
      'shows loading indicator on initial stream load without prematurely showing empty state',
      (tester) async {
        final controller = StreamController<List<ReceiptCardData>>();
        addTearDown(() => controller.close());

        await tester.pumpWidget(
          _buildTestApp(
            overrides: [
              receiptsStreamProvider.overrideWith((ref) => controller.stream),
            ],
          ),
        );

        // Verify loading indicator is displayed
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        // Important: Empty state must NOT be visible while initial query is loading
        expect(find.byType(ReceiptsEmptyState), findsNothing);

        // Emit empty receipts list
        controller.add(const []);
        await tester.pump();

        // Loading is gone, empty state is now displayed
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.byType(ReceiptsEmptyState), findsOneWidget);
      },
    );

    testWidgets(
      'shows error UI when receiptsStreamProvider encounters an error',
      (tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            observers: [_TestErrorObserver()],
            overrides: [
              receiptsStreamProvider.overrideWith(
                (ref) => Stream<List<ReceiptCardData>>.fromFuture(
                  Future.error('Database connection failed'),
                ),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Failed to load receipts'), findsOneWidget);
        expect(find.text('Database connection failed'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
        expect(find.byType(ReceiptsEmptyState), findsNothing);
      },
    );

    testWidgets(
      'connects to database stream and reactively updates UI on database changes',
      (tester) async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(() => db.close());

        await tester.pumpWidget(
          _buildTestApp(overrides: [databaseProvider.overrideWithValue(db)]),
        );
        await tester.pumpAndSettle();

        // Initially database has no records -> pristine empty state
        expect(find.byType(ReceiptsEmptyState), findsOneWidget);
        expect(find.text('No receipts yet'), findsOneWidget);

        // Insert first record into Drift database
        await db
            .into(db.receipts)
            .insert(
              ReceiptsCompanion.insert(
                productName: 'Nintendo Switch',
                storeName: const drift.Value('Gamestop'),
                category: const drift.Value('Electronics'),
                purchaseDate: DateTime(2026, 10, 1),
                totalAmount: 299.99,
                warrantyDurationDays: const drift.Value(365),
              ),
            );
        await tester.pumpAndSettle();

        // The reactive stream updates the UI automatically
        expect(find.byType(ReceiptCard), findsOneWidget);
        expect(find.text('Nintendo Switch'), findsOneWidget);
        expect(find.text('Gamestop'), findsOneWidget);
        expect(find.text('\$299.99'), findsOneWidget);
        expect(find.byType(ReceiptsEmptyState), findsNothing);

        // Insert second record
        await db
            .into(db.receipts)
            .insert(
              ReceiptsCompanion.insert(
                productName: 'Organic Milk',
                storeName: const drift.Value('Aldi'),
                category: const drift.Value('Food'),
                purchaseDate: DateTime(2026, 10, 5),
                totalAmount: 4.50,
              ),
            );
        await tester.pumpAndSettle();

        // Both cards now present
        expect(find.byType(ReceiptCard), findsNWidgets(2));
        expect(find.text('Nintendo Switch'), findsOneWidget);
        expect(find.text('Organic Milk'), findsOneWidget);

        // Test category filter against database stream data
        await tester.tap(find.text('Food'));
        await tester.pumpAndSettle();

        expect(find.text('Nintendo Switch'), findsNothing);
        expect(find.text('Organic Milk'), findsOneWidget);

        // Dispose db and pump to clear Drift query stream debounce timer
        await db.close();
        await tester.pump(const Duration(milliseconds: 50));
      },
    );
  });
}
