// test/core/services/warranty_notification_service_test.dart
//
// Unit tests for warranty notification scheduling, cancellation, synchronization,
// deterministic ID generation, and notification preference persistence.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_vault/core/services/warranty_notification_service.dart';
import 'package:receipt_vault/core/storage/app_database.dart';
import 'package:receipt_vault/core/storage/app_settings_service.dart';

Receipt _createReceipt({
  required int id,
  required String productName,
  required DateTime purchaseDate,
  int? warrantyDurationDays,
  double totalAmount = 99.99,
}) {
  return Receipt(
    id: id,
    productName: productName,
    purchaseDate: purchaseDate,
    totalAmount: totalAmount,
    warrantyDurationDays: warrantyDurationDays,
    createdAt: DateTime.now(),
  );
}

void main() {
  group('Deterministic Notification IDs', () {
    test('generates expected IDs for 30-day and 7-day reminders', () {
      expect(LocalWarrantyNotificationService.reminder30Id(1), 11);
      expect(LocalWarrantyNotificationService.reminder7Id(1), 12);

      expect(LocalWarrantyNotificationService.reminder30Id(42), 421);
      expect(LocalWarrantyNotificationService.reminder7Id(42), 422);

      expect(LocalWarrantyNotificationService.reminder30Id(999), 9991);
      expect(LocalWarrantyNotificationService.reminder7Id(999), 9992);
    });

    test(
      '30-day and 7-day reminder IDs never collide for the same or different receipts',
      () {
        final ids = <int>{};
        for (int i = 1; i <= 100; i++) {
          final id30 = LocalWarrantyNotificationService.reminder30Id(i);
          final id7 = LocalWarrantyNotificationService.reminder7Id(i);

          expect(
            ids.add(id30),
            isTrue,
            reason: 'Collision on reminder 30 for id $i',
          );
          expect(
            ids.add(id7),
            isTrue,
            reason: 'Collision on reminder 7 for id $i',
          );
        }
        expect(ids.length, 200);
      },
    );
  });

  group('FakeWarrantyNotificationService Scheduling Logic', () {
    late FakeWarrantyNotificationService service;
    final fixedNow = DateTime(2026, 6, 1, 10, 0);

    setUp(() {
      service = FakeWarrantyNotificationService();
    });

    test(
      'schedules both 30-day and 7-day reminders for warranty far in future',
      () async {
        // Purchase: 2026-05-01, 365 days -> expires ~2027-05-01
        final receipt = _createReceipt(
          id: 10,
          productName: 'Sony Headphones',
          purchaseDate: DateTime(2026, 5, 1),
          warrantyDurationDays: 365,
        );

        final scheduled = await service.scheduleWarrantyReminders(
          receipt,
          now: fixedNow,
        );

        expect(scheduled.length, 2);
        expect(scheduled[0].daysBeforeExpiry, 30);
        expect(scheduled[0].id, 101);
        expect(scheduled[0].title, contains('Sony Headphones'));
        expect(scheduled[0].body, contains('30 days'));
        expect(scheduled[0].payload, '/receipts/10');

        expect(scheduled[1].daysBeforeExpiry, 7);
        expect(scheduled[1].id, 102);
        expect(scheduled[1].title, contains('Sony Headphones'));
        expect(scheduled[1].body, contains('7 days'));
        expect(scheduled[1].payload, '/receipts/10');
      },
    );

    test(
      'schedules only 7-day reminder when 30-day reminder date has passed',
      () async {
        // Expiry is in 20 days: 30d reminder date is 10 days in the past
        // Purchase: 2026-05-01, 51 days -> expires 2026-06-21
        final receipt = _createReceipt(
          id: 20,
          productName: 'Electric Kettle',
          purchaseDate: DateTime(2026, 5, 1),
          warrantyDurationDays: 51,
        );

        final scheduled = await service.scheduleWarrantyReminders(
          receipt,
          now: fixedNow,
        );

        expect(scheduled.length, 1);
        expect(scheduled[0].daysBeforeExpiry, 7);
        expect(scheduled[0].id, 202);
        expect(scheduled[0].title, contains('Electric Kettle'));
      },
    );

    test(
      'does not schedule reminders when both 30d and 7d dates have passed',
      () async {
        // Expiry is in 3 days: 2026-06-04
        final receipt = _createReceipt(
          id: 30,
          productName: 'Phone Case',
          purchaseDate: DateTime(2026, 5, 1),
          warrantyDurationDays: 34,
        );

        final scheduled = await service.scheduleWarrantyReminders(
          receipt,
          now: fixedNow,
        );

        expect(scheduled, isEmpty);
      },
    );

    test('does not schedule reminders for receipts without warranty', () async {
      final receiptNoWarranty = _createReceipt(
        id: 40,
        productName: 'Groceries',
        purchaseDate: DateTime(2026, 5, 1),
        warrantyDurationDays: null,
      );
      final receiptZeroDays = _createReceipt(
        id: 41,
        productName: 'Coffee Mug',
        purchaseDate: DateTime(2026, 5, 1),
        warrantyDurationDays: 0,
      );

      expect(
        await service.scheduleWarrantyReminders(
          receiptNoWarranty,
          now: fixedNow,
        ),
        isEmpty,
      );
      expect(
        await service.scheduleWarrantyReminders(receiptZeroDays, now: fixedNow),
        isEmpty,
      );
    });

    test('does not schedule reminders for already-expired warranty', () async {
      final expiredReceipt = _createReceipt(
        id: 50,
        productName: 'Old Laptop',
        purchaseDate: DateTime(2024, 1, 1),
        warrantyDurationDays: 365,
      );

      final scheduled = await service.scheduleWarrantyReminders(
        expiredReceipt,
        now: fixedNow,
      );

      expect(scheduled, isEmpty);
    });

    test(
      'cancelWarrantyReminders cancels reminders for that receipt only',
      () async {
        final receipt1 = _createReceipt(
          id: 1,
          productName: 'Device 1',
          purchaseDate: DateTime(2026, 5, 1),
          warrantyDurationDays: 365,
        );
        final receipt2 = _createReceipt(
          id: 2,
          productName: 'Device 2',
          purchaseDate: DateTime(2026, 5, 1),
          warrantyDurationDays: 365,
        );

        await service.scheduleWarrantyReminders(receipt1, now: fixedNow);
        await service.scheduleWarrantyReminders(receipt2, now: fixedNow);

        expect((await service.getScheduledReminders()).length, 4);

        await service.cancelWarrantyReminders(1);

        final remaining = await service.getScheduledReminders();
        expect(remaining.length, 2);
        expect(remaining.every((n) => n.receiptId == 2), isTrue);
      },
    );

    test('cancelAllReminders removes all scheduled notifications', () async {
      final receipt = _createReceipt(
        id: 1,
        productName: 'Device',
        purchaseDate: DateTime(2026, 5, 1),
        warrantyDurationDays: 365,
      );
      await service.scheduleWarrantyReminders(receipt, now: fixedNow);
      expect((await service.getScheduledReminders()).isNotEmpty, isTrue);

      await service.cancelAllReminders();
      expect(await service.getScheduledReminders(), isEmpty);
    });

    test(
      'syncAllReceiptReminders schedules for enabled and clears for disabled',
      () async {
        final r1 = _createReceipt(
          id: 1,
          productName: 'Item 1',
          purchaseDate: DateTime(2026, 5, 1),
          warrantyDurationDays: 365,
        );
        final r2 = _createReceipt(
          id: 2,
          productName: 'Item 2',
          purchaseDate: DateTime(2026, 5, 1),
          warrantyDurationDays: 180,
        );
        final r3NoWarranty = _createReceipt(
          id: 3,
          productName: 'Item 3',
          purchaseDate: DateTime(2026, 5, 1),
          warrantyDurationDays: null,
        );

        // Enabled sync
        final count = await service.syncAllReceiptReminders(
          [r1, r2, r3NoWarranty],
          isEnabled: true,
          now: fixedNow,
        );
        expect(count, 4);
        expect((await service.getScheduledReminders()).length, 4);

        // Disabled sync
        final disabledCount = await service.syncAllReceiptReminders(
          [r1, r2, r3NoWarranty],
          isEnabled: false,
          now: fixedNow,
        );
        expect(disabledCount, 0);
        expect(await service.getScheduledReminders(), isEmpty);
      },
    );

    test(
      'requestPermissions respects configured permission return value',
      () async {
        final grantedService = FakeWarrantyNotificationService(
          permissionGranted: true,
        );
        expect(await grantedService.requestPermissions(), isTrue);

        final deniedService = FakeWarrantyNotificationService(
          permissionGranted: false,
        );
        expect(await deniedService.requestPermissions(), isFalse);
      },
    );
  });

  group('AppSettingsService Notification Preference Persistence', () {
    test(
      'InMemoryAppSettingsService defaults to true and persists setting',
      () async {
        final service = InMemoryAppSettingsService();
        expect(await service.getWarrantyNotificationsEnabled(), isTrue);

        await service.setWarrantyNotificationsEnabled(false);
        expect(await service.getWarrantyNotificationsEnabled(), isFalse);

        await service.setWarrantyNotificationsEnabled(true);
        expect(await service.getWarrantyNotificationsEnabled(), isTrue);
      },
    );

    test(
      'LocalFileAppSettingsService persists and restores notification setting',
      () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'notification_settings_test_',
        );
        addTearDown(() => tempDir.delete(recursive: true));

        final service1 = LocalFileAppSettingsService(
          getDirectory: () async => tempDir,
        );

        // Default value is true
        expect(await service1.getWarrantyNotificationsEnabled(), isTrue);

        // Disable notifications
        await service1.setWarrantyNotificationsEnabled(false);
        expect(await service1.getWarrantyNotificationsEnabled(), isFalse);

        // Re-read with a fresh instance pointing to the same file
        final service2 = LocalFileAppSettingsService(
          getDirectory: () async => tempDir,
        );
        expect(await service2.getWarrantyNotificationsEnabled(), isFalse);

        // Re-enable notifications
        await service2.setWarrantyNotificationsEnabled(true);
        expect(await service2.getWarrantyNotificationsEnabled(), isTrue);
      },
    );
  });
}
