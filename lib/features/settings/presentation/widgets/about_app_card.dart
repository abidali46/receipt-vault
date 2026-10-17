// lib/features/settings/presentation/widgets/about_app_card.dart

import 'package:flutter/material.dart';
import 'package:receipt_vault/app/constants/app_constants.dart';
import 'package:receipt_vault/app/theme/app_theme.dart';

/// Card displaying app metadata, version number, and description.
class AboutAppCard extends StatelessWidget {
  const AboutAppCard({super.key});

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

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryContainer,
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  size: 22,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppInfo.appName,
                      key: const Key('settings_about_app_name'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: primaryTextColor,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Receipt & Warranty Keeper',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                key: const Key('settings_about_version_badge'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withAlpha(isDark ? 40 : 20),
                  borderRadius: AppShapes.radiusFull,
                  border: Border.all(
                    color: AppColors.primaryContainer.withAlpha(
                      isDark ? 80 : 50,
                    ),
                  ),
                ),
                child: Text(
                  AppInfo.displayVersion,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.primaryLight
                        : AppColors.primaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            AppInfo.description,
            key: const Key('settings_about_description'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: secondaryTextColor,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          const SizedBox(height: 12),
          _MetaRow(
            label: 'Build',
            value: AppInfo.fullVersion,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
          ),
          const SizedBox(height: 6),
          _MetaRow(
            label: 'Storage',
            value: 'Offline SQLite (Drift)',
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
          ),
          const SizedBox(height: 6),
          _MetaRow(
            label: 'Architecture',
            value: 'Clean Offline-First',
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.label,
    required this.value,
    required this.primaryTextColor,
    required this.secondaryTextColor,
  });

  final String label;
  final String value;
  final Color primaryTextColor;
  final Color secondaryTextColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: secondaryTextColor,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: primaryTextColor,
          ),
        ),
      ],
    );
  }
}
