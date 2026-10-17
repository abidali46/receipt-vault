// test/widget_test.dart
//
// Basic smoke test – verifies that the app starts and renders the
// bottom navigation bar with all five destinations.

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_vault/app/router/app_router.dart';
import 'package:receipt_vault/core/services/warranty_notification_service.dart';
import 'package:receipt_vault/core/storage/app_database.dart';
import 'package:receipt_vault/core/storage/database_provider.dart';
import 'package:receipt_vault/main.dart';

Widget _buildTestApp({
  required AppDatabase db,
  WarrantyNotificationService? notifService,
}) {
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      warrantyNotificationServiceProvider.overrideWithValue(
        notifService ?? FakeWarrantyNotificationService(),
      ),
    ],
    child: const ReceiptVaultApp(),
  );
}

void main() {
  testWidgets('App renders bottom navigation bar', (WidgetTester tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(() => db.close());

    await tester.pumpWidget(_buildTestApp(db: db));
    // Allow GoRouter to settle.
    await tester.pumpAndSettle();

    // The NavigationBar should be present.
    expect(find.byType(NavigationBar), findsOneWidget);

    // All five tab labels should be visible in the NavigationBar.
    // findsWidgets is used because the active tab may also show the label
    // in the AppBar title, producing more than one match for that tab.
    expect(find.text('Receipts'), findsWidgets);
    expect(find.text('Warranties'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);
    expect(find.text('Alerts'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Clean up in-memory db and clear any pending Drift timers
    await db.close();
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets(
    'Tapping center Add button navigates to AddReceiptScreen and back',
    (WidgetTester tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => db.close());

      await tester.pumpWidget(_buildTestApp(db: db));
      await tester.pumpAndSettle();

      // Tap center Add button
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Verify AddReceiptScreen is displayed
      expect(find.text('Add Receipt'), findsOneWidget);
      expect(find.byKey(const Key('add_receipt_save_button')), findsOneWidget);
      expect(
        find.byKey(const Key('add_receipt_product_name_field')),
        findsOneWidget,
      );

      // Tap back button
      await tester.tap(find.byKey(const Key('add_receipt_back_button')));
      await tester.pumpAndSettle();

      // Verify returned to Receipts screen
      expect(find.text('My Receipts'), findsOneWidget);

      await db.close();
      await tester.pump(const Duration(milliseconds: 50));
    },
  );

  testWidgets(
    'End-to-end Add flow: navigate from shell, save receipt, return, and see it in list',
    (WidgetTester tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => db.close());

      await tester.pumpWidget(_buildTestApp(db: db));
      await tester.pumpAndSettle();

      // Tap center Add button
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Fill in details
      await tester.enterText(
        find.byKey(const Key('add_receipt_product_name_field')),
        'iPad Pro',
      );
      await tester.enterText(
        find.byKey(const Key('add_receipt_price_field')),
        '999.00',
      );

      // Save
      final saveBtn = find.byKey(const Key('add_receipt_save_button'));
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Returned to Receipts tab
      expect(find.text('My Receipts'), findsOneWidget);

      // New receipt card is displayed reactively!
      expect(find.text('iPad Pro'), findsOneWidget);
      expect(find.text(r'$999'), findsOneWidget);

      await db.close();
      await tester.pump(const Duration(milliseconds: 50));
    },
  );

  testWidgets(
    'End-to-end: tap receipt card navigates to ReceiptDetailScreen, edit updates both detail and list views',
    (WidgetTester tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => db.close());

      // Insert an existing receipt
      await db
          .into(db.receipts)
          .insert(
            ReceiptsCompanion.insert(
              productName: 'MacBook Air',
              storeName: const drift.Value('Apple Store'),
              category: const drift.Value('Electronics'),
              purchaseDate: DateTime(2026, 1, 10),
              totalAmount: 1199.00,
              warrantyDurationDays: const drift.Value(365),
            ),
          );

      appRouter.go(AppRoutes.receipts);

      await tester.pumpWidget(_buildTestApp(db: db));
      await tester.pumpAndSettle();

      // Receipts screen displays MacBook Air
      expect(find.text('MacBook Air'), findsOneWidget);
      expect(find.text('Apple Store'), findsOneWidget);

      // Tap card
      await tester.tap(find.text('MacBook Air'));
      await tester.pumpAndSettle();

      // In ReceiptDetailScreen
      expect(find.text('Receipt Details'), findsOneWidget);
      expect(
        find.byKey(const Key('receipt_detail_product_name')),
        findsOneWidget,
      );
      expect(find.text('MacBook Air'), findsOneWidget);
      expect(find.text('Apple Store'), findsOneWidget);
      expect(find.text(r'$1199'), findsOneWidget);

      // Tap Edit Details
      final editBtn = find.byKey(const Key('receipt_detail_edit_button'));
      await tester.ensureVisible(editBtn);
      await tester.tap(editBtn);
      await tester.pumpAndSettle();

      // In EditReceiptScreen
      expect(find.text('Edit Receipt'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);

      // Modify product name
      final nameField = find.byKey(const Key('add_receipt_product_name_field'));
      await tester.enterText(nameField, 'MacBook Pro M3');

      // Save
      final saveBtn = find.byKey(const Key('add_receipt_save_button'));
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Back on ReceiptDetailScreen, updated reactively!
      expect(find.text('MacBook Pro M3'), findsOneWidget);

      // Tap back to return to Receipts list
      await tester.tap(find.byKey(const Key('receipt_detail_back_button')));
      await tester.pumpAndSettle();

      // Back on Receipts screen, updated reactively!
      expect(find.text('My Receipts'), findsOneWidget);
      expect(find.text('MacBook Pro M3'), findsOneWidget);

      await db.close();
      await tester.pump(const Duration(milliseconds: 50));
    },
  );

  testWidgets(
    'End-to-end: tap receipt card, delete receipt with confirmation, and verify removed from list',
    (WidgetTester tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => db.close());

      // Insert an existing receipt
      await db
          .into(db.receipts)
          .insert(
            ReceiptsCompanion.insert(
              productName: 'AirPods Pro',
              storeName: const drift.Value('Apple Store'),
              category: const drift.Value('Electronics'),
              purchaseDate: DateTime(2026, 1, 10),
              totalAmount: 249.00,
              warrantyDurationDays: const drift.Value(365),
            ),
          );

      appRouter.go(AppRoutes.receipts);

      await tester.pumpWidget(_buildTestApp(db: db));
      await tester.pumpAndSettle();

      // Card is in list
      expect(find.text('AirPods Pro'), findsOneWidget);

      // Tap card
      await tester.tap(find.text('AirPods Pro'));
      await tester.pumpAndSettle();

      // On details screen
      expect(find.text('Receipt Details'), findsOneWidget);
      expect(find.text('AirPods Pro'), findsOneWidget);

      // Tap Delete Receipt button
      final deleteBtn = find.byKey(const Key('receipt_detail_delete_button'));
      await tester.ensureVisible(deleteBtn);
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      // Dialog is shown
      expect(
        find.byKey(const Key('receipt_detail_delete_dialog')),
        findsOneWidget,
      );

      // Confirm delete
      await tester.tap(
        find.byKey(const Key('receipt_detail_delete_confirm_button')),
      );
      await tester.pumpAndSettle();

      // Returned to Receipts tab
      expect(find.text('My Receipts'), findsOneWidget);

      // Receipt is gone from list reactively!
      expect(find.text('AirPods Pro'), findsNothing);

      await db.close();
      await tester.pump(const Duration(milliseconds: 50));
    },
  );

  testWidgets(
    'End-to-end: switch to Warranties tab, view tracked warranties, and tap card to open details',
    (WidgetTester tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => db.close());

      // Insert receipt with warranty and receipt without warranty
      await db
          .into(db.receipts)
          .insert(
            ReceiptsCompanion.insert(
              productName: 'MacBook Air',
              storeName: const drift.Value('Apple Store'),
              category: const drift.Value('Electronics'),
              purchaseDate: DateTime.now(),
              totalAmount: 999.0,
              warrantyDurationDays: const drift.Value(365),
            ),
          );

      await db
          .into(db.receipts)
          .insert(
            ReceiptsCompanion.insert(
              productName: 'Coffee Beans',
              storeName: const drift.Value('Roastery'),
              category: const drift.Value('Food'),
              purchaseDate: DateTime.now(),
              totalAmount: 18.0,
              warrantyDurationDays: const drift.Value.absent(), // No warranty
            ),
          );

      appRouter.go(AppRoutes.receipts);

      await tester.pumpWidget(_buildTestApp(db: db));
      await tester.pumpAndSettle();

      // On Receipts screen initially
      expect(find.text('My Receipts'), findsOneWidget);

      // Tap Warranties destination in bottom navigation bar
      await tester.tap(find.text('Warranties'));
      await tester.pumpAndSettle();

      // On Warranties screen
      expect(find.text('Active Warranties'), findsOneWidget);
      expect(find.text('MacBook Air'), findsOneWidget);
      expect(find.text('Coffee Beans'), findsNothing); // Strictly excluded

      // Tap MacBook Air warranty card
      await tester.tap(find.byKey(const Key('warranty_card_1')));
      await tester.pumpAndSettle();

      // Pushed to ReceiptDetailScreen
      expect(find.text('Receipt Details'), findsOneWidget);
      expect(find.text('MacBook Air'), findsWidgets);

      // Back button returns cleanly to Warranties screen
      await tester.tap(find.byKey(const Key('receipt_detail_back_button')));
      await tester.pumpAndSettle();

      expect(find.text('Active Warranties'), findsOneWidget);
      expect(find.text('MacBook Air'), findsOneWidget);

      // Unmount ProviderScope so Riverpod cancels all stream queries,
      // then pump with duration to advance clock and flush Drift's zero-duration QueryStream timer.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    },
  );

  testWidgets(
    'End-to-end: switch to Alerts tab, view calculated warranty alerts, and tap alert to open receipt details',
    (WidgetTester tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => db.close());

      final now = DateTime.now();

      // 1. Insert receipt expiring soon (7 days left)
      await db
          .into(db.receipts)
          .insert(
            ReceiptsCompanion.insert(
              productName: 'Samsung Galaxy Watch',
              storeName: const drift.Value('Best Buy'),
              category: const drift.Value('Electronics'),
              purchaseDate: now.subtract(const Duration(days: 23)),
              totalAmount: 249.0,
              warrantyDurationDays: const drift.Value(30), // 7 days left
            ),
          );

      // 2. Insert receipt with long active warranty (> 30 days left) -> NOT an alert
      await db
          .into(db.receipts)
          .insert(
            ReceiptsCompanion.insert(
              productName: 'Living Room TV',
              storeName: const drift.Value('Costco'),
              category: const drift.Value('Electronics'),
              purchaseDate: now,
              totalAmount: 899.0,
              warrantyDurationDays: const drift.Value(730), // 2 years
            ),
          );

      // 3. Insert receipt with no warranty -> NOT an alert
      await db
          .into(db.receipts)
          .insert(
            ReceiptsCompanion.insert(
              productName: 'Weekly Groceries',
              storeName: const drift.Value('Trader Joe\'s'),
              category: const drift.Value('Groceries'),
              purchaseDate: now,
              totalAmount: 65.0,
              warrantyDurationDays: const drift.Value.absent(),
            ),
          );

      appRouter.go(AppRoutes.receipts);

      await tester.pumpWidget(_buildTestApp(db: db));
      await tester.pumpAndSettle();

      // Start on Receipts tab
      expect(find.text('My Receipts'), findsOneWidget);

      // Tap Alerts tab in bottom navigation bar
      await tester.tap(find.text('Alerts'));
      await tester.pumpAndSettle();

      // Verify on Alerts screen
      expect(find.text('Alerts'), findsWidgets);
      expect(find.text('Samsung Galaxy Watch'), findsOneWidget);
      expect(find.text('Expires in 7 days'), findsOneWidget);

      // Safe active warranty and no-warranty receipts must NOT appear on Alerts screen
      expect(find.text('Living Room TV'), findsNothing);
      expect(find.text('Weekly Groceries'), findsNothing);

      // Tap alert card to open details
      await tester.tap(find.byKey(const Key('alert_card_1')));
      await tester.pumpAndSettle();

      // Pushed to ReceiptDetailScreen
      expect(find.text('Receipt Details'), findsOneWidget);
      expect(find.text('Samsung Galaxy Watch'), findsWidgets);

      // Back button returns cleanly to Alerts screen
      await tester.tap(find.byKey(const Key('receipt_detail_back_button')));
      await tester.pumpAndSettle();

      expect(find.text('Alerts'), findsWidgets);
      expect(find.text('Samsung Galaxy Watch'), findsOneWidget);

      // Unmount ProviderScope and clear pending queries
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    },
  );

  testWidgets(
    'End-to-end: switch to Settings tab, view settings sections, and switch themes',
    (WidgetTester tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => db.close());

      appRouter.go(AppRoutes.receipts);

      await tester.pumpWidget(_buildTestApp(db: db));
      await tester.pumpAndSettle();

      // Tap Settings in bottom navigation bar
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // On Settings screen
      expect(find.text('Settings'), findsWidgets);
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Data & Privacy'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);

      // Verify about section information
      expect(find.text('Receipt Vault'), findsOneWidget);
      expect(find.text('v1.0.0'), findsOneWidget);

      // Verify privacy note
      expect(find.text('100% Offline & Local Privacy'), findsOneWidget);

      // Tap Dark theme mode
      await tester.tap(find.byKey(const Key('settings_theme_dark')));
      await tester.pumpAndSettle();

      // Verify theme mode updated on MaterialApp
      final appFinder = find.byType(MaterialApp);
      final appWidget = tester.widget<MaterialApp>(appFinder);
      expect(appWidget.themeMode, ThemeMode.dark);

      // Tap Light theme mode
      await tester.tap(find.byKey(const Key('settings_theme_light')));
      await tester.pumpAndSettle();

      final appWidgetLight = tester.widget<MaterialApp>(appFinder);
      expect(appWidgetLight.themeMode, ThemeMode.light);

      // Unmount ProviderScope and clear pending queries
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    },
  );

  testWidgets(
    'Notification tap while app is running navigates to ReceiptDetailScreen',
    (WidgetTester tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => db.close());

      final notifService = FakeWarrantyNotificationService();

      await db
          .into(db.receipts)
          .insert(
            ReceiptsCompanion.insert(
              productName: 'Sony WH-1000XM5',
              purchaseDate: DateTime(2026, 1, 1),
              totalAmount: 399.99,
              warrantyDurationDays: const drift.Value(365),
              createdAt: drift.Value(DateTime.now()),
            ),
          );

      appRouter.go(AppRoutes.receipts);

      await tester.pumpWidget(
        _buildTestApp(db: db, notifService: notifService),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Receipts'), findsOneWidget);

      // Simulate notification tap
      notifService.simulateNotificationTap('/receipts/1');
      await tester.pumpAndSettle();

      // Should have navigated to ReceiptDetailScreen
      expect(find.text('Receipt Details'), findsOneWidget);
      expect(find.text('Sony WH-1000XM5'), findsOneWidget);

      // Back navigation returns to Receipts
      await tester.tap(find.byKey(const Key('receipt_detail_back_button')));
      await tester.pumpAndSettle();
      expect(find.text('My Receipts'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    },
  );

  testWidgets(
    'Cold start notification tap navigates to ReceiptDetailScreen on startup',
    (WidgetTester tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => db.close());

      final notifService = FakeWarrantyNotificationService();
      notifService.setLaunchPayload('/receipts/1');

      await db
          .into(db.receipts)
          .insert(
            ReceiptsCompanion.insert(
              productName: 'iPad Pro',
              purchaseDate: DateTime(2026, 1, 1),
              totalAmount: 999.00,
              warrantyDurationDays: const drift.Value(365),
              createdAt: drift.Value(DateTime.now()),
            ),
          );

      appRouter.go(AppRoutes.receipts);

      await tester.pumpWidget(
        _buildTestApp(db: db, notifService: notifService),
      );
      await tester.pumpAndSettle();

      // Cold start should automatically navigate to the receipt detail screen
      expect(find.text('Receipt Details'), findsOneWidget);
      expect(find.text('iPad Pro'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    },
  );

  testWidgets(
    'Notification tap with non-existent or deleted receipt ID displays Receipt Not Found',
    (WidgetTester tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => db.close());

      final notifService = FakeWarrantyNotificationService();

      appRouter.go(AppRoutes.receipts);

      await tester.pumpWidget(
        _buildTestApp(db: db, notifService: notifService),
      );
      await tester.pumpAndSettle();

      // Tap notification for non-existent receipt
      notifService.simulateNotificationTap('/receipts/9999');
      await tester.pumpAndSettle();

      // ReceiptDetailScreen renders its built-in not found state
      expect(find.text('Receipt Not Found'), findsOneWidget);
      expect(
        find.text('This receipt does not exist or has been removed.'),
        findsOneWidget,
      );

      // Back to Receipts button works
      await tester.tap(
        find.byKey(const Key('receipt_detail_not_found_back_button')),
      );
      await tester.pumpAndSettle();
      expect(find.text('My Receipts'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    },
  );

  testWidgets(
    'Notification tap with malformed payload is ignored safely without crashing',
    (WidgetTester tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => db.close());

      final notifService = FakeWarrantyNotificationService();

      appRouter.go(AppRoutes.receipts);

      await tester.pumpWidget(
        _buildTestApp(db: db, notifService: notifService),
      );
      await tester.pumpAndSettle();

      // Tap notification with malformed payload
      notifService.simulateNotificationTap('/receipts/not_a_number');
      await tester.pumpAndSettle();

      // Remains on current screen without error
      expect(find.text('My Receipts'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    },
  );
}
