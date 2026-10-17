// test/features/alerts/alerts_screen_test.dart

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
import 'package:receipt_vault/features/alerts/domain/entities/warranty_alert.dart';
import 'package:receipt_vault/features/alerts/presentation/alerts_screen.dart';
import 'package:receipt_vault/features/alerts/presentation/providers/alerts_providers.dart';
import 'package:receipt_vault/features/alerts/presentation/widgets/alert_card.dart';
import 'package:receipt_vault/features/alerts/presentation/widgets/alerts_empty_state.dart';
import 'package:receipt_vault/shared/enums/warranty_status.dart';

Widget _buildTestApp({
  List<WarrantyAlert>? initialAlerts,
  AppDatabase? db,
  ThemeMode themeMode = ThemeMode.light,
  DateTime? now,
}) {
  return ProviderScope(
    overrides: [if (db != null) databaseProvider.overrideWithValue(db)],
    child: MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: AlertsScreen(initialAlerts: initialAlerts, now: now),
    ),
  );
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
  group('WarrantyAlert entity & Urgency labels', () {
    final fixedNow = DateTime(2026, 10, 16);

    test('formats urgency label correctly for relative time horizons', () {
      // Expires today (remainingDays == 0)
      final rToday = _createReceipt(
        id: 1,
        productName: 'Watch',
        purchaseDate: fixedNow.subtract(const Duration(days: 30)),
        totalAmount: 100,
        warrantyDurationDays: 30,
      );
      final aToday = WarrantyAlert.fromReceipt(rToday, now: fixedNow);
      expect(aToday.status, WarrantyStatus.expiringSoon);
      expect(aToday.urgencyLabel, 'Expires today');

      // Expires in 1 day
      final rTomorrow = _createReceipt(
        id: 2,
        productName: 'Mouse',
        purchaseDate: fixedNow.subtract(const Duration(days: 29)),
        totalAmount: 50,
        warrantyDurationDays: 30,
      );
      final aTomorrow = WarrantyAlert.fromReceipt(rTomorrow, now: fixedNow);
      expect(aTomorrow.urgencyLabel, 'Expires in 1 day');

      // Expires in 7 days
      final r7Days = _createReceipt(
        id: 3,
        productName: 'Phone',
        purchaseDate: fixedNow.subtract(const Duration(days: 23)),
        totalAmount: 600,
        warrantyDurationDays: 30,
      );
      final a7Days = WarrantyAlert.fromReceipt(r7Days, now: fixedNow);
      expect(a7Days.urgencyLabel, 'Expires in 7 days');

      // Expired 1 day ago
      final rYesterday = _createReceipt(
        id: 4,
        productName: 'Keyboard',
        purchaseDate: fixedNow.subtract(const Duration(days: 31)),
        totalAmount: 80,
        warrantyDurationDays: 30,
      );
      final aYesterday = WarrantyAlert.fromReceipt(rYesterday, now: fixedNow);
      expect(aYesterday.status, WarrantyStatus.expired);
      expect(aYesterday.urgencyLabel, 'Expired 1 day ago');

      // Expired 2 days ago
      final r2DaysAgo = _createReceipt(
        id: 5,
        productName: 'Old Headphones',
        purchaseDate: fixedNow.subtract(const Duration(days: 32)),
        totalAmount: 120,
        warrantyDurationDays: 30,
      );
      final a2DaysAgo = WarrantyAlert.fromReceipt(r2DaysAgo, now: fixedNow);
      expect(a2DaysAgo.urgencyLabel, 'Expired 2 days ago');
    });
  });

  group('generateWarrantyAlerts & Deterministic Sorting', () {
    final fixedNow = DateTime(2026, 10, 16);

    test('strictly excludes receipts without warranty or active >30 days', () {
      final receipts = [
        _createReceipt(
          id: 1,
          productName: 'No Warranty',
          purchaseDate: fixedNow,
          totalAmount: 10,
          warrantyDurationDays: null,
        ),
        _createReceipt(
          id: 2,
          productName: 'Zero Days',
          purchaseDate: fixedNow,
          totalAmount: 20,
          warrantyDurationDays: 0,
        ),
        _createReceipt(
          id: 3,
          productName: 'Active Far Future (200 days left)',
          purchaseDate: fixedNow,
          totalAmount: 50,
          warrantyDurationDays: 200,
        ),
        _createReceipt(
          id: 4,
          productName: 'Expiring Soon (5 days left)',
          purchaseDate: fixedNow.subtract(const Duration(days: 25)),
          totalAmount: 70,
          warrantyDurationDays: 30,
        ),
        _createReceipt(
          id: 5,
          productName: 'Expired Recently (3 days ago)',
          purchaseDate: fixedNow.subtract(const Duration(days: 33)),
          totalAmount: 90,
          warrantyDurationDays: 30,
        ),
        _createReceipt(
          id: 6,
          productName: 'Expired Ancient (120 days ago)',
          purchaseDate: fixedNow.subtract(const Duration(days: 150)),
          totalAmount: 100,
          warrantyDurationDays: 30,
        ),
      ];

      final alerts = generateWarrantyAlerts(receipts, now: fixedNow);

      expect(alerts.length, 2);
      expect(alerts[0].productName, 'Expiring Soon (5 days left)');
      expect(alerts[1].productName, 'Expired Recently (3 days ago)');
    });

    test('sorts alerts with deterministic urgency and date rules', () {
      final receipts = [
        _createReceipt(
          id: 10,
          productName: 'Expired 10 days ago',
          purchaseDate: fixedNow.subtract(const Duration(days: 40)),
          totalAmount: 10,
          warrantyDurationDays: 30,
        ),
        _createReceipt(
          id: 2,
          productName: 'Expired 2 days ago',
          purchaseDate: fixedNow.subtract(const Duration(days: 32)),
          totalAmount: 20,
          warrantyDurationDays: 30,
        ),
        _createReceipt(
          id: 15,
          productName: 'Expires in 15 days',
          purchaseDate: fixedNow.subtract(const Duration(days: 15)),
          totalAmount: 30,
          warrantyDurationDays: 30,
        ),
        _createReceipt(
          id: 1,
          productName: 'Expires in 1 day',
          purchaseDate: fixedNow.subtract(const Duration(days: 29)),
          totalAmount: 40,
          warrantyDurationDays: 30,
        ),
        _createReceipt(
          id: 0,
          productName: 'Expires today',
          purchaseDate: fixedNow.subtract(const Duration(days: 30)),
          totalAmount: 50,
          warrantyDurationDays: 30,
        ),
      ];

      final alerts = generateWarrantyAlerts(receipts, now: fixedNow);

      // Expected order:
      // 1. Expiring soon group (soonest to expire first):
      //    - Expires today (0 days)
      //    - Expires in 1 day (1 day)
      //    - Expires in 15 days (15 days)
      // 2. Expired group (most recently expired first):
      //    - Expired 2 days ago (-2 days)
      //    - Expired 10 days ago (-10 days)
      expect(alerts.length, 5);
      expect(alerts[0].productName, 'Expires today');
      expect(alerts[1].productName, 'Expires in 1 day');
      expect(alerts[2].productName, 'Expires in 15 days');
      expect(alerts[3].productName, 'Expired 2 days ago');
      expect(alerts[4].productName, 'Expired 10 days ago');
    });

    test('tie-breaks identical urgency by descending receipt ID', () {
      final receipts = [
        _createReceipt(
          id: 5,
          productName: 'Old Item ID 5',
          purchaseDate: fixedNow.subtract(const Duration(days: 25)),
          totalAmount: 10,
          warrantyDurationDays: 30,
        ),
        _createReceipt(
          id: 99,
          productName: 'New Item ID 99',
          purchaseDate: fixedNow.subtract(const Duration(days: 25)),
          totalAmount: 20,
          warrantyDurationDays: 30,
        ),
      ];

      final alerts = generateWarrantyAlerts(receipts, now: fixedNow);
      expect(alerts[0].productName, 'New Item ID 99');
      expect(alerts[1].productName, 'Old Item ID 5');
    });
  });

  group('AlertsScreen Widget Tests', () {
    final fixedNow = DateTime(2026, 10, 16);

    testWidgets('renders pristine empty state ("All Clear") when no alerts', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp(initialAlerts: const []));
      await tester.pumpAndSettle();

      expect(find.text('Alerts'), findsOneWidget);
      expect(find.byType(AlertsEmptyState), findsOneWidget);
      expect(find.text('All Clear'), findsOneWidget);
      expect(
        find.text(
          'No active warranty alerts. We\'ll notify you here when warranties are approaching expiration or have recently expired.',
        ),
        findsOneWidget,
      );
      expect(find.text('0 Expiring Soon'), findsOneWidget);
    });

    testWidgets(
      'renders alert cards with product name, subtitle, badges, and progress',
      (tester) async {
        final expiring = WarrantyAlert.fromReceipt(
          _createReceipt(
            id: 1,
            productName: 'Samsung Galaxy S23',
            storeName: 'Best Buy',
            category: 'Electronics',
            purchaseDate: fixedNow.subtract(const Duration(days: 23)),
            totalAmount: 899.99,
            warrantyDurationDays: 30, // 7 days left
          ),
          now: fixedNow,
        );

        final expired = WarrantyAlert.fromReceipt(
          _createReceipt(
            id: 2,
            productName: 'Old Headphones',
            storeName: null,
            category: 'Audio',
            purchaseDate: fixedNow.subtract(const Duration(days: 32)),
            totalAmount: 150.0,
            warrantyDurationDays: 30, // 2 days ago
          ),
          now: fixedNow,
        );

        await tester.pumpWidget(
          _buildTestApp(initialAlerts: [expiring, expired]),
        );
        await tester.pumpAndSettle();

        // Section headers
        expect(
          find.byKey(const Key('alerts_section_expiring_header')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('alerts_section_expired_header')),
          findsOneWidget,
        );

        // Card 1
        expect(find.text('Samsung Galaxy S23'), findsOneWidget);
        expect(find.text('Best Buy • Electronics'), findsOneWidget);
        expect(find.text('Expires in 7 days'), findsOneWidget);

        // Card 2
        expect(find.text('Old Headphones'), findsOneWidget);
        expect(find.text('Audio'), findsOneWidget);
        expect(find.text('Expired 2 days ago'), findsOneWidget);

        // Verify line-through decoration on expired title
        final expiredTextWidget = tester.widget<Text>(
          find.byKey(const Key('alert_card_title_2')),
        );
        expect(expiredTextWidget.style?.decoration, TextDecoration.lineThrough);

        // Summary counts
        expect(find.text('1 Expiring Soon'), findsOneWidget);
        expect(find.text('1 Expired'), findsOneWidget);
      },
    );

    testWidgets('filter chips toggle between All, Expiring Soon, and Expired', (
      tester,
    ) async {
      final expiring = WarrantyAlert.fromReceipt(
        _createReceipt(
          id: 1,
          productName: 'Expiring Phone',
          purchaseDate: fixedNow.subtract(const Duration(days: 25)),
          totalAmount: 500,
          warrantyDurationDays: 30,
        ),
        now: fixedNow,
      );

      final expired = WarrantyAlert.fromReceipt(
        _createReceipt(
          id: 2,
          productName: 'Expired Tablet',
          purchaseDate: fixedNow.subtract(const Duration(days: 35)),
          totalAmount: 300,
          warrantyDurationDays: 30,
        ),
        now: fixedNow,
      );

      await tester.pumpWidget(
        _buildTestApp(initialAlerts: [expiring, expired]),
      );
      await tester.pumpAndSettle();

      // All: both items
      expect(find.text('Expiring Phone'), findsOneWidget);
      expect(find.text('Expired Tablet'), findsOneWidget);

      // Tap Expiring Soon filter chip
      await tester.tap(find.byKey(const Key('alert_filter_expiring_soon')));
      await tester.pumpAndSettle();

      expect(find.text('Expiring Phone'), findsOneWidget);
      expect(find.text('Expired Tablet'), findsNothing);

      // Tap Expired filter chip
      await tester.tap(find.byKey(const Key('alert_filter_expired')));
      await tester.pumpAndSettle();

      expect(find.text('Expiring Phone'), findsNothing);
      expect(find.text('Expired Tablet'), findsOneWidget);

      // Tap All filter chip
      await tester.tap(find.byKey(const Key('alert_filter_all')));
      await tester.pumpAndSettle();

      expect(find.text('Expiring Phone'), findsOneWidget);
      expect(find.text('Expired Tablet'), findsOneWidget);
    });

    testWidgets(
      'shows contextual empty state when filtered category has 0 items',
      (tester) async {
        final expiring = WarrantyAlert.fromReceipt(
          _createReceipt(
            id: 1,
            productName: 'Expiring Phone',
            purchaseDate: fixedNow.subtract(const Duration(days: 25)),
            totalAmount: 500,
            warrantyDurationDays: 30,
          ),
          now: fixedNow,
        );

        await tester.pumpWidget(_buildTestApp(initialAlerts: [expiring]));
        await tester.pumpAndSettle();

        // Tap Expired filter chip
        await tester.tap(find.byKey(const Key('alert_filter_expired')));
        await tester.pumpAndSettle();

        expect(find.text('No Expired Warranties'), findsOneWidget);
        expect(
          find.text(
            'None of your tracked warranties have expired in the past 90 days.',
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('alerts_empty_reset_button')),
          findsOneWidget,
        );

        // Tap reset button
        await tester.tap(find.byKey(const Key('alerts_empty_reset_button')));
        await tester.pumpAndSettle();

        // Resets to All
        expect(find.text('Expiring Phone'), findsOneWidget);
      },
    );

    testWidgets('tapping alert card pushes receipt details route', (
      tester,
    ) async {
      final alert = WarrantyAlert.fromReceipt(
        _createReceipt(
          id: 88,
          productName: 'Sony Camera',
          purchaseDate: fixedNow.subtract(const Duration(days: 28)),
          totalAmount: 1200,
          warrantyDurationDays: 30,
        ),
        now: fixedNow,
      );

      final router = GoRouter(
        initialLocation: AppRoutes.alerts,
        routes: [
          GoRoute(
            path: AppRoutes.alerts,
            builder: (context, state) => AlertsScreen(initialAlerts: [alert]),
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

      expect(find.text('Sony Camera'), findsOneWidget);

      // Tap alert card
      await tester.tap(find.byKey(const Key('alert_card_88')));
      await tester.pumpAndSettle();

      // Successfully pushed to receipt details
      expect(find.text('Receipt Detail Screen for ID: 88'), findsOneWidget);
    });

    testWidgets('renders cleanly in dark mode without errors or defects', (
      tester,
    ) async {
      final alert = WarrantyAlert.fromReceipt(
        _createReceipt(
          id: 1,
          productName: 'Dark Mode Smartwatch',
          storeName: 'Gadget Store',
          category: 'Wearables',
          purchaseDate: fixedNow.subtract(const Duration(days: 20)),
          totalAmount: 299,
          warrantyDurationDays: 30,
        ),
        now: fixedNow,
      );

      await tester.pumpWidget(
        _buildTestApp(initialAlerts: [alert], themeMode: ThemeMode.dark),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dark Mode Smartwatch'), findsOneWidget);
      expect(find.text('Gadget Store • Wearables'), findsOneWidget);
      expect(find.byType(AlertCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('reactively streams alerts from SQLite database', (
      tester,
    ) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => db.close());

      // 1. Insert expiring soon receipt
      await db
          .into(db.receipts)
          .insert(
            ReceiptsCompanion.insert(
              productName: 'Expiring Soon Gadget',
              purchaseDate: fixedNow.subtract(const Duration(days: 25)),
              totalAmount: 199.99,
              warrantyDurationDays: const drift.Value(30), // 5 days left
            ),
          );

      // 2. Insert active receipt (> 30 days left) - should NOT show as alert
      await db
          .into(db.receipts)
          .insert(
            ReceiptsCompanion.insert(
              productName: 'Safe Active Appliance',
              purchaseDate: fixedNow,
              totalAmount: 499.99,
              warrantyDurationDays: const drift.Value(365), // 365 days left
            ),
          );

      await tester.pumpWidget(_buildTestApp(db: db, now: fixedNow));
      await tester.pumpAndSettle();

      expect(find.text('Expiring Soon Gadget'), findsOneWidget);
      expect(find.text('Safe Active Appliance'), findsNothing);

      // Unmount ProviderScope and flush queries
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
