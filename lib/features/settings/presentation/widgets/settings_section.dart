// lib/features/settings/presentation/widgets/settings_section.dart

import 'package:flutter/material.dart';
import 'package:receipt_vault/app/theme/app_theme.dart';

/// Reusable section wrapper for settings categories with header title,
/// optional subtitle, and card content container.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final Widget child;

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
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: primaryTextColor,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: AppShapes.radiusMd,
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 25 : 8),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: child,
        ),
        const SizedBox(height: 18),
      ],
    );
  }
}
