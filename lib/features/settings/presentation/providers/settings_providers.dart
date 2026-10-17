import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receipt_vault/core/services/warranty_notification_service.dart';
import 'package:receipt_vault/core/storage/app_settings_service.dart';
import 'package:receipt_vault/features/receipts/presentation/providers/receipts_providers.dart';

/// Provider exposing the persistent settings storage service.
final settingsServiceProvider = Provider<AppSettingsService>((ref) {
  return LocalFileAppSettingsService();
});

/// Holds the preloaded [ThemeMode] read during app initialization in `main()`.
/// Defaults to [ThemeMode.system] when running tests without preloading.
final initialThemeModeProvider = Provider<ThemeMode>((ref) {
  return ThemeMode.system;
});

/// Holds the preloaded warranty notifications setting read during app initialization.
/// Defaults to true when running tests without preloading.
final initialWarrantyNotificationsEnabledProvider = Provider<bool>((ref) {
  return true;
});

/// Riverpod [Notifier] managing the application's active [ThemeMode].
///
/// Reactively updates the UI when changed, and persists changes to disk
/// via [AppSettingsService].
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final initial = ref.watch(initialThemeModeProvider);
    final service = ref.watch(settingsServiceProvider);

    // Asynchronously double-check persisted state in case initial was not preloaded
    service.getThemeMode().then((persistedMode) {
      if (state != persistedMode) {
        state = persistedMode;
      }
    });

    return initial;
  }

  /// Updates the active theme mode and persists it to local storage.
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final service = ref.read(settingsServiceProvider);
    await service.setThemeMode(mode);
  }
}

/// Global provider for the active [ThemeMode].
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(() {
  return ThemeModeNotifier();
});

/// Riverpod [Notifier] managing the user's warranty notification preference.
class WarrantyNotificationsNotifier extends Notifier<bool> {
  @override
  bool build() {
    final initial = ref.watch(initialWarrantyNotificationsEnabledProvider);
    final service = ref.watch(settingsServiceProvider);

    service.getWarrantyNotificationsEnabled().then((persistedEnabled) {
      if (state != persistedEnabled) {
        state = persistedEnabled;
      }
    });

    return initial;
  }

  /// Updates notification setting, requesting OS permissions when enabling.
  /// If permission is denied by the OS, leaves setting disabled and returns false.
  Future<bool> setNotificationsEnabled(bool enabled) async {
    final settingsService = ref.read(settingsServiceProvider);
    final notificationService = ref.read(warrantyNotificationServiceProvider);

    if (enabled) {
      final granted = await notificationService.requestPermissions();
      if (!granted) {
        state = false;
        await settingsService.setWarrantyNotificationsEnabled(false);
        await notificationService.cancelAllReminders();
        return false;
      }
    }

    state = enabled;
    await settingsService.setWarrantyNotificationsEnabled(enabled);

    if (enabled) {
      final repository = ref.read(receiptsRepositoryProvider);
      final receipts = await repository.getAllReceipts();
      await notificationService.syncAllReceiptReminders(
        receipts,
        isEnabled: true,
      );
    } else {
      await notificationService.cancelAllReminders();
    }

    return true;
  }
}

/// Global provider for warranty notification preference.
final warrantyNotificationsProvider =
    NotifierProvider<WarrantyNotificationsNotifier, bool>(() {
      return WarrantyNotificationsNotifier();
    });
