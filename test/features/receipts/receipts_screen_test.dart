// test/features/receipts/receipts_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_vault/app/theme/app_theme.dart';
import 'package:receipt_vault/features/receipts/domain/entities/receipt_card_data.dart';
import 'package:receipt_vault/features/receipts/presentation/receipts_screen.dart';
import 'package:receipt_vault/features/receipts/presentation/widgets/category_filter_row.dart';
import 'package:receipt_vault/features/receipts/presentation/widgets/receipt_card.dart';
import 'package:receipt_vault/features/receipts/presentation/widgets/receipt_search_bar.dart';
import 'package:receipt_vault/features/receipts/presentation/widgets/receipts_empty_state.dart';
import 'package:receipt_vault/shared/enums/warranty_status.dart';

Widget _buildTestApp({
  List<ReceiptCardData> receipts = const [],
  ValueChanged<ReceiptCardData>? onReceiptTap,
}) {
  return MaterialApp(
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: ThemeMode.light,
    home: ReceiptsScreen(receipts: receipts, onReceiptTap: onReceiptTap),
  );
}

void main() {
  group('ReceiptsScreen', () {
    testWidgets(
      'renders header, search bar, category filters, and default empty state',
      (tester) async {
        await tester.pumpWidget(_buildTestApp());

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
  });
}
