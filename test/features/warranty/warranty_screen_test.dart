// test/features/warranty/warranty_screen_test.dart

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:receipt_vault/app/router/app_router.dart';
import 'package:receipt_vault/app/theme/app_theme.dart';
import 'package:receipt_vault/core/storage/app_database.dart';
import 'package:receipt_vault/core/storage/database_provider.dart';
import 'package:receipt_vault/features/receipts/domain/services/warranty_calculator.dart';
import 'package:receipt_vault/features/warranty/domain/entities/warranty_item.dart';
import 'package:receipt_vault/features/warranty/presentation/providers/warranty_providers.dart';
import 'package:receipt_vault/features/warranty/presentation/warranty_screen.dart';
import 'package:receipt_vault/features/warranty/presentation/widgets/warranty_card.dart';
import 'package:receipt_vault/features/warranty/presentation/widgets/warranty_empty_state.dart';
import 'package:receipt_vault/shared/enums/warranty_status.dart';

Widget _buildTestApp({
  List<WarrantyItem>? initialItems,
  AppDatabase? db,
  ThemeMode themeMode = ThemeMode.light,
  NavigatorObserver? navigatorObserver,
}) {
  return ProviderScope(
    overrides: [if (db != null) databaseProvider.overrideWithValue(db)],
    child: MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      navigatorObservers: [?navigatorObserver],
      home: WarrantyScreen(initialItems: initialItems),
    ),
  );
}

String _formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

Receipt _createReceipt({
  required int id,
  required String productName,
  String? storeName,
  String? category,
  required DateTime purchaseDate,
  required double totalAmount,
  int? warrantyDurationDays,
}) {
  return Receipt(
    id: id,
    productName: productName,
    storeName: storeName,
    category: category,
    purchaseDate: purchaseDate,
    totalAmount: totalAmount,
    warrantyDurationDays: warrantyDurationDays,
    notes: null,
    imagePath: null,
    createdAt: DateTime.now(),
  );
}

void main() {
  group('WarrantyCalculator Progress & Sorting', () {
    final fixedNow = DateTime(2026, 10, 16);

    test('calculates correct progress ratio for active warranties', () {
      // 150 total days, purchased 30 days ago => 120 days left => 120 / 150 = 0.8 (80%)
      final purchaseDate = fixedNow.subtract(const Duration(days: 30));
      final info = WarrantyCalculator.calculate(
        purchaseDate: purchaseDate,
        warrantyDurationDays: 150,
        now: fixedNow,
      );

      expect(info.status, WarrantyStatus.active);
      expect(info.remainingDays, 120);
      expect(info.progress, closeTo(0.8, 0.001));
    });

    test('calculates correct progress ratio for expiring soon warranties', () {
      // 75 total days, purchased 60 days ago => 15 days left => 15 / 75 = 0.2 (20%)
      final purchaseDate = fixedNow.subtract(const Duration(days: 60));
      final info = WarrantyCalculator.calculate(
        purchaseDate: purchaseDate,
        warrantyDurationDays: 75,
        now: fixedNow,
      );

      expect(info.status, WarrantyStatus.expiringSoon);
      expect(info.remainingDays, 15);
      expect(info.progress, closeTo(0.2, 0.001));
    });

    test('returns 0.0 progress for expired or 0-day warranties', () {
      final expired = WarrantyCalculator.calculate(
        purchaseDate: fixedNow.subtract(const Duration(days: 50)),
        warrantyDurationDays: 30, // Expired 20 days ago
        now: fixedNow,
      );
      expect(expired.status, WarrantyStatus.expired);
      expect(expired.progress, 0.0);

      final noWarranty = WarrantyCalculator.calculate(
        purchaseDate: fixedNow,
        warrantyDurationDays: null,
        now: fixedNow,
      );
      expect(noWarranty.status, WarrantyStatus.none);
      expect(noWarranty.progress, 0.0);
    });

    test(
      'filterAndSortWarrantyItems strictly excludes receipts without warranty',
      () {
        final receipts = [
          _createReceipt(
            id: 1,
            productName: 'No Warranty Receipt',
            purchaseDate: fixedNow,
            totalAmount: 10.0,
            warrantyDurationDays: null,
          ),
          _createReceipt(
            id: 2,
            productName: 'Zero Days Receipt',
            purchaseDate: fixedNow,
            totalAmount: 20.0,
            warrantyDurationDays: 0,
          ),
          _createReceipt(
            id: 3,
            productName: 'Negative Days Receipt',
            purchaseDate: fixedNow,
            totalAmount: 30.0,
            warrantyDurationDays: -5,
          ),
          _createReceipt(
            id: 4,
            productName: 'Valid Warranty Receipt',
            purchaseDate: fixedNow,
            totalAmount: 40.0,
            warrantyDurationDays: 365,
          ),
        ];

        final items = filterAndSortWarrantyItems(receipts, now: fixedNow);
        expect(items.length, 1);
        expect(items.first.receipt.productName, 'Valid Warranty Receipt');
      },
    );

    test('filterAndSortWarrantyItems sorts soonest expiry first', () {
      final receipts = [
        _createReceipt(
          id: 1,
          productName: 'Long Term Active',
          purchaseDate: fixedNow,
          totalAmount: 100.0,
          warrantyDurationDays: 365, // ~365 days left
        ),
        _createReceipt(
          id: 2,
          productName: 'Urgent Expiring',
          purchaseDate: fixedNow.subtract(const Duration(days: 28)),
          totalAmount: 50.0,
          warrantyDurationDays: 30, // 2 days left
        ),
        _createReceipt(
          id: 3,
          productName: 'Medium Active',
          purchaseDate: fixedNow.subtract(const Duration(days: 10)),
          totalAmount: 70.0,
          warrantyDurationDays: 90, // 80 days left
        ),
        _createReceipt(
          id: 4,
          productName: 'Expired Item',
          purchaseDate: fixedNow.subtract(const Duration(days: 60)),
          totalAmount: 40.0,
          warrantyDurationDays: 30, // Expired
        ),
      ];

      final items = filterAndSortWarrantyItems(receipts, now: fixedNow);
      expect(items.length, 4);
      expect(items[0].receipt.productName, 'Urgent Expiring');
      expect(items[1].receipt.productName, 'Medium Active');
      expect(items[2].receipt.productName, 'Long Term Active');
      expect(items[3].receipt.productName, 'Expired Item');
    });
  });

  group('WarrantyScreen Widget Tests', () {
    final fixedNow = DateTime(2026, 10, 16);

    testWidgets('renders empty state when no warranties exist', (tester) async {
      await tester.pumpWidget(_buildTestApp(initialItems: const []));
      await tester.pumpAndSettle();

      expect(find.text('Active Warranties'), findsOneWidget);
      expect(find.byType(WarrantyEmptyState), findsOneWidget);
      expect(find.text('No Warranties Tracked'), findsOneWidget);
      expect(find.text('Add Receipt'), findsOneWidget);
      expect(find.text('0 Active'), findsOneWidget);
    });

    testWidgets(
      'renders warranty cards with product, store, dates, badge, and progress',
      (tester) async {
        final receipt = _createReceipt(
          id: 42,
          productName: 'Samsung Galaxy S23',
          storeName: 'Best Buy',
          category: 'Electronics',
          purchaseDate: fixedNow.subtract(const Duration(days: 30)),
          totalAmount: 899.99,
          warrantyDurationDays: 150, // 120 days left -> 80%
        );

        final item = WarrantyItem.fromReceipt(receipt, now: fixedNow);

        await tester.pumpWidget(_buildTestApp(initialItems: [item]));
        await tester.pumpAndSettle();

        expect(find.text('Samsung Galaxy S23'), findsOneWidget);
        expect(find.text('Best Buy • Electronics'), findsOneWidget);
        expect(find.text('120 days left'), findsOneWidget);
        expect(find.text('80%'), findsOneWidget);
        expect(
          find.text('Expires: ${_formatDate(item.expiryDate!)}'),
          findsOneWidget,
        );
        expect(find.byType(WarrantyCard), findsOneWidget);
        expect(find.text('1 Active'), findsOneWidget);
      },
    );

    testWidgets('strictly omits receipts without warranties', (tester) async {
      // In-memory database with one warranty receipt and one without
      final db = AppDatabase(NativeDatabase.memory());

      await db
          .into(db.receipts)
          .insert(
            ReceiptsCompanion.insert(
              productName: 'Grocery Receipt',
              purchaseDate: fixedNow,
              totalAmount: 45.50,
              warrantyDurationDays: const drift.Value.absent(), // No warranty
            ),
          );

      await db
          .into(db.receipts)
          .insert(
            ReceiptsCompanion.insert(
              productName: 'Sony Headphones',
              purchaseDate: fixedNow,
              totalAmount: 199.99,
              warrantyDurationDays: const drift.Value(365), // 1 year warranty
            ),
          );

      await tester.pumpWidget(_buildTestApp(db: db));
      await tester.pumpAndSettle();

      expect(find.text('Sony Headphones'), findsOneWidget);
      expect(find.text('Grocery Receipt'), findsNothing);

      await db.close();
      await tester.pump(const Duration(milliseconds: 50));
    });

    testWidgets(
      'filter chips filter between All, Active, Expiring Soon, and Expired',
      (tester) async {
        final activeItem = WarrantyItem.fromReceipt(
          _createReceipt(
            id: 1,
            productName: 'Active Laptop',
            purchaseDate: fixedNow,
            totalAmount: 1200.0,
            warrantyDurationDays: 365,
          ),
          now: fixedNow,
        );

        final expiringItem = WarrantyItem.fromReceipt(
          _createReceipt(
            id: 2,
            productName: 'Expiring Coffee Maker',
            purchaseDate: fixedNow.subtract(const Duration(days: 75)),
            totalAmount: 80.0,
            warrantyDurationDays: 90, // 15 days left
          ),
          now: fixedNow,
        );

        final expiredItem = WarrantyItem.fromReceipt(
          _createReceipt(
            id: 3,
            productName: 'Expired Blender',
            purchaseDate: fixedNow.subtract(const Duration(days: 60)),
            totalAmount: 40.0,
            warrantyDurationDays: 30, // Expired
          ),
          now: fixedNow,
        );

        final allItems = [activeItem, expiringItem, expiredItem];

        await tester.pumpWidget(_buildTestApp(initialItems: allItems));
        await tester.pumpAndSettle();

        // All: 3 items
        expect(find.text('Active Laptop'), findsOneWidget);
        expect(find.text('Expiring Coffee Maker'), findsOneWidget);
        expect(find.text('Expired Blender'), findsOneWidget);
        expect(find.text('1 Active'), findsOneWidget);
        expect(find.text('1 Expiring Soon'), findsOneWidget);

        // Tap Active filter
        await tester.tap(find.byKey(const Key('warranty_filter_active')));
        await tester.pumpAndSettle();
        expect(find.text('Active Laptop'), findsOneWidget);
        expect(find.text('Expiring Coffee Maker'), findsNothing);
        expect(find.text('Expired Blender'), findsNothing);

        // Tap Expiring Soon filter
        await tester.tap(
          find.byKey(const Key('warranty_filter_expiring_soon')),
        );
        await tester.pumpAndSettle();
        expect(find.text('Active Laptop'), findsNothing);
        expect(find.text('Expiring Coffee Maker'), findsOneWidget);
        expect(find.text('Expired Blender'), findsNothing);

        // Tap Expired filter
        await tester.tap(find.byKey(const Key('warranty_filter_expired')));
        await tester.pumpAndSettle();
        expect(find.text('Active Laptop'), findsNothing);
        expect(find.text('Expiring Coffee Maker'), findsNothing);
        expect(find.text('Expired Blender'), findsOneWidget);

        // Tap All filter
        await tester.tap(find.byKey(const Key('warranty_filter_all')));
        await tester.pumpAndSettle();
        expect(find.text('Active Laptop'), findsOneWidget);
        expect(find.text('Expiring Coffee Maker'), findsOneWidget);
        expect(find.text('Expired Blender'), findsOneWidget);
      },
    );

    testWidgets(
      'shows contextual empty state when filtered category has 0 items',
      (tester) async {
        // Only active item
        final activeItem = WarrantyItem.fromReceipt(
          _createReceipt(
            id: 1,
            productName: 'Active TV',
            purchaseDate: fixedNow,
            totalAmount: 500.0,
            warrantyDurationDays: 365,
          ),
          now: fixedNow,
        );

        await tester.pumpWidget(_buildTestApp(initialItems: [activeItem]));
        await tester.pumpAndSettle();

        // Tap Expired filter
        await tester.tap(find.byKey(const Key('warranty_filter_expired')));
        await tester.pumpAndSettle();

        expect(find.text('No Expired Warranties'), findsOneWidget);
        expect(
          find.text('None of your tracked warranties have expired.'),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('warranty_empty_reset_button')),
          findsOneWidget,
        );

        // Tapping View All Warranties resets to All filter
        await tester.tap(find.byKey(const Key('warranty_empty_reset_button')));
        await tester.pumpAndSettle();

        expect(find.text('Active TV'), findsOneWidget);
      },
    );

    testWidgets('tapping warranty card opens receipt details', (tester) async {
      final receipt = _createReceipt(
        id: 77,
        productName: 'iPad Air',
        purchaseDate: fixedNow,
        totalAmount: 599.0,
        warrantyDurationDays: 365,
      );
      final item = WarrantyItem.fromReceipt(receipt, now: fixedNow);

      final router = GoRouter(
        initialLocation: AppRoutes.warranties,
        routes: [
          GoRoute(
            path: AppRoutes.warranties,
            builder: (context, state) => WarrantyScreen(initialItems: [item]),
          ),
          GoRoute(
            path: AppRoutes.receiptDetail,
            builder: (context, state) {
              final id = state.pathParameters['id'];
              return Scaffold(body: Text('Receipt Detail Screen for ID: $id'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: router)),
      );
      await tester.pumpAndSettle();

      expect(find.text('iPad Air'), findsOneWidget);

      // Tap card
      await tester.tap(find.byKey(const Key('warranty_card_77')));
      await tester.pumpAndSettle();

      expect(find.text('Receipt Detail Screen for ID: 77'), findsOneWidget);
    });

    testWidgets(
      'renders cleanly in dark mode without errors or contrast defects',
      (tester) async {
        final activeItem = WarrantyItem.fromReceipt(
          _createReceipt(
            id: 1,
            productName: 'Dark Mode Tablet',
            storeName: 'Apple Store',
            category: 'Electronics',
            purchaseDate: fixedNow,
            totalAmount: 799.0,
            warrantyDurationDays: 180,
          ),
          now: fixedNow,
        );

        await tester.pumpWidget(
          _buildTestApp(initialItems: [activeItem], themeMode: ThemeMode.dark),
        );
        await tester.pumpAndSettle();

        expect(find.text('Dark Mode Tablet'), findsOneWidget);
        expect(find.text('Apple Store • Electronics'), findsOneWidget);
        expect(find.byType(WarrantyCard), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
