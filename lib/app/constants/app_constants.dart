// lib/app/constants/app_constants.dart

/// Static application metadata and display strings.
abstract final class AppInfo {
  static const String appName = 'Receipt Vault';
  static const String version = '1.0.0';
  static const String buildNumber = '1';
  static const String displayVersion = 'v$version';
  static const String fullVersion = 'v$version+$buildNumber';
  static const String description =
      'A simple, secure, offline-first receipt keeper and warranty tracker. '
      'Designed for digital peace of mind.';
}
