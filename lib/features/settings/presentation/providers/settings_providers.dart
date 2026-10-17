// lib/features/settings/presentation/providers/settings_providers.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receipt_vault/core/storage/app_settings_service.dart';

/// Provider exposing the persistent settings storage service.
final settingsServiceProvider = Provider<AppSettingsService>((ref) {
  return LocalFileAppSettingsService();
});

/// Holds the preloaded [ThemeMode] read during app initialization in `main()`.
/// Defaults to [ThemeMode.system] when running tests without preloading.
final initialThemeModeProvider = Provider<ThemeMode>((ref) {
  return ThemeMode.system;
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
