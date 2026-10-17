// lib/main.dart
//
// Entry point for Receipt Vault.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receipt_vault/app/router/app_router.dart';
import 'package:receipt_vault/app/theme/app_theme.dart';
import 'package:receipt_vault/core/services/warranty_notification_service.dart';
import 'package:receipt_vault/core/storage/app_settings_service.dart';
import 'package:receipt_vault/features/receipts/presentation/providers/receipts_providers.dart';
import 'package:receipt_vault/features/settings/presentation/providers/settings_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settingsService = LocalFileAppSettingsService();
  final initialThemeMode = await settingsService.getThemeMode();
  final initialNotificationsEnabled = await settingsService
      .getWarrantyNotificationsEnabled();

  final notificationService = LocalWarrantyNotificationService();
  try {
    await notificationService.initialize();
  } catch (e) {
    debugPrint('Failed to initialize warranty notification service: $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        settingsServiceProvider.overrideWithValue(settingsService),
        initialThemeModeProvider.overrideWithValue(initialThemeMode),
        initialWarrantyNotificationsEnabledProvider.overrideWithValue(
          initialNotificationsEnabled,
        ),
        warrantyNotificationServiceProvider.overrideWithValue(
          notificationService,
        ),
      ],
      child: const ReceiptVaultApp(),
    ),
  );
}

/// Root widget for the Receipt Vault application.
class ReceiptVaultApp extends ConsumerStatefulWidget {
  const ReceiptVaultApp({super.key});

  @override
  ConsumerState<ReceiptVaultApp> createState() => _ReceiptVaultAppState();
}

class _ReceiptVaultAppState extends ConsumerState<ReceiptVaultApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncNotificationsOnStartup();
    });
  }

  Future<void> _syncNotificationsOnStartup() async {
    try {
      final notificationsEnabled = ref.read(warrantyNotificationsProvider);
      if (notificationsEnabled) {
        final notificationService = ref.read(
          warrantyNotificationServiceProvider,
        );
        final repository = ref.read(receiptsRepositoryProvider);
        final receipts = await repository.getAllReceipts();
        await notificationService.syncAllReceiptReminders(
          receipts,
          isEnabled: true,
        );
      }
    } catch (e) {
      debugPrint('Startup warranty notification synchronization failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
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
