// lib/main.dart
//
// Entry point for Receipt Vault.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receipt_vault/app/router/app_router.dart';
import 'package:receipt_vault/app/theme/app_theme.dart';
import 'package:receipt_vault/core/storage/app_settings_service.dart';
import 'package:receipt_vault/features/settings/presentation/providers/settings_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settingsService = LocalFileAppSettingsService();
  final initialThemeMode = await settingsService.getThemeMode();

  runApp(
    ProviderScope(
      overrides: [
        settingsServiceProvider.overrideWithValue(settingsService),
        initialThemeModeProvider.overrideWithValue(initialThemeMode),
      ],
      child: const ReceiptVaultApp(),
    ),
  );
}

/// Root widget for the Receipt Vault application.
class ReceiptVaultApp extends ConsumerWidget {
  const ReceiptVaultApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Receipt Vault',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
