// lib/features/settings/presentation/widgets/data_export_card.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:receipt_vault/app/theme/app_theme.dart';
import 'package:receipt_vault/features/receipts/domain/repositories/receipts_repository.dart';
import 'package:receipt_vault/features/settings/domain/services/receipt_export_service.dart';
import 'package:receipt_vault/features/settings/presentation/widgets/export_receipts_dialog.dart';

/// Card displayed on the Settings screen allowing users to launch the
/// local CSV export workflow for their receipt data.
class DataExportCard extends StatelessWidget {
  const DataExportCard({
    super.key,
    this.repository,
    this.customDownloadsProvider,
    this.customDocumentsProvider,
  });

  /// Optional repository override for testing.
  final ReceiptsRepository? repository;

  /// Optional custom provider for downloads directory (for testing).
  final Future<Directory?> Function()? customDownloadsProvider;

  /// Optional custom provider for documents directory (for testing).
  final Future<Directory> Function()? customDocumentsProvider;

  void _openExportDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => ExportReceiptsDialog(
        repository: repository,
        customDownloadsProvider: customDownloadsProvider,
        customDocumentsProvider: customDocumentsProvider,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryTextColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Column(
      children: [
        InkWell(
          key: const Key('settings_export_tile'),
          onTap: () => _openExportDialog(context),
          borderRadius: AppShapes.radiusMd,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryContainer.withAlpha(
                      isDark ? 40 : 20,
                    ),
                  ),
                  child: const Icon(
                    Icons.table_chart_outlined,
                    size: 22,
                    color: AppColors.primaryContainer,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Export Receipts (CSV)',
                        key: const Key('settings_export_title'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: primaryTextColor,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Save receipt records to a human-readable CSV file',
                        key: const Key('settings_export_subtitle'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  key: const Key('settings_export_button'),
                  onPressed: () => _openExportDialog(context),
                  child: const Text('Export'),
                ),
              ],
            ),
          ),
        ),
        Divider(
          height: 1,
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline,
                size: 16,
                color: AppColors.primaryContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ReceiptExportService.photoExclusionDisclaimer,
                  key: const Key('settings_export_disclaimer_note'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    height: 1.35,
                    color: secondaryTextColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
