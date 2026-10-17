// lib/core/storage/app_settings_service.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Contract for persisting and retrieving application-level user preferences.
abstract class AppSettingsService {
  /// Loads the saved [ThemeMode]. Defaults to [ThemeMode.system] if unset or on error.
  Future<ThemeMode> getThemeMode();

  /// Persists the selected [ThemeMode].
  Future<void> setThemeMode(ThemeMode mode);

  /// Loads whether warranty reminder notifications are enabled. Defaults to true.
  Future<bool> getWarrantyNotificationsEnabled();

  /// Persists whether warranty reminder notifications are enabled.
  Future<void> setWarrantyNotificationsEnabled(bool enabled);
}

/// Lightweight, zero-new-dependency implementation of [AppSettingsService]
/// storing preferences in a local JSON file (`app_settings.json`) within
/// the app's persistent documents directory.
class LocalFileAppSettingsService implements AppSettingsService {
  LocalFileAppSettingsService({Future<Directory> Function()? getDirectory})
    : _getDirectory = getDirectory ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _getDirectory;

  static const String _fileName = 'app_settings.json';
  static const String _themeModeKey = 'theme_mode';
  static const String _notificationsEnabledKey =
      'warranty_notifications_enabled';

  File? _cachedFile;

  Future<File> _getFile() async {
    if (_cachedFile != null) return _cachedFile!;
    final dir = await _getDirectory();
    _cachedFile = File(p.join(dir.path, _fileName));
    return _cachedFile!;
  }

  @override
  Future<ThemeMode> getThemeMode() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) {
        return ThemeMode.system;
      }
      final content = await file.readAsString();
      final data = jsonDecode(content);
      if (data is Map<String, dynamic>) {
        final modeStr = data[_themeModeKey] as String?;
        switch (modeStr) {
          case 'light':
            return ThemeMode.light;
          case 'dark':
            return ThemeMode.dark;
          case 'system':
          default:
            return ThemeMode.system;
        }
      }
      return ThemeMode.system;
    } catch (_) {
      return ThemeMode.system;
    }
  }

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    try {
      final file = await _getFile();
      Map<String, dynamic> data = {};
      if (await file.exists()) {
        try {
          final content = await file.readAsString();
          final parsed = jsonDecode(content);
          if (parsed is Map<String, dynamic>) {
            data = parsed;
          }
        } catch (_) {}
      }
      data[_themeModeKey] = mode.name;
      await file.writeAsString(jsonEncode(data), flush: true);
    } catch (_) {
      // Graceful fallback if filesystem write fails
    }
  }

  @override
  Future<bool> getWarrantyNotificationsEnabled() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) {
        return true;
      }
      final content = await file.readAsString();
      final data = jsonDecode(content);
      if (data is Map<String, dynamic>) {
        final enabled = data[_notificationsEnabledKey];
        if (enabled is bool) {
          return enabled;
        }
      }
      return true;
    } catch (_) {
      return true;
    }
  }

  @override
  Future<void> setWarrantyNotificationsEnabled(bool enabled) async {
    try {
      final file = await _getFile();
      Map<String, dynamic> data = {};
      if (await file.exists()) {
        try {
          final content = await file.readAsString();
          final parsed = jsonDecode(content);
          if (parsed is Map<String, dynamic>) {
            data = parsed;
          }
        } catch (_) {}
      }
      data[_notificationsEnabledKey] = enabled;
      await file.writeAsString(jsonEncode(data), flush: true);
    } catch (_) {
      // Graceful fallback if filesystem write fails
    }
  }
}

/// In-memory test double for fast, hermetic testing without file system side effects.
class InMemoryAppSettingsService implements AppSettingsService {
  InMemoryAppSettingsService([
    this._themeMode = ThemeMode.system,
    this._warrantyNotificationsEnabled = true,
  ]);

  ThemeMode _themeMode;
  bool _warrantyNotificationsEnabled;

  @override
  Future<ThemeMode> getThemeMode() async => _themeMode;

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
  }

  @override
  Future<bool> getWarrantyNotificationsEnabled() async =>
      _warrantyNotificationsEnabled;

  @override
  Future<void> setWarrantyNotificationsEnabled(bool enabled) async {
    _warrantyNotificationsEnabled = enabled;
  }
}
