// lib/features/settings/presentation/settings_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receipt_vault/app/theme/app_theme.dart';
import 'package:receipt_vault/features/receipts/domain/repositories/receipts_repository.dart';
import 'package:receipt_vault/features/settings/presentation/providers/settings_providers.dart';
import 'package:receipt_vault/features/settings/presentation/widgets/about_app_card.dart';
import 'package:receipt_vault/features/settings/presentation/widgets/data_export_card.dart';
import 'package:receipt_vault/features/settings/presentation/widgets/notifications_setting_card.dart';
import 'package:receipt_vault/features/settings/presentation/widgets/privacy_note_card.dart';
import 'package:receipt_vault/features/settings/presentation/widgets/settings_section.dart';
import 'package:receipt_vault/features/settings/presentation/widgets/theme_selection_card.dart';

/// Screen allowing users to manage app appearance (light, dark, system-default),
/// export receipt metadata to CSV backups, review the offline data privacy guarantee,
/// and inspect app version details.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({
    super.key,
    this.repository,
    this.customDownloadsProvider,
    this.customDocumentsProvider,
  });

  /// Optional repository override for testing.
  final ReceiptsRepository? repository;

  /// Optional custom provider for downloads directory (useful in tests).
  final Future<Directory?> Function()? customDownloadsProvider;

  /// Optional custom provider for documents directory (useful in tests).
  final Future<Directory> Function()? customDocumentsProvider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentThemeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.settings_outlined,
              color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
              size: 26,
            ),
            const SizedBox(width: 8),
            const Text(
              'Settings',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              key: const Key('settings_scroll_view'),
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Section 1: Appearance / Theme Mode
                  SettingsSection(
                    title: 'Appearance',
                    subtitle:
                        'Customize how Receipt Vault looks on your device',
                    child: ThemeSelectionCard(
                      currentThemeMode: currentThemeMode,
                      onThemeChanged: (mode) {
                        ref.read(themeModeProvider.notifier).setThemeMode(mode);
                      },
                    ),
                  ),

                  // Section 2: Notifications
                  const SettingsSection(
                    title: 'Notifications',
                    subtitle: 'Manage automatic warranty expiry reminders',
                    child: NotificationsSettingCard(),
                  ),

                  // Section 3: Data Management (Export & Backup)
                  SettingsSection(
                    title: 'Data Management',
                    subtitle: 'Export and back up your receipt records',
                    child: DataExportCard(
                      repository: repository,
                      customDownloadsProvider: customDownloadsProvider,
                      customDocumentsProvider: customDocumentsProvider,
                    ),
                  ),

                  // Section 3: Data & Privacy Note
                  const SettingsSection(
                    title: 'Data & Privacy',
                    subtitle:
                        'Your receipts stay completely under your control',
                    child: PrivacyNoteCard(),
                  ),

                  // Section 4: About App
                  const SettingsSection(
                    title: 'About',
                    subtitle: 'App version and build information',
                    child: AboutAppCard(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
