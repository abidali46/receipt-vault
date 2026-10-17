// lib/core/services/warranty_notification_service.dart
//
// Scheduled local notifications service for Receipt Vault.
// Reminds users 30 days and 7 days prior to product warranty expiration
// using flutter_local_notifications, timezone, and flutter_timezone.

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:receipt_vault/core/storage/app_database.dart';
import 'package:receipt_vault/features/receipts/domain/services/warranty_calculator.dart';
import 'package:receipt_vault/shared/enums/warranty_status.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Metadata for a planned or scheduled warranty reminder.
class ScheduledWarrantyNotification {
  const ScheduledWarrantyNotification({
    required this.id,
    required this.receiptId,
    required this.daysBeforeExpiry,
    required this.title,
    required this.body,
    required this.scheduledDate,
    required this.payload,
  });

  /// Deterministic 32-bit notification ID.
  final int id;

  /// Database ID of the associated receipt.
  final int receiptId;

  /// Reminder offset (30 or 7 days).
  final int daysBeforeExpiry;

  /// Display title.
  final String title;

  /// Display message body.
  final String body;

  /// Target notification delivery timestamp.
  final DateTime scheduledDate;

  /// Deep link / router payload.
  final String payload;
}

/// Abstract contract for warranty notification scheduling and lifecycle.
abstract class WarrantyNotificationService {
  /// Initializes the local notification plugin, channels, and device timezone.
  Future<void> initialize();

  /// Requests notification permissions from the operating system (Android 13+, iOS).
  /// Returns `true` if permissions were granted or already granted.
  Future<bool> requestPermissions();

  /// Checks if notifications are permitted by operating system settings.
  Future<bool> areNotificationsEnabled();

  /// Stream emitting notification payloads when tapped while the application is running.
  Stream<String> get onNotificationTap;

  /// Retrieves payload if the app was launched by tapping a notification (cold start).
  Future<String?> getAppLaunchPayload();

  /// Schedules future 30-day and 7-day reminders for a receipt if eligible.
  /// Returns the list of scheduled reminders.
  Future<List<ScheduledWarrantyNotification>> scheduleWarrantyReminders(
    Receipt receipt, {
    DateTime? now,
  });

  /// Cancels any scheduled reminders for a specific receipt.
  Future<void> cancelWarrantyReminders(int receiptId);

  /// Cancels all scheduled Receipt Vault warranty reminders.
  Future<void> cancelAllReminders();

  /// Rebuilds all scheduled reminders from a list of receipts.
  /// If [isEnabled] is false, all reminders are cancelled and none are scheduled.
  Future<int> syncAllReceiptReminders(
    List<Receipt> receipts, {
    bool isEnabled = true,
    DateTime? now,
  });

  /// Retrieves currently scheduled reminders (supported on local implementation).
  Future<List<ScheduledWarrantyNotification>> getScheduledReminders();
}

/// Production implementation of [WarrantyNotificationService] backed by [FlutterLocalNotificationsPlugin].
class LocalWarrantyNotificationService implements WarrantyNotificationService {
  LocalWarrantyNotificationService({
    FlutterLocalNotificationsPlugin? plugin,
    Future<String> Function()? getTimeZoneName,
    Future<TimezoneInfo> Function()? getTimeZoneInfo,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _getTimeZoneName =
           getTimeZoneName ??
           (getTimeZoneInfo != null
               ? (() async {
                   final info = await getTimeZoneInfo();
                   return extractTimeZoneIdentifier(info);
                 })
               : _defaultGetTimeZoneName);

  static Future<String> _defaultGetTimeZoneName() async {
    final info = await FlutterTimezone.getLocalTimezone();
    return extractTimeZoneIdentifier(info);
  }

  /// Extracts the standardized IANA timezone identifier from [TimezoneInfo].
  static String extractTimeZoneIdentifier(TimezoneInfo info) {
    return info.identifier.trim();
  }

  final FlutterLocalNotificationsPlugin _plugin;
  final Future<String> Function() _getTimeZoneName;
  final StreamController<String> _tapStreamController =
      StreamController<String>.broadcast();
  bool _isInitialized = false;

  /// Android notification channel ID for warranty expiration alerts.
  static const String channelId = 'warranty_alerts_channel';

  /// Android notification channel user-facing name.
  static const String channelName = 'Warranty Expiration Alerts';

  /// Android notification channel user-facing description.
  static const String channelDescription =
      'Notifications reminding you before product warranties expire.';

  /// Hour of the day (0-23) at which reminders are delivered (9:00 AM local time).
  static const int reminderHour = 9;

  /// Minute of the hour at which reminders are delivered.
  static const int reminderMinute = 0;

  /// Calculates deterministic notification ID for a 30-day reminder.
  static int reminder30Id(int receiptId) => (receiptId * 10) + 1;

  /// Calculates deterministic notification ID for a 7-day reminder.
  static int reminder7Id(int receiptId) => (receiptId * 10) + 2;

  /// Formats date for notification messages (e.g., 'Mar 15, 2026').
  static String formatExpiryDate(DateTime date) {
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
    final month = months[date.month - 1];
    return '$month ${date.day}, ${date.year}';
  }

  /// Safely extracts the receipt ID from a notification payload.
  /// Handles formats like '/receipts/123', '123', or full URIs.
  /// Returns null if the payload is malformed, invalid, or null.
  static int? parseReceiptIdFromPayload(String? payload) {
    if (payload == null) return null;
    final trimmed = payload.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.startsWith('/receipts/')) {
      final idPart = trimmed.substring('/receipts/'.length);
      return int.tryParse(idPart);
    }

    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      if (uri.pathSegments.first == 'receipts' && uri.pathSegments.length > 1) {
        return int.tryParse(uri.pathSegments[1]);
      }
    }

    return int.tryParse(trimmed);
  }

  @override
  Stream<String> get onNotificationTap => _tapStreamController.stream;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();
      String timeZoneName;
      try {
        final timeoutDuration =
            !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')
            ? const Duration(milliseconds: 50)
            : const Duration(seconds: 2);
        timeZoneName = await _getTimeZoneName().timeout(timeoutDuration);
      } catch (_) {
        timeZoneName = 'UTC';
      }

      try {
        tz.setLocalLocation(tz.getLocation(timeZoneName));
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('UTC'));
      }
    } catch (e) {
      debugPrint('Warning: Timezone initialization error: $e');
      try {
        // Fallback to UTC if device timezone cannot be determined
        tz.setLocalLocation(tz.getLocation('UTC'));
      } catch (_) {}
    }

    try {
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            _tapStreamController.add(payload);
          }
        },
      );

      // Create Android Notification Channel
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin != null) {
        const channel = AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDescription,
          importance: Importance.high,
        );
        await androidPlugin.createNotificationChannel(channel);
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('Warning: Failed to initialize local notifications: $e');
    }
  }

  @override
  Future<String?> getAppLaunchPayload() async {
    try {
      await initialize();
      final launchDetails = await _plugin.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp ?? false) {
        return launchDetails?.notificationResponse?.payload;
      }
      return null;
    } catch (e) {
      debugPrint('Error retrieving app launch payload: $e');
      return null;
    }
  }

  @override
  Future<bool> requestPermissions() async {
    try {
      await initialize();

      // Android 13+ permission request
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        return granted ?? false;
      }

      // iOS permission request
      final iosPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }

      return true;
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
      return false;
    }
  }

  @override
  Future<bool> areNotificationsEnabled() async {
    try {
      await initialize();

      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidPlugin = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        return await androidPlugin?.areNotificationsEnabled() ?? false;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosPlugin = _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        final options = await iosPlugin?.checkPermissions();
        return (options?.isEnabled ?? false) ||
            (options?.isAlertEnabled ?? false);
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<ScheduledWarrantyNotification>> scheduleWarrantyReminders(
    Receipt receipt, {
    DateTime? now,
  }) async {
    final scheduled = <ScheduledWarrantyNotification>[];

    final warrantyInfo = WarrantyCalculator.calculate(
      purchaseDate: receipt.purchaseDate,
      warrantyDurationDays: receipt.warrantyDurationDays,
      now: now,
    );

    // Only schedule if a valid, unexpired warranty exists
    if (warrantyInfo.status == WarrantyStatus.none ||
        warrantyInfo.status == WarrantyStatus.expired ||
        warrantyInfo.expiryDate == null) {
      return scheduled;
    }

    final expiryDate = warrantyInfo.expiryDate!;
    final currentTime = now ?? DateTime.now();

    final remindersToSchedule = <int>[30, 7];

    for (final daysBefore in remindersToSchedule) {
      // Calculate target date
      final targetDate = DateTime(
        expiryDate.year,
        expiryDate.month,
        expiryDate.day,
        reminderHour,
        reminderMinute,
      ).subtract(Duration(days: daysBefore));

      // Reminders must be strictly in the future and after the original purchase date
      if (targetDate.isAfter(currentTime) &&
          targetDate.isAfter(receipt.purchaseDate)) {
        final notificationId = daysBefore == 30
            ? reminder30Id(receipt.id)
            : reminder7Id(receipt.id);

        final title = 'Warranty Expiring Soon: ${receipt.productName}';
        final body = daysBefore == 30
            ? 'The warranty for ${receipt.productName} expires in 30 days on ${formatExpiryDate(expiryDate)}.'
            : 'The warranty for ${receipt.productName} expires in 7 days on ${formatExpiryDate(expiryDate)}. Check your coverage now.';

        final payload = '/receipts/${receipt.id}';

        final item = ScheduledWarrantyNotification(
          id: notificationId,
          receiptId: receipt.id,
          daysBeforeExpiry: daysBefore,
          title: title,
          body: body,
          scheduledDate: targetDate,
          payload: payload,
        );

        try {
          await initialize();

          final tzScheduledDate = tz.TZDateTime(
            tz.local,
            targetDate.year,
            targetDate.month,
            targetDate.day,
            reminderHour,
            reminderMinute,
          );

          const androidDetails = AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          );

          const iosDetails = DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          );

          const details = NotificationDetails(
            android: androidDetails,
            iOS: iosDetails,
          );

          await _plugin.zonedSchedule(
            id: notificationId,
            title: title,
            body: body,
            scheduledDate: tzScheduledDate,
            notificationDetails: details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            payload: payload,
          );

          scheduled.add(item);
        } catch (e) {
          debugPrint('Failed to schedule notification $notificationId: $e');
        }
      }
    }

    return scheduled;
  }

  @override
  Future<void> cancelWarrantyReminders(int receiptId) async {
    try {
      await initialize();
      await _plugin.cancel(id: reminder30Id(receiptId));
      await _plugin.cancel(id: reminder7Id(receiptId));
    } catch (e) {
      debugPrint('Failed to cancel reminders for receipt $receiptId: $e');
    }
  }

  @override
  Future<void> cancelAllReminders() async {
    try {
      await initialize();
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('Failed to cancel all notifications: $e');
    }
  }

  @override
  Future<int> syncAllReceiptReminders(
    List<Receipt> receipts, {
    bool isEnabled = true,
    DateTime? now,
  }) async {
    if (!isEnabled) {
      await cancelAllReminders();
      return 0;
    }

    // Cancel existing reminders first to remove stale or deleted items
    await cancelAllReminders();

    int totalScheduled = 0;
    for (final receipt in receipts) {
      final scheduled = await scheduleWarrantyReminders(receipt, now: now);
      totalScheduled += scheduled.length;
    }

    return totalScheduled;
  }

  @override
  Future<List<ScheduledWarrantyNotification>> getScheduledReminders() async {
    try {
      await initialize();
      final pending = await _plugin.pendingNotificationRequests();
      return pending
          .map(
            (p) => ScheduledWarrantyNotification(
              id: p.id,
              receiptId: p.id ~/ 10,
              daysBeforeExpiry: (p.id % 10) == 1 ? 30 : 7,
              title: p.title ?? '',
              body: p.body ?? '',
              scheduledDate: DateTime.now(),
              payload: p.payload ?? '',
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }
}

/// Fake in-memory notification service for hermetic, deterministic testing without platform channels.
class FakeWarrantyNotificationService implements WarrantyNotificationService {
  FakeWarrantyNotificationService({
    bool? permissionGranted,
    bool? isPermissionGranted,
    this.notificationsEnabled = true,
  }) : isPermissionGranted = permissionGranted ?? isPermissionGranted ?? true;

  bool isPermissionGranted;
  bool notificationsEnabled;
  bool isInitialized = false;
  String? fakeLaunchPayload;

  final StreamController<String> _tapStreamController =
      StreamController<String>.broadcast();
  final Map<int, ScheduledWarrantyNotification> scheduledNotifications = {};
  final List<String> callLog = [];

  @override
  Stream<String> get onNotificationTap => _tapStreamController.stream;

  @override
  Future<String?> getAppLaunchPayload() async => fakeLaunchPayload;

  void simulateNotificationTap(String payload) {
    callLog.add('notificationTap:$payload');
    _tapStreamController.add(payload);
  }

  void setLaunchPayload(String? payload) {
    fakeLaunchPayload = payload;
  }

  @override
  Future<void> initialize() async {
    isInitialized = true;
    callLog.add('initialize');
  }

  @override
  Future<bool> requestPermissions() async {
    callLog.add('requestPermissions');
    return isPermissionGranted;
  }

  @override
  Future<bool> areNotificationsEnabled() async {
    callLog.add('areNotificationsEnabled');
    return notificationsEnabled && isPermissionGranted;
  }

  @override
  Future<List<ScheduledWarrantyNotification>> scheduleWarrantyReminders(
    Receipt receipt, {
    DateTime? now,
  }) async {
    callLog.add(
      'scheduleWarrantyReminders:${receipt.id}:${receipt.productName}',
    );
    final scheduled = <ScheduledWarrantyNotification>[];

    final warrantyInfo = WarrantyCalculator.calculate(
      purchaseDate: receipt.purchaseDate,
      warrantyDurationDays: receipt.warrantyDurationDays,
      now: now,
    );

    if (warrantyInfo.status == WarrantyStatus.none ||
        warrantyInfo.status == WarrantyStatus.expired ||
        warrantyInfo.expiryDate == null) {
      return scheduled;
    }

    final expiryDate = warrantyInfo.expiryDate!;
    final currentTime = now ?? DateTime.now();

    for (final daysBefore in [30, 7]) {
      final targetDate = DateTime(
        expiryDate.year,
        expiryDate.month,
        expiryDate.day,
        LocalWarrantyNotificationService.reminderHour,
        LocalWarrantyNotificationService.reminderMinute,
      ).subtract(Duration(days: daysBefore));

      if (targetDate.isAfter(currentTime) &&
          targetDate.isAfter(receipt.purchaseDate)) {
        final id = daysBefore == 30
            ? LocalWarrantyNotificationService.reminder30Id(receipt.id)
            : LocalWarrantyNotificationService.reminder7Id(receipt.id);

        final title = 'Warranty Expiring Soon: ${receipt.productName}';
        final body = daysBefore == 30
            ? 'The warranty for ${receipt.productName} expires in 30 days on ${LocalWarrantyNotificationService.formatExpiryDate(expiryDate)}.'
            : 'The warranty for ${receipt.productName} expires in 7 days on ${LocalWarrantyNotificationService.formatExpiryDate(expiryDate)}. Check your coverage now.';

        final item = ScheduledWarrantyNotification(
          id: id,
          receiptId: receipt.id,
          daysBeforeExpiry: daysBefore,
          title: title,
          body: body,
          scheduledDate: targetDate,
          payload: '/receipts/${receipt.id}',
        );

        scheduledNotifications[id] = item;
        scheduled.add(item);
      }
    }

    return scheduled;
  }

  @override
  Future<void> cancelWarrantyReminders(int receiptId) async {
    callLog.add('cancelWarrantyReminders:$receiptId');
    scheduledNotifications.remove(
      LocalWarrantyNotificationService.reminder30Id(receiptId),
    );
    scheduledNotifications.remove(
      LocalWarrantyNotificationService.reminder7Id(receiptId),
    );
  }

  @override
  Future<void> cancelAllReminders() async {
    callLog.add('cancelAllReminders');
    scheduledNotifications.clear();
  }

  @override
  Future<int> syncAllReceiptReminders(
    List<Receipt> receipts, {
    bool isEnabled = true,
    DateTime? now,
  }) async {
    callLog.add(
      'syncAllReceiptReminders:${receipts.length}:isEnabled=$isEnabled',
    );
    if (!isEnabled) {
      await cancelAllReminders();
      return 0;
    }

    await cancelAllReminders();

    int count = 0;
    for (final r in receipts) {
      final items = await scheduleWarrantyReminders(r, now: now);
      count += items.length;
    }
    return count;
  }

  @override
  Future<List<ScheduledWarrantyNotification>> getScheduledReminders() async {
    return scheduledNotifications.values.toList();
  }
}

/// Global Riverpod provider for [WarrantyNotificationService].
final warrantyNotificationServiceProvider =
    Provider<WarrantyNotificationService>((ref) {
      return LocalWarrantyNotificationService();
    });
